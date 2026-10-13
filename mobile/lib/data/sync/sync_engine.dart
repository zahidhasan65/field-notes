import 'dart:convert';
import 'dart:io';

import '../../core/core.dart';
import '../../services/photo_storage.dart';
import '../local/data_sources/customer_local_data_source.dart';
import '../local/data_sources/field_note_local_data_source.dart';
import '../local/data_sources/site_local_data_source.dart';
import '../local/data_sources/sync_queue_local_data_source.dart';
import '../local/data_sources/sync_table_data_source.dart';
import '../local/database/database_helper.dart';
import '../models/customer_local.dart';
import '../models/field_note_local.dart';
import '../models/site_local.dart';
import '../models/sync_queue_item.dart';
import '../remote/sync_remote_data_source.dart';
import '../repositories/app_settings_repository.dart';
import '../repositories/data_events.dart';

class SyncResult {
  final int pushed;
  final int failed;
  final bool offline;
  final bool authExpired;

  const SyncResult({
    this.pushed = 0,
    this.failed = 0,
    this.offline = false,
    this.authExpired = false,
  });
}

enum RestoreStage { customers, sites, notes, photos }





class SyncEngine {
  SyncEngine({
    required this.helper,
    required this.remote,
    required this.customers,
    required this.sites,
    required this.notes,
    required this.queue,
    required this.settings,
    required this.photos,
  });

  final DatabaseHelper helper;
  final SyncRemoteDataSource remote;
  final CustomerLocalDataSource customers;
  final SiteLocalDataSource sites;
  final FieldNoteLocalDataSource notes;
  final SyncQueueLocalDataSource queue;
  final AppSettingsRepository settings;
  final PhotoStorage photos;



  Future<SyncResult> sync(String userId) async {
    var pushed = 0;
    var failed = 0;

    try {
      await queue.resetStuckProcessing(userId);

      final items = await queue.getRunnable(userId);
      items.sort(_compare);
      final failedEntityIds = <String>{};

      for (final item in items) {
        if (_dependsOnFailed(item, failedEntityIds)) continue;

        await queue.markProcessing(item.id!);
        try {
          await _pushItem(item);
          await _onSuccess(item);
          pushed++;
        } on NetworkException {
          await queue.markPendingAgain(item.id!);
          rethrow;
        } on AuthExpiredException {
          await queue.markPendingAgain(item.id!);
          rethrow;
        } on ApiException catch (e) {
          await _onFailure(item, e.message);
          failedEntityIds.add(item.entityId);
          failed++;
        } catch (e) {
          await _onFailure(item, e.toString());
          failedEntityIds.add(item.entityId);
          failed++;
        }
      }

      final lastPull = await settings.getLastPull(userId);
      final changes = await remote.fetchChanges(
        since: lastPull?.subtract(const Duration(seconds: 5)),
      );
      await _applyCustomers(userId, changes.customers);
      await _applySites(changes.sites);
      await _applyNotes(changes.notes);
      await settings.setLastPull(userId, changes.serverTime);
      await _downloadPhotos(userId);

      if (failed == 0) {
        await settings.setLastSynced(userId, DateTime.now());
      }
      DataEvents.notify();
      return SyncResult(pushed: pushed, failed: failed);
    } on NetworkException {
      DataEvents.notify();
      return SyncResult(pushed: pushed, failed: failed, offline: true);
    } on AuthExpiredException {
      return SyncResult(pushed: pushed, failed: failed, authExpired: true);
    }
  }





  Future<void> restore(
    String userId, {
    Future<void> Function(RestoreStage stage, int count)? onStage,
  }) async {
    final changes = await remote.fetchChanges(since: null);

    final c = await _applyCustomers(userId, changes.customers);
    await onStage?.call(RestoreStage.customers, c);

    final s = await _applySites(changes.sites);
    await onStage?.call(RestoreStage.sites, s);

    final n = await _applyNotes(changes.notes);
    await onStage?.call(RestoreStage.notes, n);

    final p = await _downloadPhotos(userId);
    await onStage?.call(RestoreStage.photos, p);

    await settings.setLastPull(userId, changes.serverTime);
    await settings.setLastSynced(userId, DateTime.now());
    await settings.setRestoreDone(userId);
    DataEvents.notify();
  }



  int _priority(String type) => switch (type) {
        SyncEntityType.customer => 0,
        SyncEntityType.site => 1,
        _ => 2,
      };

  int _compare(SyncQueueItem a, SyncQueueItem b) {
    int key(SyncQueueItem i) => i.operation == SyncOperation.delete
        ? 10 + (2 - _priority(i.entityType)) // children are deleted first
        : _priority(i.entityType);
    final byKey = key(a).compareTo(key(b));
    return byKey != 0 ? byKey : (a.id ?? 0).compareTo(b.id ?? 0);
  }

  bool _dependsOnFailed(SyncQueueItem item, Set<String> failedIds) {
    if (failedIds.isEmpty || item.operation == SyncOperation.delete) return false;
    try {
      final p = jsonDecode(item.payload) as Map<String, dynamic>;
      final parent = item.entityType == SyncEntityType.site
          ? p['customerId']
          : item.entityType == SyncEntityType.fieldNote
              ? p['siteId']
              : null;
      return parent != null && failedIds.contains(parent);
    } catch (_) {
      return false;
    }
  }

  SyncTableDataSource _table(String entityType) => switch (entityType) {
        SyncEntityType.customer => customers,
        SyncEntityType.site => sites,
        _ => notes,
      };

  Future<void> _pushItem(SyncQueueItem item) async {
    await remote.push(item);

    if (item.entityType == SyncEntityType.fieldNote &&
        item.operation != SyncOperation.delete) {
      final p = jsonDecode(item.payload) as Map<String, dynamic>;
      final photoPath = p['photoPath'] as String?;

      if (photoPath != null && File(photoPath).existsSync()) {
        final url = await remote.uploadPhoto(item.entityId, photoPath);
        if (url != null) await notes.setPhotoUrl(item.entityId, url);
      } else if (p['removePhoto'] == true) {
        await remote.deletePhoto(item.entityId);
        await notes.setPhotoUrl(item.entityId, null);
      }
    }
  }

  Future<void> _onSuccess(SyncQueueItem item) async {
    final db = await helper.database;
    await db.transaction((txn) async {
      await queue.remove(txn, item.id!);
      final stillOpen =
          await queue.hasOpenItems(txn, item.entityType, item.entityId);
      if (!stillOpen) {
        await _table(item.entityType)
            .setSyncStatus(item.entityId, SyncStatus.synced, ex: txn);
      }
    });
  }

  Future<void> _onFailure(SyncQueueItem item, String message) async {
    await queue.markFailed(item.id!, message);
    await _table(item.entityType)
        .setSyncStatus(item.entityId, SyncStatus.syncFailed);
  }



  Future<int> _applyCustomers(String userId, List<Map<String, dynamic>> list) async {
    final db = await helper.database;
    var applied = 0;
    await db.transaction((txn) async {
      for (final j in list) {
        final id = j['id'].toString();
        final status = await customers.getSyncStatus(id, ex: txn);
        if (status != null && status != SyncStatus.synced) continue;

        final deletedAt = j['deletedAt'] as String?;
        if (deletedAt != null) {
          if (status != null) {
            await customers.softDeleteMany(txn, [id], deletedAt,
                syncStatus: SyncStatus.synced);
          }
          continue;
        }
        await customers.upsert(txn, CustomerLocal.fromServer(j, userId));
        applied++;
      }
    });
    return applied;
  }

  Future<int> _applySites(List<Map<String, dynamic>> list) async {
    final db = await helper.database;
    var applied = 0;
    await db.transaction((txn) async {
      for (final j in list) {
        final id = j['id'].toString();
        final status = await sites.getSyncStatus(id, ex: txn);
        if (status != null && status != SyncStatus.synced) continue;

        final deletedAt = j['deletedAt'] as String?;
        if (deletedAt != null) {
          if (status != null) {
            await sites.softDeleteMany(txn, [id], deletedAt,
                syncStatus: SyncStatus.synced);
          }
          continue;
        }
        final site = SiteLocal.fromServer(j);
        if (!await customers.exists(site.customerId, ex: txn)) continue;
        await sites.upsert(txn, site);
        applied++;
      }
    });
    return applied;
  }

  Future<int> _applyNotes(List<Map<String, dynamic>> list) async {
    final db = await helper.database;
    var applied = 0;
    final orphanFiles = <String>[];

    await db.transaction((txn) async {
      for (final j in list) {
        final id = j['id'].toString();
        final existing = await notes.getById(id, includeDeleted: true, ex: txn);
        if (existing != null && existing.syncStatus != SyncStatus.synced) continue;

        final deletedAt = j['deletedAt'] as String?;
        if (deletedAt != null) {
          if (existing != null) {
            await notes.softDeleteMany(txn, [id], deletedAt,
                syncStatus: SyncStatus.synced);
            if (existing.photoPath != null) orphanFiles.add(existing.photoPath!);
          }
          continue;
        }

        final note = FieldNoteLocal.fromServer(j, existing: existing);
        if (!await sites.exists(note.siteId, ex: txn)) continue;
        if (existing?.photoPath != null && note.photoPath == null) {
          orphanFiles.add(existing!.photoPath!);
        }
        await notes.upsert(txn, note);
        applied++;
      }
    });

    await photos.deleteAll(orphanFiles);
    return applied;
  }

  Future<int> _downloadPhotos(String userId) async {
    final missing = await notes.missingPhotos(userId);
    var downloaded = 0;
    for (final note in missing) {
      try {
        final bytes = await remote.downloadPhoto(note.id);
        if (bytes == null) continue;
        final path = await photos.saveBytes(note.id, bytes);
        await notes.setPhotoPath(note.id, path);
        downloaded++;
      } on NetworkException {
        rethrow;
      } on AuthExpiredException {
        rethrow;
      } catch (_) {

      }
    }
    return downloaded;
  }
}

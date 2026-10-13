import 'dart:convert';

import '../../core/core.dart';
import '../../services/photo_storage.dart';
import '../local/data_sources/customer_local_data_source.dart';
import '../local/data_sources/field_note_local_data_source.dart';
import '../local/data_sources/site_local_data_source.dart';
import '../local/data_sources/sync_queue_local_data_source.dart';
import '../local/database/database_helper.dart';
import '../models/site_local.dart';
import '../models/sync_queue_item.dart';
import '../models/views.dart';
import 'data_events.dart';

class SiteRepository {
  SiteRepository({
    required this.helper,
    required this.customers,
    required this.sites,
    required this.notes,
    required this.queue,
    required this.photos,
  });

  final DatabaseHelper helper;
  final CustomerLocalDataSource customers;
  final SiteLocalDataSource sites;
  final FieldNoteLocalDataSource notes;
  final SyncQueueLocalDataSource queue;
  final PhotoStorage photos;

  Future<List<SiteView>> list(
    String userId, {
    String? customerId,
    String query = '',
  }) =>
      sites.listViews(userId, customerId: customerId, query: query);

  Future<SiteView?> getView(String id) => sites.getView(id);

  Future<SiteLocal?> getById(String id) => sites.getById(id);

  Future<int> count(String userId) => sites.count(userId);

  Future<DeleteImpact> deleteImpact(String siteId) async {
    final v = await sites.getView(siteId);
    return DeleteImpact(notes: v?.noteCount ?? 0);
  }

  Future<SiteLocal> create(String userId, SiteDraft d) async {
    final now = nowIso();
    final s = SiteLocal(
      id: newUuid(),
      customerId: d.customerId,
      siteName: d.name.trim(),
      address: blankToNull(d.address),
      latitude: d.latitude,
      longitude: d.longitude,
      createdAt: now,
      updatedAt: now,
      syncStatus: SyncStatus.pendingCreate,
    );

    final db = await helper.database;
    await db.transaction((txn) async {
      await sites.upsert(txn, s);
      await queue.enqueueUpsert(
        txn,
        SyncQueueItem(
          userId: userId,
          entityType: SyncEntityType.site,
          entityId: s.id,
          operation: SyncOperation.create,
          payload: jsonEncode(s.toApiPayload()),
          createdAt: now,
        ),
      );
    });

    DataEvents.notify();
    return s;
  }

  Future<void> update(String userId, SiteLocal existing, SiteDraft d) async {
    final now = nowIso();
    final db = await helper.database;

    await db.transaction((txn) async {
      final draft = SiteLocal(
        id: existing.id,
        customerId: d.customerId,
        siteName: d.name.trim(),
        address: blankToNull(d.address),
        latitude: d.latitude,
        longitude: d.longitude,
        createdAt: existing.createdAt,
        updatedAt: now,
      );

      final op = await queue.enqueueUpsert(
        txn,
        SyncQueueItem(
          userId: userId,
          entityType: SyncEntityType.site,
          entityId: existing.id,
          operation: SyncOperation.update,
          payload: jsonEncode(draft.toApiPayload()),
          createdAt: now,
        ),
      );

      await sites.upsert(
        txn,
        SiteLocal(
          id: draft.id,
          customerId: draft.customerId,
          siteName: draft.siteName,
          address: draft.address,
          latitude: draft.latitude,
          longitude: draft.longitude,
          createdAt: draft.createdAt,
          updatedAt: draft.updatedAt,
          syncStatus: op == SyncOperation.create
              ? SyncStatus.pendingCreate
              : SyncStatus.pendingUpdate,
        ),
      );
    });

    DataEvents.notify();
  }

  /// Deletes the site with its notes.
  Future<void> delete(String userId, SiteLocal s) async {
    final now = nowIso();
    final db = await helper.database;
    var photoPaths = <String>[];

    await db.transaction((txn) async {
      final noteIds = await notes.idsBySites(txn, [s.id]);
      photoPaths = await notes.photoPathsByIds(txn, noteIds);

      await queue.removeForEntities(txn, SyncEntityType.fieldNote, noteIds);
      await notes.softDeleteMany(txn, noteIds, now, syncStatus: SyncStatus.synced);

      final neverSynced =
          await queue.hasPendingCreate(txn, SyncEntityType.site, s.id);
      if (neverSynced) {
        await queue.removeForEntities(txn, SyncEntityType.site, [s.id]);
        await sites.softDeleteMany(txn, [s.id], now, syncStatus: SyncStatus.synced);
      } else {
        await queue.enqueueDelete(
          txn,
          SyncQueueItem(
            userId: userId,
            entityType: SyncEntityType.site,
            entityId: s.id,
            operation: SyncOperation.delete,
            payload: jsonEncode({'id': s.id, 'customerId': s.customerId}),
            createdAt: now,
          ),
        );
        await sites.softDeleteMany(txn, [s.id], now,
            syncStatus: SyncStatus.pendingDelete);
      }
    });

    await photos.deleteAll(photoPaths);
    DataEvents.notify();
  }
}

import 'dart:convert';

import '../../core/core.dart';
import '../../services/photo_storage.dart';
import '../local/data_sources/field_note_local_data_source.dart';
import '../local/data_sources/sync_queue_local_data_source.dart';
import '../local/database/database_helper.dart';
import '../models/field_note_local.dart';
import '../models/note_status.dart';
import '../models/sync_queue_item.dart';
import '../models/views.dart';
import 'data_events.dart';

class FieldNoteRepository {
  FieldNoteRepository({
    required this.helper,
    required this.notes,
    required this.queue,
    required this.photos,
  });

  final DatabaseHelper helper;
  final FieldNoteLocalDataSource notes;
  final SyncQueueLocalDataSource queue;
  final PhotoStorage photos;

  Future<List<NoteView>> search(
    String userId, {
    String query = '',
    NoteStatus? status,
    String? siteId,
    int? limit,
  }) =>
      notes.search(userId, query: query, status: status, siteId: siteId, limit: limit);

  Future<NoteView?> getView(String id) => notes.getView(id);

  Future<int> count(String userId) => notes.count(userId);

  Future<FieldNoteLocal> create(String userId, NoteDraft d) async {
    final now = nowIso();
    final n = FieldNoteLocal(
      id: newUuid(),
      siteId: d.siteId,
      title: d.title.trim(),
      description: blankToNull(d.description),
      status: d.status,
      noteDatetime: d.noteDatetime.toUtc().toIso8601String(),
      latitude: d.latitude,
      longitude: d.longitude,
      photoPath: d.photoPath,
      createdAt: now,
      updatedAt: now,
      syncStatus: SyncStatus.pendingCreate,
    );

    final payload = n.toApiPayload();
    if (d.photoPath != null) payload['photoPath'] = d.photoPath;

    final db = await helper.database;
    await db.transaction((txn) async {
      await notes.upsert(txn, n);
      await queue.enqueueUpsert(
        txn,
        SyncQueueItem(
          userId: userId,
          entityType: SyncEntityType.fieldNote,
          entityId: n.id,
          operation: SyncOperation.create,
          payload: jsonEncode(payload),
          createdAt: now,
        ),
      );
    });

    DataEvents.notify();
    return n;
  }

  Future<void> update(String userId, FieldNoteLocal existing, NoteDraft d) async {
    final now = nowIso();
    final db = await helper.database;

    var photoPath = existing.photoPath;
    var photoUrl = existing.photoUrl;
    String? oldFileToDelete;

    final base = FieldNoteLocal(
      id: existing.id,
      siteId: d.siteId,
      title: d.title.trim(),
      description: blankToNull(d.description),
      status: d.status,
      noteDatetime: d.noteDatetime.toUtc().toIso8601String(),
      latitude: d.latitude,
      longitude: d.longitude,
      createdAt: existing.createdAt,
      updatedAt: now,
    );
    final payload = base.toApiPayload();

    if (d.photoChanged) {
      if (existing.photoPath != null && existing.photoPath != d.photoPath) {
        oldFileToDelete = existing.photoPath;
      }
      if (d.photoPath != null) {
        photoPath = d.photoPath;
        payload['photoPath'] = d.photoPath;
      } else {
        photoPath = null;
        photoUrl = null;
        payload['removePhoto'] = true;
      }
    }

    await db.transaction((txn) async {
      final op = await queue.enqueueUpsert(
        txn,
        SyncQueueItem(
          userId: userId,
          entityType: SyncEntityType.fieldNote,
          entityId: existing.id,
          operation: SyncOperation.update,
          payload: jsonEncode(payload),
          createdAt: now,
        ),
      );

      await notes.upsert(
        txn,
        FieldNoteLocal(
          id: base.id,
          siteId: base.siteId,
          title: base.title,
          description: base.description,
          status: base.status,
          noteDatetime: base.noteDatetime,
          latitude: base.latitude,
          longitude: base.longitude,
          photoUrl: photoUrl,
          photoPath: photoPath,
          createdAt: base.createdAt,
          updatedAt: base.updatedAt,
          syncStatus: op == SyncOperation.create
              ? SyncStatus.pendingCreate
              : SyncStatus.pendingUpdate,
        ),
      );
    });

    await photos.delete(oldFileToDelete);
    DataEvents.notify();
  }

  Future<void> delete(String userId, FieldNoteLocal n) async {
    final now = nowIso();
    final db = await helper.database;

    await db.transaction((txn) async {
      final neverSynced =
          await queue.hasPendingCreate(txn, SyncEntityType.fieldNote, n.id);
      if (neverSynced) {
        await queue.removeForEntities(txn, SyncEntityType.fieldNote, [n.id]);
        await notes.softDeleteMany(txn, [n.id], now, syncStatus: SyncStatus.synced);
      } else {
        await queue.enqueueDelete(
          txn,
          SyncQueueItem(
            userId: userId,
            entityType: SyncEntityType.fieldNote,
            entityId: n.id,
            operation: SyncOperation.delete,
            payload: jsonEncode({'id': n.id, 'siteId': n.siteId}),
            createdAt: now,
          ),
        );
        await notes.softDeleteMany(txn, [n.id], now,
            syncStatus: SyncStatus.pendingDelete);
      }
    });

    await photos.delete(n.photoPath);
    DataEvents.notify();
  }
}

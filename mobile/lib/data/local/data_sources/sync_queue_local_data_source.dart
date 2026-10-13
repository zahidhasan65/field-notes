import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../../core/core.dart';
import '../../models/sync_queue_item.dart';
import '../database/database_helper.dart';

/// The outbox: every offline change waits here until it reached the server.
///
/// Collapsing rules (one open item per entity):
///   CREATE + UPDATE -> CREATE (latest data)
///   CREATE + DELETE -> nothing (the server never saw it)
///   UPDATE + UPDATE -> UPDATE
///   UPDATE + DELETE -> DELETE
class SyncQueueLocalDataSource {
  SyncQueueLocalDataSource(this.helper);

  final DatabaseHelper helper;

  Future<DatabaseExecutor> _ex(DatabaseExecutor? ex) async =>
      ex ?? await helper.database;

  /// Adds / merges a CREATE or UPDATE. Returns the operation that is now queued.
  Future<String> enqueueUpsert(DatabaseExecutor ex, SyncQueueItem item) async {
    final open = await ex.query(
      'sync_queue',
      where: 'entity_type = ? AND entity_id = ? AND status != ?',
      whereArgs: [item.entityType, item.entityId, SyncQueueStatus.processing],
      orderBy: 'id ASC',
      limit: 1,
    );

    if (open.isEmpty) {
      await ex.insert('sync_queue', item.toMap());
      return item.operation;
    }

    final existing = SyncQueueItem.fromMap(open.first);
    final effective = existing.operation == SyncOperation.create
        ? SyncOperation.create
        : item.operation;

    await ex.update(
      'sync_queue',
      {
        'operation': effective,
        'payload': _mergePayload(existing.payload, item.payload),
        'status': SyncQueueStatus.pending,
        'retry_count': 0,
        'error_message': null,
      },
      where: 'id = ?',
      whereArgs: [existing.id],
    );
    return effective;
  }

  /// Replaces open items of the entity with one DELETE.
  Future<void> enqueueDelete(DatabaseExecutor ex, SyncQueueItem item) async {
    await ex.delete(
      'sync_queue',
      where: 'entity_type = ? AND entity_id = ? AND status != ?',
      whereArgs: [item.entityType, item.entityId, SyncQueueStatus.processing],
    );
    await ex.insert('sync_queue', item.toMap());
  }

  Future<bool> hasPendingCreate(
      DatabaseExecutor ex, String entityType, String entityId) async {
    final rows = await ex.query(
      'sync_queue',
      columns: ['id'],
      where: 'entity_type = ? AND entity_id = ? AND operation = ?',
      whereArgs: [entityType, entityId, SyncOperation.create],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<void> removeForEntities(
      DatabaseExecutor ex, String entityType, List<String> ids) async {
    if (ids.isEmpty) return;
    final marks = List.filled(ids.length, '?').join(',');
    await ex.delete(
      'sync_queue',
      where: 'entity_type = ? AND entity_id IN ($marks)',
      whereArgs: [entityType, ...ids],
    );
  }

  /// Items to send now: pending ones + failed ones that can still be retried.
  Future<List<SyncQueueItem>> getRunnable(String userId) async {
    final db = await helper.database;
    final rows = await db.query(
      'sync_queue',
      where: 'user_id = ? AND (status = ? OR (status = ? AND retry_count < ?))',
      whereArgs: [
        userId,
        SyncQueueStatus.pending,
        SyncQueueStatus.failed,
        SyncLimits.maxRetries,
      ],
      orderBy: 'id ASC',
    );
    return rows.map(SyncQueueItem.fromMap).toList();
  }

  Future<void> markProcessing(int id) async {
    final db = await helper.database;
    await db.update(
      'sync_queue',
      {'status': SyncQueueStatus.processing, 'last_attempt_at': nowIso()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Back to PENDING without counting a retry (offline / session problems).
  Future<void> markPendingAgain(int id) async {
    final db = await helper.database;
    await db.update('sync_queue', {'status': SyncQueueStatus.pending},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> markFailed(int id, String message) async {
    final db = await helper.database;
    await db.rawUpdate(
      'UPDATE sync_queue SET status = ?, retry_count = retry_count + 1, '
      'error_message = ?, last_attempt_at = ? WHERE id = ?',
      [SyncQueueStatus.failed, message, nowIso(), id],
    );
  }

  Future<void> remove(DatabaseExecutor ex, int id) async {
    await ex.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  /// true when something else is still waiting for this entity.
  Future<bool> hasOpenItems(
      DatabaseExecutor ex, String entityType, String entityId) async {
    final rows = await ex.query(
      'sync_queue',
      columns: ['id'],
      where: 'entity_type = ? AND entity_id = ?',
      whereArgs: [entityType, entityId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  /// FAILED -> PENDING (user pressed retry).
  Future<void> resetFailed(String userId) async {
    final db = await helper.database;
    await db.update(
      'sync_queue',
      {'status': SyncQueueStatus.pending, 'retry_count': 0, 'error_message': null},
      where: 'user_id = ? AND status = ?',
      whereArgs: [userId, SyncQueueStatus.failed],
    );
  }

  /// After a crash some items can be stuck in PROCESSING.
  Future<void> resetStuckProcessing(String userId) async {
    final db = await helper.database;
    await db.update(
      'sync_queue',
      {'status': SyncQueueStatus.pending},
      where: 'user_id = ? AND status = ?',
      whereArgs: [userId, SyncQueueStatus.processing],
    );
  }

  Future<int> pendingCount(String userId) async {
    final db = await helper.database;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM sync_queue WHERE user_id = ? AND status != ?',
      [userId, SyncQueueStatus.failed],
    );
    return (rows.first['c'] as int?) ?? 0;
  }

  Future<int> failedCount(String userId) async {
    final db = await helper.database;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM sync_queue WHERE user_id = ? AND status = ?',
      [userId, SyncQueueStatus.failed],
    );
    return (rows.first['c'] as int?) ?? 0;
  }

  /// Keeps photo instructions ("photoPath" / "removePhoto") of an older queued
  /// change when the newer payload does not mention the photo.
  String _mergePayload(String oldJson, String newJson) {
    try {
      final oldMap = jsonDecode(oldJson) as Map<String, dynamic>;
      final newMap = jsonDecode(newJson) as Map<String, dynamic>;
      final newHasPhotoInfo =
          newMap.containsKey('photoPath') || newMap.containsKey('removePhoto');
      if (!newHasPhotoInfo) {
        for (final key in ['photoPath', 'removePhoto']) {
          if (oldMap.containsKey(key)) newMap[key] = oldMap[key];
        }
      }
      return jsonEncode(newMap);
    } catch (_) {
      return newJson;
    }
  }
}

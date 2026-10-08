import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/sync_queue_item.dart';

class SyncQueueLocalDataSource {
  final DatabaseHelper databaseHelper;

  SyncQueueLocalDataSource({
    DatabaseHelper? databaseHelper,
  }) : databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  Future<void> addToQueue(SyncQueueItem item) async {
    final db = await databaseHelper.database;

    await db.insert(
      'sync_queue',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<SyncQueueItem>> getPendingItems() async {
    final db = await databaseHelper.database;

    final result = await db.query(
      'sync_queue',
      where: 'status = ?',
      whereArgs: ['PENDING'],
      orderBy: 'created_at ASC, id ASC',
    );

    return result.map(SyncQueueItem.fromMap).toList();
  }

  Future<List<SyncQueueItem>> getPendingItemsByEntity(
    String entityType,
    String entityId,
  ) async {
    final db = await databaseHelper.database;

    final result = await db.query(
      'sync_queue',
      where: 'entity_type = ? AND entity_id = ? AND status = ?',
      whereArgs: [entityType, entityId, 'PENDING'],
      orderBy: 'created_at ASC, id ASC',
    );

    return result.map(SyncQueueItem.fromMap).toList();
  }

  Future<void> markProcessing(int id) async {
    final db = await databaseHelper.database;

    await db.update(
      'sync_queue',
      {
        'status': 'PROCESSING',
        'last_attempt_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markFailed(
    int id, {
    required String errorMessage,
  }) async {
    final db = await databaseHelper.database;

    final result = await db.query(
      'sync_queue',
      columns: ['retry_count'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) {
      return;
    }

    final currentRetryCount =
        (result.first['retry_count'] as int?) ?? 0;

    await db.update(
      'sync_queue',
      {
        'status': 'FAILED',
        'retry_count': currentRetryCount + 1,
        'last_attempt_at': DateTime.now().toIso8601String(),
        'error_message': errorMessage,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markPending(int id) async {
    final db = await databaseHelper.database;

    await db.update(
      'sync_queue',
      {
        'status': 'PENDING',
        'error_message': null,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> removeFromQueue(int id) async {
    final db = await databaseHelper.database;

    await db.delete(
      'sync_queue',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> removeEntityOperations(
    String entityType,
    String entityId,
  ) async {
    final db = await databaseHelper.database;

    await db.delete(
      'sync_queue',
      where: 'entity_type = ? AND entity_id = ?',
      whereArgs: [entityType, entityId],
    );
  }
}

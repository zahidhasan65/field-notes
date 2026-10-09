import 'package:sqflite/sqflite.dart';

import '../../../core/constants/sync_constants.dart';
import '../database/database_helper.dart';
import '../models/field_note_local.dart';
import '../models/sync_queue_item.dart';

class FieldNoteLocalDataSource {
  final DatabaseHelper databaseHelper;

  FieldNoteLocalDataSource({DatabaseHelper? databaseHelper})
    : databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  Future<void> insertFieldNote(FieldNoteLocal fieldNote) async {
    final db = await databaseHelper.database;

    await db.insert(
      'field_notes',
      fieldNote.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<FieldNoteLocal?> getFieldNoteById(String id) async {
    final db = await databaseHelper.database;

    final result = await db.query(
      'field_notes',
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return FieldNoteLocal.fromMap(result.first);
  }

  Future<List<FieldNoteLocal>> getFieldNotes(String siteId) async {
    final db = await databaseHelper.database;

    final result = await db.query(
      'field_notes',
      where: 'site_id = ? AND deleted_at IS NULL',
      whereArgs: [siteId],
      orderBy: 'created_at DESC',
    );

    return result.map(FieldNoteLocal.fromMap).toList();
  }

  Future<void> updateFieldNote(FieldNoteLocal fieldNote) async {
    final db = await databaseHelper.database;

    await db.update(
      'field_notes',
      fieldNote.toMap(),
      where: 'id = ?',
      whereArgs: [fieldNote.id],
    );
  }

  Future<void> markAsSynced(String id) async {
    final db = await databaseHelper.database;

    await db.update(
      'field_notes',
      {'sync_status': SyncStatus.synced},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> softDeleteFieldNote(String id, String deletedAt) async {
    final db = await databaseHelper.database;

    await db.update(
      'field_notes',
      {'deleted_at': deletedAt},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> createFieldNoteWithSyncQueue({
    required FieldNoteLocal fieldNote,
    required SyncQueueItem queueItem,
  }) async {
    final db = await databaseHelper.database;

    await db.transaction((txn) async {
      await txn.insert(
        'field_notes',
        fieldNote.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await txn.insert(
        'sync_queue',
        queueItem.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<void> updateFieldNoteWithSyncQueue({
    required FieldNoteLocal fieldNote,
    required SyncQueueItem queueItem,
  }) async {
    final db = await databaseHelper.database;

    await db.transaction((txn) async {
      await txn.update(
        'field_notes',
        fieldNote.toMap(),
        where: 'id = ?',
        whereArgs: [fieldNote.id],
      );

      await txn.insert(
        'sync_queue',
        queueItem.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<void> softDeleteFieldNoteWithSyncQueue({
    required String id,
    required String deletedAt,
    required SyncQueueItem queueItem,
  }) async {
    final db = await databaseHelper.database;

    await db.transaction((txn) async {
      await txn.update(
        'field_notes',
        {
          'deleted_at': deletedAt,
          'sync_status': SyncStatus.pendingDelete,
          'updated_at': deletedAt,
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      await txn.insert(
        'sync_queue',
        queueItem.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<void> markAsSyncFailed(String id) async {
    final db = await databaseHelper.database;
    await db.update(
      'field_notes',
      {'sync_status': SyncStatus.syncFailed},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> restoreFieldNotes(List<FieldNoteLocal> fieldNotes) async {
    final db = await databaseHelper.database;

    await db.transaction((txn) async {
      for (final fieldNote in fieldNotes) {
        await txn.insert(
          'field_notes',
          fieldNote.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }
}

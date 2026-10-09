import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:mobile/core/constants/sync_constants.dart';
import 'package:mobile/data/local/database/database_helper.dart';
import 'package:mobile/data/local/data_sources/field_note_local_data_source.dart';
import 'package:mobile/data/local/models/sync_queue_item.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('field note delete and sync queue should be atomic', () async {
    final db = await DatabaseHelper.instance.database;

    await db.delete('sync_queue');
    await db.delete('field_notes');
    await db.delete('sites');
    await db.delete('customers');
    await db.delete('users');

    await db.insert('users', {
      'id': 'user-1',
      'name': 'Test User',
      'email': 'field-note-delete@test.com',
      'created_at': '2026-01-01T00:00:00Z',
      'updated_at': '2026-01-01T00:00:00Z',
    });

    await db.insert('customers', {
      'id': 'customer-1',
      'user_id': 'user-1',
      'name': 'Test Customer',
      'created_at': '2026-01-01T00:00:00Z',
      'updated_at': '2026-01-01T00:00:00Z',
      'sync_status': SyncStatus.synced,
    });

    await db.insert('sites', {
      'id': 'site-1',
      'customer_id': 'customer-1',
      'site_name': 'Test Site',
      'address': 'Dhaka',
      'created_at': '2026-01-01T00:00:00Z',
      'updated_at': '2026-01-01T00:00:00Z',
      'sync_status': SyncStatus.synced,
    });

    await db.insert('field_notes', {
      'id': 'note-1',
      'site_id': 'site-1',
      'title': 'Test Note',
      'description': 'To be deleted',
      'latitude': 23.8103,
      'longitude': 90.4125,
      'note_datetime': '2026-01-01T10:00:00Z',
      'status': 'PENDING',
      'photo_url': null,
      'created_at': '2026-01-01T10:00:00Z',
      'updated_at': '2026-01-01T10:00:00Z',
      'deleted_at': null,
      'sync_status': SyncStatus.synced,
    });

    final deletedAt = '2026-01-02T10:00:00Z';

    final queueItem = SyncQueueItem(
      entityType: SyncEntityType.fieldNote,
      entityId: 'note-1',
      operation: SyncOperation.delete,
      payload: '{"id":"note-1"}',
      createdAt: deletedAt,
      status: SyncQueueStatus.pending,
    );

    final dataSource = FieldNoteLocalDataSource();

    await dataSource.softDeleteFieldNoteWithSyncQueue(
      id: 'note-1',
      deletedAt: deletedAt,
      queueItem: queueItem,
    );

    final noteResult = await db.query(
      'field_notes',
      where: 'id = ?',
      whereArgs: ['note-1'],
    );

    final queueResult = await db.query(
      'sync_queue',
      where: 'entity_id = ?',
      whereArgs: ['note-1'],
    );

    expect(noteResult.length, 1);
    expect(noteResult.first['deleted_at'], deletedAt);
    expect(noteResult.first['sync_status'], SyncStatus.pendingDelete);

    expect(queueResult.length, 1);
    expect(queueResult.first['entity_type'], SyncEntityType.fieldNote);
    expect(queueResult.first['operation'], SyncOperation.delete);
  });
}

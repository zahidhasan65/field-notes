import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:mobile/core/constants/sync_constants.dart';
import 'package:mobile/data/local/database/database_helper.dart';
import 'package:mobile/data/local/data_sources/field_note_local_data_source.dart';
import 'package:mobile/data/local/models/field_note_local.dart';
import 'package:mobile/data/local/models/sync_queue_item.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('field note update and sync queue should be atomic', () async {
    final db = await DatabaseHelper.instance.database;

    await db.delete('sync_queue');
    await db.delete('field_notes');
    await db.delete('sites');
    await db.delete('customers');
    await db.delete('users');

    await db.insert('users', {
      'id': 'user-1',
      'name': 'Test User',
      'email': 'field-note-update@test.com',
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
      'title': 'Old Title',
      'description': 'Old Description',
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

    final updatedNote = FieldNoteLocal(
      id: 'note-1',
      siteId: 'site-1',
      title: 'Updated Title',
      description: 'Updated Description',
      latitude: 23.8103,
      longitude: 90.4125,
      noteDatetime: '2026-01-01T10:00:00Z',
      status: 'COMPLETED',
      photoUrl: null,
      createdAt: '2026-01-01T10:00:00Z',
      updatedAt: '2026-01-02T10:00:00Z',
      deletedAt: null,
      syncStatus: SyncStatus.pendingUpdate,
    );

    final queueItem = SyncQueueItem(
      entityType: SyncEntityType.fieldNote,
      entityId: updatedNote.id,
      operation: SyncOperation.update,
      payload: '{"id":"note-1","title":"Updated Title"}',
      createdAt: '2026-01-02T10:00:00Z',
      status: SyncQueueStatus.pending,
    );

    final dataSource = FieldNoteLocalDataSource();

    await dataSource.updateFieldNoteWithSyncQueue(
      fieldNote: updatedNote,
      queueItem: queueItem,
    );

    final noteResult = await db.query(
      'field_notes',
      where: 'id = ?',
      whereArgs: [updatedNote.id],
    );

    final queueResult = await db.query(
      'sync_queue',
      where: 'entity_id = ?',
      whereArgs: [updatedNote.id],
    );

    expect(noteResult.length, 1);
    expect(noteResult.first['title'], 'Updated Title');
    expect(noteResult.first['description'], 'Updated Description');
    expect(noteResult.first['status'], 'COMPLETED');
    expect(
      noteResult.first['sync_status'],
      SyncStatus.pendingUpdate,
    );

    expect(queueResult.length, 1);
    expect(
      queueResult.first['operation'],
      SyncOperation.update,
    );
  });
}

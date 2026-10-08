import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:mobile/core/constants/sync_constants.dart';
import 'package:mobile/data/local/database/database_helper.dart';
import 'package:mobile/data/local/data_sources/site_local_data_source.dart';
import 'package:mobile/data/local/models/site_local.dart';
import 'package:mobile/data/local/models/sync_queue_item.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('site delete and sync queue should be atomic', () async {
    final db = await DatabaseHelper.instance.database;

    await db.insert('users', {
      'id': 'site-delete-user-1',
      'name': 'Test User',
      'email': 'site-delete@test.com',
      'created_at': '2026-01-01T00:00:00Z',
      'updated_at': '2026-01-01T00:00:00Z',
    });

    await db.insert('customers', {
      'id': 'site-delete-customer-1',
      'user_id': 'site-delete-user-1',
      'name': 'Test Customer',
      'created_at': '2026-01-01T00:00:00Z',
      'updated_at': '2026-01-01T00:00:00Z',
      'sync_status': SyncStatus.synced,
    });

    final site = SiteLocal(
      id: 'site-delete-site-1',
      customerId: 'site-delete-customer-1',
      siteName: 'Test Site',
      address: 'Dhaka',
      createdAt: '2026-01-01T00:00:00Z',
      updatedAt: '2026-01-01T00:00:00Z',
      syncStatus: SyncStatus.synced,
    );

    await db.insert('sites', site.toMap());

    final deletedAt = DateTime.parse('2026-01-02T00:00:00Z');

    final queueItem = SyncQueueItem(
      entityType: SyncEntityType.site,
      entityId: site.id,
      operation: SyncOperation.delete,
      payload: '{"id":"site-1"}',
      createdAt: deletedAt.toIso8601String(),
      status: SyncQueueStatus.pending,
    );

    final dataSource = SiteLocalDataSource();

    await dataSource.softDeleteSiteWithSyncQueue(
      id: site.id,
      deletedAt: deletedAt.toIso8601String(),
      queueItem: queueItem,
    );

    final siteResult = await db.query(
      'sites',
      where: 'id = ?',
      whereArgs: [site.id],
    );

    final queueResult = await db.query(
      'sync_queue',
      where: 'entity_id = ?',
      whereArgs: [site.id],
    );

    expect(siteResult.length, 1);
    expect(siteResult.first['deleted_at'], deletedAt.toIso8601String());
    expect(
      siteResult.first['sync_status'],
      SyncStatus.pendingDelete,
    );

    expect(queueResult.length, 1);
    expect(queueResult.first['operation'], SyncOperation.delete);
    expect(queueResult.first['entity_type'], SyncEntityType.site);
  });
}





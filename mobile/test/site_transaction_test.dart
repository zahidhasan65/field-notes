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

  test('site create and sync queue are saved together', () async {
    final db = await DatabaseHelper.instance.database;

    await db.delete('sync_queue');
    await db.delete('field_notes');
    await db.delete('sites');
    await db.delete('customers');
    await db.delete('users');

    final userId = 'user-site-test';
    final customerId = 'customer-site-test';
    final siteId = 'site-test-1';

    final now = DateTime.now().toUtc().toIso8601String();

    await db.insert('users', {
      'id': userId,
      'name': 'Test User',
      'email': 'site-test@example.com',
      'created_at': now,
      'updated_at': now,
    });

    await db.insert('customers', {
      'id': customerId,
      'user_id': userId,
      'name': 'Test Customer',
      'contact_information': null,
      'created_at': now,
      'updated_at': now,
      'deleted_at': null,
      'sync_status': SyncStatus.synced,
    });

    final site = SiteLocal(
      id: siteId,
      customerId: customerId,
      siteName: 'Test Site',
      address: 'Dhaka, Bangladesh',
      createdAt: now,
      updatedAt: now,
      syncStatus: SyncStatus.pendingCreate,
    );

    final queueItem = SyncQueueItem(
      entityType: SyncEntityType.site,
      entityId: siteId,
      operation: SyncOperation.create,
      payload: '{"id":"$siteId","site_name":"Test Site"}',
      createdAt: now,
      status: SyncQueueStatus.pending,
    );

    final dataSource = SiteLocalDataSource();

    await dataSource.createSiteWithSyncQueue(site: site, queueItem: queueItem);

    final siteResult = await db.query(
      'sites',
      where: 'id = ?',
      whereArgs: [siteId],
    );

    final queueResult = await db.query(
      'sync_queue',
      where: 'entity_id = ?',
      whereArgs: [siteId],
    );

    expect(siteResult.length, 1);
    expect(siteResult.first['site_name'], 'Test Site');
    expect(siteResult.first['sync_status'], SyncStatus.pendingCreate);

    expect(queueResult.length, 1);
    expect(queueResult.first['operation'], SyncOperation.create);
    expect(queueResult.first['status'], SyncQueueStatus.pending);

    await db.delete('sync_queue', where: 'entity_id = ?', whereArgs: [siteId]);

    await db.delete('sites', where: 'id = ?', whereArgs: [siteId]);

    await db.delete('customers', where: 'id = ?', whereArgs: [customerId]);

    await db.delete('users', where: 'id = ?', whereArgs: [userId]);
  });
}

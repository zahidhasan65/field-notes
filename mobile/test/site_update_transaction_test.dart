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

  test('site update and sync queue are saved together', () async {
    final db = await DatabaseHelper.instance.database;

    await db.delete('sync_queue');
    await db.delete('field_notes');
    await db.delete('sites');
    await db.delete('customers');
    await db.delete('users');

    final userId = 'user-site-update';
    final customerId = 'customer-site-update';
    final siteId = 'site-update-test';

    final createdAt = DateTime.now().toUtc().toIso8601String();

    await db.insert('users', {
      'id': userId,
      'name': 'Test User',
      'email': 'site-update@example.com',
      'created_at': createdAt,
      'updated_at': createdAt,
    });

    await db.insert('customers', {
      'id': customerId,
      'user_id': userId,
      'name': 'Test Customer',
      'contact_information': null,
      'created_at': createdAt,
      'updated_at': createdAt,
      'deleted_at': null,
      'sync_status': SyncStatus.synced,
    });

    await db.insert('sites', {
      'id': siteId,
      'customer_id': customerId,
      'site_name': 'Old Site Name',
      'address': 'Old Address',
      'created_at': createdAt,
      'updated_at': createdAt,
      'deleted_at': null,
      'sync_status': SyncStatus.synced,
    });

    final updatedAt = DateTime.now().toUtc().toIso8601String();

    final site = SiteLocal(
      id: siteId,
      customerId: customerId,
      siteName: 'Updated Site Name',
      address: 'New Address',
      createdAt: createdAt,
      updatedAt: updatedAt,
      syncStatus: SyncStatus.pendingUpdate,
    );

    final queueItem = SyncQueueItem(
      entityType: SyncEntityType.site,
      entityId: siteId,
      operation: SyncOperation.update,
      payload: '{"id":"$siteId","site_name":"Updated Site Name"}',
      createdAt: updatedAt,
      status: SyncQueueStatus.pending,
    );

    final dataSource = SiteLocalDataSource();

    await dataSource.updateSiteWithSyncQueue(site: site, queueItem: queueItem);

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
    expect(siteResult.first['site_name'], 'Updated Site Name');
    expect(siteResult.first['address'], 'New Address');
    expect(siteResult.first['sync_status'], SyncStatus.pendingUpdate);

    expect(queueResult.length, 1);
    expect(queueResult.first['operation'], SyncOperation.update);
    expect(queueResult.first['status'], SyncQueueStatus.pending);

    await db.delete('sync_queue', where: 'entity_id = ?', whereArgs: [siteId]);

    await db.delete('sites', where: 'id = ?', whereArgs: [siteId]);

    await db.delete('customers', where: 'id = ?', whereArgs: [customerId]);

    await db.delete('users', where: 'id = ?', whereArgs: [userId]);
  });
}

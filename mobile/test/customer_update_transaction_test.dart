import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:mobile/core/constants/sync_constants.dart';
import 'package:mobile/data/local/database/database_helper.dart';
import 'package:mobile/data/local/data_sources/customer_local_data_source.dart';
import 'package:mobile/data/local/models/customer_local.dart';
import 'package:mobile/data/local/models/sync_queue_item.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('customer update and sync queue are saved together', () async {
    final db = await DatabaseHelper.instance.database;

    await db.delete('sync_queue');
    await db.delete('customers');
    await db.delete('users');

    final userId = 'user-update-test';
    final customerId = 'customer-update-test';

    final createdAt = DateTime.now()
        .toUtc()
        .toIso8601String();

    await db.insert('users', {
      'id': userId,
      'name': 'Test User',
      'email': 'update-test@example.com',
      'created_at': createdAt,
      'updated_at': createdAt,
    });

    await db.insert('customers', {
      'id': customerId,
      'user_id': userId,
      'name': 'Old Customer Name',
      'contact_information': '01700000000',
      'created_at': createdAt,
      'updated_at': createdAt,
      'deleted_at': null,
      'sync_status': SyncStatus.synced,
    });

    final updatedAt = DateTime.now()
        .toUtc()
        .toIso8601String();

    final customer = CustomerLocal(
      id: customerId,
      userId: userId,
      name: 'Updated Customer Name',
      contactInformation: '01800000000',
      createdAt: createdAt,
      updatedAt: updatedAt,
      syncStatus: SyncStatus.pendingUpdate,
    );

    final queueItem = SyncQueueItem(
      entityType: SyncEntityType.customer,
      entityId: customerId,
      operation: SyncOperation.update,
      payload: '{"id":"$customerId","name":"Updated Customer Name"}',
      createdAt: updatedAt,
      status: SyncQueueStatus.pending,
    );

    final dataSource = CustomerLocalDataSource();

    await dataSource.updateCustomerWithSyncQueue(
      customer: customer,
      queueItem: queueItem,
    );

    final customerResult = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [customerId],
    );

    final queueResult = await db.query(
      'sync_queue',
      where: 'entity_id = ?',
      whereArgs: [customerId],
    );

    expect(customerResult.length, 1);
    expect(
      customerResult.first['name'],
      'Updated Customer Name',
    );
    expect(
      customerResult.first['sync_status'],
      SyncStatus.pendingUpdate,
    );

    expect(queueResult.length, 1);
    expect(
      queueResult.first['operation'],
      SyncOperation.update,
    );
    expect(
      queueResult.first['status'],
      SyncQueueStatus.pending,
    );

    await db.delete(
      'sync_queue',
      where: 'entity_id = ?',
      whereArgs: [customerId],
    );

    await db.delete(
      'customers',
      where: 'id = ?',
      whereArgs: [customerId],
    );

    await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );

    await db.close();
  });
}

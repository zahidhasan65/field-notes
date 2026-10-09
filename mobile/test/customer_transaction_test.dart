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

  test('customer create and sync queue are saved together', () async {
    final db = await DatabaseHelper.instance.database;

    await db.delete('sync_queue');
    await db.delete('field_notes');
    await db.delete('sites');
    await db.delete('customers');
    await db.delete('users');

    final userId = 'user-test-1';
    final customerId = 'customer-test-1';
    final now = DateTime.now().toUtc().toIso8601String();

    await db.insert('users', {
      'id': userId,
      'name': 'Test User',
      'email': 'test@example.com',
      'created_at': now,
      'updated_at': now,
    });

    final customer = CustomerLocal(
      id: customerId,
      userId: userId,
      name: 'Test Customer',
      contactInformation: '01700000000',
      createdAt: now,
      updatedAt: now,
      syncStatus: SyncStatus.pendingCreate,
    );

    final queueItem = SyncQueueItem(
      entityType: SyncEntityType.customer,
      entityId: customerId,
      operation: SyncOperation.create,
      payload: '{"id":"$customerId","name":"Test Customer"}',
      createdAt: now,
      status: SyncQueueStatus.pending,
    );

    final dataSource = CustomerLocalDataSource();

    await dataSource.createCustomerWithSyncQueue(
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
    expect(customerResult.first['name'], 'Test Customer');
    expect(customerResult.first['sync_status'], SyncStatus.pendingCreate);

    expect(queueResult.length, 1);
    expect(queueResult.first['operation'], SyncOperation.create);
    expect(queueResult.first['status'], SyncQueueStatus.pending);

    await db.delete(
      'sync_queue',
      where: 'entity_id = ?',
      whereArgs: [customerId],
    );

    await db.delete('customers', where: 'id = ?', whereArgs: [customerId]);

    await db.delete('users', where: 'id = ?', whereArgs: [userId]);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:mobile/core/constants/sync_constants.dart';
import 'package:mobile/data/local/database/database_helper.dart';
import 'package:mobile/data/local/data_sources/customer_local_data_source.dart';
import 'package:mobile/data/local/models/sync_queue_item.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('customer soft delete and sync queue are saved together', () async {
    final db = await DatabaseHelper.instance.database;

    await db.delete('sync_queue');
    await db.delete('field_notes');
    await db.delete('sites');
    await db.delete('customers');
    await db.delete('users');

    final userId = 'user-delete-test';
    final customerId = 'customer-delete-test';

    final createdAt = DateTime.now().toUtc().toIso8601String();

    await db.insert('users', {
      'id': userId,
      'name': 'Test User',
      'email': 'delete-test@example.com',
      'created_at': createdAt,
      'updated_at': createdAt,
    });

    await db.insert('customers', {
      'id': customerId,
      'user_id': userId,
      'name': 'Customer To Delete',
      'contact_information': '01700000000',
      'created_at': createdAt,
      'updated_at': createdAt,
      'deleted_at': null,
      'sync_status': SyncStatus.synced,
    });

    final deletedAt = DateTime.now().toUtc().toIso8601String();

    final queueItem = SyncQueueItem(
      entityType: SyncEntityType.customer,
      entityId: customerId,
      operation: SyncOperation.delete,
      payload: '{"id":"$customerId"}',
      createdAt: deletedAt,
      status: SyncQueueStatus.pending,
    );

    final dataSource = CustomerLocalDataSource();

    await dataSource.softDeleteCustomerWithSyncQueue(
      id: customerId,
      deletedAt: deletedAt,
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
    expect(customerResult.first['deleted_at'], deletedAt);
    expect(customerResult.first['sync_status'], SyncStatus.pendingDelete);

    expect(queueResult.length, 1);
    expect(queueResult.first['operation'], SyncOperation.delete);
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

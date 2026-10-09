import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:mobile/core/constants/sync_constants.dart';
import 'package:mobile/data/local/database/database_helper.dart';
import 'package:mobile/data/local/data_sources/sync_queue_local_data_source.dart';
import 'package:mobile/data/local/models/sync_queue_item.dart';
import 'package:mobile/data/repositories/local_sync_queue_repository.dart';
import 'package:mobile/data/sync/sync_queue_manager.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  Future<void> clearQueue() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('sync_queue');
  }

  SyncQueueItem item({
    required String operation,
    required String entityId,
    required String payload,
    String entityType = SyncEntityType.customer,
  }) {
    return SyncQueueItem(
      entityType: entityType,
      entityId: entityId,
      operation: operation,
      payload: payload,
      createdAt: '2026-01-01T10:00:00Z',
      status: SyncQueueStatus.pending,
    );
  }

  test('CREATE + UPDATE should remain as latest CREATE', () async {
    await clearQueue();

    final repository = LocalSyncQueueRepository(
      localDataSource: SyncQueueLocalDataSource(),
    );

    final manager = SyncQueueManager(queueRepository: repository);

    await manager.enqueue(
      item(
        operation: SyncOperation.create,
        entityId: 'customer-1',
        payload: '{"name":"Old"}',
      ),
    );

    await manager.enqueue(
      item(
        operation: SyncOperation.update,
        entityId: 'customer-1',
        payload: '{"name":"Updated"}',
      ),
    );

    final items = await repository.getPendingItems();

    expect(items.length, 1);
    expect(items.first.operation, SyncOperation.create);
    expect(items.first.payload, '{"name":"Updated"}');
  });

  test('CREATE + DELETE should remove queue item', () async {
    await clearQueue();

    final repository = LocalSyncQueueRepository(
      localDataSource: SyncQueueLocalDataSource(),
    );

    final manager = SyncQueueManager(queueRepository: repository);

    await manager.enqueue(
      item(
        operation: SyncOperation.create,
        entityId: 'customer-2',
        payload: '{"name":"Temporary"}',
      ),
    );

    await manager.enqueue(
      item(
        operation: SyncOperation.delete,
        entityId: 'customer-2',
        payload: '{"id":"customer-2"}',
      ),
    );

    final items = await repository.getPendingItems();

    expect(items.where((item) => item.entityId == 'customer-2').isEmpty, true);
  });

  test('UPDATE + UPDATE should keep latest UPDATE', () async {
    await clearQueue();

    final repository = LocalSyncQueueRepository(
      localDataSource: SyncQueueLocalDataSource(),
    );

    final manager = SyncQueueManager(queueRepository: repository);

    await manager.enqueue(
      item(
        operation: SyncOperation.update,
        entityId: 'customer-3',
        payload: '{"name":"First"}',
      ),
    );

    await manager.enqueue(
      item(
        operation: SyncOperation.update,
        entityId: 'customer-3',
        payload: '{"name":"Second"}',
      ),
    );

    final items = await repository.getPendingItems();

    expect(items.length, 1);
    expect(items.first.operation, SyncOperation.update);
    expect(items.first.payload, '{"name":"Second"}');
  });

  test('UPDATE + DELETE should become DELETE', () async {
    await clearQueue();

    final repository = LocalSyncQueueRepository(
      localDataSource: SyncQueueLocalDataSource(),
    );

    final manager = SyncQueueManager(queueRepository: repository);

    await manager.enqueue(
      item(
        operation: SyncOperation.update,
        entityId: 'customer-4',
        payload: '{"name":"Updated"}',
      ),
    );

    await manager.enqueue(
      item(
        operation: SyncOperation.delete,
        entityId: 'customer-4',
        payload: '{"id":"customer-4"}',
      ),
    );

    final items = await repository.getPendingItems();

    expect(items.length, 1);
    expect(items.first.operation, SyncOperation.delete);
  });

  test('different entities should not be coalesced', () async {
    await clearQueue();

    final repository = LocalSyncQueueRepository(
      localDataSource: SyncQueueLocalDataSource(),
    );

    final manager = SyncQueueManager(queueRepository: repository);

    await manager.enqueue(
      item(
        operation: SyncOperation.update,
        entityId: 'customer-5',
        payload: '{"name":"Customer"}',
      ),
    );

    await manager.enqueue(
      item(
        operation: SyncOperation.update,
        entityId: 'customer-6',
        payload: '{"name":"Another"}',
      ),
    );

    final items = await repository.getPendingItems();

    expect(items.length, 2);
  });
}

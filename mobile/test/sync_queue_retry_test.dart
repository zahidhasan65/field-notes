import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:mobile/core/constants/sync_constants.dart';
import 'package:mobile/data/local/database/database_helper.dart';
import 'package:mobile/data/local/data_sources/sync_queue_local_data_source.dart';
import 'package:mobile/data/local/models/sync_queue_item.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('markFailed should increment retry count', () async {
    final db = await DatabaseHelper.instance.database;

    await db.delete('sync_queue');

    final dataSource = SyncQueueLocalDataSource();

    final item = SyncQueueItem(
      entityType: SyncEntityType.customer,
      entityId: 'customer-retry-1',
      operation: SyncOperation.update,
      payload: '{"name":"Retry Test"}',
      createdAt: '2026-01-01T10:00:00Z',
      retryCount: 0,
      status: SyncQueueStatus.pending,
    );

    await dataSource.addToQueue(item);

    final pendingItems = await dataSource.getPendingItems();

    expect(pendingItems.length, 1);

    final id = pendingItems.first.id!;

    await dataSource.markProcessing(id);

    await dataSource.markFailed(
      id,
      errorMessage: 'Network unavailable',
    );

    final failedResult = await db.query(
      'sync_queue',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    expect(failedResult.length, 1);
    expect(
      failedResult.first['status'],
      SyncQueueStatus.failed,
    );
    expect(
      failedResult.first['retry_count'],
      1,
    );
    expect(
      failedResult.first['error_message'],
      'Network unavailable',
    );

    await dataSource.markPending(id);

    final pendingResult = await db.query(
      'sync_queue',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    expect(
      pendingResult.first['status'],
      SyncQueueStatus.pending,
    );
    expect(
      pendingResult.first['retry_count'],
      1,
    );
    expect(
      pendingResult.first['error_message'],
      null,
    );
  });
}

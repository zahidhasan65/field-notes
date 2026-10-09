import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:mobile/core/constants/sync_constants.dart';
import 'package:mobile/data/local/database/database_helper.dart';
import 'package:mobile/data/local/data_sources/sync_queue_local_data_source.dart';
import 'package:mobile/data/local/models/sync_queue_item.dart';
import 'package:mobile/data/repositories/local_sync_queue_repository.dart';
import 'package:mobile/data/repositories/local_customer_repository.dart';
import 'package:mobile/data/repositories/local_site_repository.dart';
import 'package:mobile/data/repositories/local_field_note_repository.dart';
import 'package:mobile/data/remote/sync_remote_data_source.dart';
import 'package:mobile/data/sync/sync_engine.dart';

class FakeSyncRemoteDataSource implements SyncRemoteDataSource {
  final List<String> calls = [];

  bool shouldFail = false;

  @override
  Future<void> create(SyncQueueItem item) async {
    if (shouldFail) {
      throw Exception('Network error');
    }

    calls.add('CREATE:${item.entityType}:${item.entityId}');
  }

  @override
  Future<void> update(SyncQueueItem item) async {
    if (shouldFail) {
      throw Exception('Network error');
    }

    calls.add('UPDATE:${item.entityType}:${item.entityId}');
  }

  @override
  Future<void> delete(SyncQueueItem item) async {
    if (shouldFail) {
      throw Exception('Network error');
    }

    calls.add('DELETE:${item.entityType}:${item.entityId}');
  }
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  SyncQueueItem item({
    required String entityType,
    required String entityId,
    required String operation,
    required String createdAt,
  }) {
    return SyncQueueItem(
      entityType: entityType,
      entityId: entityId,
      operation: operation,
      payload: '{"id":"$entityId"}',
      createdAt: createdAt,
      status: SyncQueueStatus.pending,
    );
  }

  test('sync should process items in dependency order', () async {
    final db = await DatabaseHelper.instance.database;

    await db.delete('sync_queue');

    final repository = LocalSyncQueueRepository(
      localDataSource: SyncQueueLocalDataSource(),
    );

    await repository.addToQueue(
      item(
        entityType: SyncEntityType.fieldNote,
        entityId: 'note-1',
        operation: SyncOperation.create,
        createdAt: '2026-01-01T12:00:00Z',
      ),
    );

    await repository.addToQueue(
      item(
        entityType: SyncEntityType.customer,
        entityId: 'customer-1',
        operation: SyncOperation.create,
        createdAt: '2026-01-01T10:00:00Z',
      ),
    );

    await repository.addToQueue(
      item(
        entityType: SyncEntityType.site,
        entityId: 'site-1',
        operation: SyncOperation.create,
        createdAt: '2026-01-01T11:00:00Z',
      ),
    );

    final remote = FakeSyncRemoteDataSource();

    final engine = SyncEngine(
      queueRepository: repository,
      remoteDataSource: remote,
      customerRepository: LocalCustomerRepository(),
      siteRepository: LocalSiteRepository(),
      fieldNoteRepository: LocalFieldNoteRepository(),
    );

    await engine.sync();

    expect(remote.calls, [
      'CREATE:CUSTOMER:customer-1',
      'CREATE:SITE:site-1',
      'CREATE:FIELD_NOTE:note-1',
    ]);

    expect(await repository.getPendingItems(), isEmpty);
  });

  test('successful sync should remove queue item', () async {
    final db = await DatabaseHelper.instance.database;

    await db.delete('sync_queue');

    final repository = LocalSyncQueueRepository(
      localDataSource: SyncQueueLocalDataSource(),
    );

    await repository.addToQueue(
      item(
        entityType: SyncEntityType.customer,
        entityId: 'customer-success',
        operation: SyncOperation.create,
        createdAt: '2026-01-01T10:00:00Z',
      ),
    );

    final remote = FakeSyncRemoteDataSource();

    final engine = SyncEngine(
      queueRepository: repository,
      remoteDataSource: remote,
      customerRepository: LocalCustomerRepository(),
      siteRepository: LocalSiteRepository(),
      fieldNoteRepository: LocalFieldNoteRepository(),
    );

    await engine.sync();

    expect(await repository.getPendingItems(), isEmpty);

    expect(remote.calls.length, 1);
  });

  test('failed sync should mark queue item as failed', () async {
    final db = await DatabaseHelper.instance.database;

    await db.delete('sync_queue');

    final repository = LocalSyncQueueRepository(
      localDataSource: SyncQueueLocalDataSource(),
    );

    await repository.addToQueue(
      item(
        entityType: SyncEntityType.customer,
        entityId: 'customer-failed',
        operation: SyncOperation.create,
        createdAt: '2026-01-01T10:00:00Z',
      ),
    );

    final remote = FakeSyncRemoteDataSource()..shouldFail = true;

    final engine = SyncEngine(
      queueRepository: repository,
      remoteDataSource: remote,
      customerRepository: LocalCustomerRepository(),
      siteRepository: LocalSiteRepository(),
      fieldNoteRepository: LocalFieldNoteRepository(),
    );

    await engine.sync();

    final result = await db.query(
      'sync_queue',
      where: 'entity_id = ?',
      whereArgs: ['customer-failed'],
      limit: 1,
    );

    expect(result.length, 1);
    expect(result.first['status'], SyncQueueStatus.failed);
    expect(result.first['retry_count'], 1);
  });
}

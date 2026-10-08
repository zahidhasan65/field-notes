import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/core/connectivity/connectivity_service.dart';
import 'package:mobile/data/local/data_sources/sync_queue_local_data_source.dart';
import 'package:mobile/data/repositories/local_sync_queue_repository.dart';
import 'package:mobile/data/remote/sync_remote_data_source.dart';
import 'package:mobile/data/local/models/sync_queue_item.dart';
import 'package:mobile/data/sync/sync_coordinator.dart';
import 'package:mobile/data/sync/sync_engine.dart';

class FakeConnectivityService extends ConnectivityService {
  final StreamController<bool> controller =
      StreamController<bool>.broadcast();

  bool online;

  FakeConnectivityService({
    this.online = false,
  });

  @override
  Future<bool> isOnline() async => online;

  @override
  Stream<bool> get onConnectivityChanged => controller.stream;

  Future<void> emit(bool value) async {
    online = value;
    controller.add(value);
    await Future<void>.delayed(Duration.zero);
  }

  Future<void> close() async {
    await controller.close();
  }
}

class FakeRemoteDataSource implements SyncRemoteDataSource {
  @override
  Future<void> create(SyncQueueItem item) async {}

  @override
  Future<void> update(SyncQueueItem item) async {}

  @override
  Future<void> delete(SyncQueueItem item) async {}
}

class FakeSyncEngine extends SyncEngine {
  int syncCallCount = 0;

  FakeSyncEngine()
      : super(
          queueRepository: LocalSyncQueueRepository(
            localDataSource: SyncQueueLocalDataSource(),
          ),
          remoteDataSource: FakeRemoteDataSource(),
        );

  @override
  Future<void> sync() async {
    syncCallCount++;
  }
}

class BlockingFakeSyncEngine extends SyncEngine {
  final Completer<void> syncStarted;
  final Completer<void> releaseSync;

  int syncCallCount = 0;

  BlockingFakeSyncEngine({
    required this.syncStarted,
    required this.releaseSync,
  }) : super(
          queueRepository: LocalSyncQueueRepository(
            localDataSource: SyncQueueLocalDataSource(),
          ),
          remoteDataSource: FakeRemoteDataSource(),
        );

  @override
  Future<void> sync() async {
    syncCallCount++;

    if (!syncStarted.isCompleted) {
      syncStarted.complete();
    }

    await releaseSync.future;
  }
}

void main() {
  test('should sync immediately when started online', () async {
    final connectivity = FakeConnectivityService(online: true);
    final engine = FakeSyncEngine();

    final coordinator = SyncCoordinator(
      connectivityService: connectivity,
      syncEngine: engine,
    );

    await coordinator.start();

    expect(engine.syncCallCount, 1);

    await coordinator.dispose();
    await connectivity.close();
  });

  test('should sync when connectivity changes to online', () async {
    final connectivity = FakeConnectivityService();
    final engine = FakeSyncEngine();

    final coordinator = SyncCoordinator(
      connectivityService: connectivity,
      syncEngine: engine,
    );

    await coordinator.start();

    expect(engine.syncCallCount, 0);

    await connectivity.emit(true);

    expect(engine.syncCallCount, 1);

    await coordinator.dispose();
    await connectivity.close();
  });

  test('should not start duplicate sync while already syncing', () async {
    final connectivity = FakeConnectivityService();

    final syncStarted = Completer<void>();
    final releaseSync = Completer<void>();

    final engine = BlockingFakeSyncEngine(
      syncStarted: syncStarted,
      releaseSync: releaseSync,
    );

    final coordinator = SyncCoordinator(
      connectivityService: connectivity,
      syncEngine: engine,
    );

    await coordinator.start();

    final firstSync = coordinator.syncNow();

    await syncStarted.future;

    final secondSync = coordinator.syncNow();

    await Future<void>.delayed(Duration.zero);

    expect(engine.syncCallCount, 1);

    releaseSync.complete();

    await firstSync;
    await secondSync;

    await coordinator.dispose();
    await connectivity.close();
  });
}

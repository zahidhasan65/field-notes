import '../local/data_sources/sync_queue_local_data_source.dart';
import '../local/models/sync_queue_item.dart';

class LocalSyncQueueRepository {
  final SyncQueueLocalDataSource localDataSource;

  LocalSyncQueueRepository({SyncQueueLocalDataSource? localDataSource})
    : localDataSource = localDataSource ?? SyncQueueLocalDataSource();

  Future<void> addToQueue(SyncQueueItem item) async {
    await localDataSource.addToQueue(item);
  }

  Future<List<SyncQueueItem>> getPendingItems() async {
    return localDataSource.getPendingItems();
  }

  Future<List<SyncQueueItem>> getPendingItemsByEntity(
    String entityType,
    String entityId,
  ) async {
    return localDataSource.getPendingItemsByEntity(entityType, entityId);
  }

  Future<void> markProcessing(int id) async {
    await localDataSource.markProcessing(id);
  }

  Future<void> markFailed(int id, {required String errorMessage}) async {
    await localDataSource.markFailed(id, errorMessage: errorMessage);
  }

  Future<void> markPending(int id) async {
    await localDataSource.markPending(id);
  }

  Future<void> removeFromQueue(int id) async {
    await localDataSource.removeFromQueue(id);
  }

  Future<void> removeEntityOperations(
    String entityType,
    String entityId,
  ) async {
    await localDataSource.removeEntityOperations(entityType, entityId);
  }
}

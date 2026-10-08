import '../local/models/sync_queue_item.dart';

abstract class SyncRemoteDataSource {
  Future<void> create(
    SyncQueueItem item,
  );

  Future<void> update(
    SyncQueueItem item,
  );

  Future<void> delete(
    SyncQueueItem item,
  );
}

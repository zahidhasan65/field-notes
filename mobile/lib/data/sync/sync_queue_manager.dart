import '../../core/constants/sync_constants.dart';
import '../local/models/sync_queue_item.dart';
import '../repositories/local_sync_queue_repository.dart';

class SyncQueueManager {
  final LocalSyncQueueRepository queueRepository;

  SyncQueueManager({
    LocalSyncQueueRepository? queueRepository,
  }) : queueRepository =
            queueRepository ?? LocalSyncQueueRepository();

  Future<void> enqueue(SyncQueueItem newItem) async {
    final existingItems = await queueRepository.getPendingItems();

    final sameEntityItems = existingItems
        .where(
          (item) =>
              item.entityType == newItem.entityType &&
              item.entityId == newItem.entityId,
        )
        .toList();

    if (sameEntityItems.isEmpty) {
      await queueRepository.addToQueue(newItem);
      return;
    }

    final existing = sameEntityItems.last;

    if (existing.operation == SyncOperation.create &&
        newItem.operation == SyncOperation.update) {
      await queueRepository.removeEntityOperations(
        newItem.entityType,
        newItem.entityId,
      );

      await queueRepository.addToQueue(
        existing.copyWith(
          payload: newItem.payload,
          createdAt: newItem.createdAt,
        ),
      );
      return;
    }

    if (existing.operation == SyncOperation.create &&
        newItem.operation == SyncOperation.delete) {
      await queueRepository.removeEntityOperations(
        newItem.entityType,
        newItem.entityId,
      );
      return;
    }

    if (existing.operation == SyncOperation.update &&
        newItem.operation == SyncOperation.update) {
      await queueRepository.removeEntityOperations(
        newItem.entityType,
        newItem.entityId,
      );

      await queueRepository.addToQueue(newItem);
      return;
    }

    if (existing.operation == SyncOperation.update &&
        newItem.operation == SyncOperation.delete) {
      await queueRepository.removeEntityOperations(
        newItem.entityType,
        newItem.entityId,
      );

      await queueRepository.addToQueue(newItem);
      return;
    }

    await queueRepository.removeEntityOperations(
      newItem.entityType,
      newItem.entityId,
    );

    await queueRepository.addToQueue(newItem);
  }
}

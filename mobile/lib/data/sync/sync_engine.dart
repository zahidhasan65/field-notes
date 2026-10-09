import '../../core/constants/sync_constants.dart';
import '../local/models/sync_queue_item.dart';
import '../repositories/local_customer_repository.dart';
import '../repositories/local_field_note_repository.dart';
import '../repositories/local_site_repository.dart';
import '../repositories/local_sync_queue_repository.dart';
import '../remote/sync_remote_data_source.dart';

class SyncEngine {
  final LocalSyncQueueRepository queueRepository;
  final SyncRemoteDataSource remoteDataSource;
  final LocalCustomerRepository? customerRepository;
  final LocalSiteRepository? siteRepository;
  final LocalFieldNoteRepository? fieldNoteRepository;

  SyncEngine({
    required this.queueRepository,
    required this.remoteDataSource,
    this.customerRepository,
    this.siteRepository,
    this.fieldNoteRepository,
  });

  Future<void> sync() async {
    final pendingItems = await queueRepository.getPendingItems();

    final orderedItems = _sortByDependency(pendingItems);

    for (final item in orderedItems) {
      await _processItem(item);
    }
  }

  List<SyncQueueItem> _sortByDependency(List<SyncQueueItem> items) {
    final priority = {
      SyncEntityType.customer: 1,
      SyncEntityType.site: 2,
      SyncEntityType.fieldNote: 3,
    };

    final sorted = [...items];

    sorted.sort((a, b) {
      final aPriority = priority[a.entityType] ?? 99;
      final bPriority = priority[b.entityType] ?? 99;

      if (aPriority != bPriority) {
        return aPriority.compareTo(bPriority);
      }

      return a.createdAt.compareTo(b.createdAt);
    });

    return sorted;
  }

  Future<void> _processItem(SyncQueueItem item) async {
    if (item.id == null) {
      return;
    }

    try {
      await queueRepository.markProcessing(item.id!);

      switch (item.operation) {
        case SyncOperation.create:
          await remoteDataSource.create(item);
          await _markEntityAsSynced(item);
          break;

        case SyncOperation.update:
          await remoteDataSource.update(item);
          await _markEntityAsSynced(item);
          break;

        case SyncOperation.delete:
          await remoteDataSource.delete(item);
          break;

        default:
          throw UnsupportedError(
            'Unsupported sync operation: ${item.operation}',
          );
      }

      await queueRepository.removeFromQueue(item.id!);
    } catch (error) {
      await _markEntityAsSyncFailed(item);

      await queueRepository.markFailed(
        item.id!,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> _markEntityAsSyncFailed(SyncQueueItem item) async {
    switch (item.entityType) {
      case SyncEntityType.customer:
        if (customerRepository == null) {
          throw StateError('Customer repository is not configured.');
        }
        await customerRepository!.markAsSyncFailed(item.entityId);
        break;

      case SyncEntityType.site:
        if (siteRepository == null) {
          throw StateError('Site repository is not configured.');
        }
        await siteRepository!.markAsSyncFailed(item.entityId);
        break;

      case SyncEntityType.fieldNote:
        if (fieldNoteRepository == null) {
          throw StateError('Field note repository is not configured.');
        }
        await fieldNoteRepository!.markAsSyncFailed(item.entityId);
        break;

      default:
        throw UnsupportedError('Unsupported entity type: ');
    }
  }

  Future<void> _markEntityAsSynced(SyncQueueItem item) async {
    switch (item.entityType) {
      case SyncEntityType.customer:
        if (customerRepository == null) {
          throw StateError('Customer repository is not configured.');
        }
        await customerRepository!.markAsSynced(item.entityId);
        break;

      case SyncEntityType.site:
        if (siteRepository == null) {
          throw StateError('Site repository is not configured.');
        }
        await siteRepository!.markAsSynced(item.entityId);
        break;

      case SyncEntityType.fieldNote:
        if (fieldNoteRepository == null) {
          throw StateError('Field note repository is not configured.');
        }
        await fieldNoteRepository!.markAsSynced(item.entityId);
        break;

      default:
        throw UnsupportedError('Unsupported entity type: ');
    }
  }
}

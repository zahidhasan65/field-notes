import '../local/data_sources/customer_local_data_source.dart';
import '../local/models/customer_local.dart';
import '../local/models/sync_queue_item.dart';

class LocalCustomerRepository {
  final CustomerLocalDataSource localDataSource;

  LocalCustomerRepository({
    CustomerLocalDataSource? localDataSource,
  }) : localDataSource = localDataSource ?? CustomerLocalDataSource();

  Future<void> saveCustomer(CustomerLocal customer) async =>
      localDataSource.insertCustomer(customer);

  Future<void> createCustomerWithSyncQueue({
    required CustomerLocal customer,
    required SyncQueueItem queueItem,
  }) async =>
      localDataSource.createCustomerWithSyncQueue(
        customer: customer,
        queueItem: queueItem,
      );

  Future<void> updateCustomerWithSyncQueue({
    required CustomerLocal customer,
    required SyncQueueItem queueItem,
  }) async =>
      localDataSource.updateCustomerWithSyncQueue(
        customer: customer,
        queueItem: queueItem,
      );

  Future<void> deleteCustomerWithSyncQueue({
    required String id,
    required String deletedAt,
    required SyncQueueItem queueItem,
  }) async =>
      localDataSource.softDeleteCustomerWithSyncQueue(
        id: id,
        deletedAt: deletedAt,
        queueItem: queueItem,
      );

  Future<CustomerLocal?> getCustomerById(String id) async =>
      localDataSource.getCustomerById(id);

  Future<List<CustomerLocal>> getCustomers(String userId) async =>
      localDataSource.getCustomers(userId);

  Future<void> updateCustomer(CustomerLocal customer) async =>
      localDataSource.updateCustomer(customer);

  Future<void> deleteCustomer(String id, String deletedAt) async =>
      localDataSource.softDeleteCustomer(id, deletedAt);

  Future<void> markAsSynced(String id) async =>
      localDataSource.markAsSynced(id);

  Future<void> markAsSyncFailed(String id) async =>
      localDataSource.markAsSyncFailed(id);
}


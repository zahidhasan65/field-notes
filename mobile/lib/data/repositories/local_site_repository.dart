import '../local/data_sources/site_local_data_source.dart';
import '../local/models/site_local.dart';
import '../local/models/sync_queue_item.dart';

class LocalSiteRepository {
  final SiteLocalDataSource localDataSource;

  LocalSiteRepository({
    SiteLocalDataSource? localDataSource,
  }) : localDataSource = localDataSource ?? SiteLocalDataSource();

  Future<void> saveSite(SiteLocal site) async =>
      localDataSource.insertSite(site);

  Future<void> createSiteWithSyncQueue({
    required SiteLocal site,
    required SyncQueueItem queueItem,
  }) async =>
      localDataSource.createSiteWithSyncQueue(
        site: site,
        queueItem: queueItem,
      );

  Future<void> updateSiteWithSyncQueue({
    required SiteLocal site,
    required SyncQueueItem queueItem,
  }) async =>
      localDataSource.updateSiteWithSyncQueue(
        site: site,
        queueItem: queueItem,
      );

  Future<void> deleteSiteWithSyncQueue({
    required String id,
    required String deletedAt,
    required SyncQueueItem queueItem,
  }) async =>
      localDataSource.softDeleteSiteWithSyncQueue(
        id: id,
        deletedAt: deletedAt,
        queueItem: queueItem,
      );

  Future<SiteLocal?> getSiteById(String id) async =>
      localDataSource.getSiteById(id);

  Future<List<SiteLocal>> getSites(String customerId) async =>
      localDataSource.getSites(customerId);

  Future<void> updateSite(SiteLocal site) async =>
      localDataSource.updateSite(site);

  Future<void> deleteSite(String id, String deletedAt) async =>
      localDataSource.softDeleteSite(id, deletedAt);

  Future<void> markAsSynced(String id) async =>
      localDataSource.markAsSynced(id);

  Future<void> markAsSyncFailed(String id) async =>
      localDataSource.markAsSyncFailed(id);
}


import 'package:sqflite/sqflite.dart';

import '../../../core/constants/sync_constants.dart';
import '../database/database_helper.dart';
import '../models/site_local.dart';
import '../models/sync_queue_item.dart';

class SiteLocalDataSource {
  final DatabaseHelper databaseHelper;

  SiteLocalDataSource({DatabaseHelper? databaseHelper})
    : databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  Future<void> insertSite(SiteLocal site) async {
    final db = await databaseHelper.database;

    await db.insert(
      'sites',
      site.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<SiteLocal?> getSiteById(String id) async {
    final db = await databaseHelper.database;

    final result = await db.query(
      'sites',
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return SiteLocal.fromMap(result.first);
  }

  Future<List<SiteLocal>> getSites(String customerId) async {
    final db = await databaseHelper.database;

    final result = await db.query(
      'sites',
      where: 'customer_id = ? AND deleted_at IS NULL',
      whereArgs: [customerId],
      orderBy: 'created_at DESC',
    );

    return result.map(SiteLocal.fromMap).toList();
  }

  Future<void> updateSite(SiteLocal site) async {
    final db = await databaseHelper.database;

    await db.update(
      'sites',
      site.toMap(),
      where: 'id = ?',
      whereArgs: [site.id],
    );
  }

  Future<void> markAsSynced(String id) async {
    final db = await databaseHelper.database;

    await db.update(
      'sites',
      {'sync_status': SyncStatus.synced},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> softDeleteSite(String id, String deletedAt) async {
    final db = await databaseHelper.database;

    await db.update(
      'sites',
      {'deleted_at': deletedAt},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> createSiteWithSyncQueue({
    required SiteLocal site,
    required SyncQueueItem queueItem,
  }) async {
    final db = await databaseHelper.database;

    await db.transaction((txn) async {
      await txn.insert(
        'sites',
        site.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await txn.insert(
        'sync_queue',
        queueItem.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<void> updateSiteWithSyncQueue({
    required SiteLocal site,
    required SyncQueueItem queueItem,
  }) async {
    final db = await databaseHelper.database;

    await db.transaction((txn) async {
      await txn.update(
        'sites',
        site.toMap(),
        where: 'id = ?',
        whereArgs: [site.id],
      );

      await txn.insert(
        'sync_queue',
        queueItem.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<void> softDeleteSiteWithSyncQueue({
    required String id,
    required String deletedAt,
    required SyncQueueItem queueItem,
  }) async {
    final db = await databaseHelper.database;

    await db.transaction((txn) async {
      await txn.update(
        'sites',
        {
          'deleted_at': deletedAt,
          'sync_status': SyncStatus.pendingDelete,
          'updated_at': deletedAt,
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      await txn.insert(
        'sync_queue',
        queueItem.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<void> markAsSyncFailed(String id) async {
    final db = await databaseHelper.database;
    await db.update(
      'sites',
      {'sync_status': SyncStatus.syncFailed},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> restoreSites(List<SiteLocal> sites) async {
    final db = await databaseHelper.database;

    await db.transaction((txn) async {
      for (final site in sites) {
        await txn.insert(
          'sites',
          site.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }
}

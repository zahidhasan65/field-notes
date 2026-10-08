import 'package:sqflite/sqflite.dart';

import '../../../core/constants/sync_constants.dart';
import '../database/database_helper.dart';
import '../models/customer_local.dart';
import '../models/sync_queue_item.dart';

class CustomerLocalDataSource {
  final DatabaseHelper databaseHelper;

  CustomerLocalDataSource({
    DatabaseHelper? databaseHelper,
  }) : databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  Future<void> insertCustomer(CustomerLocal customer) async {
    final db = await databaseHelper.database;

    await db.insert(
      'customers',
      customer.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<CustomerLocal?> getCustomerById(String id) async {
    final db = await databaseHelper.database;

    final result = await db.query(
      'customers',
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return CustomerLocal.fromMap(result.first);
  }

  Future<List<CustomerLocal>> getCustomers(String userId) async {
    final db = await databaseHelper.database;

    final result = await db.query(
      'customers',
      where: 'user_id = ? AND deleted_at IS NULL',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );

    return result.map(CustomerLocal.fromMap).toList();
  }

  Future<void> updateCustomer(CustomerLocal customer) async {
    final db = await databaseHelper.database;

    await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<void> markAsSynced(String id) async {
    final db = await databaseHelper.database;

    await db.update(
      'customers',
      {'sync_status': SyncStatus.synced},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> softDeleteCustomer(
    String id,
    String deletedAt,
  ) async {
    final db = await databaseHelper.database;

    await db.update(
      'customers',
      {'deleted_at': deletedAt},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> createCustomerWithSyncQueue({
    required CustomerLocal customer,
    required SyncQueueItem queueItem,
  }) async {
    final db = await databaseHelper.database;

    await db.transaction((txn) async {
      await txn.insert(
        'customers',
        customer.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await txn.insert(
        'sync_queue',
        queueItem.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<void> updateCustomerWithSyncQueue({
    required CustomerLocal customer,
    required SyncQueueItem queueItem,
  }) async {
    final db = await databaseHelper.database;

    await db.transaction((txn) async {
      await txn.update(
        'customers',
        customer.toMap(),
        where: 'id = ?',
        whereArgs: [customer.id],
      );

      await txn.insert(
        'sync_queue',
        queueItem.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<void> softDeleteCustomerWithSyncQueue({
    required String id,
    required String deletedAt,
    required SyncQueueItem queueItem,
  }) async {
    final db = await databaseHelper.database;

    await db.transaction((txn) async {
      await txn.update(
        'customers',
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
      'customers',
      {'sync_status': SyncStatus.syncFailed},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> restoreCustomers(
    List<CustomerLocal> customers,
  ) async {
    final db = await databaseHelper.database;

    await db.transaction((txn) async {
      for (final customer in customers) {
        await txn.insert(
          'customers',
          customer.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }
}

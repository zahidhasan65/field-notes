import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';

abstract class SyncTableDataSource {
  SyncTableDataSource(this.helper);

  final DatabaseHelper helper;

  String get table;

  Future<DatabaseExecutor> executor(DatabaseExecutor? ex) async =>
      ex ?? await helper.database;

  Future<String?> getSyncStatus(String id, {DatabaseExecutor? ex}) async {
    final e = await executor(ex);
    final rows = await e.query(
      table,
      columns: ['sync_status'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['sync_status'] as String?;
  }

  Future<bool> exists(String id, {DatabaseExecutor? ex}) async {
    final e = await executor(ex);
    final rows = await e.query(table,
        columns: ['id'], where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isNotEmpty;
  }

  Future<void> setSyncStatus(String id, String status,
      {DatabaseExecutor? ex}) async {
    final e = await executor(ex);
    await e.update(table, {'sync_status': status},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> softDeleteMany(
    DatabaseExecutor ex,
    List<String> ids,
    String deletedAt, {
    required String syncStatus,
  }) async {
    if (ids.isEmpty) return;
    final marks = List.filled(ids.length, '?').join(',');
    await ex.rawUpdate(
      'UPDATE $table SET deleted_at = ?, updated_at = ?, sync_status = ? '
      'WHERE id IN ($marks)',
      [deletedAt, deletedAt, syncStatus, ...ids],
    );
  }

  Future<void> upsertMap(DatabaseExecutor ex, Map<String, Object?> map) async {
    final id = map['id'];
    final updated = await ex.update(table, map, where: 'id = ?', whereArgs: [id]);
    if (updated == 0) {
      await ex.insert(table, map);
    }
  }
}

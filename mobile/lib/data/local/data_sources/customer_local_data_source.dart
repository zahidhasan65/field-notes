import 'package:sqflite/sqflite.dart';

import '../../models/customer_local.dart';
import '../../models/views.dart';
import 'sync_table_data_source.dart';

class CustomerLocalDataSource extends SyncTableDataSource {
  CustomerLocalDataSource(super.helper);

  @override
  String get table => 'customers';

  Future<void> upsert(DatabaseExecutor ex, CustomerLocal c) =>
      upsertMap(ex, c.toMap());

  Future<CustomerLocal?> getById(
    String id, {
    bool includeDeleted = false,
    DatabaseExecutor? ex,
  }) async {
    final e = await executor(ex);
    final rows = await e.query(
      'customers',
      where: includeDeleted ? 'id = ?' : 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : CustomerLocal.fromMap(rows.first);
  }

  Future<List<CustomerView>> listViews(String userId, {String query = ''}) async {
    final db = await helper.database;
    final like = '%${query.trim()}%';
    final rows = await db.rawQuery('''
      SELECT c.*,
        (SELECT COUNT(*) FROM sites s
          WHERE s.customer_id = c.id AND s.deleted_at IS NULL) AS site_count,
        (SELECT COUNT(*) FROM field_notes n
          JOIN sites s2 ON s2.id = n.site_id
          WHERE s2.customer_id = c.id AND s2.deleted_at IS NULL
            AND n.deleted_at IS NULL) AS note_count
      FROM customers c
      WHERE c.user_id = ? AND c.deleted_at IS NULL
        AND (c.name LIKE ? OR IFNULL(c.contact_person, '') LIKE ?
             OR IFNULL(c.email, '') LIKE ? OR IFNULL(c.phone, '') LIKE ?)
      ORDER BY c.name COLLATE NOCASE
    ''', [userId, like, like, like, like]);

    return rows
        .map((r) => CustomerView(
              CustomerLocal.fromMap(r),
              siteCount: (r['site_count'] as int?) ?? 0,
              noteCount: (r['note_count'] as int?) ?? 0,
            ))
        .toList();
  }

  Future<CustomerView?> getView(String id) async {
    final db = await helper.database;
    final rows = await db.rawQuery('''
      SELECT c.*,
        (SELECT COUNT(*) FROM sites s
          WHERE s.customer_id = c.id AND s.deleted_at IS NULL) AS site_count,
        (SELECT COUNT(*) FROM field_notes n
          JOIN sites s2 ON s2.id = n.site_id
          WHERE s2.customer_id = c.id AND s2.deleted_at IS NULL
            AND n.deleted_at IS NULL) AS note_count
      FROM customers c
      WHERE c.id = ? AND c.deleted_at IS NULL
    ''', [id]);
    if (rows.isEmpty) return null;
    final r = rows.first;
    return CustomerView(
      CustomerLocal.fromMap(r),
      siteCount: (r['site_count'] as int?) ?? 0,
      noteCount: (r['note_count'] as int?) ?? 0,
    );
  }

  Future<int> count(String userId) async {
    final db = await helper.database;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM customers WHERE user_id = ? AND deleted_at IS NULL',
      [userId],
    );
    return (rows.first['c'] as int?) ?? 0;
  }
}

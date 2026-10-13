import 'package:sqflite/sqflite.dart';

import '../../models/site_local.dart';
import '../../models/views.dart';
import 'sync_table_data_source.dart';

class SiteLocalDataSource extends SyncTableDataSource {
  SiteLocalDataSource(super.helper);

  @override
  String get table => 'sites';

  Future<void> upsert(DatabaseExecutor ex, SiteLocal s) => upsertMap(ex, s.toMap());

  Future<SiteLocal?> getById(
    String id, {
    bool includeDeleted = false,
    DatabaseExecutor? ex,
  }) async {
    final e = await executor(ex);
    final rows = await e.query(
      'sites',
      where: includeDeleted ? 'id = ?' : 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : SiteLocal.fromMap(rows.first);
  }

  Future<List<String>> idsByCustomer(DatabaseExecutor ex, String customerId) async {
    final rows = await ex.query('sites',
        columns: ['id'],
        where: 'customer_id = ? AND deleted_at IS NULL',
        whereArgs: [customerId]);
    return rows.map((r) => r['id'] as String).toList();
  }

  static const _selectView = '''
    SELECT s.*, c.name AS customer_name,
      (SELECT COUNT(*) FROM field_notes n
        WHERE n.site_id = s.id AND n.deleted_at IS NULL) AS note_count
    FROM sites s
    JOIN customers c ON c.id = s.customer_id
  ''';

  SiteView _toView(Map<String, Object?> r) => SiteView(
        SiteLocal.fromMap(r),
        customerName: (r['customer_name'] as String?) ?? '',
        noteCount: (r['note_count'] as int?) ?? 0,
      );

  Future<List<SiteView>> listViews(
    String userId, {
    String? customerId,
    String query = '',
  }) async {
    final db = await helper.database;
    final like = '%${query.trim()}%';
    final args = <Object?>[userId];
    final where = StringBuffer(
        'c.user_id = ? AND s.deleted_at IS NULL AND c.deleted_at IS NULL');
    if (customerId != null) {
      where.write(' AND s.customer_id = ?');
      args.add(customerId);
    }
    where.write(
        " AND (s.site_name LIKE ? OR c.name LIKE ? OR IFNULL(s.address, '') LIKE ?)");
    args.addAll([like, like, like]);

    final rows = await db.rawQuery(
      '$_selectView WHERE $where ORDER BY s.site_name COLLATE NOCASE',
      args,
    );
    return rows.map(_toView).toList();
  }

  Future<SiteView?> getView(String id) async {
    final db = await helper.database;
    final rows = await db.rawQuery(
      '$_selectView WHERE s.id = ? AND s.deleted_at IS NULL',
      [id],
    );
    return rows.isEmpty ? null : _toView(rows.first);
  }

  Future<int> count(String userId) async {
    final db = await helper.database;
    final rows = await db.rawQuery('''
      SELECT COUNT(*) AS c FROM sites s
      JOIN customers c ON c.id = s.customer_id
      WHERE c.user_id = ? AND s.deleted_at IS NULL AND c.deleted_at IS NULL
    ''', [userId]);
    return (rows.first['c'] as int?) ?? 0;
  }
}

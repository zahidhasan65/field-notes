import 'package:sqflite/sqflite.dart';

import '../../models/field_note_local.dart';
import '../../models/note_status.dart';
import '../../models/views.dart';
import 'sync_table_data_source.dart';

class FieldNoteLocalDataSource extends SyncTableDataSource {
  FieldNoteLocalDataSource(super.helper);

  @override
  String get table => 'field_notes';

  Future<void> upsert(DatabaseExecutor ex, FieldNoteLocal n) =>
      upsertMap(ex, n.toMap());

  Future<FieldNoteLocal?> getById(
    String id, {
    bool includeDeleted = false,
    DatabaseExecutor? ex,
  }) async {
    final e = await executor(ex);
    final rows = await e.query(
      'field_notes',
      where: includeDeleted ? 'id = ?' : 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : FieldNoteLocal.fromMap(rows.first);
  }

  Future<List<String>> idsBySites(DatabaseExecutor ex, List<String> siteIds) async {
    if (siteIds.isEmpty) return [];
    final marks = List.filled(siteIds.length, '?').join(',');
    final rows = await ex.rawQuery(
      'SELECT id FROM field_notes WHERE site_id IN ($marks) AND deleted_at IS NULL',
      siteIds,
    );
    return rows.map((r) => r['id'] as String).toList();
  }

  /// Photo files of the given notes (to delete them from disk).
  Future<List<String>> photoPathsByIds(DatabaseExecutor ex, List<String> ids) async {
    if (ids.isEmpty) return [];
    final marks = List.filled(ids.length, '?').join(',');
    final rows = await ex.rawQuery(
      'SELECT photo_path FROM field_notes WHERE id IN ($marks) AND photo_path IS NOT NULL',
      ids,
    );
    return rows.map((r) => r['photo_path'] as String).toList();
  }

  Future<List<String>> photoPathsForUser(String userId) async {
    final db = await helper.database;
    final rows = await db.rawQuery('''
      SELECT n.photo_path FROM field_notes n
      JOIN sites s ON s.id = n.site_id
      JOIN customers c ON c.id = s.customer_id
      WHERE c.user_id = ? AND n.photo_path IS NOT NULL
    ''', [userId]);
    return rows.map((r) => r['photo_path'] as String).toList();
  }

  Future<void> setPhotoUrl(String id, String? url) async {
    final db = await helper.database;
    await db.update('field_notes', {'photo_url': url},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> setPhotoPath(String id, String? path) async {
    final db = await helper.database;
    await db.update('field_notes', {'photo_path': path},
        where: 'id = ?', whereArgs: [id]);
  }

  /// Notes that have a remote photo but no local copy yet.
  Future<List<FieldNoteLocal>> missingPhotos(String userId) async {
    final db = await helper.database;
    final rows = await db.rawQuery('''
      SELECT n.* FROM field_notes n
      JOIN sites s ON s.id = n.site_id
      JOIN customers c ON c.id = s.customer_id
      WHERE c.user_id = ? AND n.deleted_at IS NULL
        AND n.photo_url IS NOT NULL AND n.photo_path IS NULL
    ''', [userId]);
    return rows.map(FieldNoteLocal.fromMap).toList();
  }

  static const _selectView = '''
    SELECT n.*, s.site_name AS site_name,
           c.id AS customer_id, c.name AS customer_name
    FROM field_notes n
    JOIN sites s ON s.id = n.site_id
    JOIN customers c ON c.id = s.customer_id
  ''';

  NoteView _toView(Map<String, Object?> r) => NoteView(
        FieldNoteLocal.fromMap(r),
        siteName: (r['site_name'] as String?) ?? '',
        customerId: (r['customer_id'] as String?) ?? '',
        customerName: (r['customer_name'] as String?) ?? '',
      );

  /// Search by title, description, site or customer + filter by status / site.
  /// All done with JOINs on the local database.
  Future<List<NoteView>> search(
    String userId, {
    String query = '',
    NoteStatus? status,
    String? siteId,
    int? limit,
  }) async {
    final db = await helper.database;
    final args = <Object?>[userId];
    final where = StringBuffer(
        'c.user_id = ? AND n.deleted_at IS NULL AND s.deleted_at IS NULL AND c.deleted_at IS NULL');

    if (status != null) {
      where.write(' AND n.status = ?');
      args.add(status.apiValue);
    }
    if (siteId != null) {
      where.write(' AND n.site_id = ?');
      args.add(siteId);
    }
    final q = query.trim();
    if (q.isNotEmpty) {
      final like = '%$q%';
      where.write(
          " AND (n.title LIKE ? OR IFNULL(n.description, '') LIKE ? OR s.site_name LIKE ? OR c.name LIKE ?)");
      args.addAll([like, like, like, like]);
    }

    final rows = await db.rawQuery(
      '$_selectView WHERE $where ORDER BY n.note_datetime DESC'
      '${limit != null ? ' LIMIT $limit' : ''}',
      args,
    );
    return rows.map(_toView).toList();
  }

  Future<NoteView?> getView(String id) async {
    final db = await helper.database;
    final rows = await db.rawQuery(
      '$_selectView WHERE n.id = ? AND n.deleted_at IS NULL',
      [id],
    );
    return rows.isEmpty ? null : _toView(rows.first);
  }

  Future<int> count(String userId) async {
    final db = await helper.database;
    final rows = await db.rawQuery('''
      SELECT COUNT(*) AS c FROM field_notes n
      JOIN sites s ON s.id = n.site_id
      JOIN customers c ON c.id = s.customer_id
      WHERE c.user_id = ? AND n.deleted_at IS NULL
        AND s.deleted_at IS NULL AND c.deleted_at IS NULL
    ''', [userId]);
    return (rows.first['c'] as int?) ?? 0;
  }
}

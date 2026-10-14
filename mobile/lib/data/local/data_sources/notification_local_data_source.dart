import '../../models/app_notification.dart';
import '../database/database_helper.dart';

class NotificationLocalDataSource {
  NotificationLocalDataSource(this.helper);

  final DatabaseHelper helper;

  Future<void> insert(AppNotification n) async {
    final db = await helper.database;
    await db.insert('notifications', n.toMap());
  }

  Future<List<AppNotification>> list(String userId) async {
    final db = await helper.database;
    final rows = await db.query(
      'notifications',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return rows.map(AppNotification.fromMap).toList();
  }

  Future<int> unreadCount(String userId) async {
    final db = await helper.database;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM notifications WHERE user_id = ? AND is_read = 0',
      [userId],
    );
    return (rows.first['c'] as int?) ?? 0;
  }

  Future<void> markAllRead(String userId) async {
    final db = await helper.database;
    await db.update('notifications', {'is_read': 1},
        where: 'user_id = ? AND is_read = 0', whereArgs: [userId]);
  }

  Future<void> markRead(String id) async {
    final db = await helper.database;
    await db.update('notifications', {'is_read': 1}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> delete(String id) async {
    final db = await helper.database;
    await db.delete('notifications', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clear(String userId) async {
    final db = await helper.database;
    await db.delete('notifications', where: 'user_id = ?', whereArgs: [userId]);
  }

  Future<void> trim(String userId, {int keep = 100}) async {
    final db = await helper.database;
    await db.rawDelete('''
      DELETE FROM notifications WHERE user_id = ? AND id NOT IN (
        SELECT id FROM notifications WHERE user_id = ? ORDER BY created_at DESC LIMIT ?
      )
    ''', [userId, userId, keep]);
  }
}

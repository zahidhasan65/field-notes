import '../../../core/core.dart';
import '../database/database_helper.dart';

/// Keeps one row per account that used this device (customers.user_id points here).
class UserLocalDataSource {
  UserLocalDataSource(this.helper);

  final DatabaseHelper helper;

  Future<void> upsert({
    required String id,
    required String name,
    required String email,
  }) async {
    final db = await helper.database;
    final values = {'name': name, 'email': email, 'updated_at': nowIso()};
    final updated = await db.update('users', values, where: 'id = ?', whereArgs: [id]);
    if (updated == 0) {
      await db.insert('users', {'id': id, ...values});
    }
  }
}

import '../../services/photo_storage.dart';
import '../local/data_sources/field_note_local_data_source.dart';
import '../local/database/database_helper.dart';
import 'data_events.dart';


class LocalDataRepository {
  LocalDataRepository({
    required this.helper,
    required this.notes,
    required this.photos,
  });

  final DatabaseHelper helper;
  final FieldNoteLocalDataSource notes;
  final PhotoStorage photos;

  Future<void> clearUserData(String userId) async {
    final photoPaths = await notes.photoPathsForUser(userId);
    final db = await helper.database;

    final profileRows = await db.query('app_settings',
        where: 'key = ?', whereArgs: ['profile_photo:$userId'], limit: 1);
    if (profileRows.isNotEmpty) photoPaths.add(profileRows.first['value'] as String);

    await db.transaction((txn) async {
      await txn.rawDelete('''
        DELETE FROM field_notes WHERE site_id IN (
          SELECT s.id FROM sites s
          JOIN customers c ON c.id = s.customer_id WHERE c.user_id = ?)
      ''', [userId]);
      await txn.rawDelete(
        'DELETE FROM sites WHERE customer_id IN (SELECT id FROM customers WHERE user_id = ?)',
        [userId],
      );
      await txn.delete('customers', where: 'user_id = ?', whereArgs: [userId]);
      await txn.delete('sync_queue', where: 'user_id = ?', whereArgs: [userId]);
      await txn.delete('notifications', where: 'user_id = ?', whereArgs: [userId]);
      await txn.delete(
        'app_settings',
        where: 'key IN (?, ?, ?, ?)',
        whereArgs: [
          'profile_photo:$userId',
          'restore_done:$userId',
          'last_pull:$userId',
          'last_synced:$userId',
        ],
      );
    });

    await photos.deleteAll(photoPaths);
    DataEvents.notify();
  }
}

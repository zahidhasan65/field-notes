import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';

class AppSettingsLocalDataSource {
  final DatabaseHelper databaseHelper;

  AppSettingsLocalDataSource({
    DatabaseHelper? databaseHelper,
  }) : databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  Future<void> saveSetting(
    String key,
    String value,
  ) async {
    final db = await databaseHelper.database;

    await db.insert(
      'app_settings',
      {
        'key': key,
        'value': value,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String key) async {
    final db = await databaseHelper.database;

    final result = await db.query(
      'app_settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first['value'] as String?;
  }

  Future<void> deleteSetting(String key) async {
    final db = await databaseHelper.database;

    await db.delete(
      'app_settings',
      where: 'key = ?',
      whereArgs: [key],
    );
  }
}

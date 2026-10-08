import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:mobile/data/local/database/database_helper.dart';
import 'package:mobile/data/repositories/app_settings_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('app setting can be saved and retrieved', () async {
    final db = await DatabaseHelper.instance.database;

    await db.delete('app_settings');

    final repository = AppSettingsRepository();

    await repository.saveSetting(
      'default_note_status',
      'OPEN',
    );

    final value = await repository.getSetting(
      'default_note_status',
    );

    expect(value, 'OPEN');

    await db.delete('app_settings');
    await db.close();
  });
}

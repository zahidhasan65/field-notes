import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:mobile/data/local/database/database_helper.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('SQLite database initializes successfully', () async {
    final db = await DatabaseHelper.instance.database;

    expect(db.isOpen, true);

    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name",
    );

    final tableNames = tables.map((table) => table['name'] as String).toList();

    expect(tableNames, contains('users'));
    expect(tableNames, contains('customers'));
    expect(tableNames, contains('sites'));
    expect(tableNames, contains('field_notes'));
    expect(tableNames, contains('sync_queue'));
    expect(tableNames, contains('app_settings'));

    await db.close();
  });
}

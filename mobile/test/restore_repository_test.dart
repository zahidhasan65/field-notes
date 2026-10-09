import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:mobile/core/storage/session_storage.dart';
import 'package:mobile/data/local/data_sources/customer_local_data_source.dart';
import 'package:mobile/data/local/data_sources/field_note_local_data_source.dart';
import 'package:mobile/data/local/data_sources/site_local_data_source.dart';
import 'package:mobile/data/local/database/database_helper.dart';
import 'package:mobile/data/remote/restore_remote_data_source.dart';
import 'package:mobile/data/repositories/restore_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeRestoreRemoteDataSource extends RestoreRemoteDataSource {
  FakeRestoreRemoteDataSource({
    required this.customers,
    required this.sites,
    required this.fieldNotes,
  });

  final List<Map<String, dynamic>> customers;
  final Map<String, List<Map<String, dynamic>>> sites;
  final Map<String, List<Map<String, dynamic>>> fieldNotes;

  @override
  Future<List<Map<String, dynamic>>> getCustomers() async {
    return customers;
  }

  @override
  Future<List<Map<String, dynamic>>> getSites(String customerId) async {
    return sites[customerId] ?? [];
  }

  @override
  Future<List<Map<String, dynamic>>> getFieldNotes(String siteId) async {
    return fieldNotes[siteId] ?? [];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'user_id': 'user-1',
      'auth_token': 'test-token',
    });

    final db = await DatabaseHelper.instance.database;

    await db.delete('sync_queue');
    await db.delete('field_notes');
    await db.delete('sites');
    await db.delete('customers');
    await db.delete('users');

    await db.insert('users', {
      'id': 'user-1',
      'name': 'Test User',
      'email': 'test@example.com',
      'created_at': '2026-01-01T00:00:00Z',
      'updated_at': '2026-01-01T00:00:00Z',
      'deleted_at': null,
    });
  });

  test('restores customers, sites and field notes', () async {
    final remote = FakeRestoreRemoteDataSource(
      customers: [
        {
          'id': 'customer-1',
          'name': 'Customer One',
          'contactInformation': '01700000000',
          'createdAt': '2026-01-01T00:00:00Z',
          'updatedAt': '2026-01-01T00:00:00Z',
        },
      ],
      sites: {
        'customer-1': [
          {
            'id': 'site-1',
            'customerId': 'customer-1',
            'name': 'Site One',
            'address': 'Dhaka',
            'createdAt': '2026-01-01T00:00:00Z',
            'updatedAt': '2026-01-01T00:00:00Z',
          },
        ],
      },
      fieldNotes: {
        'site-1': [
          {
            'id': 'note-1',
            'siteId': 'site-1',
            'note': 'Inspection completed.',
            'createdAt': '2026-01-01T00:00:00Z',
            'updatedAt': '2026-01-01T00:00:00Z',
          },
        ],
      },
    );

    final repository = RestoreRepository(
      remoteDataSource: remote,
      customerLocalDataSource: CustomerLocalDataSource(),
      siteLocalDataSource: SiteLocalDataSource(),
      fieldNoteLocalDataSource: FieldNoteLocalDataSource(),
      sessionStorage: SessionStorage(),
    );

    await repository.restore();

    final db = await DatabaseHelper.instance.database;

    final customers = await db.query('customers');
    final sites = await db.query('sites');
    final notes = await db.query('field_notes');
    final queue = await db.query('sync_queue');

    expect(customers.length, 1);
    expect(sites.length, 1);
    expect(notes.length, 1);

    expect(customers.first['user_id'], 'user-1');
    expect(sites.first['customer_id'], 'customer-1');
    expect(notes.first['site_id'], 'site-1');

    expect(customers.first['sync_status'], 'SYNCED');
    expect(sites.first['sync_status'], 'SYNCED');
    expect(notes.first['sync_status'], 'SYNCED');

    expect(notes.first['description'], 'Inspection completed.');

    expect(queue, isEmpty);
  });
}

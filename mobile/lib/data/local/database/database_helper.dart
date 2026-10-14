import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';




class DatabaseHelper {
  DatabaseHelper._internal();

  static final DatabaseHelper instance = DatabaseHelper._internal();

  static const int _version = 3;
  static Database? _database;

  Future<Database> get database async => _database ??= await _open();

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'field_notes.db');
    return openDatabase(
      path,
      version: _version,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) => _createTables(db),
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        contact_person TEXT,
        email TEXT,
        phone TEXT,
        address TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        sync_status TEXT NOT NULL DEFAULT 'SYNCED',
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE sites (
        id TEXT PRIMARY KEY,
        customer_id TEXT NOT NULL,
        site_name TEXT NOT NULL,
        address TEXT,
        latitude REAL,
        longitude REAL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        sync_status TEXT NOT NULL DEFAULT 'SYNCED',
        FOREIGN KEY (customer_id) REFERENCES customers(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE field_notes (
        id TEXT PRIMARY KEY,
        site_id TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        status TEXT NOT NULL DEFAULT 'PENDING',
        note_datetime TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        photo_url TEXT,
        photo_path TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        sync_status TEXT NOT NULL DEFAULT 'SYNCED',
        FOREIGN KEY (site_id) REFERENCES sites(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        payload TEXT NOT NULL,
        created_at TEXT NOT NULL,
        retry_count INTEGER NOT NULL DEFAULT 0,
        last_attempt_at TEXT,
        status TEXT NOT NULL DEFAULT 'PENDING',
        error_message TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await _createNotificationsTable(db);

    await db.execute('CREATE INDEX idx_customers_user ON customers(user_id)');
    await db.execute('CREATE INDEX idx_sites_customer ON sites(customer_id)');
    await db.execute('CREATE INDEX idx_notes_site ON field_notes(site_id)');
    await db.execute('CREATE INDEX idx_notes_date ON field_notes(note_datetime)');
    await db.execute('CREATE INDEX idx_queue_user ON sync_queue(user_id, status)');
  }

  Future<void> _createNotificationsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS notifications (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        body TEXT,
        created_at TEXT NOT NULL,
        is_read INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id, created_at)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE customers ADD COLUMN contact_person TEXT');
      await db.execute('ALTER TABLE customers ADD COLUMN email TEXT');
      await db.execute('ALTER TABLE customers ADD COLUMN phone TEXT');
      await db.execute('ALTER TABLE customers ADD COLUMN address TEXT');
      await db.execute('ALTER TABLE sites ADD COLUMN latitude REAL');
      await db.execute('ALTER TABLE sites ADD COLUMN longitude REAL');
      await db.execute('ALTER TABLE field_notes ADD COLUMN photo_path TEXT');
      await db.execute(
        "ALTER TABLE sync_queue ADD COLUMN user_id TEXT NOT NULL DEFAULT ''",
      );
    }
    if (oldVersion < 3) {
      await _createNotificationsTable(db);
    }
  }

  Future<void> wipeEverything() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('field_notes');
      await txn.delete('sites');
      await txn.delete('customers');
      await txn.delete('sync_queue');
      await txn.delete('notifications');
      await txn.delete('app_settings');
    });
  }
}

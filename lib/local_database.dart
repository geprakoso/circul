import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class CirculDatabase {
  CirculDatabase._();

  static final CirculDatabase instance = CirculDatabase._();

  static const feedPostsTable = 'feed_posts';

  Database? _database;

  Future<Database> get database async {
    final current = _database;
    if (current != null) return current;

    final dbPath = await getDatabasesPath();
    final database = await openDatabase(
      p.join(dbPath, 'circul.db'),
      version: 2,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _create,
      onUpgrade: _upgrade,
    );

    _database = database;
    return database;
  }

  Future<void> _create(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $feedPostsTable (
        id TEXT PRIMARY KEY,
        author TEXT NOT NULL,
        city TEXT NOT NULL,
        time_ago TEXT NOT NULL,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        image_asset TEXT NOT NULL,
        image_paths TEXT NOT NULL DEFAULT '[]',
        likes INTEGER NOT NULL DEFAULT 0,
        comments INTEGER NOT NULL DEFAULT 0,
        topic TEXT,
        allow_replies INTEGER NOT NULL DEFAULT 1,
        sync_status TEXT NOT NULL DEFAULT 'local',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_feed_posts_created_at '
      'ON $feedPostsTable(created_at DESC)',
    );
  }

  Future<void> _upgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        "ALTER TABLE $feedPostsTable "
        "ADD COLUMN image_paths TEXT NOT NULL DEFAULT '[]'",
      );
    }
  }
}

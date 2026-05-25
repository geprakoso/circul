import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class CirculDatabase {
  CirculDatabase._();

  static final CirculDatabase instance = CirculDatabase._();

  static const feedPostsTable = 'feed_posts';
  static const postCommentsTable = 'post_comments';

  Database? _database;

  Future<Database> get database async {
    final current = _database;
    if (current != null) return current;

    final dbPath = await getDatabasesPath();
    final database = await openDatabase(
      p.join(dbPath, 'circul.db'),
      version: 6,
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
    await _createFeedPostsTable(db);
    await _createPostCommentsTable(db);
  }

  Future<void> _createFeedPostsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $feedPostsTable (
        id TEXT PRIMARY KEY,
        author TEXT NOT NULL,
        city TEXT NOT NULL,
        time_ago TEXT NOT NULL,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        image_asset TEXT NOT NULL,
        image_paths TEXT NOT NULL DEFAULT '[]',
        location_enabled INTEGER NOT NULL DEFAULT 0,
        location_label TEXT,
        coordinate_label TEXT,
        location_latitude REAL,
        location_longitude REAL,
        checkout_completed INTEGER NOT NULL DEFAULT 0,
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
      'CREATE INDEX IF NOT EXISTS idx_feed_posts_created_at '
      'ON $feedPostsTable(created_at DESC)',
    );
  }

  Future<void> _createPostCommentsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $postCommentsTable (
        id TEXT PRIMARY KEY,
        post_id TEXT NOT NULL,
        author TEXT NOT NULL,
        time_ago TEXT NOT NULL,
        body TEXT NOT NULL,
        initials TEXT NOT NULL,
        avatar_color INTEGER NOT NULL,
        location_enabled INTEGER NOT NULL DEFAULT 0,
        location_label TEXT,
        coordinate_label TEXT,
        location_latitude REAL,
        location_longitude REAL,
        likes INTEGER NOT NULL DEFAULT 0,
        sync_status TEXT NOT NULL DEFAULT 'local',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY(post_id) REFERENCES $feedPostsTable(id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_post_comments_post_created_at '
      'ON $postCommentsTable(post_id, created_at ASC)',
    );
  }

  Future<void> _upgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        "ALTER TABLE $feedPostsTable "
        "ADD COLUMN image_paths TEXT NOT NULL DEFAULT '[]'",
      );
    }
    if (oldVersion < 3) {
      await _createPostCommentsTable(db);
    }
    if (oldVersion < 4) {
      await db.execute(
        "ALTER TABLE $feedPostsTable "
        "ADD COLUMN location_enabled INTEGER NOT NULL DEFAULT 0",
      );
      await db.execute(
        "ALTER TABLE $feedPostsTable ADD COLUMN location_label TEXT",
      );
      await db.execute(
        "ALTER TABLE $feedPostsTable ADD COLUMN coordinate_label TEXT",
      );
    }
    if (oldVersion < 5) {
      await db.execute(
        "ALTER TABLE $feedPostsTable ADD COLUMN location_latitude REAL",
      );
      await db.execute(
        "ALTER TABLE $feedPostsTable ADD COLUMN location_longitude REAL",
      );
    }
    if (oldVersion < 6) {
      await db.execute(
        "ALTER TABLE $feedPostsTable "
        "ADD COLUMN checkout_completed INTEGER NOT NULL DEFAULT 0",
      );
      if (oldVersion >= 3) {
        await db.execute(
          "ALTER TABLE $postCommentsTable "
          "ADD COLUMN location_enabled INTEGER NOT NULL DEFAULT 0",
        );
        await db.execute(
          "ALTER TABLE $postCommentsTable ADD COLUMN location_label TEXT",
        );
        await db.execute(
          "ALTER TABLE $postCommentsTable ADD COLUMN coordinate_label TEXT",
        );
        await db.execute(
          "ALTER TABLE $postCommentsTable ADD COLUMN location_latitude REAL",
        );
        await db.execute(
          "ALTER TABLE $postCommentsTable ADD COLUMN location_longitude REAL",
        );
      }
    }
  }
}

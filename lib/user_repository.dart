import 'package:sqflite/sqflite.dart';

import 'local_database.dart';
import 'profile/editable_profile.dart';

class UserRepository {
  UserRepository({CirculDatabase? database})
    : _database = database ?? CirculDatabase.instance;

  static const currentUserId = 'current_user';
  static const defaultProfile = EditableProfile(
    name: 'Sarah Mae',
    username: 'sarahmae',
    bio:
        'Berusaha hidup lebih berkelanjutan \u{1F33F}\nBelajar, berbagi, dan berdampak.',
    location: 'Jakarta, Indonesia',
  );

  final CirculDatabase _database;

  Future<EditableProfile> getCurrentUserProfile() async {
    final db = await _database.database;
    await _seedCurrentUserIfNeeded(db);

    final rows = await db.query(
      CirculDatabase.usersTable,
      where: 'is_current = 1',
      orderBy: 'updated_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return defaultProfile;

    return _profileFromRow(rows.first);
  }

  Future<Set<String>> getTakenUsernames({String excludingUserId = ''}) async {
    final db = await _database.database;
    await _seedCurrentUserIfNeeded(db);

    final rows = await db.query(
      CirculDatabase.usersTable,
      columns: const ['username'],
      where: excludingUserId.trim().isEmpty ? null : 'id != ?',
      whereArgs: excludingUserId.trim().isEmpty ? null : [excludingUserId],
    );

    return rows.map((row) => row['username']).whereType<String>().toSet();
  }

  Future<void> saveCurrentUserProfile(EditableProfile profile) async {
    final db = await _database.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final cleanProfile = _cleanProfile(profile);

    await db.transaction((txn) async {
      await txn.update(
        CirculDatabase.usersTable,
        {'is_current': 0, 'updated_at': now},
        where: 'id != ? AND is_current = 1',
        whereArgs: [currentUserId],
      );

      final existing = await txn.query(
        CirculDatabase.usersTable,
        columns: const ['id'],
        where: 'id = ?',
        whereArgs: [currentUserId],
        limit: 1,
      );

      final values = {
        'name': cleanProfile.name,
        'username': cleanProfile.username,
        'bio': cleanProfile.bio,
        'location': cleanProfile.location,
        'image_path': cleanProfile.imagePath,
        'is_current': 1,
        'sync_status': 'local',
        'updated_at': now,
      };

      if (existing.isEmpty) {
        await txn.insert(CirculDatabase.usersTable, {
          'id': currentUserId,
          ...values,
          'created_at': now,
        }, conflictAlgorithm: ConflictAlgorithm.abort);
      } else {
        await txn.update(
          CirculDatabase.usersTable,
          values,
          where: 'id = ?',
          whereArgs: [currentUserId],
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
      }
    });
  }

  Future<void> _seedCurrentUserIfNeeded(Database db) async {
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${CirculDatabase.usersTable}'),
    );
    if ((count ?? 0) > 0) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert(CirculDatabase.usersTable, {
      'id': currentUserId,
      'name': defaultProfile.name,
      'username': defaultProfile.username,
      'bio': defaultProfile.bio,
      'location': defaultProfile.location,
      'image_path': defaultProfile.imagePath,
      'is_current': 1,
      'sync_status': 'synced',
      'created_at': now,
      'updated_at': now,
    });
  }

  EditableProfile _profileFromRow(Map<String, Object?> row) {
    return EditableProfile(
      name: row['name'] as String,
      username: row['username'] as String,
      bio: row['bio'] as String,
      location: row['location'] as String,
      imagePath: row['image_path'] as String?,
    );
  }

  EditableProfile _cleanProfile(EditableProfile profile) {
    return EditableProfile(
      name: profile.name.trim(),
      username: profile.username.trim().replaceFirst(RegExp(r'^@+'), ''),
      bio: profile.bio.trim(),
      location: profile.location.trim(),
      imagePath: profile.imagePath?.trim().isEmpty == true
          ? null
          : profile.imagePath,
    );
  }
}

import 'package:sqflite/sqflite.dart';

import 'auth/profile_remote_data_source.dart';
import 'local_database.dart';
import 'profile/editable_profile.dart';

class UserRepository {
  UserRepository({
    CirculDatabase? database,
    ProfileRemoteDataSource? remoteProfileDataSource,
  }) : _database = database ?? CirculDatabase.instance,
       _remoteProfileDataSource = remoteProfileDataSource;

  static const currentUserId = 'current_user';
  static const defaultProfile = EditableProfile(
    name: 'Sarah Mae',
    username: 'sarahmae',
    bio:
        'Berusaha hidup lebih berkelanjutan \u{1F33F}\nBelajar, berbagi, dan berdampak.',
    location: 'Jakarta, Indonesia',
  );

  final CirculDatabase _database;
  final ProfileRemoteDataSource? _remoteProfileDataSource;

  Future<EditableProfile> getCurrentUserProfile() async {
    final remote = _remoteProfileDataSource;
    if (remote?.currentUserId != null) {
      try {
        final profile = await remote!.fetchCurrentProfile();
        if (profile != null) {
          await _saveLocalCurrentUserProfile(
            profile,
            id: remote.currentUserId ?? currentUserId,
            syncStatus: 'synced',
          );
          return profile;
        }
      } catch (_) {
        // Fall back to the local cache if the network request fails.
      }
    }

    final db = await _database.database;

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
    final remote = _remoteProfileDataSource;
    if (remote?.currentUserId != null) {
      try {
        return await remote!.fetchTakenUsernames(
          excludingUserId: excludingUserId == currentUserId
              ? remote.currentUserId ?? excludingUserId
              : excludingUserId,
        );
      } catch (_) {
        // Local data is good enough for validation while offline.
      }
    }

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
    final cleanProfile = _cleanProfile(profile);
    final remote = _remoteProfileDataSource;
    if (remote?.currentUserId != null) {
      await remote!.saveCurrentProfile(cleanProfile);
      await _saveLocalCurrentUserProfile(
        cleanProfile,
        id: remote.currentUserId ?? currentUserId,
        syncStatus: 'synced',
      );
      return;
    }

    await _saveLocalCurrentUserProfile(cleanProfile);
  }

  Future<void> _saveLocalCurrentUserProfile(
    EditableProfile profile, {
    String id = currentUserId,
    String syncStatus = 'local',
  }) async {
    final db = await _database.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.transaction((txn) async {
      await txn.update(
        CirculDatabase.usersTable,
        {'is_current': 0, 'updated_at': now},
        where: 'id != ? AND is_current = 1',
        whereArgs: [id],
      );

      final existing = await txn.query(
        CirculDatabase.usersTable,
        columns: const ['id'],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      final values = {
        'name': profile.name,
        'username': profile.username,
        'bio': profile.bio,
        'location': profile.location,
        'image_path': profile.imagePath,
        'is_current': 1,
        'sync_status': syncStatus,
        'updated_at': now,
      };

      if (existing.isEmpty) {
        await txn.insert(CirculDatabase.usersTable, {
          'id': id,
          ...values,
          'created_at': now,
        }, conflictAlgorithm: ConflictAlgorithm.abort);
      } else {
        await txn.update(
          CirculDatabase.usersTable,
          values,
          where: 'id = ?',
          whereArgs: [id],
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

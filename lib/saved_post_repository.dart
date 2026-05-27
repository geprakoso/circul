import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'local_database.dart';
import 'mock_data.dart';

enum SavePostResult { saved, alreadySaved }

class SavedPostRepository {
  SavedPostRepository({CirculDatabase? database})
    : _database = database ?? CirculDatabase.instance;

  final CirculDatabase _database;

  Future<SavePostResult> savePost(FeedPost post) async {
    if (post.id.isEmpty) {
      throw ArgumentError.value(post.id, 'post.id', 'Post id is required.');
    }

    final db = await _database.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final rowId = await db.insert(CirculDatabase.savedPostsTable, {
      'post_id': post.id,
      'created_at': now,
      'updated_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    return rowId == 0 ? SavePostResult.alreadySaved : SavePostResult.saved;
  }

  Future<List<FeedPost>> getSavedPosts() async {
    final db = await _database.database;
    final rows = await db.rawQuery('''
      SELECT p.*
      FROM ${CirculDatabase.savedPostsTable} s
      INNER JOIN ${CirculDatabase.feedPostsTable} p ON p.id = s.post_id
      ORDER BY s.created_at DESC
      ''');

    return rows.map(_postFromRow).toList(growable: false);
  }

  Future<void> deleteSavedPost(FeedPost post) async {
    if (post.id.isEmpty) return;

    final db = await _database.database;
    await db.delete(
      CirculDatabase.savedPostsTable,
      where: 'post_id = ?',
      whereArgs: [post.id],
    );
  }

  FeedPost _postFromRow(Map<String, Object?> row) {
    return FeedPost(
      id: row['id'] as String,
      author: row['author'] as String,
      city: row['city'] as String,
      timeAgo: row['time_ago'] as String,
      title: row['title'] as String,
      body: row['body'] as String,
      imageAsset: row['image_asset'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      topic: (row['topic'] as String?) ?? '',
      imagePaths: _imagePathsFromRow(row['image_paths']),
      locationEnabled: row['location_enabled'] == 1,
      locationLabel: row['location_label'] as String?,
      coordinateLabel: row['coordinate_label'] as String?,
      locationLatitude: _doubleFromRow(row['location_latitude']),
      locationLongitude: _doubleFromRow(row['location_longitude']),
      checkoutCompleted: row['checkout_completed'] == 1,
      likes: row['likes'] as int,
      comments: row['comments'] as int,
    );
  }

  double? _doubleFromRow(Object? value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return null;
  }

  List<String> _imagePathsFromRow(Object? value) {
    if (value is! String || value.isEmpty) return const [];

    try {
      final decoded = jsonDecode(value);
      if (decoded is! List) return const [];
      return decoded.whereType<String>().toList(growable: false);
    } catch (_) {
      return const [];
    }
  }
}

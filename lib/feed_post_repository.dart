import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'local_database.dart';
import 'mock_data.dart';

class FeedPostRepository {
  FeedPostRepository({CirculDatabase? database})
    : _database = database ?? CirculDatabase.instance;

  final CirculDatabase _database;

  Future<List<FeedPost>> getPosts() async {
    final db = await _database.database;
    await _seedInitialPostsIfNeeded(db);

    final rows = await db.query(
      CirculDatabase.feedPostsTable,
      orderBy: 'created_at DESC',
    );

    return rows.map(_postFromRow).toList();
  }

  Future<void> addPost({
    required String body,
    required String topic,
    required bool allowReplies,
    List<String> imagePaths = const [],
  }) async {
    final db = await _database.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final cleanBody = body.trim();
    final cleanTopic = topic.trim();

    await db.insert(CirculDatabase.feedPostsTable, {
      'id': 'local_$now',
      'author': 'sarahmae',
      'city': 'Solo',
      'time_ago': 'Baru saja',
      'title': cleanTopic.isEmpty ? 'Update komunitas' : cleanTopic,
      'body': cleanBody,
      'image_asset': imagePaths.isEmpty ? cleanupAsset : '',
      'image_paths': jsonEncode(imagePaths),
      'likes': 0,
      'comments': 0,
      'topic': cleanTopic.isEmpty ? null : cleanTopic,
      'allow_replies': allowReplies ? 1 : 0,
      'sync_status': 'local',
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<void> _seedInitialPostsIfNeeded(Database db) async {
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM ${CirculDatabase.feedPostsTable}',
      ),
    );
    if ((count ?? 0) > 0) return;

    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;

    for (var i = 0; i < feedPosts.length; i++) {
      final post = feedPosts[i];
      final createdAt = now - Duration(hours: i + 2).inMilliseconds;
      batch.insert(CirculDatabase.feedPostsTable, {
        'id': 'seed_${i + 1}',
        'author': post.author,
        'city': post.city,
        'time_ago': post.timeAgo,
        'title': post.title,
        'body': post.body,
        'image_asset': post.imageAsset,
        'image_paths': jsonEncode(post.imagePaths),
        'likes': post.likes,
        'comments': post.comments,
        'topic': null,
        'allow_replies': 1,
        'sync_status': 'synced',
        'created_at': createdAt,
        'updated_at': createdAt,
      });
    }

    await batch.commit(noResult: true);
  }

  FeedPost _postFromRow(Map<String, Object?> row) {
    return FeedPost(
      author: row['author'] as String,
      city: row['city'] as String,
      timeAgo: row['time_ago'] as String,
      title: row['title'] as String,
      body: row['body'] as String,
      imageAsset: row['image_asset'] as String,
      imagePaths: _imagePathsFromRow(row['image_paths']),
      likes: row['likes'] as int,
      comments: row['comments'] as int,
    );
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

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
    String? city,
    List<String> imagePaths = const [],
    bool locationEnabled = false,
    String? locationLabel,
    String? coordinateLabel,
    double? locationLatitude,
    double? locationLongitude,
  }) async {
    final db = await _database.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final cleanBody = body.trim();
    final cleanTopic = topic.trim();
    final cleanCity = city?.trim();
    final cleanLocationLabel = locationLabel?.trim();
    final cleanCoordinateLabel = coordinateLabel?.trim();

    await db.insert(CirculDatabase.feedPostsTable, {
      'id': 'local_$now',
      'author': 'sarahmae',
      'city': cleanCity?.isNotEmpty == true ? cleanCity! : 'Solo',
      'time_ago': 'Baru saja',
      'title': cleanTopic.isEmpty ? 'Update komunitas' : cleanTopic,
      'body': cleanBody,
      'image_asset': imagePaths.isEmpty && !locationEnabled ? cleanupAsset : '',
      'image_paths': jsonEncode(imagePaths),
      'location_enabled': locationEnabled ? 1 : 0,
      'location_label': cleanLocationLabel?.isNotEmpty == true
          ? cleanLocationLabel
          : null,
      'coordinate_label': cleanCoordinateLabel?.isNotEmpty == true
          ? cleanCoordinateLabel
          : null,
      'location_latitude': locationLatitude,
      'location_longitude': locationLongitude,
      'checkout_completed': 0,
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
        'location_enabled': post.locationEnabled ? 1 : 0,
        'location_label': post.locationLabel,
        'coordinate_label': post.coordinateLabel,
        'location_latitude': post.locationLatitude,
        'location_longitude': post.locationLongitude,
        'checkout_completed': post.checkoutCompleted ? 1 : 0,
        'likes': post.likes,
        'comments': post.comments,
        'topic': post.topic.isEmpty ? null : post.topic,
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

  Future<void> completeCheckout(String postId) async {
    if (postId.isEmpty) return;

    final db = await _database.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      CirculDatabase.feedPostsTable,
      {'checkout_completed': 1, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [postId],
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

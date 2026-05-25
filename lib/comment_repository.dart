import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import 'local_database.dart';
import 'mock_data.dart';

class CommentRepository {
  CommentRepository({CirculDatabase? database})
    : _database = database ?? CirculDatabase.instance;

  final CirculDatabase _database;

  Future<List<PostComment>> getComments(FeedPost post) async {
    if (post.id.isEmpty) return postComments;

    final db = await _database.database;
    await _seedInitialCommentsIfNeeded(db, post.id);

    final rows = await db.query(
      CirculDatabase.postCommentsTable,
      where: 'post_id = ?',
      whereArgs: [post.id],
      orderBy: 'created_at ASC',
    );

    return rows.map(_commentFromRow).toList(growable: false);
  }

  Future<PostComment> addComment({
    required FeedPost post,
    required String body,
  }) async {
    final cleanBody = body.trim();
    if (cleanBody.isEmpty) {
      throw ArgumentError.value(body, 'body', 'Comment body cannot be empty.');
    }

    final now = DateTime.now().microsecondsSinceEpoch;
    final comment = PostComment(
      id: 'comment_$now',
      postId: post.id,
      author: 'sarahmae',
      timeAgo: 'Baru saja',
      body: cleanBody,
      initials: 'SM',
      avatarColor: kCirculGreen,
    );

    if (post.id.isEmpty) return comment;

    final db = await _database.database;
    await db.insert(CirculDatabase.postCommentsTable, {
      'id': comment.id,
      'post_id': comment.postId,
      'author': comment.author,
      'time_ago': comment.timeAgo,
      'body': comment.body,
      'initials': comment.initials,
      'avatar_color': comment.avatarColor.toARGB32(),
      'location_enabled': 0,
      'location_label': null,
      'coordinate_label': null,
      'location_latitude': null,
      'location_longitude': null,
      'likes': comment.likes,
      'sync_status': 'local',
      'created_at': now,
      'updated_at': now,
    });

    try {
      await db.rawUpdate(
        'UPDATE ${CirculDatabase.feedPostsTable} '
        'SET comments = comments + 1, updated_at = ? '
        'WHERE id = ?',
        [now, post.id],
      );
    } catch (_) {
      // The comment is already saved; a stale counter should not surface as a
      // failed comment submission.
    }

    return comment;
  }

  Future<PostComment> addCheckoutComment({required FeedPost post}) async {
    final now = DateTime.now().microsecondsSinceEpoch;
    final comment = PostComment(
      id: 'checkout_comment_$now',
      postId: post.id,
      author: 'sarahmae',
      timeAgo: 'Baru saja',
      body: 'Telah menyelesaikan checkout',
      initials: 'SM',
      avatarColor: kCirculGreen,
      locationEnabled: true,
      locationLabel: post.locationLabel ?? post.city,
      coordinateLabel: post.coordinateLabel,
      locationLatitude: post.locationLatitude,
      locationLongitude: post.locationLongitude,
    );

    if (post.id.isEmpty) return comment;

    final db = await _database.database;
    await db.insert(CirculDatabase.postCommentsTable, {
      'id': comment.id,
      'post_id': comment.postId,
      'author': comment.author,
      'time_ago': comment.timeAgo,
      'body': comment.body,
      'initials': comment.initials,
      'avatar_color': comment.avatarColor.toARGB32(),
      'location_enabled': 1,
      'location_label': comment.locationLabel,
      'coordinate_label': comment.coordinateLabel,
      'location_latitude': comment.locationLatitude,
      'location_longitude': comment.locationLongitude,
      'likes': comment.likes,
      'sync_status': 'local',
      'created_at': now,
      'updated_at': now,
    });

    await db.rawUpdate(
      'UPDATE ${CirculDatabase.feedPostsTable} '
      'SET comments = comments + 1, updated_at = ? '
      'WHERE id = ?',
      [now, post.id],
    );

    return comment;
  }

  Future<void> _seedInitialCommentsIfNeeded(Database db, String postId) async {
    if (!postId.startsWith('seed_')) return;

    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM ${CirculDatabase.postCommentsTable} '
        'WHERE post_id = ?',
        [postId],
      ),
    );
    if ((count ?? 0) > 0) return;

    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;

    for (var i = 0; i < postComments.length; i++) {
      final comment = postComments[i];
      final createdAt =
          now - Duration(minutes: postComments.length - i).inMilliseconds;
      batch.insert(CirculDatabase.postCommentsTable, {
        'id': '${postId}_comment_${i + 1}',
        'post_id': postId,
        'author': comment.author,
        'time_ago': comment.timeAgo,
        'body': comment.body,
        'initials': comment.initials,
        'avatar_color': comment.avatarColor.toARGB32(),
        'location_enabled': comment.locationEnabled ? 1 : 0,
        'location_label': comment.locationLabel,
        'coordinate_label': comment.coordinateLabel,
        'location_latitude': comment.locationLatitude,
        'location_longitude': comment.locationLongitude,
        'likes': comment.likes,
        'sync_status': 'synced',
        'created_at': createdAt,
        'updated_at': createdAt,
      });
    }

    await batch.commit(noResult: true);
  }

  PostComment _commentFromRow(Map<String, Object?> row) {
    return PostComment(
      id: row['id'] as String,
      postId: row['post_id'] as String,
      author: row['author'] as String,
      timeAgo: row['time_ago'] as String,
      body: row['body'] as String,
      initials: row['initials'] as String,
      avatarColor: Color(row['avatar_color'] as int),
      likes: row['likes'] as int,
      locationEnabled: row['location_enabled'] == 1,
      locationLabel: row['location_label'] as String?,
      coordinateLabel: row['coordinate_label'] as String?,
      locationLatitude: _doubleFromRow(row['location_latitude']),
      locationLongitude: _doubleFromRow(row['location_longitude']),
    );
  }

  double? _doubleFromRow(Object? value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return null;
  }
}

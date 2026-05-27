import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import 'local_database.dart';
import 'mock_data.dart';

class UserCommentResult {
  const UserCommentResult({required this.comment, required this.post});

  final PostComment comment;
  final FeedPost post;
}

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

  Future<List<UserCommentResult>> getCommentsByAuthor(String author) async {
    final cleanAuthor = author.trim();
    if (cleanAuthor.isEmpty) return const [];

    final db = await _database.database;
    final rows = await db.rawQuery(
      '''
      SELECT
        c.id AS comment_id,
        c.post_id AS comment_post_id,
        c.author AS comment_author,
        c.time_ago AS comment_time_ago,
        c.body AS comment_body,
        c.initials AS comment_initials,
        c.avatar_color AS comment_avatar_color,
        c.location_enabled AS comment_location_enabled,
        c.location_label AS comment_location_label,
        c.coordinate_label AS comment_coordinate_label,
        c.location_latitude AS comment_location_latitude,
        c.location_longitude AS comment_location_longitude,
        c.likes AS comment_likes,
        p.id AS post_id,
        p.author AS post_author,
        p.city AS post_city,
        p.time_ago AS post_time_ago,
        p.title AS post_title,
        p.body AS post_body,
        p.image_asset AS post_image_asset,
        p.image_paths AS post_image_paths,
        p.location_enabled AS post_location_enabled,
        p.location_label AS post_location_label,
        p.coordinate_label AS post_coordinate_label,
        p.location_latitude AS post_location_latitude,
        p.location_longitude AS post_location_longitude,
        p.checkout_completed AS post_checkout_completed,
        p.likes AS post_likes,
        p.comments AS post_comments,
        p.topic AS post_topic,
        p.created_at AS post_created_at
      FROM ${CirculDatabase.postCommentsTable} c
      INNER JOIN ${CirculDatabase.feedPostsTable} p ON p.id = c.post_id
      WHERE lower(c.author) = lower(?)
      ORDER BY c.created_at DESC
      ''',
      [cleanAuthor],
    );

    return rows
        .map(
          (row) => UserCommentResult(
            comment: _commentFromAuthorRow(row),
            post: _postFromAuthorRow(row),
          ),
        )
        .toList(growable: false);
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

  PostComment _commentFromAuthorRow(Map<String, Object?> row) {
    return PostComment(
      id: row['comment_id'] as String,
      postId: row['comment_post_id'] as String,
      author: row['comment_author'] as String,
      timeAgo: row['comment_time_ago'] as String,
      body: row['comment_body'] as String,
      initials: row['comment_initials'] as String,
      avatarColor: Color(row['comment_avatar_color'] as int),
      likes: row['comment_likes'] as int,
      locationEnabled: row['comment_location_enabled'] == 1,
      locationLabel: row['comment_location_label'] as String?,
      coordinateLabel: row['comment_coordinate_label'] as String?,
      locationLatitude: _doubleFromRow(row['comment_location_latitude']),
      locationLongitude: _doubleFromRow(row['comment_location_longitude']),
    );
  }

  FeedPost _postFromAuthorRow(Map<String, Object?> row) {
    return FeedPost(
      id: row['post_id'] as String,
      author: row['post_author'] as String,
      city: row['post_city'] as String,
      timeAgo: row['post_time_ago'] as String,
      title: row['post_title'] as String,
      body: row['post_body'] as String,
      imageAsset: row['post_image_asset'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row['post_created_at'] as int,
      ),
      topic: (row['post_topic'] as String?) ?? '',
      imagePaths: _imagePathsFromRow(row['post_image_paths']),
      locationEnabled: row['post_location_enabled'] == 1,
      locationLabel: row['post_location_label'] as String?,
      coordinateLabel: row['post_coordinate_label'] as String?,
      locationLatitude: _doubleFromRow(row['post_location_latitude']),
      locationLongitude: _doubleFromRow(row['post_location_longitude']),
      checkoutCompleted: row['post_checkout_completed'] == 1,
      likes: row['post_likes'] as int,
      comments: row['post_comments'] as int,
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

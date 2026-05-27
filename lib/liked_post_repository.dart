import 'package:sqflite/sqflite.dart';

import 'local_database.dart';
import 'mock_data.dart';

class LikePostResult {
  const LikePostResult({required this.isLiked, required this.likes});

  final bool isLiked;
  final int likes;
}

class LikedPostRepository {
  LikedPostRepository({CirculDatabase? database})
    : _database = database ?? CirculDatabase.instance;

  final CirculDatabase _database;

  Future<bool> isLiked(FeedPost post) async {
    if (post.id.isEmpty) return false;

    final db = await _database.database;
    final rows = await db.query(
      CirculDatabase.likedPostsTable,
      columns: const ['post_id'],
      where: 'post_id = ?',
      whereArgs: [post.id],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<LikePostResult> toggleLike(FeedPost post) async {
    if (post.id.isEmpty) {
      return LikePostResult(isLiked: true, likes: post.likes + 1);
    }

    final db = await _database.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    return db.transaction((txn) async {
      final rows = await txn.query(
        CirculDatabase.likedPostsTable,
        columns: const ['post_id'],
        where: 'post_id = ?',
        whereArgs: [post.id],
        limit: 1,
      );

      final wasLiked = rows.isNotEmpty;
      if (wasLiked) {
        await txn.delete(
          CirculDatabase.likedPostsTable,
          where: 'post_id = ?',
          whereArgs: [post.id],
        );
        await txn.rawUpdate(
          'UPDATE ${CirculDatabase.feedPostsTable} '
          'SET likes = CASE WHEN likes > 0 THEN likes - 1 ELSE 0 END, '
          'updated_at = ? '
          'WHERE id = ?',
          [now, post.id],
        );
      } else {
        await txn.insert(
          CirculDatabase.likedPostsTable,
          {'post_id': post.id, 'created_at': now, 'updated_at': now},
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
        await txn.rawUpdate(
          'UPDATE ${CirculDatabase.feedPostsTable} '
          'SET likes = likes + 1, updated_at = ? '
          'WHERE id = ?',
          [now, post.id],
        );
      }

      final count = Sqflite.firstIntValue(
        await txn.rawQuery(
          'SELECT likes FROM ${CirculDatabase.feedPostsTable} WHERE id = ?',
          [post.id],
        ),
      );

      return LikePostResult(isLiked: !wasLiked, likes: count ?? post.likes);
    });
  }
}

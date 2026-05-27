import 'package:circul/comment_repository.dart';
import 'package:circul/feed_post_repository.dart';
import 'package:circul/home/widgets/feed_post_card.dart';
import 'package:circul/liked_post_repository.dart';
import 'package:circul/main.dart';
import 'package:circul/mock_data.dart';
import 'package:circul/profile/profile_screen.dart';
import 'package:circul/saved_post_repository.dart';
import 'package:circul/shared/animated_like_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders Circul app shell and navigates primary tabs', (
    tester,
  ) async {
    await tester.pumpWidget(
      CirculApp(feedPostRepository: _FakeFeedPostRepository()),
    );
    await tester.pump();

    expect(find.text('Circul'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Peta'), findsOneWidget);
    expect(find.text('Cari'), findsOneWidget);
    expect(find.text('Event'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);
    expect(
      find.text('Tips mengurangi sampah plastik di rumah 🌿'),
      findsOneWidget,
    );

    await tester.tap(
      find.text(
        'Beberapa hal kecil yang aku lakukan dan lumayan berdampak. Yuk mulai bareng-bareng!',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Give your response'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('CaterineWilz'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('CaterineWilz'), findsOneWidget);

    Navigator.of(tester.element(find.text('Give your response'))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cari'));
    await tester.pumpAndSettle();
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('#sampahplastik'), findsOneWidget);
    expect(find.text('Gaya Hidup Berkelanjutan'), findsOneWidget);

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    expect(find.text('Sarah Mae'), findsWidgets);
    expect(find.text('Achievement'), findsWidgets);
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -260));
    await tester.pumpAndSettle();
    expect(find.text('Eco Starter'), findsOneWidget);

    await tester.tap(find.text('Peta'));
    await tester.pumpAndSettle();
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.byType(TileLayer), findsOneWidget);
    expect(
      find.widgetWithText(TextField, 'Cari lokasi di map'),
      findsOneWidget,
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Cari lokasi di map'),
      '-7.5584, 110.8199',
    );
    await tester.pump();
    expect(find.text('Gunakan koordinat ini'), findsOneWidget);
    expect(find.byIcon(Icons.my_location_rounded), findsOneWidget);
    expect(find.byIcon(Icons.flag_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.flag_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Check-in'), findsOneWidget);
    expect(find.text('Check-out'), findsOneWidget);

    await tester.tap(find.text('Check-in'));
    await tester.pumpAndSettle();
    expect(find.text('Capture Result'), findsOneWidget);
    expect(find.text('Step 2 of 3'), findsNothing);
    expect(find.text('Is the environment\nup or down?'), findsOneWidget);

    Navigator.of(tester.element(find.text('Capture Result'))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Event'));
    await tester.pumpAndSettle();
    expect(find.text('Event'), findsWidgets);
    expect(find.text('Aksi Bersih Sungai Pepe'), findsWidgets);
  });

  testWidgets('profile postingan tab renders all posts by Sarah', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfileScreen(
            feedPostRepository: _FakeFeedPostRepository(
              posts: [
                ...feedPosts,
                const FeedPost(
                  author: 'anotheruser',
                  city: 'Jakarta',
                  timeAgo: '1 jam',
                  title: 'Postingan orang lain',
                  body: 'Ini tidak tampil di profil Sarah.',
                  imageAsset: cleanupAsset,
                  likes: 4,
                  comments: 1,
                ),
              ],
            ),
            commentRepository: _FakeCommentRepository(),
            savedPostRepository: _FakeSavedPostRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Tips mengurangi sampah plastik di rumah 🌿'),
      500,
      scrollable: find.byType(Scrollable).first,
    );

    expect(
      find.text('Tips mengurangi sampah plastik di rumah 🌿'),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.text('Buku tentang lingkungan yang mengubah cara pandangku 📖'),
      500,
      scrollable: find.byType(Scrollable).first,
    );

    expect(
      find.text('Buku tentang lingkungan yang mengubah cara pandangku 📖'),
      findsOneWidget,
    );
    expect(find.text('Bagikan'), findsWidgets);
    expect(find.byIcon(Icons.favorite_border_rounded), findsWidgets);
    expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsWidgets);
    expect(find.byIcon(Icons.reply_rounded), findsWidgets);
    expect(find.text('Postingan orang lain'), findsNothing);
  });

  testWidgets('profile komentar tab renders user comment with source post', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfileScreen(
            feedPostRepository: _FakeFeedPostRepository(),
            commentRepository: _FakeCommentRepository(
              results: [
                UserCommentResult(
                  comment: const PostComment(
                    author: 'sarahmae',
                    timeAgo: 'Baru saja',
                    body: 'Setuju, ini bisa dicoba di rumah.',
                    initials: 'SM',
                    avatarColor: kCirculGreen,
                  ),
                  post: feedPosts.first,
                ),
              ],
            ),
            savedPostRepository: _FakeSavedPostRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Komentar'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Komentar'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Setuju, ini bisa dicoba di rumah.'),
      500,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Setuju, ini bisa dicoba di rumah.'), findsOneWidget);
    expect(
      find.text('Tips mengurangi sampah plastik di rumah 🌿'),
      findsOneWidget,
    );
    expect(find.text('Bagikan'), findsWidgets);
  });

  testWidgets('post options bottom sheet follows owner and edit window rules', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FeedPostCard(
            post: FeedPost(
              author: 'sarahmae',
              city: 'Solo',
              timeAgo: 'Baru saja',
              title: 'Post sendiri',
              body: 'Masih bisa diedit.',
              imageAsset: '',
              createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
              likes: 0,
              comments: 0,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Lainnya'));
    await tester.pumpAndSettle();

    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    expect(find.text('Report'), findsOneWidget);

    Navigator.of(tester.element(find.text('Save'))).pop();
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FeedPostCard(
            post: FeedPost(
              author: 'anotheruser',
              city: 'Solo',
              timeAgo: 'Baru saja',
              title: 'Post orang lain',
              body: 'Tidak boleh edit hapus.',
              imageAsset: '',
              createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
              likes: 0,
              comments: 0,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Lainnya'));
    await tester.pumpAndSettle();

    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Edit'), findsNothing);
    expect(find.text('Delete'), findsNothing);
    expect(find.text('Report'), findsOneWidget);

    Navigator.of(tester.element(find.text('Save'))).pop();
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FeedPostCard(
            post: FeedPost(
              author: 'sarahmae',
              city: 'Solo',
              timeAgo: '2 jam',
              title: 'Post sendiri lama',
              body: 'Sudah lewat batas edit.',
              imageAsset: '',
              createdAt: DateTime.now().subtract(const Duration(hours: 2)),
              likes: 0,
              comments: 0,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Lainnya'));
    await tester.pumpAndSettle();

    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Edit'), findsNothing);
    expect(find.text('Delete'), findsOneWidget);
    expect(find.text('Report'), findsOneWidget);
  });

  testWidgets('feed post like toggles count and selected state', (
    tester,
  ) async {
    final likedRepository = _FakeLikedPostRepository();
    final post = feedPosts.first.copyWith(id: 'seed_1', likes: 7);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FeedPostCard(post: post, likedPostRepository: likedRepository),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('7'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.favorite_border_rounded));
    await tester.pumpAndSettle();

    expect(find.text('8'), findsOneWidget);
    expect(find.byType(AnimatedLikeIcon), findsOneWidget);

    await tester.tap(find.text('8'));
    await tester.pumpAndSettle();

    expect(find.text('7'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
  });

  testWidgets('save option stores post and shows saved state in profile', (
    tester,
  ) async {
    final savedRepository = _FakeSavedPostRepository();
    final likedRepository = _FakeLikedPostRepository();
    final post = feedPosts.first.copyWith(id: 'seed_1');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FeedPostCard(
            post: post,
            savedPostRepository: savedRepository,
            likedPostRepository: likedRepository,
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Lainnya'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Postingan disimpan.'), findsOneWidget);
    expect(find.text('Save'), findsNothing);

    await tester.tap(find.byTooltip('Lainnya'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Postingan sudah ada di Disimpan.'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfileScreen(
            feedPostRepository: _FakeFeedPostRepository(posts: [post]),
            commentRepository: _FakeCommentRepository(),
            savedPostRepository: savedRepository,
            likedPostRepository: likedRepository,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Disimpan'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Disimpan'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Tips mengurangi sampah plastik di rumah 🌿'),
      500,
      scrollable: find.byType(Scrollable).first,
    );

    expect(
      find.text('Tips mengurangi sampah plastik di rumah 🌿'),
      findsOneWidget,
    );
    expect(savedRepository.savedPostCount, 1);
  });

  testWidgets('saved tab menu only deletes saved entry', (tester) async {
    final savedRepository = _FakeSavedPostRepository();
    final likedRepository = _FakeLikedPostRepository();
    final post = feedPosts.first.copyWith(id: 'seed_1');
    await savedRepository.savePost(post);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfileScreen(
            feedPostRepository: _FakeFeedPostRepository(posts: [post]),
            commentRepository: _FakeCommentRepository(),
            savedPostRepository: savedRepository,
            likedPostRepository: likedRepository,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Disimpan'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Disimpan'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Tips mengurangi sampah plastik di rumah 🌿'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byTooltip('Lainnya').last);
    await tester.pumpAndSettle();

    expect(find.text('Delete'), findsOneWidget);
    expect(find.text('Save'), findsNothing);
    expect(find.text('Edit'), findsNothing);
    expect(find.text('Report'), findsNothing);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Postingan dihapus dari Disimpan.'), findsOneWidget);
    expect(savedRepository.savedPostCount, 0);
    expect(find.text('Belum ada postingan disimpan.'), findsOneWidget);

    await tester.tap(find.text('Postingan'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Tips mengurangi sampah plastik di rumah 🌿'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.text('Tips mengurangi sampah plastik di rumah 🌿'),
      findsOneWidget,
    );
  });
}

class _FakeFeedPostRepository extends FeedPostRepository {
  _FakeFeedPostRepository({List<FeedPost>? posts})
    : _posts = List<FeedPost>.of(posts ?? feedPosts);

  final List<FeedPost> _posts;

  @override
  Future<List<FeedPost>> getPosts() async => _posts;

  @override
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
    _posts.insert(
      0,
      FeedPost(
        author: 'sarahmae',
        city: city ?? 'Solo',
        timeAgo: 'Baru saja',
        title: topic.isEmpty ? 'Update komunitas' : topic,
        body: body,
        imageAsset: cleanupAsset,
        imagePaths: imagePaths,
        locationEnabled: locationEnabled,
        locationLabel: locationLabel,
        coordinateLabel: coordinateLabel,
        locationLatitude: locationLatitude,
        locationLongitude: locationLongitude,
        likes: 0,
        comments: 0,
      ),
    );
  }
}

class _FakeCommentRepository extends CommentRepository {
  _FakeCommentRepository({List<UserCommentResult> results = const []})
    : _results = results;

  final List<UserCommentResult> _results;

  @override
  Future<List<UserCommentResult>> getCommentsByAuthor(String author) async {
    return _results;
  }
}

class _FakeSavedPostRepository extends SavedPostRepository {
  final _savedPostsById = <String, FeedPost>{};

  int get savedPostCount => _savedPostsById.length;

  @override
  Future<SavePostResult> savePost(FeedPost post) async {
    if (_savedPostsById.containsKey(post.id)) {
      return SavePostResult.alreadySaved;
    }

    _savedPostsById[post.id] = post;
    return SavePostResult.saved;
  }

  @override
  Future<List<FeedPost>> getSavedPosts() async {
    return _savedPostsById.values.toList(growable: false);
  }

  @override
  Future<void> deleteSavedPost(FeedPost post) async {
    _savedPostsById.remove(post.id);
  }
}

class _FakeLikedPostRepository extends LikedPostRepository {
  final _likedPostIds = <String>{};
  final _likesByPostId = <String, int>{};

  @override
  Future<bool> isLiked(FeedPost post) async {
    return _likedPostIds.contains(post.id);
  }

  @override
  Future<LikePostResult> toggleLike(FeedPost post) async {
    final currentLikes = _likesByPostId[post.id] ?? post.likes;

    if (_likedPostIds.contains(post.id)) {
      _likedPostIds.remove(post.id);
      final likes = currentLikes > 0 ? currentLikes - 1 : 0;
      _likesByPostId[post.id] = likes;
      return LikePostResult(isLiked: false, likes: likes);
    }

    _likedPostIds.add(post.id);
    final likes = currentLikes + 1;
    _likesByPostId[post.id] = likes;
    return LikePostResult(isLiked: true, likes: likes);
  }
}

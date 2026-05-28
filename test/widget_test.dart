import 'package:circul/comment_repository.dart';
import 'package:circul/feed_post_repository.dart';
import 'package:circul/home/widgets/feed_post_card.dart';
import 'package:circul/liked_post_repository.dart';
import 'package:circul/main.dart';
import 'package:circul/map/map_screen.dart';
import 'package:circul/mock_data.dart';
import 'package:circul/profile/profile_screen.dart';
import 'package:circul/saved_post_repository.dart';
import 'package:circul/search/search_screen.dart';
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
    expect(find.bySemanticsLabel('Home'), findsOneWidget);
    expect(find.bySemanticsLabel('Peta'), findsOneWidget);
    expect(find.bySemanticsLabel('Cari'), findsOneWidget);
    expect(find.bySemanticsLabel('Event'), findsOneWidget);
    expect(find.bySemanticsLabel('Profil'), findsOneWidget);
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

    await tester.tap(find.bySemanticsLabel('Cari'));
    await tester.pumpAndSettle();
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Recent search'), findsOneWidget);
    expect(find.text('sampah plastik'), findsOneWidget);
    expect(find.text('zero waste'), findsOneWidget);
    expect(find.text('Topik populer'), findsNothing);
    expect(find.text('Trending'), findsNothing);

    await tester.tap(find.bySemanticsLabel('Profil'));
    await tester.pumpAndSettle();
    expect(find.text('Sarah Mae'), findsWidgets);
    expect(find.text('Achievement'), findsWidgets);
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -260));
    await tester.pumpAndSettle();
    expect(find.text('Eco Starter'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Peta'));
    await tester.pumpAndSettle();
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.byType(TileLayer), findsOneWidget);
    expect(find.text('Check-in nearby'), findsNothing);
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

    await tester.tap(find.bySemanticsLabel('Event'));
    await tester.pumpAndSettle();
    expect(find.text('upcoming feature'), findsOneWidget);
    expect(find.text('Aksi Bersih Sungai Pepe'), findsNothing);
  });

  testWidgets('map check-in marker opens detail when tapped', (tester) async {
    final post = FeedPost(
      id: 'check_in_1',
      author: 'sarahmae',
      city: 'Solo',
      timeAgo: 'Baru saja',
      title: 'Check-in Lingkungan',
      body: 'Butuh dicek lagi.',
      imageAsset: '',
      locationEnabled: true,
      locationLabel: 'Warung Hijau',
      locationLatitude: -7.5584,
      locationLongitude: 110.8199,
      likes: 0,
      comments: 0,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapScreen(
            feedPostRepository: _FakeFeedPostRepository(posts: [post]),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Detail check-in'), findsNothing);

    await tester.tap(find.bySemanticsLabel('Check-in Warung Hijau'));
    await tester.pumpAndSettle();

    expect(find.text('Detail check-in'), findsOneWidget);
    expect(find.text('Warung Hijau'), findsWidgets);
    expect(find.text('Butuh dicek lagi.'), findsWidgets);
  });

  testWidgets('map groups nearby check-ins into count marker when zoomed out', (
    tester,
  ) async {
    final posts = [
      const FeedPost(
        id: 'check_in_1',
        author: 'sarahmae',
        city: 'Solo',
        timeAgo: 'Baru saja',
        title: 'Check-in Lingkungan',
        body: 'Titik pertama.',
        imageAsset: '',
        locationEnabled: true,
        locationLabel: 'Warung Hijau',
        locationLatitude: -7.5584,
        locationLongitude: 110.8199,
        likes: 0,
        comments: 0,
      ),
      const FeedPost(
        id: 'check_in_2',
        author: 'sarahmae',
        city: 'Solo',
        timeAgo: 'Baru saja',
        title: 'Check-in Lingkungan',
        body: 'Titik kedua.',
        imageAsset: '',
        locationEnabled: true,
        locationLabel: 'Taman Dekat',
        locationLatitude: -7.55845,
        locationLongitude: 110.81995,
        likes: 0,
        comments: 0,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapScreen(
            feedPostRepository: _FakeFeedPostRepository(posts: posts),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.data == '2' &&
            widget.style?.fontSize == 18 &&
            widget.style?.fontWeight == FontWeight.w900,
      ),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Check-in Warung Hijau'), findsNothing);
    expect(find.bySemanticsLabel('Check-in Taman Dekat'), findsNothing);
  });

  testWidgets('search ranks typo query with fuzzy post matching', (
    tester,
  ) async {
    final posts = [
      const FeedPost(
        id: 'gardening',
        author: 'ninaeco',
        city: 'Solo',
        timeAgo: '1 jam',
        title: 'Urban gardening akhir pekan',
        body: 'Menanam cabai dan tomat di halaman kecil.',
        imageAsset: '',
        topic: 'Tanaman & Kebun',
        likes: 3,
        comments: 1,
      ),
      const FeedPost(
        id: 'river',
        author: 'rakaearth',
        city: 'Solo',
        timeAgo: '2 jam',
        title: 'Komunitas bersih sungai',
        body: 'Agenda bersih sungai bareng warga sekitar.',
        imageAsset: '',
        topic: 'Komunitas Lokal',
        likes: 4,
        comments: 2,
      ),
      feedPosts[0],
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchScreen(
            feedPostRepository: _FakeFeedPostRepository(posts: posts),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Search message, topic, or user'),
      'sampa plastik',
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(
      find.text('Tips mengurangi sampah plastik di rumah 🌿'),
      findsOneWidget,
    );
    expect(find.text('Topik'), findsNothing);
  });

  testWidgets('search ranks user by fuzzy author query', (tester) async {
    final posts = [
      const FeedPost(
        id: 'nina',
        author: 'ninaeco',
        city: 'Solo',
        timeAgo: '1 jam',
        title: 'Urban gardening',
        body: 'Kebun kecil di rumah.',
        imageAsset: '',
        likes: 3,
        comments: 1,
      ),
      const FeedPost(
        id: 'raka',
        author: 'rakaearth',
        city: 'Solo',
        timeAgo: '2 jam',
        title: 'Bersih sungai',
        body: 'Kegiatan komunitas.',
        imageAsset: '',
        likes: 4,
        comments: 2,
      ),
      const FeedPost(
        id: 'lani',
        author: 'lanihijau',
        city: 'Solo',
        timeAgo: '3 jam',
        title: 'Daur ulang botol',
        body: 'Botol bekas jadi pot.',
        imageAsset: '',
        likes: 5,
        comments: 1,
      ),
      feedPosts[0],
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchScreen(
            feedPostRepository: _FakeFeedPostRepository(posts: posts),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Search message, topic, or user'),
      'srahmae',
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pengguna').first);
    await tester.pumpAndSettle();

    expect(find.text('sarahmae'), findsOneWidget);
    expect(find.text('Sarah Mae'), findsOneWidget);
    expect(find.text('Topik'), findsNothing);
  });

  testWidgets('tapping selected search nav returns to search landing', (
    tester,
  ) async {
    await tester.pumpWidget(
      CirculApp(feedPostRepository: _FakeFeedPostRepository()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Cari'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Search message, topic, or user'),
      'sampa plastik',
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('Postingan'), findsWidgets);
    expect(find.text('Batal'), findsOneWidget);
    expect(find.text('Recent search'), findsNothing);

    await tester.tap(find.bySemanticsLabel('Cari'));
    await tester.pumpAndSettle();

    expect(find.text('Recent search'), findsOneWidget);
    expect(find.text('sampa plastik'), findsOneWidget);
    expect(find.text('Batal'), findsNothing);
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

  testWidgets('profile edit screen validates username and updates profile', (
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
                  author: 'ecofriend',
                  city: 'Solo',
                  timeAgo: '1 jam',
                  title: 'Postingan teman',
                  body: 'Username ini sudah dipakai.',
                  imageAsset: cleanupAsset,
                  likes: 2,
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

    await tester.tap(find.text('Edit Profil'));
    await tester.pumpAndSettle();

    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Bio'), findsOneWidget);
    expect(find.text('City, Country'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Username'),
      'ecofriend',
    );
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(find.text('Username sudah dipakai.'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Name'),
      'Maya Green',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Username'),
      'mayagreen',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Bio'),
      'Belajar hidup minim sampah.',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'City, Country'),
      'Solo, Indonesia',
    );
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(find.text('Maya Green'), findsOneWidget);
    expect(find.text('@mayagreen'), findsOneWidget);
    expect(find.text('Belajar hidup minim sampah.'), findsOneWidget);
    expect(find.text('Solo, Indonesia'), findsOneWidget);
    expect(find.text('Profil diperbarui.'), findsOneWidget);
  });

  testWidgets('profile edits update own posts and check-ins', (tester) async {
    const post = FeedPost(
      id: 'check_in_post',
      author: 'sarahmae',
      city: 'Solo',
      timeAgo: 'Baru saja',
      title: 'Check-in Lingkungan',
      body: 'Area ini sudah dicek.',
      imageAsset: '',
      locationEnabled: true,
      locationLabel: 'Warung Hijau',
      locationLatitude: -7.5584,
      locationLongitude: 110.8199,
      likes: 0,
      comments: 0,
    );

    await tester.pumpWidget(
      CirculApp(
        feedPostRepository: _FakeFeedPostRepository(posts: [post]),
        likedPostRepository: _FakeLikedPostRepository(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Profil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit Profil'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Name'),
      'Maya Green',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Username'),
      'mayagreen',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Bio'),
      'Belajar hidup minim sampah.',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'City, Country'),
      'Solo, Indonesia',
    );
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Home'));
    await tester.pumpAndSettle();
    expect(find.text('mayagreen'), findsOneWidget);
    expect(find.text('sarahmae'), findsNothing);

    await tester.tap(find.bySemanticsLabel('Peta'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Check-in Warung Hijau'));
    await tester.pumpAndSettle();

    expect(find.text('Detail check-in'), findsOneWidget);
    expect(find.text('mayagreen'), findsOneWidget);
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

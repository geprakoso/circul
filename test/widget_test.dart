import 'package:circul/feed_post_repository.dart';
import 'package:circul/main.dart';
import 'package:circul/mock_data.dart';
import 'package:circul/profile/profile_screen.dart';
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

import 'package:circul/feed_post_repository.dart';
import 'package:circul/main.dart';
import 'package:circul/mock_data.dart';
import 'package:flutter/material.dart';
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
    expect(find.text('Gondang Manis, Solo'), findsOneWidget);
    expect(find.text('Aktivitas di sekitarmu'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Lihat semua'));
    await tester.pumpAndSettle();
    expect(find.text('Event'), findsWidgets);
    expect(find.text('Aksi Bersih Sungai Pepe'), findsWidgets);
  });
}

class _FakeFeedPostRepository extends FeedPostRepository {
  _FakeFeedPostRepository();

  final _posts = List<FeedPost>.of(feedPosts);

  @override
  Future<List<FeedPost>> getPosts() async => _posts;

  @override
  Future<void> addPost({
    required String body,
    required String topic,
    required bool allowReplies,
    List<String> imagePaths = const [],
  }) async {
    _posts.insert(
      0,
      FeedPost(
        author: 'sarahmae',
        city: 'Solo',
        timeAgo: 'Baru saja',
        title: topic.isEmpty ? 'Update komunitas' : topic,
        body: body,
        imageAsset: cleanupAsset,
        imagePaths: imagePaths,
        likes: 0,
        comments: 0,
      ),
    );
  }
}

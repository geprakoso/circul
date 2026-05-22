import 'package:flutter/material.dart';

import '../comments/comment_screen.dart';
import '../feed_post_repository.dart';
import '../mock_data.dart';
import '../new_post/new_post_screen.dart';
import '../shared/shared_widgets.dart';
import 'widgets/feed_post_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.feedPostRepository, this.onMapButtonTap});

  final FeedPostRepository? feedPostRepository;
  final VoidCallback? onMapButtonTap;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final FeedPostRepository _repository;
  late Future<List<FeedPost>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _repository = widget.feedPostRepository ?? FeedPostRepository();
    _postsFuture = _repository.getPosts();
  }

  Future<void> _openComposer() async {
    final didPost = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => NewPostScreen(feedPostRepository: _repository),
      ),
    );
    if (!mounted || didPost != true) return;

    setState(() {
      _postsFuture = _repository.getPosts();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Postingan komunitas tersimpan lokal.')),
    );
  }

  void _openComments(FeedPost post) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => CommentScreen(post: post)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          FutureBuilder<List<FeedPost>>(
            future: _postsFuture,
            builder: (context, snapshot) {
              final posts = snapshot.data ?? const <FeedPost>[];

              if (snapshot.hasError) {
                return ListView(
                  padding: const EdgeInsets.only(bottom: 138),
                  children: [
                    _HomeHeader(onComposeTap: _openComposer),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 36, 24, 0),
                      child: Text(
                        'Database lokal belum bisa dibuka.',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting &&
                  posts.isEmpty) {
                return ListView(
                  padding: const EdgeInsets.only(bottom: 138),
                  children: [
                    _HomeHeader(onComposeTap: _openComposer),
                    const SizedBox(height: 36),
                    const Center(child: CircularProgressIndicator()),
                  ],
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.only(bottom: 138),
                itemCount: posts.length + 1,
                separatorBuilder: (context, index) {
                  if (index < 1) return const SizedBox.shrink();
                  return const Divider(
                    height: 1,
                    indent: 24,
                    endIndent: 24,
                    color: kLine,
                  );
                },
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _HomeHeader(onComposeTap: _openComposer);
                  }

                  final post = posts[index - 1];
                  return FeedPostCard(
                    post: post,
                    onOpenComments: () => _openComments(post),
                  );
                },
              );
            },
          ),
          Positioned(
            right: 24,
            bottom: 24,
            child: _HomeMapButton(onTap: widget.onMapButtonTap ?? () {}),
          ),
        ],
      ),
    );
  }
}

class _HomeMapButton extends StatelessWidget {
  const _HomeMapButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Buka peta',
      child: Material(
        color: Colors.black,
        borderRadius: BorderRadius.circular(28),
        elevation: 10,
        shadowColor: const Color(0x55000000),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: const SizedBox(
            width: 96,
            height: 96,
            child: Icon(
              Icons.location_on_outlined,
              color: Colors.white,
              size: 64,
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.onComposeTap});

  final VoidCallback onComposeTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const CirculHeader(),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 26),
          child: Row(
            children: [
              const SarahAvatar(radius: 31, showAddBadge: true),
              const SizedBox(width: 20),
              Expanded(child: _HomeComposerEntry(onTap: onComposeTap)),
            ],
          ),
        ),
        const Divider(height: 1, color: kLine),
      ],
    );
  }
}

class _HomeComposerEntry extends StatelessWidget {
  const _HomeComposerEntry({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SearchFieldShell(
      hint: 'Kirim sesuatu ke komunitas...',
      icon: Icons.edit_note_rounded,
      onTap: onTap,
    );
  }
}

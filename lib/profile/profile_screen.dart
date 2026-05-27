import 'package:flutter/material.dart';

import '../comments/comment_screen.dart';
import '../feed_post_repository.dart';
import '../home/widgets/feed_post_card.dart';
import '../mock_data.dart';
import '../shared/shared_widgets.dart';
import 'widgets/achievement_badge.dart';
import 'widgets/profile_meta.dart';
import 'widgets/profile_placeholder.dart';
import 'widgets/profile_stats.dart';
import 'widgets/segmented_profile_tabs.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    this.feedPostRepository,
    this.onPostUpdated,
    this.refreshToken = 0,
  });

  final FeedPostRepository? feedPostRepository;
  final VoidCallback? onPostUpdated;
  final int refreshToken;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _profileAuthor = 'sarahmae';

  var _selectedTab = 'Postingan';
  late final FeedPostRepository _repository;
  late Future<List<FeedPost>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _repository = widget.feedPostRepository ?? FeedPostRepository();
    _postsFuture = _repository.getPosts();
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _postsFuture = _repository.getPosts();
    }
  }

  Future<void> _openComments(FeedPost post) async {
    final didChange = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (context) => CommentScreen(post: post)),
    );
    if (!mounted || didChange != true) return;

    setState(() {
      _postsFuture = _repository.getPosts();
    });
    widget.onPostUpdated?.call();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 22),
        children: [
          const CirculHeader(showChat: false),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SarahAvatar(radius: 56),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sarah Mae',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        '@sarahmae',
                        style: TextStyle(
                          color: kMuted,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Berusaha hidup lebih berkelanjutan 🌿\nBelajar, berbagi, dan berdampak.',
                        style: TextStyle(fontSize: 15, height: 1.35),
                      ),
                      const SizedBox(height: 16),
                      const Wrap(
                        spacing: 14,
                        runSpacing: 8,
                        children: [
                          ProfileMeta(
                            icon: Icons.location_on_outlined,
                            text: 'Jakarta, Indonesia',
                          ),
                          ProfileMeta(
                            icon: Icons.calendar_today_outlined,
                            text: 'Bergabung Mei 2023',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.edit_square),
                        label: const Text('Edit Profil'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                          foregroundColor: kInk,
                          side: const BorderSide(color: kLine),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const ProfileStats(),
          SectionTitle(
            title: 'Achievement',
            action: 'Lihat semua',
            onAction: () {},
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final achievement in achievements)
                  Expanded(child: AchievementBadge(achievement: achievement)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SegmentedProfileTabs(
              selected: _selectedTab,
              onSelected: (value) => setState(() => _selectedTab = value),
            ),
          ),
          if (_selectedTab == 'Postingan')
            FutureBuilder<List<FeedPost>>(
              future: _postsFuture,
              builder: (context, snapshot) {
                final posts = (snapshot.data ?? const <FeedPost>[])
                    .where(
                      (post) => post.author.toLowerCase() == _profileAuthor,
                    )
                    .toList(growable: false);

                if (snapshot.hasError) {
                  return const _ProfilePostMessage(
                    title: 'Postingan belum bisa dimuat.',
                    icon: Icons.error_outline_rounded,
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting &&
                    posts.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 28, bottom: 26),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (posts.isEmpty) {
                  return const _ProfilePostMessage(
                    title: 'Belum ada postingan.',
                    icon: Icons.article_outlined,
                  );
                }

                return Column(
                  children: [
                    for (var i = 0; i < posts.length; i++) ...[
                      FeedPostCard(
                        post: posts[i],
                        compact: true,
                        framed: true,
                        showActions: true,
                        onOpenComments: () => _openComments(posts[i]),
                      ),
                      if (i != posts.length - 1)
                        const Divider(
                          height: 1,
                          thickness: 1,
                          indent: 20,
                          endIndent: 20,
                          color: kLine,
                        ),
                    ],
                  ],
                );
              },
            )
          else
            ProfilePlaceholder(tab: _selectedTab),
        ],
      ),
    );
  }
}

class _ProfilePostMessage extends StatelessWidget {
  const _ProfilePostMessage({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 18, 20, 26),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kLine),
      ),
      child: Row(
        children: [
          Icon(icon, color: kCirculGreen, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:io';

import 'package:flutter/material.dart';

import '../comment_repository.dart';
import '../comments/comment_screen.dart';
import '../feed_post_repository.dart';
import '../home/widgets/feed_post_card.dart';
import '../liked_post_repository.dart';
import '../mock_data.dart';
import 'edit_profile_screen.dart';
import '../saved_post_repository.dart';
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
    this.commentRepository,
    this.savedPostRepository,
    this.likedPostRepository,
    this.onPostUpdated,
    this.refreshToken = 0,
  });

  final FeedPostRepository? feedPostRepository;
  final CommentRepository? commentRepository;
  final SavedPostRepository? savedPostRepository;
  final LikedPostRepository? likedPostRepository;
  final VoidCallback? onPostUpdated;
  final int refreshToken;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _profileAuthor = 'sarahmae';

  var _profile = const EditableProfile(
    name: 'Sarah Mae',
    username: _profileAuthor,
    bio:
        'Berusaha hidup lebih berkelanjutan 🌿\nBelajar, berbagi, dan berdampak.',
    location: 'Jakarta, Indonesia',
  );
  var _selectedTab = 'Postingan';
  late final FeedPostRepository _repository;
  late final CommentRepository _commentRepository;
  late final SavedPostRepository _savedPostRepository;
  late final LikedPostRepository _likedPostRepository;
  late Future<List<FeedPost>> _postsFuture;
  late Future<List<UserCommentResult>> _commentsFuture;
  late Future<List<FeedPost>> _savedPostsFuture;

  @override
  void initState() {
    super.initState();
    _repository = widget.feedPostRepository ?? FeedPostRepository();
    _commentRepository = widget.commentRepository ?? CommentRepository();
    _savedPostRepository = widget.savedPostRepository ?? SavedPostRepository();
    _likedPostRepository = widget.likedPostRepository ?? LikedPostRepository();
    _postsFuture = _repository.getPosts();
    _commentsFuture = Future.value(const <UserCommentResult>[]);
    _savedPostsFuture = Future.value(const <FeedPost>[]);
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _refreshProfileFeedData();
    }
  }

  void _refreshProfileFeedData() {
    _postsFuture = _repository.getPosts();
    if (_selectedTab == 'Komentar') {
      _commentsFuture = _commentRepository.getCommentsByAuthor(_profileAuthor);
    } else if (_selectedTab == 'Disimpan') {
      _savedPostsFuture = _savedPostRepository.getSavedPosts();
    }
  }

  void _selectTab(String value) {
    setState(() {
      _selectedTab = value;
      if (value == 'Komentar') {
        _commentsFuture = _commentRepository.getCommentsByAuthor(
          _profileAuthor,
        );
      } else if (value == 'Disimpan') {
        _savedPostsFuture = _savedPostRepository.getSavedPosts();
      }
    });
  }

  void _handlePostSaved() {
    if (_selectedTab == 'Disimpan') {
      setState(() {
        _savedPostsFuture = _savedPostRepository.getSavedPosts();
      });
    }
    widget.onPostUpdated?.call();
  }

  void _handleSavedPostDeleted() {
    setState(() {
      _savedPostsFuture = _savedPostRepository.getSavedPosts();
    });
    widget.onPostUpdated?.call();
  }

  void _handlePostLiked() {
    setState(() {
      _refreshProfileFeedData();
    });
    widget.onPostUpdated?.call();
  }

  Future<void> _openComments(FeedPost post) async {
    final didChange = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => CommentScreen(
          post: post,
          likedPostRepository: _likedPostRepository,
        ),
      ),
    );
    if (!mounted || didChange != true) return;

    setState(() {
      _refreshProfileFeedData();
    });
    widget.onPostUpdated?.call();
  }

  Future<void> _openEditProfile() async {
    final posts = await _postsFuture.catchError((_) => const <FeedPost>[]);
    if (!mounted) return;

    final takenUsernames = {
      for (final post in posts)
        if (post.author.toLowerCase() != _profile.username.toLowerCase())
          post.author,
    };

    final updatedProfile = await Navigator.of(context).push<EditableProfile>(
      MaterialPageRoute<EditableProfile>(
        builder: (context) => EditProfileScreen(
          profile: _profile,
          takenUsernames: takenUsernames,
        ),
      ),
    );
    if (!mounted || updatedProfile == null) return;

    setState(() => _profile = updatedProfile);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Profil diperbarui.')));
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
                _ProfileAvatar(profile: _profile, radius: 56),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _profile.name,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '@${_profile.username}',
                        style: const TextStyle(
                          color: kMuted,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _profile.bio,
                        style: const TextStyle(fontSize: 15, height: 1.35),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 14,
                        runSpacing: 8,
                        children: [
                          ProfileMeta(
                            icon: Icons.location_on_outlined,
                            text: _profile.location,
                          ),
                          const ProfileMeta(
                            icon: Icons.calendar_today_outlined,
                            text: 'Bergabung Mei 2023',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _openEditProfile,
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
              onSelected: _selectTab,
            ),
          ),
          if (_selectedTab == 'Postingan')
            _ProfilePostsTab(
              postsFuture: _postsFuture,
              onOpenComments: _openComments,
              savedPostRepository: _savedPostRepository,
              onPostSaved: _handlePostSaved,
              likedPostRepository: _likedPostRepository,
              onPostLiked: _handlePostLiked,
            )
          else if (_selectedTab == 'Komentar')
            _ProfileCommentsTab(
              commentsFuture: _commentsFuture,
              onOpenComments: _openComments,
              savedPostRepository: _savedPostRepository,
              onPostSaved: _handlePostSaved,
              likedPostRepository: _likedPostRepository,
              onPostLiked: _handlePostLiked,
            )
          else if (_selectedTab == 'Disimpan')
            _ProfileSavedPostsTab(
              savedPostsFuture: _savedPostsFuture,
              onOpenComments: _openComments,
              savedPostRepository: _savedPostRepository,
              onSavedPostDeleted: _handleSavedPostDeleted,
              likedPostRepository: _likedPostRepository,
              onPostLiked: _handlePostLiked,
            )
          else
            ProfilePlaceholder(tab: _selectedTab),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.profile, required this.radius});

  final EditableProfile profile;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final imagePath = profile.imagePath;
    if (imagePath == null || imagePath.trim().isEmpty) {
      return SarahAvatar(radius: radius);
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFE5E7EB),
      child: ClipOval(
        child: Image.file(
          File(imagePath),
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Image.asset(
            avatarAsset,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

class _ProfilePostsTab extends StatelessWidget {
  const _ProfilePostsTab({
    required this.postsFuture,
    required this.onOpenComments,
    required this.savedPostRepository,
    required this.onPostSaved,
    required this.likedPostRepository,
    required this.onPostLiked,
  });

  static const _profileAuthor = 'sarahmae';

  final Future<List<FeedPost>> postsFuture;
  final ValueChanged<FeedPost> onOpenComments;
  final SavedPostRepository savedPostRepository;
  final VoidCallback onPostSaved;
  final LikedPostRepository likedPostRepository;
  final VoidCallback onPostLiked;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FeedPost>>(
      future: postsFuture,
      builder: (context, snapshot) {
        final posts = (snapshot.data ?? const <FeedPost>[])
            .where((post) => post.author.toLowerCase() == _profileAuthor)
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
                savedPostRepository: savedPostRepository,
                onPostSaved: onPostSaved,
                likedPostRepository: likedPostRepository,
                onPostLiked: onPostLiked,
                onOpenComments: () => onOpenComments(posts[i]),
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
    );
  }
}

class _ProfileCommentsTab extends StatelessWidget {
  const _ProfileCommentsTab({
    required this.commentsFuture,
    required this.onOpenComments,
    required this.savedPostRepository,
    required this.onPostSaved,
    required this.likedPostRepository,
    required this.onPostLiked,
  });

  final Future<List<UserCommentResult>> commentsFuture;
  final ValueChanged<FeedPost> onOpenComments;
  final SavedPostRepository savedPostRepository;
  final VoidCallback onPostSaved;
  final LikedPostRepository likedPostRepository;
  final VoidCallback onPostLiked;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UserCommentResult>>(
      future: commentsFuture,
      builder: (context, snapshot) {
        final results = snapshot.data ?? const <UserCommentResult>[];

        if (snapshot.hasError) {
          return const _ProfilePostMessage(
            title: 'Komentar belum bisa dimuat.',
            icon: Icons.error_outline_rounded,
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            results.isEmpty) {
          return const Padding(
            padding: EdgeInsets.only(top: 28, bottom: 26),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (results.isEmpty) {
          return const _ProfilePostMessage(
            title: 'Belum ada komentar.',
            icon: Icons.chat_bubble_outline_rounded,
          );
        }

        return Column(
          children: [
            for (var i = 0; i < results.length; i++) ...[
              _ProfileCommentResultCard(
                result: results[i],
                onOpenComments: () => onOpenComments(results[i].post),
                savedPostRepository: savedPostRepository,
                onPostSaved: onPostSaved,
                likedPostRepository: likedPostRepository,
                onPostLiked: onPostLiked,
              ),
              if (i != results.length - 1)
                const Divider(height: 1, thickness: 1, color: kLine),
            ],
          ],
        );
      },
    );
  }
}

class _ProfileCommentResultCard extends StatelessWidget {
  const _ProfileCommentResultCard({
    required this.result,
    required this.onOpenComments,
    required this.savedPostRepository,
    required this.onPostSaved,
    required this.likedPostRepository,
    required this.onPostLiked,
  });

  final UserCommentResult result;
  final VoidCallback onOpenComments;
  final SavedPostRepository savedPostRepository;
  final VoidCallback onPostSaved;
  final LikedPostRepository likedPostRepository;
  final VoidCallback onPostLiked;

  @override
  Widget build(BuildContext context) {
    const contentInset = 76.0;

    return Padding(
      padding: const EdgeInsets.only(top: 26, bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProfileCommentRow(comment: result.comment),
          Padding(
            padding: const EdgeInsets.only(left: contentInset, right: 20),
            child: FeedPostCard(
              post: result.post,
              compact: true,
              framed: true,
              showActions: true,
              framedMargin: const EdgeInsets.only(top: 22),
              savedPostRepository: savedPostRepository,
              onPostSaved: onPostSaved,
              likedPostRepository: likedPostRepository,
              onPostLiked: onPostLiked,
              onOpenComments: onOpenComments,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSavedPostsTab extends StatelessWidget {
  const _ProfileSavedPostsTab({
    required this.savedPostsFuture,
    required this.onOpenComments,
    required this.savedPostRepository,
    required this.onSavedPostDeleted,
    required this.likedPostRepository,
    required this.onPostLiked,
  });

  final Future<List<FeedPost>> savedPostsFuture;
  final ValueChanged<FeedPost> onOpenComments;
  final SavedPostRepository savedPostRepository;
  final VoidCallback onSavedPostDeleted;
  final LikedPostRepository likedPostRepository;
  final VoidCallback onPostLiked;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FeedPost>>(
      future: savedPostsFuture,
      builder: (context, snapshot) {
        final posts = snapshot.data ?? const <FeedPost>[];

        if (snapshot.hasError) {
          return const _ProfilePostMessage(
            title: 'Postingan disimpan belum bisa dimuat.',
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
            title: 'Belum ada postingan disimpan.',
            icon: Icons.bookmark_border_rounded,
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
                savedPostRepository: savedPostRepository,
                onPostSaved: onSavedPostDeleted,
                savedTabOptions: true,
                likedPostRepository: likedPostRepository,
                onPostLiked: onPostLiked,
                onOpenComments: () => onOpenComments(posts[i]),
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
    );
  }
}

class _ProfileCommentRow extends StatelessWidget {
  const _ProfileCommentRow({required this.comment});

  final PostComment comment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: comment.avatarColor,
            child: Text(
              comment.initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 22,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 4,
                  children: [
                    Text(
                      comment.author,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const _Dot(),
                    Text(
                      comment.timeAgo,
                      style: const TextStyle(
                        color: kMuted,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  comment.body,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    height: 1.35,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            tooltip: 'Sukai komentar',
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 42, minHeight: 42),
            icon: const Icon(
              Icons.favorite_border_rounded,
              color: kMuted,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: Colors.black,
        shape: BoxShape.circle,
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

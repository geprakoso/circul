import 'dart:io';

import 'package:fuzzy_search_engine/fuzzy_search_engine.dart';
import 'package:flutter/material.dart';

import '../comments/comment_screen.dart';
import '../feed_post_repository.dart';
import '../home/widgets/post_options_bottom_sheet.dart';
import '../image_viewer/uploaded_image_fullscreen_page.dart';
import '../liked_post_repository.dart';
import '../mock_data.dart';
import '../saved_post_repository.dart';
import '../shared/animated_like_icon.dart';
import '../shared/relative_timestamp.dart';
import '../shared/sarah_avatar.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({
    super.key,
    this.feedPostRepository,
    this.savedPostRepository,
    this.likedPostRepository,
    this.onPostUpdated,
    this.onPostSaved,
    this.onPostLiked,
  });

  final FeedPostRepository? feedPostRepository;
  final SavedPostRepository? savedPostRepository;
  final LikedPostRepository? likedPostRepository;
  final VoidCallback? onPostUpdated;
  final VoidCallback? onPostSaved;
  final VoidCallback? onPostLiked;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const _tabs = ['Semua', 'Postingan', 'Pengguna'];
  static const _searchConfig = SearchConfig(
    searchFields: ['name', 'subtitle', 'searchData'],
    fieldWeights: {'name': 1, 'subtitle': .75, 'searchData': .55},
  );

  late final FeedPostRepository _repository;
  late Future<List<FeedPost>> _postsFuture;
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  var _recentSearches = <String>[
    'sampah plastik',
    'zero waste',
    'daur ulang',
    'komunitas lokal',
  ];
  var _selectedTab = 'Semua';
  var _submittedQuery = '';

  @override
  void initState() {
    super.initState();
    _repository = widget.feedPostRepository ?? FeedPostRepository();
    _postsFuture = _repository.getPosts();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submitSearch(String value) {
    final query = value.trim();
    if (query.isEmpty) return;
    setState(() {
      _submittedQuery = query;
      _selectedTab = 'Semua';
      _rememberRecentSearch(query);
    });
    _focusNode.unfocus();
  }

  void _rememberRecentSearch(String query) {
    _recentSearches = [
      query,
      ..._recentSearches.where((item) => _normalize(item) != _normalize(query)),
    ].take(8).toList(growable: false);
  }

  void _cancelSearch() {
    setState(() {
      _submittedQuery = '';
      _selectedTab = 'Semua';
      _controller.clear();
    });
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    if (_submittedQuery.isEmpty) return _buildLanding(context);
    return _buildResults(context);
  }

  Widget _buildLanding(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        children: [
          Text(
            'Search',
            style: Theme.of(
              context,
            ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 26),
          _SearchInput(
            controller: _controller,
            focusNode: _focusNode,
            hint: 'Search message, topic, or user',
            onSubmitted: _submitSearch,
          ),
          const SizedBox(height: 28),
          Text(
            'Recent search',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final query in _recentSearches)
                _RecentSearchPill(
                  label: query,
                  onTap: () {
                    _controller.text = query;
                    _submitSearch(query);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: _SearchInput(
                    controller: _controller,
                    focusNode: _focusNode,
                    hint: 'Search',
                    onSubmitted: _submitSearch,
                    onClear: () => setState(() => _controller.clear()),
                  ),
                ),
                const SizedBox(width: 14),
                TextButton(
                  onPressed: _cancelSearch,
                  child: const Text(
                    'Batal',
                    style: TextStyle(
                      color: kCirculGreen,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SearchTabs(
            tabs: _tabs,
            selectedTab: _selectedTab,
            onChanged: (tab) => setState(() => _selectedTab = tab),
          ),
          const Divider(height: 1, color: kLine),
          Expanded(
            child: FutureBuilder<List<FeedPost>>(
              future: _postsFuture,
              builder: (context, snapshot) {
                final posts = snapshot.data ?? const <FeedPost>[];
                if (snapshot.connectionState == ConnectionState.waiting &&
                    posts.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                final resultPosts = _rankPosts(posts, _submittedQuery);
                final resultUsers = _rankUsers(posts, _submittedQuery);

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
                  children: [
                    if (_selectedTab == 'Semua' || _selectedTab == 'Postingan')
                      _ResultSection(
                        title: 'Postingan',
                        showSeeAll: true,
                        children: _postResultWidgets(resultPosts.take(2)),
                      ),
                    if (_selectedTab == 'Semua' || _selectedTab == 'Pengguna')
                      _ResultSection(
                        title: 'Pengguna',
                        showSeeAll: true,
                        children: [
                          for (final user in resultUsers.take(3))
                            _UserResultTile(user: user),
                        ],
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<FeedPost> _rankPosts(List<FeedPost> posts, String query) {
    final items = [
      for (var i = 0; i < posts.length; i++)
        SearchableItem(
          id: _postSearchId(posts[i], i),
          name: _postSearchName(posts[i]),
          subtitle: posts[i].body,
          searchData: _postSearchData(posts[i]),
          data: posts[i],
        ),
    ];
    final results = SearchEngine.fuzzySearch(
      items,
      query,
      config: _searchConfig,
    );
    if (results.isEmpty) return posts;
    return [
      for (final result in results)
        if (result.data case final FeedPost post) post,
    ];
  }

  List<Widget> _postResultWidgets(Iterable<FeedPost> posts) {
    final widgets = <Widget>[];
    var index = 0;
    for (final post in posts) {
      if (index > 0) {
        widgets.add(const Divider(height: 1, thickness: 1, color: kLine));
        widgets.add(const SizedBox(height: 18));
      }
      widgets.add(
        _SearchPostResult(
          post: post,
          savedPostRepository: widget.savedPostRepository,
          onPostSaved: widget.onPostSaved,
          likedPostRepository: widget.likedPostRepository,
          onPostLiked: widget.onPostLiked,
          onTap: () => _openPostComments(post),
        ),
      );
      index += 1;
    }
    return widgets;
  }

  Future<void> _openPostComments(FeedPost post) async {
    final didChange = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => CommentScreen(
          post: post,
          likedPostRepository: widget.likedPostRepository,
        ),
      ),
    );
    if (!mounted || didChange != true) return;

    setState(() {
      _postsFuture = _repository.getPosts();
    });
    widget.onPostUpdated?.call();
  }

  List<_SearchUser> _rankUsers(List<FeedPost> posts, String query) {
    final users = _usersFromPosts(posts);
    final postsByAuthor = _postsByAuthor(posts);
    final items = [
      for (final user in users)
        SearchableItem(
          id: user.username,
          name: user.username,
          subtitle: user.name,
          searchData: _userSearchData(postsByAuthor[user.username] ?? const []),
          data: user,
        ),
    ];
    final results = SearchEngine.fuzzySearch(
      items,
      query,
      config: _searchConfig,
    );
    if (results.isEmpty) return users;
    return [
      for (final result in results)
        if (result.data case final _SearchUser user) user,
    ];
  }

  List<_SearchUser> _usersFromPosts(List<FeedPost> posts) {
    final byAuthor = _postsByAuthor(posts);

    final users = [
      for (final entry in byAuthor.entries)
        _SearchUser.fromPosts(author: entry.key, posts: entry.value),
    ];

    users.sort((first, second) => second.postCount.compareTo(first.postCount));
    return users;
  }

  Map<String, List<FeedPost>> _postsByAuthor(List<FeedPost> posts) {
    final byAuthor = <String, List<FeedPost>>{};
    for (final post in posts) {
      byAuthor.putIfAbsent(post.author, () => []).add(post);
    }
    return byAuthor;
  }

  String _postSearchId(FeedPost post, int index) {
    final id = post.id.trim();
    return id.isEmpty ? 'post-$index' : id;
  }

  String _postSearchName(FeedPost post) {
    final title = post.title.trim();
    if (title.isNotEmpty) return title;

    final topic = post.topic.trim();
    if (topic.isNotEmpty) return topic;

    return post.author;
  }

  String _postSearchData(FeedPost post) {
    return [
      post.author,
      post.city,
      post.topic,
      post.locationLabel,
    ].whereType<String>().where((value) => value.trim().isNotEmpty).join(' ');
  }

  String _userSearchData(List<FeedPost> posts) {
    return [
      for (final post in posts) ...[
        post.title,
        post.topic,
        post.body,
        post.city,
        post.locationLabel,
      ],
    ].whereType<String>().where((value) => value.trim().isNotEmpty).join(' ');
  }

  String _normalize(String value) => value.toLowerCase().trim();
}

class _SearchInput extends StatelessWidget {
  const _SearchInput({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.onSubmitted,
    this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final ValueChanged<String> onSubmitted;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F1F3),
        borderRadius: BorderRadius.circular(32),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: Color(0xFF4B5563), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              textInputAction: TextInputAction.search,
              onSubmitted: onSubmitted,
              style: const TextStyle(
                color: kInk,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                isCollapsed: true,
                hintText: hint,
                hintStyle: const TextStyle(
                  color: kMuted,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          if (onClear != null)
            GestureDetector(
              onTap: onClear,
              child: Container(
                width: 25,
                height: 25,
                decoration: const BoxDecoration(
                  color: Color(0xFF9CA3AF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RecentSearchPill extends StatelessWidget {
  const _RecentSearchPill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF1F4F2),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.history_rounded, color: kCirculGreen, size: 17),
              const SizedBox(width: 7),
              Text(
                label,
                style: const TextStyle(
                  color: kCirculGreen,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchTabs extends StatelessWidget {
  const _SearchTabs({
    required this.tabs,
    required this.selectedTab,
    required this.onChanged,
  });

  final List<String> tabs;
  final String selectedTab;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: tabs.length,
        separatorBuilder: (context, index) => const SizedBox(width: 22),
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final selected = tab == selectedTab;
          return InkWell(
            onTap: () => onChanged(tab),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  tab,
                  style: TextStyle(
                    color: selected ? kCirculGreen : kMuted,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: 76,
                  height: 3,
                  color: selected ? kCirculGreen : Colors.transparent,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ResultSection extends StatelessWidget {
  const _ResultSection({
    required this.title,
    required this.children,
    this.showSeeAll = false,
  });

  final String title;
  final List<Widget> children;
  final bool showSeeAll;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                color: kInk,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            if (showSeeAll)
              const Text(
                'Lihat semua',
                style: TextStyle(
                  color: kCirculGreen,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        ...children,
        const Divider(height: 30, color: kLine),
      ],
    );
  }
}

class _SearchPostResult extends StatelessWidget {
  const _SearchPostResult({
    required this.post,
    required this.onTap,
    this.savedPostRepository,
    this.onPostSaved,
    this.likedPostRepository,
    this.onPostLiked,
  });

  final FeedPost post;
  final VoidCallback onTap;
  final SavedPostRepository? savedPostRepository;
  final VoidCallback? onPostSaved;
  final LikedPostRepository? likedPostRepository;
  final VoidCallback? onPostLiked;

  @override
  Widget build(BuildContext context) {
    final timestamp = post.createdAt == null
        ? post.timeAgo
        : formatRelativeTimestamp(post.createdAt!);
    final title = post.title.trim().isEmpty ? post.topic : post.title;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SarahAvatar(radius: 26),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Text(
                        post.author,
                        style: const TextStyle(
                          color: kInk,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (post.topic.isNotEmpty) _TopicPill(text: post.topic),
                      const _Dot(),
                      Text(
                        timestamp,
                        style: const TextStyle(
                          color: kMuted,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: kInk,
                                fontSize: 16,
                                height: 1.25,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              post.body,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: kInk,
                                fontSize: 15,
                                height: 1.45,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      _PostThumb(post: post),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      _SearchLikeAction(
                        post: post,
                        likedPostRepository: likedPostRepository,
                        onPostLiked: onPostLiked,
                      ),
                      _MiniAction(
                        icon: Icons.chat_bubble_outline_rounded,
                        text: '${post.comments}',
                      ),
                      const _MiniAction(
                        icon: Icons.reply_rounded,
                        text: 'Bagikan',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Lainnya',
              onPressed: () => showPostOptionsBottomSheet(
                context,
                post: post,
                savedPostRepository: savedPostRepository,
                onPostSaved: onPostSaved,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              icon: const Icon(
                Icons.more_horiz_rounded,
                color: kMuted,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostThumb extends StatelessWidget {
  const _PostThumb({required this.post});

  final FeedPost post;

  @override
  Widget build(BuildContext context) {
    final localPath = post.imagePaths.isEmpty ? null : post.imagePaths.first;
    final asset = post.imageAsset.isEmpty ? null : post.imageAsset;
    final hasMultiple = post.imagePaths.length > 1;

    Widget child;
    if (localPath != null) {
      child = Image.file(
        File(localPath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const ColoredBox(color: Color(0xFFE5E7EB));
        },
      );
    } else if (asset != null) {
      child = Image.asset(asset, fit: BoxFit.cover);
    } else {
      child = const ColoredBox(color: Color(0xFFE5E7EB));
    }

    return GestureDetector(
      onTap: localPath == null
          ? null
          : () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) =>
                      UploadedImageFullscreenPage(imagePath: localPath),
                ),
              );
            },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 96,
          height: 96,
          child: Stack(
            fit: StackFit.expand,
            children: [
              child,
              if (hasMultiple)
                Positioned(
                  left: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: .55),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${post.imagePaths.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserResultTile extends StatelessWidget {
  const _UserResultTile({required this.user});

  final _SearchUser user;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          _UserAvatar(user: user),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.username,
                  style: const TextStyle(
                    color: kInk,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  user.name,
                  style: const TextStyle(
                    color: kMuted,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${user.postCount} postingan • Aktif ${user.activeAgo}',
                  style: const TextStyle(
                    color: kMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: kCirculGreen,
              side: const BorderSide(color: kCirculGreen),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Ikuti',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicPill extends StatelessWidget {
  const _TopicPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F1F3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: kMuted,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MiniAction extends StatelessWidget {
  const _MiniAction({
    required this.icon,
    required this.text,
    this.onTap,
    this.selected = false,
    this.iconWidget,
  });

  final IconData icon;
  final String text;
  final VoidCallback? onTap;
  final bool selected;
  final Widget? iconWidget;

  @override
  Widget build(BuildContext context) {
    final color = selected ? kCirculGreen : kMuted;
    final content = Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        border: Border.all(color: kLine),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          iconWidget ?? Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return content;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: content,
    );
  }
}

class _SearchLikeAction extends StatefulWidget {
  const _SearchLikeAction({
    required this.post,
    this.likedPostRepository,
    this.onPostLiked,
  });

  final FeedPost post;
  final LikedPostRepository? likedPostRepository;
  final VoidCallback? onPostLiked;

  @override
  State<_SearchLikeAction> createState() => _SearchLikeActionState();
}

class _SearchLikeActionState extends State<_SearchLikeAction> {
  late final LikedPostRepository _repository;
  late var _likes = widget.post.likes;
  var _isLiked = false;
  var _isToggling = false;
  var _hasPlayedLikeAnimation = false;
  var _animateLike = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.likedPostRepository ?? LikedPostRepository();
    _loadLikedState();
  }

  @override
  void didUpdateWidget(covariant _SearchLikeAction oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.id != widget.post.id ||
        oldWidget.post.likes != widget.post.likes) {
      if (oldWidget.post.id != widget.post.id) {
        _hasPlayedLikeAnimation = false;
      }
      _animateLike = false;
      _likes = widget.post.likes;
      _loadLikedState();
    }
  }

  Future<void> _loadLikedState() async {
    final isLiked = await _repository.isLiked(widget.post);
    if (!mounted) return;
    setState(() {
      _isLiked = isLiked;
      _hasPlayedLikeAnimation = _hasPlayedLikeAnimation || isLiked;
      _animateLike = false;
    });
  }

  Future<void> _toggleLike() async {
    if (_isToggling) return;

    setState(() => _isToggling = true);
    try {
      final result = await _repository.toggleLike(widget.post);
      if (!mounted) return;
      setState(() {
        _animateLike = result.isLiked && !_hasPlayedLikeAnimation;
        if (result.isLiked) {
          _hasPlayedLikeAnimation = true;
        }
        _isLiked = result.isLiked;
        _likes = result.likes;
      });
      widget.onPostLiked?.call();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Like gagal disimpan.')));
    } finally {
      if (mounted) setState(() => _isToggling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _MiniAction(
      icon: Icons.favorite_border_rounded,
      iconWidget: AnimatedLikeIcon(
        isLiked: _isLiked,
        size: 22,
        animate: _animateLike,
      ),
      text: '$_likes',
      selected: _isLiked,
      onTap: _toggleLike,
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.user});

  final _SearchUser user;

  @override
  Widget build(BuildContext context) {
    if (user.assetPath != null) return SarahAvatar(radius: 27);

    return CircleAvatar(
      radius: 27,
      backgroundColor: user.color,
      child: Text(
        user.initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.w900,
        ),
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

class _SearchUser {
  const _SearchUser({
    required this.username,
    required this.name,
    required this.postCount,
    required this.activeAgo,
    required this.initial,
    required this.color,
    this.assetPath,
  });

  factory _SearchUser.fromPosts({
    required String author,
    required List<FeedPost> posts,
  }) {
    final latestPost = posts.reduce((first, second) {
      final firstDate =
          first.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final secondDate =
          second.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return firstDate.isAfter(secondDate) ? first : second;
    });
    final activeAgo = latestPost.createdAt == null
        ? latestPost.timeAgo
        : formatRelativeTimestamp(latestPost.createdAt!);

    return _SearchUser(
      username: author,
      name: _displayName(author),
      postCount: posts.length,
      activeAgo: activeAgo,
      initial: author.isEmpty ? '?' : author.characters.first.toUpperCase(),
      color: author == 'sarahmae' ? kCirculGreen : _avatarColor(author),
      assetPath: author == 'sarahmae' ? avatarAsset : null,
    );
  }

  final String username;
  final String name;
  final int postCount;
  final String activeAgo;
  final String initial;
  final Color color;
  final String? assetPath;
}

String _displayName(String author) {
  if (author == 'sarahmae') return 'Sarah Mae';
  return author
      .split(RegExp(r'[._-]'))
      .where((part) => part.isNotEmpty)
      .map(
        (part) => '${part.characters.first.toUpperCase()}${part.substring(1)}',
      )
      .join(' ');
}

Color _avatarColor(String value) {
  const colors = [
    Color(0xFF35C96B),
    Color(0xFF86A9A8),
    Color(0xFFE98B64),
    Color(0xFF8BC8E8),
  ];
  return colors[value.hashCode.abs() % colors.length];
}

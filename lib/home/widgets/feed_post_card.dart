import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../image_viewer/uploaded_image_fullscreen_page.dart';
import '../../liked_post_repository.dart';
import '../../mock_data.dart';
import '../../new_post/widgets/attachment_media_strip.dart';
import '../../profile/editable_profile.dart';
import '../../saved_post_repository.dart';
import '../../shared/animated_like_icon.dart';
import '../../shared/relative_timestamp.dart';
import '../../shared/sarah_avatar.dart';
import 'post_options_bottom_sheet.dart';

class FeedPostCard extends StatefulWidget {
  const FeedPostCard({
    super.key,
    required this.post,
    this.compact = false,
    this.framed = false,
    this.showActions = false,
    this.framedMargin,
    this.savedPostRepository,
    this.onPostSaved,
    this.savedTabOptions = false,
    this.likedPostRepository,
    this.onPostLiked,
    this.onOpenComments,
    this.onOpenLocation,
    this.currentUserProfile,
    this.currentUserAuthor = 'sarahmae',
  });

  final FeedPost post;
  final bool compact;
  final bool framed;
  final bool showActions;
  final EdgeInsetsGeometry? framedMargin;
  final SavedPostRepository? savedPostRepository;
  final VoidCallback? onPostSaved;
  final bool savedTabOptions;
  final LikedPostRepository? likedPostRepository;
  final VoidCallback? onPostLiked;
  final VoidCallback? onOpenComments;
  final VoidCallback? onOpenLocation;
  final EditableProfile? currentUserProfile;
  final String currentUserAuthor;

  @override
  State<FeedPostCard> createState() => _FeedPostCardState();
}

class _FeedPostCardState extends State<FeedPostCard> {
  late final LikedPostRepository _likedPostRepository;
  late var _likes = widget.post.likes;
  var _isLiked = false;
  var _isTogglingLike = false;
  var _hasPlayedLikeAnimation = false;
  var _animateLike = false;

  @override
  void initState() {
    super.initState();
    _likedPostRepository = widget.likedPostRepository ?? LikedPostRepository();
    _loadLikedState();
  }

  @override
  void didUpdateWidget(covariant FeedPostCard oldWidget) {
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
    final isLiked = await _likedPostRepository.isLiked(widget.post);
    if (!mounted) return;
    setState(() {
      _isLiked = isLiked;
      _hasPlayedLikeAnimation = _hasPlayedLikeAnimation || isLiked;
      _animateLike = false;
    });
  }

  Future<void> _toggleLike() async {
    if (_isTogglingLike) return;

    setState(() => _isTogglingLike = true);
    try {
      final result = await _likedPostRepository.toggleLike(widget.post);
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
      if (mounted) setState(() => _isTogglingLike = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.post.title.trim();
    final topic = widget.post.topic.trim();
    final showTitle =
        title.isNotEmpty && title.toLowerCase() != topic.toLowerCase();
    final timestamp = widget.post.createdAt == null
        ? widget.post.timeAgo
        : formatRelativeTimestamp(widget.post.createdAt!);
    final isCurrentUserPost =
        widget.post.author.toLowerCase() ==
            widget.currentUserAuthor.toLowerCase() ||
        widget.post.author.toLowerCase() ==
            widget.currentUserProfile?.username.toLowerCase();
    final currentProfile = widget.currentUserProfile;
    final authorLabel = isCurrentUserPost && currentProfile != null
        ? (widget.compact ? currentProfile.name : currentProfile.username)
        : (widget.compact
              ? _displayName(widget.post.author)
              : widget.post.author);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PostAuthorAvatar(
              radius: widget.compact ? 20 : 24,
              imagePath: isCurrentUserPost ? currentProfile?.imagePath : null,
              fallbackToSarah: isCurrentUserPost,
              author: widget.post.author,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          authorLabel,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontSize: widget.compact ? 15 : 16,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      if (!widget.compact && widget.post.topic.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        _Pill(text: widget.post.topic),
                        const SizedBox(width: 8),
                        const _Dot(),
                      ],
                      const SizedBox(width: 6),
                      Text(
                        timestamp,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: kMuted),
                      ),
                    ],
                  ),
                  if (showTitle) ...[
                    const SizedBox(height: 10),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        height: 1.35,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    widget.post.body,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(height: 1.45, color: kInk),
                  ),
                  const SizedBox(height: 14),
                  _PostMediaStrip(
                    post: widget.post,
                    compact: widget.compact,
                    onTap: widget.onOpenComments,
                    onLocationTap: widget.onOpenLocation,
                  ),
                  if (!widget.compact || widget.showActions) ...[
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _ActionButton(
                          icon: Icons.favorite_border_rounded,
                          iconWidget: AnimatedLikeIcon(
                            isLiked: _isLiked,
                            animate: _animateLike,
                          ),
                          text: '$_likes',
                          selected: _isLiked,
                          onTap: _toggleLike,
                        ),
                        _ActionButton(
                          icon: Icons.chat_bubble_outline_rounded,
                          text: '${widget.post.comments}',
                          onTap: widget.onOpenComments,
                        ),
                        const _ActionButton(
                          icon: Icons.reply_rounded,
                          text: 'Bagikan',
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              tooltip: 'Lainnya',
              onPressed: () => showPostOptionsBottomSheet(
                context,
                post: widget.post,
                savedPostRepository: widget.savedPostRepository,
                onPostSaved: widget.onPostSaved,
                savedTabMode: widget.savedTabOptions,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              icon: const Icon(Icons.more_horiz_rounded),
              iconSize: 22,
            ),
          ],
        ),
      ],
    );
    final tappableContent = widget.onOpenComments == null
        ? content
        : GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: widget.onOpenComments,
            child: content,
          );

    if (!widget.framed) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          widget.compact ? 14 : 22,
          16,
          widget.compact ? 8 : 22,
        ),
        child: tappableContent,
      );
    }

    return Container(
      margin: widget.framedMargin ?? const EdgeInsets.fromLTRB(18, 14, 18, 20),
      padding: const EdgeInsets.fromLTRB(16, 16, 6, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kLine),
      ),
      child: tappableContent,
    );
  }
}

class _PostMediaStrip extends StatelessWidget {
  const _PostMediaStrip({
    required this.post,
    required this.compact,
    this.onTap,
    this.onLocationTap,
  });

  final FeedPost post;
  final bool compact;
  final VoidCallback? onTap;
  final VoidCallback? onLocationTap;

  @override
  Widget build(BuildContext context) {
    final imagePaths = post.imagePaths;
    final imageAsset = _visibleImageAsset(post);

    if (!post.locationEnabled) {
      if (imagePaths.isEmpty) {
        if (imageAsset == null) return const SizedBox.shrink();
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            imageAsset,
            width: double.infinity,
            height: compact ? 170 : 200,
            fit: BoxFit.cover,
          ),
        );
      }

      if (imagePaths.length == 1) {
        return _LocalPostImage(
          path: imagePaths.first,
          height: compact ? 170 : 200,
          onTap: onTap,
        );
      }

      return SizedBox(
        height: compact ? 170 : 200,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          itemCount: imagePaths.length,
          separatorBuilder: (context, index) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            return SizedBox(
              width: compact ? 170 : 200,
              child: _LocalPostImage(
                path: imagePaths[index],
                height: compact ? 170 : 200,
                onTap: onTap,
              ),
            );
          },
        ),
      );
    }

    final hasImages = imagePaths.isNotEmpty || imageAsset != null;
    return LayoutBuilder(
      builder: (context, constraints) {
        final locationWidth = hasImages
            ? math.min(136.0, constraints.maxWidth * 0.64)
            : constraints.maxWidth;

        if (!hasImages) {
          return _LocationCardTapTarget(
            onTap: onLocationTap,
            child: LocationPlaceholderBox(
              enabled: true,
              loading: false,
              width: locationWidth,
              label: post.locationLabel ?? post.city,
              coordinateLabel: post.coordinateLabel,
            ),
          );
        }

        return SizedBox(
          height: 136,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: [
                _LocationCardTapTarget(
                  onTap: onLocationTap,
                  child: LocationPlaceholderBox(
                    enabled: true,
                    loading: false,
                    width: locationWidth,
                    label: post.locationLabel ?? post.city,
                    coordinateLabel: post.coordinateLabel,
                  ),
                ),
                const SizedBox(width: 10),
                if (imageAsset != null) ...[
                  _AssetImagePreviewCard(
                    asset: imageAsset,
                    width: locationWidth,
                    onTap: onTap,
                  ),
                  const SizedBox(width: 10),
                ],
                for (final path in imagePaths) ...[
                  SizedBox(
                    width: locationWidth,
                    child: _LocalPostImage(
                      path: path,
                      height: 136,
                      onTap: onTap,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String? _visibleImageAsset(FeedPost post) {
    if (post.imageAsset.isEmpty) return null;
    if (post.locationEnabled && post.imagePaths.isEmpty) return null;
    return post.imageAsset;
  }
}

class _LocationCardTapTarget extends StatelessWidget {
  const _LocationCardTapTarget({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (onTap == null) return child;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: child,
    );
  }
}

class _AssetImagePreviewCard extends StatelessWidget {
  const _AssetImagePreviewCard({
    required this.asset,
    required this.width,
    this.onTap,
  });

  final String asset;
  final double width;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final image = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(asset, width: width, height: 136, fit: BoxFit.cover),
    );

    if (onTap == null) return image;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onTap,
      child: image,
    );
  }
}

class _LocalPostImage extends StatelessWidget {
  const _LocalPostImage({required this.path, required this.height, this.onTap});

  final String path;
  final double height;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          onTap!();
          return;
        }

        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => UploadedImageFullscreenPage(imagePath: path),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(path),
          width: double.infinity,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: height,
              color: const Color(0xFFF3F4F6),
              alignment: Alignment.center,
              child: const Icon(
                Icons.broken_image_outlined,
                color: kMuted,
                size: 34,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PostAuthorAvatar extends StatelessWidget {
  const _PostAuthorAvatar({
    required this.radius,
    required this.author,
    this.imagePath,
    this.fallbackToSarah = false,
  });

  final double radius;
  final String author;
  final String? imagePath;
  final bool fallbackToSarah;

  @override
  Widget build(BuildContext context) {
    final path = imagePath;
    if (path != null && path.trim().isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFFE5E7EB),
        child: ClipOval(
          child: Image.file(
            File(path),
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                fallbackToSarah ? SarahAvatar(radius: radius) : _fallback(),
          ),
        ),
      );
    }

    if (fallbackToSarah) return SarahAvatar(radius: radius);
    return _fallback();
  }

  Widget _fallback() {
    final initial = author.isEmpty
        ? '?'
        : author.characters.first.toUpperCase();
    return CircleAvatar(
      radius: radius,
      backgroundColor: _avatarColor(author),
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * .95,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
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
    Color(0xFF16A34A),
    Color(0xFF2563EB),
    Color(0xFFEA580C),
    Color(0xFF7C3AED),
  ];
  if (value.isEmpty) return colors.first;
  final index = value.codeUnits.fold<int>(0, (sum, unit) => sum + unit);
  return colors[index % colors.length];
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F1F2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: kMuted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({
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
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          iconWidget ?? Icon(icon, color: color, size: 19),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kLine),
          ),
          child: content,
        ),
      ),
    );
  }
}

import 'dart:io';

import 'package:flutter/material.dart';

import '../../image_viewer/uploaded_image_fullscreen_page.dart';
import '../../mock_data.dart';
import '../../shared/sarah_avatar.dart';

class FeedPostCard extends StatelessWidget {
  const FeedPostCard({
    super.key,
    required this.post,
    this.compact = false,
    this.framed = false,
    this.onOpenComments,
  });

  final FeedPost post;
  final bool compact;
  final bool framed;
  final VoidCallback? onOpenComments;

  @override
  Widget build(BuildContext context) {
    final title = post.title.trim();
    final topic = post.topic.trim();
    final showTitle =
        title.isNotEmpty && title.toLowerCase() != topic.toLowerCase();

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SarahAvatar(radius: compact ? 20 : 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          compact ? 'Sarah Mae' : post.author,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontSize: compact ? 15 : 16,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      if (!compact && post.topic.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        _Pill(text: post.topic),
                        const SizedBox(width: 8),
                        const _Dot(),
                      ],
                      const SizedBox(width: 6),
                      Text(
                        compact ? post.timeAgo : post.timeAgo,
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
                    post.body,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(height: 1.45, color: kInk),
                  ),
                  const SizedBox(height: 14),
                  _PostImageMedia(
                    post: post,
                    compact: compact,
                    onTap: onOpenComments,
                  ),
                  if (!compact) ...[
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _ActionButton(
                          icon: Icons.favorite_border_rounded,
                          text: '${post.likes}',
                        ),
                        _ActionButton(
                          icon: Icons.chat_bubble_outline_rounded,
                          text: '${post.comments}',
                          onTap: onOpenComments,
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
              onPressed: () {},
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              icon: const Icon(Icons.more_horiz_rounded),
              iconSize: 22,
            ),
          ],
        ),
      ],
    );
    final tappableContent = onOpenComments == null
        ? content
        : GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onOpenComments,
            child: content,
          );

    if (!framed) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          compact ? 14 : 22,
          16,
          compact ? 8 : 22,
        ),
        child: tappableContent,
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(18, 14, 18, 20),
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

class _PostImageMedia extends StatelessWidget {
  const _PostImageMedia({
    required this.post,
    required this.compact,
    this.onTap,
  });

  final FeedPost post;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final imagePaths = post.imagePaths;

    if (imagePaths.isEmpty) {
      if (post.imageAsset.isEmpty) return const SizedBox.shrink();
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          post.imageAsset,
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
  const _ActionButton({required this.icon, required this.text, this.onTap});

  final IconData icon;
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: kMuted, size: 19),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: kMuted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
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

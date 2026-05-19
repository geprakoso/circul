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
  });

  final FeedPost post;
  final bool compact;
  final bool framed;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SarahAvatar(radius: compact ? 22 : 28),
            const SizedBox(width: 14),
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
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      if (!compact && post.topic.isNotEmpty) ...[
                        const SizedBox(width: 10),
                        _Pill(text: post.topic),
                        const SizedBox(width: 10),
                        const _Dot(),
                      ],
                      const SizedBox(width: 8),
                      Text(
                        compact ? post.timeAgo : post.timeAgo,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: kMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    post.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    post.body,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      height: 1.45,
                      color: kInk,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _PostImageMedia(post: post, compact: compact),
                  if (!compact) ...[
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        _ActionButton(
                          icon: Icons.favorite_border_rounded,
                          text: '${post.likes}',
                        ),
                        const SizedBox(width: 12),
                        _ActionButton(
                          icon: Icons.chat_bubble_outline_rounded,
                          text: '${post.comments}',
                        ),
                        const SizedBox(width: 12),
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
              icon: const Icon(Icons.more_horiz_rounded),
            ),
          ],
        ),
      ],
    );

    if (!framed) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          compact ? 16 : 28,
          18,
          compact ? 10 : 28,
        ),
        child: content,
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      padding: const EdgeInsets.fromLTRB(20, 20, 8, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kLine),
      ),
      child: content,
    );
  }
}

class _PostImageMedia extends StatelessWidget {
  const _PostImageMedia({required this.post, required this.compact});

  final FeedPost post;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final imagePaths = post.imagePaths;

    if (imagePaths.isEmpty) {
      if (post.imageAsset.isEmpty) return const SizedBox.shrink();
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.asset(
          post.imageAsset,
          width: double.infinity,
          height: compact ? 190 : 230,
          fit: BoxFit.cover,
        ),
      );
    }

    if (imagePaths.length == 1) {
      return _LocalPostImage(
        path: imagePaths.first,
        height: compact ? 190 : 230,
      );
    }

    return SizedBox(
      height: compact ? 190 : 230,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: imagePaths.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return SizedBox(
            width: compact ? 190 : 230,
            child: _LocalPostImage(
              path: imagePaths[index],
              height: compact ? 190 : 230,
            ),
          );
        },
      ),
    );
  }
}

class _LocalPostImage extends StatelessWidget {
  const _LocalPostImage({required this.path, required this.height});

  final String path;
  final double height;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => UploadedImageFullscreenPage(imagePath: path),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F1F2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(color: kMuted, fontWeight: FontWeight.w600),
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
  const _ActionButton({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kLine),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: kMuted),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(color: kMuted, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

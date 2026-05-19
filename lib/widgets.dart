import 'dart:io';

import 'package:flutter/material.dart';

import 'mock_data.dart';

class CirculLogo extends StatelessWidget {
  const CirculLogo({super.key, this.size = 46});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(size), painter: _CirculLogoPainter());
  }
}

class _CirculLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = kCirculGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.22
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromLTWH(
      size.width * 0.18,
      size.height * 0.16,
      size.width * 0.62,
      size.height * 0.68,
    );
    canvas.drawArc(rect, 0.78, 4.95, false, stroke);
    final dotPaint = Paint()..color = kCirculGreen;
    canvas.drawCircle(
      Offset(size.width * 0.78, size.height * 0.42),
      size.width * 0.095,
      dotPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.69, size.height * 0.66),
      size.width * 0.07,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CirculHeader extends StatelessWidget {
  const CirculHeader({super.key, this.showChat = true, this.title = 'Circul'});

  final bool showChat;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 18),
      child: Row(
        children: [
          const CirculLogo(size: 44),
          const SizedBox(width: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: kInk,
            ),
          ),
          const Spacer(),
          const NotificationIcon(),
          if (showChat) ...[
            const SizedBox(width: 14),
            IconButton(
              tooltip: 'Pesan',
              onPressed: () {},
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 27),
            ),
          ],
        ],
      ),
    );
  }
}

class NotificationIcon extends StatelessWidget {
  const NotificationIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: 'Notifikasi',
          onPressed: () {},
          icon: const Icon(Icons.notifications_none_rounded, size: 30),
        ),
        Positioned(
          right: 10,
          top: 9,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: kCirculGreen,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class SarahAvatar extends StatelessWidget {
  const SarahAvatar({super.key, this.radius = 26, this.showAddBadge = false});

  final double radius;
  final bool showAddBadge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: const Color(0xFFE5E7EB),
          child: ClipOval(
            child: Image.asset(
              avatarAsset,
              width: radius * 2,
              height: radius * 2,
              fit: BoxFit.cover,
            ),
          ),
        ),
        if (showAddBadge)
          Positioned(
            right: -3,
            bottom: -3,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: kCirculGreen,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
      ],
    );
  }
}

class SearchFieldShell extends StatelessWidget {
  const SearchFieldShell({
    super.key,
    required this.hint,
    this.icon = Icons.search_rounded,
    this.onTap,
  });

  final String hint;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(32),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        children: [
          Icon(icon, color: kMuted, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              hint,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: kMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(32),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(32),
        child: content,
      ),
    );
  }
}

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

class UploadedImageFullscreenPage extends StatelessWidget {
  const UploadedImageFullscreenPage({super.key, required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 5,
              child: Center(
                child: Image.file(
                  File(imagePath),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white70,
                      size: 54,
                    );
                  },
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: IconButton.filled(
                  tooltip: 'Tutup',
                  onPressed: () => Navigator.of(context).pop(),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.58),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            ),
          ),
        ],
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

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: onAction,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    action!,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class ChipButton extends StatelessWidget {
  const ChipButton({
    super.key,
    required this.label,
    required this.selected,
    this.icon,
    this.onTap,
  });

  final String label;
  final bool selected;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? kCirculGreen : Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: selected ? kCirculGreen : kLine),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: selected ? Colors.white : kMuted),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : kMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../image_viewer/uploaded_image_fullscreen_page.dart';

class AttachmentMediaStrip extends StatelessWidget {
  const AttachmentMediaStrip({
    super.key,
    required this.locationEnabled,
    required this.imagePaths,
    required this.onRemoveImage,
  });

  final bool locationEnabled;
  final List<String> imagePaths;
  final ValueChanged<String> onRemoveImage;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const height = 170.0;
        final cardWidth = imagePaths.isEmpty
            ? constraints.maxWidth
            : math.min(170.0, constraints.maxWidth * 0.72);

        if (imagePaths.isEmpty) {
          return LocationPlaceholderBox(
            enabled: locationEnabled,
            width: cardWidth,
          );
        }

        return SizedBox(
          height: height,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: [
                LocationPlaceholderBox(
                  enabled: locationEnabled,
                  width: cardWidth,
                ),
                const SizedBox(width: 12),
                for (final path in imagePaths) ...[
                  ImagePreviewCard(
                    path: path,
                    width: cardWidth,
                    onRemove: () => onRemoveImage(path),
                  ),
                  const SizedBox(width: 12),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class ImagePreviewCard extends StatelessWidget {
  const ImagePreviewCard({
    super.key,
    required this.path,
    required this.width,
    required this.onRemove,
  });

  final String path;
  final double width;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: width,
        height: 170,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) =>
                          UploadedImageFullscreenPage(imagePath: path),
                    ),
                  );
                },
                child: Image.file(
                  File(path),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
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
            ),
            Positioned(
              right: 8,
              top: 8,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.68),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.16),
                    ),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 19,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LocationPlaceholderBox extends StatelessWidget {
  const LocationPlaceholderBox({
    super.key,
    required this.enabled,
    required this.width,
  });

  final bool enabled;
  final double width;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: enabled ? 1 : 0.46,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: width,
          height: 170,
          decoration: BoxDecoration(
            color: const Color(0xFF151819),
            border: Border.all(
              color: enabled ? kCirculGreen : const Color(0xFF2B2E31),
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(painter: MiniMapPlaceholderPainter()),
              ),
              if (!enabled)
                Positioned.fill(
                  child: ColoredBox(color: Colors.black.withValues(alpha: 0.2)),
                ),
              Positioned(
                left: 12,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xE61A1D1F),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFF303438)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.flag_outlined, color: kCirculGreen, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Lokasi check-in',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Center(child: MapPinPlaceholder(enabled: enabled)),
              Positioned(
                right: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xE61A1D1F),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF303438)),
                  ),
                  child: Text(
                    enabled ? 'Map placeholder' : 'Tap bendera untuk check-in',
                    style: const TextStyle(
                      color: Color(0xFFB8BBBF),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
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

class MapPinPlaceholder extends StatelessWidget {
  const MapPinPlaceholder({super.key, required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 180),
      scale: enabled ? 1 : 0.86,
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFFE9FFF0) : const Color(0xFF39403C),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF101113), width: 5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: enabled ? 0.4 : 0.18),
              blurRadius: enabled ? 18 : 8,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(
          Icons.flag_rounded,
          color: enabled ? kCirculGreen : const Color(0xFF73777C),
          size: 28,
        ),
      ),
    );
  }
}

class MiniMapPlaceholderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = const Color(0xFF181C1D);
    canvas.drawRect(Offset.zero & size, background);

    final areaPaint = Paint()..color = const Color(0xFF1D2622);
    final area = Path()
      ..moveTo(0, size.height * 0.72)
      ..cubicTo(
        size.width * 0.26,
        size.height * 0.55,
        size.width * 0.48,
        size.height * 0.92,
        size.width,
        size.height * 0.68,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(area, areaPaint);

    final primaryRoad = Paint()
      ..color = const Color(0xFF34393D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    final secondaryRoad = Paint()
      ..color = const Color(0xFF2B3033)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(-10, size.height * 0.35),
      Offset(size.width + 10, size.height * 0.18),
      secondaryRoad,
    );
    canvas.drawLine(
      Offset(size.width * 0.12, size.height + 10),
      Offset(size.width * 0.68, -10),
      primaryRoad,
    );
    canvas.drawLine(
      Offset(-10, size.height * 0.56),
      Offset(size.width + 10, size.height * 0.48),
      secondaryRoad,
    );
    canvas.drawLine(
      Offset(size.width * 0.2, -8),
      Offset(size.width * 0.96, size.height + 8),
      secondaryRoad,
    );

    final gridPaint = Paint()
      ..color = const Color(0x223F464A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var x = 24.0; x < size.width; x += 46) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var y = 22.0; y < size.height; y += 42) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

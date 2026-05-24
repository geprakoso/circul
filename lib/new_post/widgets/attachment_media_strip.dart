import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../image_viewer/uploaded_image_fullscreen_page.dart';

const _attachmentHeight = 136.0;
const _attachmentRadius = 12.0;

class AttachmentMediaStrip extends StatelessWidget {
  const AttachmentMediaStrip({
    super.key,
    required this.locationEnabled,
    required this.locationLoading,
    required this.imagePaths,
    required this.onRemoveImage,
    this.locationLabel,
    this.coordinateLabel,
  });

  final bool locationEnabled;
  final bool locationLoading;
  final List<String> imagePaths;
  final ValueChanged<String> onRemoveImage;
  final String? locationLabel;
  final String? coordinateLabel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = imagePaths.isEmpty
            ? constraints.maxWidth
            : math.min(_attachmentHeight, constraints.maxWidth * 0.64);

        if (imagePaths.isEmpty) {
          return LocationPlaceholderBox(
            enabled: locationEnabled,
            loading: locationLoading,
            width: cardWidth,
            label: locationLabel,
            coordinateLabel: coordinateLabel,
          );
        }

        return SizedBox(
          height: _attachmentHeight,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: [
                LocationPlaceholderBox(
                  enabled: locationEnabled,
                  loading: locationLoading,
                  width: cardWidth,
                  label: locationLabel,
                  coordinateLabel: coordinateLabel,
                ),
                const SizedBox(width: 10),
                for (final path in imagePaths) ...[
                  ImagePreviewCard(
                    path: path,
                    width: cardWidth,
                    onRemove: () => onRemoveImage(path),
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
      borderRadius: BorderRadius.circular(_attachmentRadius),
      child: SizedBox(
        width: width,
        height: _attachmentHeight,
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
              right: 7,
              top: 7,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  width: 26,
                  height: 26,
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
                    size: 17,
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
    required this.loading,
    required this.width,
    this.label,
    this.coordinateLabel,
  });

  final bool enabled;
  final bool loading;
  final double width;
  final String? label;
  final String? coordinateLabel;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: enabled ? 1 : 0.46,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_attachmentRadius),
        child: Container(
          width: width,
          height: _attachmentHeight,
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
                left: 10,
                top: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xE61A1D1F),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF303438)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.flag_outlined, color: kCirculGreen, size: 15),
                      SizedBox(width: 6),
                      Text(
                        'Lokasi check-in',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Center(
                child: loading
                    ? const SizedBox.square(
                        dimension: 34,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: kCirculGreen,
                        ),
                      )
                    : MapPinPlaceholder(enabled: enabled),
              ),
              Positioned(
                right: 10,
                bottom: 10,
                child: Container(
                  constraints: BoxConstraints(maxWidth: width - 20),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xE61A1D1F),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF303438)),
                  ),
                  child: _LocationCaption(
                    enabled: enabled,
                    loading: loading,
                    label: label,
                    coordinateLabel: coordinateLabel,
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

class _LocationCaption extends StatelessWidget {
  const _LocationCaption({
    required this.enabled,
    required this.loading,
    this.label,
    this.coordinateLabel,
  });

  final bool enabled;
  final bool loading;
  final String? label;
  final String? coordinateLabel;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return const Text(
        'Tap bendera',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Color(0xFFB8BBBF),
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    if (loading) {
      return const Text(
        'Getting location...',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.white,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      );
    }

    final cleanLabel = label?.trim();
    final cleanCoordinate = coordinateLabel?.trim();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          cleanLabel?.isNotEmpty == true ? cleanLabel! : 'Location active',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (cleanCoordinate?.isNotEmpty == true) ...[
          const SizedBox(height: 2),
          Text(
            cleanCoordinate!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFB8BBBF),
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
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
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFFE9FFF0) : const Color(0xFF39403C),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF101113), width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: enabled ? 0.4 : 0.18),
              blurRadius: enabled ? 12 : 6,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Icon(
          Icons.flag_rounded,
          color: enabled ? kCirculGreen : const Color(0xFF73777C),
          size: 22,
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

import 'dart:io';

import 'package:flutter/material.dart';

class UploadedImageFullscreenPage extends StatelessWidget {
  const UploadedImageFullscreenPage({super.key, required this.imagePath})
    : assetPath = null;

  const UploadedImageFullscreenPage.asset({super.key, required this.assetPath})
    : imagePath = null;

  final String? imagePath;
  final String? assetPath;

  @override
  Widget build(BuildContext context) {
    final localImagePath = imagePath;
    final localAssetPath = assetPath;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 5,
              child: Center(
                child: localAssetPath == null
                    ? Image.file(
                        File(localImagePath!),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white70,
                            size: 54,
                          );
                        },
                      )
                    : Image.asset(localAssetPath, fit: BoxFit.contain),
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

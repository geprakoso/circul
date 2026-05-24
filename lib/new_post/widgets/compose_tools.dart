import 'package:flutter/material.dart';

import '../../core/constants.dart';

class ComposeTools extends StatelessWidget {
  const ComposeTools({
    super.key,
    required this.locationCheckInEnabled,
    required this.onImageTap,
    required this.onLocationCheckInTap,
  });

  final bool locationCheckInEnabled;
  final VoidCallback onImageTap;
  final VoidCallback onLocationCheckInTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        ComposeToolButton(
          icon: Icons.image_outlined,
          tooltip: 'Foto',
          onPressed: onImageTap,
        ),
        ComposeToolButton(
          icon: Icons.flag_outlined,
          tooltip: 'Check-in lokasi',
          selected: locationCheckInEnabled,
          onPressed: onLocationCheckInTap,
        ),
        const ComposeToolButton(icon: Icons.gif_box_outlined, tooltip: 'GIF'),
        const ComposeToolButton(
          icon: Icons.note_alt_outlined,
          tooltip: 'Stiker',
        ),
        const ComposeToolButton(
          icon: Icons.article_outlined,
          tooltip: 'Template',
        ),
        const ComposeToolButton(
          icon: Icons.more_horiz_rounded,
          tooltip: 'Lainnya',
        ),
      ],
    );
  }
}

class ComposeToolButton extends StatelessWidget {
  const ComposeToolButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.selected = false,
    this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 32, height: 32),
      style: IconButton.styleFrom(
        backgroundColor: selected ? const Color(0xFF183B2A) : null,
      ),
      onPressed: onPressed ?? () {},
      icon: Icon(
        icon,
        color: selected ? kCirculGreen : const Color(0xFF73777C),
        size: 25,
      ),
    );
  }
}

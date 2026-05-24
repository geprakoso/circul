import 'package:flutter/material.dart';

class ComposeHeader extends StatelessWidget {
  const ComposeHeader({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Row(
        children: [
          const SizedBox(width: 6),
          IconButton(
            tooltip: 'Tutup',
            onPressed: onClose,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            icon: const Icon(
              Icons.close_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 6),
          const Expanded(
            child: Text(
              'Post baru',
              style: TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Draf',
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            icon: const Icon(
              Icons.note_add_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Lainnya',
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            icon: const Icon(
              Icons.more_horiz_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }
}

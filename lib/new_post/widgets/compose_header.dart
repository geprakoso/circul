import 'package:flutter/material.dart';

class ComposeHeader extends StatelessWidget {
  const ComposeHeader({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      child: Row(
        children: [
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Tutup',
            onPressed: onClose,
            icon: const Icon(
              Icons.close_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Post baru',
              style: TextStyle(
                color: Colors.white,
                fontSize: 27,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Draf',
            onPressed: () {},
            icon: const Icon(
              Icons.note_add_outlined,
              color: Colors.white,
              size: 31,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Lainnya',
            onPressed: () {},
            icon: const Icon(
              Icons.more_horiz_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

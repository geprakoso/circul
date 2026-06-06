import 'package:flutter/material.dart';

import '../../core/constants.dart';

class ProfilePlaceholder extends StatelessWidget {
  const ProfilePlaceholder({super.key, required this.tab});

  final String tab;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kLine),
      ),
      child: Row(
        children: [
          const Icon(Icons.eco_outlined, color: kCirculGreen, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$tab Sarah Mae akan tampil di sini.',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

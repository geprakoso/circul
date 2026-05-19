import 'package:flutter/material.dart';

import '../../core/constants.dart';

class ProfilePlaceholder extends StatelessWidget {
  const ProfilePlaceholder({super.key, required this.tab});

  final String tab;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 18, 20, 26),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kLine),
      ),
      child: Row(
        children: [
          const Icon(Icons.eco_outlined, color: kCirculGreen, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              '$tab Sarah Mae akan tampil di sini.',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

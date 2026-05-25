import 'package:flutter/material.dart';

import '../../core/constants.dart';

class ProfileMeta extends StatelessWidget {
  const ProfileMeta({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: kMuted, size: 18),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            color: kMuted,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

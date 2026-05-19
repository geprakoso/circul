import 'package:flutter/material.dart';

import '../../mock_data.dart';

class AchievementBadge extends StatelessWidget {
  const AchievementBadge({super.key, required this.achievement});

  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: [
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              color: kSoftGreen,
              shape: BoxShape.circle,
              border: Border.all(color: kLine),
            ),
            child: Icon(achievement.icon, color: kCirculGreen, size: 42),
          ),
          const SizedBox(height: 14),
          Text(
            achievement.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            achievement.caption,
            textAlign: TextAlign.center,
            style: const TextStyle(color: kMuted, fontSize: 13, height: 1.3),
          ),
        ],
      ),
    );
  }
}

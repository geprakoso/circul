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
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: kSoftGreen,
              shape: BoxShape.circle,
              border: Border.all(color: kLine),
            ),
            child: Icon(achievement.icon, color: kCirculGreen, size: 32),
          ),
          const SizedBox(height: 10),
          Text(
            achievement.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            achievement.caption,
            textAlign: TextAlign.center,
            style: const TextStyle(color: kMuted, fontSize: 12, height: 1.25),
          ),
        ],
      ),
    );
  }
}

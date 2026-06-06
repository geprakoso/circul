import 'package:flutter/material.dart';

import '../../mock_data.dart';

class AchievementBadge extends StatelessWidget {
  const AchievementBadge({super.key, required this.achievement});

  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: kSoftGreen,
              shape: BoxShape.circle,
              border: Border.all(color: kLine),
            ),
            child: Icon(achievement.icon, color: kCirculGreen, size: 27),
          ),
          const SizedBox(height: 8),
          Text(
            achievement.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            achievement.caption,
            textAlign: TextAlign.center,
            style: const TextStyle(color: kMuted, fontSize: 10.5, height: 1.25),
          ),
        ],
      ),
    );
  }
}

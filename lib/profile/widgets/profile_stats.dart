import 'package:flutter/material.dart';

import '../../core/constants.dart';

class ProfileStats extends StatelessWidget {
  const ProfileStats({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = [
      ('124', 'Follower'),
      ('198', 'Following'),
      ('23', 'Contributions'),
      ('8', 'Achievement'),
    ];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kLine),
      ),
      child: Row(
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            Expanded(
              child: Column(
                children: [
                  Text(
                    stats[i].$1,
                    style: const TextStyle(
                      color: kCirculGreen,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    stats[i].$2,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: kMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (i != stats.length - 1)
              Container(width: 1, height: 34, color: kLine),
          ],
        ],
      ),
    );
  }
}

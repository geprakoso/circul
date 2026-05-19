import 'package:flutter/material.dart';

import '../mock_data.dart';

class SarahAvatar extends StatelessWidget {
  const SarahAvatar({super.key, this.radius = 26, this.showAddBadge = false});

  final double radius;
  final bool showAddBadge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: const Color(0xFFE5E7EB),
          child: ClipOval(
            child: Image.asset(
              avatarAsset,
              width: radius * 2,
              height: radius * 2,
              fit: BoxFit.cover,
            ),
          ),
        ),
        if (showAddBadge)
          Positioned(
            right: -3,
            bottom: -3,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: kCirculGreen,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
      ],
    );
  }
}

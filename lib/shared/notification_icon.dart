import 'package:flutter/material.dart';

import '../core/constants.dart';

class NotificationIcon extends StatelessWidget {
  const NotificationIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: 'Notifikasi',
          onPressed: () {},
          icon: const Icon(Icons.notifications_none_rounded, size: 30),
        ),
        Positioned(
          right: 10,
          top: 9,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: kCirculGreen,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

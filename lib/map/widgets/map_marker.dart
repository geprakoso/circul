import 'package:flutter/material.dart';

import '../../core/constants.dart';

class MapMarker extends StatelessWidget {
  const MapMarker({
    super.key,
    required this.label,
    required this.distance,
    required this.color,
    required this.icon,
  });

  final String label;
  final String distance;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.location_on_rounded, color: color, size: 44),
        Transform.translate(
          offset: const Offset(-28, -2),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        Transform.translate(
          offset: const Offset(-18, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              Text(
                distance,
                style: const TextStyle(
                  color: kMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

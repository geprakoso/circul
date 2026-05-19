import 'package:flutter/material.dart';

import '../../core/constants.dart';

class MapSquareButton extends StatelessWidget {
  const MapSquareButton({super.key, required this.icon, this.label});

  final IconData icon;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      height: label == null ? 78 : 88,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 16,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: label == 'Lokasi saya' ? kCirculGreen : kInk,
            size: 31,
          ),
          if (label != null) ...[
            const SizedBox(height: 7),
            Text(
              label!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ],
      ),
    );
  }
}

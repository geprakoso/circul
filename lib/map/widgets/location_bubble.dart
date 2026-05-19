import 'package:flutter/material.dart';

class LocationBubble extends StatelessWidget {
  const LocationBubble({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: const Text(
        'Lokasi kamu',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class UserLocationPulse extends StatelessWidget {
  const UserLocationPulse({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      height: 112,
      decoration: BoxDecoration(
        color: const Color(0x5534C77B),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0x9934C77B), width: 1),
      ),
      alignment: Alignment.center,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: const Color(0xFF2EA7FF),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../core/constants.dart';
import 'notification_icon.dart';

class CirculLogo extends StatelessWidget {
  const CirculLogo({super.key, this.size = 46});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(size), painter: _CirculLogoPainter());
  }
}

class _CirculLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = kCirculGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.22
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromLTWH(
      size.width * 0.18,
      size.height * 0.16,
      size.width * 0.62,
      size.height * 0.68,
    );
    canvas.drawArc(rect, 0.78, 4.95, false, stroke);
    final dotPaint = Paint()..color = kCirculGreen;
    canvas.drawCircle(
      Offset(size.width * 0.78, size.height * 0.42),
      size.width * 0.095,
      dotPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.69, size.height * 0.66),
      size.width * 0.07,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CirculHeader extends StatelessWidget {
  const CirculHeader({super.key, this.showChat = true, this.title = 'Circul'});

  final bool showChat;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 18),
      child: Row(
        children: [
          const CirculLogo(size: 44),
          const SizedBox(width: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: kInk,
            ),
          ),
          const Spacer(),
          const NotificationIcon(),
          if (showChat) ...[
            const SizedBox(width: 14),
            IconButton(
              tooltip: 'Pesan',
              onPressed: () {},
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 27),
            ),
          ],
        ],
      ),
    );
  }
}

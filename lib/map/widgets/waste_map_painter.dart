import 'dart:math' as math;

import 'package:flutter/material.dart';

class WasteMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = const Color(0xFFF8F9FA);
    canvas.drawRect(Offset.zero & size, background);

    final park = Paint()..color = const Color(0xFFE6F1E8);
    final path = Path()
      ..moveTo(0, size.height * 0.58)
      ..lineTo(size.width * 0.26, size.height * 0.53)
      ..lineTo(size.width * 0.42, size.height * 0.63)
      ..lineTo(size.width * 0.34, size.height * 0.82)
      ..lineTo(0, size.height * 0.88)
      ..close();
    canvas.drawPath(path, park);

    final road = Paint()
      ..color = const Color(0xFFB7C1CB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    final thinRoad = Paint()
      ..color = const Color(0xFFD7DCE2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(0, size.height * 0.30),
      Offset(size.width, size.height * 0.34),
      road,
    );
    canvas.drawLine(
      Offset(size.width * 0.48, -20),
      Offset(size.width * 0.72, size.height),
      road,
    );
    canvas.drawLine(
      Offset(size.width * 0.80, 0),
      Offset(size.width * 0.76, size.height * 0.75),
      road,
    );
    canvas.drawLine(
      Offset(size.width * 0.56, size.height),
      Offset(size.width, size.height * 0.90),
      road,
    );
    canvas.drawLine(
      Offset(size.width * 0.23, size.height * 0.96),
      Offset(size.width * 0.43, size.height * 0.12),
      thinRoad,
    );

    final buildingPaint = Paint()..color = const Color(0xFFE8E8E8);
    final random = math.Random(9);
    for (var i = 0; i < 120; i++) {
      final w = 16 + random.nextDouble() * 30;
      final h = 10 + random.nextDouble() * 38;
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final rect = Rect.fromLTWH(x, y, w, h);
      canvas.save();
      canvas.translate(rect.center.dx, rect.center.dy);
      canvas.rotate((random.nextDouble() - .5) * .35);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: w, height: h),
          const Radius.circular(2),
        ),
        buildingPaint,
      );
      canvas.restore();
    }

    void heat(Offset center, double radius, Color color) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: .82),
            color.withValues(alpha: .22),
            color.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }

    heat(Offset(size.width * .30, size.height * .95), 120, Colors.red);
    heat(Offset(size.width * .29, size.height * .92), 90, Colors.yellow);
    heat(Offset(size.width * .39, size.height * .78), 82, Colors.greenAccent);
    heat(Offset(size.width * .50, size.height * .38), 95, Colors.blueAccent);
    heat(Offset(size.width * .83, size.height * .58), 75, Colors.greenAccent);
    heat(Offset(size.width * .35, size.height * .02), 88, Colors.yellow);
    heat(Offset(size.width * .53, size.height * .51), 96, Colors.greenAccent);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

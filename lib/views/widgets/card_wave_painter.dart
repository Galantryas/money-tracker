import 'package:flutter/material.dart';

/// Reusable custom painter to draw flowing wavy lines across cards
class CardWavePainter extends CustomPainter {
  final Color waveColor;
  final double strokeWidth;

  const CardWavePainter({
    required this.waveColor,
    this.strokeWidth = 1.6,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = waveColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    // Wave 1
    final path1 = Path();
    path1.moveTo(0, size.height * 0.35);
    path1.cubicTo(
      size.width * 0.35,
      size.height * 0.1,
      size.width * 0.65,
      size.height * 0.8,
      size.width,
      size.height * 0.3,
    );
    canvas.drawPath(path1, paint);

    // Wave 2
    final path2 = Path();
    path2.moveTo(0, size.height * 0.55);
    path2.cubicTo(
      size.width * 0.3,
      size.height * 0.3,
      size.width * 0.7,
      size.height * 0.95,
      size.width,
      size.height * 0.5,
    );
    canvas.drawPath(path2, paint);

    // Wave 3
    final path3 = Path();
    path3.moveTo(0, size.height * 0.75);
    path3.cubicTo(
      size.width * 0.4,
      size.height * 0.5,
      size.width * 0.75,
      size.height * 1.1,
      size.width,
      size.height * 0.7,
    );
    canvas.drawPath(path3, paint);
  }

  @override
  bool shouldRepaint(covariant CardWavePainter oldDelegate) =>
      oldDelegate.waveColor != waveColor || oldDelegate.strokeWidth != strokeWidth;
}

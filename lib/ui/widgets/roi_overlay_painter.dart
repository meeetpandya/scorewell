import 'dart:ui';

import 'package:flutter/material.dart';

class RoiOverlayPainter extends CustomPainter {
  RoiOverlayPainter({
    required this.tableRect,
    required this.questionRects,
    required this.totalRect,
    required this.enrollmentRect,
    required this.isLocked,
  });

  final Rect tableRect;
  final List<Rect> questionRects;
  final Rect totalRect;
  final Rect enrollmentRect;
  final bool isLocked;

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = isLocked ? Colors.greenAccent : Colors.redAccent;

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
      ..color = isLocked ? Colors.greenAccent.withValues(alpha: 0.5) : Colors.transparent;

    canvas.drawRect(tableRect, glowPaint);
    canvas.drawRect(tableRect, borderPaint);

    final cellPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = Colors.white70;

    canvas.drawRect(enrollmentRect, cellPaint);
    for (final rect in questionRects) {
      canvas.drawRect(rect, cellPaint);
    }
    canvas.drawRect(totalRect, cellPaint);
  }

  @override
  bool shouldRepaint(covariant RoiOverlayPainter oldDelegate) {
    return oldDelegate.tableRect != tableRect || oldDelegate.isLocked != isLocked;
  }
}

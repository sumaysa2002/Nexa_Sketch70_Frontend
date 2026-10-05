import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class ShapePainter extends CustomPainter{

  @override
  void paint(Canvas canvas, Size size) {
    // TODO: implement paint

    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    // Rectangle
    canvas.drawRect(
      Rect.fromLTWH(20, 20, size.width - 40, 100),
      paint,
    );

    // Circle
    canvas.drawCircle(
      Offset(size.width / 2, 200),
      50,
      paint
        ..style = PaintingStyle.fill
        ..color = Colors.red,
    );

    // Line
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height / 2),
      paint
        ..color = Colors.green
        ..strokeWidth = 2,
    );

  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    // TODO: implement shouldRepaint
    return true;
  }
  
}

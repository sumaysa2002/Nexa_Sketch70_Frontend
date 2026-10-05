import 'package:flutter/material.dart';

class ShapeCircle {
  Offset center;
  double radius;
  Paint paint;
  double rotation;

  ShapeCircle({
    required this.center,
    required this.radius,
    required this.paint,
    this.rotation = 0.0,
  });

  ShapeCircle copyWith() => ShapeCircle(
    center: center,
    radius: radius,
    rotation: rotation,
    paint: Paint()
      ..color = paint.color
      ..strokeWidth = paint.strokeWidth
      ..style = paint.style
      ..isAntiAlias = paint.isAntiAlias,
  );
}
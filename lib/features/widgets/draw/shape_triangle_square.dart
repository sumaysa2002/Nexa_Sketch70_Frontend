import 'dart:ui';
import 'package:flutter/material.dart';

enum Shape_TriangleSquare { triangle, square }

class Shape {
  Shape_TriangleSquare type;
  Offset center;
  double width;
  double height;
  Paint paint;
  double rotation;

  Shape({
    required this.type,
    required this.center,
    required this.width,
    required this.height,
    required this.paint,
    this.rotation = 0.0,
  });

  Shape copyWith() => Shape(
    type: type,
    center: center,
    width: width,
    height: height,
    rotation: rotation,
    paint: Paint()
      ..color = paint.color
      ..strokeWidth = paint.strokeWidth
      ..style = paint.style
      ..isAntiAlias = paint.isAntiAlias,
  );
}
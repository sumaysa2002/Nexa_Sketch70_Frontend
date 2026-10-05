import 'package:flutter/material.dart';
import 'shape_triangle_square.dart';

class ShapeObject {
  Shape_TriangleSquare? type;
  Offset position;
  double width;
  double height;
  Paint paint;
  double rotation;
  bool isCircle;

  ShapeObject({
    this.type,
    required this.position,
    required this.width,
    required this.height,
    required this.paint,
    this.rotation = 0.0,
    this.isCircle = false,
  });

  ShapeObject copyWith() =>  ShapeObject(
    type: type,
    position: position,
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
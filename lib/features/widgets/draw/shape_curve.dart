import 'package:flutter/material.dart';
import 'linestyle.dart';

class ShapeCurve {
  List<Offset> points;
  Paint paint;
  LineStyle lineStyle;

  ShapeCurve({
    required this.points,
    required this.paint,
    this.lineStyle = LineStyle.solid,
  });

  Offset get start => points.first;
  Offset get end => points.last;


  ShapeCurve copyWith() => ShapeCurve(
    points: points.map((p) => Offset(p.dx, p.dy)).toList(),
    lineStyle: lineStyle,
    paint: Paint()
      ..color = paint.color
      ..strokeWidth = paint.strokeWidth
      ..style = paint.style
      ..strokeCap = paint.strokeCap
      ..isAntiAlias = paint.isAntiAlias,
  );


  void translate(Offset delta) {
    points = points.map((p) => p + delta).toList();
  }

  Path toPath() {
    final path = Path();
    if (points.isEmpty) return path;

    path.moveTo(points.first.dx, points.first.dy);

    if (points.length == 1) return path;

    if (points.length == 2) {
      path.lineTo(points[1].dx, points[1].dy);
      return path;
    }

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = i == 0 ? points[i] : points[i - 1];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = (i + 2 < points.length) ? points[i + 2] : p2;

      final cp1 = Offset(
        p1.dx + (p2.dx - p0.dx) / 6,
        p1.dy + (p2.dy - p0.dy) / 6,
      );
      final cp2 = Offset(
        p2.dx - (p3.dx - p1.dx) / 6,
        p2.dy - (p3.dy - p1.dy) / 6,
      );

      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
    }

    return path;
  }
}

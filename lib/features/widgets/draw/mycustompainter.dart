import 'dart:ui' as ui;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:offline_gnss69_new/features/widgets/draw/linestyle.dart';
import 'drawing_area.dart';
import 'shape_curve.dart';

class MyCustomPainter extends CustomPainter {

  List<DrawingArea?> points;
  Color color;
  double strokeWidth;

  Offset? previewStart;
  Offset? previewEnd;

  final Offset? circleStart;
  final Offset? circleCurrent;
  final Offset? shapeStart;
  final Offset? shapeCurrent;

  final List<ShapeCurve> curves;
  final Offset? curveStart;
  final Offset? curveEnd;

  final String drawMode;
  final ui.Image? backgroundImage;
  final LineStyle lineStyle;

  MyCustomPainter({
    required this.points,
    required this.color,
    required this.strokeWidth,
    required this.previewStart,
    required this.previewEnd,
    required this.circleStart,
    required this.circleCurrent,
    required this.shapeStart,
    required this.shapeCurrent,
    required this.curves,
    required this.curveStart,
    required this.curveEnd,
    required this.drawMode,
    required this.backgroundImage,
    required this.lineStyle,
  });

  /// ── ประ เส้นตรง ──────────────────
  void _drawDottedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    final path = Path()..moveTo(start.dx, start.dy)..lineTo(end.dx, end.dy);
    _drawDottedOnPath(canvas, path, paint);
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    final path = Path()..moveTo(start.dx, start.dy)..lineTo(end.dx, end.dy);
    _drawDashedOnPath(canvas, path, paint);
  }

  void _drawDashDotLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    final path = Path()..moveTo(start.dx, start.dy)..lineTo(end.dx, end.dy);
    _drawDashDotOnPath(canvas, path, paint);
  }


  /// ── ประ เส้นโค้ง ──────────────────
  void _drawDottedOnPath(Canvas canvas, Path path, Paint paint) {
    final double dotDiameter = (paint.strokeWidth * 1.1).clamp(4.0, 16.0);
    final double radius = dotDiameter / 2.5;
    final double gap = dotDiameter * 0.4;

    final fillPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true
      ..blendMode = paint.blendMode;

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final tangent = metric.getTangentForOffset(distance);
        if (tangent != null) {
          canvas.drawCircle(tangent.position, radius, fillPaint);
        }
        distance += dotDiameter + gap;
      }
    }
  }

  void _drawDashedOnPath(Canvas canvas, Path path, Paint paint) {
    const dashWidth = 8.0;
    const dashSpace = 6.0;
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + dashWidth), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  void _drawDashDotOnPath(Canvas canvas, Path path, Paint paint) {
    const dashWidth = 10.0;
    const dashSpace = 5.0;
    const dotSize = 2.0;
    const dotSpace = 5.0;
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + dashWidth), paint);
        distance += dashWidth + dashSpace;
        if (distance < metric.length) {
          canvas.drawPath(metric.extractPath(distance, distance + dotSize), paint);
          distance += dotSize + dotSpace;
        }
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.saveLayer(rect, Paint());

    for (int x = 0; x < points.length - 1; x++) {
      final p1 = points[x];
      final p2 = points[x + 1];

      if (p1 != null && p2 != null) {
        final paint = p1.areaPaint;
        if (p1.lineStyle == LineStyle.dashed) {
          _drawDashedLine(canvas, p1.point, p2.point, paint);
        } else if (p1.lineStyle == LineStyle.dashDot) {
          _drawDashDotLine(canvas, p1.point, p2.point, paint);
        } else if (p1.lineStyle == LineStyle.dotted) {
          _drawDottedLine(canvas, p1.point, p2.point, paint);
        } else {
          canvas.drawLine(p1.point, p2.point, paint);
        }
      } else if (p1 != null && p2 == null) {
        canvas.drawPoints(PointMode.points, [p1.point], p1.areaPaint);
      }
    }

    for (final c in curves) {
      final path = c.toPath();

      switch (c.lineStyle) {
        case LineStyle.dashed:
          _drawDashedOnPath(canvas, path, c.paint);
          break;
        case LineStyle.dashDot:
          _drawDashDotOnPath(canvas, path, c.paint);
          break;
        case LineStyle.dotted:
          _drawDottedOnPath(canvas, path, c.paint);
          break;
        case LineStyle.solid:
          canvas.drawPath(path, c.paint);
          break;
      }
    }

    canvas.restore();
    _drawPreviews(canvas);
  }

  void _drawPreviews(Canvas canvas) {
    final previewPaint = Paint()
      ..color = color.withOpacity(0.5)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    if (previewStart != null && previewEnd != null) {
      if (lineStyle == LineStyle.dashed) {
        _drawDashedLine(canvas, previewStart!, previewEnd!, previewPaint);
      } else if (lineStyle == LineStyle.dashDot) {
        _drawDashDotLine(canvas, previewStart!, previewEnd!, previewPaint);
      } else if (lineStyle == LineStyle.dotted) {
        _drawDottedLine(canvas, previewStart!, previewEnd!, previewPaint);
      } else {
        canvas.drawLine(previewStart!, previewEnd!, previewPaint);
      }
    }

    // Circle Preview
    if (circleStart != null && circleCurrent != null) {
      final center = Offset(
        (circleStart!.dx + circleCurrent!.dx) / 2,
        (circleStart!.dy + circleCurrent!.dy) / 2,
      );
      final radius = (circleStart! - circleCurrent!).distance / 2;
      canvas.drawCircle(center, radius, previewPaint);
    }

    // Shape Preview
    if (shapeStart != null && shapeCurrent != null) {
      if (drawMode == "square") {
        canvas.drawRect(Rect.fromPoints(shapeStart!, shapeCurrent!), previewPaint);
      } else if (drawMode == "triangle") {
        final path = Path()
          ..moveTo((shapeStart!.dx + shapeCurrent!.dx) / 2, shapeStart!.dy)
          ..lineTo(shapeStart!.dx, shapeCurrent!.dy)
          ..lineTo(shapeCurrent!.dx, shapeCurrent!.dy)
          ..close();
        canvas.drawPath(path, previewPaint);
      }
    }

    // Curve Preview
    if (curveStart != null && curveEnd != null) {
      final mid = Offset.lerp(curveStart!, curveEnd!, 0.5)!;
      final path = Path()
        ..moveTo(curveStart!.dx, curveStart!.dy)
        ..quadraticBezierTo(mid.dx, mid.dy, curveEnd!.dx, curveEnd!.dy);

      switch (lineStyle) {
        case LineStyle.dashed:
          _drawDashedOnPath(canvas, path, previewPaint);
          break;
        case LineStyle.dashDot:
          _drawDashDotOnPath(canvas, path, previewPaint);
          break;
        case LineStyle.dotted:
          _drawDottedOnPath(canvas, path, previewPaint);
          break;
        case LineStyle.solid:
          canvas.drawPath(path, previewPaint);
          break;
      }
    }

  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
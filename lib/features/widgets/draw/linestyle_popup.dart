import 'package:flutter/material.dart';
import 'linestyle.dart';

class LineStyle_Popup extends StatelessWidget {
  final Offset iconPosition;
  final Size iconSize;
  final LineStyle? currentStyle;

  const LineStyle_Popup({
    super.key,
    required this.iconPosition,
    required this.iconSize,
    this.currentStyle,
  });

  static const double _popupRadius = 24;
  static const double _itemRadius = 16;

  @override
  Widget build(BuildContext context) {

    const double popupWidth = 258; // ความกว้าง popup
    final screenWidth = MediaQuery.of(context).size.width;

    double left = iconPosition.dx + iconSize.width / 2 - popupWidth / 2;
    left = left.clamp(12.0, screenWidth - popupWidth - 12.0);

    return Stack(
      children: [

        // ปิดเมื่อกดนอก popup
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(color: Colors.transparent),
        ),

        Positioned(
          left: left,
          top: iconPosition.dy - 150,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.92, end: 1.0),
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            builder: (context, scale, child) {
              return Transform.scale(
                alignment: Alignment.bottomCenter,
                scale: scale,
                child: Opacity(opacity: scale.clamp(0.0, 1.0), child: child),
              );
            },
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: popupWidth,
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(_popupRadius),
                  border: Border.all(color: Colors.black.withOpacity(0.06)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 10),
                      child: Text(
                        'เลือกประเภทเส้น',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'NotoSansThai',
                          color: Colors.grey.shade500,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _item(context, LineStyle.dotted, 'จุดไข่ปลา'),
                        _item(context, LineStyle.dashed, 'เส้นประ'),
                        _item(context, LineStyle.dashDot, 'ขีดจุด'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // ลูกศรชี้ลงหาไอคอน
        Positioned(
          left: (iconPosition.dx + iconSize.width / 2 - 8).clamp(
            left + 16,
            left + popupWidth - 16 - 8,
          ),
          top: iconPosition.dy - 31,
          child: CustomPaint(
            size: const Size(16, 10),
            painter: _DownArrowPainter(),
          ),
        ),
      ],
    );
  }

  Widget _item(BuildContext context, LineStyle style, String label) {
    final bool selected = currentStyle == style;

    return InkWell(
      borderRadius: BorderRadius.circular(_itemRadius),
      onTap: () => Navigator.pop(context, style),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? Colors.black
              : const Color(0xFFF6F6F6),
          borderRadius: BorderRadius.circular(_itemRadius),
          border: Border.all(
            color: selected
                ? Colors.black
                : Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 44,
              height: 22,
              child: Center(
                child: CustomPaint(
                  size: const Size(36, 18),
                  painter: _LineStylePreviewPainter(
                    style: style,
                    color: selected ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                fontFamily: 'NotoSansThai',
                color: selected ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ลูกศรชี้ลงหาไอคอน
class _DownArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawShadow(path, Colors.black.withOpacity(0.18), 3, false);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


/// ── ตัวอย่างเส้น (dotted / dashed / dashDot) ใน popup ──────────────────
class _LineStylePreviewPainter extends CustomPainter {
  final LineStyle style;
  final Color color;
  _LineStylePreviewPainter({required this.style, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final y = size.height / 2;
    final start = Offset(2, y);
    final end = Offset(size.width - 2, y);

    switch (style) {
      case LineStyle.dashed:
        _drawDashed(canvas, start, end, paint);
        break;
      case LineStyle.dashDot:
        _drawDashDot(canvas, start, end, paint);
        break;
      case LineStyle.dotted:
        _drawDotted(canvas, start, end, color);
        break;
      case LineStyle.solid:
        canvas.drawLine(start, end, paint);
        break;
    }
  }

  void _drawDotted(Canvas canvas, Offset start, Offset end, Color color) {
    const dotSize = 3.2;
    const gap = 3.2;
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..lineTo(end.dx, end.dy);

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final tangent = metric.getTangentForOffset(distance);
        if (tangent != null) {
          canvas.drawCircle(tangent.position, dotSize / 2, fillPaint);
        }
        distance += dotSize + gap;
      }
    }
  }

  void _drawDashed(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 6.0;
    const dashSpace = 4;
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..lineTo(end.dx, end.dy);
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + dashWidth), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  void _drawDashDot(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 7.0;
    const dashSpace = 5.0;
    const dotSize = 1.6;
    const dotSpace = 5.0;
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..lineTo(end.dx, end.dy);
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
  bool shouldRepaint(covariant _LineStylePreviewPainter oldDelegate) =>
      oldDelegate.style != style || oldDelegate.color != color;
}

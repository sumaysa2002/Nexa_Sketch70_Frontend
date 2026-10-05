import 'dart:math';
import 'package:flutter/material.dart';
import 'shape_triangle_square.dart';
import 'shape_circle.dart';

/// ─── Shape (Square / Triangle) ───────────────────────────────────
class WDraggableShape extends StatefulWidget {
  final Shape shape;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;
  final VoidCallback? onTransformEnd;
  final bool drawingActive;

  const WDraggableShape({
    super.key,
    required this.shape,
    required this.selected,
    required this.onSelect,
    required this.onDelete,
    required this.onDuplicate,
    this.onTransformEnd,
    this.drawingActive = false,
  });

  @override
  State<WDraggableShape> createState() => _WDraggableShapeState();
}

class _WDraggableShapeState extends State<WDraggableShape> {
  final GlobalKey _bodyKey = GlobalKey();

  Offset _rotateOffset(Offset offset, double angle) {
    final cosA = cos(angle);
    final sinA = sin(angle);
    return Offset(
      offset.dx * cosA - offset.dy * sinA,
      offset.dx * sinA + offset.dy * cosA,
    );
  }

  /// ── ย้าย ─────────────────────────────────────────────
  void _onBodyPanStart(DragStartDetails d) => widget.onSelect();
  void _onBodyPanUpdate(DragUpdateDetails d) {
    final worldDelta = _rotateOffset(d.delta, widget.shape.rotation);
    setState(() => widget.shape.center += worldDelta);
  }
  void _onBodyPanEnd(DragEndDetails d) => widget.onTransformEnd?.call();

  /// ── ย่อ-ขยาย ─────────────────────────────────────────
  double _startWidth = 0;
  double _startHeight = 0;
  double _resizeStartDistance = 1;
  Offset _resizeCenter = Offset.zero;

  Offset _globalCenter() {
    final box = _bodyKey.currentContext!.findRenderObject() as RenderBox;
    return box.localToGlobal(box.size.center(Offset.zero));
  }

  void _onResizeStart(DragStartDetails d) {
    _startWidth = widget.shape.width;
    _startHeight = widget.shape.height;
    _resizeCenter = _globalCenter();
    _resizeStartDistance =
        (d.globalPosition - _resizeCenter).distance.clamp(1.0, double.infinity);
  }

  void _onResizeUpdate(DragUpdateDetails d) {
    final currentDistance = (d.globalPosition - _resizeCenter).distance;
    final factor = (currentDistance / _resizeStartDistance).clamp(0.2, 6.0);
    setState(() {
      widget.shape.width = (_startWidth * factor).clamp(20.0, 2000.0);
      widget.shape.height = (_startHeight * factor).clamp(20.0, 2000.0);
    });
  }

  void _onResizeEnd(DragEndDetails d) => widget.onTransformEnd?.call();

  /// ── หมุน ─────────────────────────────────────────────
  double _startRotation = 0;
  double _rotateStartAngle = 0;
  Offset _rotateCenter = Offset.zero;

  void _onRotateStart(DragStartDetails d) {
    _rotateCenter = _globalCenter();
    _startRotation = widget.shape.rotation;
    _rotateStartAngle = atan2(
      d.globalPosition.dy - _rotateCenter.dy,
      d.globalPosition.dx - _rotateCenter.dx,
    );
  }

  void _onRotateUpdate(DragUpdateDetails d) {
    final currentAngle = atan2(
      d.globalPosition.dy - _rotateCenter.dy,
      d.globalPosition.dx - _rotateCenter.dx,
    );
    setState(() {
      widget.shape.rotation = _startRotation + (currentAngle - _rotateStartAngle);
    });
  }

  void _onRotateEnd(DragEndDetails d) => widget.onTransformEnd?.call();

  Widget _dragHandle({
    required Offset center,
    required IconData icon,
    required Color color,
    required GestureDragStartCallback onPanStart,
    required GestureDragUpdateCallback onPanUpdate,
    required GestureDragEndCallback onPanEnd,
  }) {
    const double size = 30.0;
    return Positioned(
      left: center.dx - size / 2,
      top: center.dy - size / 2,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: onPanStart,
        onPanUpdate: onPanUpdate,
        onPanEnd: onPanEnd,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: Icon(icon, color: Colors.white, size: 15),
        ),
      ),
    );
  }

  Widget _tapButton({
    required Offset center,
    required IconData icon,
    required Color color,
    required double size,
    required VoidCallback onTap,
  }) {
    return Positioned(
      left: center.dx - size / 2,
      top: center.dy - size / 2,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: Icon(icon, color: color, size: size * 0.62),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.shape.width;
    final h = widget.shape.height;
    final center = widget.shape.center;
    // กันชนรอบรูปทรง
    const double pad = 40.0;

    return Positioned(
      left: center.dx - w / 2 - pad,
      top: center.dy - h / 2 - pad,
      child: IgnorePointer(
        ignoring: widget.drawingActive,
        child: Transform.rotate(
          angle: widget.shape.rotation,
          child: SizedBox(
            width: w + pad * 2,
            height: h + pad * 2,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
            
                // shape
                Positioned(
                  left: pad,
                  top: pad,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.onSelect,
                    onPanStart: _onBodyPanStart,
                    onPanUpdate: _onBodyPanUpdate,
                    onPanEnd: _onBodyPanEnd,
                    child: SizedBox(
                      key: _bodyKey,
                      width: w,
                      height: h,
                      child: CustomPaint(
                        size: Size(w, h),
                        painter: _ShapePainter(
                          shape: widget.shape,
                          selected: widget.selected,
                        ),
                      ),
                    ),
                  ),
                ),
            
                if (widget.selected) ...[
            
                  // ปุ่มลบ
                  _tapButton(
                    center: Offset(pad + w + 6, pad - 14),
                    icon: Icons.cancel,
                    color: Colors.red,
                    size: 28,
                    onTap: widget.onDelete,
                  ),
            
                  // ปุ่มคัดลอก
                  _tapButton(
                    center: Offset(pad - 14, pad - 14),
                    icon: Icons.copy,
                    color: Colors.blueAccent,
                    size: 26,
                    onTap: widget.onDuplicate,
                  ),
            
                  // จุดจับหมุน
                  _dragHandle(
                    center: Offset(pad + w / 2, pad - 34),
                    icon: Icons.sync,
                    color: Colors.green,
                    onPanStart: _onRotateStart,
                    onPanUpdate: _onRotateUpdate,
                    onPanEnd: _onRotateEnd,
                  ),
            
                  // จุดจับย่อ-ขยาย
                  _dragHandle(
                    center: Offset(pad + w + 6, pad + h + 6),
                    icon: Icons.open_in_full,
                    color: Colors.blueAccent,
                    onPanStart: _onResizeStart,
                    onPanUpdate: _onResizeUpdate,
                    onPanEnd: _onResizeEnd,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShapePainter extends CustomPainter {
  final Shape shape;
  final bool selected;

  _ShapePainter({required this.shape, required this.selected});

  @override
  void paint(Canvas canvas, Size size) {
    if (shape.type == Shape_TriangleSquare.square) {
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), shape.paint);
    } else if (shape.type == Shape_TriangleSquare.triangle) {
      final path = Path()
        ..moveTo(size.width / 2, 0)
        ..lineTo(0, size.height)
        ..lineTo(size.width, size.height)
        ..close();
      canvas.drawPath(path, shape.paint);
    }

    if (selected) {
      const padding = 10.0;
      canvas.drawRect(
        Rect.fromLTWH(
            -padding, -padding, size.width + padding * 2, size.height + padding * 2),
        Paint()
          ..color = Colors.blueAccent
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}


/// ─── Draggable Circle ───────────────────────────────────
class WDraggableCircle extends StatefulWidget {
  final ShapeCircle circle;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;
  final VoidCallback? onTransformEnd;
  final bool drawingActive;

  const WDraggableCircle({
    super.key,
    required this.circle,
    required this.selected,
    required this.onSelect,
    required this.onDelete,
    required this.onDuplicate,
    this.onTransformEnd,
    this.drawingActive = false,
  });

  @override
  State<WDraggableCircle> createState() => _WDraggableCircleState();
}

class _WDraggableCircleState extends State<WDraggableCircle> {
  final GlobalKey _bodyKey = GlobalKey();
  Offset _rotateOffset(Offset offset, double angle) {
    final cosA = cos(angle);
    final sinA = sin(angle);
    return Offset(
      offset.dx * cosA - offset.dy * sinA,
      offset.dx * sinA + offset.dy * cosA,
    );
  }

  /// ── ย้าย ─────────────────────────────────────────────
  void _onBodyPanStart(DragStartDetails d) => widget.onSelect();
  void _onBodyPanUpdate(DragUpdateDetails d) {
    final worldDelta = _rotateOffset(d.delta, widget.circle.rotation);
    setState(() => widget.circle.center += worldDelta);
  }
  void _onBodyPanEnd(DragEndDetails d) => widget.onTransformEnd?.call();

  /// ── ย่อ-ขยาย ─────────────────────────────────────────
  double _startRadius = 0;
  double _resizeStartDistance = 1;
  Offset _resizeCenter = Offset.zero;

  Offset _globalCenter() {
    final box = _bodyKey.currentContext!.findRenderObject() as RenderBox;
    return box.localToGlobal(box.size.center(Offset.zero));
  }

  void _onResizeStart(DragStartDetails d) {
    _startRadius = widget.circle.radius;
    _resizeCenter = _globalCenter();
    _resizeStartDistance =
        (d.globalPosition - _resizeCenter).distance.clamp(1.0, double.infinity);
  }

  void _onResizeUpdate(DragUpdateDetails d) {
    final currentDistance = (d.globalPosition - _resizeCenter).distance;
    final factor = (currentDistance / _resizeStartDistance).clamp(0.2, 6.0);
    setState(() {
      widget.circle.radius = (_startRadius * factor).clamp(10.0, 1000.0);
    });
  }

  void _onResizeEnd(DragEndDetails d) => widget.onTransformEnd?.call();

  /// ── หมุน ─────────────────────────────────────────────
  double _startRotation = 0;
  double _rotateStartAngle = 0;
  Offset _rotateCenter = Offset.zero;

  void _onRotateStart(DragStartDetails d) {
    _rotateCenter = _globalCenter();
    _startRotation = widget.circle.rotation;
    _rotateStartAngle = atan2(
      d.globalPosition.dy - _rotateCenter.dy,
      d.globalPosition.dx - _rotateCenter.dx,
    );
  }

  void _onRotateUpdate(DragUpdateDetails d) {
    final currentAngle = atan2(
      d.globalPosition.dy - _rotateCenter.dy,
      d.globalPosition.dx - _rotateCenter.dx,
    );
    setState(() {
      widget.circle.rotation = _startRotation + (currentAngle - _rotateStartAngle);
    });
  }

  void _onRotateEnd(DragEndDetails d) => widget.onTransformEnd?.call();

  Widget _dragHandle({
    required Offset center,
    required IconData icon,
    required Color color,
    required GestureDragStartCallback onPanStart,
    required GestureDragUpdateCallback onPanUpdate,
    required GestureDragEndCallback onPanEnd,
  }) {
    const double size = 30.0;
    return Positioned(
      left: center.dx - size / 2,
      top: center.dy - size / 2,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: onPanStart,
        onPanUpdate: onPanUpdate,
        onPanEnd: onPanEnd,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: Icon(icon, color: Colors.white, size: 15),
        ),
      ),
    );
  }

  Widget _tapButton({
    required Offset center,
    required IconData icon,
    required Color color,
    required double size,
    required VoidCallback onTap,
  }) {
    return Positioned(
      left: center.dx - size / 2,
      top: center.dy - size / 2,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: Icon(icon, color: color, size: size * 0.62),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.circle.radius;
    final size = r * 2;
    final center = widget.circle.center;

    const double pad = 40.0;

    return Positioned(
      left: center.dx - r - pad,
      top: center.dy - r - pad,
      child: IgnorePointer(
        ignoring: widget.drawingActive,
        child: Transform.rotate(
          angle: widget.circle.rotation,
          child: SizedBox(
            width: size + pad * 2,
            height: size + pad * 2,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
        
                // Circle
                Positioned(
                  left: pad,
                  top: pad,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.onSelect,
                    onPanStart: _onBodyPanStart,
                    onPanUpdate: _onBodyPanUpdate,
                    onPanEnd: _onBodyPanEnd,
                    child: SizedBox(
                      key: _bodyKey,
                      width: size,
                      height: size,
                      child: CustomPaint(
                        size: Size(size, size),
                        painter: _CirclePainter(
                          circle: widget.circle,
                          selected: widget.selected,
                        ),
                      ),
                    ),
                  ),
                ),
        
                if (widget.selected) ...[
        
                  // ปุ่มลบ
                  _tapButton(
                    center: Offset(pad + size + 6, pad - 14),
                    icon: Icons.cancel,
                    color: Colors.red,
                    size: 28,
                    onTap: widget.onDelete,
                  ),
        
                  // ปุ่มคัดลอก
                  _tapButton(
                    center: Offset(pad - 14, pad - 14),
                    icon: Icons.copy,
                    color: Colors.blueAccent,
                    size: 26,
                    onTap: widget.onDuplicate,
                  ),
        
                  // จุดจับหมุน
                  _dragHandle(
                    center: Offset(pad + r, pad - 34),
                    icon: Icons.sync,
                    color: Colors.green,
                    onPanStart: _onRotateStart,
                    onPanUpdate: _onRotateUpdate,
                    onPanEnd: _onRotateEnd,
                  ),
        
                  // จุดจับย่อ-ขยาย
                  _dragHandle(
                    center: Offset(pad + size + 6, pad + size + 6),
                    icon: Icons.open_in_full,
                    color: Colors.blueAccent,
                    onPanStart: _onResizeStart,
                    onPanUpdate: _onResizeUpdate,
                    onPanEnd: _onResizeEnd,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CirclePainter extends CustomPainter {
  final ShapeCircle circle;
  final bool selected;

  _CirclePainter({required this.circle, required this.selected});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, size.width / 2, circle.paint);

    if (selected) {
      const padding = 10.0;
      canvas.drawRect(
        Rect.fromLTWH(
            -padding, -padding, size.width + padding * 2, size.height + padding * 2),
        Paint()
          ..color = Colors.blueAccent
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}
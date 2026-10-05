import 'dart:math';
import 'package:flutter/material.dart';

/// ── Icons ──────────────────
class WDraggableIcon extends StatefulWidget {
  final Offset position;
  final String assetPath;
  final double scale;
  final double rotation;
  final bool selected;

  final ValueChanged<Offset> onMove;
  final ValueChanged<double> onScale;
  final ValueChanged<double> onRotate;

  final VoidCallback onSelect;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;
  final VoidCallback? onTransformEnd;

  final double iconSize;

  final bool drawingActive;

  const WDraggableIcon({
    super.key,
    required this.position,
    required this.assetPath,
    required this.scale,
    required this.rotation,
    required this.selected,
    required this.onMove,
    required this.onScale,
    required this.onRotate,
    required this.onSelect,
    required this.onDelete,
    required this.onDuplicate,
    this.onTransformEnd,
    this.iconSize = 40.0,
    this.drawingActive = false,
  });

  @override
  State<WDraggableIcon> createState() => _WDraggableIconState();
}

class _WDraggableIconState extends State<WDraggableIcon> {
  late Offset _position;
  late double _scale;
  late double _rotation;

  final GlobalKey _bodyKey = GlobalKey();

  static const double _pad = 40.0;

  double _startScale = 1.0;
  double _resizeStartDistance = 1.0;
  Offset _resizeCenter = Offset.zero;

  double _startRotation = 0.0;
  double _rotateStartAngle = 0.0;
  Offset _rotateCenter = Offset.zero;

  Offset _rotateOffset(Offset offset, double angle) {
    final cosA = cos(angle);
    final sinA = sin(angle);
    return Offset(
      offset.dx * cosA - offset.dy * sinA,
      offset.dx * sinA + offset.dy * cosA,
    );
  }

  @override
  void initState() {
    super.initState();
    _position = widget.position;
    _scale = widget.scale;
    _rotation = widget.rotation;
  }

  @override
  void didUpdateWidget(covariant WDraggableIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.position != widget.position) _position = widget.position;
    if (oldWidget.scale != widget.scale) _scale = widget.scale;
    if (oldWidget.rotation != widget.rotation) _rotation = widget.rotation;
  }

  Offset _globalCenter() {
    final box = _bodyKey.currentContext!.findRenderObject() as RenderBox;
    return box.localToGlobal(box.size.center(Offset.zero));
  }

  /// ── ย้าย ─────────────────────────────────────────────
  void _onBodyPanStart(DragStartDetails d) => widget.onSelect();

  void _onBodyPanUpdate(DragUpdateDetails d) {
    final worldDelta = _rotateOffset(d.delta, _rotation);
    setState(() => _position += worldDelta);
    widget.onMove(_position);
  }

  void _onBodyPanEnd(DragEndDetails d) => widget.onTransformEnd?.call();

  /// ── ย่อ-ขยาย ─────────────────────────────────────────
  void _onResizeStart(DragStartDetails d) {
    _startScale = _scale;
    _resizeCenter = _globalCenter();
    _resizeStartDistance =
        (d.globalPosition - _resizeCenter).distance.clamp(1.0, double.infinity);
  }

  void _onResizeUpdate(DragUpdateDetails d) {
    final currentDistance = (d.globalPosition - _resizeCenter).distance;
    final factor = (currentDistance / _resizeStartDistance).clamp(0.2, 6.0);
    setState(() {
      _scale = (_startScale * factor).clamp(0.3, 6.0);
    });
    widget.onScale(_scale);
  }

  void _onResizeEnd(DragEndDetails d) => widget.onTransformEnd?.call();

  /// ── หมุน ─────────────────────────────────────────────
  void _onRotateStart(DragStartDetails d) {
    _rotateCenter = _globalCenter();
    _startRotation = _rotation;
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
      _rotation = _startRotation + (currentAngle - _rotateStartAngle);
    });
    widget.onRotate(_rotation);
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
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 4),
            ],
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
            boxShadow: [
              BoxShadow(color: Colors.black26, blurRadius: 4),
            ],
          ),
          child: Icon(icon, color: color, size: size * 0.62),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double displaySize = widget.iconSize * _scale;
    final double half = displaySize / 2;

    // จุดศูนย์กลางคงที่
    final double baseHalf = widget.iconSize / 2;
    final Offset fixedCenter = Offset(
      _position.dx + baseHalf,
      _position.dy + baseHalf,
    );

    return Positioned(
      left: fixedCenter.dx - half - _pad,
      top: fixedCenter.dy - half - _pad,
      child: IgnorePointer(
        ignoring: widget.drawingActive,
        child: Transform.rotate(
          angle: _rotation,
          child: SizedBox(
            width: displaySize + _pad * 2,
            height: displaySize + _pad * 2,
            child: Stack(
              clipBehavior: Clip.none,
              children: [

                // Icon
                Positioned(
                  left: _pad,
                  top: _pad,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.onSelect,
                    onPanStart: _onBodyPanStart,
                    onPanUpdate: _onBodyPanUpdate,
                    onPanEnd: _onBodyPanEnd,
                    child: Container(
                      key: _bodyKey,
                      width: displaySize,
                      height: displaySize,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        border: widget.selected
                            ? Border.all(color: Colors.blueAccent, width: 2)
                            : Border.all(color: Colors.transparent, width: 2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Image.asset(
                        widget.assetPath,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),

                if (widget.selected) ...[

                  // เส้นบาง ๆ
                  IgnorePointer(
                    child: CustomPaint(
                      size: Size(displaySize + _pad * 2, displaySize + _pad * 2),
                      painter: _ConnectorLinePainter(
                        from: Offset(_pad + half, _pad - 19),
                        to: Offset(_pad + half, _pad),
                        color: Colors.green.withOpacity(0.6),
                      ),
                    ),
                  ),

                  // ปุ่มลบ
                  _tapButton(
                    center: Offset(_pad + displaySize + 6, _pad - 14),
                    icon: Icons.cancel,
                    color: Colors.red,
                    size: 28,
                    onTap: widget.onDelete,
                  ),

                  // ปุ่มคัดลอก
                  _tapButton(
                    center: Offset(_pad - 14, _pad - 14),
                    icon: Icons.copy,
                    color: Colors.blueAccent,
                    size: 26,
                    onTap: widget.onDuplicate,
                  ),

                  // จุดจับหมุน
                  _dragHandle(
                    center: Offset(_pad + half, _pad - 34),
                    icon: Icons.sync,
                    color: Colors.green,
                    onPanStart: _onRotateStart,
                    onPanUpdate: _onRotateUpdate,
                    onPanEnd: _onRotateEnd,
                  ),

                  // จุดจับย่อ-ขยาย
                  _dragHandle(
                    center: Offset(_pad + displaySize + 6, _pad + displaySize + 6),
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

/// ── เส้นขอบ ──────────────────
class _ConnectorLinePainter extends CustomPainter {
  final Offset from;
  final Offset to;
  final Color color;

  _ConnectorLinePainter({
    required this.from,
    required this.to,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    canvas.drawLine(from, to, paint);
  }

  @override
  bool shouldRepaint(covariant _ConnectorLinePainter oldDelegate) {
    return oldDelegate.from != from ||
        oldDelegate.to != to ||
        oldDelegate.color != color;
  }
}
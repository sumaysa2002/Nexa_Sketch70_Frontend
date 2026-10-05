import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class WdraggableText extends StatefulWidget {
  final Offset position;
  final String text;
  final ValueChanged<Offset> onMove;
  final ValueChanged<String> onChanged;

  final double scale;
  final ValueChanged<double> onScale;

  final bool selected;
  final VoidCallback onSelect;

  final VoidCallback onDelete;
  final VoidCallback onDuplicate;

  final double rotation;
  final ValueChanged<double> onRotate;

  final VoidCallback? onTransformEnd;

  final VoidCallback onUnselect;

  final bool isBold;
  final ValueChanged<bool> onBoldChanged;

  final bool hasOutline;
  final ValueChanged<bool> onOutlineChanged;

  final Color textColor;
  final ValueChanged<Color> onColorChanged;

  final bool drawingActive;

  final bool autofocusEdit;

  const WdraggableText({
    super.key,
    required this.position,
    required this.text,
    required this.onMove,
    required this.onChanged,
    required this.scale,
    required this.onScale,
    required this.selected,
    required this.onSelect,
    required this.onDelete,
    required this.onDuplicate,
    required this.rotation,
    required this.onRotate,
    required this.onTransformEnd,
    required this.onUnselect,
    required this.isBold,
    required this.onBoldChanged,
    required this.hasOutline,
    required this.onOutlineChanged,
    required this.textColor,
    required this.onColorChanged,
    this.drawingActive = false,
    this.autofocusEdit = false,
  });

  @override
  State<WdraggableText> createState() => _WdraggableTextState();
}

class _WdraggableTextState extends State<WdraggableText> {
  late Offset _position;
  late double _scale;
  late double _rotation;

  late TextEditingController controller;
  bool editing = false;

  final GlobalKey _bodyKey = GlobalKey();

  // ขนาดของกล่องข้อความก่อน layout
  Size _bodySize = const Size(90, 44);

  static const double _pad = 70.0;
  static const double _baseFontSize = 24.0;

  double _startScale = 1.0;
  double _resizeStartDistance = 1.0;
  Offset _resizeCenter = Offset.zero;

  double _startRotation = 0.0;
  double _rotateStartAngle = 0.0;
  Offset _rotateCenter = Offset.zero;

  @override
  void initState() {
    super.initState();
    _position = widget.position;
    _scale = widget.scale;
    _rotation = widget.rotation;
    controller = TextEditingController(text: widget.text);
    editing = widget.autofocusEdit;
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void didUpdateWidget(covariant WdraggableText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) controller.text = widget.text;
    if (oldWidget.position != widget.position) _position = widget.position;
    if (oldWidget.scale != widget.scale) _scale = widget.scale;
    if (oldWidget.rotation != widget.rotation) _rotation = widget.rotation;
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  // ขนาดของกล่องข้อความหลัง layout
  void _measure() {
    final box = _bodyKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize && mounted) {
      final newSize = box.size;
      if (newSize != _bodySize) {
        setState(() => _bodySize = newSize);
      }
    }
  }

  Offset _globalCenter() {
    final box = _bodyKey.currentContext!.findRenderObject() as RenderBox;
    return box.localToGlobal(box.size.center(Offset.zero));
  }

  Offset _rotateOffset(Offset offset, double angle) {
    final cosA = cos(angle);
    final sinA = sin(angle);
    return Offset(
      offset.dx * cosA - offset.dy * sinA,
      offset.dx * sinA + offset.dy * cosA,
    );
  }

  /// ── ย้าย ─────────────────────────────────────────────
  void _onBodyPanStart(DragStartDetails d) {
    if (!widget.selected) widget.onSelect();
  }

  void _onBodyPanUpdate(DragUpdateDetails d) {
    final worldDelta = _rotateOffset(d.delta, _rotation);
    setState(() => _position += worldDelta);
    widget.onMove(_position);
  }

  void _onBodyPanEnd(DragEndDetails d) => widget.onTransformEnd?.call();

  void _onTap() {
    if (widget.selected) {
      setState(() => editing = true);
    } else {
      widget.onSelect();
    }
  }

  /// ── ย่อ-ขยาย ─────────────────────────────────────────
  void _onResizeStart(DragStartDetails d) {
    _startScale = _scale;
    _resizeCenter = _globalCenter();
    _resizeStartDistance =
        (d.globalPosition - _resizeCenter).distance.clamp(1.0, double.infinity);
  }

  void _onResizeUpdate(DragUpdateDetails d) {
    final currentDistance = (d.globalPosition - _resizeCenter).distance;
    final factor = (currentDistance / _resizeStartDistance).clamp(0.3, 6.0);
    setState(() {
      _scale = (_startScale * factor).clamp(0.5, 6.0);
    });
    widget.onScale(_scale);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
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

  void _finishEdit() {
    setState(() => editing = false);
    widget.onChanged(controller.text);
    widget.onUnselect();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

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

  Widget _buildStrokeText(String content, TextStyle baseStyle) {
    if (!widget.hasOutline) return Text(content, style: baseStyle);
    return Stack(
      children: [
        Text(
          content,
          style: baseStyle.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 6
              ..color = Colors.white,
          ),
        ),
        Text(content, style: baseStyle),
      ],
    );
  }

  Widget _buildText(double fontSize) {
    final textContent = widget.text.isEmpty ? 'พิมพ์ข้อความ' : widget.text;
    final baseStyle = TextStyle(
      fontSize: fontSize,
      color: widget.textColor,
      fontFamily: 'THSarabun',
      fontWeight: widget.isBold ? FontWeight.w900 : FontWeight.w700,
    );
    return _buildStrokeText(textContent, baseStyle);
  }

  Widget _buildEditor(double fontSize) {
    return IntrinsicWidth(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: TextField(
          controller: controller,
          autofocus: true,
          maxLines: null,
          decoration: const InputDecoration(isDense: true, border: InputBorder.none),
          style: TextStyle(
            fontSize: fontSize,
            color: Colors.black,
            fontFamily: 'THSarabun',
            fontWeight: widget.isBold ? FontWeight.w900 : FontWeight.w700,
          ),
          onEditingComplete: _finishEdit,
          onTapOutside: (_) => _finishEdit(),
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [

            // เลือกสีตัวอักษร
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () async {
                final picked = await showDialog<Color>(
                  context: context,
                  barrierDismissible: false,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: const Text(
                      'Color Chooser',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.black,
                        fontFamily: 'InstrumentSans',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    content: SizedBox(
                      height: 300,
                      child: BlockPicker(
                        pickerColor: widget.textColor,
                        onColorChanged: (c) => Navigator.pop(ctx, c),
                      ),
                    ),
                  ),
                );
                if (picked != null) widget.onColorChanged(picked);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Container(
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                    color: widget.textColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ),

            // ตัวอักษรหนา
            _toolbarButton(
              icon: Icons.format_bold,
              active: widget.isBold,
              onTap: () => widget.onBoldChanged(!widget.isBold),
            ),

            // ขอบตัวอักษร
            _toolbarButton(
              icon: Icons.text_fields_outlined,
              active: widget.hasOutline,
              onTap: () => widget.onOutlineChanged(!widget.hasOutline),
            ),

            // คัดลอกตัวอักษร
            _toolbarButton(icon: Icons.copy, onTap: widget.onDuplicate),

            // ลบตัวอักษร
            _toolbarButton(icon: Icons.delete_outline, onTap: widget.onDelete),
          ],
        ),
      ),
    );
  }

  Widget _toolbarButton({
    required IconData icon,
    required VoidCallback onTap,
    bool active = false,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Icon(icon, size: 20, color: active ? Colors.yellow : Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double fontSize = (_baseFontSize * _scale).clamp(10.0, 160.0);
    final double w = _bodySize.width;
    final double h = _bodySize.height;

    const double toolbarHeight = 34;
    const double toolbarGap = 6;
    final double toolbarTop = _pad - toolbarGap - toolbarHeight;

    return Positioned(
      left: _position.dx - _pad,
      top: _position.dy - _pad,
      child: IgnorePointer(
        ignoring: widget.drawingActive,
        child: Transform.rotate(
          angle: _rotation,
          child: SizedBox(
            width: w + _pad * 2,
            height: h + _pad * 2,
            child: Stack(
              clipBehavior: Clip.none,
              children: [

                // Text
                Positioned(
                  left: _pad,
                  top: _pad,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: editing ? null : _onTap,
                    onPanStart: editing ? null : _onBodyPanStart,
                    onPanUpdate: editing ? null : _onBodyPanUpdate,
                    onPanEnd: editing ? null : _onBodyPanEnd,
                    child: Container(
                      key: _bodyKey,
                      constraints: const BoxConstraints(minWidth: 200, minHeight: 44),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: (widget.selected || editing)
                            ? Border.all(color: Colors.blueAccent, width: 2)
                            : Border.all(color: Colors.transparent, width: 2),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: editing ? _buildEditor(fontSize) : _buildText(fontSize),
                    ),
                  ),
                ),

                if (widget.selected && !editing) ...[

                  // เส้นบาง ๆ
                  IgnorePointer(
                    child: CustomPaint(
                      size: Size(w + _pad * 2, h + _pad * 2),
                      painter: _ConnectorLinePainter(
                        from: Offset(_pad + w / 2, _pad - toolbarGap - toolbarHeight - 24),
                        to: Offset(_pad + w / 2, _pad),
                        color: Colors.green.withOpacity(0.5),
                      ),
                    ),
                  ),

                  // Toolbar
                  Positioned(
                    left: _pad,
                    right: _pad,
                    top: toolbarTop,
                    height: toolbarHeight,
                    child: _buildToolbar(),
                  ),

                  // จุดจับหมุน
                  _dragHandle(
                    center: Offset(_pad + w / 2, toolbarTop - 24),
                    icon: Icons.sync,
                    color: Colors.green,
                    onPanStart: _onRotateStart,
                    onPanUpdate: _onRotateUpdate,
                    onPanEnd: _onRotateEnd,
                  ),

                  // จุดจับย่อ-ขยาย
                  _dragHandle(
                    center: Offset(_pad + w + 6, _pad + h + 6),
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

class _ConnectorLinePainter extends CustomPainter {
  final Offset from;
  final Offset to;
  final Color color;

  _ConnectorLinePainter({required this.from, required this.to, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(from, to, Paint()..color = color..strokeWidth = 1);
  }

  @override
  bool shouldRepaint(covariant _ConnectorLinePainter oldDelegate) =>
      oldDelegate.from != from || oldDelegate.to != to || oldDelegate.color != color;
}

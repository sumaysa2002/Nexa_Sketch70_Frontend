import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/gestures.dart';
import 'package:offline_gnss69_new/export.dart';


class Signature_Page extends StatefulWidget {

  static MaterialPageRoute<Uint8List?> route() => MaterialPageRoute<Uint8List?>(
    builder: (context) => const Signature_Page(),
  );

  const Signature_Page({super.key});

  @override
  State<Signature_Page> createState() => _Signature_PageState();
}

/// เส้น
class _SigStroke {
  final List<Offset> points;
  final double width;
  _SigStroke(this.points, this.width);
}

class _Signature_PageState extends State<Signature_Page> {

  /// เส้นที่แสดงอยู่บนกระดาษ
  List<_SigStroke> _strokes = [];

  /// เส้นที่กำลังวาด
  _SigStroke? _current;

  /// History
  final List<List<_SigStroke>> _history = [[]];
  int _historyIndex = 0;

  /// โหมดปากกา
  bool _stylusOnlyMode = true;
  bool _fingerHintShown = false;

  /// ความหนาเส้น
  double _strokeWidth = 8.0;
  static const double _minStroke = 0.5;
  static const double _maxStroke = 10.0;

  static const Color _inkColor = Colors.black;

  int?  _activePointer;
  Size  _padSize = Size.zero;
  bool  _saving  = false;

  /// ขนาดรูปที่ส่งออก
  static const int    _outW      = 1000;
  static const int    _outH      = 500;
  static const double _outMargin = 30.0;

  bool get _hasInk  => _strokes.isNotEmpty;
  bool get _canUndo => _historyIndex > 0;
  bool get _canRedo => _historyIndex < _history.length - 1;


  /// ── History ───────────────────────────────────────────────
  void _pushHistorySnapshot() {
    // ตัด redo ที่ค้างอยู่ทิ้ง เมื่อมีการวาดใหม่
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }
    _history.add(List.of(_strokes));
    _historyIndex = _history.length - 1;
  }

  void _undo() {
    if (!_canUndo) return;
    setState(() {
      _historyIndex--;
      _strokes = List.of(_history[_historyIndex]);
    });
  }

  void _redo() {
    if (!_canRedo) return;
    setState(() {
      _historyIndex++;
      _strokes = List.of(_history[_historyIndex]);
    });
  }

  void _clearAll() {
    if (!_hasInk) return;
    setState(() {
      _strokes = [];
      _pushHistorySnapshot();
    });
  }


  /// ── การแตะ / ลาก ─────────────────────────────────────────
  Offset _clamp(Offset p) => Offset(
    p.dx.clamp(0.0, _padSize.width),
    p.dy.clamp(0.0, _padSize.height),
  );

  bool _acceptKind(PointerDeviceKind kind) {
    if (kind == PointerDeviceKind.invertedStylus) return false;
    if (_stylusOnlyMode) return kind == PointerDeviceKind.stylus;
    return true;
  }

  void _onPointerDown(PointerDownEvent e) {
    if (_activePointer != null) return;

    if (!_acceptKind(e.kind)) {
      // ใช้นิ้วแตะขณะเปิดโหมดปากกา >> แจ้งครั้งเดียว
      if (_stylusOnlyMode && e.kind == PointerDeviceKind.touch && !_fingerHintShown) {
        _fingerHintShown = true;
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(const SnackBar(
            content: Text('กรุณาวาดด้วยปากกา',
              style: TextStyle(
                fontFamily: 'NotoSansThai',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ));
      }
      return;
    }

    _activePointer = e.pointer;
    setState(() {
      _current = _SigStroke([_clamp(e.localPosition)], _strokeWidth);
      _strokes.add(_current!);
    });
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (e.pointer != _activePointer || _current == null) return;
    final p = _clamp(e.localPosition);
    if ((p - _current!.points.last).distance < 1.0) return;
    setState(() => _current!.points.add(p));
  }

  void _onPointerEnd(PointerEvent e) {
    if (e.pointer != _activePointer) return;
    _activePointer = null;
    _current = null;
    setState(_pushHistorySnapshot);
  }


  /// ── Render เส้นเป็น PNG ─────────────────────────────────────
  Future<Uint8List?> _exportPng() async {
    if (!_hasInk || _padSize.isEmpty) return null;

    double minX = double.infinity, minY = double.infinity;
    double maxX = -double.infinity, maxY = -double.infinity;
    double maxW = 0;
    for (final s in _strokes) {
      maxW = math.max(maxW, s.width);
      for (final p in s.points) {
        minX = math.min(minX, p.dx);
        minY = math.min(minY, p.dy);
        maxX = math.max(maxX, p.dx);
        maxY = math.max(maxY, p.dy);
      }
    }
    final bounds = Rect.fromLTRB(minX, minY, maxX, maxY).inflate(maxW);

    // scale ปกติ
    final baseScale = _outW / _padSize.width;
    final fitScale  = math.min(
      (_outW - _outMargin * 2) / bounds.width,
      (_outH - _outMargin * 2) / bounds.height,
    );
    final scale = math.min(fitScale, baseScale * 2.5);

    final recorder = ui.PictureRecorder();
    final canvas   = Canvas(recorder, Rect.fromLTWH(0, 0, _outW.toDouble(), _outH.toDouble()));

    canvas.translate(
      (_outW - bounds.width  * scale) / 2 - bounds.left * scale,
      (_outH - bounds.height * scale) / 2 - bounds.top  * scale,
    );
    canvas.scale(scale);

    // ความหนาเส้นในรูป
    _SignaturePainter.paintStrokes(
      canvas, _strokes,
      color: _inkColor,
      widthFactor: baseScale / scale,
    );

    final picture = recorder.endRecording();
    final image   = await picture.toImage(_outW, _outH);
    final data    = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    picture.dispose();

    return data?.buffer.asUint8List();
  }

  Future<void> _save() async {
    if (!_hasInk || _saving) return;
    setState(() => _saving = true);
    try {
      final bytes = await _exportPng();
      if (!mounted) return;
      Navigator.pop(context, bytes);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(
          content: Text('บันทึกลายเซ็นไม่สำเร็จ กรุณาลองใหม่อีกครั้ง',
            style: TextStyle(
              fontFamily: 'NotoSansThai',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ));
    }
  }


  /// ── ยืนยันก่อนออกจากหน้า ──────────────────
  Future<void> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => alert_image_two_button(
        text: "ยกเลิกการบันทึกลายเซ็น",
        assets_image: "assets/images/question.png",
        one_text_button: "ยกเลิก",
        one_onPressed: () => Navigator.pop(ctx, false),
        two_text_button: "ตกลง",
        two_onPressed: () => Navigator.pop(ctx, true),
      ),
    );
    if (discard == true && mounted) Navigator.pop(context);
  }


  /// ── เส้นแบ่งในแถบเครื่องมือ ─────────────────────────────────
  Widget _divider() => SizedBox(
    height: 50,
    child: VerticalDivider(width: 16, thickness: 1, color: Colors.grey.shade400),
  );


  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasInk || _saving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmDiscard();
      },
      child: Scaffold(
        body: Stack(
          children: [

            /// พื้นหลังขาว
            const ColoredBox(color: Colors.white, child: SizedBox.expand()),

            SafeArea(
              child: Column(
                children: [

                  /// Bar
                  SizedBox(
                    height: kToolbarHeight,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                              Icons.arrow_back_ios_new_outlined,
                              color: Color(0xFF18181C)
                          ),
                          onPressed: () => Navigator.maybePop(context),
                        ),
                        const Expanded(
                          child: Center(
                            child: w_text_thai_notosansthai(
                              name: 'ลายเซ็น',
                              font_Size: 24,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF18181C),
                            ),
                          ),
                        ),
                        const SizedBox(width: 48), // balance icon
                      ],
                    ),
                  ),

                  /// ── กระดาษเซ็น (2:1) ──────────────────────────
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 900),
                          child: AspectRatio(
                            aspectRatio: 2,
                            child: Container(
                              // พื้นหลังเป็นสีขาว จึงใช้กรอบเส้นแทนเงาเพื่อแยกกระดาษ
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: const BorderRadius.all(Radius.circular(10.0)),
                                border: Border.all(color: Colors.grey.shade500, width: 1.6),
                              ),
                              child: ClipRRect(
                                borderRadius: const BorderRadius.all(Radius.circular(10.0)),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    _padSize = constraints.biggest;
                                    return Listener(
                                      behavior: HitTestBehavior.opaque,
                                      onPointerDown:   _onPointerDown,
                                      onPointerMove:   _onPointerMove,
                                      onPointerUp:     _onPointerEnd,
                                      onPointerCancel: _onPointerEnd,
                                      child: CustomPaint(
                                        size: _padSize,
                                        painter: _SignaturePainter(
                                          strokes: _strokes,
                                          color: _inkColor,
                                          showGuide: true,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  /// ── แถบเครื่องมือด้านล่าง ───────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 700),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.all(Radius.circular(16.0)),
                        border: Border.all(color: Colors.grey.shade500),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [

                            // Pen mode
                            DrawToolButton(
                              icon: Icons.edit,
                              label: 'วาดด้วยปากกา',
                              selected: _stylusOnlyMode,
                              onPressed: () {
                                setState(() => _stylusOnlyMode = !_stylusOnlyMode);
                              },
                            ),

                            const SizedBox(width: 5),
                            _divider(),
                            const SizedBox(width: 5),

                            // ความหนาเส้น
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 25,
                                      child: Text(
                                        _strokeWidth.toStringAsFixed(1),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 150,
                                      child: Slider(
                                        min: _minStroke,
                                        max: _maxStroke,
                                        activeColor: _inkColor,
                                        value: _strokeWidth,
                                        onChanged: (v) => setState(() => _strokeWidth = v),
                                      ),
                                    ),
                                    // ตัวอย่างความหนาเส้น
                                    SizedBox(
                                      width: 24,
                                      child: Center(
                                        child: Container(
                                          width: _strokeWidth.clamp(2.0, 20.0),
                                          height: _strokeWidth.clamp(2.0, 20.0),
                                          decoration: const BoxDecoration(
                                            color: _inkColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Text(
                                  'ความหนา',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                    fontFamily: 'NotoSansThai',
                                  ),
                                ),
                              ],
                            ),

                            _divider(),
                            const SizedBox(width: 5),

                            // Undo
                            DrawToolButton(
                              icon: Icons.keyboard_arrow_left,
                              label: 'ย้อนกลับ',
                              selected: false,
                              enabled: _canUndo,
                              onPressed: _undo,
                            ),

                            const SizedBox(width: 5),

                            // Redo
                            DrawToolButton(
                              icon: Icons.keyboard_arrow_right,
                              label: 'ทำซ้ำ',
                              selected: false,
                              enabled: _canRedo,
                              onPressed: _redo,
                            ),

                            const SizedBox(width: 5),

                            // Clear
                            DrawToolButton(
                              icon: Icons.delete,
                              label: 'ลบทั้งหมด',
                              selected: false,
                              enabled: _hasInk,
                              onPressed: _clearAll,
                            ),

                            const SizedBox(width: 5),

                            // Save
                            DrawToolButton(
                              icon: Icons.save_rounded,
                              label: 'Save',
                              selected: false,
                              enabled: _hasInk && !_saving,
                              onPressed: _save,
                            ),

                          ],
                        ),
                      ),
                    ),
                  ),

                ],
              ),
            ),

            // กำลังบันทึก
            if (_saving)
              const Positioned.fill(
                child: ColoredBox(
                  color: Colors.black38,
                  child: Center(child: CircularProgressIndicator(color: Colors.white)),
                ),
              ),

          ],
        ),
      ),
    );
  }
}


/// ── วาดเส้นลายเซ็น ───────────────────
class _SignaturePainter extends CustomPainter {

  final List<_SigStroke> strokes;
  final Color color;
  final bool showGuide;

  _SignaturePainter({
    required this.strokes,
    required this.color,
    this.showGuide = false,
  });

  /// เส้นนำสายตา
  void _paintGuide(Canvas canvas, Size size) {
    final y = size.height * 0.72;
    final guide = Paint()
      ..color = Colors.black26
      ..strokeWidth = 1;
    canvas.drawLine(Offset(size.width * 0.08, y), Offset(size.width * 0.92, y), guide);

    final tp = TextPainter(
      text: const TextSpan(text: '×', style: TextStyle(fontSize: 20, color: Colors.black38)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(size.width * 0.08, y - tp.height - 2));
  }

  /// วาดเส้นแบบโค้งเรียบ
  static void paintStrokes(
      Canvas canvas,
      List<_SigStroke> strokes, {
        required Color color,
        double widthFactor = 1.0,
      }) {
    for (final s in strokes) {
      final pts = s.points;
      if (pts.isEmpty) continue;
      final w = s.width * widthFactor;

      // แตะครั้งเดียว >> วาดเป็นจุด
      if (pts.length == 1) {
        canvas.drawCircle(pts.first, w / 2, Paint()..color = color..isAntiAlias = true);
        continue;
      }

      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      if (pts.length == 2) {
        path.lineTo(pts.last.dx, pts.last.dy);
      } else {
        for (int i = 1; i < pts.length - 1; i++) {
          final mid = Offset(
            (pts[i].dx + pts[i + 1].dx) / 2,
            (pts[i].dy + pts[i + 1].dy) / 2,
          );
          path.quadraticBezierTo(pts[i].dx, pts[i].dy, mid.dx, mid.dy);
        }
        path.lineTo(pts.last.dx, pts.last.dy);
      }

      canvas.drawPath(path, Paint()
        ..color = color
        ..strokeWidth = w
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (showGuide) _paintGuide(canvas, size);
    paintStrokes(canvas, strokes, color: color);
  }
  
  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
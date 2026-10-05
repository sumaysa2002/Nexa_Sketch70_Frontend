import 'dart:ui';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:offline_gnss69_new/export.dart';
import 'package:offline_gnss69_new/features/widgets/draw/shape_curve.dart';
import 'package:offline_gnss69_new/features/widgets/draw/draggable_curve.dart';


class Draw_CreateNewPoint extends StatefulWidget {

  final ProjectModel project;
  final String boxName;

  final Uint8List? zoomInBytes;
  final Uint8List? zoomOutBytes;

  final String? pointName;

  static MaterialPageRoute route(
      ProjectModel project, {
        String boxName = 'drawings_field',
        Uint8List? zoomInBytes,
        Uint8List? zoomOutBytes,
        String? pointName,
      }) => MaterialPageRoute(
    builder: (context) => Draw_CreateNewPoint(
      project: project,
      boxName: boxName,
      zoomInBytes:  zoomInBytes,
      zoomOutBytes: zoomOutBytes,
      pointName: pointName,
    ),
  );

  const Draw_CreateNewPoint({
    super.key,
    required this.project,
    this.boxName = 'drawings_field',
    this.zoomInBytes,
    this.zoomOutBytes,
    this.pointName,
  });

  @override
  State<Draw_CreateNewPoint> createState() => _Draw_CreateNewPointState();
}

class _Draw_CreateNewPointState extends State<Draw_CreateNewPoint> {

  List <DrawingArea?> points = <DrawingArea?>[];
  late Color selectedColor;
  late double strokeWidth;
  late double eraserWidth = 20.0;

  final List<CanvasState> history = [];
  int historyIndex = -1;

  // โหมดวาด
  bool isDrawing = false;

  // เพิ่มค่าคงที่โหมดเลือก
  static const int kToolTypeSelect = 5;

  // เส้น / สถานะการวาด
  String drawMode = "free";
  Offset? lineStart;
  Offset? previewEnd;

  // เส้นประ
  final GlobalKey _dashKey = GlobalKey();
  LineStyle currentLineStyle = LineStyle.solid;

  // เส้นโค้ง
  final List<ShapeCurve> curves = [];
  Offset? curveStart;
  Offset? curveEnd;

  // เส้นโค้ง ประ
  final GlobalKey _curveDashKey = GlobalKey();

  // วงกลม
  final List <ShapeCircle> circles = [];
  Offset? circleStart;
  Offset? circleCurrent;

  // triangle and square
  final List <Shape> shapes = [];
  Offset? shapeStart;
  Offset? shapeCurrent;

  // วงกลม สามเหลี่ยม สี่เหลี่ยม เส้นโค้ง ขยับ/เลือก
  int? _selectedShapeIndex;
  int? _selectedCircleIndex;
  int? _selectedCurveIndex;

  // สถานะ Drawing
  static const int kToolTypeNone = 0;
  static const int kToolTypePen = 1;
  static const int kToolTypeEraser = 4;

  int selectedTool = kToolTypeNone;

  // เก็บค่า Paint ของเส้นที่กำลังวาด
  Paint? linePaintInProgress;

  // POPUP Icon
  final GlobalKey _emojiKey = GlobalKey();
  final GlobalKey _drawIconKey = GlobalKey();
  String? selectedIcon;
  int? _selectedIconIndex;
  final List <OverLayedWidget> _addedWidgets = [];

  List<Map<String, dynamic>> _widgetsData = [];

  // layer
  bool isLayerMenuOpen = false;

  // CheckBox
  bool azimuthLayer = false;
  bool satellite_in = false;
  bool satellite_out = false;
  bool triangle_layer = false;
  bool triangle_line_layer = false;
  bool cross_layer = false;
  bool pointNameLayer = false;

  // scale และ offset ของ satelliteช
  double _satInScale  = 1.0;
  double _satOutScale = 1.0;
  Offset _satInOffset  = Offset.zero;
  Offset _satOutOffset = Offset.zero;

  // โหมดปรับ satellite
  bool _satelliteAdjustMode = false;

  // เลือกว่ากำลังปรับตัวไหน: 'in' | 'out'
  String _adjustTarget = 'in';

  // Export
  final GlobalKey repaintKey = GlobalKey();

  final ValueNotifier<ui.Image?> backgroundImage =
  ValueNotifier<ui.Image?>(null);

  // Save
  late Box<SavedDrawing> drawingBox;

  // Text
  List<Map<String, dynamic>> texts = [];
  int? _newTextIndex;

  SavedDrawing? savedDrawing;

  // ใช้ปากกาหรือมือ
  bool _stylusOnlyMode = true;

  // zoom เข้า - ออก กระดาษ
  final TransformationController _transformationController = TransformationController();

  // เพิ่มตัวแปรนับจำนวนนิ้ว
  int _pointerCount = 0;


  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }


  @override
  void initState() {
    super.initState();
    selectedColor = Colors.black;
    strokeWidth = 2.0;
    eraserWidth = 20.0;
    _pushHistorySnapshot();

    backgroundImage.value = null;

    drawingBox = Hive.box<SavedDrawing>(widget.boxName);

  }


  /// ── StrokeModel ────────────────────────────────
  List<Map<String, dynamic>> serializePoints() {
    return points.map((p) {
      if (p == null) return {'break' : true};
      return StrokeModel(
        x: p.point.dx,
        y: p.point.dy,
        color: p.areaPaint.color.value,
        strokeWidth: p.areaPaint.strokeWidth,
        isEraser: p.areaPaint.blendMode == BlendMode.clear,
        lineStyle: p.lineStyle?.index,
      ).toMap();
    }).toList();
  }

  bool _restoredOnce = false;


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if( _restoredOnce) return;

    if (savedDrawing == null) {
      final args = ModalRoute.of(context)?.settings.arguments as SavedDrawing?;

      if (args != null) {
        savedDrawing = args;

        // ตรวจข้อมูลทุกอย่าง เพื่อ save แล้วกลับมาแก้ได้
        final bool hasSavedData = args.strokes.isNotEmpty ||
            (args.texts?.isNotEmpty ?? false) ||
            (args.widgetsData?.isNotEmpty ?? false) ||
            (args.circles?.isNotEmpty ?? false) ||
            (args.shapes?.isNotEmpty ?? false) ||
            (args.curves?.isNotEmpty ?? false) ||
            args.backgroundImageData != null;

        if (hasSavedData) {
          restoreAllData(args);
        } else {
          _loadSavedImage(args.imageBytes);
          _pushHistorySnapshot();
        }
      }
    }
    _restoredOnce = true;
  }


  /// ── Undo and Redo ────────────────────────────────
  void _pushHistorySnapshot() {
    if (historyIndex < history.length - 1) {
      history.removeRange(historyIndex + 1, history.length);
    }
    history.add(
      CanvasState(
        backgroundImage: backgroundImage.value,
        points: List<DrawingArea?>.from(points),
        widgets: List<OverLayedWidget>.from(_addedWidgets),

        widgetsData: List<Map<String, dynamic>>.from(
            _widgetsData.map((e) => Map<String, dynamic>.from(e))
        ),

        texts: List<Map<String, dynamic>>.from(
          texts.map((e) => Map<String, dynamic>.from(e)),
        ),

        circles: circles.map((c) => c.copyWith()).toList(),
        shapes: shapes.map((s) => s.copyWith()).toList(),
        curves: curves.map((c) => c.copyWith()).toList(),
      ),
    );
    historyIndex = history.length - 1;

    const int maxHistory = 100;
    if (history.length > maxHistory) {
      history.removeRange(0, history.length - maxHistory);
      historyIndex = history.length - 1;
    }
  }

  void _undo() {
    if (historyIndex > 0) {
      historyIndex--;
      final state = history[historyIndex];
      setState(() {
        points = List<DrawingArea?>.from(state.points);
        _addedWidgets
          ..clear()
          ..addAll(state.widgets);

        _widgetsData = List<Map<String, dynamic>>.from(state.widgetsData);

        texts
          ..clear()
          ..addAll(state.texts);
        shapes
          ..clear()
          ..addAll(state.shapes);
        circles
          ..clear()
          ..addAll(state.circles);
        curves
          ..clear()
          ..addAll(state.curves);
        backgroundImage.value = state.backgroundImage;
      });
    }
  }

  void _redo() {
    if (historyIndex < history.length - 1) {
      historyIndex++;
      final state = history[historyIndex];
      setState(() {
        points = List<DrawingArea?>.from(state.points);
        _addedWidgets
          ..clear()
          ..addAll(state.widgets);

        _widgetsData = List<Map<String, dynamic>>.from(state.widgetsData);

        texts
          ..clear()
          ..addAll(state.texts);
        shapes
          ..clear()
          ..addAll(state.shapes);
        circles
          ..clear()
          ..addAll(state.circles);
        curves
          ..clear()
          ..addAll(state.curves);
        backgroundImage.value = state.backgroundImage;
      });
    }
  }


  /// ── ให้รับค่าจากปากกา ────────────────────────────────
  // void _handlePointerDown(Offset localPosition) {
  //   if (!isDrawing) return;
  //
  //   FocusScope.of(context).unfocus();
  //   setState(() {
  //     for (var t in texts) t['selected'] = false;
  //   });
  //
  //   if (selectedTool == kToolTypeEraser) {
  //
  //   }
  //   if (drawMode == "free") {
  //     setState(() {
  //       points.add(DrawingArea(
  //         point: localPosition,
  //         lineStyle: currentLineStyle,
  //         areaPaint: Paint()
  //           ..style = PaintingStyle.stroke
  //           ..strokeCap = StrokeCap.round
  //           ..isAntiAlias = true
  //           ..strokeWidth = selectedTool == kToolTypeEraser ? eraserWidth : strokeWidth
  //           ..color = selectedTool == kToolTypeEraser ? Colors.transparent : selectedColor
  //           ..blendMode = selectedTool == kToolTypeEraser ? BlendMode.clear : BlendMode.srcOver,
  //       ));
  //     });
  //   } else if (drawMode == "line") {
  //     setState(() {
  //       lineStart = localPosition;
  //       previewEnd = lineStart;
  //       linePaintInProgress = Paint()
  //         ..style = PaintingStyle.stroke
  //         ..strokeCap = StrokeCap.round
  //         ..isAntiAlias = true
  //         ..color = selectedColor
  //         ..strokeWidth = strokeWidth
  //         ..blendMode = BlendMode.srcOver;
  //     });
  //   } else if (drawMode == "circle") {
  //     setState(() {
  //       circleStart = localPosition;
  //       circleCurrent = localPosition;
  //     });
  //   } else if (drawMode == "square" || drawMode == "triangle") {
  //     setState(() {
  //       shapeStart = localPosition;
  //       shapeCurrent = localPosition;
  //     });
  //   } else if (drawMode == "curve") {
  //     setState(() {
  //       curveStart = localPosition;
  //       curveEnd = localPosition;
  //     });
  //   }
  // }
  //
  // void _handlePointerMove(Offset localPosition) {
  //   if (!isDrawing) return;
  //   if (drawMode == "free") {
  //     setState(() {
  //       points.add(DrawingArea(
  //         point: localPosition,
  //         lineStyle: currentLineStyle,
  //         areaPaint: Paint()
  //           ..style = PaintingStyle.stroke
  //           ..strokeCap = StrokeCap.round
  //           ..isAntiAlias = true
  //           ..strokeWidth = selectedTool == kToolTypeEraser ? eraserWidth : strokeWidth
  //           ..color = selectedTool == kToolTypeEraser ? Colors.transparent : selectedColor
  //           ..blendMode = selectedTool == kToolTypeEraser ? BlendMode.clear : BlendMode.srcOver,
  //       ));
  //     });
  //   } else if (drawMode == "line") {
  //     setState(() => previewEnd = localPosition);
  //   } else if (drawMode == "circle") {
  //     setState(() => circleCurrent = localPosition);
  //   } else if (drawMode == "square" || drawMode == "triangle") {
  //     setState(() => shapeCurrent = localPosition);
  //   } else if (drawMode == "curve") {
  //     setState(() => curveEnd = localPosition);
  //   }
  // }
  //
  // void _handlePointerUp() {
  //   if (!isDrawing) return;
  //   if (drawMode == "free") {
  //     setState(() {
  //       points.add(null);
  //       _pushHistorySnapshot();
  //     });
  //   } else if (drawMode == "line") {
  //     if (lineStart != null && previewEnd != null && linePaintInProgress != null) {
  //       setState(() {
  //         points.add(DrawingArea(point: lineStart!, areaPaint: linePaintInProgress!, lineStyle: currentLineStyle));
  //         points.add(DrawingArea(point: previewEnd!, areaPaint: linePaintInProgress!, lineStyle: currentLineStyle));
  //         points.add(null);
  //         _pushHistorySnapshot();
  //         lineStart = null;
  //         previewEnd = null;
  //         linePaintInProgress = null;
  //       });
  //     }
  //   } else if (drawMode == "circle") {
  //     if (circleStart != null && circleCurrent != null) {
  //       setState(() {
  //         final center = Offset(
  //           (circleStart!.dx + circleCurrent!.dx) / 2,
  //           (circleStart!.dy + circleCurrent!.dy) / 2,
  //         );
  //         final radius = (circleStart! - circleCurrent!).distance / 2;
  //         circles.add(ShapeCircle(
  //           center: center,
  //           radius: radius,
  //           paint: Paint()
  //             ..color = selectedColor
  //             ..strokeWidth = strokeWidth
  //             ..style = PaintingStyle.stroke
  //             ..isAntiAlias = true,
  //         ));
  //         _pushHistorySnapshot();
  //         circleStart = null;
  //         circleCurrent = null;
  //
  //         isDrawing = false;
  //         selectedTool = kToolTypeNone;
  //         drawMode = "";
  //       });
  //     }
  //   } else if (drawMode == "square" || drawMode == "triangle") {
  //     if (shapeStart != null && shapeCurrent != null) {
  //       setState(() {
  //         final center = Offset(
  //           (shapeStart!.dx + shapeCurrent!.dx) / 2,
  //           (shapeStart!.dy + shapeCurrent!.dy) / 2,
  //         );
  //         shapes.add(Shape(
  //           type: drawMode == "square" ? Wshape.square : Wshape.triangle,
  //           center: center,
  //           width: (shapeCurrent!.dx - shapeStart!.dx).abs(),
  //           height: (shapeCurrent!.dy - shapeStart!.dy).abs(),
  //           paint: Paint()
  //             ..color = selectedColor
  //             ..strokeWidth = strokeWidth
  //             ..style = PaintingStyle.stroke
  //             ..isAntiAlias = true,
  //         ));
  //         _pushHistorySnapshot();
  //
  //         isDrawing = false;
  //         selectedTool = kToolTypeNone;
  //         drawMode = "";
  //       });
  //     }
  //     setState(() {
  //       shapeStart = null;
  //       shapeCurrent = null;
  //     });
  //   } else if (drawMode == "curve") {
  //     if (curveStart != null && curveEnd != null &&
  //         (curveStart! - curveEnd!).distance > 8) {
  //       setState(() {
  //         final mid = Offset.lerp(curveStart!, curveEnd!, 0.5)!;
  //         curves.add(ShapeCurve(
  //           points: [curveStart!, mid, curveEnd!],
  //           lineStyle: currentLineStyle,
  //           paint: Paint()
  //             ..color = selectedColor
  //             ..strokeWidth = strokeWidth
  //             ..strokeCap = StrokeCap.round
  //             ..style = PaintingStyle.stroke
  //             ..isAntiAlias = true,
  //         ));
  //         _pushHistorySnapshot();
  //
  //         isDrawing = false;
  //         selectedTool = kToolTypeNone;
  //         drawMode = "";
  //       });
  //     }
  //     setState(() {
  //       curveStart = null;
  //       curveEnd = null;
  //     });
  //   }
  // }


  void _clearAllSelections() {
    setState(() {
      for (var t in texts) t['selected'] = false;
      _selectedShapeIndex = null;
      _selectedCircleIndex = null;
      _selectedCurveIndex = null;
      _selectedIconIndex = null;
    });
  }

  /// ── จานสี ────────────────────────────────
  void selectColor() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Center(
            child: Text(
              'Color Chooser',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                color: Colors.black,
                fontFamily: 'InstrumentSans',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          content: SizedBox(
            height: 380,
            child: BlockPicker(
              pickerColor: selectedColor,
              onColorChanged: (color) {
                setState(() {
                  selectedColor = color;
                });
              },
            ),
          ),
          actionsPadding: const EdgeInsets.only(
            top: 0,
            left: 8,
            right: 8,
            bottom: 8,
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text(
                  "Close",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontFamily: 'InstrumentSans',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }


  /// ── เส้น ────────────────────────────────
  void setDrawMode(String mode) {
    setState(() {
      drawMode = mode;
      isDrawing = true;
      selectedTool = kToolTypePen;

      if (mode == "line" || mode == "curve") {
        currentLineStyle = LineStyle.solid;
      }

      // Reset ค่าตำแหน่งชั่วคราว
      lineStart = null;
      previewEnd = null;
      circleStart = null;
      circleCurrent = null;
      shapeStart = null;
      shapeCurrent = null;
      curveStart = null;
      curveEnd = null;
    });
  }


  /// ── ปิดเครื่องมือวาดทั้งหมด ────────────────────────────────
  void _turnOffDrawTool() {
    setState(() {
      selectedTool = kToolTypeNone;
      drawMode = "";
      isDrawing = false;
      lineStart = null;
      previewEnd = null;
      circleStart = null;
      circleCurrent = null;
      shapeStart = null;
      shapeCurrent = null;
      curveStart = null;
      curveEnd = null;
    });
  }

  /// ── เส้นอิสระ (ปากกา) ────────────────────────────────
  void _toggleFreeLine() {
    final bool isActive = selectedTool == kToolTypePen && drawMode == "free";
    if (isActive) {
      _turnOffDrawTool();
    } else {
      setState(() {
        selectedTool = kToolTypePen;
        drawMode = "free";
        currentLineStyle = LineStyle.solid;
        isDrawing = true;
      });
    }
  }

  /// ── เส้นตรง ────────────────────────────────
  void _toggleLineMode() {
    final bool isActive = isDrawing && drawMode == "line" && currentLineStyle == LineStyle.solid;
    if (isActive) {
      _turnOffDrawTool();
    } else {
      setDrawMode("line");
    }
  }

  /// ── เส้นประ ────────────────────────────────
  void _toggleLineDashed() {
    final bool isActive = drawMode == "line" &&
        selectedTool != kToolTypeEraser &&
        currentLineStyle != LineStyle.solid;
    if (isActive) {
      _turnOffDrawTool();
    } else {
      _showLineStylePopup();
    }
  }

  /// ── เส้นโค้ง ────────────────────────────────
  void _toggleCurveMode() {
    final bool isActive = isDrawing && drawMode == "curve" && currentLineStyle == LineStyle.solid;
    if (isActive) {
      _turnOffDrawTool();
    } else {
      setDrawMode("curve");
    }
  }

  /// ── เส้นโค้งประ ────────────────────────────────
  void _toggleCurveDashed() {
    final bool isActive = drawMode == "curve" && currentLineStyle != LineStyle.solid;
    if (isActive) {
      _turnOffDrawTool();
    } else {
      _showCurveStylePopup();
    }
  }

  /// ── วงกลม / สามเหลี่ยม / สี่เหลี่ยม ────────────────────────────────
  void _toggleShapeMode(String mode) {
    final bool isActive = isDrawing && drawMode == mode;
    if (isActive) {
      _turnOffDrawTool();
    } else {
      setDrawMode(mode);
    }
  }

  /// ── ยางลบ ────────────────────────────────
  void _toggleEraser() {
    final bool isActive = selectedTool == kToolTypeEraser && drawMode == "free";
    if (isActive) {
      _turnOffDrawTool();
    } else {
      setState(() {
        selectedTool = kToolTypeEraser;
        drawMode = "free";
        isDrawing = true;
        currentLineStyle = LineStyle.solid;
      });
    }
  }

  /// ── popup เส้นประ ────────────────────────────────
  void _showLineStylePopup() async {
    final RenderBox box =
    _dashKey.currentContext!.findRenderObject() as RenderBox;

    final Offset iconPosition = box.localToGlobal(Offset.zero);
    final Size iconSize = box.size;

    final LineStyle? result = await showDialog<LineStyle>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (_) {
        return LineStyle_Popup(
          iconPosition: iconPosition,
          iconSize: iconSize,
          currentStyle: currentLineStyle,
        );
      },
    );

    if (result != null) {
      setState(() {
        selectedTool = kToolTypePen;
        currentLineStyle = result;
        drawMode = "line";
        isDrawing = true;
      });
    }
  }

  /// ── popup เส้นโค้งประ ────────────────────────────────
  void _showCurveStylePopup() async {
    final RenderBox box =
    _curveDashKey.currentContext!.findRenderObject() as RenderBox;

    final Offset iconPosition = box.localToGlobal(Offset.zero);
    final Size iconSize = box.size;

    final LineStyle? result = await showDialog<LineStyle>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (_) {
        return LineStyle_Popup(
          iconPosition: iconPosition,
          iconSize: iconSize,
        );
      },
    );

    if (result != null) {
      setDrawMode("curve");
      setState(() {
        currentLineStyle = result;
      });
    }
  }


  /// ── popup เลือกไอคอน ────────────────────────────────
  void _showDrawIconPopup() async {
    final RenderBox box =
    _drawIconKey.currentContext!.findRenderObject() as RenderBox;

    final Offset iconPosition = box.localToGlobal(Offset.zero);
    final Size iconSize = box.size;

    final String? result = await showDialog<String>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (_) {
        return Icon_Popup(
          iconPosition: iconPosition,
          iconSize: iconSize,
          iconPaths: drawIconPaths,
          iconLabels: [
            'RF1', 'RF2', 'จุดหมาย', 'ธง', 'โรงเรียน', 'วัด',
            'สนามบิน', 'ปั๊มน้ำมัน', 'ห้องน้ำ', 'หลักกิโลเมตร',
            'เสาไฟฟ้าแรงสูง', 'แทงค์น้ำ', 'มอเตอร์ไซค์', 'รถยนต์',
            'รถยนต์', 'ที่จอดรถ', 'ต้นไม้', 'ป่า',
            'หญ้า', 'พื้นที่เปิดโล่ง', 'ข้าว', 'นาข้าว',
            'ป้ายวงกลม', 'ป้ายสามเหลี่ยม', 'ป้ายสี่เหลี่ยม',
            'ป้ายสี่เหลี่ยม', 'ป้ายแปดเหลี่ยม',
          ],
        );
      },
    );

    if (result != null) {
      setState(() {
        selectedTool = kToolTypeNone;
        drawMode = "";
        isDrawing = false;

        _widgetsData.add({
          'path': result,
          'x': 350.0,
          'y': 380.0,
          'scale': 1.0,
          'rotation': 0.0,
        });
        _selectedIconIndex = _widgetsData.length - 1;
        _pushHistorySnapshot();
      });
    }
  }


  /// ── ประเภทไฟล์ที่ Export ────────────────────────────────
  String exportTypeToString(ExportType type) {
    switch (type) {
      case ExportType.png:
        return "PNG";
      case ExportType.jpeg:
        return "JPEG";
    }
  }

  ExportType stringToExportType(String value) {
    switch (value) {
      case "PNG":
        return ExportType.png;
      case "JPEG":
        return ExportType.jpeg;
      default:
        return ExportType.png;
    }
  }

  /// ── save >> Export file ────────────────────────────────
  /// ──  popup ────────────────────────────────
  void showExportDialog() {
    final TextEditingController nameController = TextEditingController(text: 'name');
    ExportType fileType = ExportType.png;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 70),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    // ไอคอนหัวข้อ
                    Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.image_outlined, size: 26, color: Colors.black),
                    ),

                    const SizedBox(height: 14),

                    const Text(
                      'Export file',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.black,
                        fontFamily: 'InstrumentSans',
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      'ตั้งชื่อไฟล์และเลือกประเภทไฟล์',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'NotoSansThai',
                        color: Colors.grey.shade500,
                      ),
                    ),

                    const SizedBox(height: 22),

                    // ชื่อไฟล์
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'File name',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'NotoSansThai',
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    TextField(
                      controller: nameController,
                      style: const TextStyle(fontSize: 14, fontFamily: 'NotoSansThai'),
                      decoration: InputDecoration(
                        hintText: 'Name',
                        filled: true,
                        fillColor: const Color(0xFFF6F6F6),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Colors.black87, width: 1.4),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ประเภทไฟล์
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'File type',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'NotoSansThai',
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    Row(
                      children: [
                        Expanded(
                          child: _FileTypeChip(
                            label: 'PNG',
                            selected: fileType == ExportType.png,
                            onTap: () => setState(() => fileType = ExportType.png),
                          ),
                        ),

                        SizedBox(width: 10),

                        Expanded(
                          child: _FileTypeChip(
                            label: 'JPEG',
                            selected: fileType == ExportType.jpeg,
                            onTap: () => setState(() => fileType = ExportType.jpeg),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    // ปุ่ม Cancel / Save
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(14),
                                  ),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontFamily: 'InstrumentSans',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(width: 10),

                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: const BorderRadius.only(
                                    bottomRight: Radius.circular(14),
                                  ),
                                ),
                              ),
                              onPressed: () async {
                                final ext = exportExtension(fileType);
                                final fileName = normalizeFileName(nameController.text, ext);

                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (_) => const Center(
                                    child: CircularProgressIndicator(color: Colors.white),
                                  ),
                                );

                                try {
                                  final bytes = await getBytes(format: ext);
                                  if (bytes != null) {
                                    await Wexport.saveToGallery(
                                      bytes: bytes,
                                      filename: fileName,
                                      extension: ext,
                                    );

                                    Navigator.pop(context);

                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (_) => alert_image_one_button(
                                        text: "บันทึก $fileName.$ext สำเร็จ",
                                        assets_image: "assets/images/checkmark.png",
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          Navigator.of(context).pop();
                                        },
                                        text_button: "ตกลง",
                                      ),
                                    );
                                  }

                                } catch (e) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
                                  );
                                }
                              },
                              child: const Text(
                                'Save',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontFamily: 'InstrumentSans',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }


  /// ── SnackBar หลัง save ────────────────────────────────
  void showSaveSuccessSnackBar(String fileName) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.grey[900],
        content: Text(
            "$fileName",
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Mitr',
              fontWeight: FontWeight.w400,
            )
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.fixed,
      ),
    );
  }

  /// ── popup Save ────────────────────────────────
  void showSaveOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                const SizedBox(height: 10),

                // handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                const SizedBox(height: 16),

                // header
                const Text(
                  'บันทึกงาน',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'NotoSansThai',
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  'เลือกวิธีการบันทึก',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'NotoSansThai',
                    color: Colors.grey.shade500,
                  ),
                ),

                const SizedBox(height: 18),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _SaveOptionCard(
                          icon: Icons.edit_outlined,
                          title: 'Save Drawing',
                          subtitle: 'บันทึกแบบร่าง (สามารถแก้ไขได้)',
                          onTap: () async {
                            Navigator.pop(context);
                            await saveDraft();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SaveOptionCard(
                          icon: Icons.image_outlined,
                          title: 'Export Image',
                          subtitle: 'PNG / JPEG',
                          onTap: () {
                            Navigator.pop(context);
                            showExportDialog();
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 15),

                // ปุ่มยกเลิก
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Color(0xFF18181C),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'ยกเลิก',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'NotoSansThai',
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),
              ],
            ),
          ),
        );
      },
    );
  }


  /// ── แก้งานเดิมได้ ────────────────────────────────
  void restorePoints(List<Map<String, dynamic>> data) {
    points.clear();

    for (final item in data) {
      if (item['break'] == true) {
        points.add(null);
        continue;
      }

      final stroke = StrokeModel.fromMap(item);

      LineStyle restoredStyle = LineStyle.solid;
      if (stroke.lineStyle != null) {
        restoredStyle = LineStyle.values[stroke.lineStyle!];
      }

      points.add(
        DrawingArea(
          point: Offset(stroke.x!, stroke.y!),
          areaPaint: Paint()
            ..color = Color(stroke.color)
            ..strokeWidth = stroke.strokeWidth
            ..strokeCap = StrokeCap.round
            ..isAntiAlias = true
            ..style = PaintingStyle.stroke
            ..blendMode = (item['isEraser'] ?? false)
                ? BlendMode.clear
                : BlendMode.srcOver,
          lineStyle: restoredStyle,
        ),
      );
    }
  }

  bool isPointInsideCircle(Offset p, ShapeCircle c) {
    return (p - c.center).distance <= c.radius + 15;
  }

  bool isPointInsideShape(Offset p, Shape s) {
    final rect = Rect.fromCenter(
      center: s.center,
      width: s.width,
      height: s.height,
    );
    return rect.inflate(15).contains(p);
  }

  bool isPointNearCurve(Offset p, ShapeCurve c) {
    final path = c.toPath();
    for (final metric in path.computeMetrics()) {
      const steps = 40;
      for (int i = 0; i <= steps; i++) {
        final dist = metric.length * i / steps;
        final tangent = metric.getTangentForOffset(dist);
        if (tangent != null && (p - tangent.position).distance <= 15) return true;
      }
    }
    return false;
  }

  void restoreAllData(SavedDrawing drawing) {
    setState(() {
      restorePoints(drawing.strokes);
      azimuthLayer = drawing.azimuthLayer ?? false;
      if (drawing.texts != null) {
        texts = drawing.texts!.map((t) {
          return {
            ...t,
            'position': Offset(t['dx'], t['dy']),
            'selected': false,
          };
        }).toList();
      }
      if (drawing.widgetsData != null) {
        _widgetsData = List<Map<String, dynamic>>.from(drawing.widgetsData!);
      }
      if (drawing.circles != null) {
        circles.clear();

        circles.addAll(drawing.circles!.map((c) => ShapeCircle(
          center: Offset(c['center_dx'], c['center_dy']),
          radius: (c['radius'] as num).toDouble(),
          paint: Paint()
            ..color = Color(c['color'] ?? Colors.black.value)
            ..strokeWidth = (c['strokeWidth'] ?? 2.0).toDouble()
            ..style = PaintingStyle.stroke,
          rotation: (c['rotation'] ?? 0.0).toDouble(),
        )));
      }
      if (drawing.shapes != null) {
        shapes.clear();

        shapes.addAll(drawing.shapes!.map((s) => Shape(
          type: s['type'] == 'triangle' ? Shape_TriangleSquare.triangle : Shape_TriangleSquare.square,
          center: Offset(s['center_dx'], s['center_dy']),
          width: (s['width'] as num).toDouble(),
          height: (s['height'] as num).toDouble(),
          paint: Paint()
            ..color = Color(s['color'] ?? Colors.black.value)
            ..strokeWidth = (s['strokeWidth'] ?? 2.0).toDouble()
            ..style = PaintingStyle.stroke,
          rotation: (s['rotation'] ?? 0.0).toDouble(),
        )));
      }
      if (drawing.curves != null) {
        curves.clear();
        curves.addAll(drawing.curves!.map((c) {
          List<Offset> pts;
          if (c['points'] != null) {
            pts = (c['points'] as List)
                .map((p) => Offset(
                (p['dx'] as num).toDouble(), (p['dy'] as num).toDouble()))
                .toList();
          } else {
            pts = [
              Offset(c['start_dx'], c['start_dy']),
              Offset(c['control_dx'], c['control_dy']),
              Offset(c['end_dx'], c['end_dy']),
            ];
          }
          return ShapeCurve(
            points: pts,
            lineStyle: c['lineStyle'] != null
                ? LineStyle.values[c['lineStyle']]
                : LineStyle.solid,
            paint: Paint()
              ..color = Color(c['color'] ?? Colors.black.value)
              ..strokeWidth = (c['strokeWidth'] ?? 2.0).toDouble()
              ..strokeCap = StrokeCap.round
              ..style = PaintingStyle.stroke
              ..isAntiAlias = true,
          );
        }));
      }
      if (drawing.backgroundImageData != null) {
        _loadSavedImage(drawing.backgroundImageData!);
      } else {
        backgroundImage.value = null;
      }
    });
    _pushHistorySnapshot();
  }



  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery
        .of(context)
        .size
        .width;
    final double height = MediaQuery
        .of(context)
        .size
        .height;

    return Scaffold(
      resizeToAvoidBottomInset: false,

      body: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF18181C),
                  Color(0xFF18181C),
                  Color(0xFF505050),
                ],
              ),
            ),
          ),

          /// Bar
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Container(
                height: kToolbarHeight,
                child: Row(
                  children: [

                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_new_outlined,
                          color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),

                    Expanded(
                        child: Center(
                          child: w_text_thai_notosansthai(
                            name: 'รูปวาดภาคสนาม',
                            font_Size: 24,
                            fontWeight : FontWeight.w700,
                            color: Colors.white,
                          ),
                        )
                    ),

                    SizedBox(width: 48), // balance icon

                  ],
                ),
              ),
            ),
          ),

          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[

                SizedBox(height: 60),

                SizedBox(
                  width: 900,
                  height: 500,
                  child: Stack(
                    children: [

                      /// ── Canvas (วาดรูป) ──────────────────────────────────
                      Listener(
                        onPointerDown: (_) => setState(() => _pointerCount++),
                        onPointerUp: (_) => setState(() => _pointerCount--),
                        onPointerCancel: (_) => setState(() => _pointerCount--),

                        // zoom เข้า - ออก กระดาษ
                        child: InteractiveViewer(
                          transformationController: _transformationController,
                          minScale: 0.5,
                          maxScale: 5.0,
                          panEnabled: _pointerCount >= 2,
                          scaleEnabled: _pointerCount >= 2,
                          child: Container(
                            width: double.infinity,
                            height: height * 0.50,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.all(Radius.circular(10.0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.6),
                                    blurRadius: 5.0,
                                    spreadRadius: 1.0,
                                  )
                                ]
                            ),

                            // กระดาษวาดรูป
                            child: RepaintBoundary(
                              key: repaintKey,
                              child: AbsorbPointer(
                                absorbing: _satelliteAdjustMode,
                                child: Listener(

                                  // เปิดโหมดปากกา
                                  onPointerDown: (event) {
                                    if (_stylusOnlyMode && event.kind != PointerDeviceKind.stylus) return;

                                    FocusScope.of(context).unfocus();
                                    setState(() {
                                      for (var t in texts) t['selected'] = false;
                                    });

                                    if (!isDrawing) return;

                                    final localPosition = event.localPosition;

                                    if (drawMode == "free") {
                                      setState(() {
                                        points.add(DrawingArea(
                                          point: localPosition,
                                          lineStyle: currentLineStyle,
                                          areaPaint: Paint()
                                            ..style = PaintingStyle.stroke
                                            ..strokeCap = StrokeCap.round
                                            ..isAntiAlias = true
                                            ..strokeWidth = selectedTool == kToolTypeEraser ? eraserWidth : strokeWidth
                                            ..color = selectedTool == kToolTypeEraser ? Colors.transparent : selectedColor
                                            ..blendMode = selectedTool == kToolTypeEraser ? BlendMode.clear : BlendMode.srcOver,
                                        ));
                                      });
                                    } else if (drawMode == "line") {
                                      setState(() {
                                        lineStart = localPosition;
                                        previewEnd = lineStart;
                                        linePaintInProgress = Paint()
                                          ..style = PaintingStyle.stroke
                                          ..strokeCap = StrokeCap.round
                                          ..isAntiAlias = true
                                          ..color = selectedColor
                                          ..strokeWidth = selectedTool == kToolTypeEraser ? eraserWidth : strokeWidth
                                          ..blendMode = BlendMode.srcOver;
                                      });
                                    } else if (drawMode == "circle") {
                                      setState(() {
                                        circleStart = localPosition;
                                        circleCurrent = localPosition;
                                      });
                                    } else if (drawMode == "square" || drawMode == "triangle") {
                                      setState(() {
                                        shapeStart = localPosition;
                                        shapeCurrent = localPosition;
                                      });
                                    } else if (drawMode == "curve") {
                                      setState(() {
                                        curveStart = localPosition;
                                        curveEnd = localPosition;
                                      });
                                    }
                                  },

                                  onPointerMove: (event) {
                                    if (_stylusOnlyMode && event.kind != PointerDeviceKind.stylus) return;
                                    if (!isDrawing) return;

                                    final localPosition = event.localPosition;

                                    if (drawMode == "free") {
                                      setState(() {
                                        points.add(DrawingArea(
                                          point: localPosition,
                                          lineStyle: currentLineStyle,
                                          areaPaint: Paint()
                                            ..style = PaintingStyle.stroke
                                            ..strokeCap = StrokeCap.round
                                            ..isAntiAlias = true
                                            ..strokeWidth = selectedTool == kToolTypeEraser ? eraserWidth : strokeWidth
                                            ..color = selectedTool == kToolTypeEraser ? Colors.transparent : selectedColor
                                            ..blendMode = selectedTool == kToolTypeEraser ? BlendMode.clear : BlendMode.srcOver,
                                        ));
                                      });
                                    } else if (drawMode == "line") {
                                      setState(() {
                                        previewEnd = localPosition;
                                      });
                                    } else if (drawMode == "circle") {
                                      setState(() {
                                        circleCurrent = localPosition;
                                      });
                                    } else if (drawMode == "square" || drawMode == "triangle") {
                                      setState(() {
                                        shapeCurrent = localPosition;
                                      });
                                    } else if (drawMode == "curve") {
                                      setState(() {
                                        curveEnd = localPosition;
                                      });
                                    }
                                  },

                                  onPointerUp: (event) {
                                    if (_stylusOnlyMode && event.kind != PointerDeviceKind.stylus) return;
                                    if (!isDrawing) return;

                                    if (drawMode == "free") {
                                      setState(() {
                                        points.add(null);
                                        _pushHistorySnapshot();
                                      });
                                    } else if (drawMode == "line") {
                                      if (lineStart != null && previewEnd != null && linePaintInProgress != null) {
                                        setState(() {
                                          points.add(DrawingArea(
                                            point: lineStart!,
                                            areaPaint: linePaintInProgress!,
                                            lineStyle: currentLineStyle,
                                          ));
                                          points.add(DrawingArea(
                                            point: previewEnd!,
                                            areaPaint: linePaintInProgress!,
                                            lineStyle: currentLineStyle,
                                          ));
                                          points.add(null);
                                          _pushHistorySnapshot();
                                          lineStart = null;
                                          previewEnd = null;
                                          linePaintInProgress = null;
                                        });
                                      } else {
                                        setState(() {
                                          lineStart = null;
                                          previewEnd = null;
                                        });
                                      }
                                    } else if (drawMode == "circle") {
                                      if (circleStart != null && circleCurrent != null) {
                                        setState(() {
                                          final center = Offset(
                                            (circleStart!.dx + circleCurrent!.dx) / 2,
                                            (circleStart!.dy + circleCurrent!.dy) / 2,
                                          );
                                          final radius = (circleStart! - circleCurrent!).distance / 2;
                                          circles.add(ShapeCircle(
                                            center: center,
                                            radius: radius,
                                            paint: Paint()
                                              ..color = selectedColor
                                              ..strokeWidth = strokeWidth
                                              ..style = PaintingStyle.stroke
                                              ..isAntiAlias = true,
                                          ));
                                          _pushHistorySnapshot();
                                          circleStart = null;
                                          circleCurrent = null;
                                          isDrawing = false;
                                          selectedTool = kToolTypeNone;
                                          drawMode = "";
                                        });
                                      } else {
                                        setState(() {
                                          circleStart = null;
                                          circleCurrent = null;
                                        });
                                      }
                                    } else if (drawMode == "square" || drawMode == "triangle") {
                                      if (shapeStart != null && shapeCurrent != null) {
                                        setState(() {
                                          final center = Offset(
                                            (shapeStart!.dx + shapeCurrent!.dx) / 2,
                                            (shapeStart!.dy + shapeCurrent!.dy) / 2,
                                          );
                                          shapes.add(Shape(
                                            type: drawMode == "square" ? Shape_TriangleSquare.square : Shape_TriangleSquare.triangle,
                                            center: center,
                                            width: (shapeCurrent!.dx - shapeStart!.dx).abs(),
                                            height: (shapeCurrent!.dy - shapeStart!.dy).abs(),
                                            paint: Paint()
                                              ..color = selectedColor
                                              ..strokeWidth = strokeWidth
                                              ..style = PaintingStyle.stroke
                                              ..isAntiAlias = true,
                                          ));
                                          _pushHistorySnapshot();

                                          isDrawing = false;
                                          selectedTool = kToolTypeNone;
                                          drawMode = "";
                                        });
                                      }
                                      setState(() {
                                        shapeStart = null;
                                        shapeCurrent = null;
                                      });
                                    } else if (drawMode == "curve") {
                                      if (curveStart != null && curveEnd != null &&
                                          (curveStart! - curveEnd!).distance > 8) {
                                        setState(() {
                                          final mid = Offset.lerp(curveStart!, curveEnd!, 0.5)!;
                                          curves.add(ShapeCurve(
                                            points: [curveStart!, mid, curveEnd!],
                                            lineStyle: currentLineStyle,
                                            paint: Paint()
                                              ..color = selectedColor
                                              ..strokeWidth = strokeWidth
                                              ..strokeCap = StrokeCap.round
                                              ..style = PaintingStyle.stroke
                                              ..isAntiAlias = true,
                                          ));
                                          _pushHistorySnapshot();

                                          isDrawing = false;
                                          selectedTool = kToolTypeNone;
                                          drawMode = "";
                                        });
                                      }
                                      setState(() {
                                        curveStart = null;
                                        curveEnd = null;
                                      });
                                    }
                                  },

                                  // ปากกาออกนอกจอ หรือ interrupt
                                  onPointerCancel: (event) {
                                    if (_stylusOnlyMode && event.kind != PointerDeviceKind.stylus) return;
                                    setState(() {
                                      if (drawMode == "free") {
                                        points.add(null);
                                        _pushHistorySnapshot();
                                      }
                                      lineStart = null;
                                      previewEnd = null;
                                      linePaintInProgress = null;
                                      circleStart = null;
                                      circleCurrent = null;
                                      shapeStart = null;
                                      shapeCurrent = null;
                                      curveStart = null;
                                      curveEnd = null;
                                    });
                                  },

                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTapUp: (details) {
                                      FocusScope.of(context).unfocus();

                                      final pos = details.localPosition;

                                      // แตะใกล้เส้นโค้งเส้นใดเส้นหนึ่ง >> เลือกเส้นนั้นแทนการยกเลิกเลือก
                                      for (int i = curves.length - 1; i >= 0; i--) {
                                        if (isPointNearCurve(pos, curves[i])) {
                                          setState(() {
                                            _selectedCurveIndex = i;
                                            _selectedShapeIndex = null;
                                            _selectedCircleIndex = null;
                                            for (var t in texts) t['selected'] = false;
                                          });
                                          return;
                                        }
                                      }

                                      // แตะพื้นที่อื่น >> ยกเลิกการเลือกทั้งหมด
                                      setState(() {
                                        for (var t in texts) t['selected'] = false;
                                        _selectedShapeIndex = null;
                                        _selectedCircleIndex = null;
                                        _selectedCurveIndex = null;
                                        _selectedIconIndex = null;
                                      });
                                    },

                                    child: ClipRRect(
                                      borderRadius: BorderRadius.all(Radius.circular(10.0)),
                                      child: Stack(
                                        children: [

                                          // พื้นหลังกระดาษ
                                          Container(color: Colors.white),

                                          // Background Image จาก Gallery
                                          if (backgroundImage.value != null)
                                            Positioned.fill(
                                              child: Opacity(
                                                opacity: 1.0,
                                                child: RawImage(
                                                  image: backgroundImage.value,
                                                  fit: BoxFit.contain,
                                                ),
                                              ),
                                            ),

                                          // Satellite Zoom In
                                          if (satellite_in && widget.zoomInBytes != null)
                                            Positioned.fill(
                                              child: IgnorePointer(
                                                child: Transform.translate(
                                                  offset: _satInOffset,
                                                  child: Transform.scale(
                                                    scale: _satInScale,
                                                    child: Opacity(
                                                      opacity: 0.75,
                                                      child: Image.memory(
                                                        widget.zoomInBytes!,
                                                        fit: BoxFit.contain,
                                                        width: double.infinity,
                                                        height: double.infinity,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),

                                          // Satellite Zoom Out
                                          if (satellite_out && widget.zoomOutBytes != null)
                                            Positioned.fill(
                                              child: IgnorePointer(
                                                child: Transform.translate(
                                                  offset: _satOutOffset,
                                                  child: Transform.scale(
                                                    scale: _satOutScale,
                                                    child: Opacity(
                                                      opacity: 0.75,
                                                      child: Image.memory(
                                                        widget.zoomOutBytes!,
                                                        fit: BoxFit.contain,
                                                        width: double.infinity,
                                                        height: double.infinity,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),

                                          // แสดงภาพ Azimuth
                                          if (azimuthLayer)
                                            IgnorePointer(
                                              child: Center(
                                                child: Opacity(
                                                  opacity: 1.0,
                                                  child: Image.asset(
                                                    'assets/images/AzimuthPNG.png',
                                                    fit: BoxFit.contain,
                                                  ),
                                                ),
                                              ),
                                            ),

                                          // วาดรูป
                                          CustomPaint(
                                            painter: MyCustomPainter(
                                              points: points,
                                              color: selectedColor,
                                              strokeWidth: (selectedTool == kToolTypeEraser) ? eraserWidth : strokeWidth,
                                              lineStyle: currentLineStyle,
                                              drawMode: drawMode,
                                              previewStart: lineStart,
                                              previewEnd: previewEnd,
                                              circleStart: circleStart,
                                              circleCurrent: circleCurrent,
                                              shapeStart: shapeStart,
                                              shapeCurrent: shapeCurrent,
                                              curves: curves,
                                              curveStart: curveStart,
                                              curveEnd: curveEnd,
                                              backgroundImage: backgroundImage.value,
                                            ),
                                            size: Size.infinite,
                                          ),

                                          // Shapes (square/triangle)
                                          ...shapes.asMap().entries.map((entry) {
                                            final i = entry.key;
                                            final shape = entry.value;
                                            return WDraggableShape(
                                              key: ValueKey('shape_$i'),
                                              shape: shape,
                                              selected: _selectedShapeIndex == i,
                                              drawingActive: isDrawing,
                                              onSelect: () {
                                                setState(() {
                                                  _selectedShapeIndex = i;
                                                  _selectedCircleIndex = null;
                                                  _selectedCurveIndex = null;
                                                  _selectedIconIndex = null;
                                                  isDrawing = false;
                                                  selectedTool = kToolTypeNone;
                                                  drawMode = "";
                                                  for (var t in texts) t['selected'] = false;
                                                });
                                              },
                                              onDelete: () {
                                                setState(() {
                                                  shapes.removeAt(i);
                                                  _selectedShapeIndex = null;
                                                  _pushHistorySnapshot();
                                                });
                                              },
                                              onDuplicate: () {
                                                setState(() {
                                                  final copy = shape.copyWith();
                                                  copy.center = copy.center + const Offset(20, 20);
                                                  shapes.insert(i + 1, copy);
                                                  _selectedShapeIndex = i + 1;
                                                  _selectedCircleIndex = null;
                                                  _selectedCurveIndex = null;
                                                  _selectedIconIndex = null;
                                                  _pushHistorySnapshot();
                                                });
                                              },
                                              onTransformEnd: () {
                                                setState(() {});
                                                _pushHistorySnapshot();
                                              },
                                            );
                                          }),

                                          // Circles
                                          ...circles.asMap().entries.map((entry) {
                                            final i = entry.key;
                                            final circle = entry.value;
                                            return WDraggableCircle(
                                              key: ValueKey('circle_$i'),
                                              circle: circle,
                                              selected: _selectedCircleIndex == i,
                                              drawingActive: isDrawing,
                                              onSelect: () {
                                                setState(() {
                                                  _selectedCircleIndex = i;
                                                  _selectedShapeIndex = null;
                                                  _selectedCurveIndex = null;
                                                  _selectedIconIndex = null;
                                                  isDrawing = false;
                                                  selectedTool = kToolTypeNone;
                                                  drawMode = "";
                                                  for (var t in texts) t['selected'] = false;
                                                });
                                              },
                                              onDelete: () {
                                                setState(() {
                                                  circles.removeAt(i);
                                                  _selectedCircleIndex = null;
                                                  _pushHistorySnapshot();
                                                });
                                              },
                                              onDuplicate: () {
                                                setState(() {
                                                  final copy = circle.copyWith();
                                                  copy.center = copy.center + const Offset(20, 20);
                                                  circles.insert(i + 1, copy);
                                                  _selectedCircleIndex = i + 1;
                                                  _selectedShapeIndex = null;
                                                  _selectedCurveIndex = null;
                                                  _selectedIconIndex = null;
                                                  _pushHistorySnapshot();
                                                });
                                              },
                                              onTransformEnd: () {
                                                setState(() {});
                                                _pushHistorySnapshot();
                                              },
                                            );
                                          }),

                                          // Curves
                                          ...curves.asMap().entries.map((entry) {
                                            final i = entry.key;
                                            final curve = entry.value;
                                            return WDraggableCurve(
                                              key: ValueKey('curve_$i'),
                                              curve: curve,
                                              selected: _selectedCurveIndex == i,
                                              onSelect: () {
                                                setState(() {
                                                  _selectedCurveIndex = i;
                                                  _selectedShapeIndex = null;
                                                  _selectedCircleIndex = null;
                                                  _selectedIconIndex = null;
                                                  isDrawing = false;
                                                  selectedTool = kToolTypeNone;
                                                  drawMode = "";
                                                  for (var t in texts) t['selected'] = false;
                                                });
                                              },
                                              onDelete: () {
                                                setState(() {
                                                  curves.removeAt(i);
                                                  _selectedCurveIndex = null;
                                                  _pushHistorySnapshot();
                                                });
                                              },
                                              onChanged: () => setState(() {}),
                                              onTransformEnd: () {
                                                _pushHistorySnapshot();
                                              },
                                            );
                                          }),

                                          // Icons
                                          ..._widgetsData.asMap().entries.map((entry) {
                                            final i = entry.key;
                                            final data = entry.value;
                                            return WDraggableIcon(
                                              key: ValueKey('icon_${i}_${data['path']}'),
                                              position: Offset(data['x'], data['y']),
                                              assetPath: data['path'],
                                              scale: data['scale'],
                                              rotation: data['rotation'],
                                              selected: _selectedIconIndex == i,
                                              drawingActive: isDrawing,
                                              iconSize: 40,
                                              onSelect: () {
                                                setState(() {
                                                  _selectedIconIndex = i;
                                                  _selectedShapeIndex = null;
                                                  _selectedCircleIndex = null;
                                                  _selectedCurveIndex = null;
                                                  isDrawing = false;
                                                  selectedTool = kToolTypeNone;
                                                  drawMode = "";
                                                  for (var t in texts) t['selected'] = false;
                                                });
                                              },
                                              onMove: (pos) {
                                                _widgetsData[i]['x'] = pos.dx;
                                                _widgetsData[i]['y'] = pos.dy;
                                              },
                                              onScale: (s) => _widgetsData[i]['scale'] = s,
                                              onRotate: (r) => _widgetsData[i]['rotation'] = r,
                                              onDelete: () {
                                                setState(() {
                                                  _widgetsData.removeAt(i);
                                                  _selectedIconIndex = null;
                                                  _pushHistorySnapshot();
                                                });
                                              },
                                              onDuplicate: () {
                                                setState(() {
                                                  final copy = Map<String, dynamic>.from(_widgetsData[i]);
                                                  copy['x'] = (copy['x'] as double) + 20.0;
                                                  copy['y'] = (copy['y'] as double) + 20.0;
                                                  _widgetsData.insert(i + 1, copy);
                                                  _selectedIconIndex = i + 1;
                                                  _pushHistorySnapshot();
                                                });
                                              },
                                              onTransformEnd: () {
                                                _pushHistorySnapshot();
                                              },
                                            );
                                          }),

                                          // AddText
                                          ...texts
                                              .asMap()
                                              .entries
                                              .map((entry) {
                                            final i = entry.key;
                                            final item = entry.value;
                                            return WdraggableText(
                                              key: ValueKey('text_${i}_${item['text']}'),
                                              position: item['position'],
                                              text: item['text'],
                                              scale: item['scale'],
                                              selected: item['selected'] ?? false,
                                              rotation: item['rotation'],
                                              isBold: item['bold'] ?? false,
                                              autofocusEdit: i == _newTextIndex,
                                              textColor: Color(item['color'] ?? Colors.black.value),
                                              onColorChanged: (c) {
                                                setState(() {
                                                  texts[i]['color'] = c.value;
                                                });
                                                _pushHistorySnapshot();
                                              },

                                              hasOutline: item['hasOutline'] ?? false,
                                              onOutlineChanged: (value) {
                                                setState(() {
                                                  texts[i]['hasOutline'] = value;
                                                });
                                                _pushHistorySnapshot();
                                              },

                                              onBoldChanged: (value) {
                                                setState(() {
                                                  texts[i]['bold'] = value;
                                                });
                                                _pushHistorySnapshot();
                                              },

                                              onSelect: () {
                                                setState(() {

                                                  selectedTool = kToolTypeNone;
                                                  drawMode = "";
                                                  isDrawing = false;
                                                  _selectedShapeIndex = null;
                                                  _selectedCircleIndex = null;
                                                  _selectedCurveIndex = null;
                                                  _selectedIconIndex = null;

                                                  for (final t in texts) {
                                                    t['selected'] = false;
                                                  }
                                                  texts[i]['selected'] = true;
                                                });
                                              },

                                              onUnselect: () {
                                                setState(() {
                                                  texts[i]['selected'] = false;
                                                });
                                              },

                                              onMove: (p) {
                                                setState(() {
                                                  texts[i]['position'] = p;
                                                });
                                              },

                                              onScale: (s) {
                                                setState(() {
                                                  texts[i]['scale'] = s;
                                                });
                                              },

                                              onChanged: (t) {
                                                setState(() {
                                                  texts[i]['text'] = t;
                                                });
                                                _pushHistorySnapshot();
                                              },

                                              onRotate: (r) {
                                                setState(() {
                                                  texts[i]['rotation'] = r;
                                                });
                                              },

                                              onDelete: () {
                                                setState(() {
                                                  texts.removeAt(i);
                                                });
                                                _pushHistorySnapshot();
                                              },

                                              onDuplicate: () {
                                                setState(() {
                                                  for (var t in texts) t['selected'] = false;

                                                  texts.add({
                                                    'position': item['position'] + const Offset(20, 20),
                                                    'text': item['text'],
                                                    'scale': item['scale'],
                                                    'rotation': item['rotation'],
                                                    'bold' : item['bold'] ?? false,
                                                    'hasOutline': item['hasOutline'] ?? false,
                                                    'color': item['color'] ?? Colors.black.value,
                                                    'selected': true,
                                                  });
                                                });
                                                _pushHistorySnapshot();
                                              },

                                              onTransformEnd: () {
                                                _pushHistorySnapshot();
                                              },
                                            );
                                          }),

                                          // layer ชื่อหมุด
                                          if (pointNameLayer &&
                                              widget.pointName != null &&
                                              widget.pointName!.trim().isNotEmpty)
                                            IgnorePointer(
                                              child: Align(
                                                alignment: Alignment.topCenter,
                                                child: Padding(
                                                  padding: const EdgeInsets.only(
                                                      top: 190,
                                                      left: 10
                                                  ),
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(
                                                        horizontal: 6, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius: BorderRadius.circular(2),
                                                    ),
                                                    child: Text(
                                                      widget.pointName!,
                                                      textAlign: TextAlign.center,
                                                      style: const TextStyle(
                                                        color: Colors.red,
                                                        fontWeight: FontWeight.w900,
                                                        fontSize: 20,
                                                        fontFamily: 'THSarabun',
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),

                                          // Cross layers
                                          if (cross_layer)
                                            IgnorePointer(
                                              child: Center(
                                                child: Opacity(
                                                  opacity: 1.0,
                                                  child: Transform.translate(
                                                    offset: const Offset(4, -8),
                                                    child: Image.asset(
                                                      'assets/images/cross.png',
                                                      width: 20,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),

                                          // Triangle line layers
                                          if (triangle_line_layer)
                                            IgnorePointer(
                                              child: Center(
                                                child: Opacity(
                                                  opacity: 1.0,
                                                  child: Transform.translate(
                                                    offset: const Offset(4, -9),
                                                    child: Image.asset(
                                                      'assets/images/triangle_line.PNG',
                                                      width: 30,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),

                                          // Triangle layers
                                          if (triangle_layer)
                                            IgnorePointer(
                                              child: Center(
                                                child: Opacity(
                                                  opacity: 1.0,
                                                  child: Transform.translate(
                                                    offset: const Offset(4, -9),
                                                    child: Image.asset(
                                                      'assets/images/triangle.PNG',
                                                      width: 30,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),

                                        ],
                                      ),
                                    ),
                                  ),
                                ), // ปิด Listener (canvas drawing)
                              ), // ปิด AbsorbPointer (canvas inner)
                            ), // ปิด RepaintBoundary
                          ), // ปิด Container (canvas box)
                        ), // ปิด InteractiveViewer (canvas)
                      ), // ปิด Listener (pointer counter)
                    ], // ปิด Stack children
                  ), // ปิด Stack
                ), // ปิด SizedBox

                SizedBox(height: 50),

                // แถบเครื่องมือด้านล่าง
                Container(
                  width: 700,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(16.0),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [

                      /// แถวแรก
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[

                          // Pen mode
                          DrawToolButton(
                            icon: Icons.edit,
                            label: 'วาดด้วยปากกา',
                            selected: _stylusOnlyMode,
                            onPressed: () {
                              _clearAllSelections();
                              setState(() {
                                _stylusOnlyMode = !_stylusOnlyMode;
                              });
                            },
                          ),

                          SizedBox(width: 5),

                          // สี
                          DrawToolButton(
                            icon: Icons.color_lens_sharp,
                            label: 'สี',
                            selected: false,
                            iconColor: selectedColor,
                            onPressed: () {
                              _clearAllSelections();
                              selectColor();
                            },
                          ),

                          SizedBox(width: 5),

                          SizedBox(
                            height: 50,
                            child: VerticalDivider(
                              width: 16,
                              thickness: 1,
                              color: Colors.grey.shade400,
                            ),
                          ),

                          SizedBox(width: 5),

                          // ความหนาเส้น/ยางลบ
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [

                              Row(
                                children: [

                                  SizedBox(
                                    width: 25,
                                    child: Text(
                                      (selectedTool == kToolTypeEraser)
                                          ? eraserWidth.toStringAsFixed(1)
                                          : strokeWidth.toStringAsFixed(1),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: (selectedTool == kToolTypeEraser)
                                            ? Colors.grey
                                            : Colors.black,
                                      ),
                                    ),
                                  ),

                                  SizedBox(
                                    width: 150,
                                    child: Slider(
                                      min: 0.5,
                                      max: (selectedTool == kToolTypeEraser) ? 50.0 : 10.0,
                                      activeColor: (selectedTool == kToolTypeEraser)
                                          ? Colors.grey
                                          : selectedColor,
                                      value: (selectedTool == kToolTypeEraser)
                                          ? eraserWidth
                                          : strokeWidth,
                                      onChanged: (value) {
                                        _clearAllSelections();
                                        setState(() {
                                          if (selectedTool == kToolTypeEraser) {
                                            eraserWidth = value;
                                          } else {
                                            strokeWidth = value;
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),

                              Text(
                                'ความหนา',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                  fontFamily: 'NotoSansThai',
                                ),
                              ),

                            ],
                          ),

                          SizedBox(
                            height: 50,
                            child: VerticalDivider(
                              width: 16,
                              thickness: 1,
                              color: Colors.grey.shade400,
                            ),
                          ),

                          SizedBox(width: 5),

                          // Undo
                          DrawToolButton(
                            icon: Icons.keyboard_arrow_left,
                            label: 'ย้อนกลับ',
                            selected: false,
                            enabled: historyIndex > 0,
                            onPressed: () {
                              _clearAllSelections();
                              _undo();
                            },
                          ),

                          SizedBox(width: 5),

                          // Redo
                          DrawToolButton(
                            icon: Icons.keyboard_arrow_right,
                            label: 'ทำซ้ำ',
                            selected: false,
                            enabled: historyIndex < history.length - 1,
                            onPressed: () {
                              _clearAllSelections();
                              _redo();
                            },
                          ),

                          SizedBox(width: 5),

                          // Clear
                          DrawToolButton(
                            icon: Icons.delete,
                            label: 'ลบทั้งหมด',
                            selected: false,
                            onPressed: () {
                              _clearAllSelections();
                              setState(() {
                                points.clear();
                                _widgetsData.clear();
                                _selectedIconIndex = null;
                                texts.clear();
                                circles.clear();
                                shapes.clear();
                                curves.clear();
                                _pushHistorySnapshot();
                              });
                            },
                          ),

                          SizedBox(width: 5),

                          // Export
                          DrawToolButton(
                            icon: Icons.save_rounded,
                            label: 'Save',
                            selected: false,
                            onPressed: () {
                              _clearAllSelections();
                              showSaveOptions();
                            },
                          ),

                        ],
                      ),

                      SizedBox(height: 10),

                      Divider(
                        indent: 30,
                        endIndent: 30,
                        thickness: 1,
                        color: Colors.grey.shade400,
                      ),

                      SizedBox(height: 10),

                      /// เครื่องมือแถวที่ 2
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [

                          // เส้นอิสระ
                          DrawToolButton(
                            icon: Icons.draw_outlined,
                            label: 'เส้นอิสระ',
                            selected: selectedTool == kToolTypePen && drawMode == "free",
                            onPressed: () {
                              _clearAllSelections();
                              _toggleFreeLine();
                            },
                          ),

                          SizedBox(width: 10),

                          // เส้นตรง
                          DrawToolButton(
                            icon: Icons.horizontal_rule,
                            label: 'เส้นตรง',
                            selected: drawMode == "line" && currentLineStyle == LineStyle.solid,
                            onPressed: () {
                              _clearAllSelections();
                              _toggleLineMode();
                            },
                          ),

                          SizedBox(width: 10),

                          // เส้นประ
                          DrawToolButton(
                            iconKey: _dashKey,
                            icon: Icons.linear_scale_outlined,
                            label: 'เส้นประ',
                            selected: drawMode == "line" &&
                                selectedTool != kToolTypeEraser &&
                                currentLineStyle != LineStyle.solid,
                            onPressed: () {
                              _clearAllSelections();
                              _toggleLineDashed();
                            },
                          ),

                          SizedBox(width: 10),

                          // เส้นโค้ง
                          DrawToolButton(
                            assetIcon: 'assets/images/icon_curve_black.png',
                            label: 'เส้นโค้ง',
                            selected: drawMode == "curve" && currentLineStyle == LineStyle.solid,
                            onPressed: () {
                              _clearAllSelections();
                              _toggleCurveMode();
                            },
                          ),

                          SizedBox(width: 10),

                          // เส้นโค้งประ
                          DrawToolButton(
                            iconKey: _curveDashKey,
                            assetIcon: 'assets/images/icon_curve_dot_black.png',
                            label: 'เส้นโค้งประ',
                            selected: drawMode == "curve" && currentLineStyle != LineStyle.solid,
                            onPressed: () {
                              _clearAllSelections();
                              _toggleCurveDashed();
                            },
                          ),

                          SizedBox(width: 10),

                          // วงกลม
                          DrawToolButton(
                            icon: Icons.circle_outlined,
                            label: 'วงกลม',
                            selected: drawMode == "circle",
                            onPressed: () {
                              _clearAllSelections();
                              _toggleShapeMode("circle");
                            },
                          ),

                          SizedBox(width: 10),

                          // สามเหลี่ยม
                          DrawToolButton(
                            icon: Icons.change_history_outlined,
                            label: 'สามเหลี่ยม',
                            selected: drawMode == "triangle",
                            onPressed: () {
                              _clearAllSelections();
                              _toggleShapeMode("triangle");
                            },
                          ),

                          SizedBox(width: 10),

                          // สี่เหลี่ยม
                          DrawToolButton(
                            icon: Icons.crop_square_outlined,
                            label: 'สี่เหลี่ยม',
                            selected: drawMode == "square",
                            onPressed: () {
                              _clearAllSelections();
                              _toggleShapeMode("square");
                            },
                          ),

                          SizedBox(width: 10),

                          // text
                          DrawToolButton(
                            icon: Icons.text_fields,
                            label: 'ข้อความ',
                            selected: false,
                            onPressed: () {
                              setState(() {
                                selectedTool = kToolTypeNone;
                                drawMode = "";
                                isDrawing = false;

                                texts.add({
                                  'position': const Offset(120, 120),
                                  'text': '',
                                  'scale': 1.0,
                                  'selected': true,
                                  'rotation': 0.0,
                                  'color': selectedColor.value,
                                });
                                _newTextIndex = texts.length - 1;
                              });
                              _pushHistorySnapshot();

                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) setState(() => _newTextIndex = null);
                              });
                            },
                          ),

                          SizedBox(width: 10),

                          // ปุ่ม Icons
                          DrawToolButton(
                            iconKey: _drawIconKey,
                            icon: Icons.emoji_symbols,
                            label: 'Icons',
                            selected: false,
                            onPressed: () {
                              _clearAllSelections();
                              _showDrawIconPopup();
                            },
                          ),

                          SizedBox(width: 10),

                          // ยางลบ
                          DrawToolButton(
                            assetIcon: 'assets/images/eraser_black.PNG',
                            label: 'ยางลบ',
                            selected: selectedTool == kToolTypeEraser && drawMode == "free",
                            onPressed: () {
                              _clearAllSelections();
                              _toggleEraser();
                            },
                          ),

                        ],
                      ),

                    ],
                  ),
                ),
              ],
            ),
          ),


          /// ── ปรับาภพ Satellite ───────────────────────────────────
          if (_satelliteAdjustMode) ...[
            Positioned(
              bottom: 140,
              left: 18,
              right: 18,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      // header + ปุ่มปิด
                      Row(
                        children: [
                          const Icon(Icons.satellite_alt, color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'ปรับภาพ: ${_adjustTarget == "in" ? "Zoom In" : "Zoom Out"}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontFamily: 'NotoSansThai',
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const Spacer(),

                          // toggle in/out (แสดงเฉพาะเปิดทั้งสอง)
                          if (satellite_in && satellite_out && widget.zoomInBytes != null && widget.zoomOutBytes != null)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  backgroundColor: Colors.white12,
                                  foregroundColor: Colors.white70,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),

                                icon: const Icon(Icons.compare_arrows, size: 14),

                                label: const Text(
                                  'สลับ',
                                  style: TextStyle(fontSize: 11,  fontFamily: 'NotoSansThai'),
                                ),
                                onPressed: () => setState(() =>
                                _adjustTarget = _adjustTarget == 'in' ? 'out' : 'in'),
                              ),
                            ),

                          const SizedBox(width: 5),

                          // ปุ่ม Reset
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                backgroundColor: Colors.white12,
                                foregroundColor: Colors.white70,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),

                              icon: const Icon(Icons.refresh, size: 14),

                              label: const Text(
                                  'Reset',
                                  style: TextStyle(fontSize: 11, fontFamily: 'NotoSansThai')
                              ),
                              onPressed: () => setState(() {
                                if (_adjustTarget == 'in') {
                                  _satInScale  = 1.0;
                                  _satInOffset = Offset.zero;
                                } else {
                                  _satOutScale  = 1.0;
                                  _satOutOffset = Offset.zero;
                                }
                              }),
                            ),
                          ),

                          const SizedBox(width: 5),

                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              style: TextButton.styleFrom(
                                minimumSize: const Size(40, 40),
                                padding: const EdgeInsets.all(2),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                backgroundColor: Colors.white12,
                                foregroundColor: Colors.white70,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () => setState(() => _satelliteAdjustMode = false),
                              child: const Icon(Icons.close, size: 14),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),
                      const Divider(color: Colors.white24, height: 1),
                      const SizedBox(height: 8),

                      // Scale slider
                      Row(
                        children: [
                          const Icon(Icons.zoom_in, color: Colors.white70, size: 16),
                          const SizedBox(width: 6),
                          const Text('ขนาด', style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'NotoSansThai')),
                          Expanded(
                            child: Slider(
                              min: 0.2,
                              max: 4.0,
                              value: _adjustTarget == 'in' ? _satInScale : _satOutScale,
                              activeColor: Colors.lightBlueAccent,
                              inactiveColor: Colors.white24,
                              onChanged: (v) => setState(() {
                                if (_adjustTarget == 'in') _satInScale = v;
                                else _satOutScale = v;
                              }),
                            ),
                          ),
                          SizedBox(
                            width: 36,
                            child: Text(
                              (_adjustTarget == 'in' ? _satInScale : _satOutScale).toStringAsFixed(1),
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),

                      // X offset slider
                      Row(
                        children: [
                          const Icon(Icons.swap_horiz, color: Colors.white70, size: 16),
                          const SizedBox(width: 6),
                          const Text('ซ้าย/ขวา', style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'NotoSansThai')),
                          Expanded(
                            child: Slider(
                              min: -500,
                              max: 500,
                              value: _adjustTarget == 'in' ? _satInOffset.dx : _satOutOffset.dx,
                              activeColor: Colors.lightBlueAccent,
                              inactiveColor: Colors.white24,
                              onChanged: (v) => setState(() {
                                if (_adjustTarget == 'in') {
                                  _satInOffset = Offset(v, _satInOffset.dy);
                                } else {
                                  _satOutOffset = Offset(v, _satOutOffset.dy);
                                }
                              }),
                            ),
                          ),
                          SizedBox(
                            width: 36,
                            child: Text(
                              (_adjustTarget == 'in' ? _satInOffset.dx : _satOutOffset.dx).toStringAsFixed(0),
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),

                      // Y offset slider
                      Row(
                        children: [
                          const Icon(Icons.swap_vert, color: Colors.white70, size: 16),
                          const SizedBox(width: 6),
                          const Text('บน/ล่าง', style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'NotoSansThai')),
                          Expanded(
                            child: Slider(
                              min: -500,
                              max: 500,
                              value: _adjustTarget == 'in' ? _satInOffset.dy : _satOutOffset.dy,
                              activeColor: Colors.lightBlueAccent,
                              inactiveColor: Colors.white24,
                              onChanged: (v) => setState(() {
                                if (_adjustTarget == 'in') {
                                  _satInOffset = Offset(_satInOffset.dx, v);
                                } else {
                                  _satOutOffset = Offset(_satOutOffset.dx, v);
                                }
                              }),
                            ),
                          ),
                          SizedBox(
                            width: 36,
                            child: Text(
                              (_adjustTarget == 'in' ? _satInOffset.dy : _satOutOffset.dy).toStringAsFixed(0),
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ),
            ),
          ],

          /// ── ปุ่ม layers มุมบนขวา ────────────────────────────────
          Positioned(
            top: 55,
            right: 8,
            child: Material(
                color: Colors.white,
                shape: CircleBorder(),
                elevation: 4,
                child: IconButton(
                  tooltip: 'Layers',
                  constraints: BoxConstraints(
                      minWidth: 32,
                      minHeight: 32
                  ),
                  padding: EdgeInsets.zero,

                  iconSize: 20.0,

                  onPressed: () {
                    setState(() {
                      isLayerMenuOpen = !isLayerMenuOpen;
                    });
                  },
                  icon: Icon(Icons.layers),
                  color: Colors.black,
                )
            ),
          ),

          /// ── Checkbox ────────────────────────────────
          if (isLayerMenuOpen)
            Positioned(
                top: 45,
                right: 8,
                child: Material(
                  elevation: 10,
                  shadowColor: Colors.black.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                  child: Container(
                    width: 500,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200, width: 1),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [

                        _LayerPanelHeader(
                          onClose: () => setState(() => isLayerMenuOpen = false),
                        ),

                        const Divider(height: 1, indent: 14, endIndent: 14),

                        const SizedBox(height: 6),

                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              // Triangle Line, Triangle, Azimuth
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 10, right: 6),
                                  child: Column(
                                    children: [

                                      /// Layer ชื่อหมุดรังวัด
                                      // if (widget.pointName != null &&
                                      //     widget.pointName!.trim().isNotEmpty)
                                      //   _LayerToggleTileCompact(
                                      //     icon: Icons.text_fields,
                                      //     label: 'ชื่อหมุดรังวัด',
                                      //     value: pointNameLayer,
                                      //     onChanged: (v) => setState(() => pointNameLayer = v),
                                      //   ),

                                      _LayerToggleTileCompact(
                                        icon: Icons.close,
                                        label: 'หมุดรังวัด',
                                        value: cross_layer,
                                        onChanged: (v) => setState(() => cross_layer = v),
                                      ),

                                      // _LayerToggleTileCompact(
                                      //   icon: Icons.change_history_outlined,
                                      //   label: 'Triangle Line',
                                      //   value: triangle_line_layer,
                                      //   onChanged: (v) => setState(() => triangle_line_layer = v),
                                      // ),
                                      //
                                      // _LayerToggleTileCompact(
                                      //   icon: Icons.navigation,
                                      //   label: 'Triangle',
                                      //   value: triangle_layer,
                                      //   onChanged: (v) => setState(() => triangle_layer = v),
                                      // ),

                                      _LayerToggleTileCompact(
                                        icon: Icons.explore_outlined,
                                        label: 'Azimuth',
                                        value: azimuthLayer,
                                        onChanged: (v) => setState(() => azimuthLayer = v),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              Container(
                                width: 1,
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                color: Colors.grey.shade200,
                              ),

                              // Satellite in/out + ปุ่มปรับภาพ
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 6, right: 10),
                                  child: Column(
                                    children: [

                                      if (widget.zoomInBytes != null)
                                        _LayerToggleTileCompact(
                                          icon: Icons.satellite_alt_outlined,
                                          label: 'Satellite (Zoom in)',
                                          value: satellite_in,
                                          onChanged: (v) => setState(() {
                                            satellite_in = v;
                                            if (!satellite_in) {
                                              _satelliteAdjustMode = false;
                                            }
                                          }),
                                        ),

                                      if (widget.zoomOutBytes != null)
                                        _LayerToggleTileCompact(
                                          icon: Icons.satellite_alt_outlined,
                                          label: 'Satellite (Zoom out)',
                                          value: satellite_out,
                                          onChanged: (v) => setState(() {
                                            satellite_out = v;
                                            if (!satellite_out) {
                                              _satelliteAdjustMode = false;
                                            }
                                          }),
                                        ),

                                      SizedBox(height: 7),

                                      // ปุ่มปรับภาพ
                                      if ((satellite_in && widget.zoomInBytes != null) ||
                                          (satellite_out && widget.zoomOutBytes != null)) ...[
                                        const SizedBox(height: 4),
                                        SizedBox(
                                          width: double.infinity,
                                          height: 34,
                                          child: ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: _satelliteAdjustMode
                                                  ? Color(0xFF7C7C7C)
                                                  : Colors.black,
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              padding: const EdgeInsets.symmetric(horizontal: 6),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                            ),
                                            icon: Icon(
                                              _satelliteAdjustMode
                                                  ? Icons.close
                                                  : Icons.open_with,
                                              size: 13,
                                            ),
                                            label: Text(
                                              _satelliteAdjustMode
                                                  ? 'ปิดการปรับภาพ'
                                                  : 'ปรับภาพ',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                fontFamily: 'NotoSansThai',
                                              ),
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _satelliteAdjustMode = !_satelliteAdjustMode;
                                                if (_satelliteAdjustMode) {
                                                  if (satellite_in && widget.zoomInBytes != null) {
                                                    _adjustTarget = 'in';
                                                  } else if (satellite_out && widget.zoomOutBytes != null) {
                                                    _adjustTarget = 'out';
                                                  }
                                                  isDrawing = false;
                                                  selectedTool = kToolTypeNone;
                                                  drawMode = '';
                                                  isLayerMenuOpen = false;
                                                }
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),

                            ],
                          ),
                        ),

                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                )
            ),

        ],
      ),
    );
  }

  /// ── Export ────────────────────────────────
  Future<Uint8List?> getBytes({String format = 'png'}) async {
    try {
      final boundary = repaintKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) return null;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);

      final ByteData? byteData =
      await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) return null;

      return byteData.buffer.asUint8List();
    } catch (e) {
      debugPrint('getBytes error: $e');
      return null;
    }
  }

  Future<void> _loadSavedImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    setState(() {
      backgroundImage.value = frame.image;
    });
  }

  /// ── saveDraft ────────────────────────────────
  Future<void> saveDraft() async {
    FocusScope.of(context).unfocus();
    _selectedShapeIndex = null;
    _selectedCircleIndex = null;
    _selectedCurveIndex = null;

    setState(() {
      for (var t in texts) {
        t['selected'] = false;
      }
    });

    await Future.delayed(const Duration(milliseconds: 100));

    final String draftName = savedDrawing?.name ?? "Note_${DateTime.now().millisecondsSinceEpoch}";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // เก็บสถานะเดิมไว้ก่อน
    bool originalAzimuthState    = azimuthLayer;
    bool originalSatelliteIn     = satellite_in;
    bool originalSatelliteOut    = satellite_out;
    bool originalTriangle        = triangle_layer;
    bool originalTriangleLine    = triangle_line_layer;
    bool originalCrossLine       = cross_layer;

    setState(() {
      azimuthLayer       = false;
      satellite_in       = false;
      satellite_out      = false;
    });

    await Future.delayed(const Duration(milliseconds: 50));

    try {
      final previewBytes = await getBytes(format: 'png');
      if (previewBytes == null) return;

      setState(() {
        azimuthLayer        = originalAzimuthState;
        satellite_in        = originalSatelliteIn;
        satellite_out       = originalSatelliteOut;
        triangle_layer      = originalTriangle;
        triangle_line_layer = originalTriangleLine;
        cross_layer         = originalCrossLine;
      });

      final savedTexts = texts.map((t) {
        final Offset pos = t['position'] as Offset;
        return {
          'text': t['text'],
          'dx': pos.dx,
          'dy': pos.dy,
          'scale': t['scale'],
          'rotation': t['rotation'],
          'bold': t['bold'] ?? false,
          'hasOutline': t['hasOutline'] ?? false,
          'color': t['color'] ?? Colors.black.value,
          'selected': false,
        };
      }).toList();

      final savedCircles = circles.map((c) => {
        'center_dx': c.center.dx,
        'center_dy': c.center.dy,
        'radius': c.radius,
        'color': c.paint.color.value,
        'strokeWidth': c.paint.strokeWidth,
        'rotation': c.rotation,
      }).toList();

      final savedShapes = shapes.map((s) => {
        'type': s.type == Shape_TriangleSquare.triangle ? 'triangle' : 'square',
        'center_dx': s.center.dx,
        'center_dy': s.center.dy,
        'width': s.width,
        'height': s.height,
        'color': s.paint.color.value,
        'strokeWidth': s.paint.strokeWidth,
        'rotation': s.rotation,
      }).toList();

      final savedCurves = curves.map((c) => {
        'points': c.points.map((p) => {'dx': p.dx, 'dy': p.dy}).toList(),
        'color': c.paint.color.value,
        'strokeWidth': c.paint.strokeWidth,
        'lineStyle': c.lineStyle.index,
      }).toList();

      Uint8List? bgBytes;
      if (backgroundImage.value != null) {
        final byteData = await backgroundImage.value!.toByteData(format: ui.ImageByteFormat.png);
        bgBytes = byteData?.buffer.asUint8List();
      }

      final drawing = SavedDrawing(
        name: draftName,
        imageBytes: previewBytes,
        format: 'draft',
        strokes: serializePoints(),
        texts: savedTexts,
        widgetsData: _widgetsData,
        azimuthLayer: azimuthLayer,
        circles: savedCircles,
        shapes: savedShapes,
        curves: savedCurves,
        backgroundImageData: bgBytes,
      );

      await drawingBox.clear();
      await drawingBox.add(drawing);

      if (mounted) {
        Navigator.pop(context);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => alert_image_one_button(
            text: "บันทึกรูปวาดภาคสนามสำเร็จ",
            assets_image: "assets/images/checkmark.png",
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            text_button: "ตกลง",
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      // debugPrint("Save error: $e");
    }
  }

  /// ── savename ────────────────────────────────
  Future<String?> showDraftNameDialog({String? initialName}) async {
    final controller = TextEditingController(text: initialName ?? '');

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('ตั้งชื่อผลงาน'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'เช่น แบบร่างบ้าน, แผนที่แปลงนา',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(context, name);
              },
              child: const Text('บันทึก'),
            ),
          ],
        );
      },
    );
  }
}

class CanvasState {
  final List<DrawingArea?> points;
  final List<OverLayedWidget> widgets;
  final List<Map<String, dynamic>> texts;
  final List<Shape> shapes;
  final List<ShapeCircle> circles;
  final List<ShapeCurve> curves;
  final ui.Image? backgroundImage;
  final List<Map<String, dynamic>> widgetsData;

  CanvasState({
    required this.points,
    required this.widgets,
    required this.texts,
    required this.shapes,
    required this.circles,
    required this.curves,
    required this.backgroundImage,
    required this.widgetsData,
  });
}

class _SaveOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SaveOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F6F6),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 24, color: Colors.black),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                fontFamily: 'NotoSansThai',
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.5,
                fontFamily: 'NotoSansThai',
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ── save >> Export file ────────────────────────────────
class _FileTypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FileTypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? Color(0xFF7C7C7C)
              : const Color(0xFFF6F6F6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? Color(0xFF7C7C7C)
                : Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            fontFamily: 'InstrumentSans',
            color: selected
                ? Colors.white
                : Colors.black87,
          ),
        ),
      ),
    );
  }
}

/// ── Layer ────────────────────────────────
class _LayerPanelHeader extends StatelessWidget {
  final VoidCallback onClose;
  const _LayerPanelHeader({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 8),
      child: Row(
        children: [

          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.06),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.layers_outlined, size: 16, color: Colors.black),
          ),

          const SizedBox(width: 8),

          const Text(
            'Layers',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              fontFamily: 'NotoSansThai',
              color: Colors.black,
            ),
          ),

          const Spacer(),

          GestureDetector(
            onTap: onClose,
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 15, color: Colors.black54),
            ),
          ),

          SizedBox(width: 5)
        ],
      ),
    );
  }
}

// Layer แสดงข้อมูล
class _LayerToggleTileCompact extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _LayerToggleTileCompact({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: value ? Colors.black.withOpacity(0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [

            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: value ? Colors.black : const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 14,
                color: value ? Colors.white : Colors.grey.shade500,
              ),
            ),

            const SizedBox(width: 5),

            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: value ? FontWeight.w700 : FontWeight.w500,
                fontFamily: 'NotoSansThai',
                color: value ? Colors.black : Colors.black87,
              ),
            ),

            const Spacer(),

            Transform.scale(
              scale: 0.75,
              child: Switch(
                value: value,
                onChanged: onChanged,
                activeColor: Colors.white,
                activeTrackColor: Colors.black,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: Colors.grey.shade300,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
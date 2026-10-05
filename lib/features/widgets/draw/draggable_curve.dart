import 'package:flutter/material.dart';
import 'shape_curve.dart';

/// ── เส้นโค้งมีปุ่ม X ลบโค้ง ──────────────────
class WDraggableCurve extends StatelessWidget {
  final ShapeCurve curve;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onDelete;
  final VoidCallback onChanged;
  final VoidCallback? onTransformEnd;

  const WDraggableCurve({
    super.key,
    required this.curve,
    required this.selected,
    required this.onSelect,
    required this.onDelete,
    required this.onChanged,
    this.onTransformEnd,
  });

  /// ── จุดควบคุมมุมโค้ง ──────────────────
  Widget _pointHandle(int index) {
    final points = curve.points;
    final pos = points[index];

    final Color color = index == 0
        ? Colors.green
        : (index == points.length - 1
        ? Colors.redAccent
        : Colors.blueAccent);

    const double size = 22.0;

    return Positioned(
      key: ValueKey('curve_point_$index'),
      left: pos.dx - size / 2,
      top: pos.dy - size / 2,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (_) => onSelect(),
        onPanUpdate: (d) {
          curve.points[index] = curve.points[index] + d.delta;
          onChanged();
        },
        onPanEnd: (_) => onTransformEnd?.call(),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color.withOpacity(0.9),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 3),
            ],
          ),
        ),
      ),
    );
  }

  /// ── ปุ่ม X ลบมุมโค้ง ──────────────────
  Widget _deletePointButton(int index) {
    final pos = curve.points[index];
    const double handleSize = 22.0;
    const double btnSize = 18.0;

    final Offset badgeCenter = Offset(
      pos.dx + handleSize / 2 + 2,
      pos.dy - handleSize / 2 - 2,
    );

    return Positioned(
      key: ValueKey('curve_delete_$index'),
      left: badgeCenter.dx - btnSize / 2,
      top: badgeCenter.dy - btnSize / 2,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          curve.points.removeAt(index);
          onChanged();
          onTransformEnd?.call();
        },
        child: Container(
          width: btnSize,
          height: btnSize,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 3)],
          ),
          child: const Icon(Icons.close, size: 12, color: Colors.red),
        ),
      ),
    );
  }

  /// ── ปุ่ม + เพิ่มมุมโค้ง ──────────────────
  Widget _addPointButton(int afterIndex) {
    final p1 = curve.points[afterIndex];
    final p2 = curve.points[afterIndex + 1];
    final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
    const double size = 20.0;

    return Positioned(
      key: ValueKey('curve_add_$afterIndex'),
      left: mid.dx - size / 2,
      top: mid.dy - size / 2,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          curve.points.insert(afterIndex + 1, mid);
          onSelect();
          onChanged();
          onTransformEnd?.call();
        },
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.blueAccent, width: 1.5),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 3),
            ],
          ),
          child: const Icon(Icons.add, size: 13, color: Colors.blueAccent),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    // ยังไม่ถูกเลือก >> ไม่แสดงอะไรเลย
    if (!selected) {
      return const SizedBox.shrink();
    }

    final points = curve.points;

    return Stack(
      clipBehavior: Clip.none,
      children: [

        // เส้นเชื่อมจุดควบคุม
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _GuideLinePainter(points: points),
            ),
          ),
        ),

        // ปุ่มเพิ่มจุด
        for (int i = 0; i < points.length - 1; i++) _addPointButton(i),

        // จุดจับทุกจุด
        for (int i = 0; i < points.length; i++) _pointHandle(i),

        // ปุ่มลบจุดกลาง (เฉพาะจุดที่ไม่ใช่จุดเริ่ม/จุดจบ และเหลือมากกว่า 2 จุด)
        if (points.length > 2)
          for (int i = 1; i < points.length - 1; i++) _deletePointButton(i),

        // ปุ่มลบทั้งเส้น
        Positioned(
          left: points.last.dx - 30,
          top: points.last.dy + 20,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onDelete,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
              ),
              child: const Icon(Icons.cancel, color: Colors.red, size: 24),
            ),
          ),
        ),
      ],
    );
  }
}

class _GuideLinePainter extends CustomPainter {
  final List<Offset> points;
  _GuideLinePainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final guide = Paint()
      ..color = Colors.blueAccent.withOpacity(0.4)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], guide);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


/// ── เส้นโค้ง >> กด 2 ครั้งเพื่อลบมุมโค้ง ──────────────────
// import 'package:flutter/material.dart';
// import 'shape_curve.dart';
//
// /// Widget ที่วางทับ Canvas เพื่อให้แตะเลือก / ลากปรับจุดควบคุมของ
// /// เส้นโค้ง ShapeCurve ทีละจุด (รองรับหลายจุด ไม่ใช่แค่ 3 จุดแบบเดิม)
// ///
// /// - ลากแต่ละจุดควบคุม (handle) เพื่อปรับรูปร่างเฉพาะช่วงนั้น
// /// - แตะปุ่ม "+" กลางแต่ละช่วง เพื่อแทรกจุดควบคุมใหม่ตรงนั้น
// /// - แตะสองครั้ง (double-tap) ที่จุดกลาง (ไม่ใช่จุดเริ่ม/จุดจบ) เพื่อลบจุดนั้น
// class WDraggableCurve extends StatelessWidget {
//   final ShapeCurve curve;
//   final bool selected;
//   final VoidCallback onSelect;
//   final VoidCallback onDelete;
//   final VoidCallback onChanged;       // เรียก setState ทุกครั้งที่ลาก/เพิ่ม/ลบจุด (เพื่อ re-paint เส้น)
//   final VoidCallback? onTransformEnd; // เรียกตอนปล่อยนิ้ว/เพิ่ม/ลบจุด เพื่อ push history
//
//   const WDraggableCurve({
//     super.key,
//     required this.curve,
//     required this.selected,
//     required this.onSelect,
//     required this.onDelete,
//     required this.onChanged,
//     this.onTransformEnd,
//   });
//
//   // ── จุดควบคุมแต่ละจุด (ลากได้ / double-tap ลบได้ถ้าเป็นจุดกลาง) ──
//   Widget _pointHandle(int index) {
//     final points = curve.points;
//     final pos = points[index];
//     final bool isEndpoint = index == 0 || index == points.length - 1;
//     final bool canDelete = !isEndpoint && points.length > 2;
//
//     final Color color = index == 0
//         ? Colors.green
//         : (index == points.length - 1 ? Colors.redAccent : Colors.blueAccent);
//
//     const double size = 22.0;
//
//     return Positioned(
//       key: ValueKey('curve_point_$index'),
//       left: pos.dx - size / 2,
//       top: pos.dy - size / 2,
//       child: GestureDetector(
//         behavior: HitTestBehavior.opaque,
//         onPanStart: (_) => onSelect(),
//         onPanUpdate: (d) {
//           curve.points[index] = curve.points[index] + d.delta;
//           onChanged();
//         },
//         onPanEnd: (_) => onTransformEnd?.call(),
//         onDoubleTap: canDelete
//             ? () {
//           curve.points.removeAt(index);
//           onChanged();
//           onTransformEnd?.call();
//         }
//             : null,
//         child: Container(
//           width: size,
//           height: size,
//           decoration: BoxDecoration(
//             color: color.withOpacity(0.9),
//             shape: BoxShape.circle,
//             border: Border.all(color: Colors.white, width: 2),
//             boxShadow: const [
//               BoxShadow(color: Colors.black26, blurRadius: 3),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   // ── ปุ่ม "+" กลางแต่ละช่วง สำหรับแทรกจุดใหม่ ─────────────
//   Widget _addPointButton(int afterIndex) {
//     final p1 = curve.points[afterIndex];
//     final p2 = curve.points[afterIndex + 1];
//     final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
//     const double size = 20.0;
//
//     return Positioned(
//       key: ValueKey('curve_add_$afterIndex'),
//       left: mid.dx - size / 2,
//       top: mid.dy - size / 2,
//       child: GestureDetector(
//         behavior: HitTestBehavior.opaque,
//         onTap: () {
//           curve.points.insert(afterIndex + 1, mid);
//           onSelect();
//           onChanged();
//           onTransformEnd?.call();
//         },
//         child: Container(
//           width: size,
//           height: size,
//           decoration: BoxDecoration(
//             color: Colors.white,
//             shape: BoxShape.circle,
//             border: Border.all(color: Colors.blueAccent, width: 1.5),
//             boxShadow: const [
//               BoxShadow(color: Colors.black26, blurRadius: 3),
//             ],
//           ),
//           child: const Icon(Icons.add, size: 13, color: Colors.blueAccent),
//         ),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // ✅ ยังไม่ถูกเลือก -> ไม่แสดงอะไรเลย (ไม่มีจุดฟ้าจางค้างอยู่)
//     // การเลือกเส้นโค้งทำผ่านการแตะที่ตัวเส้นจริงบน Canvas แทน (ดู isPointNearCurve ในหน้า Draw/Note)
//     if (!selected) {
//       return const SizedBox.shrink();
//     }
//
//     final points = curve.points;
//
//     return Stack(
//       clipBehavior: Clip.none,
//       children: [
//         // เส้น guide บาง ๆ เชื่อมจุดควบคุมทั้งหมด (มองเห็นโครงเส้นตรงระหว่างจุด)
//         Positioned.fill(
//           child: IgnorePointer(
//             child: CustomPaint(
//               painter: _GuideLinePainter(points: points),
//             ),
//           ),
//         ),
//
//         // ปุ่มเพิ่มจุด ระหว่างแต่ละคู่จุดที่ติดกัน
//         for (int i = 0; i < points.length - 1; i++) _addPointButton(i),
//
//         // จุดจับทุกจุด
//         for (int i = 0; i < points.length; i++) _pointHandle(i),
//
//         // ปุ่มลบทั้งเส้น ลอยข้างจุดสุดท้าย
//         Positioned(
//           left: points.last.dx + 16,
//           top: points.last.dy - 34,
//           child: GestureDetector(
//             behavior: HitTestBehavior.opaque,
//             onTap: onDelete,
//             child: Container(
//               decoration: const BoxDecoration(
//                 color: Colors.white,
//                 shape: BoxShape.circle,
//                 boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
//               ),
//               child: const Icon(Icons.cancel, color: Colors.red, size: 24),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }
//
// class _GuideLinePainter extends CustomPainter {
//   final List<Offset> points;
//   _GuideLinePainter({required this.points});
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     if (points.length < 2) return;
//     final guide = Paint()
//       ..color = Colors.blueAccent.withOpacity(0.4)
//       ..strokeWidth = 1
//       ..style = PaintingStyle.stroke;
//     for (int i = 0; i < points.length - 1; i++) {
//       canvas.drawLine(points[i], points[i + 1], guide);
//     }
//   }
//
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
// }


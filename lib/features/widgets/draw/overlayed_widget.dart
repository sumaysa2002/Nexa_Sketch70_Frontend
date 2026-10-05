import 'dart:math';
import 'package:flutter/material.dart';
import 'package:matrix_gesture_detector/matrix_gesture_detector.dart';

class OverLayedWidget extends StatefulWidget {

  final Widget child;

  final Offset? position;
  final double? scale;
  final double? rotation;

  final Function(Offset)? onMove;
  final Function(double)? onScale;
  final Function(double)? onRotate;
  final Function()? onDelete;
  final Function()? onDuplicate;

  OverLayedWidget copy(){
    return OverLayedWidget(
      child: child,
    );
  }

  OverLayedWidget({
    super.key,
    required this.child,
    this.position,
    this.scale,
    this.rotation,
    this.onMove,
    this.onScale,
    this.onRotate,
    this.onDelete,
    this.onDuplicate,
  });

  @override
  State<OverLayedWidget> createState() => _OverLayedWidgetState();
}

class _OverLayedWidgetState extends State<OverLayedWidget> {

  late ValueNotifier <Matrix4> notifier;
  bool _isTransforming = false;

  @override
  void initState() {
    super.initState();

    Matrix4 initialMatrix = Matrix4.identity();

    if (widget.position != null) {
      initialMatrix.translate(widget.position!.dx, widget.position!.dy);
    }

    if (widget.scale != null) {
      initialMatrix.scale(widget.scale!);
    }

    if (widget.rotation != null) {
      initialMatrix.rotateZ(widget.rotation!);
    }

    notifier = ValueNotifier(initialMatrix);
  }

  @override
  Widget build(BuildContext context) {
    return TapRegion(

      // กดข้างนอกพื้นที่ >> กรอบจะหายไป
      onTapOutside: (event) {
        if (_isTransforming) {
          setState(() => _isTransforming = false);
        }
      },
      // กดที่ตัวไอคอน >> กรอบจะขึ้น
      onTapInside: (event) {
        if (!_isTransforming) {
          setState(() => _isTransforming = true);
        }
      },
      child: MatrixGestureDetector(
        onMatrixUpdate: (m, tm, sm, rm) {
          notifier.value = m;

          if (!_isTransforming) {
            setState(() => _isTransforming = true);
          }

          if (widget.onMove != null) {
            final t = m.getTranslation();
            widget.onMove!(Offset(t.x, t.y));
          }
          if (widget.onScale != null) {
            final s = m.getMaxScaleOnAxis();
            widget.onScale!(s);
          }
          if (widget.onRotate != null) {
            final r = atan2(m.entry(1, 0), m.entry(0, 0));
            widget.onRotate!(r);
          }
        },
        child: AnimatedBuilder(
          animation: notifier,
          builder: (ctx, childWidget) {
            return Transform(
              transform: notifier.value,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: IntrinsicWidth(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [

                          //เส้นกรอบ
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _isTransforming ? Colors.blueAccent : Colors.transparent,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: widget.child,
                          ),

                          // ปุ่มลบ
                          if (_isTransforming && widget.onDelete != null)
                            Positioned(
                              top: -15,
                              right: -15,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  widget.onDelete!();
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.black26, blurRadius: 4
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                      Icons.cancel,
                                      color: Colors.red,
                                      size: 30
                                  ),
                                ),
                              ),
                            ),

                          // ปุ่มคัดลอก
                          if (_isTransforming && widget.onDuplicate != null)
                            Positioned(
                              top: -15,
                              left: -15,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  widget.onDuplicate!();
                                },
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.black26, blurRadius: 4
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                      Icons.copy,
                                      color: Colors.blueAccent,
                                      size: 26
                                  ),
                                ),
                              ),
                            ),

                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}


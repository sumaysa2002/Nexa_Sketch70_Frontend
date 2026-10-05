import 'package:flutter/material.dart';

class TransformLayer extends StatelessWidget {

  final ValueNotifier<double> scale;
  final ValueNotifier<double> rotation;
  final Widget child;


  const TransformLayer({
    super.key,
    required this.scale,
    required this.rotation,
    required this.child
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
        valueListenable: scale,
        builder: (_, s,__){
          return ValueListenableBuilder<double>(
              valueListenable: rotation,
              builder: (_, r,__){
                return Transform(
                  alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..rotateZ(r)
                      ..scale(s),
                  child: child,
                );
              }
          );
        }
    );
  }
}

import 'package:flutter/material.dart';

class w_text_big extends StatelessWidget {
  final String name;
  final double font_Size;
  final Color color;
  final FontWeight fontWeight;
  final Color shadow_color;
  final double shadowwithOpacity;
  final double offset;
  final double blurRadius;

  const w_text_big({
    required this.name,
    required this.font_Size,
    required this.color,
    this.fontWeight = FontWeight.w700,
    this.shadow_color = Colors.grey,
    this.shadowwithOpacity = 0.5,
    this.offset = 2,
    this.blurRadius = 3,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
        name,
        style: TextStyle(
          fontSize: font_Size,
          color: color,
          fontFamily: 'InstrumentSans',
          fontWeight: fontWeight,
          shadows: [
            Shadow(
              color: shadow_color.withOpacity(shadowwithOpacity),
              offset: Offset(offset, offset),
              blurRadius: blurRadius,
            ),
          ],
        )
    );
  }
}
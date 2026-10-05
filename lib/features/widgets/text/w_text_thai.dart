import 'package:flutter/material.dart';

class w_text_thai extends StatelessWidget {
  final String name;
  final double font_Size;
  final Color color;
  final Color shadow_color;
  final FontWeight fontWeight;
  final double shadowwithOpacity;
  final double offset;
  final double blurRadius;

  const w_text_thai({
    required this.name,
    required this.font_Size,
    required this.color,
    this.shadow_color = Colors.grey,
    this.fontWeight = FontWeight.w500,
    this.shadowwithOpacity = 0.2,
    this.offset = 1,
    this.blurRadius = 2,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
        name,
        style: TextStyle(
          fontSize: font_Size,
          color: color,
          fontFamily: 'Mitr',
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
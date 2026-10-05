import 'package:flutter/material.dart';

class w_text_thai_notosansthai extends StatelessWidget {
  final String name;
  final double font_Size;
  final Color color;
  final Color shadow_color;
  final FontWeight fontWeight;
  final double shadowwithOpacity;
  final double offset;
  final double blurRadius;

  const w_text_thai_notosansthai({
    required this.name,
    required this.font_Size,
    this.color  = Colors.black,
    this.shadow_color = Colors.grey,
    this.fontWeight = FontWeight.w400,
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
          fontFamily: 'NotoSansThai',
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
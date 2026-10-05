import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Point_Title extends StatelessWidget {
  final String title;

  const Point_Title({
    required this.title
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: const Color(0xFF18181C),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'NotoSansThai',
            color: Color(0xFF18181C),
          ),
        ),
      ],
    );
  }
}
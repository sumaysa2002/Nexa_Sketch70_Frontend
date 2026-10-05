import 'package:flutter/material.dart';

extension SnackBarExtension on BuildContext {
  void showSnackBar({
    required String message,
    Color backgroundColor = const Color(0xFF212121),
    Color textColor = Colors.white,
  }) {
    ScaffoldMessenger.of(this).clearSnackBars();

    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.fixed,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        content: Text(
          message,
          style: TextStyle(
            fontFamily: 'Mitr',
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
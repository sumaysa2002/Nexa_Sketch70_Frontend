import 'package:flutter/foundation.dart';

class AppException implements Exception {
  final String message;

  AppException(this.message, [Object? debugInfo]) {
    if (debugInfo != null && kDebugMode) {
      debugPrint('[AppException] $message | debug: $debugInfo');
    }
  }

  @override
  String toString() => message;
}

/// แปลง error สำหรับโชว์ user
String safeErrorMessage(
    Object error, {
      String fallback = 'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง',
    }) {
  if (kDebugMode) {
    debugPrint('[safeErrorMessage] raw: $error (${error.runtimeType})');
  }

  if (error is AppException) return error.message;
  if (error is String) return error;

  return fallback;
}
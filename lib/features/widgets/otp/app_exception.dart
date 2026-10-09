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

/// ขอ OTP ถี่/ครบโควตา (429) + ต้องรออีกกี่วินาที (มาจาก backend)
class OtpRateLimitException extends AppException {
  final int retryAfterSeconds;

  OtpRateLimitException(super.message, {required this.retryAfterSeconds});
}

/// ยืนยัน OTP ไม่ผ่าน + จำนวนครั้งที่กรอกไปแล้ว (มาจาก backend)
class OtpVerifyException extends AppException {
  final int attempts;
  final int maxAttempts;

  OtpVerifyException(
      super.message, {
        required this.attempts,
        required this.maxAttempts,
      });
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
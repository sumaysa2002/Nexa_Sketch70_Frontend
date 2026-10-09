import 'package:flutter/material.dart';

/// รหัสอ้างอิง Ref ของ OTP (จาก backend)
String otpRefCode(String hash) =>
    (hash.length >= 6 ? hash.substring(0, 6) : hash).toUpperCase();

/// กล่องแสดง Ref + จำนวนครั้งที่กรอกไปแล้ว + หมายเหตุ
class OtpStatusPanel extends StatelessWidget {
  final String hash;
  final int attempts;
  final int maxAttempts;

  const OtpStatusPanel({
    super.key,
    required this.hash,
    required this.attempts,
    this.maxAttempts = 5,
  });

  @override
  Widget build(BuildContext context) {
    final locked = attempts >= maxAttempts;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: locked
            ? Colors.red.shade50
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: locked
              ? Colors.red.shade200
              : Colors.grey.shade400,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// Ref
          Row(
            children: [
              Text(
                'รหัสอ้างอิง (Ref)',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.7,
                  fontFamily: 'NotoSansThai',
                  color: Color(0xFF707078),
                ),
              ),

              const Spacer(),

              Text(
                otpRefCode(hash),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  fontFamily: 'NotoSansThai',
                  color: Color(0xFF24252A),
                ),
              ),

            ],
          ),

          const SizedBox(height: 8),

          /// จำนวนครั้งที่กรอก
          Row(
            children: [
              Text(
                'กรอกไปแล้ว',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.7,
                  fontFamily: 'NotoSansThai',
                  color: Color(0xFF707078),
                ),
              ),

              const Spacer(),

              Text(
                '$attempts / $maxAttempts ครั้ง',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'NotoSansThai',
                  color: Color(0xFF24252A),
                ),
              ),

            ],
          ),

          const SizedBox(height: 10),

          /// หมายเหตุ
          Text(
            locked
                ? 'กรอกรหัสผิดครบ $maxAttempts ครั้งแล้ว กรุณากด Resend OTP เพื่อขอรหัสใหม่'
                : 'หมายเหตุ: โปรดตรวจสอบว่า Ref ตรงกับในอีเมล (กรอกรหัสผิดได้ไม่เกิน $maxAttempts ครั้ง '
                'หากครบกรุณาขอรหัสใหม่)',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              fontFamily: 'NotoSansThai',
              color: locked
                  ? Colors.red
                  : Color(0xFF707078),
            ),
          ),
        ],
      ),
    );
  }
}
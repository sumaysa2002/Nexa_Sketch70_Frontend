import 'dart:typed_data';

class SignupPayload {
  final String first_name;
  final String last_name;
  final String phone;
  final String email;
  final String password;

  final String? title_name;
  final String? job_position;
  final String? job_level;
  final String? job_office;
  final String? job_department;

  final Uint8List? profile_image;

  SignupPayload({
    required this.first_name,
    required this.last_name,
    required this.phone,
    required this.email,
    required this.password,
    this.title_name,
    this.job_position,
    this.job_level,
    this.job_office,
    this.job_department,
    this.profile_image,
  });

  // ── toMap ──────────────────────────────────────────────
  Map<String, dynamic> toMap() {
    return {
      'first_name': first_name,
      'last_name': last_name,
      'phone': phone,
      'email': email,
      'password': password,
      'title_name': title_name,
      'job_position': job_position,
      'job_level': job_level,
      'job_office': job_office,
      'job_department': job_department,
      // ส่ง profile_image แยกเป็น Multipart File
    };
  }
}


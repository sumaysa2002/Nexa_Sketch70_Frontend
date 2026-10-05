import 'dart:convert';

class UserModel {
  final int id;
  final String titleName;
  final String firstName;
  final String lastName;
  final String phone;
  final String email;
  final String? profileImg;
  final String? signature;
  final String? jobPosition;
  final String? jobLevel;
  final String? jobOffice;
  final String? jobDepartment;
  final String? admin;
  final String? status;
  final String token;

  UserModel({
    required this.id,
    required this.titleName,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
    this.profileImg,
    this.signature,
    this.jobPosition,
    this.jobLevel,
    this.jobOffice,
    this.jobDepartment,
    this.admin,
    this.status,
    required this.token,
  });

  // สำหรับดึงชื่อเต็มของ User
  String get fullName => '$titleName $firstName $lastName';

  // ── copyWith ──────────────────────────────────────────────
  UserModel copyWith({
    int? id,
    String? titleName,
    String? firstName,
    String? lastName,
    String? phone,
    String? email,
    String? profileImg,
    String? signature,
    String? jobPosition,
    String? jobLevel,
    String? jobOffice,
    String? jobDepartment,
    String? admin,
    String? status,
    String? token,
  }) {
    return UserModel(
      id:            id ?? this.id,
      titleName:     titleName ?? this.titleName,
      firstName:     firstName ?? this.firstName,
      lastName:      lastName ?? this.lastName,
      phone:         phone ?? this.phone,
      email:         email ?? this.email,
      profileImg:    profileImg ?? this.profileImg,
      signature:     signature ?? this.signature,
      jobPosition:   jobPosition ?? this.jobPosition,
      jobLevel:      jobLevel ?? this.jobLevel,
      jobOffice:     jobOffice ?? this.jobOffice,
      jobDepartment: jobDepartment ?? this.jobDepartment,
      admin:         admin ?? this.admin,
      status:        status ?? this.status,
      token:         token ?? this.token,
    );
  }

  // ── toMap ──────────────────────────────────────
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title_name': titleName,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'email': email,
      'profile_img': profileImg,
      'signature': signature,
      'job_position': jobPosition,
      'job_level': jobLevel,
      'job_office': jobOffice,
      'job_department': jobDepartment,
      'admin': admin,
      'status': status,
      'token': token,
    };
  }

  // ── fromMap ──────────────────────────────────────
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id']?.toInt() ?? 0,
      titleName: map['title_name'] ?? '',
      firstName: map['first_name'] ?? '',
      lastName: map['last_name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      profileImg: map['profile_img'],
      signature: map['signature'],
      jobPosition: map['job_position'],
      jobLevel: map['job_level'],
      jobOffice: map['job_office'],
      jobDepartment: map['job_department'],
      admin: map['admin'],
      status: map['status'],
      token: map['token'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  // แสดงรูปแบบเบอร์ xxx - xxx - xxxx
  String get formattedPhone {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) return phone;

    return '${digits.substring(0,3)} - '
        '${digits.substring(3,6)} - '
        '${digits.substring(6)}';
  }

  // ── fromJson ────────────────────────────────────
  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(json.decode(source) as Map<String, dynamic>);

  // ── toString ──────────────────────────────────────────────
  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, fullName: $fullName, token: $token)';
  }

  // ── == ────────────────────────────────────────────────────
  @override
  bool operator ==(covariant UserModel other) {
    if (identical(this, other)) return true;
    return other.id == id && other.token == token;
  }

  // ── hashCode ──────────────────────────────────────────────
  @override
  int get hashCode => id.hashCode ^ token.hashCode;
}
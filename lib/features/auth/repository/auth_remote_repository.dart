import 'package:http/http.dart' as http;

import 'package:offline_gnss69_new/export.dart';

class AuthRemoteRepository {
  final spService = SpService();
  final authLocalRepository = AuthLocalRepository();

  /* ============================================================
    1) SIGNUP
  ============================================================ */
  /// ── เช็ค Email ซ้ำในระบบ ──────────────────────────────────────
  Future<bool> checkEmailExists({
    required String email,
  }) async {
    final res = await http.post(
      Uri.parse('${Constants.backendUri}/auth/signup/check_email'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
      }),
    );

    if (res.statusCode != 200) {
      throw 'ตรวจสอบอีเมลไม่สำเร็จ';
    }

    final data = jsonDecode(res.body);
    return data['exists'] as bool;
  }

  /// ── ส่งรหัส OTP ไปยัง email ──────────────────────────────────────
  Future<String> sendOtp({required String email}) async {
    final res = await http.post(
      Uri.parse('${Constants.backendUri}/auth/signup/send_otp'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'email': email}),
    );

    final data = jsonDecode(res.body);
    if (res.statusCode == 200) {
      return data['hash'];
    }
    throw data['message'] ?? 'ส่ง OTP ไม่สำเร็จ';
  }

  /// ── ตรวจสอบ OTP และ insert user เข้าฐานข้อมูล ──────────────────────────────────────
  Future<void> verifyAndRegister({
    required String otp,
    required String hash,
    required SignupPayload payload,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${Constants.backendUri}/auth/signup/verify_and_register'),
      );

      request.fields['otp'] = otp;
      request.fields['hash'] = hash;
      request.fields['payload'] = jsonEncode(payload.toMap());

      // ใส่รูปภาพ (ถ้ามี)
      if (payload.profile_image != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'profile_image',
            payload.profile_image!,
            filename: 'profile_pic.jpg', // ชื่อไฟล์สมมติ >> เดี๋ยว backend จะ rename
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }

      // ส่ง request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 201) {
        final errorData = jsonDecode(response.body);
        throw errorData['message'] ?? 'สมัครสมาชิกไม่สำเร็จ';
      }
    } catch (e) {
      throw AppException(safeErrorMessage(e, fallback: 'สมัครสมาชิกไม่สำเร็จ กรุณาลองใหม่อีกครั้ง'), e);
    }
  }



  /* ============================================================
    2) LOGIN
  ============================================================ */
  /// ── เช็ค email + password >> ส่ง OTP ไปที่ email ──────────────────────────────────────
  Future<Map<String, dynamic>> LoginUser({
    required String email,
    required String password,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('${Constants.backendUri}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 10)); // เพิ่ม timeout 10 วินาที

      if (res.statusCode != 200) {
        throw jsonDecode(res.body)['error'] ?? 'เกิดข้อผิดพลาดในการเข้าสู่ระบบ';
      }
      return jsonDecode(res.body);
    } catch (e) {
      throw AppException(safeErrorMessage(e, fallback: 'เกิดข้อผิดพลาดในการเข้าสู่ระบบ'), e);
    }
  }

  /// ── ตรวจสอบ OTP (Login) ──────────────────────────────────────
  Future<UserModel> verifyLoginOtp({
    required String email,
    required String otp,
    required String hash,
  }) async {
    final res = await http.post(
      Uri.parse('${Constants.backendUri}/auth/login/verify_otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'otp': otp,
        'hash': hash,
      }),
    );

    if (res.statusCode != 200) {
      throw jsonDecode(res.body)['message'] ?? 'รหัส OTP ไม่ถูกต้องหรือหมดอายุ';
    }
    return UserModel.fromJson(res.body);
  }

  /// ── Reset Password ผ่าน Email >> ยืนยัน OTP และเปลี่ยนรหัสผ่าน ──────────────────────
  Future<void> LoginResetPassword({
    required String email,
    required String otp,
    required String hash,
    required String newPassword,
  }) async {
    final res = await http.post(
      Uri.parse('${Constants.backendUri}/auth/login/reset_password/verify_and_reset'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'otp': otp,
        'hash': hash,
        'new_password': newPassword,
      }),
    );

    if (res.statusCode != 200) {
      final data = jsonDecode(res.body);
      throw data['message'] ?? 'เปลี่ยนรหัสผ่านไม่สำเร็จ';
    }
  }


  /* ============================================================
    3) ส่วนจัดการ User ที่กำลัง Login อยู่
  ============================================================ */
  /// ── เรียกข้อมูล User ที่กำลัง Login อยู่ ──────────────────────────────────────
  Future<UserModel?> getUserData() async {
    try {

      // อ่าน token
      final token = await spService.getToken();

      // ถ้าไม่มี token
      if (token == null) return null;

      // ส่ง token ไปตรวจสอบกับ backend
      final response = await http.get(
        Uri.parse('${Constants.backendUri}/auth/user_data'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': token,
        },
      ).timeout(const Duration(seconds: 10));

      if (kDebugMode) debugPrint("getUserData status: ${response.statusCode}");

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.body);
      }

      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('getUserData error: $e');
      return await authLocalRepository.getUser();
    }
  }

  /// ── Profile Edit >> update ข้อมูล User ──────────────────────────────────────
  Future<UserModel> updateUser({
    required String token,
    required String titleName,
    required String firstName,
    required String lastName,
    required String phone,
    String? jobPosition,
    String? jobLevel,
    String? jobOffice,
    String? jobDepartment,
    Uint8List? profileImage,
    Uint8List? signatureImage,
  }) async {
    var request = http.MultipartRequest(
      'PUT',
      Uri.parse('${Constants.backendUri}/auth/update_user'),
    );
    request.headers['x-auth-token'] = token;
    request.fields['title_name']    = titleName;
    request.fields['first_name']    = firstName;
    request.fields['last_name']     = lastName;
    request.fields['phone']         = phone;
    if (jobPosition   != null) request.fields['job_position']   = jobPosition;
    if (jobLevel      != null) request.fields['job_level']      = jobLevel;
    if (jobOffice     != null) request.fields['job_office']     = jobOffice;
    if (jobDepartment != null) request.fields['job_department'] = jobDepartment;

    if (profileImage != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'profile_image',
        profileImage,
        filename: 'profile.jpg',
        contentType: MediaType('image', 'jpeg'),
      ));
    }
    if (signatureImage != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'signature_image',
        signatureImage,
        filename: 'signature.jpg',
        contentType: MediaType('image', 'jpeg'),
      ));
    }

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode != 200) {
      throw jsonDecode(res.body)['error'] ?? 'แก้ไขข้อมูลไม่สำเร็จ';
    }
    return UserModel.fromJson(res.body);
  }

  /// ── Reset Password (ยืนยันด้วยรหัสผ่านปัจจุบัน, ต้อง login) ──────────
  Future<void> ProfileResetPassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    final res = await http.put(
      Uri.parse('${Constants.backendUri}/auth/profile/reset_password'),
      headers: {
        'Content-Type': 'application/json',
        'x-auth-token': token,
      },
      body: jsonEncode({
        'current_password': currentPassword,
        'new_password': newPassword,
      }),
    );

    if (res.statusCode != 200) {
      final data = jsonDecode(res.body);
      throw data['message'] ?? data['error'] ?? 'เปลี่ยนรหัสผ่านไม่สำเร็จ';
    }
  }


  /* ============================================================
    4) User Management (admin)
  ============================================================ */
  /// ── เรียกข้อมูล User ที่ผ่านการอนุมัติแล้ว (ใช้ me.admin เป็นตัวกรอง ทั้ง admin และ user) ─────────────────────────
  Future<List<UserModel>> getAllUsers({required String token}) async {
    try {
      final res = await http.get(
        Uri.parse('${Constants.backendUri}/auth/all_approved_users'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
      );

      if (res.statusCode != 200) {
        throw jsonDecode(res.body)['error'] ?? 'ไม่สามารถดึงข้อมูลสมาชิกที่ผ่านการอนุมัติได้';
      }

      final List<dynamic> data = jsonDecode(res.body);
      final users = data.map((item) => UserModel(
        id:            item['id'] ?? 0,
        titleName:     item['title_name'] ?? '',
        firstName:     item['first_name'] ?? '',
        lastName:      item['last_name'] ?? '',
        phone:         item['phone'] ?? '',
        email:         item['email'] ?? '',
        profileImg:    item['profile_img'],
        jobPosition:   item['job_position'],
        jobLevel:      item['job_level'],
        jobOffice:     item['job_office'],
        jobDepartment: item['job_department'],
        admin:         item['admin'],
        status:        item['status'],
        signature:     item['signature'],
        token:         '',
      )).toList();

      // cache ลง SQLite
      await authLocalRepository.insertApprovedUsers(users);

      return users;

    } catch (e) {
      // ถ้า API fail >> ดึงจาก SQLite แทน
      final localUsers = await authLocalRepository.getApprovedUsers();
      if (localUsers.isNotEmpty) return localUsers;
      rethrow;
    }
  }

  /// ── ดึงข้อมูล user ตาม id ──────────
  Future<List<UserModel>> getUsersByIds({
    required String token,
    required List<int> ids,
  }) async {
    if (ids.isEmpty) return [];

    try {
      final idsParam = ids.toSet().join(',');
      final res = await http.get(
        Uri.parse('${Constants.backendUri}/auth/users_by_ids?ids=$idsParam'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
      );

      if (res.statusCode != 200) {
        throw jsonDecode(res.body)['error'] ?? 'ไม่สามารถดึงข้อมูลสมาชิกได้';
      }

      final List<dynamic> data = jsonDecode(res.body);
      return data.map((item) => _mapToUserModel(item)).toList();

    } catch (e) {
      final localUsers = await authLocalRepository.getApprovedUsers();
      return localUsers.where((u) => ids.contains(u.id)).toList();
    }
  }

  /// ── สำหรับ admin >> ค้นหา user ที่ยังไม่ได้รับการอนุมัติ ──────────────────
  Future<List<UserModel>> searchAllUsers({
    required String token,
    required String query,
  }) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final res = await http.get(
        Uri.parse('${Constants.backendUri}/auth/search_users?q=$encodedQuery'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
      );

      if (res.statusCode != 200) {
        throw jsonDecode(res.body)['error'] ?? 'ค้นหาสมาชิกไม่สำเร็จ';
      }

      final List<dynamic> data = jsonDecode(res.body);
      return data.map((item) => _mapToUserModel(item)).toList();

    } catch (e) {
      throw AppException(safeErrorMessage(e, fallback: 'ค้นหาสมาชิกไม่สำเร็จ'), e);
    }
  }


  /// ── สำหรับ admin >> อนุมัติ user ──────────────────────────────────────────────
  Future<void> ApprovedUser({
    required String token,
    required int userId,
  }) async {
    final res = await http.put(
      Uri.parse('${Constants.backendUri}/auth/approved_user/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'x-auth-token': token,
      },
    );

    if (res.statusCode != 200) {
      throw jsonDecode(res.body)['error'] ?? 'อนุมัติสมาชิกไม่สำเร็จ';
    }
  }

  /// ── สำหรับ admin >> ยกเลิกการอนุมัติ user ──────────────────────────────────────────────
  Future<void> RevokeApprovalUser({
    required String token,
    required int userId,
  }) async {
    final res = await http.put(
      Uri.parse('${Constants.backendUri}/auth/revoke_approval_user/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'x-auth-token': token,
      },
    );

    if (res.statusCode != 200) {
      throw jsonDecode(res.body)['error'] ?? 'ยกเลิกการอนุมัติสมาชิกไม่สำเร็จ';
    }
  }


  /// ── sync user ที่ค้างจาก offline ──────────────────────────────────────
  Future<void> syncPendingUser({required String token}) async {
    final pending = await authLocalRepository.getPendingUser();
    if (pending == null) return;

    // offline ไม่ได้เก็บ image bytes >> sync แค่ข้อมูล text
    final updated = await updateUser(
      token:         token,
      titleName:     pending.titleName,
      firstName:     pending.firstName,
      lastName:      pending.lastName,
      phone:         pending.phone,
      jobPosition:   pending.jobPosition,
      jobLevel:      pending.jobLevel,
      jobOffice:     pending.jobOffice,
      jobDepartment: pending.jobDepartment,
    );

    await authLocalRepository.updateUser(updated);
  }

  /// ── helper แปลง Map → UserModel ──────────────────────────────────────
  UserModel _mapToUserModel(Map<String, dynamic> item) {
    return UserModel(
      id:            item['id'] ?? 0,
      titleName:     item['title_name'] ?? '',
      firstName:     item['first_name'] ?? '',
      lastName:      item['last_name'] ?? '',
      phone:         item['phone'] ?? '',
      email:         item['email'] ?? '',
      profileImg:    item['profile_img'],
      jobPosition:   item['job_position'],
      jobLevel:      item['job_level'],
      jobOffice:     item['job_office'],
      jobDepartment: item['job_department'],
      admin:         item['admin'],
      status:        item['status'],
      signature:     item['signature'],
      token:         '',
    );
  }

}
import 'package:offline_gnss69_new/export.dart' hide safeErrorMessage;

import '../../widgets/otp/app_exception.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {

  AuthCubit() : super(AuthInitial());
  final authRemoteRepository = AuthRemoteRepository();
  final authLocalRepository = AuthLocalRepository();
  final spService = SpService(); // จดจำผู้ใช้


  /* ============================================================
    1) SIGNUP
  ============================================================ */
  /// ── เช็ค Email ซ้ำในระบบ ──────────────────────────────────────
  void signUpCheckEmail({required SignupPayload payload}) async {
    try {
      emit(AuthLoading());

      // เช็กเมล
      final exists = await authRemoteRepository.checkEmailExists(email: payload.email);

      if (exists) {
        emit(AuthError('มีอีเมลนี้ในระบบแล้ว'));
      } else {

        // เมลไม่ซ้ำ >> ส่ง OTP
        final hash = await authRemoteRepository.sendOtp(email: payload.email);

        // ส่ง payload และ hash ไปที่หน้า OTP
        emit(AuthSignupOtpSent(payload: payload, hash: hash));
      }
    } catch (e) {
      emit(AuthError(safeErrorMessage(e)));
    }
  }

  /// ── error จากการยืนยัน OTP → ถ้ามีจำนวนครั้งที่กรอก ให้ emit AuthOtpInvalid ──
  void _emitOtpError(Object e) {
    if (e is OtpVerifyException) {
      emit(AuthOtpInvalid(
        e.message,
        attempts: e.attempts,
        maxAttempts: e.maxAttempts,
      ));
    } else {
      emit(AuthError(safeErrorMessage(e)));
    }
  }

  /// ── ยืนยัน OTP ──────────────────────────────────────
  void verifyOtp({
    required String otp,
    required String hash,
    required SignupPayload payload,
  }) async {
    try {
      emit(AuthLoading());
      await authRemoteRepository.verifyAndRegister(
        otp: otp,
        hash: hash,
        payload: payload,
      );
      emit(AuthSignupSuccess());
    } catch (e) {
      _emitOtpError(e);
    }
  }

  /// ── ฟังก์ชันสำหรับส่ง OTP ซ้ำ ──────────────────────────────────────
  Future<void> resendOtp(
      String email, {
        String purpose = 'signup',
        String? previousHash,
      }) async {
    emit(AuthLoading());
    try {
      final hash = await authRemoteRepository.sendOtp(
        email: email,
        purpose: purpose,
        previousHash: previousHash,
      );
      emit(AuthResendOtpSuccess(hash: hash));
    } on OtpRateLimitException catch (e) {
      emit(AuthOtpRateLimited(e.message, retryAfterSeconds: e.retryAfterSeconds));
    } catch (e) {
      emit(AuthError(safeErrorMessage(e)));
    }
  }



  /* ============================================================
    2) LOGIN
  ============================================================ */
  /// ── เช็ค email + password >> ส่ง OTP ไปที่ email ──────────────────────────────────────
  void login({required String email, required String password}) async {
    try {
      emit(AuthLoading());

      final data = await authRemoteRepository.LoginUser(email: email, password: password);

      if (data != null && data['tempUser'] != null) {
        final tempUser = UserModel.fromMap(data['tempUser']);
        final hash = data['hash'];
        emit(AuthLoginOtpSent(hash: hash, tempUser: tempUser));
      } else {
        emit(AuthError('เกิดข้อผิดพลาดในการเข้าสู่ระบบ'));
      }
    } catch (e) {
      emit(AuthError(safeErrorMessage(e)));
    }
  }

  /// ── ตรวจสอบ OTP (Login) ──────────────────────────────────────
  void verifyLoginOtp({
    required String otp,
    required String hash,
    required UserModel tempUser,
  }) async {
    try {
      emit(AuthLoading());

      // ยืนยัน OTP กับ Backend
      final userModel = await authRemoteRepository.verifyLoginOtp(
        email: tempUser.email,
        otp: otp,
        hash: hash,
        //userId: tempUser.id,
      );

      // ตรวจสอบ token และบันทึก
      if (userModel.token.isNotEmpty) {
        await spService.setToken(userModel.token);
      }

      // เก็บข้อมูล User
      await authLocalRepository.insertUser(userModel);

      // Login สำเร็จ (บันทึกลง SQLite)
      emit(AuthLoggedIn(userModel));
    } catch (e) {
      _emitOtpError(e);
    }
  }

  /// ── Reset Password ผ่าน Email >> ยืนยัน OTP และเปลี่ยนรหัสผ่าน ──────────────────────
  void resetPasswordWithEmail({
    required String email,
    required String newPassword,
  }) async {
    try {
      emit(AuthLoading());

      final exists = await authRemoteRepository.checkEmailExists(email: email);

      if (!exists) {
        emit(AuthError('กรุณาตรวจสอบ Email'));
        return;
      }

      final hash = await authRemoteRepository.sendOtp(
        email: email,
        purpose: 'reset_password',
      );

      emit(AuthResetPasswordOtpSent(
        email: email,
        newPassword: newPassword,
        hash: hash,
      ));
    } catch (e) {
      emit(AuthError(safeErrorMessage(e)));
    }
  }

  /// ── ยืนยัน OTP และเปลี่ยนรหัสผ่าน ────────────────────────────────────
  void verifyResetPasswordOtp({
    required String otp,
    required String hash,
    required String email,
    required String newPassword,
  }) async {
    try {
      emit(AuthLoading());
      await authRemoteRepository.LoginResetPassword(
        email: email,
        otp: otp,
        hash: hash,
        newPassword: newPassword,
      );
      emit(AuthResetPasswordSuccess());
    } catch (e) {
      _emitOtpError(e);
    }
  }



  /* ============================================================
    3) ส่วนจัดการ User ที่กำลัง Login อยู่
  ============================================================ */
  /// ── เรียกข้อมูล User ที่กำลัง Login อยู่ ────────────────────────────
  void getUserData() async {
    try {
      emit(AuthLoading());

      // ดึง Token
      final token = await spService.getToken();


      // ไม่มี Token >> ให้ไปหน้า Login
      if (token == null || token.isEmpty) {
        emit(AuthInitial());
        return;
      }

      // มี Token >> Token ยังใช้ได้มั้ย (Token Validation)
      final userModel = await authRemoteRepository.getUserData();

      // Token ใช้ได้ >> ไปหน้า Home
      if (userModel != null) {
        await authLocalRepository.insertUser(userModel);
        emit(AuthLoggedIn(userModel));
      } else {
        emit(AuthInitial());
      }
    } catch (e) {
      emit(AuthInitial());
    }
  }

  /// ── Profile Edit >> update ข้อมูล User ──────────────────────────────────────
  Future<void> updateUserProfile({
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

    // ดึง currentUser ก่อน emit AuthLoading
    final currentUser = (state is AuthLoggedIn)
        ? (state as AuthLoggedIn).userModel
        : null;
    if (currentUser == null) return;

    emit(AuthLoading());

    try {
      final updatedUser = await authRemoteRepository.updateUser(
        token: token,
        titleName: titleName,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        jobPosition: jobPosition,
        jobLevel: jobLevel,
        jobOffice: jobOffice,
        jobDepartment: jobDepartment,
        profileImage: profileImage,
        signatureImage: signatureImage,
      );
      await authLocalRepository.updateUser(updatedUser);

      emit(UpdateUserSuccess(updatedUser));
      emit(AuthLoggedIn(updatedUser));

    } catch (e) {
      if (kDebugMode) debugPrint('updateUserProfile error: $e');
      emit(AuthLoggedIn(currentUser));
      emit(UpdateUserOfflineError());
      emit(AuthLoggedIn(currentUser));
    }
  }

  /// ── Reset Password (ยืนยันด้วยรหัสผ่านปัจจุบัน, ต้อง login) ──────────
  Future<void> resetPasswordWithCurrentPassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    final currentUser = (state is AuthLoggedIn)
        ? (state as AuthLoggedIn).userModel
        : null;
    if (currentUser == null) return;

    emit(AuthLoading());

    try {
      await authRemoteRepository.ProfileResetPassword(
        token:            token,
        currentPassword:  currentPassword,
        newPassword:      newPassword,
      );

      emit(ResetPasswordSuccess());
      emit(AuthLoggedIn(currentUser));

    } catch (e) {
      emit(AuthLoggedIn(currentUser));
      emit(AuthError(safeErrorMessage(e)));
      emit(AuthLoggedIn(currentUser));
    }
  }

  /// ── logout ──────────────────────────────────────
  Future<void> logout() async {
    try {

      // ลบ Token
      await spService.setToken("");

      // ลบข้อมูล User ใน SQLite
      await authLocalRepository.deleteUser();

      // ล้าง taskLocal
      final taskLocal = TaskLocalRepository();
      await taskLocal.clearAll();

      emit(AuthInitial());
    } catch (e) {
      emit(AuthError(safeErrorMessage(e, fallback: 'ออกจากระบบไม่สำเร็จ กรุณาลองใหม่อีกครั้ง')));
    }
  }



  /* ============================================================
    4) User Management (admin)
  ============================================================ */
  /// ── เรียกข้อมูล User ที่ผ่านการอนุมัติแล้ว (ใช้ me.admin เป็นตัวกรอง ทั้ง admin และ user) ───────────────────
  Future<void> loadAllUsers({required String token}) async {
    try {
      emit(AllUsersLoading());

      final users = await authRemoteRepository.getAllUsers(token: token);
      emit(AllUsersLoaded(users));

    } catch (e) {
      final local = await authLocalRepository.getApprovedUsers();
      if (local.isNotEmpty) {
        emit(AllUsersLoaded(local));
      } else {
        emit(AllUsersError(safeErrorMessage(e)));
      }
    }
  }

  /// ── สำหรับ admin >> ค้นหา user ที่ยังไม่ได้รับการอนุมัติ ──────────────────
  Future<void> searchAllUsers({
    required String token,
    required String query,
  }) async {
    try {
      emit(AllUsersLoading());

      final users = await authRemoteRepository.searchAllUsers(
        token: token,
        query: query,
      );
      emit(SearchUsersLoaded(users));

    } catch (e) {
      emit(AllUsersError(safeErrorMessage(e)));
    }
  }

  /// ── สำหรับ admin >> อนุมัติ user ──────────────────────────────────────────────
  Future<void> ApprovedUserToGroup({
    required String token,
    required UserModel user,
  }) async {
    try {
      emit(AllUsersLoading());

      await authRemoteRepository.ApprovedUser(
        token:  token,
        userId: user.id,
      );

      emit(UserApproved(user));

    } catch (e) {
      emit(AllUsersError(safeErrorMessage(e)));
    }
  }

  /// ── สำหรับ admin >> ยกเลิกการอนุมัติ user ─────────────────────────
  Future<void> RevokeApprovalUserFromGroup({
    required String token,
    required int userId,
  }) async {
    try {
      emit(AllUsersLoading());

      await authRemoteRepository.RevokeApprovalUser(
        token:  token,
        userId: userId,
      );

      emit(UserApprovalRevoked(userId));

    } catch (e) {
      emit(AllUsersError(safeErrorMessage(e)));
    }
  }



  /// ── sync user ที่ค้างจาก offline ──────────────────────────────────────
  Future<void> syncPendingUser({required String token}) async {
    await authRemoteRepository.syncPendingUser(token: token);
  }


}


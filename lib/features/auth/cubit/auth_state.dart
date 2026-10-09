part of 'auth_cubit.dart';

sealed class AuthState {}

final class AuthInitial extends AuthState {}

final class AuthLoading extends AuthState {}

final class AuthError extends AuthState {
  final String error;
  AuthError(this.error);
}

/// ขอ OTP ไม่ได้เพราะครบโควตา → หน้า OTP ล็อกปุ่ม Resend ตามเวลาที่ต้องรอ
final class AuthOtpRateLimited extends AuthError {
  final int retryAfterSeconds;
  AuthOtpRateLimited(super.error, {required this.retryAfterSeconds});
}

/// ยืนยัน OTP ไม่ผ่าน (มีจำนวนครั้งที่กรอกไปแล้ว)
final class AuthOtpInvalid extends AuthError {
  final int attempts;
  final int maxAttempts;
  AuthOtpInvalid(super.error, {required this.attempts, required this.maxAttempts});

  bool get isLocked => attempts >= maxAttempts;
}

/* ============================================================
    1) SIGNUP
============================================================ */
/// SignUp
final class AuthSignUp extends AuthState {
  final SignupPayload payload;
  AuthSignUp(this.payload);
}

/// ส่ง OTP SignUp
final class AuthSignupOtpSent extends AuthState {
  final SignupPayload payload;
  final String hash;
  AuthSignupOtpSent({required this.payload, required this.hash});
}

/// Resend OTP
class AuthResendOtpSuccess extends AuthState {
  final String hash;
  AuthResendOtpSuccess({required this.hash});
}

/// SignUp สำเร็จ
final class AuthSignupSuccess extends AuthState {}


/* ============================================================
    2) LOGIN
============================================================ */
/// LOGIN
final class AuthLoggedIn extends AuthState {
  final UserModel userModel;
  AuthLoggedIn(this.userModel);
}

/// ส่ง OTP Login
final class AuthLoginOtpSent extends AuthState {
  final String hash;
  final UserModel tempUser;
  AuthLoginOtpSent({required this.hash, required this.tempUser});
}

/// Reset Password ผ่าน Email
final class AuthResetPasswordOtpSent extends AuthState {
  final String email;
  final String newPassword;
  final String hash;
  AuthResetPasswordOtpSent({
    required this.email,
    required this.newPassword,
    required this.hash,
  });
}

/// login -- เปลี่ยนรหัสผ่านสำเร็จ
final class AuthResetPasswordSuccess extends AuthState {}


/* ============================================================
    3) ส่วนจัดการ User ที่กำลัง Login อยู่
============================================================ */
/// update ข้อมูล User
final class UpdateUserSuccess extends AuthState {
  final UserModel userModel;
  UpdateUserSuccess(this.userModel);
}

/// Reset Password (ยืนยันด้วยรหัสผ่านปัจจุบัน, ต้อง login)
final class ResetPasswordSuccess extends AuthState {}

/// offline error
final class UpdateUserOfflineError extends AuthState {}


/* ============================================================
    4) User Management (admin)
============================================================ */
/// เรียกข้อมูล User ที่ผ่านการอนุมัติแล้ว (ใช้ me.admin เป็นตัวกรอง ทั้ง admin และ user)
final class AllUsersLoading extends AuthState {}

/// โหลด User ที่ผ่านการอนุมัติสำเร็จ
final class AllUsersLoaded extends AuthState {
  final List<UserModel> members;
  AllUsersLoaded(this.members);
}

/// ค้นหา user สำเร็จ
final class SearchUsersLoaded extends AuthState {
  final List<UserModel> users;
  SearchUsersLoaded(this.users);
}

/// อนุมัติ user สำเร็จ
final class UserApproved extends AuthState {
  final UserModel user;
  UserApproved(this.user);
}

/// ยกเลิกการอนุมัติ user สำเร็จ
final class UserApprovalRevoked extends AuthState {
  final int userId;
  UserApprovalRevoked(this.userId);
}

/// users error
final class AllUsersError extends AuthState {
  final String error;
  AllUsersError(this.error);
}

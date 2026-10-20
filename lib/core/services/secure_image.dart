import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:offline_gnss69_new/export.dart';

/// ── โหลดรูปจาก server แบบต้อง login ──────────────────────
class SecureImage {
  SecureImage._();

  /// token ปัจจุบัน
  static String? _token;
  static void setToken(String? token) =>
      _token = (token == null || token.isEmpty) ? null : token;

  /// header สำหรับ Image.network / NetworkImage / http.get
  static Map<String, String> get authHeaders =>
      _token == null ? const {} : {'x-auth-token': _token!};

  /// URL รูปของหมุดรังวัด >> GET /points/image/:project_id/:point_id/:filename
  static String pointUrl(int projectId, int pointId, String filename) =>
      '${Constants.backendUri}/points/image/$projectId/$pointId/${Uri.encodeComponent(filename)}';

  /// URL รูปโปรไฟล์ >> GET /auth/image/profile/:filename
  static String profileUrl(String? filename) =>
      '${Constants.backendUri}/auth/image/profile/${Uri.encodeComponent(filename ?? '')}';

  /// URL ลายเซ็น >> GET /auth/image/signature/:filename
  static String signatureUrl(String? filename) =>
      '${Constants.backendUri}/auth/image/signature/${Uri.encodeComponent(filename ?? '')}';

  /// header จาก AuthCubit ผ่าน context
  static Map<String, String> headers(BuildContext context) {
    final state = context.read<AuthCubit>().state;
    if (state is AuthLoggedIn) {
      setToken(state.userModel.token);
      return {'x-auth-token': state.userModel.token};
    }
    return authHeaders;
  }

  /// มี token อยู่แล้ว (เช่น export PDF)
  static Map<String, String> headersFromToken(String token) =>
      {'x-auth-token': token};
}
import 'package:http/http.dart' as http;
import 'package:nexa_sketch/export.dart';

/// แจ้งเตือน offline
class TrashOfflineException extends AppException {
  TrashOfflineException()
      : super('กรุณาตรวจสอบอินเทอร์เน็ตแล้วลองใหม่อีกครั้ง');
}

/// ── ประวัติการลบ / กู้คืน โครงการและหมุดรังวัด ──────────────────────
class TrashRemoteRepository {
  static const _timeout = Duration(seconds: 15);

  static Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'x-auth-token': token,
  };

  static bool _isOfflineError(Object e) =>
      e is SocketException ||
          e is TimeoutException ||
          e is HandshakeException ||
          e is http.ClientException;

  static String _errorFrom(http.Response res, String fallback) {
    try {
      final body = jsonDecode(res.body);
      if (body is Map && body['error'] is String) return body['error'] as String;
    } catch (_) {}
    return fallback;
  }

  /// ส่ง request + แปลง error การเชื่อมต่อ
  Future<http.Response> _send(Future<http.Response> Function() call) async {
    try {
      final res = await call().timeout(_timeout);
      if (res.statusCode == 502 || res.statusCode == 503 || res.statusCode == 504) {
        throw TrashOfflineException();
      }
      return res;
    } catch (e) {
      if (e is TrashOfflineException) rethrow;
      if (_isOfflineError(e)) throw TrashOfflineException();
      rethrow;
    }
  }

  /* ============================================================
    โครงการ
  ============================================================ */
  /// ── รายการโครงการที่ถูกลบ ──
  Future<List<DeletedProject>> getDeletedProjects({required String token}) async {
    final res = await _send(() => http.get(
      Uri.parse('${Constants.backendUri}/tasks/deleted_projects'),
      headers: _headers(token),
    ));

    if (res.statusCode != 200) {
      throw ServerException(res.statusCode, _errorFrom(res, 'ดึงประวัติการลบโครงการไม่สำเร็จ'));
    }

    final List<dynamic> data = jsonDecode(res.body);
    return data
        .map((e) => DeletedProject.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// ── หมุดภายในโครงการที่ถูกลบ ──
  Future<List<PointModel>> getPointsOfDeletedProject({
    required String token,
    required int projectId,
  }) async {
    final res = await _send(() => http.get(
      Uri.parse('${Constants.backendUri}/points/points/$projectId?include_deleted=1'),
      headers: _headers(token),
    ));

    if (res.statusCode != 200) {
      throw ServerException(res.statusCode, _errorFrom(res, 'ดึงข้อมูลหมุดรังวัดไม่สำเร็จ'));
    }

    final List<dynamic> data = jsonDecode(res.body);
    return data
        .map((e) => PointModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// ── กู้คืนโครงการ ──
  Future<void> restoreProject({required String token, required int projectId}) async {
    final res = await _send(() => http.post(
      Uri.parse('${Constants.backendUri}/tasks/restore_project/$projectId'),
      headers: _headers(token),
    ));

    if (res.statusCode != 200) {
      throw ServerException(res.statusCode, _errorFrom(res, 'กู้คืนโครงการไม่สำเร็จ'));
    }
  }

  /* ============================================================
    หมุดรังวัด
  ============================================================ */
  /// ── หมุดที่ถูกลบของโครงการ (ลบหมุด ไม่ลบโครงการ) ──
  Future<List<DeletedPoint>> getDeletedPoints({
    required String token,
    required int projectId,
  }) async {
    final res = await _send(() => http.get(
      Uri.parse('${Constants.backendUri}/points/deleted_point/$projectId'),
      headers: _headers(token),
    ));

    if (res.statusCode != 200) {
      throw ServerException(res.statusCode, _errorFrom(res, 'ดึงประวัติการลบหมุดรังวัดไม่สำเร็จ'));
    }

    final List<dynamic> data = jsonDecode(res.body);
    return data
        .map((e) => DeletedPoint.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// ── กู้คืนหมุดรังวัด ──
  Future<void> restorePoint({required String token, required int pointId}) async {
    final res = await _send(() => http.post(
      Uri.parse('${Constants.backendUri}/points/restore_point/$pointId'),
      headers: _headers(token),
    ));

    if (res.statusCode != 200) {
      throw ServerException(res.statusCode, _errorFrom(res, 'กู้คืนหมุดรังวัดไม่สำเร็จ'));
    }
  }



  /* ============================================================
    ลบถาวร (ก่อนครบ 30 วัน)
  ============================================================ */
  /// ── DELETE >> จำนวนรายการที่ถูกลบ ──
  Future<int> _purge(String path, String fallback, {required String token}) async {
    final res = await _send(() => http.delete(
      Uri.parse('${Constants.backendUri}$path'),
      headers: _headers(token),
    ));

    if (res.statusCode != 200) {
      throw ServerException(res.statusCode, _errorFrom(res, fallback));
    }

    try {
      final body = jsonDecode(res.body);
      if (body is Map && body['count'] is num) return (body['count'] as num).toInt();
    } catch (_) {}
    return 0;
  }

  /// ── ลบถาวรโครงการเดียว ──
  Future<int> purgeProject({required String token, required int projectId}) =>
      _purge('/tasks/purge_project/$projectId', 'ลบโครงการแบบถาวรไม่สำเร็จ', token: token);

  /// ── ลบถาวรโครงการทั้งหมดในประวัติการลบ ──
  Future<int> purgeAllProjects({required String token}) =>
      _purge('/tasks/purge_all_projects', 'ลบโครงการแบบถาวรไม่สำเร็จ', token: token);

  /// ── ลบถาวรหมุดรังวัดเดียว ──
  Future<int> purgePoint({required String token, required int pointId}) =>
      _purge('/points/purge_point/$pointId', 'ลบหมุดรังวัดแบบถาวรไม่สำเร็จ', token: token);

  /// ── ลบถาวรหมุดรังวัดทั้งหมดในประวัติการลบของโครงการ ──
  Future<int> purgeAllPoints({required String token, required int projectId}) =>
      _purge('/points/purge_all_points/$projectId', 'ลบหมุดรังวัดแบบถาวรไม่สำเร็จ', token: token);
}
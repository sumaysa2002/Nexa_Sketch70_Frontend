import 'package:offline_gnss69_new/export.dart';

class SpService {
  static const _tokenKey = 'x-auth-token';

  // AES-encrypted storage, backed by Android Keystore / iOS Keychain
  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// ── บันทึก Token (เข้ารหัส) ────────
  Future<void> setToken(String token) async {
    if (token.isEmpty) {
      await _secureStorage.delete(key: _tokenKey);
      return;
    }
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  /// ── อ่าน Token ────────
  Future<String?> getToken() async {
    final secureToken = await _secureStorage.read(key: _tokenKey);
    if (secureToken != null && secureToken.isNotEmpty) {
      return secureToken;
    }

    // ── migrate จาก SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final legacyToken = prefs.getString(_tokenKey);

    if (legacyToken != null && legacyToken.isNotEmpty) {
      await _secureStorage.write(key: _tokenKey, value: legacyToken);
      await prefs.remove(_tokenKey); // ลบ token เดิมออกจาก plaintext storage
      return legacyToken;
    }

    return null;
  }

  /// ── ลบ Token (logout) ────────
  Future<void> clearToken() async {
    await _secureStorage.delete(key: _tokenKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}
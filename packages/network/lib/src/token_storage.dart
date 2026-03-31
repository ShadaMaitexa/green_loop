import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Manages persistence of JWT access + refresh tokens.
/// 
/// - Mobile: Uses FlutterSecureStorage for encrypted storage.
/// - Web: Uses SharedPreferences (Browser LocalStorage) for reliability.
class TokenStorage {
  static const _accessKey = 'greenloop_access_token';
  static const _refreshKey = 'greenloop_refresh_token';

  final FlutterSecureStorage _secureStorage;
  SharedPreferences? _webStorage;

  TokenStorage({FlutterSecureStorage? storage})
      : _secureStorage = storage ?? const FlutterSecureStorage();

  Future<void> _initWeb() async {
    if (kIsWeb && _webStorage == null) {
      _webStorage = await SharedPreferences.getInstance();
    }
  }

  // ── Access token ──────────────────────────────────────────────────────────

  Future<String?> getAccessToken() async {
    if (kIsWeb) {
      await _initWeb();
      return _webStorage?.getString(_accessKey);
    }
    return _secureStorage.read(key: _accessKey);
  }

  Future<void> saveAccessToken(String token) async {
    if (kIsWeb) {
      await _initWeb();
      await _webStorage?.setString(_accessKey, token);
      return;
    }
    return _secureStorage.write(key: _accessKey, value: token);
  }

  Future<void> deleteAccessToken() async {
    if (kIsWeb) {
      await _initWeb();
      await _webStorage?.remove(_accessKey);
      return;
    }
    return _secureStorage.delete(key: _accessKey);
  }

  // ── Refresh token ─────────────────────────────────────────────────────────

  Future<String?> getRefreshToken() async {
    if (kIsWeb) {
      await _initWeb();
      return _webStorage?.getString(_refreshKey);
    }
    return _secureStorage.read(key: _refreshKey);
  }

  Future<void> saveRefreshToken(String token) async {
    if (kIsWeb) {
      await _initWeb();
      await _webStorage?.setString(_refreshKey, token);
      return;
    }
    return _secureStorage.write(key: _refreshKey, value: token);
  }

  Future<void> deleteRefreshToken() async {
    if (kIsWeb) {
      await _initWeb();
      await _webStorage?.remove(_refreshKey);
      return;
    }
    return _secureStorage.delete(key: _refreshKey);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await saveAccessToken(accessToken);
    await saveRefreshToken(refreshToken);
  }

  Future<void> clearAll() async {
    await deleteAccessToken();
    await deleteRefreshToken();
  }

  Future<bool> hasValidSession() async {
    final access = await getAccessToken();
    final refresh = await getRefreshToken();
    return access != null && access.isNotEmpty && 
           refresh != null && refresh.isNotEmpty;
  }
}

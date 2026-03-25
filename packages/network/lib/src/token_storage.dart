import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Manages secure persistence of JWT access + refresh tokens.
///
/// Tokens are stored in the OS keychain / keystore via flutter_secure_storage,
/// so they survive app restarts and are never written to shared-prefs in plain text.
class TokenStorage {
  static const _accessKey = 'greenloop_access_token';
  static const _refreshKey = 'greenloop_refresh_token';

  final FlutterSecureStorage _storage;

  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  // ── Access token ──────────────────────────────────────────────────────────

  Future<String?> getAccessToken() => _storage.read(key: _accessKey);

  Future<void> saveAccessToken(String token) =>
      _storage.write(key: _accessKey, value: token);

  Future<void> deleteAccessToken() => _storage.delete(key: _accessKey);

  // ── Refresh token ─────────────────────────────────────────────────────────

  Future<String?> getRefreshToken() => _storage.read(key: _refreshKey);

  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _refreshKey, value: token);

  Future<void> deleteRefreshToken() => _storage.delete(key: _refreshKey);

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Save both tokens at once (e.g. after login).
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      saveAccessToken(accessToken),
      saveRefreshToken(refreshToken),
    ]);
  }

  /// Wipe all stored tokens (e.g. on logout).
  Future<void> clearAll() async {
    await Future.wait([
      deleteAccessToken(),
      deleteRefreshToken(),
    ]);
  }

  /// Returns true only when both tokens are present.
  Future<bool> hasValidSession() async {
    final access = await getAccessToken();
    final refresh = await getRefreshToken();
    return access != null &&
        access.isNotEmpty &&
        refresh != null &&
        refresh.isNotEmpty;
  }
}

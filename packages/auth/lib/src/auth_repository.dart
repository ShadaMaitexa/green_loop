import 'package:network/network.dart';
import 'auth_user.dart';
import 'auth_exceptions.dart';

/// The central repository managing authentication requests and token persistence.
class AuthRepository {
  final ApiClient _apiClient;

  // The login endpoint based on usual Django+SimpleJWT+custom logic structure
  static const String _loginPath = '/api/auth/login/';
  // Assuming a reliable profile/me endpoint to fetch current user data
  static const String _profilePath = '/api/auth/profile/';

  AuthRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Authenticate with email/password and save JWT tokens.
  /// Uses [ApiClient.postPublic] to skip attaching an existing token.
  Future<AuthUser> loginWithEmail(String email, String password) async {
    try {
      final response = await _apiClient.postPublic(
        _loginPath,
        data: {
          'email': email,
          'password': password,
        },
      );

      final data = response.data;
      if (data == null || data['access'] == null || data['refresh'] == null) {
        throw const AuthException('Invalid server response format.');
      }

      final access = data['access'] as String;
      final refresh = data['refresh'] as String;

      await _apiClient.tokenStorage.saveTokens(
        accessToken: access,
        refreshToken: refresh,
      );

      // Return the nested user object directly if provided (Django Djoser/custom login).
      // Otherwise, fetch it.
      if (data['user'] != null) {
        return AuthUser.fromJson(data['user'] as Map<String, dynamic>);
      }

      return await getProfile();
    } on UnauthorizedException catch (_) {
      throw const InvalidCredentialsException();
    } on ApiException catch (e) {
      if (e.message.toLowerCase().contains('disabled')) {
        throw const AccountDisabledException();
      }
      throw AuthException(e.message);
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  /// Check if a valid session exists. Usually called on app startup.
  /// We attempt to fetch the profile to confirm the token is genuinely active.
  /// (The Network interceptor will handle auto-refresh if the access token expired).
  Future<AuthUser?> checkAuth() async {
    final hasSession = await _apiClient.tokenStorage.hasValidSession();
    if (!hasSession) return null;

    try {
      return await getProfile();
    } on UnauthorizedException {
      // Refresh token is also expired/invalid. The interceptor already cleared the storage.
      return null;
    } catch (_) {
      // If offline, we might want to return a cached user.
      // For this simplified logic, we just return null on failure,
      // or optionally throw a specific error.
      // If we assume a valid session exists, we can return a dummy user and load later.
      return null;
    }
  }

  /// Get current user profile details using the saved valid token.
  Future<AuthUser> getProfile() async {
    try {
      final response = await _apiClient.get(_profilePath);
      return AuthUser.fromJson(response.data as Map<String, dynamic>);
    } on ApiException catch (e) {
      throw AuthException(e.message);
    }
  }

  /// Wipes all tokens and effectively logs the user out.
  Future<void> logout() async {
    await _apiClient.tokenStorage.clearAll();
  }
}

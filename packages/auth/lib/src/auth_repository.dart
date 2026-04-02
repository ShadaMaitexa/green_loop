import 'package:network/network.dart';
import 'auth_user.dart';
import 'auth_exceptions.dart';
import 'package:data_models/data_models.dart';

/// The central repository managing authentication requests and token persistence.
class AuthRepository {
  final ApiClient _apiClient;

  static const String _otpSendPath = '/api/v1/auth/otp/request/';
  static const String _otpVerifyPath = '/api/v1/auth/otp/verify/';
  static const String _adminLoginPath = '/api/v1/auth/admin-login/';
  static const String _workerLoginPath = '/api/v1/auth/worker-login/';
  static const String _logoutPath = '/api/v1/auth/logout/';
  static const String _profilePath = '/api/v1/users/me/';
  static const String _wardsPath = '/api/v1/wards/';
  static const String _completeProfilePath = '/api/v1/users/me/';

  AuthRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Authenticate admin with email/password.
  Future<AuthUser> loginAdmin(String email, String password) async {
    try {
      final response = await _apiClient.postPublic(
        _adminLoginPath,
        data: {
          'email': email,
          'password': password,
        },
      );
      
      final data = response.data;
      if (data == null || data['access'] == null || data['refresh'] == null) {
        throw const AuthException('Invalid server response format.');
      }

      await _apiClient.tokenStorage.saveTokens(
        accessToken: data['access'] as String,
        refreshToken: data['refresh'] as String,
      );

      // We merge the user object with the outer response data to have access to registration_required 
      // and other meta-flags in AuthUser.fromJson.
      return AuthUser.fromJson({
        ...(data['user'] as Map? ?? {}),
        ...data,
      });
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

  /// Authenticate recycler/HKS worker with username/password.
  Future<AuthUser> loginWorker(String username, String password) async {
    try {
      final response = await _apiClient.postPublic(
        _workerLoginPath,
        data: {
          'username': username,
          'password': password,
        },
      );
      
      final data = response.data;
      if (data == null || data['access'] == null || data['refresh'] == null) {
        throw const AuthException('Invalid server response format.');
      }

      await _apiClient.tokenStorage.saveTokens(
        accessToken: data['access'] as String,
        refreshToken: data['refresh'] as String,
      );

      return AuthUser.fromJson({
        ...(data['user'] as Map? ?? {}),
        ...data,
      });
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

  /// Request OTP for a given email (User flow).
  Future<String?> requestOtp(String email) async {
    try {
      final response = await _apiClient.postPublic(
        _otpSendPath,
        data: {'email': email},
      );
      return response.data is Map ? response.data['otp']?.toString() : null;
    } on ApiException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  /// Verify OTP and save JWT tokens (Both User and Admin verify).
  Future<AuthUser> verifyOtp(String email, String otp) async {
    try {
      final response = await _apiClient.postPublic(
        _otpVerifyPath,
        data: {
          'email': email,
          'code': otp,
        },
      );

      final data = response.data;
      if (data == null || data['access'] == null || data['refresh'] == null) {
        throw const AuthException('Invalid server response format.');
      }

      await _apiClient.tokenStorage.saveTokens(
        accessToken: data['access'] as String,
        refreshToken: data['refresh'] as String,
      );

      return AuthUser.fromJson({
        ...(data['user'] as Map? ?? {}),
        ...data,
      });

    } on UnauthorizedException catch (_) {
      throw const InvalidCredentialsException();
    } on ApiException catch (e) {
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

  /// Fetch the list of available Municipal Wards.
  Future<List<Ward>> getWards() async {
    try {
      final response = await _apiClient.get(_wardsPath);
      final data = response.data;
      
      if (data is Map) {
        if (data['type'] == 'FeatureCollection') {
          final features = data['features'] as List? ?? [];
          return features.map((e) => Ward.fromJson(e as Map<String, dynamic>)).toList();
        }
        if (data['results'] is List) {
          final list = data['results'] as List;
          return list.map((e) => Ward.fromJson(e as Map<String, dynamic>)).toList();
        }
      }
      
      if (data is List) {
        return data.map((e) => Ward.fromJson(e as Map<String, dynamic>)).toList();
      }
      
      return [];
    } on ApiException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  /// Complete the resident profile with name and location.
  Future<AuthUser> completeProfile(ResidentProfile profile) async {
    try {
      final response = await _apiClient.post(
        _completeProfilePath,
        data: profile.toJson(),
      );
      // The server response should reflect the updated profile/user state.
      return AuthUser.fromJson(response.data as Map<String, dynamic>);
    } on UnauthorizedException {
      throw const AuthException('Session expired. Please log in again.');
    } on ApiException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw AuthException('Failed to connect to server. Please try again.');
    }
  }

  /// Wipes all tokens and effectively logs the user out.
  Future<void> logout() async {
    try {
      final refreshToken = await _apiClient.tokenStorage.getRefreshToken();
      if (refreshToken != null) {
        await _apiClient.post(_logoutPath, data: {'refresh': refreshToken});
      }
    } catch (_) {
      // Ignore server exceptions on logout, proceed to clear local tokens
    } finally {
      await _apiClient.tokenStorage.clearAll();
    }
  }

  /// Get current access token from storage.
  Future<String?> getAccessToken() async {
    return _apiClient.tokenStorage.getAccessToken();
  }
}

import 'package:flutter/foundation.dart';
import 'package:auth/src/auth_user.dart';
import 'package:data_models/data_models.dart';
import 'auth_repository.dart';

enum AuthStatus {
  initial,
  checking,
  authenticated,
  unauthenticated,
  loading,
  error,
  otpRequested,
}

/// The stateNotifier linking AuthRepository logic to UI state.
class AuthState extends ChangeNotifier {
  final AuthRepository _repository;

  AuthStatus _status = AuthStatus.initial;
  AuthUser? _user;
  String? _errorMessage;

  AuthState({required AuthRepository repository}) : _repository = repository;

  AuthStatus get status => _status;
  AuthUser? get user => _user;
  String? get errorMessage => _errorMessage;

  /// Check current active session (for app cold starts).
  Future<void> initialize() async {
    _setStatus(AuthStatus.checking);
    try {
      final user = await _repository.checkAuth();
      if (user != null) {
        _user = user;
        _setStatus(AuthStatus.authenticated);
      } else {
        _setStatus(AuthStatus.unauthenticated);
      }
    } catch (e) {
      _errorMessage = e.toString();
      _setStatus(AuthStatus.unauthenticated); // We still route to login on failure.
    }
  }

  /// Perform email & password login (Admin).
  Future<bool> loginAdmin(String email, String password) async {
    _setStatus(AuthStatus.loading);
    try {
      await _repository.loginAdmin(email, password);
      _setStatus(AuthStatus.otpRequested);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setStatus(AuthStatus.error);
      return false;
    }
  }

  /// Request OTP (User).
  Future<bool> requestOtp(String email) async {
    _setStatus(AuthStatus.loading);
    try {
      await _repository.requestOtp(email);
      _setStatus(AuthStatus.otpRequested);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setStatus(AuthStatus.error);
      return false;
    }
  }

  /// Verify OTP to finalize login.
  Future<bool> verifyOtp(String email, String otp) async {
    _setStatus(AuthStatus.loading);
    try {
      final user = await _repository.verifyOtp(email, otp);
      _user = user;
      _setStatus(AuthStatus.authenticated);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setStatus(AuthStatus.error);
      return false;
    }
  }

  /// Log the user out, erasing session records.
  Future<void> logout() async {
    _setStatus(AuthStatus.loading);
    await _repository.logout();
    _user = null;
    _setStatus(AuthStatus.unauthenticated);
  }

  /// Fetch wards list.
  Future<List<Ward>> getWards() async {
    return await _repository.getWards();
  }

  /// Complete profile and update user state.
  Future<bool> completeProfile(ResidentProfile profile) async {
    _setStatus(AuthStatus.loading);
    try {
      final updatedUser = await _repository.completeProfile(profile);
      _user = updatedUser;
      _setStatus(AuthStatus.authenticated);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setStatus(AuthStatus.error);
      return false;
    }
  }

  /// Helper to change state and signal UI.
  void _setStatus(AuthStatus status) {
    _status = status;
    notifyListeners();
  }
}

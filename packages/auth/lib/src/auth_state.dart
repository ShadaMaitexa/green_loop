import 'package:flutter/foundation.dart';
import 'auth_repository.dart';
import 'auth_user.dart';

enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  loading,
  error,
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
    _setStatus(AuthStatus.loading);
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

  /// Perform email & password login.
  Future<bool> login(String email, String password) async {
    _setStatus(AuthStatus.loading);
    try {
      final user = await _repository.loginWithEmail(email, password);
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

  /// Helper to change state and signal UI.
  void _setStatus(AuthStatus status) {
    _status = status;
    notifyListeners();
  }
}

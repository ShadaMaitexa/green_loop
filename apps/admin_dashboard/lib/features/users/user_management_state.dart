import 'package:flutter/foundation.dart';
import 'package:data_models/data_models.dart';
import 'user_management_service.dart';

class UserManagementState extends ChangeNotifier {
  final UserManagementService _service;

  List<PlatformUser> _users = [];
  bool _isLoading = false;
  String? _error;

  // Filters
  UserRole? _filterRole;
  String _searchQuery = '';
  int? _filterWardId;

  UserManagementState({required UserManagementService service}) : _service = service;

  List<PlatformUser> get users => _users;
  bool get isLoading => _isLoading;
  String? get error => _error;
  UserRole? get filterRole => _filterRole;
  String get searchQuery => _searchQuery;

  /// Load users from backend with current filters.
  Future<void> loadUsers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _users = await _service.getUsers(
        role: _filterRole?.toJson(),
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
        wardId: _filterWardId,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update search query and reload.
  void setSearchQuery(String query) {
    _searchQuery = query;
    loadUsers();
  }

  /// Update role filter and reload.
  void setRoleFilter(UserRole? role) {
    _filterRole = role;
    loadUsers();
  }

  /// Create a new user.
  Future<bool> createUser(Map<String, dynamic> userData) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.createUser(userData);
      await loadUsers();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggle user active status.
  Future<bool> toggleUserStatus(PlatformUser user) async {
    try {
      await _service.setUserStatus(user.id, !user.isActive);
      await loadUsers();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}

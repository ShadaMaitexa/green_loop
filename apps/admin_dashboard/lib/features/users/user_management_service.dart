import 'package:flutter/foundation.dart';
import 'package:network/network.dart';
import 'package:data_models/data_models.dart';

class UserManagementService {
  final ApiClient _apiClient;

  UserManagementService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Fetch users with optional filtering.
  Future<List<PlatformUser>> getUsers({
    String? role,
    String? searchQuery,
    int? wardId,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/v1/users/',
        queryParameters: {
          if (role != null) 'role': role,
          if (searchQuery != null) 'search': searchQuery,
          if (wardId != null) 'ward': wardId,
        },
      );
      final list = response.data as List? ?? [];
      return list.map((e) => PlatformUser.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      if (kDebugMode) {
        // More comprehensive Mock data for testing filtering/search
        final mockUsers = [
          const PlatformUser(id: '1', email: 'arathyrajeesh2@gmail.com', name: 'arathyrajeesh2', role: UserRole.resident, isActive: true),
          const PlatformUser(id: '2', email: 'arathyrajeesh050@example.com', name: 'arathyrajeesh050', role: UserRole.resident, isActive: true),
          const PlatformUser(id: '3', email: 'aswathy@gmail.com', name: 'Aswathy', role: UserRole.hksWorker, isActive: true),
          const PlatformUser(id: '4', email: 'amaya@gmail.com', name: 'amaya', role: UserRole.recycler, isActive: true),
          const PlatformUser(id: '5', email: 'user@example.com', name: 'user', role: UserRole.resident, isActive: true),
          const PlatformUser(id: '6', email: 'athy@gmail.com', name: 'arthy', role: UserRole.resident, isActive: true),
          const PlatformUser(id: '7', email: 'arathy2@gmail.com', name: 'arathy2', role: UserRole.resident, isActive: true),
          const PlatformUser(id: '8', email: 'admin@greenloop.app', name: 'Project Lead', role: UserRole.admin, isActive: true),
        ];

        return mockUsers.where((user) {
          bool matchesSearch = true;
          if (searchQuery != null && searchQuery.isNotEmpty) {
            final query = searchQuery.toLowerCase();
            matchesSearch = user.name.toLowerCase().contains(query) || user.email.toLowerCase().contains(query);
          }

          bool matchesRole = true;
          if (role != null) {
            // DataModels role toString/toJson check
            matchesRole = user.role.toJson().toLowerCase() == role.toLowerCase();
          }

          return matchesSearch && matchesRole;
        }).toList();
      }
      rethrow;
    }
  }

  /// Create a new user.
  Future<PlatformUser> createUser(Map<String, dynamic> userData) async {
    try {
      final response = await _apiClient.post('/api/v1/users/', data: userData);
      return PlatformUser.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Specialized worker/recycler creation with ward assignment.
  Future<PlatformUser> createWorker(Map<String, dynamic> userData) async {
    try {
      final response = await _apiClient.post('/api/v1/users/create-worker/', data: userData);
      return PlatformUser.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch details of a single user.
  Future<PlatformUser> getUserDetails(String id) async {
    try {
      final response = await _apiClient.get('/api/v1/users/$id/');
      return PlatformUser.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Full update of a user.
  Future<PlatformUser> updateUser(String id, Map<String, dynamic> userData) async {
    try {
      final response = await _apiClient.put('/api/v1/users/$id/', data: userData);
      return PlatformUser.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Partial update of a user.
  Future<PlatformUser> patchUser(String id, Map<String, dynamic> userData) async {
    try {
      final response = await _apiClient.patch('/api/v1/users/$id/', data: userData);
      return PlatformUser.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a user.
  Future<void> deleteUser(String id) async {
    try {
      await _apiClient.delete('/api/v1/users/$id/');
    } catch (e) {
      rethrow;
    }
  }

  /// Toggle user active status (Shortcut).
  Future<void> setUserStatus(String id, bool isActive) async {
    try {
      await _apiClient.patch('/api/v1/users/$id/', data: {'is_active': isActive});
    } catch (e) {
      rethrow;
    }
  }
}

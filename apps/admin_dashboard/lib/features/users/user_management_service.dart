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
          if (wardId != null) 'ward_id': wardId,
        },
      );
      final list = response.data as List;
      return list.map((e) => PlatformUser.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      rethrow;
    }
  }

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

  Future<PlatformUser> updateUser(String id, Map<String, dynamic> userData) async {
    try {
      final response = await _apiClient.patch('/api/v1/users/$id/', data: userData);
      return PlatformUser.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Toggle user active status.
  Future<void> setUserStatus(String id, bool isActive) async {
    try {
      await _apiClient.patch('/api/v1/users/$id/', data: {'is_active': isActive});
    } catch (e) {
      rethrow;
    }
  }
}

import 'package:network/network.dart';
import 'package:data_models/data_models.dart';

/// Repository for User management operations.
class UserRepository {
  final ApiClient _apiClient;

  static const String _usersPath = '/api/v1/users/';

  UserRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Fetch all users.
  Future<List<PlatformUser>> getUsers() async {
    try {
      final response = await _apiClient.get(_usersPath);
      final list = (response.data is Map ? (response.data['results'] as List?) : response.data as List?) ?? [];
      return list.map((e) => PlatformUser.fromJson(e as Map<String, dynamic>)).toList();
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Create a new user.
  Future<PlatformUser> createUser(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post(_usersPath, data: data);
      return PlatformUser.fromJson(response.data as Map<String, dynamic>);
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Fetch user details by ID.
  Future<PlatformUser> getUser(String id) async {
    try {
      final response = await _apiClient.get('$_usersPath$id/');
      return PlatformUser.fromJson(response.data as Map<String, dynamic>);
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Update user details.
  Future<PlatformUser> updateUser(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.patch('$_usersPath$id/', data: data);
      return PlatformUser.fromJson(response.data as Map<String, dynamic>);
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Delete a user.
  Future<void> deleteUser(String id) async {
    try {
      await _apiClient.delete('$_usersPath$id/');
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Special endpoint to create HKS workers.
  Future<PlatformUser> createWorker(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post('${_usersPath}create-worker/', data: data);
      return PlatformUser.fromJson(response.data as Map<String, dynamic>);
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Fetch own profile details.
  Future<PlatformUser> getMe() async {
    try {
      final response = await _apiClient.get('${_usersPath}me/');
      return PlatformUser.fromJson(response.data as Map<String, dynamic>);
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }
}

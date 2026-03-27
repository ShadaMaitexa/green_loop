import 'package:network/network.dart';
import 'package:data_models/data_models.dart';

class WardService {
  final ApiClient _apiClient;

  WardService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Fetch all wards with boundaries.
  Future<List<Ward>> getWards() async {
    try {
      final response = await _apiClient.get('/api/v1/admin/wards/');
      final list = response.data as List;
      return list.map((e) => Ward.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Create a new ward with boundary.
  Future<Ward> createWard(Map<String, dynamic> wardData) async {
    try {
      final response = await _apiClient.post('/api/v1/admin/wards/', data: wardData);
      return Ward.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Update an existing ward.
  Future<Ward> updateWard(int id, Map<String, dynamic> wardData) async {
    try {
      final response = await _apiClient.patch('/api/v1/admin/wards/$id/', data: wardData);
      return Ward.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch workers assigned to a specific ward.
  Future<List<PlatformUser>> getWardWorkers(int wardId) async {
    try {
      final response = await _apiClient.get(
        '/api/v1/admin/users/',
        queryParameters: {
          'role': 'hks_worker',
          'ward_id': wardId,
        },
      );
      final list = response.data as List;
      return list.map((e) => PlatformUser.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch all HKS workers (useful for assignment dropdown).
  Future<List<PlatformUser>> getAllHksWorkers() async {
    try {
      final response = await _apiClient.get(
        '/api/v1/admin/users/',
        queryParameters: {'role': 'hks_worker'},
      );
      final list = response.data as List;
      return list.map((e) => PlatformUser.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Assign a worker to a ward.
  Future<void> assignWorker(String workerId, int wardId) async {
    try {
      await _apiClient.patch(
        '/api/v1/admin/users/$workerId/',
        data: {'ward_id': wardId},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Unassign a worker from a ward.
  Future<void> unassignWorker(String workerId) async {
    try {
      await _apiClient.patch(
        '/api/v1/admin/users/$workerId/',
        data: {'ward_id': null},
      );
    } catch (e) {
      rethrow;
    }
  }
}

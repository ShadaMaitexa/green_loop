import 'package:network/network.dart';
import 'package:data_models/data_models.dart';

class WardService {
  final ApiClient _apiClient;

  WardService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Fetch all wards with boundaries.
  /// API returns a GeoJSON FeatureCollection.
  Future<List<Ward>> getWards() async {
    try {
      final response = await _apiClient.get('/api/v1/wards/');
      final data = response.data;

      if (data is Map && data['type'] == 'FeatureCollection') {
        final features = data['features'] as List? ?? [];
        return features
            .map((e) => Ward.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (data is List) {
        return data
            .map((e) => Ward.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Create a new ward. Sends as GeoJSON Feature.
  Future<Ward> createWard(Map<String, dynamic> wardData) async {
    try {
      final response = await _apiClient.post(
        '/api/v1/wards/',
        data: wardData, // already in GeoJSON Feature format from WardState
      );
      return Ward.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Update an existing ward. Sends as GeoJSON Feature PATCH.
  Future<Ward> updateWard(int id, Map<String, dynamic> wardData) async {
    try {
      final response = await _apiClient.patch(
        '/api/v1/wards/$id/',
        data: wardData,
      );
      return Ward.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch workers assigned to a specific ward.
  /// API: GET /api/v1/wards/{id}/workers/
  Future<List<PlatformUser>> getWardWorkers(int wardId) async {
    try {
      final response = await _apiClient.get('/api/v1/wards/$wardId/workers/');
      final data = response.data;
      // May return FeatureCollection (ward) or a list of users
      if (data is List) {
        return data
            .map((e) => PlatformUser.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch all HKS workers.
  /// API: GET /api/v1/users/?role=HKS_WORKER
  Future<List<PlatformUser>> getAllHksWorkers() async {
    try {
      final response = await _apiClient.get(
        '/api/v1/users/',
        queryParameters: {'role': 'HKS_WORKER'},
      );
      final data = response.data;
      if (data is List) {
        return data
            .map((e) => PlatformUser.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Batch assign/unassign workers via POST /api/v1/wards/{id}/assign_workers/
  Future<void> assignWorker(String workerId, int wardId) async {
    try {
      await _apiClient.post(
        '/api/v1/wards/$wardId/assign_workers/',
        data: {
          'type': 'Feature',
          'geometry': null,
          'properties': {
            'worker_ids': [workerId],
            'action': 'assign',
          },
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Unassign a worker from a ward.
  Future<void> unassignWorker(String workerId) async {
    try {
      // Use user PATCH to clear ward assignment
      await _apiClient.patch(
        '/api/v1/users/$workerId/',
        data: {'ward': null},
      );
    } catch (e) {
      rethrow;
    }
  }
}

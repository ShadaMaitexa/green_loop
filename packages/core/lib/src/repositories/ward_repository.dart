import 'package:network/network.dart';
import 'package:data_models/data_models.dart';

/// Repository for Ward-related operations.
class WardRepository {
  final ApiClient _apiClient;

  static const String _wardsPath = '/api/v1/wards/';

  WardRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Fetch all wards.
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
      throw Exception(e.message);
    }
  }

  /// Create a new ward.
  Future<Ward> createWard(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post(_wardsPath, data: data);
      return Ward.fromJson(response.data as Map<String, dynamic>);
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Fetch ward details by ID.
  Future<Ward> getWard(int id) async {
    try {
      final response = await _apiClient.get('$_wardsPath$id/');
      return Ward.fromJson(response.data as Map<String, dynamic>);
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Update ward details.
  Future<Ward> updateWard(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.patch('$_wardsPath$id/', data: data);
      return Ward.fromJson(response.data as Map<String, dynamic>);
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Delete a ward.
  Future<void> deleteWard(int id) async {
    try {
      await _apiClient.delete('$_wardsPath$id/');
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Assign workers to a ward.
  Future<void> assignWorkers(int wardId, List<String> workerIds) async {
    try {
      await _apiClient.post('$_wardsPath$wardId/assign_workers/', data: {
        'worker_ids': workerIds,
      });
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Get ward statistics.
  Future<Map<String, dynamic>> getStats(int wardId) async {
    try {
      final response = await _apiClient.get('$_wardsPath$wardId/stats/');
      return response.data as Map<String, dynamic>;
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Get workers assigned to a ward.
  Future<List<PlatformUser>> getWorkers(int wardId) async {
    try {
      final response = await _apiClient.get('$_wardsPath$wardId/workers/');
      final list = response.data as List? ?? [];
      return list.map((e) => PlatformUser.fromJson(e as Map<String, dynamic>)).toList();
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Get ward summary.
  Future<Map<String, dynamic>> getSummary() async {
    try {
      final response = await _apiClient.get('${_wardsPath}summary/');
      return response.data as Map<String, dynamic>;
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }
}

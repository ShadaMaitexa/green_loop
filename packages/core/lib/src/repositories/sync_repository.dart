import 'package:network/network.dart';
import 'package:data_models/data_models.dart';

/// Repository for background data synchronization management.
class SyncRepository {
  final ApiClient _apiClient;

  static const String _syncPath = '/api/v1/sync/';

  SyncRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Fetch all sync queue items.
  Future<List<SyncQueue>> getSyncQueue() async {
    try {
      final response = await _apiClient.get(_syncPath);
      final list = response.data as List? ?? [];
      return list.map((e) => SyncQueue.fromJson(e as Map<String, dynamic>)).toList();
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Manually trigger a data upload/sync.
  Future<void> uploadSync() async {
    try {
      await _apiClient.post('${_syncPath}upload/');
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Get active worker locations for live tracking.
  Future<List<Map<String, dynamic>>> getActiveLocations() async {
    try {
      final response = await _apiClient.get('${_syncPath}active_locations/');
      return (response.data as List).cast<Map<String, dynamic>>();
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Prefetch metadata for offline use.
  Future<Map<String, dynamic>> prefetch() async {
    try {
      final response = await _apiClient.get('${_syncPath}prefetch/');
      return response.data as Map<String, dynamic>;
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }
}

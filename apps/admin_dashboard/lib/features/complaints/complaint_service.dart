import 'package:network/network.dart';
import 'package:data_models/data_models.dart';

class ComplaintService {
  final ApiClient _apiClient;

  ComplaintService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Fetch complaints with optional sorting and filtering.
  Future<List<ComplaintModel>> getComplaints({
    String sortBy = 'created_at',
    bool ascending = false,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/v1/complaints/',
        queryParameters: {
          'sort': sortBy,
          'order': ascending ? 'asc' : 'desc',
        },
      );
      final data = response.data;
      if (data is Map && data['type'] == 'FeatureCollection') {
        final features = data['features'] as List? ?? [];
        return features.map((e) => ComplaintModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      if (data is List) {
        return data.map((e) => ComplaintModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Create a new complaint.
  Future<ComplaintModel> createComplaint(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post('/api/v1/complaints/', data: data);
      return ComplaintModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch details of a single complaint.
  Future<ComplaintModel> getComplaintDetails(String id) async {
    try {
      final response = await _apiClient.get('/api/v1/complaints/$id/');
      return ComplaintModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Full update of a complaint.
  Future<ComplaintModel> updateComplaint(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put('/api/v1/complaints/$id/', data: data);
      return ComplaintModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Partial update of a complaint.
  Future<ComplaintModel> patchComplaint(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.patch('/api/v1/complaints/$id/', data: data);
      return ComplaintModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a complaint.
  Future<void> deleteComplaint(String id) async {
    try {
      await _apiClient.delete('/api/v1/complaints/$id/');
    } catch (e) {
      rethrow;
    }
  }

  /// Assign a complaint to a worker or staff.
  Future<ComplaintModel> assignComplaint(String id, String userId) async {
    try {
      final response = await _apiClient.post(
        '/api/v1/complaints/$id/assign/',
        data: {'worker_id': userId},
      );
      return ComplaintModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Update the status of a complaint (Shortcut via patch).
  Future<ComplaintModel> updateStatus(String id, ComplaintStatus status) async {
    try {
      final response = await _apiClient.patch(
        '/api/v1/complaints/$id/',
        data: {
          'properties': {'status': status.toJson()}
        },
      );
      return ComplaintModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch heatmap data (KMeans clustered hotspots).
  Future<List<Map<String, dynamic>>> getHeatmapData() async {
    try {
      final response = await _apiClient.get('/api/v1/complaints/heatmap/');
      if (response.data is List) {
        return (response.data as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch potential assignees (HKS workers and Admin staff).
  Future<List<PlatformUser>> getPotentialAssignees() async {
    try {
      final response = await _apiClient.get('/api/v1/users/', queryParameters: {
        'role__in': 'hks_worker,admin',
      });
      final list = response.data as List? ?? [];
      return list.map((e) => PlatformUser.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      rethrow;
    }
  }
}

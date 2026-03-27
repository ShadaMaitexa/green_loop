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
        '/api/v1/admin/complaints/',
        queryParameters: {
          'sort': sortBy,
          'order': ascending ? 'asc' : 'desc',
        },
      );
      final list = response.data as List;
      return list.map((e) => ComplaintModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Assign a complaint to a worker or staff.
  Future<ComplaintModel> assignComplaint(String id, String userId) async {
    try {
      final response = await _apiClient.patch(
        '/api/v1/admin/complaints/$id/',
        data: {'assigned_to': userId, 'status': 'assigned'},
      );
      return ComplaintModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Update the status of a complaint.
  Future<ComplaintModel> updateStatus(String id, ComplaintStatus status) async {
    try {
      final response = await _apiClient.patch(
        '/api/v1/admin/complaints/$id/',
        data: {'status': status.toJson()},
      );
      return ComplaintModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch heatmap data (KMeans clustered hotspots).
  Future<List<Map<String, dynamic>>> getHeatmapData() async {
    try {
      final response = await _apiClient.get('/api/v1/admin/complaints/heatmap/');
      return (response.data as List).cast<Map<String, dynamic>>();
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch potential assignees (HKS workers and Admin staff).
  Future<List<PlatformUser>> getPotentialAssignees() async {
    try {
      final response = await _apiClient.get('/api/v1/admin/users/', queryParameters: {
        'role__in': 'hks_worker,admin',
      });
      final list = response.data as List;
      return list.map((e) => PlatformUser.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      rethrow;
    }
  }
}

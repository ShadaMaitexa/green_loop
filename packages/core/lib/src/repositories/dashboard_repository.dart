import 'package:network/network.dart';
import 'package:data_models/data_models.dart';

/// Repository for Dashboard statistics and administrative overview.
class DashboardRepository {
  final ApiClient _apiClient;

  static const String _statsPath = '/api/v1/dashboard/stats/';

  DashboardRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Fetches system-wide administrative statistics.
  Future<DashboardStats> getStats() async {
    try {
      final response = await _apiClient.get(_statsPath);
      return DashboardStats.fromJson(response.data as Map<String, dynamic>);
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }
}

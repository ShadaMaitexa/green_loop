import 'package:network/network.dart';
import 'models/dashboard_stats.dart';

class DashboardService {
  final ApiClient _apiClient;

  DashboardService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Fetch dashboard stats with a given date range.
  Future<DashboardStats> getStats({String range = '7d'}) async {
    try {
      final response = await _apiClient.get(
        '/api/v1/admin/dashboard/stats/',
        queryParameters: {'range': range},
      );
      return DashboardStats.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }
}

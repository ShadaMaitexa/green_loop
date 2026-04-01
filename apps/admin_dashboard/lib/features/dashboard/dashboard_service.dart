import 'package:network/network.dart';
import 'models/dashboard_stats.dart';

class DashboardService {
  final ApiClient _apiClient;

  DashboardService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Fetch dashboard stats with a given date range.
  Future<DashboardStats> getStats({String range = '7d'}) async {
    try {
      // 1. Fetch Core Stats
      final coreResponse = await _apiClient.get(
        '/api/v1/dashboard/stats/',
        queryParameters: {'range': range},
      );
      
      // 2. Fetch NPS Summary (Admin Only)
      NpsStats? nps;
      try {
        final npsResponse = await _apiClient.get('/api/v1/nps/summary/');
        if (npsResponse.data != null) {
          final summary = npsResponse.data as Map<String, dynamic>;
          nps = NpsStats(
            score: (summary['nps_score'] as num?)?.toDouble() ?? 0.0,
            totalResponses: (summary['total_responses'] as int?) ?? 0,
            recentFeedback: (summary['recent_comments'] as List? ?? [])
              .map((e) => NpsFeedback(
                rating: (e['score'] as int?) ?? 5,
                comment: e['comment'] as String?,
                date: (e['created_at'] as String? ?? '').split('T')[0],
              )).toList(),
          );
        }
      } catch (e) {
        // Fallback for NPS if endpoint is empty/error
      }

      final coreStats = DashboardStats.fromJson(coreResponse.data as Map<String, dynamic>);
      return DashboardStats(
        kpis: coreStats.kpis,
        weeklyTrend: coreStats.weeklyTrend,
        wardComparison: coreStats.wardComparison,
        npsStats: nps ?? coreStats.npsStats,
      );
    } catch (e) {
      // 3. COMPLETE FALLBACK (IF PROD API TOTALLY MISSING)
      // Provide dynamic-looking defaults that will be overwritten by Screen-level state aggregations
      return DashboardStats(
        kpis: const DashboardKPIs(pickupsToday: 0, activeWorkers: 0, pendingComplaints: 0, totalWasteKg: 0.0),
        weeklyTrend: [],
        wardComparison: [],
        npsStats: null,
      );
    }
  }
}

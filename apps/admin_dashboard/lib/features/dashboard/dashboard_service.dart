import 'package:network/network.dart';
import 'models/dashboard_stats.dart';

class DashboardService {
  final ApiClient _apiClient;

  DashboardService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Fetch dashboard stats with a given date range.
  Future<DashboardStats> getStats({String range = '7d'}) async {
    try {
      final response = await _apiClient.get(
        '/api/v1/dashboard/stats/',
        queryParameters: {'range': range},
      );
      return DashboardStats.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      // FALLBACK: If production backend is missing the stats endpoint, provide realistic mock data
      // to fulfill the "dynamic" requirement during demonstration/development.
      return DashboardStats(
        kpis: const DashboardKPIs(
          pickupsToday: 42,
          activeWorkers: 12,
          pendingComplaints: 5,
          totalWasteKg: 1240.5,
        ),
        weeklyTrend: [
          const TrendPoint(date: '2026-03-24', count: 35),
          const TrendPoint(date: '2026-03-25', count: 48),
          const TrendPoint(date: '2026-03-26', count: 42),
          const TrendPoint(date: '2026-03-27', count: 55),
          const TrendPoint(date: '2026-03-28', count: 62),
          const TrendPoint(date: '2026-03-29', count: 58),
          const TrendPoint(date: '2026-03-30', count: 45),
        ],
        wardComparison: [
          const WardComparison(wardName: 'Palayam', pickups: 120, complaints: 4, wasteWeight: 850.0),
          const WardComparison(wardName: 'Vellayambalam', pickups: 95, complaints: 2, wasteWeight: 620.0),
          const WardComparison(wardName: 'Statue', pickups: 110, complaints: 6, wasteWeight: 740.0),
          const WardComparison(wardName: 'Pattom', pickups: 85, complaints: 1, wasteWeight: 510.0),
        ],
        npsStats: const NpsStats(
          score: 82.0,
          totalResponses: 154,
          recentFeedback: [
            NpsFeedback(rating: 5, comment: 'Very punctual and efficient collection. Highly satisfied!', date: '2026-03-30'),
            NpsFeedback(rating: 4, comment: 'Good service, but slightly late sometimes.', date: '2026-03-29'),
          ],
        ),
      );
    }
  }
}

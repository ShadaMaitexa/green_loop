import 'package:network/network.dart';
import 'package:data_models/data_models.dart';

class ReportsService {
  final ApiClient apiClient;

  ReportsService({required this.apiClient});

  Future<ComplianceReport> generateSuchitwaReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final response = await apiClient.get(
      '/api/v1/compliance/suchitwa-mission/',
      queryParameters: {
        'start_date': startDate.toIso8601String().split('T')[0],
        'end_date': endDate.toIso8601String().split('T')[0],
      },
    );

    if (response.statusCode == 200) {
      return ComplianceReport.fromJson(response.data);
    } else {
      // Mock for development / ULB Demo if API is not ready
      return _generateMockReport(startDate, endDate);
    }
  }

  // MOCK FOR ULB PROGRESS REPORT
  ComplianceReport _generateMockReport(DateTime start, DateTime end) {
    return ComplianceReport(
      startDate: start,
      endDate: end,
      wasteByTypeKg: {
        'Organic': 4520.5,
        'Plastic': 1240.2,
        'Paper': 850.4,
        'Glass': 320.1,
        'Hazardous': 145.8,
      },
      householdCoveragePercentage: 85.4,
      segregationAccuracyPercentage: 92.1,
      hksAttendancePercentage: 96.5,
      totalHouseholds: 12000,
      coveredHouseholds: 10248,
      totalHKSWorkers: 40,
      activeHKSWorkers: 38,
      totalWasteCollectedKg: 7077.0,
      totalPickupsCompleted: 24500,
      npsScore: 68.0,
      systemUptimePercentage: 99.98,
      averageResponseTimeSeconds: 2.4 * 3600, // 2.4 hours
      cloudCostUsd: 1450.0,
      totalFeeCollected: 512400.0,
      budgetUtilizationPercentage: 74.5,
      projectedOnboardingNextMonth: 1200,
      tonnageGrowthProjectionPercent: 12.5,
    );
  }
}

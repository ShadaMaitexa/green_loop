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
      throw Exception('Failed to generate report: ${response.statusCode}');
    }
  }
}

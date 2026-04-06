import 'package:network/network.dart';
import 'package:data_models/data_models.dart';

/// Repository for Administrative Reports and Category management.
class ReportRepository {
  final ApiClient _apiClient;

  static const String _reportsPath = '/api/v1/reports/';
  static const String _categoriesPath = '/api/v1/report-categories/';
  static const String _wardReportsPath = '/api/v1/ward-reports/';

  ReportRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Fetch all generated reports.
  Future<List<Report>> getReports() async {
    try {
      final response = await _apiClient.get(_reportsPath);
      final list = (response.data is Map ? response.data['results'] : response.data) as List? ?? [];
      return list.map((e) => Report.fromJson(e as Map<String, dynamic>)).toList();
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Trigger generation of a new report.
  Future<Report> generateReport(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post(_reportsPath, data: data);
      return Report.fromJson(response.data as Map<String, dynamic>);
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Fetch available report categories.
  Future<List<ReportCategory>> getCategories() async {
    try {
      final response = await _apiClient.get(_categoriesPath);
      final list = response.data as List? ?? [];
      return list.map((e) => ReportCategory.fromJson(e as Map<String, dynamic>)).toList();
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Fetch Ward Collection Reports (Summary of waste collected per ward).
  Future<List<WardCollectionReport>> getWardReports() async {
    try {
      final response = await _apiClient.get(_wardReportsPath);
      final list = (response.data is Map ? response.data['results'] : response.data) as List? ?? [];
      return list.map((e) => WardCollectionReport.fromJson(e as Map<String, dynamic>)).toList();
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }
}

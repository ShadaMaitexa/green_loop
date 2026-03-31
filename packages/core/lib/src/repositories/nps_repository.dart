import 'package:network/network.dart';
import 'package:data_models/data_models.dart';

/// Repository for handling NPS (Net Promoter Score) surveys.
class NPSRepository {
  final ApiClient _apiClient;

  static const String _statusPath = '/api/v1/nps/status/';
  static const String _submitPath = '/api/v1/nps/submit/';
  static const String _summaryPath = '/api/v1/nps/summary/';

  NPSRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Checks if the NPS survey should be shown to the resident.
  Future<bool> shouldShowSurvey() async {
    try {
      final response = await _apiClient.get(_statusPath);
      // Backend returns survey status (show/don't show)
      return response.data is Map ? response.data['show_survey'] == true : false;
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Submits a new NPS survey response.
  Future<bool> submitSurvey(NPSSurveySubmit request) async {
    try {
      await _apiClient.post(_submitPath, data: request.toJson());
      return true;
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Fetches the NPS score and feedback summary (Admin only).
  Future<NPSSummary> getNPSSummary() async {
    try {
      final response = await _apiClient.get(_summaryPath);
      return NPSSummary.fromJson(response.data as Map<String, dynamic>);
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }
}

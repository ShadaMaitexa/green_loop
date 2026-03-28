import 'package:network/network.dart';

class NpsService {
  final ApiClient _apiClient;

  NpsService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<bool> checkEligibility() async {
    try {
      final response = await _apiClient.get('/api/v1/nps/check-eligibility/');
      // Expected response: { "eligible": true }
      return response.data['eligible'] as bool? ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<void> submitNps({required int rating, String? comment}) async {
    try {
      await _apiClient.post(
        '/api/v1/nps/submit/',
        data: {
          'rating': rating,
          if (comment != null && comment.isNotEmpty) 'comment': comment,
        },
      );
    } catch (e) {
      rethrow;
    }
  }
}

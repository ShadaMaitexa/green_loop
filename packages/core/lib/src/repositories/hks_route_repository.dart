import 'package:network/network.dart';
import 'package:data_models/data_models.dart';

/// Repository for handling HKS worker-specific route and attendance data.
class HksRouteRepository {
  final ApiClient _apiClient;

  static const String _todayRoutePath = '/api/v1/hks/routes/today/';
  static const String _attendancePath = '/api/v1/hks/attendance/';

  HksRouteRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Fetches the assigned route for the logged-in worker for today.
  Future<HksRoute> getTodayRoute() async {
    try {
      final response = await _apiClient.get(_todayRoutePath);
      return HksRoute.fromJson(response.data as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        throw Exception('No route assigned for today');
      }
      throw Exception(e.message);
    }
  }

  /// Logs attendance with GPS validation and PPE proof.
  Future<void> logAttendance({
    required double latitude,
    required double longitude,
    required String ppePhotoUrl,
  }) async {
    try {
      await _apiClient.post(_attendancePath, data: {
        'latitude': latitude,
        'longitude': longitude,
        'ppe_photo_url': ppePhotoUrl,
      });
    } on ApiException catch (e) {
      // Re-throw if validation failed (ST_Within check on backend)
      throw Exception(e.message);
    }
  }
}

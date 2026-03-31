import 'package:network/network.dart';

class AttendanceService {
  final ApiClient _apiClient;

  AttendanceService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<Map<String, dynamic>>> getAttendance() async {
    try {
      final response = await _apiClient.get('/api/v1/attendance/');
      if (response.data is List) {
        return (response.data as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> submitAttendance(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post('/api/v1/attendance/', data: data);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }
}

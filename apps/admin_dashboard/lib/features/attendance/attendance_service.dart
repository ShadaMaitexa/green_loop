import 'package:network/network.dart';
import 'package:data_models/data_models.dart';

class AttendanceService {
  final ApiClient _apiClient;

  AttendanceService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Fetch all attendance records.
  Future<List<AttendanceRecord>> getAttendance() async {
    try {
      final response = await _apiClient.get('/api/v1/attendance/');
      final list = response.data as List? ?? [];
      return list.map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Create a new attendance record.
  Future<AttendanceRecord> submitAttendance(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post('/api/v1/attendance/', data: data);
      return AttendanceRecord.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch details of a single attendance record.
  Future<AttendanceRecord> getAttendanceDetails(String id) async {
    try {
      final response = await _apiClient.get('/api/v1/attendance/$id/');
      return AttendanceRecord.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Full update of an attendance record.
  Future<AttendanceRecord> updateAttendance(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put('/api/v1/attendance/$id/', data: data);
      return AttendanceRecord.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Partial update of an attendance record.
  Future<AttendanceRecord> patchAttendance(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.patch('/api/v1/attendance/$id/', data: data);
      return AttendanceRecord.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete an attendance record.
  Future<void> deleteAttendance(String id) async {
    try {
      await _apiClient.delete('/api/v1/attendance/$id/');
    } catch (e) {
      rethrow;
    }
  }
}

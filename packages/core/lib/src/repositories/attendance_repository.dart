import 'package:network/network.dart';
import 'package:data_models/data_models.dart';

/// Repository for HKS worker attendance operations.
class AttendanceRepository {
  final ApiClient _apiClient;

  static const String _attendancePath = '/api/v1/hks/attendance/';
  static const String _historyPath = '/api/v1/hks/attendance/history/';
  static const String _todayPath = '/api/v1/hks/attendance/today/';

  AttendanceRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Fetches today's attendance record (or null if not checked in yet).
  Future<AttendanceRecord?> getTodayAttendance() async {
    try {
      final response = await _apiClient.get(_todayPath);
      return AttendanceRecord.fromJson(response.data as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null; // Not checked in yet
      throw Exception(e.message);
    }
  }

  /// Submits worker check-in with selfie URL, GPS, and PPE status.
  Future<AttendanceRecord> checkIn({
    required String selfieUrl,
    required double latitude,
    required double longitude,
    required bool ppeConfirmed,
  }) async {
    try {
      final response = await _apiClient.post(_attendancePath, data: {
        'type': 'Feature',
        'geometry': {
          'type': 'Point',
          'coordinates': [longitude, latitude],
        },
        'properties': {
          'selfie_url': selfieUrl,
          'ppe_confirmed': ppeConfirmed,
          'status': 'PRESENT',
        },
      });
      return AttendanceRecord.fromJson(response.data as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.statusCode == 400) {
        throw Exception(e.message); // e.g. "Already checked in" or "Outside ward"
      }
      if (e.statusCode == 403) {
        throw Exception('You are outside your assigned ward boundary.');
      }
      throw Exception(e.message);
    }
  }

  /// Records end-of-day check-out.
  Future<AttendanceRecord> checkOut() async {
    try {
      final response = await _apiClient.patch(_attendancePath, data: {
        'properties': {
          'status': 'LOGGED_OUT',
          'checkout_time': DateTime.now().toIso8601String(),
        },
      });
      return AttendanceRecord.fromJson(response.data as Map<String, dynamic>);
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Fetches attendance records for a given month (YYYY-MM).
  Future<List<AttendanceRecord>> getMonthlyHistory(String yearMonth) async {
    try {
      final response = await _apiClient.get(_historyPath, queryParameters: {
        'month': yearMonth,
      });
      final list = response.data as List? ?? [];
      return list.map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>)).toList();
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }
}

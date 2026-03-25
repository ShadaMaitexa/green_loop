import 'package:network/network.dart';
import 'package:data_models/data_models.dart';

class ScheduleRepository {
  final ApiClient _apiClient;

  static const String _wardSchedulePath = '/api/v1/wards/';
  static const String _myPickupsPath = '/api/v1/pickups/my-pickups/';

  ScheduleRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Fetch the generic recurring schedule for a ward.
  Future<WardSchedule> getWardSchedule(int wardId) async {
    try {
      final response = await _apiClient.get('$_wardSchedulePath$wardId/schedule/');
      return WardSchedule.fromJson(response.data as Map<String, dynamic>);
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Fetch the user's upcoming personal pickup bookings.
  Future<List<PickupResponse>> getMyUpcomingPickups() async {
    try {
      final response = await _apiClient.get(_myPickupsPath);
      final list = response.data as List;
      return list.map((e) => PickupResponse.fromJson(e as Map<String, dynamic>)).toList();
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }
}

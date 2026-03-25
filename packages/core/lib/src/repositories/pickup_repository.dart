import 'package:network/network.dart';
import 'package:data_models/data_models.dart';

class PickupRepository {
  final ApiClient _apiClient;

  static const String _availabilityPath = '/api/v1/pickups/availability/';
  static const String _pickupsPath = '/api/v1/pickups/';

  PickupRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Fetch availability (dates and their slots) for a specific ward.
  Future<List<PickupSlot>> getAvailability(int wardId) async {
    try {
      final response = await _apiClient.get(
        _availabilityPath,
        queryParameters: {'ward_id': wardId},
      );
      final list = response.data as List;
      return list.map((e) => PickupSlot.fromJson(e as Map<String, dynamic>)).toList();
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Create a new pickup booking.
  Future<PickupResponse> createPickup(PickupRequest request) async {
    try {
      final response = await _apiClient.post(
        _pickupsPath,
        data: request.toJson(),
      );
      return PickupResponse.fromJson(response.data as Map<String, dynamic>);
    } on ConflictException catch (e) {
      // Specifically catch conflict to handle "Suggested Next Date" if provided by backend
      throw e;
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }
}

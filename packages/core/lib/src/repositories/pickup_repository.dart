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

  /// Fetch a list of pickups. Optional filtering by ward and date.
  Future<List<PickupResponse>> getPickups({int? wardId, String? date}) async {
    try {
      final Map<String, dynamic> query = {};
      if (wardId != null) query['ward'] = wardId.toString();
      if (date != null) query['date'] = date;

      final response = await _apiClient.get(_pickupsPath, queryParameters: query);
      final list = response.data as List? ?? [];
      return list.map((e) => PickupResponse.fromJson(e as Map<String, dynamic>)).toList();
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Fetch details for a specific pickup.
  Future<PickupResponse> getPickupDetails(String id) async {
    try {
      final response = await _apiClient.get('$_pickupsPath$id/');
      return PickupResponse.fromJson(response.data as Map<String, dynamic>);
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Verify a pickup scan (HKS Side).
  Future<bool> verifyScan(String pickupId) async {
    try {
      await _apiClient.post('$_pickupsPath$pickupId/verify_scan/');
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Cancel a pickup booking (Resident Side).
  Future<void> cancelPickup(String pickupId) async {
    try {
      await _apiClient.delete('$_pickupsPath$pickupId/');
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Confirm a pickup for contamination (Contamination Review).
  Future<void> confirmContamination(String pickupId) async {
    try {
      await _apiClient.post('/api/pickups/$pickupId/confirm/');
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Override a pickup as clean (Contamination Review).
  Future<void> overrideClean(String pickupId) async {
    try {
      await _apiClient.post('/api/pickups/$pickupId/override-clean/');
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }
}

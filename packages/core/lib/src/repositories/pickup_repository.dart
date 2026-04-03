import 'package:network/network.dart';
import 'package:data_models/data_models.dart';

class PickupRepository {
  final ApiClient _apiClient;

  static const String _slotsPath = '/api/v1/pickup-slots/';
  static const String _availabilityPath = '/api/v1/pickups/availability/';
  static const String _pickupsPath = '/api/v1/pickups/';

  PickupRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Fetch all possible shifts/slots for a ward (The "Templates").
  Future<List<PickupSlot>> getPickupSlots(int wardId) async {
    try {
      final response = await _apiClient.get(
        _slotsPath,
        queryParameters: {'ward_id': wardId, 'is_active': true},
      );
      final list = response.data as List;
      return list.map((e) => PickupSlot.fromJson(e as Map<String, dynamic>)).toList();
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Fetch availability for a specific date (Checking if "Full").
  Future<List<PickupSlot>> getAvailability(String date, int wardId) async {
    try {
      final response = await _apiClient.get(
        _availabilityPath,
        queryParameters: {'date': date, 'ward_id': wardId},
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
    } on ValidationException catch (e) {
      final errorMsg = e.errors != null ? '${e.message} ${e.errors}' : e.message;
      throw Exception(errorMsg);
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
      final dynamic rawData = response.data;
      List<dynamic> list;
      if (rawData is Map<String, dynamic>) {
        if (rawData.containsKey('results')) {
          list = rawData['results'] as List<dynamic>? ?? [];
        } else if (rawData['type'] == 'FeatureCollection' && rawData.containsKey('features')) {
          list = rawData['features'] as List<dynamic>? ?? [];
        } else {
          list = [];
        }
      } else if (rawData is List) {
        list = rawData;
      } else {
        list = [];
      }
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
      await _apiClient.patch('$_pickupsPath$pickupId/cancel/');
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Complete a pickup (HKS Side).
  Future<void> completePickup(String pickupId) async {
    try {
      await _apiClient.patch('$_pickupsPath$pickupId/complete/');
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Update a pickup booking.
  Future<PickupResponse> updatePickup(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.patch('$_pickupsPath$id/', data: data);
      return PickupResponse.fromJson(response.data as Map<String, dynamic>);
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Delete a pickup booking.
  Future<void> deletePickup(String pickupId) async {
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

  /// Fetch live routes for the map (Resident Side).
  Future<List<Map<String, dynamic>>> getLiveRoutes() async {
    try {
      final response = await _apiClient.get('/api/v1/routes/ward_live/');
      // Assume returning raw list of features or similar Map to parse in UI
      final dynamic rawData = response.data;
      if (rawData is Map<String, dynamic> && rawData['type'] == 'FeatureCollection') {
        return (rawData['features'] as List).cast<Map<String, dynamic>>();
      } else if (rawData is List) {
        return rawData.cast<Map<String, dynamic>>();
      }
      return [];
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }
}

import 'package:network/network.dart';
import 'package:data_models/data_models.dart';

class PickupSlotsService {
  final ApiClient _apiClient;

  PickupSlotsService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Fetch all pickup slots.
  Future<List<PickupSlot>> getPickupSlots() async {
    try {
      final response = await _apiClient.get('/api/v1/pickup-slots/');
      final list = response.data as List? ?? [];
      return list.map((e) => PickupSlot.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Create a new pickup slot.
  Future<PickupSlot> createPickupSlot(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post('/api/v1/pickup-slots/', data: data);
      return PickupSlot.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch details of a single pickup slot.
  Future<PickupSlot> getPickupSlotDetails(String id) async {
    try {
      final response = await _apiClient.get('/api/v1/pickup-slots/$id/');
      return PickupSlot.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Full update of a pickup slot.
  Future<PickupSlot> updatePickupSlot(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put('/api/v1/pickup-slots/$id/', data: data);
      return PickupSlot.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Partial update of a pickup slot.
  Future<PickupSlot> patchPickupSlot(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.patch('/api/v1/pickup-slots/$id/', data: data);
      return PickupSlot.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a pickup slot.
  Future<void> deletePickupSlot(String id) async {
    try {
      await _apiClient.delete('/api/v1/pickup-slots/$id/');
    } catch (e) {
      rethrow;
    }
  }
}

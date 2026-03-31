import 'package:network/network.dart';

class PickupSlotsService {
  final ApiClient _apiClient;

  PickupSlotsService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<Map<String, dynamic>>> getPickupSlots() async {
    try {
      final response = await _apiClient.get('/api/v1/pickup-slots/');
      if (response.data is List) {
        return (response.data as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createPickupSlot(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post('/api/v1/pickup-slots/', data: data);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deletePickupSlot(String id) async {
    try {
      await _apiClient.delete('/api/v1/pickup-slots/$id/');
    } catch (e) {
      rethrow;
    }
  }
}

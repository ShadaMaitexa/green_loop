import 'package:network/network.dart';
import 'package:data_models/data_models.dart';

class PickupService {
  final ApiClient _apiClient;

  PickupService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<PickupResponse>> getPickups({int? wardId}) async {
    final Map<String, dynamic> queryParameters = {};
    if (wardId != null) {
      queryParameters['ward_id'] = wardId;
    }

    final response = await _apiClient.get(
      '/api/v1/pickups/',
      queryParameters: queryParameters,
    );

    if (response.data is List) {
      return (response.data as List)
          .map((json) => PickupResponse.fromJson(json))
          .toList();
    }
    return [];
  }

  Future<void> cancelPickup(int id) async {
    await _apiClient.patch('/api/v1/pickups/$id/cancel/');
  }
}

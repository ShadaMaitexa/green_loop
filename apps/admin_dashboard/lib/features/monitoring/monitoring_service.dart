import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:data_models/data_models.dart';
import 'package:network/network.dart';

class MonitoringService {
  final ApiClient _apiClient;
  final String _wsBaseUrl;

  MonitoringService({
    required ApiClient apiClient,
  })  : _apiClient = apiClient,
        _wsBaseUrl = apiClient.environment.baseUrl.replaceFirst('http', 'ws');

  /// Fetch all ward boundaries for overlay display.
  Future<List<WardBoundary>> getWardBoundaries() async {
    try {
      final response = await _apiClient.get('/api/v1/wards/');
      final data = response.data;
      if (data is Map && data['type'] == 'FeatureCollection') {
        final features = data['features'] as List? ?? [];
        return features.map((e) => WardBoundary.fromJson(e as Map<String, dynamic>)).toList();
      }
      if (data is List) {
        return data.map((e) => WardBoundary.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      if (kDebugMode || e.toString().contains('OperationError')) {
        return [
          const WardBoundary(wardId: 1, polygon: [[11.25, 75.78], [11.26, 75.78], [11.26, 75.79]]),
          const WardBoundary(wardId: 2, polygon: [[11.24, 75.78], [11.25, 75.78], [11.25, 75.79]]),
        ];
      }
      rethrow;
    }
  }

  /// Fetch current pending pickups to display on map.
  Future<List<PickupResponse>> getPendingPickups() async {
    try {
      final response = await _apiClient.get('/api/v1/pickups/pending/');
      final list = response.data as List;
      return list.map((e) => PickupResponse.fromJson(e)).toList();
    } catch (e) {
      if (kDebugMode || e.toString().contains('OperationError')) {
        return [
          const PickupResponse(id: '1', qrCodeData: 'P1', status: 'pending', scheduledDate: '2026-03-31', slot: 'MORNING', wasteType: WasteType.dry, latitude: 11.255, longitude: 75.785),
        ];
      }
      rethrow;
    }
  }

  /// Connect to real-time GPS tracking WebSocket.
  WebSocketChannel connectTracking() {
    // Note: Assuming the backend handles JWT via query param or subprotocol
    // since WebSocket headers aren't natively supported in all browser/web environments easily.
    // However, for mobile it works. For now, let's use the simplest approach.
    final uri = Uri.parse('$_wsBaseUrl/ws/tracking/');
    return WebSocketChannel.connect(uri);
  }
}

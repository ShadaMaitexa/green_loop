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
        return [];
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
        return [];
      }
      rethrow;
    }
  }

  /// Connect to real-time GPS tracking WebSocket.
  WebSocketChannel connectTracking({String? token}) {
    // Note: Most DRF/Channels backends require the token in the query param for WebSockets on the web
    final url = '$_wsBaseUrl/ws/tracking/${token != null ? "?token=$token" : ""}';
    final uri = Uri.parse(url);
    return WebSocketChannel.connect(uri);
  }
}

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
      final response = await _apiClient.get('/api/v1/admin/wards/boundaries/');
      final list = response.data as List;
      return list.map((e) => WardBoundary.fromJson(e)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch current pending pickups to display on map.
  Future<List<PickupResponse>> getPendingPickups() async {
    try {
      final response = await _apiClient.get('/api/v1/admin/pickups/pending/');
      final list = response.data as List;
      return list.map((e) => PickupResponse.fromJson(e)).toList();
    } catch (e) {
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

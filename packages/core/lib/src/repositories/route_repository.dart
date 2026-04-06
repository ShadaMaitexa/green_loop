import 'package:network/network.dart';
import 'package:data_models/data_models.dart';

/// Repository for Route management and live tracking.
class RouteRepository {
  final ApiClient _apiClient;

  static const String _routesPath = '/api/v1/routes/';

  RouteRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Fetch all defined routes (Admin).
  Future<List<Route>> getRoutes() async {
    try {
      final response = await _apiClient.get(_routesPath);
      final list = (response.data is Map ? response.data['results'] : response.data) as List? ?? [];
      return list.map((e) => Route.fromJson(e as Map<String, dynamic>)).toList();
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Create a new route.
  Future<Route> createRoute(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post(_routesPath, data: data);
      return Route.fromJson(response.data as Map<String, dynamic>);
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Fetch route details by ID.
  Future<Route> getRouteDetails(String id) async {
    try {
      final response = await _apiClient.get('$_routesPath$id/');
      return Route.fromJson(response.data as Map<String, dynamic>);
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Update an existing route.
  Future<Route> updateRoute(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.patch('$_routesPath$id/', data: data);
      return Route.fromJson(response.data as Map<String, dynamic>);
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Delete a route.
  Future<void> deleteRoute(String id) async {
    try {
      await _apiClient.delete('$_routesPath$id/');
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Fetch live routes for the map (Resident Side).
  Future<List<Map<String, dynamic>>> getLiveRoutes() async {
    try {
      final response = await _apiClient.get('${_routesPath}ward_live/');
      if (response.data is Map && response.data['type'] == 'FeatureCollection') {
        final features = response.data['features'] as List? ?? [];
        return features.map((e) => e as Map<String, dynamic>).toList();
      }
      return (response.data as List).cast<Map<String, dynamic>>();
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }
}

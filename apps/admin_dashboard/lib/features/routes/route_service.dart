import 'package:flutter/foundation.dart';
import 'package:network/network.dart';
import 'route_model.dart';

class RouteService {
  final ApiClient _apiClient;

  RouteService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Fetch all routes for the admin dashboard.
  Future<List<RouteModel>> getRoutes() async {
    try {
      final response = await _apiClient.get('/api/v1/routes/');
      final list = response.data as List? ?? [];
      return list.map((e) => RouteModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      if (kDebugMode) {
        // Fallback for CORS/OperationError
        return [
          RouteModel(id: '1', status: 'active', date: '2026-03-31',
            hksWorker: WorkerInfo(id: 'w1', name: 'Ravi Kumar')),
          RouteModel(id: '2', status: 'pending', date: '2026-03-31',
            hksWorker: WorkerInfo(id: 'w2', name: 'Anjali Sharma')),
          RouteModel(id: '3', status: 'completed', date: '2026-03-30',
            hksWorker: WorkerInfo(id: 'w1', name: 'Ravi Kumar')),
        ];
      }
      rethrow;
    }
  }

  /// Create a new route.
  Future<RouteModel> createRoute(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post('/api/v1/routes/', data: data);
      return RouteModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Update an existing route.
  Future<RouteModel> updateRoute(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.patch('/api/v1/routes/$id/', data: data);
      return RouteModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a route.
  Future<void> deleteRoute(String id) async {
    try {
      await _apiClient.delete('/api/v1/routes/$id/');
    } catch (e) {
      rethrow;
    }
  }

  /// Optimize a route based on current pickups.
  Future<void> optimizeRoute(String id) async {
    try {
      await _apiClient.post('/api/v1/routes/$id/optimize/');
    } catch (e) {
      rethrow;
    }
  }
}

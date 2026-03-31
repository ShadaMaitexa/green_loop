import 'package:flutter/foundation.dart';
import 'route_model.dart';
import 'route_service.dart';

class RouteState extends ChangeNotifier {
  final RouteService _service;

  List<RouteModel> _routes = [];
  bool _isLoading = false;
  String? _error;

  RouteState({required RouteService service}) : _service = service;

  List<RouteModel> get routes => _routes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load routes.
  Future<void> loadRoutes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _routes = await _service.getRoutes();
    } catch (e) {
      _error = 'Failed to load routes: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new route.
  Future<bool> createRoute(Map<String, dynamic> data) async {
    try {
      await _service.createRoute(data);
      await loadRoutes();
      return true;
    } catch (e) {
      _error = 'Failed to create route: $e';
      notifyListeners();
      return false;
    }
  }

  /// Update an existing route.
  Future<bool> updateRoute(String id, Map<String, dynamic> data) async {
    try {
      await _service.updateRoute(id, data);
      await loadRoutes();
      return true;
    } catch (e) {
      _error = 'Failed to update route: $e';
      notifyListeners();
      return false;
    }
  }

  /// Delete a route.
  Future<bool> deleteRoute(String id) async {
    try {
      await _service.deleteRoute(id);
      await loadRoutes();
      return true;
    } catch (e) {
      _error = 'Failed to delete route: $e';
      notifyListeners();
      return false;
    }
  }

  /// Optimize a route.
  Future<bool> optimizeRoute(String id) async {
    try {
      await _service.optimizeRoute(id);
      await loadRoutes();
      return true;
    } catch (e) {
      _error = 'Failed to optimize route: $e';
      notifyListeners();
      return false;
    }
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:core/core.dart';
import 'package:data_models/data_models.dart';

/// State management for the HKS Route Map.
/// Handles fetching route data and real-time GPS tracking.
class RouteMapState extends ChangeNotifier {
  final HksRouteRepository _repository;

  HksRoute? _route;
  HksRoute? get route => _route;

  Position? _currentPosition;
  Position? get currentPosition => _currentPosition;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  StreamSubscription<Position>? _positionSubscription;

  RouteMapState({required HksRouteRepository repository})
      : _repository = repository;

  /// Fetches today's route from the backend.
  Future<void> fetchRoute() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _route = await _repository.getTodayRoute();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Starts listening to GPS updates for real-time tracking.
  Future<void> startLocationTracking() async {
    try {
      // Check/request permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      _positionSubscription?.cancel();
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5, // Update every 5 meters
        ),
      ).listen(
        (position) {
          _currentPosition = position;
          notifyListeners();
        },
        onError: (e) {
          debugPrint('Location tracking error: $e');
        },
      );
    } catch (e) {
      debugPrint('Failed to start location tracking: $e');
    }
  }

  /// Logs attendance at the current location.
  Future<void> logAttendance(String ppePhotoUrl) async {
    if (_currentPosition == null) {
      throw Exception('GPS location not available.');
    }

    try {
      await _repository.logAttendance(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        ppePhotoUrl: ppePhotoUrl,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }
}

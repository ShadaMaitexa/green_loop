import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:data_models/data_models.dart';
import 'monitoring_service.dart';

class MonitoringState extends ChangeNotifier {
  final MonitoringService _service;

  List<WardBoundary> _wardBoundaries = [];
  List<PickupResponse> _pendingPickups = [];
  final Map<String, WorkerPosition> _workerPositions = {};

  bool _isLoading = false;
  String? _error;
  StreamSubscription? _trackingSubscription;

  MonitoringState({required MonitoringService service}) : _service = service;

  List<WardBoundary> get wardBoundaries => _wardBoundaries;
  List<PickupResponse> get pendingPickups => _pendingPickups;
  List<WorkerPosition> get workerPositions => _workerPositions.values.toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load initial map data.
  Future<void> initializeMap() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final boundaries = await _service.getWardBoundaries();
      final pickups = await _service.getPendingPickups();

      _wardBoundaries = boundaries;
      _pendingPickups = pickups;

      _startTracking();
    } catch (e) {
      _error = 'Failed to load monitoring data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Start listening to WebSocket tracking updates.
  void _startTracking() {
    _trackingSubscription?.cancel();
    final channel = _service.connectTracking();
    
    _trackingSubscription = channel.stream.listen(
      (data) {
        try {
          final decoded = jsonDecode(data as String);
          final position = WorkerPosition.fromJson(decoded);
          
          _workerPositions[position.workerId] = position;
          notifyListeners();
        } catch (e) {
          debugPrint('Error processing tracking data: $e');
        }
      },
      onError: (e) {
        _error = 'Live tracking error: $e';
        notifyListeners();
        // Re-try after delay...
        Future.delayed(const Duration(seconds: 5), _startTracking);
      },
      onDone: () {
        debugPrint('Tracking WebSocket closed');
        // Re-try after delay...
        Future.delayed(const Duration(seconds: 5), _startTracking);
      },
    );
  }

  @override
  void dispose() {
    _trackingSubscription?.cancel();
    super.dispose();
  }
}

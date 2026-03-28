import 'package:flutter/foundation.dart';
import 'package:data_models/data_models.dart';
import 'ward_service.dart';

enum WardDrawMode { idle, drawing, editing }

class WardState extends ChangeNotifier {
  final WardService _service;

  List<Ward> _wards = [];
  bool _isLoading = false;
  String? _error;

  // Selected ward for detailed view/editing
  Ward? _selectedWard;
  
  // Drawing/editing logic
  WardDrawMode _drawMode = WardDrawMode.idle;
  List<List<double>> _pendingPolygon = []; // [lat, lng]

  WardState({required WardService service}) : _service = service;

  List<Ward> get wards => _wards;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Ward? get selectedWard => _selectedWard;
  WardDrawMode get drawMode => _drawMode;
  List<List<double>> get pendingPolygon => _pendingPolygon;

  List<PlatformUser> _wardWorkers = [];
  List<PlatformUser> _allHksWorkers = [];
  List<PlatformUser> get wardWorkers => _wardWorkers;
  List<PlatformUser> get allHksWorkers => _allHksWorkers;

  /// Load all wards with boundaries.
  Future<void> loadWards() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _wards = await _service.getWards();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load workers for a specific ward.
  Future<void> loadWardWorkers(int wardId) async {
    try {
      _wardWorkers = await _service.getWardWorkers(wardId);
      notifyListeners();
    } catch (_) {}
  }

  /// Load all HKS workers.
  Future<void> loadAllHksWorkers() async {
    try {
      _allHksWorkers = await _service.getAllHksWorkers();
      notifyListeners();
    } catch (_) {}
  }

  /// Select a ward for editing/viewing.
  void selectWard(Ward? ward) {
    _selectedWard = ward;
    _drawMode = WardDrawMode.idle;
    _pendingPolygon = ward?.boundary ?? [];
    notifyListeners();
  }

  /// Start drawing mode.
  void startDrawing() {
    _drawMode = WardDrawMode.drawing;
    _pendingPolygon = [];
    _selectedWard = null;
    notifyListeners();
  }

  /// Start editing mode for current selected ward.
  void startEditing() {
    if (_selectedWard != null) {
      _drawMode = WardDrawMode.editing;
      _pendingPolygon = List.from(_selectedWard!.boundary ?? []);
      notifyListeners();
    }
  }

  /// Add coordinate to pending polygon.
  void addCoordinate(double lat, double lng) {
    if (_drawMode != WardDrawMode.idle) {
      _pendingPolygon.add([lat, lng]);
      notifyListeners();
    }
  }

  /// Clear pending drawing.
  void clearDrawing() {
    _pendingPolygon = [];
    notifyListeners();
  }

  /// Save new or updated ward.
  Future<bool> saveWard(Map<String, dynamic> data) async {
    if (_pendingPolygon.isEmpty) {
      _error = 'Please draw a boundary on the map.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Build closed polygon (GeoJSON requires first == last point)
      final ring = _pendingPolygon.map((c) => [c[1], c[0]]).toList();
      if (ring.first[0] != ring.last[0] || ring.first[1] != ring.last[1]) {
        ring.add(ring.first);
      }

      // Send as GeoJSON Feature to match POST/PATCH /api/v1/wards/ schema
      final wardData = {
        'type': 'Feature',
        'geometry': {
          'type': 'Polygon',
          'coordinates': [ring],
        },
        'properties': {
          'name': data['name'] ?? data['name_en'] ?? '',
          if (data['number'] != null) 'number': data['number'],
        },
      };

      if (_selectedWard != null) {
        await _service.updateWard(_selectedWard!.id, wardData);
      } else {
        await _service.createWard(wardData);
      }

      await loadWards();
      _drawMode = WardDrawMode.idle;
      _selectedWard = null;
      _pendingPolygon = [];
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Assign/unassign HKS worker.
  Future<bool> updateWorkerAssignment(String workerId, int? wardId) async {
    try {
      if (wardId != null) {
        await _service.assignWorker(workerId, wardId);
      } else {
        await _service.unassignWorker(workerId);
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}

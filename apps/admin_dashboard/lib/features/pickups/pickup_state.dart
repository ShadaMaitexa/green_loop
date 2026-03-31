import 'package:flutter/foundation.dart';
import 'package:data_models/data_models.dart';
import 'pickup_service.dart';

class PickupState extends ChangeNotifier {
  final PickupService _service;

  List<PickupResponse> _pickups = [];
  bool _isLoading = false;
  String? _error;

  PickupState({required PickupService service}) : _service = service;

  List<PickupResponse> get pickups => _pickups;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchPickups({int? wardId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _pickups = await _service.getPickups(wardId: wardId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cancelPickup(int id) async {
    try {
      await _service.cancelPickup(id);
      // Refresh list
      await fetchPickups();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}

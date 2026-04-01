import 'package:flutter/foundation.dart';
import 'package:data_models/data_models.dart';
import 'pickup_slots_service.dart';

class PickupSlotsState extends ChangeNotifier {
  final PickupSlotsService _service;

  List<PickupSlot> _slots = [];
  bool _isLoading = false;
  String? _error;

  PickupSlotsState({required PickupSlotsService service}) : _service = service;

  List<PickupSlot> get slots => _slots;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadSlots() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _slots = await _service.getPickupSlots();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createSlot(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.createPickupSlot(data);
      await loadSlots();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteSlot(String id) async {
    try {
      await _service.deletePickupSlot(id);
      await loadSlots();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}

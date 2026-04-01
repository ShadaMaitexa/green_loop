import 'package:flutter/foundation.dart';
import 'package:data_models/data_models.dart';
import 'recycler_service.dart';

class RecyclerState extends ChangeNotifier {
  final RecyclerService _service;

  List<MaterialType> _materialTypes = [];
  List<RecyclerPurchase> _purchases = [];
  bool _isLoading = false;
  String? _error;

  RecyclerState({required RecyclerService service}) : _service = service;

  List<MaterialType> get materialTypes => _materialTypes;
  List<RecyclerPurchase> get purchases => _purchases;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadLedger() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final futures = await Future.wait([
        _service.getMaterialTypes(),
        _service.getPurchases(),
      ]);
      _materialTypes = futures[0] as List<MaterialType>;
      _purchases = futures[1] as List<RecyclerPurchase>;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addMaterial(Map<String, dynamic> data) async {
    try {
      await _service.createMaterialType(data);
      await loadLedger();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> addPurchase(Map<String, dynamic> data) async {
    try {
      await _service.createPurchase(data);
      await loadLedger();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}

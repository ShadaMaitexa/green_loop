import 'package:flutter/foundation.dart';
import 'package:data_models/data_models.dart';
import 'recycler_service.dart';

class RecyclerState extends ChangeNotifier {
  final RecyclerService _service;

  List<MaterialType> _materialTypes = [];
  List<RecyclerPurchase> _purchases = [];
  List<RecyclerCertificate> _pendingCertificates = [];
  bool _isLoading = false;
  String? _error;

  RecyclerState({required RecyclerService service}) : _service = service;

  List<MaterialType> get materialTypes => _materialTypes;
  List<RecyclerPurchase> get purchases => _purchases;
  List<RecyclerCertificate> get pendingCertificates => _pendingCertificates;
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
        _service.getPendingCertificates(),
      ]);
      _materialTypes = futures[0] as List<MaterialType>;
      _purchases = futures[1] as List<RecyclerPurchase>;
      _pendingCertificates = futures[2] as List<RecyclerCertificate>;
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

  Future<bool> updateMaterial(int id, Map<String, dynamic> data) async {
    try {
      await _service.updateMaterialType(id, data);
      await loadLedger();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyCertificate(int id) async {
    try {
      await _service.verifyCertificate(id);
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

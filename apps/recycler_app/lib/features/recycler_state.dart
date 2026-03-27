import 'package:flutter/material.dart' hide MaterialType;
import 'package:core/core.dart';
import 'package:data_models/data_models.dart';

class RecyclerState extends ChangeNotifier {
  final RecyclerRepository repository;

  RecyclerDashboardData? _dashboardData;
  List<MaterialType> _materials = [];
  List<RecyclerPurchase> _history = [];
  List<Ward> _wards = [];
  bool _isLoading = false;
  String? _error;

  RecyclerDashboardData? get dashboardData => _dashboardData;
  List<MaterialType> get materials => _materials;
  List<RecyclerPurchase> get history => _history;
  List<Ward> get wards => _wards;
  bool get isLoading => _isLoading;
  String? get error => _error;

  RecyclerState({required this.repository});

  Future<void> fetchDashboard() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _dashboardData = await repository.getDashboardData();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMaterials() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _materials = await repository.getMaterialTypes();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchWards() async {
    try {
      _wards = await repository.getWards();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> fetchHistory({String? date, int? materialId, int? wardId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _history = await repository.getPurchaseHistory(
        date: date,
        materialId: materialId,
        wardId: wardId,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addPurchase(RecyclerPurchase purchase) async {
    _isLoading = true;
    notifyListeners();
    try {
      final success = await repository.recordPurchase(purchase);
      if (success) {
        await fetchDashboard();
        await fetchHistory();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

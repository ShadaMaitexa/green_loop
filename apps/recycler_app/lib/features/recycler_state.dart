import 'package:flutter/material.dart' hide MaterialType;
import 'package:core/core.dart';
import 'package:data_models/data_models.dart';

class RecyclerState extends ChangeNotifier {
  final RecyclerRepository repository;

  RecyclerDashboardData? _dashboardData;
  List<MaterialType> _materials = [];
  List<RecyclerPurchase> _history = [];
  List<RecyclingCertificate> _certificates = [];
  List<Ward> _wards = [];
  bool _isLoading = false;
  String? _error;

  RecyclerDashboardData? get dashboardData => _dashboardData;
  List<MaterialType> get materials => _materials;
  List<RecyclerPurchase> get history => _history;
  List<RecyclingCertificate> get certificates => _certificates;
  List<Ward> get wards => _wards;
  bool get isLoading => _isLoading;
  String? get error => _error;

  RecyclerState({required this.repository});

  // ── Dashboard ─────────────────────────────────────────────────────────────

  /// Computes dashboard stats from the already-loaded [_history].
  /// Call this AFTER [fetchHistory] completes — no extra API call is made.
  void computeDashboard() {
    final now = DateTime.now();
    double totalWeight = 0;
    double totalSpent = 0;
    int certsThisMonth = 0;

    for (final p in _history) {
      totalWeight += p.weightKg;
      totalSpent += p.totalAmount;
      if (p.certificateUrl != null &&
          p.date.year == now.year &&
          p.date.month == now.month) {
        certsThisMonth++;
      }
    }

    _dashboardData = RecyclerDashboardData(
      totalWeightPurchased: totalWeight,
      totalSpent: totalSpent,
      certificatesIssuedThisMonth: certsThisMonth,
    );
    notifyListeners();
  }

  /// Legacy alias — kept for call-sites that still use fetchDashboard().
  /// Computes locally; does NOT make a network request.
  Future<void> fetchDashboard() async {
    computeDashboard();
  }

  // ── Materials ─────────────────────────────────────────────────────────────

  Future<void> fetchMaterials() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _materials = await repository.getMaterialTypes();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addMaterial(MaterialType type) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final success = await repository.addMaterial(type);
      if (success) await fetchMaterials();
      return success;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateMaterial(MaterialType type) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final success = await repository.updateMaterial(type);
      if (success) await fetchMaterials();
      return success;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteMaterial(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await repository.deleteMaterial(id.toString());
      await fetchMaterials();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Wards ─────────────────────────────────────────────────────────────────

  Future<void> fetchWards() async {
    try {
      _wards = await repository.getWards();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching wards: $e');
    }
  }

  // ── Purchases / History ───────────────────────────────────────────────────

  Future<void> fetchHistory({String? date, int? materialId, int? wardId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final list = await repository.getPurchaseHistory(
        date: date,
        materialId: materialId,
        wardId: wardId,
      );
      
      // Sort history by date descending (latest first)
      list.sort((a, b) => b.date.compareTo(a.date));
      _history = list;
      
      // Recompute dashboard stats whenever history changes.
      // Only recompute for unfiltered fetches so stats reflect the full dataset.
      if (date == null && materialId == null && wardId == null) {
        computeDashboard();
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addPurchase(RecyclerPurchase purchase) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final success = await repository.recordPurchase(purchase);
      if (success) {
        // Re-fetch history so the new purchase appears, then recompute stats.
        await fetchHistory();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deletePurchase(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await repository.deletePurchase(id.toString());
      await fetchHistory();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Certificates ──────────────────────────────────────────────────────────

  Future<void> fetchCertificates() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final list = await repository.getCertificates();
      // Sort certificates by date requested descending
      list.sort((a, b) {
        if (a.dateRequested == null && b.dateRequested == null) return 0;
        if (a.dateRequested == null) return 1;
        if (b.dateRequested == null) return -1;
        return b.dateRequested!.compareTo(a.dateRequested!);
      });
      _certificates = list;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteCertificate(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await repository.deleteCertificate(id.toString());
      await fetchCertificates();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> requestCertificate(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await repository.createCertificate(data);
      await fetchCertificates();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

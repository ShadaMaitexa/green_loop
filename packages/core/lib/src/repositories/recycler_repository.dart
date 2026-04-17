import 'package:network/network.dart';
import 'package:data_models/data_models.dart';

/// Repository for recycler material management, purchases, and history.
class RecyclerRepository {
  final ApiClient _apiClient;

  static const String _certificatesPath = '/api/v1/recycler/certificates/';
  static const String _purchasesPath = '/api/v1/recycler/purchases/';
  static const String _materialsPath = '/api/v1/recycler/materials/';
  static const String _adminPendingCertificatesPath = '/api/v1/recycler/certificates/admin_pending/';

  RecyclerRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  // ── Compatibility Aliases (for recycler_app) ──────────────────────────────

  /// Compatibility alias for [getMaterials].
  Future<List<MaterialType>> getMaterialTypes() => getMaterials();

  /// Compatibility alias for [createMaterial].
  Future<bool> addMaterial(MaterialType type) async {
    try {
      await createMaterial(type.toJson());
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Compatibility alias for [updateMaterial] (Implementation using patch).
  Future<bool> updateMaterial(MaterialType type) async {
    try {
      await _apiClient.patch('$_materialsPath${type.id}/', data: type.toJson());
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Compatibility alias for [createPurchase].
  Future<bool> recordPurchase(RecyclerPurchase purchase) async {
    try {
      await createPurchase(purchase.toJson());
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Compatibility alias for [getPurchases].
  Future<List<RecyclerPurchase>> getPurchaseHistory({
    String? date,
    int? materialId,
    int? wardId,
  }) async {
    try {
      final Map<String, dynamic> query = {};
      if (date != null) query['date'] = date;
      if (materialId != null) query['material'] = materialId.toString();
      if (wardId != null) query['ward'] = wardId.toString();

      final response = await _apiClient.get(_purchasesPath, queryParameters: query);
      final list = (response.data is Map ? response.data['results'] : response.data) as List? ?? [];
      return list.map((e) => RecyclerPurchase.fromJson(e as Map<String, dynamic>)).toList();
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Compatibility alias for dashboard stats.
  Future<RecyclerDashboardData> getDashboardData() async {
    try {
      final response = await _apiClient.get('/api/v1/dashboard/stats/');
      return RecyclerDashboardData.fromJson(response.data as Map<String, dynamic>);
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Compatibility alias for fetching wards.
  Future<List<Ward>> getWards() async {
    try {
      final response = await _apiClient.get('/api/v1/wards/');
      final data = response.data;
      if (data is Map && data['type'] == 'FeatureCollection') {
        final features = data['features'] as List? ?? [];
        return features.map((e) => Ward.fromJson(e as Map<String, dynamic>)).toList();
      }
      if (data is List) {
        return data.map((e) => Ward.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  // ── Certificates ───────────────────────────────────────────────────────────

  /// Fetch all recycling certificates for the current user.
  Future<List<RecyclingCertificate>> getCertificates() async {
    try {
      final response = await _apiClient.get(_certificatesPath);
      final list = (response.data is Map ? response.data['results'] : response.data) as List? ?? [];
      return list.map((e) => RecyclingCertificate.fromJson(e as Map<String, dynamic>)).toList();
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Get details for a specific certificate.
  Future<RecyclingCertificate> getCertificate(String id) async {
    try {
      final response = await _apiClient.get('$_certificatesPath$id/');
      return RecyclingCertificate.fromJson(response.data as Map<String, dynamic>);
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Create a new recycling certificate.
  Future<RecyclingCertificate> createCertificate(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post(_certificatesPath, data: data);
      return RecyclingCertificate.fromJson(response.data as Map<String, dynamic>);
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Delete a recycling certificate.
  Future<void> deleteCertificate(String id) async {
    try {
      await _apiClient.delete('$_certificatesPath$id/');
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Verify a recycling certificate (Admin Side).
  Future<void> verifyCertificate(String id) async {
    try {
      await _apiClient.post('$_certificatesPath$id/verify/');
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Fetch certificates pending admin verification.
  Future<List<RecyclingCertificate>> getAdminPendingCertificates() async {
    try {
      final response = await _apiClient.get(_adminPendingCertificatesPath);
      final list = (response.data is Map ? response.data['results'] : response.data) as List? ?? [];
      return list.map((e) => RecyclingCertificate.fromJson(e as Map<String, dynamic>)).toList();
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  // ── Purchases ──────────────────────────────────────────────────────────────

  /// Fetch all recycler purchases.
  Future<List<RecyclerPurchase>> getPurchases() async {
    try {
      final response = await _apiClient.get(_purchasesPath);
      final list = (response.data is Map ? response.data['results'] : response.data) as List? ?? [];
      return list.map((e) => RecyclerPurchase.fromJson(e as Map<String, dynamic>)).toList();
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Get details for a specific purchase.
  Future<RecyclerPurchase> getPurchase(String id) async {
    try {
      final response = await _apiClient.get('$_purchasesPath$id/');
      return RecyclerPurchase.fromJson(response.data as Map<String, dynamic>);
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Create a new recycler purchase (Recording a transaction).
  Future<RecyclerPurchase> createPurchase(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post(_purchasesPath, data: data);
      return RecyclerPurchase.fromJson(response.data as Map<String, dynamic>);
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Delete a purchase record.
  Future<void> deletePurchase(String id) async {
    try {
      await _apiClient.delete('$_purchasesPath$id/');
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  // ── Materials ─────────────────────────────────────────────────────────────

  /// Fetch all material types available to the recycler.
  Future<List<MaterialType>> getMaterials() async {
    try {
      final response = await _apiClient.get(_materialsPath);
      final list = (response.data is Map ? response.data['results'] : response.data) as List? ?? [];
      return list.map((e) => MaterialType.fromJson(e as Map<String, dynamic>)).toList();
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Get details for a specific material type.
  Future<MaterialType> getMaterial(String id) async {
    try {
      final response = await _apiClient.get('$_materialsPath$id/');
      return MaterialType.fromJson(response.data as Map<String, dynamic>);
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Add a new material type.
  Future<MaterialType> createMaterial(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post(_materialsPath, data: data);
      return MaterialType.fromJson(response.data as Map<String, dynamic>);
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Delete a material type.
  Future<void> deleteMaterial(String id) async {
    try {
      await _apiClient.delete('$_materialsPath$id/');
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }
}

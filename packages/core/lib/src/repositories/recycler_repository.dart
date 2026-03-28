import 'package:network/network.dart';
import 'package:data_models/data_models.dart';

/// Repository for recycler material management, purchases, and history.
class RecyclerRepository {
  final ApiClient apiClient;

  RecyclerRepository({required this.apiClient});

  /// Fetches the recycler's dashboard totals.
  Future<RecyclerDashboardData> getDashboardData() async {
    final response = await apiClient.get('/api/v1/recycler/dashboard/');
    return RecyclerDashboardData.fromJson(response.data as Map<String, dynamic>);
  }

  /// Fetches material types available to the recycler.
  /// API returns a plain list from /api/v1/material-types/
  Future<List<MaterialType>> getMaterialTypes() async {
    final response = await apiClient.get('/api/v1/material-types/');
    return (response.data as List)
        .map((e) => MaterialType.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Adds a new material type.
  Future<bool> addMaterial(MaterialType type) async {
    try {
      await apiClient.post('/api/v1/material-types/', data: type.toJson());
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Updates an existing material type.
  Future<bool> updateMaterial(MaterialType type) async {
    try {
      await apiClient.patch(
        '/api/v1/material-types/${type.id}/',
        data: type.toJson(),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Records a new purchase transaction.
  Future<bool> recordPurchase(RecyclerPurchase purchase) async {
    try {
      await apiClient.post(
        '/api/v1/recycler-purchases/',
        data: purchase.toJson(),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Fetches purchase history with optional filtering.
  Future<List<RecyclerPurchase>> getPurchaseHistory({
    String? date,
    int? materialId,
    int? wardId,
  }) async {
    final Map<String, dynamic> query = {};
    if (date != null) query['date'] = date;
    if (materialId != null) query['material'] = materialId.toString();
    if (wardId != null) query['ward'] = wardId.toString();

    final response = await apiClient.get(
      '/api/v1/recycler-purchases/',
      queryParameters: query,
    );
    return (response.data as List)
        .map((e) => RecyclerPurchase.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetches all wards. API returns a GeoJSON FeatureCollection.
  Future<List<Ward>> getWards() async {
    final response = await apiClient.get('/api/v1/wards/');
    final data = response.data;

    // GeoJSON FeatureCollection: { type: "FeatureCollection", features: [...] }
    if (data is Map && data['type'] == 'FeatureCollection') {
      final features = data['features'] as List? ?? [];
      return features
          .map((e) => Ward.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    // Fallback: flat list
    if (data is List) {
      return data
          .map((e) => Ward.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return [];
  }
}

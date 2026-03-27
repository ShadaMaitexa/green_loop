import 'package:network/network.dart';
import 'package:data_models/data_models.dart';

/// Repository for recycler material management, purchases, and history.
class RecyclerRepository {
  final ApiClient apiClient;

  RecyclerRepository({required this.apiClient});

  /// Fetches the recycler's dashboard totals.
  Future<RecyclerDashboardData> getDashboardData() async {
    final response = await apiClient.get('/api/v1/recycler/dashboard/');
    return RecyclerDashboardData.fromJson(response as Map<String, dynamic>);
  }

  /// Fetches material types available to the recycler.
  Future<List<MaterialType>> getMaterialTypes() async {
    final response = await apiClient.get('/api/v1/recycler/materials/');
    return (response as List).map((e) => MaterialType.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Adds a new material type to the recycler's profile.
  Future<bool> addMaterial(MaterialType type) async {
    try {
      await apiClient.post('/api/v1/recycler/materials/', data: type.toJson());
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Records a new purchase transaction.
  Future<bool> recordPurchase(RecyclerPurchase purchase) async {
    try {
      await apiClient.post('/api/v1/recycler/purchases/', data: purchase.toJson());
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Fetches purchase history with filtering.
  Future<List<RecyclerPurchase>> getPurchaseHistory({
    String? date,
    int? materialId,
    int? wardId,
  }) async {
    final Map<String, dynamic> query = {};
    if (date != null) query['date'] = date;
    if (materialId != null) query['material'] = materialId.toString();
    if (wardId != null) query['ward'] = wardId.toString();

    final response = await apiClient.get('/api/v1/recycler/purchases/', queryParameters: query);
    return (response as List).map((e) => RecyclerPurchase.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Fetches all wards for the purchase form.
  Future<List<Ward>> getWards() async {
    final response = await apiClient.get('/api/v1/wards/');
    return (response as List).map((e) => Ward.fromJson(e as Map<String, dynamic>)).toList();
  }
}

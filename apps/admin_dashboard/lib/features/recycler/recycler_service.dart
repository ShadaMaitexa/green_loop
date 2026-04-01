import 'package:network/network.dart';
import 'package:data_models/data_models.dart';

class RecyclerService {
  final ApiClient _api;

  RecyclerService(this._api);

  Future<List<MaterialType>> getMaterialTypes() async {
    try {
      final response = await _api.get('/api/v1/recycler/materials/');
      final List data = response.data;
      return data.map((json) => MaterialType.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<RecyclerPurchase>> getPurchases() async {
    try {
      final response = await _api.get('/api/v1/recycler/purchases/');
      final List data = response.data;
      return data.map((json) => RecyclerPurchase.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<RecyclerCertificate>> getPendingCertificates() async {
    try {
      final response = await _api.get('/api/v1/recycler/certificates/admin_pending/');
      final List data = response.data;
      return data.map((json) => RecyclerCertificate.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> verifyCertificate(int id) async {
    await _api.post('/api/v1/recycler/certificates/$id/verify/');
  }

  Future<void> createMaterialType(Map<String, dynamic> data) async {
    await _api.post('/api/v1/recycler/materials/', data: data);
  }

  Future<void> updateMaterialType(int id, Map<String, dynamic> data) async {
    await _api.patch('/api/v1/recycler/materials/$id/', data: data);
  }

  Future<void> createPurchase(Map<String, dynamic> data) async {
    await _api.post('/api/v1/recycler/purchases/', data: data);
  }
}

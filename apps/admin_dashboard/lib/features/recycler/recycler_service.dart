import 'package:network/network.dart';
import 'package:data_models/data_models.dart';

class RecyclerService {
  final ApiClient _api;

  RecyclerService(this._api);

  Future<List<MaterialType>> getMaterialTypes() async {
    final response = await _api.get('/material-types/');
    final List data = response.data;
    return data.map((json) => MaterialType.fromJson(json)).toList();
  }

  Future<List<RecyclerPurchase>> getPurchases() async {
    final response = await _api.get('/recycler-purchases/');
    final List data = response.data;
    return data.map((json) => RecyclerPurchase.fromJson(json)).toList();
  }

  Future<void> createMaterialType(Map<String, dynamic> data) async {
    await _api.post('/material-types/', data: data);
  }

  Future<void> createPurchase(Map<String, dynamic> data) async {
    await _api.post('/recycler-purchases/', data: data);
  }
}

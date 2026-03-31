import 'package:network/network.dart';
import 'package:data_models/data_models.dart';

class PaymentService {
  final ApiClient _apiClient;

  PaymentService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Fetch all payments.
  Future<List<FeeCollection>> getPayments() async {
    try {
      final response = await _apiClient.get('/api/v1/payments/');
      final list = response.data as List? ?? [];
      return list.map((e) => FeeCollection.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Create a new payment.
  Future<FeeCollection> createPayment(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post('/api/v1/payments/', data: data);
      return FeeCollection.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch details of a single payment.
  Future<FeeCollection> getPaymentDetails(int id) async {
    try {
      final response = await _apiClient.get('/api/v1/payments/$id/');
      return FeeCollection.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Full update of a payment.
  Future<FeeCollection> updatePayment(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put('/api/v1/payments/$id/', data: data);
      return FeeCollection.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Partial update of a payment.
  Future<FeeCollection> patchPayment(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.patch('/api/v1/payments/$id/', data: data);
      return FeeCollection.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a payment.
  Future<void> deletePayment(int id) async {
    try {
      await _apiClient.delete('/api/v1/payments/$id/');
    } catch (e) {
      rethrow;
    }
  }
}

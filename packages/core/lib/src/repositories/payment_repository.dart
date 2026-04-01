import 'package:network/network.dart';
import 'package:data_models/data_models.dart';

/// Repository for handling fee collections and payments.
class PaymentRepository {
  final ApiClient _apiClient;

  static const String _paymentsPath = '/api/v1/payments/';
  static const String _summaryPath = '/api/v1/payments/summary/';

  PaymentRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Fetches a list of fee collections.
  Future<List<FeeCollection>> getPayments({int? wardId, String? residentId}) async {
    try {
      final Map<String, dynamic> query = {};
      if (wardId != null) query['ward'] = wardId.toString();
      if (residentId != null) query['resident'] = residentId;

      final response = await _apiClient.get(_paymentsPath, queryParameters: query);
      final list = response.data as List? ?? [];
      return list.map((e) => FeeCollection.fromJson(e as Map<String, dynamic>)).toList();
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Records a new fee collection.
  Future<FeeCollection> recordPayment(FeeCollectionRequest request) async {
    try {
      final response = await _apiClient.post(
        _paymentsPath,
        data: request.toJson(),
      );
      return FeeCollection.fromJson(response.data as Map<String, dynamic>);
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Fetches the daily summary of fee collections for the authenticated worker.
  Future<DailyFeeSummary> getDailySummary() async {
    try {
      final response = await _apiClient.get(_summaryPath);
      return DailyFeeSummary.fromJson(response.data as Map<String, dynamic>);
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Fetches details for a single payment.
  Future<FeeCollection> getPaymentDetails(int id) async {
    try {
      final response = await _apiClient.get('$_paymentsPath$id/');
      return FeeCollection.fromJson(response.data as Map<String, dynamic>);
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Update a payment record.
  Future<FeeCollection> updatePayment(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.patch('$_paymentsPath$id/', data: data);
      return FeeCollection.fromJson(response.data as Map<String, dynamic>);
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Replace a payment record.
  Future<FeeCollection> replacePayment(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put('$_paymentsPath$id/', data: data);
      return FeeCollection.fromJson(response.data as Map<String, dynamic>);
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Delete a payment record (only for admin/corrections).
  Future<void> deletePayment(int id) async {
    try {
      await _apiClient.delete('$_paymentsPath$id/');
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:data_models/data_models.dart';
import 'payment_service.dart';

class PaymentState extends ChangeNotifier {
  final PaymentService _service;

  List<FeeCollection> _payments = [];
  bool _isLoading = false;
  String? _error;

  PaymentState({required PaymentService service}) : _service = service;

  List<FeeCollection> get payments => _payments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadPayments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _payments = await _service.getPayments();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deletePayment(int id) async {
    try {
      await _service.deletePayment(id);
      await loadPayments();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}

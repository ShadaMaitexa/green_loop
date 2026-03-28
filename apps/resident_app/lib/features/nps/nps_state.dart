import 'package:flutter/foundation.dart';
import 'nps_service.dart';

class NpsState extends ChangeNotifier {
  final NpsService _service;

  bool _isEligible = false;
  bool get isEligible => _isEligible;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _error;
  String? get error => _error;

  NpsState({required NpsService service}) : _service = service;

  Future<void> checkEligibility() async {
    _isEligible = await _service.checkEligibility();
    notifyListeners();
  }
  
  void markAsShown() {
    _isEligible = false;
    notifyListeners();
  }

  Future<bool> submitNps(int rating, String? comment) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      await _service.submitNps(rating: rating, comment: comment);
      _isEligible = false;
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }
}

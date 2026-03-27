import 'package:flutter/material.dart';
import 'package:data_models/data_models.dart';
import 'reports_service.dart';

class ReportsState extends ChangeNotifier {
  final ReportsService service;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  ComplianceReport? _currentReport;
  ComplianceReport? get currentReport => _currentReport;

  ReportsState({required this.service});

  Future<void> generateSuchitwaReport(DateTime start, DateTime end) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentReport = await service.generateSuchitwaReport(
        startDate: start,
        endDate: end,
      );
    } catch (e) {
      _error = 'Failed to generate report: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearReport() {
    _currentReport = null;
    notifyListeners();
  }
}

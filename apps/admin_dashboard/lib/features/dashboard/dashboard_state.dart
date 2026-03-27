import 'package:flutter/foundation.dart';
import 'dashboard_service.dart';
import 'models/dashboard_stats.dart';

enum DateRange { 
  today(label: 'Today', value: 'today'), 
  last7Days(label: 'Last 7 Days', value: '7d'), 
  last30Days(label: 'Last 30 Days', value: '30d');

  final String label;
  final String value;
  const DateRange({required this.label, required this.value});
}

class DashboardState extends ChangeNotifier {
  final DashboardService _service;

  DashboardStats? _stats;
  bool _isLoading = false;
  String? _error;
  DateRange _currentRange = DateRange.last7Days;

  DashboardState({required DashboardService service}) : _service = service;

  DashboardStats? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateRange get currentRange => _currentRange;

  /// Load stats based on current range.
  Future<void> loadStats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _stats = await _service.getStats(range: _currentRange.value);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Change range and reload.
  void setRange(DateRange range) {
    _currentRange = range;
    loadStats();
  }
}

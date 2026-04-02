import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'package:data_models/data_models.dart';

class HomeState extends ChangeNotifier {
  final PickupRepository pickupRepository;
  final RewardRepository rewardRepository;

  Map<String, dynamic>? _summary;
  List<PickupResponse> _recentPickups = [];
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get summary => _summary;
  List<PickupResponse> get recentPickups => _recentPickups;
  int get pointsBalance => _summary?['balance'] as int? ?? 0;
  String get streakLabel => _summary?['streak_label'] as String? ?? '0-week streak';
  bool get isLoading => _isLoading;
  String? get error => _error;

  HomeState({
    required this.pickupRepository,
    required this.rewardRepository,
  });

  Future<void> fetchDashboard() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        rewardRepository.getSummary(),
        pickupRepository.getPickups(),
      ]);

      final dynamic summaryData = results[0];
      if (summaryData is Map<String, dynamic>) {
        _summary = summaryData;
      }

      final dynamic pickupData = results[1];
      if (pickupData is List<PickupResponse>) {
        _recentPickups = pickupData.take(3).toList();
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Dashboard error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

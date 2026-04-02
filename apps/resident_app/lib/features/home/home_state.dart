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

      _summary = results[0] as Map<String, dynamic>;
      _recentPickups = (results[1] as List<PickupResponse>).take(3).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

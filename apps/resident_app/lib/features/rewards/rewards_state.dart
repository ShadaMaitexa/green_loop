import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'package:data_models/data_models.dart';

class RewardsState extends ChangeNotifier {
  final RewardRepository repository;

  ResidentProfile? _profile;
  List<Reward> _availableRewards = [];
  List<RewardHistoryEntry> _history = [];
  bool _isLoading = false;
  String? _error;

  ResidentProfile? get profile => _profile;
  List<Reward> get availableRewards => _availableRewards;
  List<RewardHistoryEntry> get history => _history;
  bool get isLoading => _isLoading;
  String? get error => _error;

  RewardsState({required this.repository});

  Future<void> fetchAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        repository.getProfile(),
        repository.getAvailableRewards(),
        repository.getHistory(),
      ]);

      _profile = results[0] as ResidentProfile;
      _availableRewards = results[1] as List<Reward>;
      _history = results[2] as List<RewardHistoryEntry>;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> redeemReward(Reward reward) async {
    if (_profile == null || _profile!.pointsBalance < reward.pointCost) {
      _error = 'Insufficient points';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final success = await repository.redeemReward(reward.id);
      if (success) {
        await fetchAll(); // Refresh data
        return true;
      } else {
        _error = 'Redemption failed';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

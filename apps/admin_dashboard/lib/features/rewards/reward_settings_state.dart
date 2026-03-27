import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'package:data_models/data_models.dart';

class RewardSettingsState extends ChangeNotifier {
  final RewardRepository repository;

  RewardConfig? _config;
  List<Reward> _rewards = [];
  bool _isLoading = false;
  String? _error;

  RewardConfig? get config => _config;
  List<Reward> get rewards => _rewards;
  bool get isLoading => _isLoading;
  String? get error => _error;

  RewardSettingsState({required this.repository});

  Future<void> fetchAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        repository.getConfig(),
        repository.getAvailableRewards(),
      ]);

      _config = results[0] as RewardConfig;
      _rewards = results[1] as List<Reward>;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateConfig(RewardConfig newConfig) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await repository.updateConfig(newConfig);
      if (success) {
        _config = newConfig;
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addReward(Reward reward) async {
    _isLoading = true;
    notifyListeners();
    try {
      final success = await repository.createReward(reward);
      if (success) {
        await fetchAll();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteReward(String rewardId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final success = await repository.deleteReward(rewardId);
      if (success) {
        await fetchAll();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

import 'package:network/network.dart';
import 'package:data_models/data_models.dart';

/// Repository for managing rewards, points, and history.
class RewardRepository {
  final ApiClient apiClient;

  RewardRepository({required this.apiClient});

  /// Fetches the resident's current point balance.
  Future<int> getBalance() async {
    final response = await apiClient.get('/api/v1/rewards/balance/');
    return (response.data as Map<String, dynamic>)['balance'] as int? ?? 0;
  }

  /// Fetches the resident's current perfect segregation streak.
  Future<String> getStreak() async {
    final response = await apiClient.get('/api/v1/rewards/streak/');
    return (response.data as Map<String, dynamic>)['streak_label'] as String? ?? '0-week streak';
  }

  /// Fetches the resident's reward summary (Balance + Streak + Recent history).
  Future<Map<String, dynamic>> getSummary() async {
    final response = await apiClient.get('/api/v1/rewards/summary/');
    return response.data as Map<String, dynamic>;
  }

  /// Fetches the list of all reward items in the catalog.
  Future<List<Reward>> getAvailableRewards() async {
    final response = await apiClient.get('/api/v1/rewards/items/');
    return (response.data as List).map((e) => Reward.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Fetches the resident's reward and earning history.
  Future<List<RewardHistoryEntry>> getHistory() async {
    final response = await apiClient.get('/api/v1/rewards/history/');
    return (response.data as List).map((e) => RewardHistoryEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Redeems a specific reward.
  Future<bool> redeemReward(String rewardId) async {
    try {
      await apiClient.post('/api/v1/rewards/redeem/', data: {'reward_id': rewardId});
      return true;
    } catch (e) {
      return false;
    }
  }

  // --- Admin Methods ---

  /// Fetches the list of all reward transactions (Admin only).
  Future<List<RewardHistoryEntry>> getAllTransactions() async {
    final response = await apiClient.get('/api/v1/rewards/');
    return (response.data as List).map((e) => RewardHistoryEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Fetches the global rewards configuration.
  Future<RewardConfig> getConfig() async {
    final response = await apiClient.get('/api/v1/reward-settings/');
    return RewardConfig.fromJson(response.data as Map<String, dynamic>);
  }

  /// Updates the global rewards configuration.
  Future<bool> updateConfig(RewardConfig config) async {
    try {
      await apiClient.patch('/api/v1/reward-settings/', data: config.toJson());
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Adds a new reward to the catalog (Admin only).
  Future<bool> createReward(Reward reward) async {
    try {
      await apiClient.post('/api/v1/rewards/', data: reward.toJson());
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Updates an existing reward (Admin only).
  Future<bool> updateReward(Reward reward) async {
    try {
      await apiClient.patch('/api/v1/rewards/${reward.id}/', data: reward.toJson());
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Deletes a reward from the catalog (Admin only).
  Future<bool> deleteReward(String rewardId) async {
    try {
      await apiClient.delete('/api/v1/rewards/$rewardId/');
      return true;
    } catch (e) {
      return false;
    }
  }
}

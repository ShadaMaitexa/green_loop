import 'package:network/network.dart';
import 'package:data_models/data_models.dart';

/// Repository for managing rewards, points, and history.
class RewardRepository {
  final ApiClient apiClient;

  RewardRepository({required this.apiClient});

  /// Fetches the resident's current profile including points balance and streak.
  Future<ResidentProfile> getProfile() async {
    final response = await apiClient.get('/api/v1/resident/profile/');
    return ResidentProfile.fromJson(response as Map<String, dynamic>);
  }

  /// Fetches the list of available rewards.
  Future<List<Reward>> getAvailableRewards() async {
    final response = await apiClient.get('/api/v1/rewards/available/');
    return (response as List).map((e) => Reward.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Fetches the resident's reward and earning history.
  Future<List<RewardHistoryEntry>> getHistory() async {
    final response = await apiClient.get('/api/v1/rewards/history/');
    return (response as List).map((e) => RewardHistoryEntry.fromJson(e as Map<String, dynamic>)).toList();
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

  /// Fetches the global rewards configuration.
  Future<RewardConfig> getConfig() async {
    final response = await apiClient.get('/api/v1/admin/rewards/config/');
    return RewardConfig.fromJson(response as Map<String, dynamic>);
  }

  /// Updates the global rewards configuration.
  Future<bool> updateConfig(RewardConfig config) async {
    try {
      await apiClient.patch('/api/v1/admin/rewards/config/', data: config.toJson());
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Adds a new reward to the catalog (Admin only).
  Future<bool> createReward(Reward reward) async {
    try {
      await apiClient.post('/api/v1/admin/rewards/', data: reward.toJson());
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Updates an existing reward (Admin only).
  Future<bool> updateReward(Reward reward) async {
    try {
      await apiClient.patch('/api/v1/admin/rewards/${reward.id}/', data: reward.toJson());
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Deletes a reward from the catalog (Admin only).
  Future<bool> deleteReward(String rewardId) async {
    try {
      await apiClient.delete('/api/v1/admin/rewards/$rewardId/');
      return true;
    } catch (e) {
      return false;
    }
  }
}

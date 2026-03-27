/// Model representing the global configuration for the loyalty/rewards system.
class RewardConfig {
  final int pointsPerCleanPickup;
  final int pointsPerContaminatedPickup;
  final int streakBonusPoints;
  final int streakWeeksRequired;

  const RewardConfig({
    required this.pointsPerCleanPickup,
    required this.pointsPerContaminatedPickup,
    required this.streakBonusPoints,
    required this.streakWeeksRequired,
  });

  factory RewardConfig.fromJson(Map<String, dynamic> json) {
    return RewardConfig(
      pointsPerCleanPickup: json['points_per_clean_pickup'] as int,
      pointsPerContaminatedPickup: json['points_per_contaminated_pickup'] as int,
      streakBonusPoints: json['streak_bonus_points'] as int,
      streakWeeksRequired: json['streak_weeks_required'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'points_per_clean_pickup': pointsPerCleanPickup,
      'points_per_contaminated_pickup': pointsPerContaminatedPickup,
      'streak_bonus_points': streakBonusPoints,
      'streak_weeks_required': streakWeeksRequired,
    };
  }

  RewardConfig copyWith({
    int? pointsPerCleanPickup,
    int? pointsPerContaminatedPickup,
    int? streakBonusPoints,
    int? streakWeeksRequired,
  }) {
    return RewardConfig(
      pointsPerCleanPickup: pointsPerCleanPickup ?? this.pointsPerCleanPickup,
      pointsPerContaminatedPickup: pointsPerContaminatedPickup ?? this.pointsPerContaminatedPickup,
      streakBonusPoints: streakBonusPoints ?? this.streakBonusPoints,
      streakWeeksRequired: streakWeeksRequired ?? this.streakWeeksRequired,
    );
  }
}

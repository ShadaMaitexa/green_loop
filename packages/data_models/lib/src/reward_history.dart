/// Model representing an entry in the resident's reward/earning history.
class RewardHistoryEntry {
  final String id;
  final DateTime date;
  final String description; // e.g., 'Plastic Waste Pickup'
  final int pointsEarned; // Positive for earnings, negative for redemptions
  final int totalBalanceAtTime;

  const RewardHistoryEntry({
    required this.id,
    required this.date,
    required this.description,
    required this.pointsEarned,
    required this.totalBalanceAtTime,
  });

  factory RewardHistoryEntry.fromJson(Map<String, dynamic> json) {
    return RewardHistoryEntry(
      id: json['id'].toString(),
      date: DateTime.parse(json['date'] as String),
      description: json['description'] as String,
      pointsEarned: json['points_earned'] as int,
      totalBalanceAtTime: json['total_balance'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'description': description,
      'points_earned': pointsEarned,
      'total_balance': totalBalanceAtTime,
    };
  }
}

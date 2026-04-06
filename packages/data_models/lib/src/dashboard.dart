class DashboardStats {
  final int totalResidents;
  final int totalWorkers;
  final int activePickups;
  final int resolvedComplaints;
  final double wasteCollected;
  final double recyclingRate;

  const DashboardStats({
    required this.totalResidents,
    required this.totalWorkers,
    required this.activePickups,
    required this.resolvedComplaints,
    required this.wasteCollected,
    required this.recyclingRate,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalResidents: json['total_residents'] as int? ?? 0,
      totalWorkers: json['total_workers'] as int? ?? 0,
      activePickups: json['active_pickups'] as int? ?? 0,
      resolvedComplaints: json['resolved_complaints'] as int? ?? 0,
      wasteCollected: (json['waste_collected'] as num?)?.toDouble() ?? 0.0,
      recyclingRate: (json['recycling_rate'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_residents': totalResidents,
      'total_workers': totalWorkers,
      'active_pickups': activePickups,
      'resolved_complaints': resolvedComplaints,
      'waste_collected': wasteCollected,
      'recycling_rate': recyclingRate,
    };
  }
}

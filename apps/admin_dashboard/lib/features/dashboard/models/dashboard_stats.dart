class DashboardKPIs {
  final int pickupsToday;
  final int activeWorkers;
  final int pendingComplaints;
  final double totalWasteKg;

  const DashboardKPIs({
    required this.pickupsToday,
    required this.activeWorkers,
    required this.pendingComplaints,
    required this.totalWasteKg,
  });

  factory DashboardKPIs.fromJson(Map<String, dynamic> json) {
    return DashboardKPIs(
      pickupsToday: json['pickups_today'] as int? ?? 0,
      activeWorkers: json['active_workers'] as int? ?? 0,
      pendingComplaints: json['pending_complaints'] as int? ?? 0,
      totalWasteKg: (json['total_waste_kg'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class TrendPoint {
  final String date;
  final int count;

  const TrendPoint({required this.date, required this.count});

  factory TrendPoint.fromJson(Map<String, dynamic> json) {
    return TrendPoint(
      date: json['date'] as String,
      count: json['count'] as int,
    );
  }
}

class WardComparison {
  final String wardName;
  final int pickups;
  final int complaints;
  final double wasteWeight;

  const WardComparison({
    required this.wardName,
    required this.pickups,
    required this.complaints,
    required this.wasteWeight,
  });

  factory WardComparison.fromJson(Map<String, dynamic> json) {
    return WardComparison(
      wardName: json['ward_name'] as String,
      pickups: json['pickups'] as int? ?? 0,
      complaints: json['complaints'] as int? ?? 0,
      wasteWeight: (json['waste_weight'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class DashboardStats {
  final DashboardKPIs kpis;
  final List<TrendPoint> weeklyTrend;
  final List<WardComparison> wardComparison;

  const DashboardStats({
    required this.kpis,
    required this.weeklyTrend,
    required this.wardComparison,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      kpis: DashboardKPIs.fromJson(json['kpis'] as Map<String, dynamic>),
      weeklyTrend: (json['weekly_trend'] as List? ?? [])
          .map((e) => TrendPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      wardComparison: (json['ward_comparison'] as List? ?? [])
          .map((e) => WardComparison.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

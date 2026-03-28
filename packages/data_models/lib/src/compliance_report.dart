class ComplianceReport {
  final DateTime startDate;
  final DateTime endDate;
  final Map<String, double> wasteByTypeKg; 
  final double householdCoveragePercentage; 
  final double segregationAccuracyPercentage; 
  final double hksAttendancePercentage; 
  final int totalHouseholds;
  final int coveredHouseholds;
  final int totalHKSWorkers;
  final int activeHKSWorkers;
  final double totalWasteCollectedKg;
  
  // New metrics for ULB Progress Report
  final int totalPickupsCompleted;
  final double npsScore; // -100 to 100
  final double systemUptimePercentage; 
  final double averageResponseTimeSeconds;
  final double cloudCostUsd;
  final double totalFeeCollected;
  final double budgetUtilizationPercentage;
  final int projectedOnboardingNextMonth;
  final double tonnageGrowthProjectionPercent;

  const ComplianceReport({
    required this.startDate,
    required this.endDate,
    required this.wasteByTypeKg,
    required this.householdCoveragePercentage,
    required this.segregationAccuracyPercentage,
    required this.hksAttendancePercentage,
    required this.totalHouseholds,
    required this.coveredHouseholds,
    required this.totalHKSWorkers,
    required this.activeHKSWorkers,
    required this.totalWasteCollectedKg,
    required this.totalPickupsCompleted,
    required this.npsScore,
    required this.systemUptimePercentage,
    required this.averageResponseTimeSeconds,
    required this.cloudCostUsd,
    required this.totalFeeCollected,
    required this.budgetUtilizationPercentage,
    required this.projectedOnboardingNextMonth,
    required this.tonnageGrowthProjectionPercent,
  });

  factory ComplianceReport.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> wasteJson = json['wasteByTypeKg'] ?? {};
    final wasteByType = wasteJson.map((key, value) => MapEntry(key, (value as num).toDouble()));

    return ComplianceReport(
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      wasteByTypeKg: wasteByType,
      householdCoveragePercentage: (json['householdCoveragePercentage'] as num).toDouble(),
      segregationAccuracyPercentage: (json['segregationAccuracyPercentage'] as num).toDouble(),
      hksAttendancePercentage: (json['hksAttendancePercentage'] as num).toDouble(),
      totalHouseholds: json['totalHouseholds'] as int? ?? 0,
      coveredHouseholds: json['coveredHouseholds'] as int? ?? 0,
      totalHKSWorkers: json['totalHKSWorkers'] as int? ?? 0,
      activeHKSWorkers: json['activeHKSWorkers'] as int? ?? 0,
      totalWasteCollectedKg: (json['totalWasteCollectedKg'] as num).toDouble(),
      totalPickupsCompleted: json['totalPickupsCompleted'] as int? ?? 0,
      npsScore: (json['npsScore'] as num? ?? 0.0).toDouble(),
      systemUptimePercentage: (json['systemUptimePercentage'] as num? ?? 99.9).toDouble(),
      averageResponseTimeSeconds: (json['averageResponseTimeSeconds'] as num? ?? 0.0).toDouble(),
      cloudCostUsd: (json['cloudCostUsd'] as num? ?? 0.0).toDouble(),
      totalFeeCollected: (json['totalFeeCollected'] as num? ?? 0.0).toDouble(),
      budgetUtilizationPercentage: (json['budgetUtilizationPercentage'] as num? ?? 0.0).toDouble(),
      projectedOnboardingNextMonth: json['projectedOnboardingNextMonth'] as int? ?? 0,
      tonnageGrowthProjectionPercent: (json['tonnageGrowthProjectionPercent'] as num? ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'wasteByTypeKg': wasteByTypeKg,
      'householdCoveragePercentage': householdCoveragePercentage,
      'segregationAccuracyPercentage': segregationAccuracyPercentage,
      'hksAttendancePercentage': hksAttendancePercentage,
      'totalHouseholds': totalHouseholds,
      'coveredHouseholds': coveredHouseholds,
      'totalHKSWorkers': totalHKSWorkers,
      'activeHKSWorkers': activeHKSWorkers,
      'totalWasteCollectedKg': totalWasteCollectedKg,
      'totalPickupsCompleted': totalPickupsCompleted,
      'npsScore': npsScore,
      'systemUptimePercentage': systemUptimePercentage,
      'averageResponseTimeSeconds': averageResponseTimeSeconds,
      'cloudCostUsd': cloudCostUsd,
      'totalFeeCollected': totalFeeCollected,
      'budgetUtilizationPercentage': budgetUtilizationPercentage,
      'projectedOnboardingNextMonth': projectedOnboardingNextMonth,
      'tonnageGrowthProjectionPercent': tonnageGrowthProjectionPercent,
    };
  }
}

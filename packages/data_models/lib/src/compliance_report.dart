class ComplianceReport {
  final DateTime startDate;
  final DateTime endDate;
  final Map<String, double> wasteByTypeKg; // e.g. {"Plastic": 120.5, "Glass": 45.0}
  final double householdCoveragePercentage; // 0.0 to 100.0
  final double segregationAccuracyPercentage; // 0.0 to 100.0
  final double hksAttendancePercentage; // 0.0 to 100.0
  final int totalHouseholds;
  final int coveredHouseholds;
  final int totalHKSWorkers;
  final int activeHKSWorkers;
  final double totalWasteCollectedKg;

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
    };
  }
}

enum ReportType {
  wardCollection,
  monitoring,
  revenue;

  static ReportType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'ward_collection':
        return ReportType.wardCollection;
      case 'monitoring':
        return ReportType.monitoring;
      case 'revenue':
        return ReportType.revenue;
      default:
        return ReportType.wardCollection;
    }
  }
}

class ReportCategory {
  final int id;
  final String name;
  final String? description;

  const ReportCategory({
    required this.id,
    required this.name,
    this.description,
  });

  factory ReportCategory.fromJson(Map<String, dynamic> json) {
    return ReportCategory(
      id: json['id'] as int? ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
    );
  }
}

class Report {
  final String id;
  final String title;
  final ReportType type;
  final String? fileUrl;
  final DateTime createdAt;

  const Report({
    required this.id,
    required this.title,
    required this.type,
    this.fileUrl,
    required this.createdAt,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Report',
      type: ReportType.fromString(json['type']?.toString() ?? 'ward_collection'),
      fileUrl: json['file_url']?.toString() ?? json['report_file']?.toString(),
      createdAt: DateTime.parse(json['created_at'].toString()),
    );
  }
}

class WardCollectionReport {
  final String id;
  final int wardId;
  final String date;
  final double wetWasteKg;
  final double dryWasteKg;
  final String status;

  const WardCollectionReport({
    required this.id,
    required this.wardId,
    required this.date,
    required this.wetWasteKg,
    required this.dryWasteKg,
    required this.status,
  });

  factory WardCollectionReport.fromJson(Map<String, dynamic> json) {
    return WardCollectionReport(
      id: json['id']?.toString() ?? '',
      wardId: json['ward'] as int? ?? 0,
      date: json['date']?.toString() ?? '',
      wetWasteKg: (json['wet_waste_kg'] as num?)?.toDouble() ?? 0.0,
      dryWasteKg: (json['dry_waste_kg'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString() ?? 'PENDING',
    );
  }
}

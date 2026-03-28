/// Model representing a material type accepted by the recycler.
/// Aligns with GET /api/v1/material-types/
class MaterialType {
  final int id;
  final String name;
  final String description;
  final double currentPricePerKg;

  const MaterialType({
    required this.id,
    required this.name,
    required this.description,
    required this.currentPricePerKg,
  });

  factory MaterialType.fromJson(Map<String, dynamic> json) {
    return MaterialType(
      id: json['id'] as int? ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      currentPricePerKg: double.tryParse(json['price_per_kg']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'price_per_kg': currentPricePerKg.toString(),
    };
  }

  @override
  bool operator ==(Object other) => other is MaterialType && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Model representing a purchase record for the recycler.
/// Aligns with GET /api/v1/recycler-purchases/
class RecyclerPurchase {
  final int? id;
  final int materialTypeId;
  final String? materialName; // API might not return this, UI can fallback
  final double weightKg;
  final double totalAmount;
  final int sourceWardId;
  final String? sourceWardName;
  final DateTime date;
  final String? certificateUrl;

  const RecyclerPurchase({
    this.id,
    required this.materialTypeId,
    this.materialName,
    required this.weightKg,
    required this.totalAmount,
    required this.sourceWardId,
    this.sourceWardName,
    required this.date,
    this.certificateUrl,
  });

  factory RecyclerPurchase.fromJson(Map<String, dynamic> json) {
    return RecyclerPurchase(
      id: json['id'] as int?,
      // API uses 'material_type' and 'ward' for IDs
      materialTypeId: json['material_type'] as int? ?? json['material_type_id'] as int? ?? 0,
      materialName: json['material_name']?.toString() ?? json['material_type_name']?.toString(),
      weightKg: double.tryParse(json['weight']?.toString() ?? '0') ?? 0.0,
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0.0,
      sourceWardId: json['ward'] as int? ?? json['source_ward_id'] as int? ?? 0,
      sourceWardName: json['ward_name']?.toString() ?? json['source_ward_name']?.toString(),
      // API uses 'purchase_date'
      date: DateTime.tryParse(json['purchase_date']?.toString() ?? '') ??
          DateTime.tryParse(json['date']?.toString() ?? '') ??
          DateTime.now(),
      certificateUrl: json['certificate_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'material_type': materialTypeId,
      'weight': weightKg.toString(),
      'total_amount': totalAmount.toString(),
      'ward': sourceWardId,
      'purchase_date': "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}",
    };
  }
}

/// Dashboard totals for the recycler.
/// API: GET /api/v1/recycler-purchases/stats/ (hypothesized from requirements)
class RecyclerDashboardData {
  final double totalWeightPurchased;
  final double totalSpent;
  final int certificatesIssuedThisMonth;

  const RecyclerDashboardData({
    required this.totalWeightPurchased,
    required this.totalSpent,
    required this.certificatesIssuedThisMonth,
  });

  factory RecyclerDashboardData.fromJson(Map<String, dynamic> json) {
    return RecyclerDashboardData(
      totalWeightPurchased: (json['total_weight'] as num?)?.toDouble() ?? 0.0,
      totalSpent: (json['total_spent'] as num?)?.toDouble() ?? 0.0,
      certificatesIssuedThisMonth: (json['certificates_issued'] as int?) ??
          (json['certificates_month'] as int?) ?? 0,
    );
  }
}

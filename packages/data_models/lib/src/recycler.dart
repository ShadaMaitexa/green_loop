/// Model representing a material type accepted by the recycler.
class MaterialType {
  final String id;
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
      id: json['id'].toString(),
      name: json['name'] as String,
      description: json['description'] as String,
      currentPricePerKg: (json['price_per_kg'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price_per_kg': currentPricePerKg,
    };
  }
}

/// Model representing a purchase record for the recycler.
class RecyclerPurchase {
  final String? id;
  final String materialTypeId;
  final String materialName;
  final double weightKg;
  final double totalAmount;
  final int sourceWardId;
  final String sourceWardName;
  final DateTime date;
  final String? certificateUrl;

  const RecyclerPurchase({
    this.id,
    required this.materialTypeId,
    required this.materialName,
    required this.weightKg,
    required this.totalAmount,
    required this.sourceWardId,
    required this.sourceWardName,
    required this.date,
    this.certificateUrl,
  });

  factory RecyclerPurchase.fromJson(Map<String, dynamic> json) {
    return RecyclerPurchase(
      id: json['id']?.toString(),
      materialTypeId: json['material_type_id'].toString(),
      materialName: json['material_name'] as String,
      weightKg: (json['weight'] as num).toDouble(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      sourceWardId: json['source_ward_id'] as int,
      sourceWardName: json['source_ward_name'] as String,
      date: DateTime.parse(json['date'] as String),
      certificateUrl: json['certificate_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'material_type_id': materialTypeId,
      'weight': weightKg,
      'total_amount': totalAmount,
      'source_ward_id': sourceWardId,
      'date': date.toIso8601String(),
    };
  }
}

/// Dashboard totals for the recycler.
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
      totalWeightPurchased: (json['total_weight'] as num).toDouble(),
      totalSpent: (json['total_spent'] as num).toDouble(),
      certificatesIssuedThisMonth: json['certificates_month'] as int,
    );
  }
}

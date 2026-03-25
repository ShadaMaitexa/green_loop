/// Represents a Municipal Ward in the GreenLoop system.
class Ward {
  final int id;
  final String nameEn;
  final String nameMl;
  final String? description;

  const Ward({
    required this.id,
    required this.nameEn,
    required this.nameMl,
    this.description,
  });

  factory Ward.fromJson(Map<String, dynamic> json) {
    return Ward(
      id: json['id'] as int,
      nameEn: json['name_en'] as String,
      nameMl: json['name_ml'] as String,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_en': nameEn,
      'name_ml': nameMl,
      if (description != null) 'description': description,
    };
  }

  /// Displays the name based on locale
  String localizedName(String locale) => locale == 'ml' ? nameMl : nameEn;
}

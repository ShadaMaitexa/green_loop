/// Represents a Municipal Ward in the GreenLoop system.
class Ward {
  final int id;
  final String nameEn;
  final String nameMl;
  final String? description;
  final List<List<double>>? boundary; // List of [lat, lng]

  const Ward({
    required this.id,
    required this.nameEn,
    required this.nameMl,
    this.description,
    this.boundary,
  });

  factory Ward.fromJson(Map<String, dynamic> json) {
    List<List<double>>? boundary;
    if (json['boundary'] != null) {
      final geometry = json['boundary'] as Map<String, dynamic>;
      // PostGIS GeoJSON Polygon: {"type": "Polygon", "coordinates": [[[lng, lat], ...]]}
      if (geometry['type'] == 'Polygon' && geometry['coordinates'] != null) {
        final coords = (geometry['coordinates'] as List)[0] as List;
        boundary = coords.map<List<double>>((dynamic c) {
          final list = c as List;
          // Note: GeoJSON is [lng, lat], Flutter Map is [lat, lng]
          return [(list[1] as num).toDouble(), (list[0] as num).toDouble()];
        }).toList();
      }
    }

    return Ward(
      id: json['id'] as int,
      nameEn: json['name_en'] as String,
      nameMl: json['name_ml'] as String,
      description: json['description'] as String?,
      boundary: boundary,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_en': nameEn,
      'name_ml': nameMl,
      if (description != null) 'description': description,
      if (boundary != null)
        'boundary': {
          'type': 'Polygon',
          'coordinates': [
            boundary!.map((c) => [c[1], c[0]]).toList(), // Convert back to [lng, lat]
          ],
        },
    };
  }

  /// Displays the name based on locale
  String localizedName(String locale) => locale == 'ml' ? nameMl : nameEn;
}

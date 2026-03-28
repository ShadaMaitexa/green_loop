/// Represents a Municipal Ward in the GreenLoop system.
/// API returns GeoJSON Feature: { type, id, geometry (Polygon), properties: { name, number, location, created_at } }
class Ward {
  final int id;
  final String name;
  final int? number;
  final List<List<double>>? boundary; // List of [lat, lng]

  const Ward({
    required this.id,
    required this.name,
    this.number,
    this.boundary,
  });

  // ── Backwards compat getters used across the app ──────────────────────────
  /// Alias kept for components that use nameEn.
  String get nameEn => name;
  String get nameMl => name; // API provides one name only

  factory Ward.fromJson(Map<String, dynamic> json) {
    // Support both flat JSON and GeoJSON Feature format
    final isFeature = json['type'] == 'Feature';
    final props = isFeature ? (json['properties'] as Map<String, dynamic>? ?? json) : json;
    final geometry = isFeature ? json['geometry'] : null;

    final wardId = isFeature ? (json['id'] as int?) ?? 0 : (json['id'] as int?) ?? 0;

    List<List<double>>? boundary;
    if (geometry != null && geometry['type'] == 'Polygon' && geometry['coordinates'] != null) {
      final coords = (geometry['coordinates'] as List)[0] as List;
      boundary = coords.map<List<double>>((dynamic c) {
        final list = c as List;
        // GeoJSON is [lng, lat] → convert to [lat, lng]
        return [(list[1] as num).toDouble(), (list[0] as num).toDouble()];
      }).toList();
    } else if (props['boundary'] != null) {
      // Legacy flat format with boundary object
      final geo = props['boundary'] as Map<String, dynamic>;
      if (geo['type'] == 'Polygon' && geo['coordinates'] != null) {
        final coords = (geo['coordinates'] as List)[0] as List;
        boundary = coords.map<List<double>>((dynamic c) {
          final list = c as List;
          return [(list[1] as num).toDouble(), (list[0] as num).toDouble()];
        }).toList();
      }
    }

    return Ward(
      id: wardId,
      name: props['name']?.toString() ?? props['name_en']?.toString() ?? '',
      number: props['number'] as int?,
      boundary: boundary,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (number != null) 'number': number,
      if (boundary != null)
        'boundary': {
          'type': 'Polygon',
          'coordinates': [
            boundary!.map((c) => [c[1], c[0]]).toList(), // Convert back to [lng, lat]
          ],
        },
    };
  }

  @override
  bool operator ==(Object other) => other is Ward && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

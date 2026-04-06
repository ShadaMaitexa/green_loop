class Route {
  final String id;
  final String name;
  final int wardId;
  final bool isActive;
  final List<List<double>>? path; // [ [lat, lng], ... ]

  const Route({
    required this.id,
    required this.name,
    required this.wardId,
    this.isActive = true,
    this.path,
  });

  factory Route.fromJson(Map<String, dynamic> json) {
    List<List<double>>? parsePath(dynamic node) {
      if (node == null) return null;
      if (node is List) {
        return node.map<List<double>>((e) {
          final list = e as List;
          return [(list[1] as num).toDouble(), (list[0] as num).toDouble()]; // GeoJSON [lng, lat]
        }).toList();
      }
      if (node is Map && node['type'] == 'LineString') {
        return (node['coordinates'] as List).map<List<double>>((e) {
          final list = e as List;
          return [(list[1] as num).toDouble(), (list[0] as num).toDouble()];
        }).toList();
      }
      return null;
    }

    return Route(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Route',
      wardId: json['ward'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      path: parsePath(json['route_path'] ?? json['path']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'ward': wardId,
      'is_active': isActive,
      if (path != null) 'path': path!.map((e) => [e[1], e[0]]).toList(), // GeoJSON [lng, lat]
    };
  }
}

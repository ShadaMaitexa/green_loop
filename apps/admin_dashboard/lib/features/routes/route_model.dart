class RouteModel {
  final String id;
  final String status;
  final String? date;
  final WorkerInfo? hksWorker;
  final List<List<double>> plannedPath;
  final List<List<double>> actualPath;

  RouteModel({
    required this.id,
    required this.status,
    this.date,
    this.hksWorker,
    this.plannedPath = const [],
    this.actualPath = const [],
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    List<List<double>> parseGeoJSON(dynamic node) {
      if (node == null || node['coordinates'] == null) return [];
      // GeoJSON LineString: [[lng, lat], ...] -> We want [[lat, lng], ...]
      final coords = node['coordinates'] as List;
      return coords.map<List<double>>((e) {
        final list = e as List;
        return [(list[1] as num).toDouble(), (list[0] as num).toDouble()];
      }).toList();
    }

    return RouteModel(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      date: json['route_date']?.toString(),
      hksWorker: json['hks_worker'] != null 
          ? WorkerInfo.fromJson(json['hks_worker'] as Map<String, dynamic>) 
          : null,
      plannedPath: parseGeoJSON(json['planned_path']),
      actualPath: parseGeoJSON(json['actual_path']),
    );
  }
}

class WorkerInfo {
  final String id;
  final String name;

  WorkerInfo({required this.id, required this.name});

  factory WorkerInfo.fromJson(Map<String, dynamic> json) {
    return WorkerInfo(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
    );
  }
}

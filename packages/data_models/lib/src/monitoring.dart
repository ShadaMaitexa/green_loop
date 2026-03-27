import 'package:data_models/src/pickup.dart';

class WorkerPosition {
  final String workerId;
  final String workerName;
  final double latitude;
  final double longitude;
  final DateTime lastUpdated;
  final bool isDeviated;
  final String? activeRouteId;

  const WorkerPosition({
    required this.workerId,
    required this.workerName,
    required this.latitude,
    required this.longitude,
    required this.lastUpdated,
    this.isDeviated = false,
    this.activeRouteId,
  });

  factory WorkerPosition.fromJson(Map<String, dynamic> json) {
    return WorkerPosition(
      workerId: json['worker_id']?.toString() ?? '',
      workerName: json['worker_name']?.toString() ?? 'Worker',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      lastUpdated: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      isDeviated: json['is_deviated'] as bool? ?? false,
      activeRouteId: json['route_id']?.toString(),
    );
  }
}

class WardBoundary {
  final int wardId;
  final List<List<double>> polygon; // List of [lat, lng]

  const WardBoundary({
    required this.wardId,
    required this.polygon,
  });

  factory WardBoundary.fromJson(Map<String, dynamic> json) {
    // Expected format from GeoDjango: {"ward_id": 1, "boundary": {"type": "Polygon", "coordinates": [[[lng, lat], ...]]}}
    final geometry = json['boundary'] as Map<String, dynamic>;
    final coords = (geometry['coordinates'] as List)[0] as List;
    
    return WardBoundary(
      wardId: json['id'] as int,
      polygon: coords.map<List<double>>((dynamic c) {
        final list = c as List;
        return [(list[1] as num).toDouble(), (list[0] as num).toDouble()];
      }).toList(),
    );
  }
}

class LiveMarker {
  final String id;
  final double latitude;
  final double longitude;
  final WasteType? wasteType; // For pickups
  final bool isWorker;
  final String title;

  const LiveMarker({
    required this.id,
    required this.latitude,
    required this.longitude,
    this.wasteType,
    required this.isWorker,
    required this.title,
  });
}

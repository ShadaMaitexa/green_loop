import 'pickup.dart';

/// Represents today's assigned route for an HKS worker.
class HksRoute {
  /// Boundary of the ward assigned (Polygon coordinates).
  /// Note: [lat, lng] format.
  final List<List<double>>? wardBoundary;

  /// Ordered path for the route (LineString coordinates).
  /// Note: [lat, lng] format.
  final List<List<double>> routePath;

  /// List of pickup points along the route.
  final List<HksPickup> pickups;

  HksRoute({
    this.wardBoundary,
    required this.routePath,
    required this.pickups,
  });

  factory HksRoute.fromJson(Map<String, dynamic> json) {
    // Parser for GeoJSON formats from GeoDjango
    List<List<double>>? parseList(dynamic node) {
      if (node == null) return null;
      if (node['type'] == 'Polygon') {
        final coords = node['coordinates'] as List;
        if (coords.isEmpty) return null;
        // Polygon is [[[lng, lat], ...]]
        return (coords[0] as List)
            .map<List<double>>((e) {
              final list = e as List;
              return [(list[1] as num).toDouble(), (list[0] as num).toDouble()];
            })
            .toList();
      } else if (node['type'] == 'LineString') {
        // LineString is [[lng, lat], ...]
        return (node['coordinates'] as List)
            .map<List<double>>((e) {
              final list = e as List;
              return [(list[1] as num).toDouble(), (list[0] as num).toDouble()];
            })
            .toList();
      }
      return null;
    }

    return HksRoute(
      wardBoundary: parseList(json['ward_boundary']),
      routePath: parseList(json['route_path']) ?? [],
      pickups: (json['pickups'] as List? ?? [])
          .map((e) => HksPickup.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// A specific pickup point assigned to an HKS worker.
class HksPickup {
  final String id;
  final String residentName;
  final String address;
  final WasteType wasteType;
  final String bookingTime;
  final double latitude;
  final double longitude;
  final String? phoneNumber;

  HksPickup({
    required this.id,
    required this.residentName,
    required this.address,
    required this.wasteType,
    required this.bookingTime,
    required this.latitude,
    required this.longitude,
    this.phoneNumber,
  });

  factory HksPickup.fromJson(Map<String, dynamic> json) {
    return HksPickup(
      id: json['id']?.toString() ?? '',
      residentName: json['resident_name'] as String? ?? 'N/A',
      address: json['address'] as String? ?? 'N/A',
      wasteType: WasteType.fromJson(json['waste_type'] as String? ?? 'dry'),
      bookingTime: json['booking_time'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      phoneNumber: json['phone_number'] as String?,
    );
  }
}

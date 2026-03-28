import 'package:flutter/material.dart';

enum WasteType {
  dry(label: 'Dry', icon: Icons.recycling_rounded, color: Colors.green),
  wet(label: 'Wet', icon: Icons.eco_rounded, color: Colors.blue),
  eWaste(label: 'E-Waste', icon: Icons.devices_other_rounded, color: Colors.orange),
  biomedical(label: 'Biomedical', icon: Icons.medical_services_rounded, color: Colors.red);

  final String label;
  final IconData icon;
  final Color color;

  const WasteType({
    required this.label,
    required this.icon,
    required this.color,
  });

  String toJson() {
    switch (this) {
      case WasteType.dry: return 'DRY';
      case WasteType.wet: return 'WET';
      case WasteType.eWaste: return 'E_WASTE';
      case WasteType.biomedical: return 'BIOMEDICAL';
    }
  }
  
  static WasteType fromJson(String json) {
    switch (json.toUpperCase()) {
      case 'DRY': return WasteType.dry;
      case 'WET': return WasteType.wet;
      case 'E_WASTE': return WasteType.eWaste;
      case 'BIOMEDICAL': return WasteType.biomedical;
      default: return WasteType.dry;
    }
  }
}

class PickupSlot {
  final String date; // YYYY-MM-DD
  final String slot; // MORNING, AFTERNOON, EVENING
  final bool isAvailable;

  const PickupSlot({
    required this.date,
    required this.slot,
    this.isAvailable = true,
  });

  factory PickupSlot.fromJson(Map<String, dynamic> json) {
    return PickupSlot(
      date: json['date'] as String,
      slot: json['slot'] as String,
      isAvailable: json['is_available'] as bool? ?? true,
    );
  }
}

class PickupRequest {
  final WasteType wasteType;
  final String scheduledDate;
  final String slot;
  final String address;
  final double latitude;
  final double longitude;

  const PickupRequest({
    required this.wasteType,
    required this.scheduledDate,
    required this.slot,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  /// Aligns with POST /api/v1/pickups/ Feature format
  Map<String, dynamic> toJson() {
    return {
      'type': 'Feature',
      'geometry': {
        'type': 'Point',
        'coordinates': [longitude, latitude], // GeoJSON is [lng, lat]
      },
      'properties': {
        'waste_type': wasteType.toJson(),
        'scheduled_date': scheduledDate,
        'slot': slot,
        'address': address,
      },
    };
  }
}

class PickupResponse {
  final String id;
  final String qrCodeData;
  final String status;
  final String scheduledDate;
  final String slot;
  final WasteType wasteType;
  final double? latitude;
  final double? longitude;

  const PickupResponse({
    required this.id,
    required this.qrCodeData,
    required this.status,
    required this.scheduledDate,
    required this.slot,
    required this.wasteType,
    this.latitude,
    this.longitude,
  });

  factory PickupResponse.fromJson(Map<String, dynamic> json) {
    // Handle both flat and GeoJSON Feature responses
    final Map<String, dynamic> properties = json['properties'] ?? json;
    final Map<String, dynamic>? geometry = json['geometry'];
    final List<dynamic>? coords = geometry?['coordinates'];

    return PickupResponse(
      id: json['id']?.toString() ?? properties['id']?.toString() ?? '',
      qrCodeData: properties['qr_code_data']?.toString() ?? '',
      status: properties['status']?.toString() ?? 'pending',
      scheduledDate: properties['scheduled_date']?.toString() ?? '',
      slot: properties['slot']?.toString() ?? 'MORNING',
      wasteType: WasteType.fromJson(properties['waste_type']?.toString() ?? 'DRY'),
      longitude: coords != null && coords.isNotEmpty ? (coords[0] as num).toDouble() : (json['longitude'] as num?)?.toDouble(),
      latitude: coords != null && coords.length > 1 ? (coords[1] as num).toDouble() : (json['latitude'] as num?)?.toDouble(),
    );
  }
}

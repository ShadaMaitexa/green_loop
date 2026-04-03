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
      case WasteType.dry: return 'dry';
      case WasteType.wet: return 'wet';
      case WasteType.eWaste: return 'e-waste';
      case WasteType.biomedical: return 'biomedical';
    }
  }
  
  static WasteType fromJson(String json) {
    switch (json.toLowerCase()) {
      case 'dry': return WasteType.dry;
      case 'wet': return WasteType.wet;
      case 'e-waste': 
      case 'e_waste': return WasteType.eWaste;
      case 'biomedical': return WasteType.biomedical;
      default: return WasteType.dry;
    }
  }
}

class PickupSlot {
  final String id;
  final String date;
  final String label;
  final String slot; // Maps to time_range
  final bool isAvailable; // Maps to is_active
  final List<int> wards;
  final int capacity;

  const PickupSlot({
    required this.id,
    required this.date,
    required this.label,
    required this.slot,
    this.isAvailable = true,
    this.wards = const [],
    this.capacity = 15,
  });

  factory PickupSlot.fromJson(Map<String, dynamic> json) {
    return PickupSlot(
      id: json['id']?.toString() ?? '',
      date: (json['date'] ?? json['scheduled_date'] ?? '').toString(),
      label: json['label']?.toString() ?? 'Time Slot',
      slot: (json['time_range'] ?? json['slot'])?.toString() ?? '00:00 - 00:00',
      isAvailable: json['is_active'] as bool? ?? json['is_available'] as bool? ?? true,
      wards: (json['wards'] as List?)
              ?.map((e) => int.tryParse(e.toString()) ?? 0)
              .where((e) => e != 0)
              .toList() ??
          [],
      capacity: json['capacity'] as int? ?? 15,
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
  final bool isInstant;

  const PickupRequest({
    required this.wasteType,
    required this.scheduledDate,
    required this.slot,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.isInstant = false,
  });

  /// Aligns with project convention: Flat fields + GeoJSON 'location' object
  Map<String, dynamic> toJson() {
    return {
      'waste_type': wasteType.toJson(), // DRY, WET, etc.
      'scheduled_date': scheduledDate,
      'slot': slot,
      'address': address,
      'location': {
        'type': 'Point',
        'coordinates': [longitude, latitude], // GeoJSON is [lng, lat]
      },
      'is_instant': isInstant,
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
  final bool isInstant;
  final String bookingType;

  const PickupResponse({
    required this.id,
    required this.qrCodeData,
    required this.status,
    required this.scheduledDate,
    required this.slot,
    required this.wasteType,
    this.latitude,
    this.longitude,
    this.isInstant = false,
    this.bookingType = 'Scheduled Slot',
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
      isInstant: properties['is_instant'] as bool? ?? false,
      bookingType: properties['booking_type']?.toString() ?? 'Scheduled Slot',
    );
  }
}

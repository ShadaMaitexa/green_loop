import 'package:flutter/material.dart';

enum WasteType {
  dry(label: 'Dry', icon: Icons.recycling_rounded, color: Colors.blue),
  wet(label: 'Wet', icon: Icons.eco_rounded, color: Colors.green),
  eWaste(label: 'E-Waste', icon: Icons.devices_other_rounded, color: Colors.deepPurple),
  biomedical(label: 'Biomedical', icon: Icons.medical_services_rounded, color: Colors.red);

  final String label;
  final IconData icon;
  final Color color;

  const WasteType({
    required this.label,
    required this.icon,
    required this.color,
  });

  String toJson() => name.toLowerCase();
  
  static WasteType fromJson(String json) {
    return WasteType.values.firstWhere(
      (e) => e.name.toLowerCase() == json.toLowerCase(),
      orElse: () => WasteType.dry,
    );
  }
}

class PickupSlot {
  final String date; // YYYY-MM-DD
  final String slot; // Morning, Afternoon, Evening
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

  Map<String, dynamic> toJson() {
    return {
      'waste_type': wasteType.toJson(),
      'scheduled_date': scheduledDate,
      'slot': slot,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
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

  const PickupResponse({
    required this.id,
    required this.qrCodeData,
    required this.status,
    required this.scheduledDate,
    required this.slot,
    required this.wasteType,
  });

  factory PickupResponse.fromJson(Map<String, dynamic> json) {
    return PickupResponse(
      id: json['id']?.toString() ?? '',
      qrCodeData: json['qr_code_data']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      scheduledDate: json['scheduled_date'] as String,
      slot: json['slot'] as String,
      wasteType: WasteType.fromJson(json['waste_type'] as String),
    );
  }
}

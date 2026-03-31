/// Attendance record for an HKS worker.
class AttendanceRecord {
  final String id;
  final String date;           // YYYY-MM-DD
  final String? checkInTime;   // ISO-8601
  final String? checkOutTime;  // ISO-8601
  final bool ppeConfirmed;
  final String? selfieUrl;
  final String status;         // "present" | "partial" | "absent"

  const AttendanceRecord({
    required this.id,
    required this.date,
    this.checkInTime,
    this.checkOutTime,
    required this.ppeConfirmed,
    this.selfieUrl,
    required this.status,
  });

  bool get isCheckedIn => checkInTime != null;
  bool get isCheckedOut => checkOutTime != null;

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    // Handle GeoJSON Feature format
    final properties = json['type'] == 'Feature'
        ? (json['properties'] as Map<String, dynamic>? ?? {})
        : json;

    return AttendanceRecord(
      id: json['id']?.toString() ?? properties['id']?.toString() ?? '',
      date: properties['date']?.toString() ?? '',
      checkInTime: properties['check_in']?.toString() ?? properties['check_in_time']?.toString(),
      checkOutTime: properties['check_out']?.toString() ?? properties['check_out_time']?.toString(),
      ppeConfirmed: properties['has_gloves'] == true && properties['has_mask'] == true, // Derived from detail PPE flags
      selfieUrl: properties['ppe_photo_url']?.toString() ?? properties['ppe_selfie']?.toString(),
      status: properties['status']?.toString() ?? 'absent',
    );
  }
}

/// PPE items the worker must confirm before check-in.
class PpeItem {
  final String id;
  final String label;
  final String icon;    // emoji or icon identifier
  bool isChecked;

  PpeItem({
    required this.id,
    required this.label,
    required this.icon,
    this.isChecked = false,
  });

  static List<PpeItem> defaultChecklist() => [
    PpeItem(id: 'gloves', label: 'Gloves', icon: '🧤'),
    PpeItem(id: 'mask', label: 'Face Mask', icon: '😷'),
    PpeItem(id: 'vest', label: 'Reflective Vest', icon: '🦺'),
    PpeItem(id: 'boots', label: 'Safety Boots', icon: '🥾'),
  ];
}

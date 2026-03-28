import 'package:flutter/material.dart';

/// Complaint status values returned by the API.
enum ComplaintStatus {
  submitted(label: 'Submitted'),
  assigned(label: 'Assigned'),
  inProgress(label: 'In Progress'),
  resolved(label: 'Resolved'),
  closed(label: 'Closed');

  final String label;
  const ComplaintStatus({required this.label});

  static ComplaintStatus fromJson(String json) {
    final normalized = json.toLowerCase().replaceAll('_', '').replaceAll(' ', '');
    return ComplaintStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == normalized ||
             e.name.toLowerCase().replaceAll('_', '') == normalized,
      orElse: () => ComplaintStatus.submitted,
    );
  }

  String toJson() => name;

  IconData get icon {
    switch (this) {
      case ComplaintStatus.submitted: return Icons.pending_actions_rounded;
      case ComplaintStatus.assigned: return Icons.assignment_ind_rounded;
      case ComplaintStatus.inProgress: return Icons.hourglass_top_rounded;
      case ComplaintStatus.resolved: return Icons.check_circle_rounded;
      case ComplaintStatus.closed: return Icons.archive_rounded;
    }
  }

  Color get color {
    switch (this) {
      case ComplaintStatus.submitted: return Colors.blue;
      case ComplaintStatus.assigned: return Colors.indigo;
      case ComplaintStatus.inProgress: return Colors.orange;
      case ComplaintStatus.resolved: return Colors.green;
      case ComplaintStatus.closed: return Colors.purple;
    }
  }
}

/// Priority is an integer from the API (1 = highest).
class ComplaintPriority {
  final int value;
  const ComplaintPriority(this.value);

  static const low = ComplaintPriority(4);
  static const medium = ComplaintPriority(3);
  static const high = ComplaintPriority(2);
  static const critical = ComplaintPriority(1);

  String get label {
    if (value <= 1) return 'Critical';
    if (value == 2) return 'High';
    if (value == 3) return 'Medium';
    return 'Low';
  }

  String get colorName {
    if (value <= 1) return 'purple';
    if (value == 2) return 'red';
    if (value == 3) return 'orange';
    return 'green';
  }

  Color get flutterColor {
    if (value <= 1) return Colors.purple;
    if (value == 2) return Colors.red;
    if (value == 3) return Colors.orange;
    return Colors.green;
  }

  static ComplaintPriority fromJson(dynamic json) {
    if (json is int) return ComplaintPriority(json);
    if (json is String) {
      final lower = json.toLowerCase();
      if (lower == 'critical') return critical;
      if (lower == 'high') return high;
      if (lower == 'medium') return medium;
      return low;
    }
    return low;
  }

  int toJson() => value;
}

/// API-aligned complaint model parsing GeoJSON Feature responses.
///
/// Complaint API format:
/// { type: "Feature", id: 0, geometry: { type: "Point", coordinates: [lng, lat] },
///   properties: { reporter, category, priority, description, image, assigned_to,
///                 status, is_escalated, resolved_at, created_at, updated_at } }
class ComplaintModel {
  final String id;
  final String type;      // maps to `category` in API
  final String description;
  final String? imageUrl;
  final double latitude;
  final double longitude;
  final ComplaintStatus status;
  final ComplaintPriority priority;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;
  final List<ComplaintHistory>? history;
  final int? rating;
  final String? assignedTo;
  final String? reporter;
  final bool isEscalated;

  const ComplaintModel({
    required this.id,
    required this.type,
    required this.description,
    this.imageUrl,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.priority,
    required this.createdAt,
    this.updatedAt,
    this.resolvedAt,
    this.history,
    this.rating,
    this.assignedTo,
    this.reporter,
    this.isEscalated = false,
  });

  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    // Handle both GeoJSON Feature and flat JSON formats
    final isFeature = json['type'] == 'Feature';
    final props = isFeature
        ? (json['properties'] as Map<String, dynamic>? ?? {})
        : json;
    final geometry = isFeature ? json['geometry'] : null;

    final rawId = isFeature ? json['id'] : json['id'];

    // Coordinates: GeoJSON [lng, lat]
    double lat = 0.0, lng = 0.0;
    if (geometry != null && geometry['coordinates'] != null) {
      final coords = geometry['coordinates'] as List;
      if (coords.length >= 2) {
        lng = (coords[0] as num).toDouble();
        lat = (coords[1] as num).toDouble();
      }
    } else {
      lat = (props['latitude'] as num?)?.toDouble() ?? 0.0;
      lng = (props['longitude'] as num?)?.toDouble() ?? 0.0;
    }

    return ComplaintModel(
      id: rawId?.toString() ?? '',
      // API uses `category`, fallback to `type` for legacy
      type: props['category']?.toString() ?? props['type']?.toString() ?? 'GENERAL',
      description: props['description']?.toString() ?? '',
      imageUrl: props['image']?.toString() ?? props['image_url'] as String?,
      latitude: lat,
      longitude: lng,
      status: ComplaintStatus.fromJson(props['status']?.toString() ?? 'submitted'),
      priority: ComplaintPriority.fromJson(props['priority'] ?? 4),
      reporter: props['reporter']?.toString(),
      assignedTo: props['assigned_to']?.toString(),
      isEscalated: props['is_escalated'] as bool? ?? false,
      createdAt: DateTime.tryParse(props['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: props['updated_at'] != null ? DateTime.tryParse(props['updated_at'].toString()) : null,
      resolvedAt: props['resolved_at'] != null ? DateTime.tryParse(props['resolved_at'].toString()) : null,
      history: (props['history'] as List?)
          ?.map((e) => ComplaintHistory.fromJson(e as Map<String, dynamic>))
          .toList(),
      rating: props['rating'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': type,
      'description': description,
      'status': status.toJson(),
      'priority': priority.toJson(),
      if (assignedTo != null) 'assigned_to': assignedTo,
      'is_escalated': isEscalated,
      if (imageUrl != null) 'image': imageUrl,
    };
  }
}

class ComplaintHistory {
  final String status;
  final String comment;
  final DateTime updatedAt;

  const ComplaintHistory({
    required this.status,
    required this.comment,
    required this.updatedAt,
  });

  factory ComplaintHistory.fromJson(Map<String, dynamic> json) {
    return ComplaintHistory(
      status: json['status'] as String,
      comment: json['comment'] as String? ?? '',
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

/// Used for submitting new complaints.
class ComplaintRequest {
  final String type;        // sent as `category`
  final String description;
  final String? imageUrl;
  final double latitude;
  final double longitude;

  const ComplaintRequest({
    required this.type,
    required this.description,
    this.imageUrl,
    required this.latitude,
    required this.longitude,
  });

  /// Sends as GeoJSON Feature to match the POST /api/v1/complaints/ schema.
  Map<String, dynamic> toJson() {
    return {
      'type': 'Feature',
      'geometry': {
        'type': 'Point',
        'coordinates': [longitude, latitude],
      },
      'properties': {
        'category': type,
        'description': description,
        if (imageUrl != null) 'image': imageUrl,
      },
    };
  }
}

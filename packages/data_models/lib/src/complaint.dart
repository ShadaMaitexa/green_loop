enum ComplaintStatus {
  submitted(label: 'Submitted'),
  assigned(label: 'Assigned'),
  inProgress(label: 'In Progress'),
  resolved(label: 'Resolved'),
  closed(label: 'Closed');

  final String label;
  const ComplaintStatus({required this.label});

  static ComplaintStatus fromJson(String json) {
    return ComplaintStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == json.toLowerCase().replaceAll(' ', ''),
      orElse: () => ComplaintStatus.submitted,
    );
  }

  String toJson() => name;
}

enum ComplaintPriority {
  low(label: 'Low', color: 'green'),
  medium(label: 'Medium', color: 'orange'),
  high(label: 'High', color: 'red'),
  critical(label: 'Critical', color: 'purple');

  final String label;
  final String color;
  const ComplaintPriority({required this.label, required this.color});

  static ComplaintPriority fromJson(String json) {
    return ComplaintPriority.values.firstWhere(
      (e) => e.name.toLowerCase() == json.toLowerCase(),
      orElse: () => ComplaintPriority.low,
    );
  }

  String toJson() => name;
}

class ComplaintModel {
  final String id;
  final String type;
  final String description;
  final String? imageUrl;
  final double latitude;
  final double longitude;
  final ComplaintStatus status;
  final ComplaintPriority priority;
  final DateTime createdAt;
  final List<ComplaintHistory>? history;
  final int? rating;
  final String? assignedTo; // ID of worker or admin
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
    this.history,
    this.rating,
    this.assignedTo,
    this.isEscalated = false,
  });

  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    return ComplaintModel(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'General',
      description: json['description']?.toString() ?? '',
      imageUrl: json['image_url'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      status: ComplaintStatus.fromJson(json['status']?.toString() ?? 'submitted'),
      priority: ComplaintPriority.fromJson(json['priority']?.toString() ?? 'low'),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      history: (json['history'] as List?)
          ?.map((e) => ComplaintHistory.fromJson(e as Map<String, dynamic>))
          .toList(),
      rating: json['rating'] as int?,
      assignedTo: json['assigned_to']?.toString(),
      isEscalated: json['is_escalated'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'description': description,
      'status': status.toJson(),
      'priority': priority.toJson(),
      'assigned_to': assignedTo,
      'is_escalated': isEscalated,
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
      comment: json['comment'] as String,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

class ComplaintRequest {
  final String type;
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

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'description': description,
      if (imageUrl != null) 'image_url': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

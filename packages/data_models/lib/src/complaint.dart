enum ComplaintStatus {
  submitted(label: 'Submitted'),
  inProgress(label: 'In Progress'),
  resolved(label: 'Resolved');

  final String label;
  const ComplaintStatus({required this.label});

  static ComplaintStatus fromJson(String json) {
    return ComplaintStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == json.toLowerCase().replaceAll(' ', ''),
      orElse: () => ComplaintStatus.submitted,
    );
  }
}

class ComplaintModel {
  final String id;
  final String type;
  final String description;
  final String? imageUrl;
  final double latitude;
  final double longitude;
  final ComplaintStatus status;
  final DateTime createdAt;
  final List<ComplaintHistory>? history;
  final int? rating;

  const ComplaintModel({
    required this.id,
    required this.type,
    required this.description,
    this.imageUrl,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.createdAt,
    this.history,
    this.rating,
  });

  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    return ComplaintModel(
      id: json['id']?.toString() ?? '',
      type: json['type'] as String,
      description: json['description'] as String,
      imageUrl: json['image_url'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      status: ComplaintStatus.fromJson(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      history: (json['history'] as List?)
          ?.map((e) => ComplaintHistory.fromJson(e as Map<String, dynamic>))
          .toList(),
      rating: json['rating'] as int?,
    );
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

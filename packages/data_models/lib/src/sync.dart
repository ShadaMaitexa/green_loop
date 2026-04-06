enum SyncQueueStatus {
  pending,
  inProgress,
  completed,
  failed;

  static SyncQueueStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return SyncQueueStatus.pending;
      case 'in_progress':
        return SyncQueueStatus.inProgress;
      case 'completed':
        return SyncQueueStatus.completed;
      case 'failed':
        return SyncQueueStatus.failed;
      default:
        return SyncQueueStatus.pending;
    }
  }

  String toJson() {
    switch (this) {
      case SyncQueueStatus.pending:
        return 'pending';
      case SyncQueueStatus.inProgress:
        return 'in_progress';
      case SyncQueueStatus.completed:
        return 'completed';
      case SyncQueueStatus.failed:
        return 'failed';
    }
  }
}

class SyncQueue {
  final String id;
  final String action;
  final Map<String, dynamic> payload;
  final SyncQueueStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? errorMessage;

  const SyncQueue({
    required this.id,
    required this.action,
    required this.payload,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.errorMessage,
  });

  factory SyncQueue.fromJson(Map<String, dynamic> json) {
    return SyncQueue(
      id: json['id']?.toString() ?? '',
      action: json['action']?.toString() ?? '',
      payload: (json['payload'] as Map<String, dynamic>?) ?? {},
      status: SyncQueueStatus.fromString(json['status']?.toString() ?? 'pending'),
      createdAt: DateTime.parse(json['created_at'].toString()),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'].toString()) : null,
      errorMessage: json['error_message']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'action': action,
      'payload': payload,
      'status': status.toJson(),
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (errorMessage != null) 'error_message': errorMessage,
    };
  }
}

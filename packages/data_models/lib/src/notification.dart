import 'package:flutter/foundation.dart';

@immutable
class Notification {
  final int id;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final String userId;

  const Notification({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    required this.userId,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'] as int? ?? 0,
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      userId: json['user']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'user': userId,
    };
  }

  Notification copyWith({
    int? id,
    String? title,
    String? message,
    bool? isRead,
    DateTime? createdAt,
    String? userId,
  }) {
    return Notification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
    );
  }
}

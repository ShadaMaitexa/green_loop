import 'package:network/network.dart';
import 'package:data_models/data_models.dart' as model;

/// Repository for managing application notifications.
class NotificationRepository {
  final ApiClient _apiClient;

  static const String _notificationsPath = '/api/v1/notifications/';

  NotificationRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Fetches a list of notifications for the current user.
  Future<List<model.Notification>> getNotifications() async {
    try {
      final response = await _apiClient.get(_notificationsPath);
      final list = response.data as List? ?? [];
      return list.map((e) => model.Notification.fromJson(e as Map<String, dynamic>)).toList();
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Marks a specific notification as read.
  Future<model.Notification> markAsRead(int id) async {
    try {
      final response = await _apiClient.patch(
        '$_notificationsPath$id/',
        data: {'is_read': true},
      );
      return model.Notification.fromJson(response.data as Map<String, dynamic>);
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  /// Deletes a specific notification.
  Future<void> deleteNotification(int id) async {
    try {
      await _apiClient.delete('$_notificationsPath$id/');
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }
}

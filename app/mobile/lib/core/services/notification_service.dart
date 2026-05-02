import 'package:flutter/foundation.dart';
import '../../models/notification_model.dart';
import 'api_client.dart';

class NotificationService {
  final ApiClient _apiClient = ApiClient();

  Future<List<NotificationModel>> getNotifications() async {
    try {
      final response = await _apiClient.dio.get('/notifications/');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => NotificationModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      return [];
    }
  }

  Future<bool> markAsRead(int notificationId) async {
    try {
      final response = await _apiClient.dio.post('/notifications/$notificationId/read');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      final response = await _apiClient.dio.post('/notifications/read-all');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      return false;
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await _apiClient.dio.get('/notifications/unread-count');
      if (response.statusCode == 200) {
        return response.data['count'] ?? 0;
      }
      return 0;
    } catch (e) {
      debugPrint('Error fetching unread count: $e');
      return 0;
    }
  }
}

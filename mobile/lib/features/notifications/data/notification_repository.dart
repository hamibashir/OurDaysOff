import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/notification_model.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NotificationRepository(apiClient: apiClient);
});

class NotificationRepository {
  final ApiClient apiClient;

  NotificationRepository({required this.apiClient});

  /// Fetch user notifications and unread count
  Future<NotificationsResponse> getNotifications() async {
    final response = await apiClient.get('/notifications');
    if (response is Map<String, dynamic>) {
      return NotificationsResponse.fromJson(response);
    }
    return const NotificationsResponse(data: [], unreadCount: 0);
  }

  /// Mark a single notification as read
  Future<NotificationModel> markAsRead(int id) async {
    final response = await apiClient.put('/notifications/$id/read');
    if (response is Map<String, dynamic> && response['data'] != null) {
      return NotificationModel.fromJson(response['data'] as Map<String, dynamic>);
    }
    return NotificationModel(
      id: id,
      userId: 0,
      type: 'system',
      title: '',
      body: '',
      readAt: DateTime.now(),
      createdAt: DateTime.now(),
    );
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    await apiClient.put('/notifications/read-all');
  }
}

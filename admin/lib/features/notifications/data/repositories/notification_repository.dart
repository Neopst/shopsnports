import '../models/notification_model.dart';
import '../models/notification_preferences.dart';

abstract class INotificationRepository {
  /// Fetch all notifications for a user, optionally filtered by category
  Future<List<Notification>> getNotifications({
    required String userId,
    String? category,
    int limit = 100,
  });

  /// Stream of notifications for real-time updates
  Stream<List<Notification>> getNotificationsStream({
    required String userId,
    String? category,
  });

  /// Get a single notification by ID
  Future<Notification?> getNotificationById(String notificationId);

  /// Update a notification (usually for marking as read/unread)
  Future<void> updateNotification(Notification notification);

  /// Mark a single notification as read
  Future<void> markAsRead(String notificationId);

  /// Mark a single notification as unread
  Future<void> markAsUnread(String notificationId);

  /// Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId);

  /// Archive a notification
  Future<void> archive(String notificationId);

  /// Delete a notification
  Future<void> delete(String notificationId);

  /// Bulk archive notifications
  Future<void> bulkArchive(List<String> notificationIds);

  /// Bulk delete notifications
  Future<void> bulkDelete(List<String> notificationIds);

  /// Get unread count for a user
  Future<int> getUnreadCount(String userId);

  /// Stream of unread count updates
  Stream<int> getUnreadCountStream(String userId);

  /// Get user's notification preferences
  Future<NotificationPreferences?> getPreferences(String userId);

  /// Save user's notification preferences
  Future<void> savePreferences(
    String userId,
    NotificationPreferences preferences,
  );

  /// Mark notification as failed
  Future<void> markAsFailed(String notificationId, String error);

  /// Retry a failed notification
  Future<void> retryNotification(String notificationId);

  /// Get failed notifications that can be retried
  Future<List<Notification>> getRetryableNotifications(String userId);

  /// Get notification retry statistics
  Future<Map<String, dynamic>> getRetryStats(String notificationId);
}

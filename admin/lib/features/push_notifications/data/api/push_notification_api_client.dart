import 'package:dio/dio.dart';
import '../models/notification_template.dart';
import '../models/push_notification.dart';

/// API client for push notifications
/// Uses Firebase Cloud Messaging for delivery
class PushNotificationApiClient {
  final Dio _dio;

  PushNotificationApiClient(this._dio);

  /// Get notification templates
  Future<List<NotificationTemplate>> getTemplates({String? category}) async {
    // TODO: Implement when backend templates API is ready
    // For now, return empty list - templates managed locally
    return [];
  }

  /// Send a push notification
  Future<Map<String, dynamic>> sendNotification(PushNotification notification) async {
    // TODO: Implement when FCM backend is ready
    // For now, simulate successful send
    await Future.delayed(const Duration(milliseconds: 500));
    return {
      'success': true,
      'data': {
        'sent': 0,
        'message': 'Notification sent (mock - implement FCM integration)',
      },
    };
  }

  /// Get notification history
  Future<List<Map<String, dynamic>>> getHistory({String? category}) async {
    // TODO: Implement when backend history API is ready
    return [];
  }

  /// Get notification statistics
  Future<Map<String, dynamic>> getStats() async {
    // TODO: Implement when backend stats API is ready
    return {
      'total': 0,
      'sent': 0,
      'delivered': 0,
      'failed': 0,
    };
  }
}
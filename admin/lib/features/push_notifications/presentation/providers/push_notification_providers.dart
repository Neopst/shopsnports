import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:admin_dashboard/core/services/api_client.dart';
import 'package:admin_dashboard/core/services/fcm_sender_service.dart';
import 'package:admin_dashboard/features/push_notifications/data/api/push_notification_api_client.dart';
import 'package:admin_dashboard/features/push_notifications/data/repositories/push_notification_repository_firestore.dart';

// FCM Sender Service provider
final fcmSenderServiceProvider = Provider<FCMSenderService>((ref) {
  return FCMSenderService();
});

// API Client provider
final pushNotificationApiClientProvider = Provider<PushNotificationApiClient>((ref) {
  final dio = ref.watch(dioProvider);
  return PushNotificationApiClient(dio);
});

// Repository provider
final pushNotificationRepositoryProvider =
    Provider<PushNotificationRepositoryFirestore>((ref) {
      return PushNotificationRepositoryFirestore();
    });

// Notification history stream provider
final notificationHistoryStreamProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
      final repository = ref.watch(pushNotificationRepositoryProvider);
      return repository.getNotificationHistoryStream();
    });

// Notification history provider (one-time fetch)
final notificationHistoryProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final repository = ref.watch(pushNotificationRepositoryProvider);
  return repository.getNotificationHistory();
});

// Recent notifications provider (last 7 days)
final recentNotificationsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final repository = ref.watch(pushNotificationRepositoryProvider);
  return repository.getRecentNotifications();
});

// Notification stats provider
final notificationStatsProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final repository = ref.watch(pushNotificationRepositoryProvider);
  return repository.getNotificationStats();
});

// Notification filter provider (for UI filtering)
final notificationFilterProvider = Provider<String>((ref) => 'all');

// Filtered notification history provider
final filteredNotificationHistoryProvider =
    Provider<List<Map<String, dynamic>>>((ref) {
      final history = ref.watch(notificationHistoryStreamProvider);
      final filter = ref.watch(notificationFilterProvider);

      return history.when(
        data: (notifications) {
          if (filter == 'all') return notifications;
          return notifications.where((n) => n['status'] == filter).toList();
        },
        loading: () => [],
        error: (_, __) => [],
      );
    });

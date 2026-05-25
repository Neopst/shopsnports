import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/notification_model.dart' as notif_model;
import '../../data/repositories/notification_repository_firestore.dart';
import '../../../auth/data/providers/auth_providers.dart';

// Firestore repository provider
final notificationRepositoryProvider = Provider((ref) {
  return NotificationRepositoryFirestore();
});

// Notifications stream provider for real-time updates
final notificationsStreamProvider = StreamProvider((ref) {
  final repo = ref.watch(notificationRepositoryProvider);
  final userId = ref.watch(authStateProvider).value?.uid ?? '';

  if (userId.isEmpty) {
    return Stream.value(<notif_model.Notification>[]);
  }

  return repo.getNotificationsStream(userId: userId);
});

// Filtered notifications by category
final notificationsFilterProvider = Provider<String>((ref) => '');

final filteredNotificationsProvider = StreamProvider((ref) {
  final repo = ref.watch(notificationRepositoryProvider);
  final userId = ref.watch(authStateProvider).value?.uid ?? '';
  final category = ref.watch(notificationsFilterProvider);

  if (userId.isEmpty) {
    return Stream.value(<notif_model.Notification>[]);
  }

  return repo.getNotificationsStream(
    userId: userId,
    category: category.isEmpty ? null : category,
  );
});

// Unread count stream for real-time badge updates
final unreadCountStreamProvider = StreamProvider((ref) {
  final repo = ref.watch(notificationRepositoryProvider);
  final userId = ref.watch(authStateProvider).value?.uid ?? '';

  if (userId.isEmpty) {
    return Stream.value(0);
  }

  return repo.getUnreadCountStream(userId: userId);
});

// Single notification provider
final notificationProvider =
    FutureProvider.family<notif_model.Notification?, String>((ref, id) async {
      final repo = ref.watch(notificationRepositoryProvider);
      return repo.getNotificationById(id);
    });

// Notification preferences provider
final notificationPreferencesProvider = FutureProvider((ref) async {
  final repo = ref.watch(notificationRepositoryProvider);
  final userId = ref.watch(authStateProvider).value?.uid ?? '';

  if (userId.isEmpty) return null;

  return repo.getPreferences(userId);
});

// Selected notifications for bulk actions
final selectedNotificationsProvider = Provider<Set<String>>((ref) => {});

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:admin_dashboard/features/auth/data/providers/auth_providers.dart';
import '../../data/models/notification_preferences.dart';
import '../providers/notification_providers.dart';
import '../widgets/notification_list_item.dart';
import 'create_notification_screen.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(filteredNotificationsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.notifications, size: 32),
                    SizedBox(width: 12),
                    Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Create Notification'),
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CreateNotificationScreen(),
                          ),
                        );
                        if (result == true) {
                          ref.invalidate(filteredNotificationsProvider);
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.history),
                      label: const Text('History'),
                      onPressed: () {
                        context.push('/dashboard/notifications/history');
                      },
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.analytics),
                      label: const Text('Analytics'),
                      onPressed: () {
                        context.push('/dashboard/notifications/analytics');
                      },
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.schedule),
                      label: const Text('Scheduled'),
                      onPressed: () {
                        context.push('/dashboard/notifications/scheduled');
                      },
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.settings),
                      onPressed: () => _showPreferencesModal(context, ref),
                      tooltip: 'Notification Settings',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Notifications list
            Expanded(
              child: notificationsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
                data: (notifications) {
                  if (notifications.isEmpty) {
                    return const Center(child: Text('No notifications'));
                  }
                  return ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];

                      return NotificationListItem(
                        notification: notification,
                        isSelected: false,
                        onSelectionChanged: (_) {},
                        onTap: () =>
                            _showDetailModal(context, ref, notification.id),
                        onMarkAsRead: () async {
                          final repo = ref.read(notificationRepositoryProvider);
                          if (!notification.isRead) {
                            await repo.markAsRead(notification.id);
                          } else {
                            await repo.markAsUnread(notification.id);
                          }
                          ref.invalidate(filteredNotificationsProvider);
                          ref.invalidate(unreadCountStreamProvider);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailModal(
    BuildContext context,
    WidgetRef ref,
    String notificationId,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) =>
          NotificationDetailModal(notificationId: notificationId),
      isScrollControlled: true,
    );
  }

  void _showPreferencesModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => const NotificationPreferencesModal(),
      isScrollControlled: true,
    );
  }
}

class NotificationDetailModal extends ConsumerWidget {
  final String notificationId;

  const NotificationDetailModal({super.key, required this.notificationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationAsync = ref.watch(notificationProvider(notificationId));

    return DraggableScrollableSheet(
      expand: false,
      builder: (context, scrollController) {
        return notificationAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
          data: (notification) {
            if (notification == null) {
              return const Center(child: Text('Notification not found'));
            }

            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with close button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        notification.type.displayName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Title
                  Text(
                    notification.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  // Category badge
                  Chip(
                    label: Text(notification.category.displayName),
                    avatar: Icon(notification.category.icon),
                  ),
                  const SizedBox(height: 16),
                  // Priority indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: notification.priority.color.withAlpha(25),
                      border: Border.all(color: notification.priority.color),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Priority: ${notification.priority.displayName}',
                      style: TextStyle(color: notification.priority.color),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Message
                  Text(
                    notification.message,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  // Metadata
                  if (notification.metadata != null) ...[
                    Text(
                      'Details',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    ...notification.metadata!.entries.map(
                      (e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [Text(e.key), Text(e.value.toString())],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Timestamps
                  Text(
                    'Created: ${notification.createdAt}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (notification.readAt != null)
                    Text(
                      'Read: ${notification.readAt}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  const SizedBox(height: 16),
                  // Action button
                  if (notification.actionUrl != null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Navigate to action URL
                          Navigator.pop(context);
                        },
                        child: const Text('View Details'),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class NotificationPreferencesModal extends ConsumerWidget {
  const NotificationPreferencesModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferencesAsync = ref.watch(notificationPreferencesProvider);

    return DraggableScrollableSheet(
      expand: false,
      builder: (context, scrollController) {
        return preferencesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
          data: (prefs) {
            if (prefs == null) {
              return const Center(child: Text('No preferences'));
            }

            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Notification Settings',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Categories',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    title: const Text('Sales'),
                    value: prefs.salesEnabled,
                    onChanged: (value) {
                      if (value != null) {
                        _updatePreferences(
                          context,
                          ref,
                          prefs.copyWith(salesEnabled: value),
                        );
                      }
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('Orders'),
                    value: prefs.ordersEnabled,
                    onChanged: (value) {
                      _updatePreferences(
                        context,
                        ref,
                        prefs.copyWith(ordersEnabled: value),
                      );
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('Reviews'),
                    value: prefs.reviewsEnabled,
                    onChanged: (value) {
                      _updatePreferences(
                        context,
                        ref,
                        prefs.copyWith(reviewsEnabled: value),
                      );
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('Users'),
                    value: prefs.usersEnabled,
                    onChanged: (value) {
                      _updatePreferences(
                        context,
                        ref,
                        prefs.copyWith(usersEnabled: value),
                      );
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('Inventory'),
                    value: prefs.inventoryEnabled,
                    onChanged: (value) {
                      _updatePreferences(
                        context,
                        ref,
                        prefs.copyWith(inventoryEnabled: value),
                      );
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('System'),
                    value: prefs.systemEnabled,
                    onChanged: (value) {
                      _updatePreferences(
                        context,
                        ref,
                        prefs.copyWith(systemEnabled: value),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Delivery Methods',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    title: const Text('Email Notifications'),
                    value: prefs.emailNotifications,
                    onChanged: (value) {
                      _updatePreferences(
                        context,
                        ref,
                        prefs.copyWith(emailNotifications: value),
                      );
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('Push Notifications'),
                    value: prefs.pushNotifications,
                    onChanged: (value) {
                      _updatePreferences(
                        context,
                        ref,
                        prefs.copyWith(pushNotifications: value),
                      );
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('Sound Alert'),
                    value: prefs.soundAlert,
                    onChanged: (value) {
                      _updatePreferences(
                        context,
                        ref,
                        prefs.copyWith(soundAlert: value),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _updatePreferences(
    BuildContext context,
    WidgetRef ref,
    NotificationPreferences prefs,
  ) async {
    final authState = ref.read(authStateProvider);
    final userId = authState.value?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not logged in')),
      );
      return;
    }
    final repo = ref.read(notificationRepositoryProvider);
    await repo.savePreferences(userId, prefs);
    ref.invalidate(notificationPreferencesProvider);
  }
}

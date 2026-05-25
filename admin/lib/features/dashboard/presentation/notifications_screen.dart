// lib/features/dashboard/presentation/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../notifications/presentation/providers/notification_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use real notifications from provider
    final notificationsAsync = ref.watch(notificationsStreamProvider);
    final unreadCountAsync = ref.watch(unreadCountStreamProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, unreadCountAsync),
          const SizedBox(height: 24),

          // Notifications List
          _buildSectionTitle('Recent Notifications'),
          const SizedBox(height: 12),
          notificationsAsync.when(
            data: (notifications) {
              if (notifications.isEmpty) {
                return _buildEmptyState();
              }
              return _buildNotificationsList(notifications);
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, s) => _buildErrorCard('Failed to load notifications'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AsyncValue<int> unreadCountAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notifications',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 4),
        unreadCountAsync.when(
          data: (count) => Text(
            count > 0 ? '$count unread notifications' : 'All caught up!',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          loading: () => Text(
            'Loading...',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          error: (_, __) => Text(
            'Unable to load count',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.grey[700],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You\'re all caught up!',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsList(List<dynamic> notifications) {
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: notifications.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return ListTile(
            leading: Icon(
              _getNotificationIcon(notification.type?.toString() ?? 'default'),
              color: _getNotificationColor(notification.type?.toString() ?? 'default'),
            ),
            title: Text(notification.title?.toString() ?? 'No title'),
            subtitle: Text(
              notification.message?.toString() ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: notification.read == false
              ? Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                )
              : null,
          );
        },
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error, color: Colors.red[400]),
            const SizedBox(width: 12),
            Text(message, style: TextStyle(color: Colors.red[400])),
          ],
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'system':
        return Icons.settings;
      case 'promo':
      case 'promotion':
        return Icons.campaign;
      case 'alert':
        return Icons.warning;
      case 'order':
        return Icons.shopping_cart;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type.toLowerCase()) {
      case 'system':
        return Colors.blue;
      case 'promo':
      case 'promotion':
        return Colors.green;
      case 'alert':
        return Colors.orange;
      case 'order':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
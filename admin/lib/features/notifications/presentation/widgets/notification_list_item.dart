import 'package:flutter/material.dart';
import 'package:admin_dashboard/features/notifications/data/models/notification_model.dart'
    as notif_model;

class NotificationListItem extends StatelessWidget {
  final notif_model.Notification notification;
  final bool isSelected;
  final Function(bool) onSelectionChanged;
  final VoidCallback onTap;
  final VoidCallback onMarkAsRead;

  const NotificationListItem({
    super.key,
    required this.notification,
    required this.isSelected,
    required this.onSelectionChanged,
    required this.onTap,
    required this.onMarkAsRead,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: notification.isRead
          ? Colors.transparent
          : Colors.blue.withAlpha(12),
      child: ListTile(
        leading: Checkbox(
          value: isSelected,
          onChanged: (value) => onSelectionChanged(value ?? false),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead
                ? FontWeight.normal
                : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.message,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: Text(
                    notification.category.displayName,
                    style: const TextStyle(fontSize: 12),
                  ),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: notification.priority.color.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    notification.priority.displayName,
                    style: TextStyle(
                      fontSize: 11,
                      color: notification.priority.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatTime(notification.createdAt),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(4),
                ),
              )
            else
              const Icon(Icons.check, size: 16, color: Colors.green),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return 'just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${dateTime.month}/${dateTime.day}';
    }
  }
}

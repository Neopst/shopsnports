import 'package:flutter/material.dart';

class NotificationsMenu extends StatelessWidget {
  const NotificationsMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Notifications',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          _notificationItem(
            Icons.local_shipping,
            'Order #1234 shipped',
            '5m ago',
          ),
          _notificationItem(Icons.store, 'New vendor approved', '10m ago'),
          _notificationItem(Icons.rate_review, 'Review posted', '1h ago'),
          const Divider(),
          TextButton(
            onPressed: () {
              // Navigate to full notifications page
              Navigator.pop(context);
            },
            child: const Text('View all notifications →'),
          ),
        ],
      ),
    );
  }

  Widget _notificationItem(IconData icon, String text, String time) {
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 20),
      title: Text(text),
      trailing: Text(time, style: const TextStyle(color: Colors.black54)),
    );
  }
}

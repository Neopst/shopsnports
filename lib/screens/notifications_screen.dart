import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shopsnports/providers/user_providers.dart';
import 'package:shopsnports/core/routing/app_routes.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final userId = user?.id;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text(
                'Sign in to view your notifications',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, AppRoutes.login),
                child: const Text('Sign In'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.mark_email_read),
            tooltip: 'Mark all as read',
            onPressed: () => _markAllAsRead(userId),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('notifications')
            .where('targetUserId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                  const SizedBox(height: 16),
                  Text('Error loading notifications: ${snapshot.error}'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data?.docs ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'No notifications yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We\'ll notify you when there\'s something new',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          // Count unread
          final unreadCount = notifications
              .where((doc) => !(doc.data() as Map<String, dynamic>?)?['read'] as bool? ?? false)
              .length;

          return Column(
            children: [
              // Unread count badge
              if (unreadCount > 0)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.blue[50],
                  child: Text(
                    '$unreadCount unread notification${unreadCount > 1 ? 's' : ''}',
                    style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.w500),
                  ),
                ),
              // Notifications list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final doc = notifications[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final isRead = data['read'] ?? false;
                    final notificationType = data['type'] ?? 'general';
                    final createdAt = data['createdAt'] as Timestamp?;
                    final message = data['message'] ?? 'No message';

                    return Dismissible(
                      key: Key(doc.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        color: Colors.red[400],
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Notification'),
                            content: const Text('Are you sure you want to delete this notification?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (direction) async {
                        await _firestore
                            .collection('notifications')
                            .doc(doc.id)
                            .delete();
                      },
                      child: Card(
                        elevation: isRead ? 0.5 : 1,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: isRead ? Colors.white : Colors.blue[50],
                        child: InkWell(
                          onTap: () => _handleNotificationTap(context, data),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Icon based on type
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: _getNotificationColor(notificationType)
                                        .withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _getNotificationIcon(notificationType),
                                    color: _getNotificationColor(notificationType),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              _getNotificationTitle(notificationType),
                                              style: TextStyle(
                                                fontWeight: isRead
                                                    ? FontWeight.w500
                                                    : FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          if (!isRead)
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(
                                                color: Colors.blue,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        message,
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 13,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _formatTimestamp(createdAt),
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'shipping_request_status_update':
        return Icons.local_shipping;
      case 'shipment_delivered_confirmation':
        return Icons.check_circle;
      case 'payout_ready':
        return Icons.attach_money;
      case 'welcome':
        return Icons.waving_hand;
      case 'shipment_assigned':
        return Icons.assignment;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'shipping_request_status_update':
        return Colors.blue;
      case 'shipment_delivered_confirmation':
        return Colors.green;
      case 'payout_ready':
        return Colors.orange;
      case 'welcome':
        return Colors.purple;
      case 'shipment_assigned':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getNotificationTitle(String type) {
    switch (type) {
      case 'shipping_request_status_update':
        return 'Shipping Update';
      case 'shipment_delivered_confirmation':
        return 'Delivery Confirmed';
      case 'payout_ready':
        return 'Payout Ready';
      case 'welcome':
        return 'Welcome!';
      case 'shipment_assigned':
        return 'Shipment Assigned';
      default:
        return 'Notification';
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown time';
    final date = timestamp.toDate();
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d, y').format(date);
  }

  Future<void> _markAllAsRead(String userId) async {
    final snapshot = await _firestore
        .collection('notifications')
        .where('targetUserId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notifications marked as read')),
      );
    }
  }

  void _handleNotificationTap(BuildContext context, Map<String, dynamic> data) {
    final actionUrl = data['actionUrl'] as String?;
    final requestId = data['requestId'] as String?;

    // Navigate based on requestId or actionUrl
    if (requestId != null) {
      Navigator.pushNamed(context, '/shipping-detail', arguments: requestId);
    } else if (actionUrl != null && actionUrl.startsWith('/')) {
      Navigator.pushNamed(context, actionUrl);
    }
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shopsnports/providers/user_providers.dart';

class AlertsNotificationsScreen extends ConsumerStatefulWidget {
  const AlertsNotificationsScreen({super.key});

  @override
  ConsumerState<AlertsNotificationsScreen> createState() =>
      _AlertsNotificationsScreenState();
}

class _AlertsNotificationsScreenState
    extends ConsumerState<AlertsNotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts & Notifications'),
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Archived'),
            Tab(text: 'All'),
          ],
          indicatorColor: Colors.blue[700],
          labelColor: Colors.blue[700],
          unselectedLabelColor: Colors.grey,
        ),
      ),
      body: user == null
          ? const Center(
              child: Text('Please log in to view alerts'),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                // Active alerts
                _buildAlertsList(
                  userId: user.id,
                  filterStatus: 'active',
                ),
                // Archived alerts
                _buildAlertsList(
                  userId: user.id,
                  filterStatus: 'archived',
                ),
                // All alerts
                _buildAlertsList(
                  userId: user.id,
                  filterStatus: null,
                ),
              ],
            ),
    );
  }

  Widget _buildAlertsList({
    required String userId,
    required String? filterStatus,
  }) {
    Query query = _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50);

    if (filterStatus != null) {
      query = query.where('status', isEqualTo: filterStatus);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final notifications = snapshot.data?.docs ?? [];

        if (notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_off,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  filterStatus == 'active'
                      ? 'No active alerts'
                      : filterStatus == 'archived'
                          ? 'No archived alerts'
                          : 'No alerts yet',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final doc = notifications[index];
            final data = doc.data() as Map<String, dynamic>;

            return _buildNotificationCard(
              notificationId: doc.id,
              title: data['title'] ?? 'Notification',
              message: data['message'] ?? '',
              type: data['type'] ?? 'info',
              timestamp: data['createdAt'] as Timestamp?,
              status: data['status'] ?? 'active',
              isRead: data['isRead'] ?? false,
            );
          },
        );
      },
    );
  }

  Widget _buildNotificationCard({
    required String notificationId,
    required String title,
    required String message,
    required String type,
    required Timestamp? timestamp,
    required String status,
    required bool isRead,
  }) {
    Color typeColor = Colors.blue;
    IconData typeIcon = Icons.info;

    switch (type) {
      case 'shipment':
        typeColor = Colors.blue;
        typeIcon = Icons.local_shipping;
        break;
      case 'payment':
        typeColor = Colors.green;
        typeIcon = Icons.payment;
        break;
      case 'warning':
        typeColor = Colors.orange;
        typeIcon = Icons.warning;
        break;
      case 'error':
        typeColor = Colors.red;
        typeIcon = Icons.error;
        break;
      default:
        typeColor = Colors.blue;
        typeIcon = Icons.notifications;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Card(
        elevation: isRead ? 0 : 2,
        color: isRead ? Colors.white : Colors.blue[50],
        child: InkWell(
          onTap: () {
            _markAsRead(notificationId, !isRead);
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    typeIcon,
                    color: typeColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: isRead
                                        ? FontWeight.normal
                                        : FontWeight.bold,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.blue[700],
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatTime(timestamp),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (status == 'active')
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Active',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Action buttons
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'archive') {
                      _archiveNotification(notificationId);
                    } else if (value == 'delete') {
                      _deleteNotification(notificationId);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'archive',
                      child: Row(
                        children: [
                          Icon(Icons.archive, size: 18),
                          SizedBox(width: 8),
                          Text('Archive'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _markAsRead(String notificationId, bool read) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({
        'isRead': read,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating notification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _archiveNotification(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({
        'status': 'archived',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification archived'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error archiving notification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification deleted'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting notification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';

    final dateTime = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
    }
  }
}

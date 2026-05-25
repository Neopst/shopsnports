import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:cloud_functions/cloud_functions.dart';

class AdminNotificationsScreen extends ConsumerStatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  ConsumerState<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends ConsumerState<AdminNotificationsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  String? _selectedTypeFilter;
  String? _selectedStatusFilter;
  String? _selectedRoleFilter;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Management'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => setState(() {}),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filters',
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatsBar(),
          _buildFilterChips(),
          Expanded(
            child: _buildNotificationsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('notifications').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final notifications = snapshot.data!.docs;
        int total = notifications.length;
        int unread = 0;
        int failed = 0;

        for (final doc in notifications) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['read'] == false) unread++;
          if (data['deliveryStatus'] == 'failed') failed++;
        }

        return Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue[50],
          child: Row(
            children: [
              Expanded(
                child: _buildStatItem('Total', total, Colors.blue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem('Unread', unread, Colors.orange),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem('Failed', failed, Colors.red),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (_selectedTypeFilter != null)
              Chip(
                label: Text('Type: $_selectedTypeFilter'),
                onDeleted: () => setState(() => _selectedTypeFilter = null),
              ),
            if (_selectedStatusFilter != null) ...[
              const SizedBox(width: 8),
              Chip(
                label: Text('Status: $_selectedStatusFilter'),
                onDeleted: () => setState(() => _selectedStatusFilter = null),
              ),
            ],
            if (_selectedRoleFilter != null) ...[
              const SizedBox(width: 8),
              Chip(
                label: Text('Role: $_selectedRoleFilter'),
                onDeleted: () => setState(() => _selectedRoleFilter = null),
              ),
            ],
            if (_startDate != null || _endDate != null) ...[
              const SizedBox(width: 8),
              Chip(
                label: Text(
                  '${_startDate != null ? DateFormat('MM/dd').format(_startDate!) : ''}'
                  ' - '
                  '${_endDate != null ? DateFormat('MM/dd').format(_endDate!) : ''}',
                ),
                onDeleted: () {
                  setState(() {
                    _startDate = null;
                    _endDate = null;
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsList() {
    Query query = _firestore
        .collection('notifications')
        .orderBy('createdAt', descending: true);

    if (_selectedTypeFilter != null) {
      query = query.where('type', isEqualTo: _selectedTypeFilter);
    }

    if (_selectedStatusFilter != null) {
      if (_selectedStatusFilter == 'unread') {
        query = query.where('read', isEqualTo: false);
      } else if (_selectedStatusFilter == 'read') {
        query = query.where('read', isEqualTo: true);
      } else if (_selectedStatusFilter == 'failed') {
        query = query.where('deliveryStatus', isEqualTo: 'failed');
      }
    }

    if (_selectedRoleFilter != null) {
      query = query.where('targetRole', isEqualTo: _selectedRoleFilter);
    }

    if (_startDate != null) {
      query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate!));
    }

    if (_endDate != null) {
      final endOfDay = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
      query = query.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.limit(100).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final notifications = snapshot.data?.docs ?? [];

        if (notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text('No notifications found'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final doc = notifications[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildNotificationCard(doc, data);
          },
        );
      },
    );
  }

  Widget _buildNotificationCard(QueryDocumentSnapshot doc, Map<String, dynamic> data) {
    final type = data['type'] as String? ?? 'unknown';
    final isRead = data['read'] as bool? ?? false;
    final deliveryStatus = data['deliveryStatus'] as String? ?? 'pending';
    final targetRole = data['targetRole'] as String? ?? 'user';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isRead ? Colors.grey : Colors.blue,
          child: Icon(
            _getNotificationIcon(type),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          data['message'] ?? 'No message',
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: $type • Role: $targetRole'),
            Text(_formatTimestamp(data['createdAt'])),
            if (deliveryStatus == 'failed')
              Text(
                'Delivery Failed',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (deliveryStatus == 'failed')
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Resend',
                onPressed: () => _resendNotification(doc),
              ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showNotificationOptions(doc, data),
            ),
          ],
        ),
        onTap: () => _showNotificationDetails(doc, data),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'payout_ready':
      case 'payout_completed':
        return Icons.payment;
      case 'payout_request_generated':
        return Icons.request_quote;
      case 'shipping_update':
        return Icons.local_shipping;
      case 'invoice_ready_for_review':
        return Icons.receipt;
      case 'affiliate_application':
        return Icons.person_add;
      case 'admin_alert':
        return Icons.admin_panel_settings;
      default:
        return Icons.notifications;
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      final date = (timestamp as Timestamp).toDate();
      return DateFormat('MMM dd, yyyy HH:mm').format(date);
    } catch (_) {
      return 'Invalid date';
    }
  }

  Future<void> _showFilterDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Notifications'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Notification Type'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedTypeFilter,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('All')),
                  DropdownMenuItem(value: 'payout_ready', child: Text('Payout Ready')),
                  DropdownMenuItem(value: 'payout_completed', child: Text('Payout Completed')),
                  DropdownMenuItem(value: 'payout_request_generated', child: Text('Payout Request')),
                  DropdownMenuItem(value: 'shipping_update', child: Text('Shipping Update')),
                  DropdownMenuItem(value: 'invoice_ready_for_review', child: Text('Invoice Ready')),
                  DropdownMenuItem(value: 'affiliate_application', child: Text('Affiliate Application')),
                  DropdownMenuItem(value: 'admin_alert', child: Text('Admin Alert')),
                ],
                onChanged: (value) {
                  setState(() => _selectedTypeFilter = value);
                },
              ),
              const SizedBox(height: 16),
              const Text('Status'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedStatusFilter,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('All')),
                  DropdownMenuItem(value: 'unread', child: Text('Unread')),
                  DropdownMenuItem(value: 'read', child: Text('Read')),
                  DropdownMenuItem(value: 'failed', child: Text('Failed')),
                ],
                onChanged: (value) {
                  setState(() => _selectedStatusFilter = value);
                },
              ),
              const SizedBox(height: 16),
              const Text('Target Role'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedRoleFilter,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('All')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  DropdownMenuItem(value: 'affiliate', child: Text('Affiliate')),
                  DropdownMenuItem(value: 'user', child: Text('User')),
                  DropdownMenuItem(value: 'shipper', child: Text('Shipper')),
                ],
                onChanged: (value) {
                  setState(() => _selectedRoleFilter = value);
                },
              ),
              const SizedBox(height: 16),
              const Text('Date Range'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _startDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() => _startDate = date);
                        }
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_startDate != null
                          ? DateFormat('MM/dd').format(_startDate!)
                          : 'Start Date'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _endDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() => _endDate = date);
                        }
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_endDate != null
                          ? DateFormat('MM/dd').format(_endDate!)
                          : 'End Date'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Apply'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {});
    }
  }

  Future<void> _showNotificationDetails(QueryDocumentSnapshot doc, Map<String, dynamic> data) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(_getNotificationIcon(data['type'] as String? ?? 'unknown')),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                (data['type'] as String? ?? 'unknown').toUpperCase(),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Message', data['message'] ?? 'N/A'),
              _buildDetailRow('Type', data['type']?.toString().toUpperCase() ?? 'N/A'),
              _buildDetailRow('Target Role', data['targetRole']?.toString().toUpperCase() ?? 'N/A'),
              _buildDetailRow('Target User ID', data['targetUserId'] ?? 'N/A'),
              _buildDetailRow('Read', data['read'] == true ? 'Yes' : 'No'),
              _buildDetailRow('Delivery Status', data['deliveryStatus']?.toString().toUpperCase() ?? 'PENDING'),
              _buildDetailRow('Created', _formatTimestamp(data['createdAt'])),
              if (data['actionUrl'] != null)
                _buildDetailRow('Action URL', data['actionUrl']),
              if (data['payoutId'] != null)
                _buildDetailRow('Payout ID', data['payoutId']),
              if (data['affiliateId'] != null)
                _buildDetailRow('Affiliate ID', data['affiliateId']),
              if (data['invoiceId'] != null)
                _buildDetailRow('Invoice ID', data['invoiceId']),
              if (data['shippingRequestId'] != null)
                _buildDetailRow('Shipping Request ID', data['shippingRequestId']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (data['deliveryStatus'] == 'failed')
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _resendNotification(doc);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Resend'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showNotificationOptions(QueryDocumentSnapshot doc, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                _showNotificationDetails(doc, data);
              },
            ),
            if (data['deliveryStatus'] == 'failed')
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Resend'),
                onTap: () {
                  Navigator.pop(context);
                  _resendNotification(doc);
                },
              ),
            ListTile(
              leading: const Icon(Icons.mark_email_read),
              title: const Text('Mark as Read'),
              onTap: () {
                Navigator.pop(context);
                _markAsRead(doc);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete'),
              onTap: () {
                Navigator.pop(context);
                _deleteNotification(doc);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resendNotification(QueryDocumentSnapshot doc) async {
    setState(() => _isLoading = true);

    try {
      final data = doc.data() as Map<String, dynamic>;
      final targetUserId = data['targetUserId'] as String?;
      final message = data['message'] as String?;

      if (targetUserId == null || message == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cannot resend: missing data')),
          );
        }
        return;
      }

      // Call Cloud Function to resend notification
      await _functions.httpsCallable('sendPushNotification').call({
        'targetUserIds': [targetUserId],
        'title': 'Notification',
        'body': message,
        'data': {
          'originalNotificationId': doc.id,
          'type': data['type'],
          'actionUrl': data['actionUrl'],
        },
      });

      // Update delivery status
      await doc.reference.update({
        'deliveryStatus': 'sent',
        'resentAt': FieldValue.serverTimestamp(),
        'resendCount': FieldValue.increment(1),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification resent successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(QueryDocumentSnapshot doc) async {
    try {
      await doc.reference.update({
        'read': true,
        'readAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Marked as read')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      }
    }
  }

  Future<void> _deleteNotification(QueryDocumentSnapshot doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notification'),
        content: const Text('Are you sure you want to delete this notification?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await doc.reference.delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification deleted')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      }
    }
  }
}
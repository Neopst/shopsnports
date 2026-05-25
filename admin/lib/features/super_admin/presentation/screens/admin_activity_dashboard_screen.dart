import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminActivityDashboardScreen extends StatefulWidget {
  const AdminActivityDashboardScreen({super.key});

  @override
  State<AdminActivityDashboardScreen> createState() => _AdminActivityDashboardScreenState();
}

class _AdminActivityDashboardScreenState extends State<AdminActivityDashboardScreen> {
  String _selectedFilter = 'all';
  DateTimeRange? _dateRange;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Activity Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildQuickStats(),
          const Divider(height: 1),
          Expanded(
            child: _buildActivityFeed(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: StreamBuilder<QuerySnapshot>(
        stream: _getActivityStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final activities = snapshot.data!.docs;
          final todayActivities = activities.where((doc) {
            final timestamp = (doc.data() as Map)['timestamp'] as Timestamp?;
            if (timestamp == null) return false;
            final date = timestamp.toDate();
            return _isSameDay(date, DateTime.now());
          }).length;

          final weekActivities = activities.where((doc) {
            final timestamp = (doc.data() as Map)['timestamp'] as Timestamp?;
            if (timestamp == null) return false;
            final date = timestamp.toDate();
            return _isThisWeek(date);
          }).length;

          final uniqueAdmins = activities.map((doc) {
            return (doc.data() as Map)['userId'] as String?;
          }).where((id) => id != null).toSet().length;

          final criticalActions = activities.where((doc) {
            final action = (doc.data() as Map)['action'] as String?;
            return action != null && _isCriticalAction(action);
          }).length;

          return Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Today',
                  value: todayActivities.toString(),
                  icon: Icons.today,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'This Week',
                  value: weekActivities.toString(),
                  icon: Icons.calendar_view_week,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'Active Admins',
                  value: uniqueAdmins.toString(),
                  icon: Icons.people,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'Critical Actions',
                  value: criticalActions.toString(),
                  icon: Icons.warning,
                  color: Colors.red,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActivityFeed() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getActivityStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No activity yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final activities = snapshot.data!.docs;

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: activities.length,
          itemBuilder: (context, index) {
            final activity = activities[index].data() as Map<String, dynamic>;
            return _ActivityCard(activity: activity);
          },
        );
      },
    );
  }

  Stream<QuerySnapshot> _getActivityStream() {
    Query query = FirebaseFirestore.instance
        .collection('admin_activity_logs')
        .orderBy('timestamp', descending: true);

    if (_dateRange != null) {
      query = query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(_dateRange!.start));
      query = query.where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(_dateRange!.end));
    }

    if (_selectedFilter != 'all') {
      query = query.where('action', isEqualTo: _selectedFilter);
    }

    return query.limit(100).snapshots();
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Activities'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Action Type:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _selectedFilter == 'all',
                  onSelected: (selected) {
                    setState(() => _selectedFilter = 'all');
                    Navigator.pop(context);
                  },
                ),
                FilterChip(
                  label: const Text('Create'),
                  selected: _selectedFilter == 'create',
                  onSelected: (selected) {
                    setState(() => _selectedFilter = 'create');
                    Navigator.pop(context);
                  },
                ),
                FilterChip(
                  label: const Text('Update'),
                  selected: _selectedFilter == 'update',
                  onSelected: (selected) {
                    setState(() => _selectedFilter = 'update');
                    Navigator.pop(context);
                  },
                ),
                FilterChip(
                  label: const Text('Delete'),
                  selected: _selectedFilter == 'delete',
                  onSelected: (selected) {
                    setState(() => _selectedFilter = 'delete');
                    Navigator.pop(context);
                  },
                ),
                FilterChip(
                  label: const Text('Login'),
                  selected: _selectedFilter == 'login',
                  onSelected: (selected) {
                    setState(() => _selectedFilter = 'login');
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Date Range:'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: Text(_dateRange == null
                        ? 'Select Range'
                        : '${DateFormat('MM/dd').format(_dateRange!.start)} - ${DateFormat('MM/dd').format(_dateRange!.end)}'),
                    onPressed: _selectDateRange,
                  ),
                ),
                if (_dateRange != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() => _dateRange = null);
                    },
                  ),
                ],
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  bool _isThisWeek(DateTime date) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return date.isAfter(startOfWeek) && date.isBefore(endOfWeek);
  }

  bool _isCriticalAction(String action) {
    return ['delete', 'admin_created', 'admin_deleted', 'permission_changed']
        .contains(action.toLowerCase());
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color.withOpacity(0.8),
                ),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final Map<String, dynamic> activity;

  const _ActivityCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    final action = activity['action'] as String? ?? 'Unknown';
    final timestamp = activity['timestamp'] as Timestamp?;
    final userEmail = activity['userEmail'] as String? ?? 'Unknown';
    final details = activity['details'] as Map<String, dynamic>? ?? {};

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: _buildActionIcon(action),
        title: Text(
          _formatAction(action),
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(userEmail),
            if (details.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                _formatDetails(details),
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ],
        ),
        trailing: Text(
          timestamp != null
              ? _formatTimestamp(timestamp.toDate())
              : 'Unknown',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildActionIcon(String action) {
    IconData icon;
    Color color;

    switch (action.toLowerCase()) {
      case 'create':
        icon = Icons.add_circle;
        color = Colors.green;
        break;
      case 'update':
        icon = Icons.edit;
        color = Colors.blue;
        break;
      case 'delete':
        icon = Icons.delete;
        color = Colors.red;
        break;
      case 'login':
        icon = Icons.login;
        color = Colors.purple;
        break;
      case 'logout':
        icon = Icons.logout;
        color = Colors.orange;
        break;
      default:
        icon = Icons.info;
        color = Colors.grey;
    }

    return CircleAvatar(
      backgroundColor: color.withOpacity(0.2),
      child: Icon(icon, color: color, size: 20),
    );
  }

  String _formatAction(String action) {
    return action.split('_').map((word) {
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  String _formatDetails(Map<String, dynamic> details) {
    return details.entries
        .map((e) => '${e.key}: ${e.value}')
        .join(', ');
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MM/dd/yyyy').format(timestamp);
    }
  }
}
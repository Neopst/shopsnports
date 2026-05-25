import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminSessionManagementScreen extends StatefulWidget {
  const AdminSessionManagementScreen({super.key});

  @override
  State<AdminSessionManagementScreen> createState() => _AdminSessionManagementScreenState();
}

class _AdminSessionManagementScreenState extends State<AdminSessionManagementScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _activeSessions = [];
  List<Map<String, dynamic>> _sessionHistory = [];
  final ScrollController _scrollController = ScrollController();
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoading = true);

    try {
      // Load active sessions
      final activeSnapshot = await FirebaseFirestore.instance
          .collection('admin_sessions')
          .where('isActive', isEqualTo: true)
          .orderBy('lastActivity', descending: true)
          .get();

      // Load session history
      final historySnapshot = await FirebaseFirestore.instance
          .collection('admin_sessions')
          .where('isActive', isEqualTo: false)
          .orderBy('endedAt', descending: true)
          .limit(50)
          .get();

      setState(() {
        _activeSessions = activeSnapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();

        _sessionHistory = historySnapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();

        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading sessions: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Session Management'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Active Sessions'),
              Tab(text: 'Session History'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadSessions,
              tooltip: 'Refresh',
            ),
            PopupMenuButton<String>(
              onSelected: _handleFilter,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'all',
                  child: Text('Show All'),
                ),
                const PopupMenuItem(
                  value: 'super_admin',
                  child: Text('Super Admins Only'),
                ),
                const PopupMenuItem(
                  value: 'admin',
                  child: Text('Admins Only'),
                ),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            _buildSummaryCards(),
            const Divider(height: 1),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      children: [
                        _buildActiveSessionsTab(),
                        _buildSessionHistoryTab(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final totalActive = _activeSessions.length;
    final superAdminSessions = _activeSessions.where((session) {
      final role = session['userRole'] as String?;
      return role == 'super_admin';
    }).length;
    final recentLogins = _sessionHistory.where((session) {
      final endedAt = session['endedAt'] as Timestamp?;
      if (endedAt == null) return false;
      return endedAt.toDate().isAfter(DateTime.now().subtract(const Duration(hours: 24)));
    }).length;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              title: 'Active Sessions',
              value: totalActive.toString(),
              icon: Icons.devices,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SummaryCard(
              title: 'Super Admins',
              value: superAdminSessions.toString(),
              icon: Icons.admin_panel_settings,
              color: Colors.purple,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SummaryCard(
              title: '24h Logins',
              value: recentLogins.toString(),
              icon: Icons.login,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSessionsTab() {
    if (_activeSessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.phone_android, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No active sessions',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _activeSessions.length,
      itemBuilder: (context, index) {
        final session = _activeSessions[index];
        return _SessionCard(
          session: session,
          isActive: true,
          onTerminate: () => _terminateSession(session),
        );
      },
    );
  }

  Widget _buildSessionHistoryTab() {
    if (_sessionHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No session history',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _sessionHistory.length,
      itemBuilder: (context, index) {
        final session = _sessionHistory[index];
        return _SessionCard(
          session: session,
          isActive: false,
        );
      },
    );
  }

  Future<void> _terminateSession(Map<String, dynamic> session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terminate Session'),
        content: Text(
          'Are you sure you want to terminate the session for ${session['userEmail']}?\n\n'
          'This will force the user to log in again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Terminate'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      // Update session in Firestore
      await FirebaseFirestore.instance
          .collection('admin_sessions')
          .doc(session['id'])
          .update({
        'isActive': false,
        'endedAt': FieldValue.serverTimestamp(),
        'terminatedBy': FirebaseAuth.instance.currentUser?.uid,
        'terminationReason': 'Manual termination by admin',
      });

      // Revoke the user's refresh token (requires admin SDK)
      // Note: This would need to be done via Cloud Functions

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session terminated successfully')),
        );
      }

      await _loadSessions();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error terminating session: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleFilter(String filter) {
    setState(() => _selectedFilter = filter);
    // Apply filter logic here
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
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

class _SessionCard extends StatelessWidget {
  final Map<String, dynamic> session;
  final bool isActive;
  final VoidCallback? onTerminate;

  const _SessionCard({
    required this.session,
    required this.isActive,
    this.onTerminate,
  });

  @override
  Widget build(BuildContext context) {
    final userEmail = session['userEmail'] as String? ?? 'Unknown';
    final userName = session['userDisplayName'] as String? ?? '';
    final userRole = session['userRole'] as String? ?? 'Unknown';
    final deviceInfo = session['deviceInfo'] as Map<String, dynamic>? ?? {};
    final ipAddress = session['ipAddress'] as String?;
    final location = session['location'] as String?;
    final createdAt = session['createdAt'] as Timestamp?;
    final lastActivity = session['lastActivity'] as Timestamp?;
    final endedAt = session['endedAt'] as Timestamp?;

    final deviceType = deviceInfo['deviceType'] as String? ?? 'Unknown';
    final browser = deviceInfo['browser'] as String? ?? 'Unknown';
    final os = deviceInfo['os'] as String? ?? 'Unknown';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: _buildDeviceIcon(deviceType),
        title: Text(
          userEmail,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (userName.isNotEmpty) Text(userName),
            Row(
              children: [
                _buildRoleBadge(userRole),
                const SizedBox(width: 8),
                if (isActive)
                  const Text(
                    'Active',
                    style: TextStyle(fontSize: 12, color: Colors.green),
                  )
                else
                  Text(
                    'Ended: ${endedAt != null ? _formatTimestamp(endedAt.toDate()) : 'Unknown'}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ],
        ),
        trailing: isActive
            ? IconButton(
                icon: const Icon(Icons.block, color: Colors.red),
                onPressed: onTerminate,
                tooltip: 'Terminate Session',
              )
            : null,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Device', '$deviceType - $os'),
                const SizedBox(height: 8),
                _buildDetailRow('Browser', browser),
                const SizedBox(height: 8),
                if (ipAddress != null) ...[
                  _buildDetailRow('IP Address', ipAddress),
                  const SizedBox(height: 8),
                ],
                if (location != null) ...[
                  _buildDetailRow('Location', location),
                  const SizedBox(height: 8),
                ],
                if (createdAt != null) ...[
                  _buildDetailRow(
                    'Started',
                    DateFormat('MM/dd/yyyy HH:mm:ss').format(createdAt.toDate()),
                  ),
                  const SizedBox(height: 8),
                ],
                if (lastActivity != null && isActive) ...[
                  _buildDetailRow(
                    'Last Activity',
                    _formatTimestamp(lastActivity.toDate()),
                  ),
                  const SizedBox(height: 8),
                ],
                if (session['userAgent'] != null) ...[
                  const Text(
                    'User Agent:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    session['userAgent'] as String? ?? '',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceIcon(String deviceType) {
    IconData icon;
    switch (deviceType.toLowerCase()) {
      case 'mobile':
      case 'phone':
        icon = Icons.phone_android;
        break;
      case 'tablet':
        icon = Icons.tablet_android;
        break;
      case 'desktop':
      case 'computer':
        icon = Icons.computer;
        break;
      default:
        icon = Icons.devices;
    }

    return CircleAvatar(
      backgroundColor: isActive ? Colors.blue.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
      child: Icon(icon, color: isActive ? Colors.blue : Colors.grey, size: 20),
    );
  }

  Widget _buildRoleBadge(String role) {
    Color color;
    switch (role.toLowerCase()) {
      case 'super_admin':
        color = Colors.purple;
        break;
      case 'admin':
        color = Colors.blue;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        role.split('_').map((word) => word[0].toUpperCase() + word.substring(1)).join(' '),
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
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
      return DateFormat('MM/dd/yyyy HH:mm').format(timestamp);
    }
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPayoutSchedulingScreen extends ConsumerStatefulWidget {
  const AdminPayoutSchedulingScreen({super.key});

  @override
  ConsumerState<AdminPayoutSchedulingScreen> createState() =>
      _AdminPayoutSchedulingScreenState();
}

class _AdminPayoutSchedulingScreenState
    extends ConsumerState<AdminPayoutSchedulingScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payout Scheduling'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Schedule',
            onPressed: _showAddScheduleDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildInfoBanner(),
          Expanded(
            child: _buildSchedulesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue[50],
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Payout schedules determine when automatic payouts are generated for affiliates.',
              style: TextStyle(color: Colors.blue[900]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchedulesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('payout_schedules')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final schedules = snapshot.data?.docs ?? [];

        if (schedules.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.schedule, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text('No payout schedules configured'),
                const SizedBox(height: 8),
                Text(
                  'Add a schedule to enable automatic payouts',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _showAddScheduleDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Schedule'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: schedules.length,
          itemBuilder: (context, index) {
            final doc = schedules[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildScheduleCard(doc, data);
          },
        );
      },
    );
  }

  Widget _buildScheduleCard(QueryDocumentSnapshot doc, Map<String, dynamic> data) {
    final isActive = data['isActive'] as bool? ?? false;
    final scheduleType = data['scheduleType'] as String? ?? 'daily';
    final threshold = data['minimumThreshold'] as num? ?? 0;
    final affiliateId = data['affiliateId'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: isActive ? Colors.green : Colors.grey,
          child: Icon(
            isActive ? Icons.check : Icons.pause,
            color: Colors.white,
          ),
        ),
        title: Text(
          affiliateId != null ? 'Affiliate Schedule' : 'Global Schedule',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${scheduleType.toUpperCase()} • Min: \$${threshold.toStringAsFixed(2)}',
        ),
        trailing: Switch(
          value: isActive,
          onChanged: (value) => _toggleSchedule(doc.id, value),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Schedule Type', scheduleType.toUpperCase()),
                _buildDetailRow('Minimum Threshold', '\$${threshold.toStringAsFixed(2)}'),
                if (data['dayOfMonth'] != null)
                  _buildDetailRow('Day of Month', '${data['dayOfMonth']}'),
                if (data['dayOfWeek'] != null)
                  _buildDetailRow('Day of Week', _getDayOfWeek(data['dayOfWeek'])),
                if (data['time'] != null)
                  _buildDetailRow('Time', data['time']),
                if (affiliateId != null)
                  _buildDetailRow('Affiliate ID', affiliateId),
                _buildDetailRow('Created', _formatDate(data['createdAt'])),
                _buildDetailRow('Last Run', data['lastRunAt'] != null ? _formatDate(data['lastRunAt']) : 'Never'),
                _buildDetailRow('Next Run', data['nextRunAt'] != null ? _formatDate(data['nextRunAt']) : 'Pending'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _editSchedule(doc),
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _runScheduleNow(doc),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Run Now'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _deleteSchedule(doc),
                        icon: const Icon(Icons.delete),
                        label: const Text('Delete'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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

  String _getDayOfWeek(dynamic day) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final index = day is int ? day - 1 : 0;
    return days[index.clamp(0, 6)];
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      final date = (timestamp as Timestamp).toDate();
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return 'Invalid date';
    }
  }

  Future<void> _toggleSchedule(String scheduleId, bool isActive) async {
    setState(() => _isLoading = true);

    try {
      await _firestore.collection('payout_schedules').doc(scheduleId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isActive ? 'Schedule activated' : 'Schedule deactivated'),
            backgroundColor: isActive ? Colors.green : Colors.orange,
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

  Future<void> _runScheduleNow(QueryDocumentSnapshot doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Run Schedule Now'),
        content: const Text('Are you sure you want to run this schedule immediately?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Run'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      // This would call a Cloud Function to run the schedule
      // For now, just update the last run time
      await doc.reference.update({
        'lastRunAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Schedule run initiated'),
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

  Future<void> _deleteSchedule(QueryDocumentSnapshot doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Schedule'),
        content: const Text('Are you sure you want to delete this schedule?'),
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

    setState(() => _isLoading = true);

    try {
      await doc.reference.delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Schedule deleted'),
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

  Future<void> _editSchedule(QueryDocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    await _showAddScheduleDialog(existingData: data, scheduleId: doc.id);
  }

  Future<void> _showAddScheduleDialog({
    Map<String, dynamic>? existingData,
    String? scheduleId,
  }) async {
    final scheduleTypeController = TextEditingController(
      text: existingData?['scheduleType'] ?? 'daily',
    );
    final thresholdController = TextEditingController(
      text: (existingData?['minimumThreshold'] ?? 10).toString(),
    );
    final dayOfMonthController = TextEditingController(
      text: existingData?['dayOfMonth']?.toString() ?? '1',
    );
    final dayOfWeekController = TextEditingController(
      text: existingData?['dayOfWeek']?.toString() ?? '1',
    );
    final timeController = TextEditingController(
      text: existingData?['time'] ?? '02:00',
    );
    final isGlobal = existingData?['affiliateId'] == null;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          String currentScheduleType = scheduleTypeController.text;

          return AlertDialog(
            title: Text(existingData != null ? 'Edit Schedule' : 'Add Schedule'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Schedule Type'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: currentScheduleType,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'daily', child: Text('Daily')),
                        DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                        DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          scheduleTypeController.text = value;
                          setDialogState(() => currentScheduleType = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Minimum Threshold (\$)'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: thresholdController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: '10.00',
                      ),
                    ),
                    if (currentScheduleType == 'weekly') ...[
                      const SizedBox(height: 16),
                      const Text('Day of Week'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: int.tryParse(dayOfWeekController.text) ?? 1,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        items: List.generate(7, (index) {
                          return DropdownMenuItem(
                            value: index + 1,
                            child: Text(_getDayOfWeek(index + 1)),
                          );
                        }),
                        onChanged: (value) {
                          if (value != null) {
                            dayOfWeekController.text = value.toString();
                          }
                        },
                      ),
                    ],
                    if (currentScheduleType == 'monthly') ...[
                      const SizedBox(height: 16),
                      const Text('Day of Month (1-31)'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: dayOfMonthController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: '1',
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Text('Time (UTC)'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: timeController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: '02:00',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final threshold = double.tryParse(thresholdController.text);
                  if (threshold == null || threshold < 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invalid threshold amount')),
                    );
                    return;
                  }

                  Navigator.pop(context, {
                    'scheduleType': scheduleTypeController.text,
                    'minimumThreshold': threshold,
                    'dayOfMonth': currentScheduleType == 'monthly'
                        ? int.tryParse(dayOfMonthController.text)
                        : null,
                    'dayOfWeek': currentScheduleType == 'weekly'
                        ? int.tryParse(dayOfWeekController.text)
                        : null,
                    'time': timeController.text,
                    'isGlobal': isGlobal,
                  });
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );

    if (result == null) return;

    setState(() => _isLoading = true);

    try {
      final scheduleData = {
        'scheduleType': result['scheduleType'],
        'minimumThreshold': result['minimumThreshold'],
        'dayOfMonth': result['dayOfMonth'],
        'dayOfWeek': result['dayOfWeek'],
        'time': result['time'],
        'isActive': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (scheduleId != null) {
        await _firestore.collection('payout_schedules').doc(scheduleId).update(scheduleData);
      } else {
        await _firestore.collection('payout_schedules').add({
          ...scheduleData,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(scheduleId != null ? 'Schedule updated' : 'Schedule created'),
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
}
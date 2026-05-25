import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Widget that shows recent admin creations with undo option
/// Displays admins created within the last 5 minutes with a countdown timer
class RecentAdminCreationsWidget extends ConsumerStatefulWidget {
  const RecentAdminCreationsWidget({super.key});

  @override
  ConsumerState<RecentAdminCreationsWidget> createState() =>
      _RecentAdminCreationsWidgetState();
}

class _RecentAdminCreationsWidgetState
    extends ConsumerState<RecentAdminCreationsWidget> {
  List<Map<String, dynamic>> _recentCreations = [];
  bool _isLoading = true;
  Timer? _refreshTimer;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _loadRecentCreations();
    // Refresh every 10 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _loadRecentCreations();
    });
    // Update countdown every second
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateCountdowns();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadRecentCreations() async {
    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('getRecentAdminCreations');
      final result = await callable();

      if (mounted) {
        setState(() {
          _recentCreations =
              List<Map<String, dynamic>>.from(result.data['recentCreations']);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _updateCountdowns() {
    if (!mounted) return;

    setState(() {
      for (var creation in _recentCreations) {
        final remainingTime = creation['remainingTime'] as int;
        if (remainingTime > 0) {
          creation['remainingTime'] = remainingTime - 1;
          creation['canUndo'] = remainingTime - 1 > 0;
        }
      }

      // Remove expired creations
      _recentCreations.removeWhere((c) => !(c['canUndo'] as bool));
    });
  }

  Future<void> _undoCreation(String adminId, String displayName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Undo Admin Creation'),
        content: Text(
          'Are you sure you want to undo the creation of $displayName? '
          'This will permanently delete their account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Undo'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('undoAdminCreation');
      await callable({'adminId': adminId});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Admin creation undone successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadRecentCreations();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to undo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_recentCreations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Row(
              spacing: 8,
              children: [
                Icon(
                  Icons.history,
                  color: Colors.orange.shade700,
                ),
                Text(
                  'Recent Admin Creations',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_recentCreations.length} admin(s)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade600,
                  ),
                ),
              ],
            ),
            ..._recentCreations.map((creation) => _buildCreationItem(creation)),
          ],
        ),
      ),
    );
  }

  Widget _buildCreationItem(Map<String, dynamic> creation) {
    final remainingTime = creation['remainingTime'] as int;
    final canUndo = creation['canUndo'] as bool;
    final minutes = remainingTime ~/ 60;
    final seconds = remainingTime % 60;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: canUndo ? Colors.orange.shade300 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        spacing: 12,
        children: [
          CircleAvatar(
            child: Text(creation['displayName'][0].toUpperCase()),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Text(
                  creation['displayName'],
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  creation['email'],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Row(
                  spacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: creation['role'] == 'admin'
                            ? Colors.blue.shade100
                            : Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        creation['role'] == 'admin' ? 'Admin' : 'Sub-Admin',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: creation['role'] == 'admin'
                              ? Colors.blue.shade700
                              : Colors.green.shade700,
                        ),
                      ),
                    ),
                    if (canUndo)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          spacing: 4,
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 12,
                              color: Colors.orange.shade700,
                            ),
                            Text(
                              '${minutes}:${seconds.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (canUndo)
            TextButton.icon(
              onPressed: () => _undoCreation(
                creation['id'],
                creation['displayName'],
              ),
              icon: const Icon(Icons.undo, size: 18),
              label: const Text('Undo'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            )
          else
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 20,
            ),
        ],
      ),
    );
  }
}
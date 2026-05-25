import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:admin_dashboard/features/auth/data/providers/auth_providers.dart';
import '../../data/models/notification_preferences.dart';
import '../providers/notification_providers.dart';

class UserNotificationPreferencesScreen extends ConsumerStatefulWidget {
  const UserNotificationPreferencesScreen({super.key});

  @override
  ConsumerState<UserNotificationPreferencesScreen> createState() =>
      _UserNotificationPreferencesScreenState();
}

class _UserNotificationPreferencesScreenState
    extends ConsumerState<UserNotificationPreferencesScreen> {
  @override
  Widget build(BuildContext context) {
    final preferencesAsync = ref.watch(notificationPreferencesProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Notification Preferences'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: preferencesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $err'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(notificationPreferencesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (prefs) {
          if (prefs == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No preferences found',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Create Preferences'),
                    onPressed: () => _createDefaultPreferences(),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection(
                  'Notification Categories',
                  'Choose which types of notifications you want to receive',
                  [
                    _buildSwitchTile(
                      'Sales',
                      'Get notified about sales and promotions',
                      Icons.local_offer,
                      prefs.salesEnabled,
                      (value) => _updatePreference(
                        prefs.copyWith(salesEnabled: value),
                      ),
                    ),
                    _buildSwitchTile(
                      'Orders',
                      'Get notified about new orders and order updates',
                      Icons.shopping_cart,
                      prefs.ordersEnabled,
                      (value) => _updatePreference(
                        prefs.copyWith(ordersEnabled: value),
                      ),
                    ),
                    _buildSwitchTile(
                      'Reviews',
                      'Get notified about new product reviews',
                      Icons.star,
                      prefs.reviewsEnabled,
                      (value) => _updatePreference(
                        prefs.copyWith(reviewsEnabled: value),
                      ),
                    ),
                    _buildSwitchTile(
                      'Users',
                      'Get notified about user registrations and updates',
                      Icons.person,
                      prefs.usersEnabled,
                      (value) => _updatePreference(
                        prefs.copyWith(usersEnabled: value),
                      ),
                    ),
                    _buildSwitchTile(
                      'Inventory',
                      'Get notified about inventory changes',
                      Icons.inventory,
                      prefs.inventoryEnabled,
                      (value) => _updatePreference(
                        prefs.copyWith(inventoryEnabled: value),
                      ),
                    ),
                    _buildSwitchTile(
                      'System',
                      'Get notified about system updates and maintenance',
                      Icons.settings,
                      prefs.systemEnabled,
                      (value) => _updatePreference(
                        prefs.copyWith(systemEnabled: value),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSection(
                  'Delivery Methods',
                  'Choose how you want to receive notifications',
                  [
                    _buildSwitchTile(
                      'Email Notifications',
                      'Receive notifications via email',
                      Icons.email,
                      prefs.emailNotifications,
                      (value) => _updatePreference(
                        prefs.copyWith(emailNotifications: value),
                      ),
                    ),
                    _buildSwitchTile(
                      'Push Notifications',
                      'Receive push notifications on your device',
                      Icons.notifications_active,
                      prefs.pushNotifications,
                      (value) => _updatePreference(
                        prefs.copyWith(pushNotifications: value),
                      ),
                    ),
                    _buildSwitchTile(
                      'Sound Alerts',
                      'Play sound when receiving notifications',
                      Icons.volume_up,
                      prefs.soundAlert,
                      (value) => _updatePreference(
                        prefs.copyWith(soundAlert: value),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSection(
                  'Quiet Hours',
                  'Set a time period when you don\'t want to receive notifications',
                  [
                    _buildTimeTile(
                      'Start Time',
                      'Quiet hours begin',
                      prefs.quietHoursStart,
                      (time) => _updatePreference(
                        prefs.copyWith(quietHoursStart: time),
                      ),
                    ),
                    _buildTimeTile(
                      'End Time',
                      'Quiet hours end',
                      prefs.quietHoursEnd,
                      (time) => _updatePreference(
                        prefs.copyWith(quietHoursEnd: time),
                      ),
                    ),
                    if (prefs.quietHoursStart != null &&
                        prefs.quietHoursEnd != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Quiet hours: ${_formatTime(prefs.quietHoursStart!)} - ${_formatTime(prefs.quietHoursEnd!)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 32),
                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.restore),
                    label: const Text('Reset to Defaults'),
                    onPressed: () => _resetToDefaults(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection(String title, String description, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      title: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[700]),
          const SizedBox(width: 12),
          Text(title),
        ],
      ),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      activeColor: Theme.of(context).primaryColor,
    );
  }

  Widget _buildTimeTile(
    String title,
    String subtitle,
    TimeOfDay? time,
    ValueChanged<TimeOfDay?> onChanged,
  ) {
    return ListTile(
      title: Row(
        children: [
          Icon(Icons.access_time, size: 20, color: Colors.grey[700]),
          const SizedBox(width: 12),
          Text(title),
        ],
      ),
      subtitle: Text(subtitle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            time != null ? _formatTime(time) : 'Not set',
            style: TextStyle(
              color: time != null ? Colors.black87 : Colors.grey,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 8),
          if (time != null)
            IconButton(
              icon: const Icon(Icons.clear, size: 20),
              onPressed: () => onChanged(null),
              tooltip: 'Clear',
            ),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: time ?? const TimeOfDay(hour: 9, minute: 0),
        );
        if (picked != null) {
          onChanged(picked);
        }
      },
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _updatePreference(NotificationPreferences prefs) async {
    final authState = ref.read(authStateProvider);
    final userId = authState.value?.uid;
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not logged in')),
        );
      }
      return;
    }

    try {
      final repo = ref.read(notificationRepositoryProvider);
      await repo.savePreferences(userId, prefs);
      ref.invalidate(notificationPreferencesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preferences updated'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating preferences: $e')),
        );
      }
    }
  }

  Future<void> _createDefaultPreferences() async {
    final authState = ref.read(authStateProvider);
    final userId = authState.value?.uid;
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not logged in')),
        );
      }
      return;
    }

    try {
      final repo = ref.read(notificationRepositoryProvider);
      final defaultPrefs = NotificationPreferences();
      await repo.savePreferences(userId, defaultPrefs);
      ref.invalidate(notificationPreferencesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Default preferences created'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating preferences: $e')),
        );
      }
    }
  }

  Future<void> _resetToDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults'),
        content: const Text(
          'Are you sure you want to reset all notification preferences to default values?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _createDefaultPreferences();
    }
  }
}
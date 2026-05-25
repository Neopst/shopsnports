import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationPreferencesScreen extends ConsumerStatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  ConsumerState<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends ConsumerState<NotificationPreferencesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Map<String, bool> _preferences = {};
  bool _isLoading = true;
  bool _isSaving = false;

  // Default notification preferences
  final Map<String, bool> _defaultPreferences = {
    // Payout notifications
    'payout_ready': true,
    'payout_completed': true,
    'payout_failed': true,

    // Shipping notifications
    'shipping_status_update': true,
    'shipping_delivered': true,
    'shipping_tracking_assigned': true,

    // Invoice notifications
    'invoice_ready': true,
    'invoice_overdue': true,
    'invoice_reminder': true,

    // Affiliate notifications
    'affiliate_application_approved': true,
    'affiliate_application_rejected': true,
    'affiliate_commission_earned': true,

    // Admin notifications
    'admin_alerts': true,
    'system_updates': false,

    // General settings
    'push_enabled': true,
    'email_enabled': true,
    'quiet_hours_enabled': false,
  };

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() {
          _preferences = Map.from(_defaultPreferences);
          _isLoading = false;
        });
        return;
      }

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('notifications')
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _preferences = {
            ..._defaultPreferences,
            ...data.map((key, value) => MapEntry(key, value is bool ? value : false)),
          };
        });
      } else {
        setState(() {
          _preferences = Map.from(_defaultPreferences);
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading preferences: $error')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePreferences() async {
    setState(() => _isSaving = true);

    try {
      final user = _auth.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not logged in')),
          );
        }
        return;
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('notifications')
          .set({
            ..._preferences,
            updatedAt: FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preferences saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving preferences: $error')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Preferences'),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton.icon(
              onPressed: _savePreferences,
              icon: const Icon(Icons.save),
              label: const Text('Save'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGeneralSettings(),
                  const SizedBox(height: 24),
                  _buildPayoutNotifications(),
                  const SizedBox(height: 24),
                  _buildShippingNotifications(),
                  const SizedBox(height: 24),
                  _buildInvoiceNotifications(),
                  const SizedBox(height: 24),
                  _buildAffiliateNotifications(),
                  const SizedBox(height: 24),
                  _buildAdminNotifications(),
                ],
              ),
            ),
    );
  }

  Widget _buildGeneralSettings() {
    return _buildSection(
      'General Settings',
      [
        _buildSwitchTile(
          'Push Notifications',
          'Receive push notifications on your device',
          'push_enabled',
          icon: Icons.notifications,
        ),
        _buildSwitchTile(
          'Email Notifications',
          'Receive notifications via email',
          'email_enabled',
          icon: Icons.email,
        ),
        _buildSwitchTile(
          'Quiet Hours',
          'Disable notifications during quiet hours (10 PM - 8 AM)',
          'quiet_hours_enabled',
          icon: Icons.bedtime,
        ),
      ],
    );
  }

  Widget _buildPayoutNotifications() {
    return _buildSection(
      'Payout Notifications',
      [
        _buildSwitchTile(
          'Payout Ready',
          'When a payout is ready for processing',
          'payout_ready',
          icon: Icons.payment,
        ),
        _buildSwitchTile(
          'Payout Completed',
          'When a payout has been processed',
          'payout_completed',
          icon: Icons.check_circle,
        ),
        _buildSwitchTile(
          'Payout Failed',
          'When a payout processing fails',
          'payout_failed',
          icon: Icons.error,
        ),
      ],
    );
  }

  Widget _buildShippingNotifications() {
    return _buildSection(
      'Shipping Notifications',
      [
        _buildSwitchTile(
          'Status Updates',
          'When shipping status changes',
          'shipping_status_update',
          icon: Icons.local_shipping,
        ),
        _buildSwitchTile(
          'Delivered',
          'When shipment is delivered',
          'shipping_delivered',
          icon: Icons.check_circle,
        ),
        _buildSwitchTile(
          'Tracking Assigned',
          'When tracking number is assigned',
          'shipping_tracking_assigned',
          icon: Icons.qr_code,
        ),
      ],
    );
  }

  Widget _buildInvoiceNotifications() {
    return _buildSection(
      'Invoice Notifications',
      [
        _buildSwitchTile(
          'Invoice Ready',
          'When an invoice is ready for review',
          'invoice_ready',
          icon: Icons.receipt,
        ),
        _buildSwitchTile(
          'Overdue',
          'When an invoice becomes overdue',
          'invoice_overdue',
          icon: Icons.warning,
        ),
        _buildSwitchTile(
          'Reminders',
          'Receive payment reminders',
          'invoice_reminder',
          icon: Icons.alarm,
        ),
      ],
    );
  }

  Widget _buildAffiliateNotifications() {
    return _buildSection(
      'Affiliate Notifications',
      [
        _buildSwitchTile(
          'Application Approved',
          'When affiliate application is approved',
          'affiliate_application_approved',
          icon: Icons.check_circle,
        ),
        _buildSwitchTile(
          'Application Rejected',
          'When affiliate application is rejected',
          'affiliate_application_rejected',
          icon: Icons.cancel,
        ),
        _buildSwitchTile(
          'Commission Earned',
          'When commission is earned',
          'affiliate_commission_earned',
          icon: Icons.attach_money,
        ),
      ],
    );
  }

  Widget _buildAdminNotifications() {
    return _buildSection(
      'Admin Notifications',
      [
        _buildSwitchTile(
          'Admin Alerts',
          'Important system alerts for admins',
          'admin_alerts',
          icon: Icons.admin_panel_settings,
        ),
        _buildSwitchTile(
          'System Updates',
          'System maintenance and updates',
          'system_updates',
          icon: Icons.system_update,
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    String preferenceKey, {
    IconData? icon,
  }) {
    return SwitchListTile(
      secondary: icon != null ? Icon(icon) : null,
      title: Text(title),
      subtitle: Text(subtitle),
      value: _preferences[preferenceKey] ?? false,
      onChanged: (value) {
        setState(() {
          _preferences[preferenceKey] = value;
        });
      },
    );
  }
}
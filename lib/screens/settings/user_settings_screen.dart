import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shopsnports/providers/user_providers.dart';
import 'package:shopsnports/screens/settings/change_password_screen.dart';

class UserSettingsScreen extends ConsumerStatefulWidget {
  const UserSettingsScreen({super.key});

  @override
  ConsumerState<UserSettingsScreen> createState() => _UserSettingsScreenState();
}

class _UserSettingsScreenState extends ConsumerState<UserSettingsScreen> {
  late bool _notificationsEnabled;
  late bool _emailNotificationsEnabled;
  late bool _pushNotificationsEnabled;
  late bool _smsNotificationsEnabled;
  String _language = 'English';
  String _theme = 'light';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    _notificationsEnabled = true;
    _emailNotificationsEnabled = true;
    _pushNotificationsEnabled = true;
    _smsNotificationsEnabled = true;
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      final firestore = FirebaseFirestore.instance;
      await firestore.collection('userSettings').doc(user.id).set({
        'userId': user.id,
        'notificationsEnabled': _notificationsEnabled,
        'emailNotificationsEnabled': _emailNotificationsEnabled,
        'pushNotificationsEnabled': _pushNotificationsEnabled,
        'smsNotificationsEnabled': _smsNotificationsEnabled,
        'language': _language,
        'theme': _theme,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving settings: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Notifications settings section
            _buildSectionHeader('Notifications'),
            _buildNotificationToggle(
              title: 'All Notifications',
              subtitle: 'Enable/disable all notifications',
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
              },
            ),
            if (_notificationsEnabled) ...[
              _buildNotificationToggle(
                title: 'Email Notifications',
                subtitle: 'Receive updates via email',
                value: _emailNotificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _emailNotificationsEnabled = value;
                  });
                },
              ),
              _buildNotificationToggle(
                title: 'Push Notifications',
                subtitle: 'Receive app notifications',
                value: _pushNotificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _pushNotificationsEnabled = value;
                  });
                },
              ),
              _buildNotificationToggle(
                title: 'SMS Notifications',
                subtitle: 'Receive text message alerts',
                value: _smsNotificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _smsNotificationsEnabled = value;
                  });
                },
              ),
            ],

            const Divider(height: 32),

            // App settings section
            _buildSectionHeader('App Settings'),
            _buildSettingTile(
              icon: Icons.language,
              title: 'Language',
              value: _language,
              onTap: () => _showLanguageDialog(),
            ),
            _buildSettingTile(
              icon: Icons.palette,
              title: 'Theme',
              value: _theme.toUpperCase(),
              onTap: () => _showThemeDialog(),
            ),

            const Divider(height: 32),

            // Account settings section
            _buildSectionHeader('Account'),
            _buildSettingTile(
              icon: Icons.security,
              title: 'Change Password',
              value: '',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ChangePasswordScreen(),
                  ),
                );
              },
            ),
            _buildSettingTile(
              icon: Icons.verified_user,
              title: 'Two-Factor Authentication',
              value: 'Not enabled',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('2FA feature coming soon'),
                  ),
                );
              },
            ),

            const Divider(height: 32),

            // Support section
            _buildSectionHeader('Support & Legal'),
            _buildSettingTile(
              icon: Icons.help,
              title: 'Help Center',
              value: '',
              onTap: () {
                Navigator.pop(context);
              },
            ),
            _buildSettingTile(
              icon: Icons.description,
              title: 'Terms of Service',
              value: '',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Opening terms of service'),
                  ),
                );
              },
            ),
            _buildSettingTile(
              icon: Icons.privacy_tip,
              title: 'Privacy Policy',
              value: '',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Opening privacy policy'),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            // Save button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveSettings,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue[700],
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          'Save Settings',
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // App version
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'App Version 1.0.0',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
        ),
      ),
    );
  }

  Widget _buildNotificationToggle({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey[200]!),
          ),
        ),
        child: SwitchListTile(
          title: Text(title),
          subtitle: Text(subtitle),
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.blue[700],
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey[200]!),
          ),
        ),
        child: ListTile(
          leading: Icon(icon, color: Colors.blue[700]),
          title: Text(title),
          trailing: value.isNotEmpty
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                  ],
                )
              : Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['English', 'Spanish', 'French', 'German'].map((lang) {
            return RadioListTile(
              title: Text(lang),
              value: lang,
              groupValue: _language,
              onChanged: (value) {
                setState(() {
                  _language = value!;
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['light', 'dark', 'system'].map((theme) {
            return RadioListTile(
              title: Text(theme.toUpperCase()),
              value: theme,
              groupValue: _theme,
              onChanged: (value) {
                setState(() {
                  _theme = value!;
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}

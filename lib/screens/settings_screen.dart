import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopsnports/core/routing/app_routes.dart';
import 'package:shopsnports/screens/navigation_shell.dart';
import 'package:shopsnports/widgets/main_scaffold.dart';
import 'package:shopsnports/providers/language_provider.dart';
import 'package:shopsnports/providers/currency_provider.dart';
import 'package:shopsnports/screens/settings/change_password_screen.dart';
import 'package:shopsnports/screens/settings/data_export_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  static const routeName = '/settings';
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _darkMode = false;

  void _handleNavTap(int index) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => NavigationShell(initialIndex: index),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedLanguage = ref.watch(languageProvider).code;
    final selectedCurrency = ref.watch(currencyProvider).code;

    return MainScaffold(
      currentIndex: 4,
      onNavTap: _handleNavTap,
      appBar: null,
      appBarTitle: 'Settings',
      showNewsTicker: false,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Back Button
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: InkWell(
              onTap: () => Navigator.pop(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Back to Profile',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // General Settings
          _buildSectionTitle('General'),
          Card(
            elevation: 1,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text('Language'),
                  subtitle: Text(selectedLanguage),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showLanguageDialog(),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.attach_money),
                  title: const Text('Currency'),
                  subtitle: Text(selectedCurrency),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showCurrencyDialog(),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.dark_mode),
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Use dark theme'),
                  value: _darkMode,
                  onChanged: (value) {
                    setState(() => _darkMode = value);
                    // TODO: Implement theme switching
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Notifications
          _buildSectionTitle('Notifications'),
          Card(
            elevation: 1,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.notifications),
                  title: const Text('Enable Notifications'),
                  subtitle: const Text('Receive all notifications'),
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                      if (!value) {
                        _emailNotifications = false;
                        _pushNotifications = false;
                      }
                    });
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.email),
                  title: const Text('Email Notifications'),
                  subtitle: const Text('Receive updates via email'),
                  value: _emailNotifications,
                  onChanged: _notificationsEnabled
                      ? (value) => setState(() => _emailNotifications = value)
                      : null,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.phone_android),
                  title: const Text('Push Notifications'),
                  subtitle: const Text('Receive push notifications'),
                  value: _pushNotifications,
                  onChanged: _notificationsEnabled
                      ? (value) => setState(() => _pushNotifications = value)
                      : null,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Privacy & Security
          _buildSectionTitle('Privacy & Security'),
          Card(
            elevation: 1,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.verified_user, color: Color(0xFF0A2463)),
                  title: Text('Email Verified'),
                  subtitle: Text('Your email is verified'),
                  trailing: Icon(Icons.check_circle, color: Color(0xFF0A2463)),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.lock),
                  title: const Text('Change Password'),
                  subtitle: const Text('Update your password'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ChangePasswordScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.security),
                  title: const Text('Two-Factor Authentication'),
                  subtitle: const Text('Add extra layer of security'),
                  value: false,
                  onChanged: (value) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('2FA feature coming soon. Contact support to enable.'),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip),
                  title: const Text('Privacy Policy'),
                  subtitle: const Text('View our privacy policy'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pushNamed(context, AppRoutes.privacyPolicy);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.download),
                  title: const Text('Export My Data'),
                  subtitle: const Text('Download your account data'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DataExportScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // About
          _buildSectionTitle('About'),
          Card(
            elevation: 1,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.info),
                  title: Text('App Version'),
                  subtitle: Text('1.0.0'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description),
                  title: const Text('Terms of Service'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pushNamed(context, AppRoutes.termsOfService);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.bug_report),
                  title: const Text('Report a Bug'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _showBugReportDialog();
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
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
          children: [
            _languageOption('English', 'EN'),
            _languageOption('Spanish', 'ES'),
            _languageOption('French', 'FR'),
            _languageOption('German', 'DE'),
          ],
        ),
      ),
    );
  }

  Widget _languageOption(String name, String code) {
    return ListTile(
      title: Text(name),
      onTap: () async {
        await ref.read(languageProvider.notifier).setLanguage(code);
        if (mounted) Navigator.pop(context);
      },
    );
  }

  void _showCurrencyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Currency'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _currencyOption('US Dollar', 'USD'),
            _currencyOption('Euro', 'EUR'),
            _currencyOption('British Pound', 'GBP'),
            _currencyOption('Nigerian Naira', 'NGN'),
          ],
        ),
      ),
    );
  }

  Widget _currencyOption(String name, String code) {
    return ListTile(
      title: Text(name),
      subtitle: Text(code),
      onTap: () async {
        try {
          await ref.read(currencyProvider.notifier).setCurrency(code);
        } catch (_) {
          ref.read(currencyProvider.notifier).setCodeOnly(code);
        }
        if (mounted) Navigator.pop(context);
      },
    );
  }

  void _showBugReportDialog() {
    final subjectController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report a Bug'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: subjectController,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  hintText: 'Brief description of the bug',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Detailed steps to reproduce the bug',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (subjectController.text.isEmpty || descriptionController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill in all fields'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              // Copy bug report to clipboard and notify user
              final report = '''
Bug Report - ShipSnports
========================
Subject: ${subjectController.text}
Description: ${descriptionController.text}
Date: ${DateTime.now().toIso8601String()}
App Version: 1.0.0
''';
              Clipboard.setData(ClipboardData(text: report));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Bug report copied to clipboard. Please paste and send to support.'),
                  duration: Duration(seconds: 4),
                ),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}

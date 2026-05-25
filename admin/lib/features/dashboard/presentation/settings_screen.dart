// lib/features/dashboard/presentation/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../settings/presentation/providers/settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use real settings from provider
    final businessSettingsAsync = ref.watch(businessSettingsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 24),

          // Business Settings
          _buildSectionTitle('Business Settings'),
          const SizedBox(height: 12),
          businessSettingsAsync.when(
            data: (settings) => _buildSettingsList(settings),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, s) => _buildErrorCard('Failed to load settings'),
          ),
          const SizedBox(height: 24),

          // Quick Settings
          _buildSectionTitle('Quick Settings'),
          const SizedBox(height: 12),
          _buildQuickSettings(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Configure your dashboard preferences',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.grey[700],
      ),
    );
  }

  Widget _buildSettingsList(dynamic settings) {
    return Card(
      child: Column(
        children: [
          _buildSettingTile(
            icon: Icons.business,
            title: 'Company Name',
            value: settings.companyName ?? 'Not set',
          ),
          const Divider(height: 1),
          _buildSettingTile(
            icon: Icons.email,
            title: 'Contact Email',
            value: settings.contactEmail ?? 'Not set',
          ),
          const Divider(height: 1),
          _buildSettingTile(
            icon: Icons.phone,
            title: 'Contact Phone',
            value: settings.contactPhone ?? 'Not set',
          ),
          const Divider(height: 1),
          _buildSettingTile(
            icon: Icons.location_on,
            title: 'Address',
            value: settings.address ?? 'Not set',
          ),
          const Divider(height: 1),
          _buildSettingTile(
            icon: Icons.language,
            title: 'Default Currency',
            value: settings.defaultCurrency ?? 'USD',
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      subtitle: Text(value),
      trailing: const Icon(Icons.chevron_right),
    );
  }

  Widget _buildQuickSettings(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.dark_mode, color: Colors.purple),
            title: const Text('Dark Mode'),
            trailing: Switch(
              value: false,
              onChanged: (value) {
                // TODO: Implement dark mode toggle
              },
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.notifications, color: Colors.orange),
            title: const Text('Push Notifications'),
            trailing: Switch(
              value: true,
              onChanged: (value) {
                // TODO: Implement notification toggle
              },
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.language, color: Colors.green),
            title: const Text('Language'),
            trailing: const Text('English'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error, color: Colors.red[400]),
            const SizedBox(width: 12),
            Text(message, style: TextStyle(color: Colors.red[400])),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:admin_dashboard/core/config/providers/config_providers.dart';
import 'package:admin_dashboard/core/config/env/environment.dart';

class ConfigurationScreen extends ConsumerWidget {
  const ConfigurationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appConfig = ref.watch(appConfigProvider);
    final environment = ref.watch(environmentProvider);
    final debugMode = ref.watch(debugModeProvider);
    final loggingEnabled = ref.watch(loggingEnabledProvider);
    final appVersion = ref.watch(appVersionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration & System Settings'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Environment & Build Info Section
            _SectionHeader(title: 'System Information', icon: Icons.info),
            const SizedBox(height: 16),
            _ConfigCardGrid(
              children: [
                _ConfigInfoCard(
                  label: 'Environment',
                  value: environment.toString().split('.').last.toUpperCase(),
                  icon: Icons.cloud,
                  valueColor: _getEnvironmentColor(environment),
                ),
                _ConfigInfoCard(
                  label: 'App Version',
                  value: appVersion,
                  icon: Icons.tag,
                ),
                _ConfigInfoCard(
                  label: 'Debug Mode',
                  value: debugMode ? 'Enabled' : 'Disabled',
                  icon: Icons.bug_report,
                  valueColor: debugMode ? Colors.orange : Colors.grey,
                ),
                _ConfigInfoCard(
                  label: 'Logging',
                  value: loggingEnabled ? 'Enabled' : 'Disabled',
                  icon: Icons.description,
                  valueColor: loggingEnabled ? Colors.blue : Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 32),
            // App Configuration Section
            _SectionHeader(
              title: 'Application Configuration',
              icon: Icons.settings,
            ),
            const SizedBox(height: 16),
            _AppConfigurationCard(appConfig: appConfig),
            const SizedBox(height: 32),
            // Firebase/Firestore Section
            _SectionHeader(
              title: 'Firestore Configuration',
              icon: Icons.storage,
            ),
            const SizedBox(height: 16),
            _FirestoreConfigCard(firestoreConfig: appConfig.firestoreConfig),
            const SizedBox(height: 32),
            // Authentication Section
            _SectionHeader(
              title: 'Authentication Configuration',
              icon: Icons.security,
            ),
            const SizedBox(height: 16),
            _AuthConfigCard(authConfig: appConfig.authConfig),
            const SizedBox(height: 32),
            // Elasticsearch Section
            _SectionHeader(
              title: 'Elasticsearch Configuration',
              icon: Icons.search,
            ),
            const SizedBox(height: 16),
            _ElasticsearchConfigCard(
              elasticsearchConfig: appConfig.elasticsearchConfig,
            ),
            const SizedBox(height: 32),
            // Feature Flags Section
            _SectionHeader(title: 'Feature Flags', icon: Icons.flag),
            const SizedBox(height: 16),
            _FeatureFlagsCard(featureFlags: appConfig.featureFlags),
          ],
        ),
      ),
    );
  }

  Color _getEnvironmentColor(Environment env) {
    switch (env) {
      case Environment.production:
        return Colors.red;
      case Environment.staging:
        return Colors.orange;
      case Environment.development:
        return Colors.green;
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 24),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _ConfigCardGrid extends StatelessWidget {
  final List<Widget> children;

  const _ConfigCardGrid({required this.children});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: children,
    );
  }
}

class _ConfigInfoCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _ConfigInfoCard({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
          border: Border(left: BorderSide(color: Colors.blue[400]!, width: 4)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 24, color: Colors.blue[400]),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppConfigurationCard extends StatelessWidget {
  final dynamic appConfig;

  const _AppConfigurationCard({required this.appConfig});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ConfigRow(label: 'App Name', value: appConfig.appName),
            const Divider(),
            _ConfigRow(label: 'Version', value: appConfig.appVersion),
            const Divider(),
            _ConfigRow(label: 'Build Number', value: appConfig.buildNumber),
            const Divider(),
            _ConfigRow(
              label: 'Debug Mode',
              value: appConfig.debugMode ? 'Enabled' : 'Disabled',
              valueColor: appConfig.debugMode ? Colors.orange : Colors.grey,
            ),
            const Divider(),
            _ConfigRow(
              label: 'Logging',
              value: appConfig.enableLogging ? 'Enabled' : 'Disabled',
              valueColor: appConfig.enableLogging ? Colors.green : Colors.grey,
            ),
            const Divider(),
            _ConfigRow(
              label: 'Log Level',
              value: _getLogLevelName(appConfig.logLevel),
            ),
          ],
        ),
      ),
    );
  }

  String _getLogLevelName(int level) {
    switch (level) {
      case 0:
        return 'Verbose';
      case 1:
        return 'Debug';
      case 2:
        return 'Info';
      case 3:
        return 'Warning';
      case 4:
        return 'Error';
      default:
        return 'Unknown';
    }
  }
}

class _FirestoreConfigCard extends StatelessWidget {
  final dynamic firestoreConfig;

  const _FirestoreConfigCard({required this.firestoreConfig});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ConfigRow(
              label: 'Offline Persistence',
              value: firestoreConfig.enableOfflinePersistence
                  ? 'Enabled'
                  : 'Disabled',
              valueColor: firestoreConfig.enableOfflinePersistence
                  ? Colors.green
                  : Colors.grey,
            ),
            const Divider(),
            _ConfigRow(
              label: 'Caching',
              value: firestoreConfig.enableCaching ? 'Enabled' : 'Disabled',
              valueColor: firestoreConfig.enableCaching
                  ? Colors.green
                  : Colors.grey,
            ),
            const Divider(),
            _ConfigRow(
              label: 'Cache Duration',
              value: '${firestoreConfig.cacheDuration.inHours} hours',
            ),
            const Divider(),
            _ConfigRow(
              label: 'Max Batch Size',
              value:
                  '${firestoreConfig.maxBatchReadSize} reads / ${firestoreConfig.maxBatchWriteSize} writes',
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthConfigCard extends StatelessWidget {
  final dynamic authConfig;

  const _AuthConfigCard({required this.authConfig});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ConfigRow(
              label: 'Two-Factor Auth',
              value: authConfig.enableTwoFactor ? 'Enabled' : 'Disabled',
              valueColor: authConfig.enableTwoFactor
                  ? Colors.orange
                  : Colors.grey,
            ),
            const Divider(),
            _ConfigRow(
              label: 'Email Verification',
              value: authConfig.requireEmailVerification
                  ? 'Required'
                  : 'Optional',
              valueColor: authConfig.requireEmailVerification
                  ? Colors.orange
                  : Colors.grey,
            ),
            const Divider(),
            _ConfigRow(
              label: 'Session Timeout',
              value: '${authConfig.sessionTimeout.inHours} hours',
            ),
            const Divider(),
            _ConfigRow(
              label: 'Password Min Length',
              value: '${authConfig.passwordMinLength} characters',
            ),
            const Divider(),
            _ConfigRow(
              label: 'Max Login Attempts',
              value: '${authConfig.maxLoginAttempts}',
            ),
          ],
        ),
      ),
    );
  }
}

class _ElasticsearchConfigCard extends StatelessWidget {
  final dynamic elasticsearchConfig;

  const _ElasticsearchConfigCard({required this.elasticsearchConfig});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ConfigRow(
              label: 'Cluster URL',
              value: elasticsearchConfig.clusterUrl,
            ),
            const Divider(),
            _ConfigRow(
              label: 'API Version',
              value: elasticsearchConfig.apiVersion,
            ),
            const Divider(),
            _ConfigRow(
              label: 'Connection Pool Size',
              value: '${elasticsearchConfig.connectionPoolSize}',
            ),
            const Divider(),
            _ConfigRow(
              label: 'Request Timeout',
              value: '${elasticsearchConfig.requestTimeout.inSeconds}s',
            ),
            const Divider(),
            _ConfigRow(
              label: 'Validate Certificate',
              value: elasticsearchConfig.validateCertificate ? 'Yes' : 'No',
              valueColor: elasticsearchConfig.validateCertificate
                  ? Colors.green
                  : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureFlagsCard extends StatelessWidget {
  final dynamic featureFlags;

  const _FeatureFlagsCard({required this.featureFlags});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FeatureFlagRow(
              label: 'Notifications',
              enabled: featureFlags.enableNotifications,
            ),
            const Divider(),
            _FeatureFlagRow(
              label: 'Bulk Actions',
              enabled: featureFlags.enableBulkActions,
            ),
            const Divider(),
            _FeatureFlagRow(
              label: 'Invoices',
              enabled: featureFlags.enableInvoices,
            ),
            const Divider(),
            _FeatureFlagRow(
              label: 'Affiliates',
              enabled: featureFlags.enableAffiliates,
            ),
            const Divider(),
            _FeatureFlagRow(
              label: 'Vendors',
              enabled: featureFlags.enableVendors,
            ),
            const Divider(),
            _FeatureFlagRow(
              label: 'Elasticsearch Search',
              enabled: featureFlags.enableElasticsearchSearch,
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfigRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _ConfigRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureFlagRow extends StatelessWidget {
  final String label;
  final bool enabled;

  const _FeatureFlagRow({required this.label, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Chip(
            label: Text(enabled ? 'Enabled' : 'Disabled'),
            backgroundColor: enabled
                ? Colors.green.shade100
                : Colors.grey.shade200,
            labelStyle: TextStyle(
              color: enabled ? Colors.green[700] : Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

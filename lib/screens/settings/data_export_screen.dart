import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class DataExportScreen extends ConsumerStatefulWidget {
  const DataExportScreen({super.key});

  @override
  ConsumerState<DataExportScreen> createState() => _DataExportScreenState();
}

class _DataExportScreenState extends ConsumerState<DataExportScreen> {
  bool _isExporting = false;
  String? _exportStatus;
  final Set<String> _selectedData = {
    'profile',
    'shipments',
    'invoices',
    'settings',
  };

  final Map<String, String> _dataOptions = {
    'profile': 'Profile Information',
    'shipments': 'Shipping History',
    'invoices': 'Invoices & Payments',
    'settings': 'App Settings',
    'affiliate': 'Affiliate Data',
    'notifications': 'Notification History',
  };

  Future<void> _exportData() async {
    if (_selectedData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one data type to export'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isExporting = true;
      _exportStatus = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showError('You must be logged in to export data');
        return;
      }

      final firestore = FirebaseFirestore.instance;
      final Map<String, dynamic> exportData = {
        'exportDate': DateTime.now().toIso8601String(),
        'userId': user.uid,
        'email': user.email,
        'data': <String, dynamic>{},
      };

      // Export profile
      if (_selectedData.contains('profile')) {
        final userDoc = await firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          exportData['data']['profile'] = userDoc.data();
        }
      }

      // Export shipments
      if (_selectedData.contains('shipments')) {
        final shipmentsSnapshot = await firestore
            .collection('shippingRequests')
            .where('userId', isEqualTo: user.uid)
            .get();
        exportData['data']['shipments'] = shipmentsSnapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();
      }

      // Export invoices
      if (_selectedData.contains('invoices')) {
        final invoicesSnapshot = await firestore
            .collection('invoices')
            .where('userId', isEqualTo: user.uid)
            .get();
        exportData['data']['invoices'] = invoicesSnapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();
      }

      // Export settings
      if (_selectedData.contains('settings')) {
        final settingsDoc = await firestore
            .collection('userSettings')
            .doc(user.uid)
            .get();
        if (settingsDoc.exists) {
          exportData['data']['settings'] = settingsDoc.data();
        }
      }

      // Export affiliate data
      if (_selectedData.contains('affiliate')) {
        final affiliateSnapshot = await firestore
            .collection('affiliates')
            .where('userId', isEqualTo: user.uid)
            .get();
        if (affiliateSnapshot.docs.isNotEmpty) {
          exportData['data']['affiliate'] = affiliateSnapshot.docs.first.data();
        }
      }

      // Export notification history
      if (_selectedData.contains('notifications')) {
        final notificationsSnapshot = await firestore
            .collection('notifications')
            .where('userId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .limit(100)
            .get();
        exportData['data']['notifications'] = notificationsSnapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();
      }

      // Convert to formatted JSON string
      final jsonString = _formatExportData(exportData);

      // For now, copy to clipboard as a simple export mechanism
      // In production, this would save to a file or send via email
      await _copyToClipboard(jsonString);

      setState(() {
        _exportStatus = 'Data exported successfully! ${_selectedData.length} categories selected.';
      });
    } on FirebaseException catch (e) {
      _showError('Failed to export data: ${e.message}');
    } catch (e) {
      _showError('An unexpected error occurred: $e');
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  String _formatExportData(Map<String, dynamic> data) {
    final buffer = StringBuffer();
    buffer.writeln('ShipSnports Data Export');
    buffer.writeln('========================');
    buffer.writeln('Export Date: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}');
    buffer.writeln('User: ${data['email']}');
    buffer.writeln('========================');
    buffer.writeln();

    final dataSection = data['data'] as Map<String, dynamic>;
    for (final entry in dataSection.entries) {
      buffer.writeln('--- ${_dataOptions[entry.key] ?? entry.key} ---');
      if (entry.value is List) {
        buffer.writeln('${(entry.value as List).length} records');
        for (final item in (entry.value as List)) {
          buffer.writeln('  - $item');
        }
      } else if (entry.value is Map) {
        (entry.value as Map).forEach((key, value) {
          buffer.writeln('  $key: $value');
        });
      } else {
        buffer.writeln(entry.value);
      }
      buffer.writeln();
    }

    buffer.writeln('========================');
    buffer.writeln('End of export');
    return buffer.toString();
  }

  Future<void> _copyToClipboard(String data) async {
    // This would ideally save to a file, but for now we copy to clipboard
    // In production, use file_picker and path_provider to save to device
    await Clipboard.setData(ClipboardData(text: data));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data copied to clipboard'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export My Data'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.download_for_offline_outlined,
              size: 80,
              color: Color(0xFF0A2463),
            ),
            const SizedBox(height: 24),
            Text(
              'Download Your Data',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Select the data you want to export and download it as a text file',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Data selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Data to Export',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    ..._dataOptions.entries.map((entry) {
                      return CheckboxListTile(
                        title: Text(entry.value),
                        value: _selectedData.contains(entry.key),
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              _selectedData.add(entry.key);
                            } else {
                              _selectedData.remove(entry.key);
                            }
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Info card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your data will be exported as a text file that you can save or share.',
                        style: TextStyle(color: Colors.blue.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Export status
            if (_exportStatus != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _exportStatus!,
                        style: TextStyle(color: Colors.green.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // Export button
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isExporting ? null : _exportData,
                icon: _isExporting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.download),
                label: Text(_isExporting ? 'Exporting...' : 'Export Data'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A2463),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

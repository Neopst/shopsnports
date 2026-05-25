import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class IPWhitelistManagementScreen extends StatefulWidget {
  const IPWhitelistManagementScreen({super.key});

  @override
  State<IPWhitelistManagementScreen> createState() => _IPWhitelistManagementScreenState();
}

class _IPWhitelistManagementScreenState extends State<IPWhitelistManagementScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _whitelistEntries = [];
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadWhitelist();
  }

  @override
  void dispose() {
    _ipController.dispose();
    _descriptionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadWhitelist() async {
    setState(() => _isLoading = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('ip_whitelist')
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        _whitelistEntries = snapshot.docs.map((doc) {
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
          SnackBar(content: Text('Error loading whitelist: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IP Whitelist Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWhitelist,
            tooltip: 'Refresh',
          ),
          PopupMenuButton<String>(
            onSelected: _handleImportExport,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.upload_file),
                    SizedBox(width: 8),
                    Text('Import CSV'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download),
                    SizedBox(width: 8),
                    Text('Export CSV'),
                  ],
                ),
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
                : _whitelistEntries.isEmpty
                    ? _buildEmptyState()
                    : _buildWhitelistList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddIPDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add IP'),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final totalEntries = _whitelistEntries.length;
    final activeEntries = _whitelistEntries.where((entry) => entry['isActive'] == true).length;
    final expiredEntries = _whitelistEntries.where((entry) {
      final expiresAt = entry['expiresAt'] as Timestamp?;
      if (expiresAt == null) return false;
      return expiresAt.toDate().isBefore(DateTime.now());
    }).length;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              title: 'Total Entries',
              value: totalEntries.toString(),
              icon: Icons.list,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SummaryCard(
              title: 'Active',
              value: activeEntries.toString(),
              icon: Icons.check_circle,
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SummaryCard(
              title: 'Expired',
              value: expiredEntries.toString(),
              icon: Icons.warning,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.security, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No IP whitelist entries',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Add IP addresses to whitelist for super admin operations',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildWhitelistList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _whitelistEntries.length,
      itemBuilder: (context, index) {
        final entry = _whitelistEntries[index];
        return _IPWhitelistCard(
          entry: entry,
          onToggle: () => _toggleEntry(entry),
          onDelete: () => _deleteEntry(entry),
          onEdit: () => _editEntry(entry),
        );
      },
    );
  }

  void _showAddIPDialog() {
    _ipController.clear();
    _descriptionController.clear();

    showDialog(
      context: context,
      builder: (context) => _AddIPDialog(
        ipController: _ipController,
        descriptionController: _descriptionController,
        onAdd: _addIP,
      ),
    );
  }

  Future<void> _addIP() async {
    final ip = _ipController.text.trim();
    final description = _descriptionController.text.trim();

    if (ip.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an IP address')),
      );
      return;
    }

    if (!_isValidIP(ip)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid IP address')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('ip_whitelist').add({
        'ipAddress': ip,
        'description': description,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': FirebaseAuth.instance.currentUser?.uid,
        'expiresAt': null,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('IP address added to whitelist')),
        );
      }

      await _loadWhitelist();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding IP: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _editEntry(Map<String, dynamic> entry) {
    _ipController.text = entry['ipAddress'] ?? '';
    _descriptionController.text = entry['description'] ?? '';

    showDialog(
      context: context,
      builder: (context) => _AddIPDialog(
        ipController: _ipController,
        descriptionController: _descriptionController,
        onAdd: () => _updateIP(entry),
        isEdit: true,
      ),
    );
  }

  Future<void> _updateIP(Map<String, dynamic> entry) async {
    final ip = _ipController.text.trim();
    final description = _descriptionController.text.trim();

    if (ip.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an IP address')),
      );
      return;
    }

    if (!_isValidIP(ip)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid IP address')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('ip_whitelist')
          .doc(entry['id'])
          .update({
        'ipAddress': ip,
        'description': description,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('IP address updated')),
        );
      }

      await _loadWhitelist();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating IP: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleEntry(Map<String, dynamic> entry) async {
    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('ip_whitelist')
          .doc(entry['id'])
          .update({
        'isActive': !(entry['isActive'] ?? false),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _loadWhitelist();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error toggling IP: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteEntry(Map<String, dynamic> entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete IP Address'),
        content: Text('Are you sure you want to delete ${entry['ipAddress']} from the whitelist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('ip_whitelist')
          .doc(entry['id'])
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('IP address removed from whitelist')),
        );
      }

      await _loadWhitelist();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting IP: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleImportExport(String action) async {
    if (action == 'export') {
      await _exportWhitelist();
    } else {
      await _importWhitelist();
    }
  }

  Future<void> _exportWhitelist() async {
    if (_whitelistEntries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data to export')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final headers = ['IP Address', 'Description', 'Active', 'Created At', 'Expires At'];
      final rows = _whitelistEntries.map((entry) {
        final createdAt = entry['createdAt'] as Timestamp?;
        final expiresAt = entry['expiresAt'] as Timestamp?;
        return [
          entry['ipAddress'] ?? '',
          entry['description'] ?? '',
          entry['isActive'] == true ? 'Yes' : 'No',
          createdAt != null ? DateFormat('yyyy-MM-dd HH:mm:ss').format(createdAt.toDate()) : '',
          expiresAt != null ? DateFormat('yyyy-MM-dd HH:mm:ss').format(expiresAt.toDate()) : '',
        ];
      }).toList();

      final csv = const ListToCsvConverter().convert([headers, ...rows]);

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/ip_whitelist_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv');
      await file.writeAsString(csv);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/csv')],
        subject: 'IP Whitelist Export',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Whitelist exported successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _importWhitelist() async {
    // Note: This would require file picker implementation
    // For now, show a message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Import feature requires file picker implementation')),
    );
  }

  bool _isValidIP(String ip) {
    final ipv4Pattern = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
    final ipv6Pattern = RegExp(r'^([0-9a-fA-F]{0,4}:){7}[0-9a-fA-F]{0,4}$');

    if (ipv4Pattern.hasMatch(ip)) {
      final parts = ip.split('.');
      return parts.every((part) {
        final num = int.tryParse(part);
        return num != null && num >= 0 && num <= 255;
      });
    }

    return ipv6Pattern.hasMatch(ip);
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

class _IPWhitelistCard extends StatelessWidget {
  final Map<String, dynamic> entry;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _IPWhitelistCard({
    required this.entry,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final ipAddress = entry['ipAddress'] as String? ?? 'Unknown';
    final description = entry['description'] as String? ?? '';
    final isActive = entry['isActive'] == true;
    final createdAt = entry['createdAt'] as Timestamp?;
    final expiresAt = entry['expiresAt'] as Timestamp?;

    final isExpired = expiresAt != null && expiresAt.toDate().isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isActive && !isExpired
              ? Colors.green.withOpacity(0.2)
              : Colors.grey.withOpacity(0.2),
          child: Icon(
            isActive && !isExpired ? Icons.check_circle : Icons.block,
            color: isActive && !isExpired ? Colors.green : Colors.grey,
          ),
        ),
        title: Text(
          ipAddress,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (description.isNotEmpty) Text(description),
            if (createdAt != null)
              Text(
                'Added: ${DateFormat('MM/dd/yyyy').format(createdAt.toDate())}',
                style: const TextStyle(fontSize: 12),
              ),
            if (expiresAt != null)
              Text(
                'Expires: ${DateFormat('MM/dd/yyyy').format(expiresAt.toDate())}',
                style: TextStyle(
                  fontSize: 12,
                  color: isExpired ? Colors.red : Colors.grey,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: isActive,
              onChanged: (_) => onToggle(),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: onEdit,
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: onDelete,
              tooltip: 'Delete',
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddIPDialog extends StatefulWidget {
  final TextEditingController ipController;
  final TextEditingController descriptionController;
  final VoidCallback onAdd;
  final bool isEdit;

  const _AddIPDialog({
    required this.ipController,
    required this.descriptionController,
    required this.onAdd,
    this.isEdit = false,
  });

  @override
  State<_AddIPDialog> createState() => _AddIPDialogState();
}

class _AddIPDialogState extends State<_AddIPDialog> {
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    widget.ipController.addListener(_validate);
  }

  @override
  void dispose() {
    widget.ipController.removeListener(_validate);
    super.dispose();
  }

  void _validate() {
    final ip = widget.ipController.text.trim();
    setState(() {
      _isValid = _isValidIP(ip);
    });
  }

  bool _isValidIP(String ip) {
    final ipv4Pattern = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
    final ipv6Pattern = RegExp(r'^([0-9a-fA-F]{0,4}:){7}[0-9a-fA-F]{0,4}$');

    if (ipv4Pattern.hasMatch(ip)) {
      final parts = ip.split('.');
      return parts.every((part) {
        final num = int.tryParse(part);
        return num != null && num >= 0 && num <= 255;
      });
    }

    return ipv6Pattern.hasMatch(ip);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEdit ? 'Edit IP Address' : 'Add IP Address'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('IP Address:'),
          const SizedBox(height: 8),
          TextField(
            controller: widget.ipController,
            decoration: InputDecoration(
              hintText: 'e.g., 192.168.1.1',
              suffixIcon: _isValid
                  ? const Icon(Icons.check, color: Colors.green)
                  : const Icon(Icons.error, color: Colors.red),
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          const Text('Description (optional):'),
          const SizedBox(height: 8),
          TextField(
            controller: widget.descriptionController,
            decoration: const InputDecoration(
              hintText: 'e.g., Office Network',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Supports IPv4 and IPv6 addresses',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isValid ? widget.onAdd : null,
          child: Text(widget.isEdit ? 'Update' : 'Add'),
        ),
      ],
    );
  }
}
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:intl/intl.dart';
import 'package:file_saver/file_saver.dart';
import 'admin_payout_scheduling_screen.dart';
import 'admin_audit_trail_screen.dart';

class AdminPayoutsScreen extends ConsumerStatefulWidget {
  const AdminPayoutsScreen({super.key});

  @override
  ConsumerState<AdminPayoutsScreen> createState() => _AdminPayoutsScreenState();
}

class _AdminPayoutsScreenState extends ConsumerState<AdminPayoutsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  String? _selectedStatusFilter;
  String? _selectedAffiliateFilter;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;
  bool _isExporting = false;
  Set<String> _selectedPayoutIds = {};
  bool _selectAll = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payout Management'),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (_selectedPayoutIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.check_circle),
              tooltip: 'Process Selected',
              onPressed: _bulkProcessSelected,
            ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export CSV',
            onPressed: _isExporting ? null : _exportPayouts,
          ),
          IconButton(
            icon: const Icon(Icons.compare_arrows),
            tooltip: 'Reconciliation',
            onPressed: _showReconciliationView,
          ),
          IconButton(
            icon: const Icon(Icons.schedule),
            tooltip: 'Payout Schedules',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminPayoutSchedulingScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Audit Trail',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminAuditTrailScreen(),
                ),
              );
            },
          ),
          PopupMenuButton(
            icon: const Icon(Icons.filter_list),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'date_range',
                child: Text('Date Range'),
              ),
              const PopupMenuItem(
                value: 'affiliate',
                child: Text('Filter by Affiliate'),
              ),
              const PopupMenuItem(
                value: 'clear_filters',
                child: Text('Clear Filters'),
              ),
            ],
            onSelected: _handleFilterAction,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          _buildStatsBar(),
          Expanded(
            child: _buildPayoutsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            FilterChip(
              label: const Text('All'),
              selected: _selectedStatusFilter == null,
              onSelected: (selected) {
                setState(() => _selectedStatusFilter = selected ? null : null);
              },
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('Pending'),
              selected: _selectedStatusFilter == 'pending',
              onSelected: (selected) {
                setState(() => _selectedStatusFilter = selected ? 'pending' : null);
              },
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('Processing'),
              selected: _selectedStatusFilter == 'processing',
              onSelected: (selected) {
                setState(() => _selectedStatusFilter = selected ? 'processing' : null);
              },
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('Completed'),
              selected: _selectedStatusFilter == 'completed',
              onSelected: (selected) {
                setState(() => _selectedStatusFilter = selected ? 'completed' : null);
              },
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('Failed'),
              selected: _selectedStatusFilter == 'failed',
              onSelected: (selected) {
                setState(() => _selectedStatusFilter = selected ? 'failed' : null);
              },
            ),
            if (_startDate != null || _endDate != null) ...[
              const SizedBox(width: 8),
              Chip(
                label: Text(
                  '${_startDate != null ? DateFormat('MM/dd').format(_startDate!) : ''}'
                  ' - '
                  '${_endDate != null ? DateFormat('MM/dd').format(_endDate!) : ''}',
                ),
                onDeleted: () {
                  setState(() {
                    _startDate = null;
                    _endDate = null;
                  });
                },
              ),
            ],
            if (_selectedAffiliateFilter != null) ...[
              const SizedBox(width: 8),
              Chip(
                label: Text('Affiliate: $_selectedAffiliateFilter'),
                onDeleted: () {
                  setState(() => _selectedAffiliateFilter = null);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatsBar() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('payouts').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final payouts = snapshot.data!.docs;
        int pendingCount = 0;
        int processingCount = 0;
        int completedCount = 0;
        double pendingAmount = 0;
        double processingAmount = 0;
        double completedAmount = 0;

        for (final doc in payouts) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'] as String? ?? '';
          final amount = (data['amount'] as num?)?.toDouble() ?? 0;

          switch (status) {
            case 'pending':
              pendingCount++;
              pendingAmount += amount;
              break;
            case 'processing':
              processingCount++;
              processingAmount += amount;
              break;
            case 'completed':
              completedCount++;
              completedAmount += amount;
              break;
          }
        }

        return Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue[50],
          child: Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Pending',
                  pendingCount,
                  pendingAmount,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  'Processing',
                  processingCount,
                  processingAmount,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  'Completed',
                  completedCount,
                  completedAmount,
                  Colors.green,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, int count, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: color,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayoutsList() {
    Query query = _firestore
        .collection('payouts')
        .orderBy('requestedAt', descending: true);

    if (_selectedStatusFilter != null) {
      query = query.where('status', isEqualTo: _selectedStatusFilter);
    }

    if (_selectedAffiliateFilter != null) {
      query = query.where('affiliateId', isEqualTo: _selectedAffiliateFilter);
    }

    if (_startDate != null) {
      query = query.where('requestedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate!));
    }

    if (_endDate != null) {
      final endOfDay = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
      query = query.where('requestedAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.limit(100).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final payouts = snapshot.data?.docs ?? [];

        if (payouts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.payment_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text('No payouts found'),
              ],
            ),
          );
        }

        return Column(
          children: [
            if (payouts.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Checkbox(
                      value: _selectAll,
                      onChanged: (value) {
                        setState(() {
                          _selectAll = value ?? false;
                          if (_selectAll) {
                            _selectedPayoutIds = payouts.map((doc) => doc.id).toSet();
                          } else {
                            _selectedPayoutIds.clear();
                          }
                        });
                      },
                    ),
                    const Text('Select All'),
                    const Spacer(),
                    Text('${_selectedPayoutIds.length} selected'),
                  ],
                ),
              ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: payouts.length,
                itemBuilder: (context, index) {
                  final doc = payouts[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final isSelected = _selectedPayoutIds.contains(doc.id);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: CheckboxListTile(
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedPayoutIds.add(doc.id);
                          } else {
                            _selectedPayoutIds.remove(doc.id);
                          }
                          _selectAll = _selectedPayoutIds.length == payouts.length;
                        });
                      },
                      title: Row(
                        children: [
                          Text(
                            data['payoutNumber'] ?? doc.id.substring(0, 10),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          _buildStatusChip(data['status'] as String? ?? 'pending'),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            'Affiliate: ${data['affiliateName'] ?? 'Unknown'}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Amount: \$${(data['amount'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Requested: ${_formatDate(data['requestedAt'])}',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                          if (data['completedAt'] != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Completed: ${_formatDate(data['completedAt'])}',
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                      secondary: IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () => _showPayoutOptions(doc),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'pending':
        color = Colors.orange;
        break;
      case 'processing':
        color = Colors.blue;
        break;
      case 'completed':
        color = Colors.green;
        break;
      case 'failed':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      final date = (timestamp as Timestamp).toDate();
      return DateFormat('MMM dd, yyyy HH:mm').format(date);
    } catch (_) {
      return 'Invalid date';
    }
  }

  void _handleFilterAction(String action) {
    switch (action) {
      case 'date_range':
        _showDateRangePicker();
        break;
      case 'affiliate':
        _showAffiliateFilter();
        break;
      case 'clear_filters':
        setState(() {
          _selectedStatusFilter = null;
          _selectedAffiliateFilter = null;
          _startDate = null;
          _endDate = null;
        });
        break;
    }
  }

  Future<void> _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _showAffiliateFilter() async {
    final affiliates = await _firestore
        .collection('affiliates')
        .where('status', isEqualTo: 'approved')
        .get();

    if (!mounted) return;

    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Affiliate'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: affiliates.docs.length,
            itemBuilder: (context, index) {
              final doc = affiliates.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['fullName'] ?? data['name'] ?? 'Unknown'),
                subtitle: Text(data['email'] ?? ''),
                onTap: () => Navigator.of(context).pop(doc.id),
              );
            },
          ),
        ),
      ),
    );

    if (selected != null) {
      setState(() => _selectedAffiliateFilter = selected);
    }
  }

  Future<void> _bulkProcessSelected() async {
    if (_selectedPayoutIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Process Payouts'),
        content: Text(
          'Are you sure you want to process ${_selectedPayoutIds.length} payout(s)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Process'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final result = await _functions.httpsCallable('bulkProcessPayments').call({
        'payoutIds': _selectedPayoutIds.toList(),
        'transactionReference': 'bulk-${DateTime.now().millisecondsSinceEpoch}',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Processed ${result.data['totalProcessed']} payouts successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _selectedPayoutIds.clear();
          _selectAll = false;
        });
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

  Future<void> _exportPayouts() async {
    setState(() => _isExporting = true);

    try {
      final result = await _functions.httpsCallable('exportPayments').call({
        'startDate': _startDate?.toIso8601String(),
        'endDate': _endDate?.toIso8601String(),
        'status': _selectedStatusFilter,
        'affiliateId': _selectedAffiliateFilter,
        'format': 'csv',
      });

      if (mounted) {
        final filename = result.data['filename'] as String? ?? 'payouts_export.csv';
        final content = result.data['content'] as String? ?? '';

        await FileSaver.instance.saveFile(
          name: filename,
          bytes: Utf8Encoder().convert(content),
          ext: 'csv',
          mimeType: MimeType.csv,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported ${result.data['recordCount']} records'),
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
      setState(() => _isExporting = false);
    }
  }

  void _showPayoutOptions(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final status = data['status'] as String? ?? 'pending';

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                _showPayoutDetails(doc);
              },
            ),
            if (status == 'pending' || status == 'processing')
              ListTile(
                leading: const Icon(Icons.check_circle),
                title: const Text('Process Payout'),
                onTap: () {
                  Navigator.pop(context);
                  _processSinglePayout(doc.id);
                },
              ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy Payout Number'),
              onTap: () {
                Navigator.pop(context);
                Clipboard.setData(
                  ClipboardData(text: data['payoutNumber'] ?? doc.id),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('View Commissions'),
              onTap: () {
                Navigator.pop(context);
                _showPayoutCommissions(doc);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPayoutDetails(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(data['payoutNumber'] ?? 'Payout Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Status', data['status']?.toString().toUpperCase() ?? 'N/A'),
              _buildDetailRow('Amount', '\$${(data['amount'] as num?)?.toStringAsFixed(2) ?? '0.00'}'),
              _buildDetailRow('Gross Amount', '\$${(data['grossAmount'] as num?)?.toStringAsFixed(2) ?? '0.00'}'),
              _buildDetailRow('Commission', '\$${(data['commissionAmount'] as num?)?.toStringAsFixed(2) ?? '0.00'}'),
              _buildDetailRow('Tax', '\$${(data['taxAmount'] as num?)?.toStringAsFixed(2) ?? '0.00'}'),
              _buildDetailRow('Net Amount', '\$${(data['netAmount'] as num?)?.toStringAsFixed(2) ?? '0.00'}'),
              _buildDetailRow('Affiliate', data['affiliateName'] ?? 'N/A'),
              _buildDetailRow('Affiliate Email', data['affiliateEmail'] ?? 'N/A'),
              _buildDetailRow('Payment Method', data['paymentMethod'] ?? 'N/A'),
              _buildDetailRow('Requested', _formatDate(data['requestedAt'])),
              if (data['completedAt'] != null)
                _buildDetailRow('Completed', _formatDate(data['completedAt'])),
              if (data['transactionReference'] != null)
                _buildDetailRow('Transaction ID', data['transactionReference']),
              if (data['notes'] != null && data['notes'].toString().isNotEmpty)
                _buildDetailRow('Notes', data['notes']),
              _buildDetailRow('Commissions', '${(data['commissionIds'] as List?)?.length ?? 0} items'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
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

  Future<void> _processSinglePayout(String payoutId) async {
    setState(() => _isLoading = true);

    try {
      await _functions.httpsCallable('processPayment').call({
        'payoutId': payoutId,
        'transactionReference': 'manual-${DateTime.now().millisecondsSinceEpoch}',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payout processed successfully'),
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

  Future<void> _showPayoutCommissions(QueryDocumentSnapshot payoutDoc) async {
    final payoutData = payoutDoc.data() as Map<String, dynamic>;
    final commissionIds = payoutData['commissionIds'] as List<dynamic>? ?? [];

    if (commissionIds.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No commissions associated with this payout')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final commissions = await Future.wait(
        commissionIds.map((id) => _firestore.collection('commissions').doc(id as String).get()),
      );

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Commissions for ${payoutData['payoutNumber'] ?? 'Payout'}'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              itemCount: commissions.length,
              itemBuilder: (context, index) {
                final doc = commissions[index];
                if (!doc.exists) {
                  return ListTile(
                    title: Text('Commission ${commissionIds[index]}'),
                    subtitle: const Text('Not found'),
                    tileColor: Colors.red[50],
                  );
                }

                final data = doc.data() as Map<String, dynamic>;
                final status = data['status'] as String? ?? 'unknown';

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getCommissionStatusColor(status),
                      child: Icon(
                        _getCommissionStatusIcon(status),
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Text('Commission #${doc.id.substring(0, 10)}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Amount: \$${(data['commissionAmount'] as num?)?.toStringAsFixed(2) ?? '0.00'}'),
                        Text('Status: ${status.toUpperCase()}'),
                        if (data['shipmentId'] != null)
                          Text('Shipment: ${data['shipmentId']}'),
                      ],
                    ),
                    trailing: Text(
                      _formatDate(data['createdAt']),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Color _getCommissionStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.blue;
      case 'paid':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getCommissionStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending;
      case 'approved':
        return Icons.check_circle;
      case 'paid':
        return Icons.payments;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  Future<void> _showReconciliationView() async {
    setState(() => _isLoading = true);

    try {
      final payouts = await _firestore
          .collection('payouts')
          .orderBy('requestedAt', descending: true)
          .limit(50)
          .get();

      final commissions = await _firestore
          .collection('commissions')
          .where('status', whereIn: ['approved', 'paid'])
          .get();

      final payoutCommissionIds = <String>{};
      for (final payout in payouts.docs) {
        final data = payout.data() as Map<String, dynamic>;
        final ids = data['commissionIds'] as List<dynamic>? ?? [];
        payoutCommissionIds.addAll(ids.map((e) => e as String));
      }

      final orphanedCommissions = commissions.docs.where((doc) {
        return !payoutCommissionIds.contains(doc.id);
      }).toList();

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Payout Reconciliation'),
          content: SizedBox(
            width: double.maxFinite,
            height: 500,
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'Payouts Summary'),
                      Tab(text: 'Orphaned Commissions'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildPayoutsSummary(payouts.docs),
                        _buildOrphanedCommissions(orphanedCommissions),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildPayoutsSummary(List<QueryDocumentSnapshot> payouts) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: payouts.length,
      itemBuilder: (context, index) {
        final doc = payouts[index];
        final data = doc.data() as Map<String, dynamic>;
        final commissionIds = data['commissionIds'] as List<dynamic>? ?? [];
        final status = data['status'] as String? ?? 'pending';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ExpansionTile(
            leading: _buildStatusChip(status),
            title: Text(data['payoutNumber'] ?? doc.id.substring(0, 10)),
            subtitle: Text(
              '\$${(data['amount'] as num?)?.toStringAsFixed(2) ?? '0.00'} • ${commissionIds.length} commissions',
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Affiliate', data['affiliateName'] ?? 'N/A'),
                    _buildDetailRow('Status', status.toUpperCase()),
                    _buildDetailRow('Gross Amount', '\$${(data['grossAmount'] as num?)?.toStringAsFixed(2) ?? '0.00'}'),
                    _buildDetailRow('Commission Amount', '\$${(data['commissionAmount'] as num?)?.toStringAsFixed(2) ?? '0.00'}'),
                    _buildDetailRow('Tax Amount', '\$${(data['taxAmount'] as num?)?.toStringAsFixed(2) ?? '0.00'}'),
                    _buildDetailRow('Net Amount', '\$${(data['netAmount'] as num?)?.toStringAsFixed(2) ?? '0.00'}'),
                    _buildDetailRow('Requested', _formatDate(data['requestedAt'])),
                    if (data['completedAt'] != null)
                      _buildDetailRow('Completed', _formatDate(data['completedAt'])),
                    const SizedBox(height: 8),
                    const Text(
                      'Associated Commissions:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    ...commissionIds.map((id) => Padding(
                      padding: const EdgeInsets.only(left: 8, top: 2),
                      child: Text(
                        '• ${id as String}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    )),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrphanedCommissions(List<QueryDocumentSnapshot> commissions) {
    if (commissions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text('No orphaned commissions found'),
            Text('All approved/paid commissions are linked to payouts'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: commissions.length,
      itemBuilder: (context, index) {
        final doc = commissions[index];
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status'] as String? ?? 'unknown';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: Colors.orange[50],
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getCommissionStatusColor(status),
              child: Icon(
                _getCommissionStatusIcon(status),
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text('Commission #${doc.id.substring(0, 10)}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Amount: \$${(data['commissionAmount'] as num?)?.toStringAsFixed(2) ?? '0.00'}'),
                Text('Status: ${status.toUpperCase()}'),
                if (data['affiliateId'] != null)
                  Text('Affiliate: ${data['affiliateId']}'),
                if (data['shipmentId'] != null)
                  Text('Shipment: ${data['shipmentId']}'),
              ],
            ),
            trailing: Text(
              _formatDate(data['createdAt']),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ),
        );
      },
    );
  }
}
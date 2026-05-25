import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminInvoicesScreen extends ConsumerStatefulWidget {
  const AdminInvoicesScreen({super.key});

  @override
  ConsumerState<AdminInvoicesScreen> createState() =>
      _AdminInvoicesScreenState();
}

class _AdminInvoicesScreenState extends ConsumerState<AdminInvoicesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  String? _selectedStatusFilter;
  String? _selectedTypeFilter;
  String? _selectedRecipientFilter;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Management'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => setState(() {}),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filters',
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatsBar(),
          _buildFilterChips(),
          Expanded(
            child: _buildInvoicesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('invoices').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final invoices = snapshot.data!.docs;
        int total = invoices.length;
        int draft = 0;
        int sent = 0;
        int paid = 0;
        int overdue = 0;
        double totalAmount = 0;
        double paidAmount = 0;

        for (final doc in invoices) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'] as String? ?? 'draft';
          final amount = (data['amount'] as num?)?.toDouble() ?? 0;

          totalAmount += amount;

          switch (status) {
            case 'draft':
              draft++;
              break;
            case 'sent':
              sent++;
              break;
            case 'paid':
              paid++;
              paidAmount += amount;
              break;
            case 'overdue':
              overdue++;
              break;
          }
        }

        return Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue[50],
          child: Row(
            children: [
              Expanded(
                child: _buildStatItem('Total', total, Colors.blue, '\$${totalAmount.toStringAsFixed(2)}'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem('Draft', draft, Colors.orange, ''),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem('Sent', sent, Colors.blue, ''),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem('Paid', paid, Colors.green, '\$${paidAmount.toStringAsFixed(2)}'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem('Overdue', overdue, Colors.red, ''),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, int count, Color color, String amount) {
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
          if (amount.isNotEmpty)
            Text(
              amount,
              style: TextStyle(
                color: color,
                fontSize: 11,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (_selectedStatusFilter != null)
              Chip(
                label: Text('Status: $_selectedStatusFilter'),
                onDeleted: () => setState(() => _selectedStatusFilter = null),
              ),
            if (_selectedTypeFilter != null) ...[
              const SizedBox(width: 8),
              Chip(
                label: Text('Type: $_selectedTypeFilter'),
                onDeleted: () => setState(() => _selectedTypeFilter = null),
              ),
            ],
            if (_selectedRecipientFilter != null) ...[
              const SizedBox(width: 8),
              Chip(
                label: Text('Recipient: $_selectedRecipientFilter'),
                onDeleted: () => setState(() => _selectedRecipientFilter = null),
              ),
            ],
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
          ],
        ),
      ),
    );
  }

  Widget _buildInvoicesList() {
    Query query = _firestore
        .collection('invoices')
        .orderBy('createdAt', descending: true);

    if (_selectedStatusFilter != null) {
      query = query.where('status', isEqualTo: _selectedStatusFilter);
    }

    if (_selectedTypeFilter != null) {
      query = query.where('invoiceType', isEqualTo: _selectedTypeFilter);
    }

    if (_selectedRecipientFilter != null) {
      if (_selectedRecipientFilter == 'affiliate') {
        query = query.where('recipientType', isEqualTo: 'affiliate');
      } else if (_selectedRecipientFilter == 'customer') {
        query = query.where('recipientType', isEqualTo: 'customer');
      } else if (_selectedRecipientFilter == 'guest') {
        query = query.where('recipientType', isEqualTo: 'guest');
      }
    }

    if (_startDate != null) {
      query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate!));
    }

    if (_endDate != null) {
      final endOfDay = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
      query = query.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay));
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

        final invoices = snapshot.data?.docs ?? [];

        if (invoices.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text('No invoices found'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: invoices.length,
          itemBuilder: (context, index) {
            final doc = invoices[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildInvoiceCard(doc, data);
          },
        );
      },
    );
  }

  Widget _buildInvoiceCard(QueryDocumentSnapshot doc, Map<String, dynamic> data) {
    final invoiceNumber = data['invoiceNumber'] as String? ?? 'N/A';
    final status = data['status'] as String? ?? 'draft';
    final invoiceType = data['invoiceType'] as String? ?? 'service_fee';
    final amount = (data['amount'] as num?)?.toDouble() ?? 0;
    final recipientName = data['billTo']?['name'] as String? ?? 'Unknown';
    final recipientEmail = data['billTo']?['email'] as String? ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(status),
          child: Icon(
            _getStatusIcon(status),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          invoiceNumber,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$recipientName • $invoiceType'),
            Text('\$${amount.toStringAsFixed(2)}'),
            Text(_formatTimestamp(data['createdAt'])),
            if (status == 'overdue')
              Text(
                'OVERDUE',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (status == 'draft')
              IconButton(
                icon: const Icon(Icons.send),
                tooltip: 'Send',
                onPressed: () => _sendInvoice(doc),
              ),
            if (status == 'sent')
              IconButton(
                icon: const Icon(Icons.check_circle),
                tooltip: 'Mark as Paid',
                onPressed: () => _markAsPaid(doc),
              ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showInvoiceOptions(doc, data),
            ),
          ],
        ),
        onTap: () => _showInvoiceDetails(doc, data),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return Colors.orange;
      case 'sent':
        return Colors.blue;
      case 'paid':
        return Colors.green;
      case 'overdue':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return Icons.edit;
      case 'sent':
        return Icons.send;
      case 'paid':
        return Icons.check_circle;
      case 'overdue':
        return Icons.warning;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.receipt;
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      final date = (timestamp as Timestamp).toDate();
      return DateFormat('MMM dd, yyyy HH:mm').format(date);
    } catch (_) {
      return 'Invalid date';
    }
  }

  Future<void> _showFilterDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Invoices'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Status'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedStatusFilter,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('All')),
                  DropdownMenuItem(value: 'draft', child: Text('Draft')),
                  DropdownMenuItem(value: 'sent', child: Text('Sent')),
                  DropdownMenuItem(value: 'paid', child: Text('Paid')),
                  DropdownMenuItem(value: 'overdue', child: Text('Overdue')),
                  DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                ],
                onChanged: (value) {
                  setState(() => _selectedStatusFilter = value);
                },
              ),
              const SizedBox(height: 16),
              const Text('Invoice Type'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedTypeFilter,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('All')),
                  DropdownMenuItem(value: 'service_fee', child: Text('Service Fee')),
                  DropdownMenuItem(value: 'affiliate_commission', child: Text('Affiliate Commission')),
                  DropdownMenuItem(value: 'vendor', child: Text('Vendor')),
                ],
                onChanged: (value) {
                  setState(() => _selectedTypeFilter = value);
                },
              ),
              const SizedBox(height: 16),
              const Text('Recipient Type'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedRecipientFilter,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('All')),
                  DropdownMenuItem(value: 'affiliate', child: Text('Affiliate')),
                  DropdownMenuItem(value: 'customer', child: Text('Customer')),
                  DropdownMenuItem(value: 'guest', child: Text('Guest')),
                ],
                onChanged: (value) {
                  setState(() => _selectedRecipientFilter = value);
                },
              ),
              const SizedBox(height: 16),
              const Text('Date Range'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _startDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() => _startDate = date);
                        }
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_startDate != null
                          ? DateFormat('MM/dd').format(_startDate!)
                          : 'Start Date'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _endDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() => _endDate = date);
                        }
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_endDate != null
                          ? DateFormat('MM/dd').format(_endDate!)
                          : 'End Date'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Apply'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {});
    }
  }

  Future<void> _showInvoiceDetails(QueryDocumentSnapshot doc, Map<String, dynamic> data) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(_getStatusIcon(data['status'] as String? ?? 'draft')),
            const SizedBox(width: 12),
            Expanded(
              child: Text(data['invoiceNumber'] as String? ?? 'Invoice Details'),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Invoice Number', data['invoiceNumber'] ?? 'N/A'),
              _buildDetailRow('Status', (data['status'] as String? ?? 'draft').toUpperCase()),
              _buildDetailRow('Type', (data['invoiceType'] as String? ?? 'service_fee').toUpperCase()),
              _buildDetailRow('Amount', '\$${(data['amount'] as num?)?.toStringAsFixed(2) ?? '0.00'}'),
              _buildDetailRow('Currency', data['currency'] ?? 'USD'),
              _buildDetailRow('Recipient Type', (data['recipientType'] as String? ?? 'customer').toUpperCase()),
              _buildDetailRow('Recipient Name', data['billTo']?['name'] ?? 'N/A'),
              _buildDetailRow('Recipient Email', data['billTo']?['email'] ?? 'N/A'),
              _buildDetailRow('Created', _formatTimestamp(data['createdAt'])),
              if (data['sentAt'] != null)
                _buildDetailRow('Sent', _formatTimestamp(data['sentAt'])),
              if (data['paidAt'] != null)
                _buildDetailRow('Paid', _formatTimestamp(data['paidAt'])),
              if (data['shippingRequestId'] != null)
                _buildDetailRow('Shipping Request ID', data['shippingRequestId']),
              if (data['affiliateId'] != null)
                _buildDetailRow('Affiliate ID', data['affiliateId']),
              if (data['customerId'] != null)
                _buildDetailRow('Customer ID', data['customerId']),
              if (data['notes'] != null && data['notes'].toString().isNotEmpty)
                _buildDetailRow('Notes', data['notes']),
              if (data['lineItems'] != null) ...[
                const SizedBox(height: 12),
                const Text(
                  'Line Items:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...(data['lineItems'] as List).map((item) => Padding(
                  padding: const EdgeInsets.only(left: 8, top: 2),
                  child: Text(
                    '${item['description']} - \$${(item['total'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                  ),
                )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (data['status'] == 'draft')
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _sendInvoice(doc);
              },
              icon: const Icon(Icons.send),
              label: const Text('Send'),
            ),
          if (data['status'] == 'sent')
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _markAsPaid(doc);
              },
              icon: const Icon(Icons.check_circle),
              label: const Text('Mark as Paid'),
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
            width: 140,
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

  void _showInvoiceOptions(QueryDocumentSnapshot doc, Map<String, dynamic> data) {
    final status = data['status'] as String? ?? 'draft';

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                _showInvoiceDetails(doc, data);
              },
            ),
            if (status == 'draft')
              ListTile(
                leading: const Icon(Icons.send),
                title: const Text('Send Invoice'),
                onTap: () {
                  Navigator.pop(context);
                  _sendInvoice(doc);
                },
              ),
            if (status == 'sent')
              ListTile(
                leading: const Icon(Icons.check_circle),
                title: const Text('Mark as Paid'),
                onTap: () {
                  Navigator.pop(context);
                  _markAsPaid(doc);
                },
              ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Download PDF'),
              onTap: () {
                Navigator.pop(context);
                _downloadInvoicePDF(doc);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Invoice'),
              onTap: () {
                Navigator.pop(context);
                _editInvoice(doc);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete Invoice'),
              onTap: () {
                Navigator.pop(context);
                _deleteInvoice(doc);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendInvoice(QueryDocumentSnapshot doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Invoice'),
        content: const Text('Are you sure you want to send this invoice to the recipient?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final data = doc.data() as Map<String, dynamic>;
      final recipientEmail = data['billTo']?['email'] as String?;

      if (recipientEmail == null || recipientEmail.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No recipient email found')),
          );
        }
        return;
      }

      // Update invoice status
      await doc.reference.update({
        'status': 'sent',
        'sentAt': FieldValue.serverTimestamp(),
        'sentBy': FirebaseAuth.instance.currentUser?.uid,
      });

      // Call Cloud Function to send email
      await _functions.httpsCallable('sendInvoiceEmail').call({
        'invoiceId': doc.id,
        'recipientEmail': recipientEmail,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invoice sent successfully'),
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

  Future<void> _markAsPaid(QueryDocumentSnapshot doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Paid'),
        content: const Text('Are you sure you want to mark this invoice as paid?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Mark Paid'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await doc.reference.update({
        'status': 'paid',
        'paidAt': FieldValue.serverTimestamp(),
        'paidBy': FirebaseAuth.instance.currentUser?.uid,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invoice marked as paid'),
            backgroundColor: Colors.green,
          ),
        );
      }
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

  Future<void> _downloadInvoicePDF(QueryDocumentSnapshot doc) async {
    setState(() => _isLoading = true);

    try {
      // Call Cloud Function to generate PDF
      final result = await _functions.httpsCallable('generateInvoicePDF').call({
        'invoiceId': doc.id,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.data['message'] as String? ?? 'PDF generated'),
            backgroundColor: Colors.green,
          ),
        );
      }
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

  Future<void> _editInvoice(QueryDocumentSnapshot doc) async {
    // TODO: Implement invoice editing
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice editing coming soon')),
      );
    }
  }

  Future<void> _deleteInvoice(QueryDocumentSnapshot doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Invoice'),
        content: const Text('Are you sure you want to delete this invoice?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await doc.reference.delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice deleted')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      }
    }
  }
}
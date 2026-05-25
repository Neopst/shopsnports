import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../widgets/main_scaffold.dart';

/// Form Shares Screen
/// Shows all shareable forms created by the affiliate with analytics
class FormSharesScreen extends StatefulWidget {
  final String affiliateId;

  const FormSharesScreen({
    super.key,
    required this.affiliateId,
  });

  @override
  State<FormSharesScreen> createState() => _FormSharesScreenState();
}

class _FormSharesScreenState extends State<FormSharesScreen> {
  final _db = FirebaseFirestore.instance;
  String _searchQuery = '';
  bool _showUsedOnly = false;

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      appBarTitle: 'Shareable Forms',
      showBackOnly: true,
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search forms...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    FilterChip(
                      label: const Text('Show used only'),
                      selected: _showUsedOnly,
                      onSelected: (value) {
                        setState(() => _showUsedOnly = value);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Stats Summary
          _buildStatsSummary(),

          // Form Shares List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getFormSharesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                final filteredDocs = _filterDocs(docs);

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.share_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _showUsedOnly
                              ? 'No used forms yet'
                              : 'No shareable forms yet',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Create shareable forms to track your referrals',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => setState(() {}),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      final data = filteredDocs[index].data() as Map<String, dynamic>;
                      return _buildFormShareCard(
                        docId: filteredDocs[index].id,
                        data: data,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getFormSharesStream() {
    Query query = _db
        .collection('form_shares')
        .where('affiliateId', isEqualTo: widget.affiliateId)
        .orderBy('createdAt', descending: true);

    return query.snapshots();
  }

  List<QueryDocumentSnapshot> _filterDocs(List<QueryDocumentSnapshot> docs) {
    var filtered = docs;

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return (data['formId']?.toString().toLowerCase().contains(query) ?? false) ||
            (data['customerName']?.toString().toLowerCase().contains(query) ?? false);
      }).toList();
    }

    if (_showUsedOnly) {
      filtered = filtered.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['used'] == true;
      }).toList();
    }

    return filtered;
  }

  Widget _buildStatsSummary() {
    return FutureBuilder<QuerySnapshot>(
      future: _db
          .collection('form_shares')
          .where('affiliateId', isEqualTo: widget.affiliateId)
          .get(),
      builder: (context, snapshot) {
        final total = snapshot.data?.docs.length ?? 0;
        final used = snapshot.data?.docs.where((d) => (d.data() as Map<String, dynamic>)['used'] == true).length ?? 0;

        final conversionRate = total > 0 ? (used / total * 100).toStringAsFixed(0) : '0';

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _buildStatItem('Total Forms', '$total', Icons.link),
              const SizedBox(width: 24),
              _buildStatItem('Used', '$used', Icons.check_circle),
              const SizedBox(width: 24),
              _buildStatItem('Conversion', '$conversionRate%', Icons.trending_up),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormShareCard({required String docId, required Map<String, dynamic> data}) {
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final usedAt = (data['usedAt'] as Timestamp?)?.toDate();
    final isUsed = data['used'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showShareDetails(docId, data),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      data['customerName'] ?? 'Unnamed Form',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isUsed
                          ? Colors.green.withValues(alpha: 0.2)
                          : Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isUsed ? 'USED' : 'UNUSED',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isUsed ? Colors.green : Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Form ID: ${data['formId'] ?? docId.substring(0, 8)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Created: ${createdAt != null ? DateFormat('MMM dd, yyyy').format(createdAt) : 'N/A'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
              if (isUsed && usedAt != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.green[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Used: ${DateFormat('MMM dd, yyyy').format(usedAt)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.green[600],
                          ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _copyShareLink(data['shareToken'] ?? docId),
                      icon: const Icon(Icons.content_copy, size: 16),
                      label: const Text('Copy Link'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _showShareDetails(docId, data),
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('Details'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _copyShareLink(String token) {
    final link = 'https://shopsnports.com/public/form/$token';
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link copied to clipboard')),
    );
  }

  void _showShareDetails(String docId, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Form Share Details',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              _buildDetailRow('Customer Name', data['customerName'] ?? 'N/A'),
              _buildDetailRow('Form ID', data['formId'] ?? docId),
              _buildDetailRow('Status', data['used'] == true ? 'Used' : 'Unused'),
              _buildDetailRow(
                'Created',
                (data['createdAt'] as Timestamp?) != null
                    ? DateFormat('MMM dd, yyyy HH:mm')
                        .format((data['createdAt'] as Timestamp).toDate())
                    : 'N/A',
              ),
              if (data['usedAt'] != null)
                _buildDetailRow(
                  'Used At',
                  DateFormat('MMM dd, yyyy HH:mm')
                      .format((data['usedAt'] as Timestamp).toDate()),
                ),
              if (data['shippingRequestId'] != null)
                _buildDetailRow('Shipment ID', data['shippingRequestId']),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _copyShareLink(data['shareToken'] ?? docId);
                },
                icon: const Icon(Icons.content_copy),
                label: const Text('Copy Share Link'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
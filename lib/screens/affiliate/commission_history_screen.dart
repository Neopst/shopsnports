import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shopsnports/services/affiliate_api_service.dart';
import '../../widgets/main_scaffold.dart';

/// Commission History Screen
/// Shows direct commission documents from the commissions collection
class CommissionHistoryScreen extends ConsumerStatefulWidget {
  const CommissionHistoryScreen({super.key});

  @override
  ConsumerState<CommissionHistoryScreen> createState() =>
      _CommissionHistoryScreenState();
}

class _CommissionHistoryScreenState
    extends ConsumerState<CommissionHistoryScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _affiliateService = AffiliateService();

  List<QueryDocumentSnapshot> _commissions = [];
  bool _isLoading = true;
  String? _error;
  String? _filterStatus;
  double _totalCommission = 0;

  @override
  void initState() {
    super.initState();
    _loadCommissions();
  }

  Future<void> _loadCommissions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = await _affiliateService.getCurrentUser();
      if (user == null) {
        setState(() {
          _error = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }

      Query<Map<String, dynamic>> query = _db
          .collection('commissions')
          .where('affiliateId', isEqualTo: user.uid)
          .orderBy('earnedAt', descending: true);

      if (_filterStatus != null) {
        query = query.where('status', isEqualTo: _filterStatus);
      }

      final snapshot = await query.get();

      double total = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final amount =
            (data['commissionAmount'] ?? data['amount'] ?? 0).toDouble();
        total += amount;
      }

      setState(() {
        _commissions = snapshot.docs;
        _totalCommission = total;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'void':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      appBarTitle: 'Commission History',
      showBackOnly: true,
      body: Column(
        children: [
          // Total Commission Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withValues(alpha: 0.7),
                ],
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'Total Commissions',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${_totalCommission.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_commissions.length} commissions',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    initialValue: _filterStatus,
                    decoration: const InputDecoration(
                      labelText: 'Filter by Status',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All')),
                      const DropdownMenuItem(
                          value: 'pending', child: Text('PENDING')),
                      const DropdownMenuItem(
                          value: 'paid', child: Text('PAID')),
                      const DropdownMenuItem(
                          value: 'void', child: Text('VOID')),
                    ],
                    onChanged: (value) {
                      setState(() => _filterStatus = value);
                      _loadCommissions();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadCommissions,
                ),
              ],
            ),
          ),

          // Commissions List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 64, color: Colors.red[300]),
                            const SizedBox(height: 16),
                            Text(_error!),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: _loadCommissions,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _commissions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.receipt_long_outlined,
                                    size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                const Text('No commission history'),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadCommissions,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _commissions.length,
                              itemBuilder: (context, index) {
                                final doc = _commissions[index];
                                final data = doc.data() as Map<String, dynamic>;
                                final amount = (data['commissionAmount'] ??
                                        data['amount'] ??
                                        0)
                                    .toDouble();
                                final status =
                                    (data['status'] ?? 'pending').toString();
                                final earnedAt = data['earnedAt']?.toDate();
                                final paidAt = data['paidAt']?.toDate();
                                final shipmentId = data['shipmentId'] ?? '';
                                final shipmentAmount =
                                    (data['shipmentAmount'] ?? 0).toDouble();
                                final commissionRate =
                                    (data['commissionRate'] ?? 0).toDouble();

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Header
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Commission #${doc.id.substring(0, 8)}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: _getStatusColor(status)
                                                    .withValues(alpha: 0.2),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                status.toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color:
                                                      _getStatusColor(status),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Divider(height: 16),

                                        // Amount
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Amount Earned',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall,
                                                ),
                                                Text(
                                                  '\$${amount.toStringAsFixed(2)}',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .headlineSmall
                                                      ?.copyWith(
                                                        color: Colors.green,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                ),
                                              ],
                                            ),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  'Rate Applied',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall,
                                                ),
                                                Text(
                                                  '${commissionRate.toStringAsFixed(1)}%',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 12),

                                        // Shipment Details
                                        if (shipmentId.isNotEmpty) ...[
                                          Row(
                                            children: [
                                              Icon(Icons.local_shipping,
                                                  size: 16,
                                                  color: Colors.grey[600]),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  'Shipment: ${shipmentId.substring(0, min(12, shipmentId.length))}...',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall,
                                                ),
                                              ),
                                              Text(
                                                'Shipment: \$${shipmentAmount.toStringAsFixed(2)}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                        ],

                                        // Dates
                                        Row(
                                          children: [
                                            Icon(Icons.calendar_today,
                                                size: 16,
                                                color: Colors.grey[600]),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Earned: ${earnedAt != null ? DateFormat('MMM dd, yyyy').format(earnedAt) : 'Unknown'}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall,
                                            ),
                                            if (paidAt != null) ...[
                                              const SizedBox(width: 16),
                                              const Icon(Icons.check_circle,
                                                  size: 16,
                                                  color: Colors.green),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Paid: ${DateFormat('MMM dd, yyyy').format(paidAt)}',
                                                style: const TextStyle(
                                                    color: Colors.green),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  int min(int a, int b) => a < b ? a : b;
}

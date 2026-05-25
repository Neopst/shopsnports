// lib/features/affiliates/presentation/affiliate_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/affiliate_provider.dart';
import '../domain/affiliate_model.dart';

class AffiliateListScreen extends ConsumerStatefulWidget {
  const AffiliateListScreen({super.key});

  @override
  ConsumerState<AffiliateListScreen> createState() =>
      _AffiliateListScreenState();
}

class _AffiliateListScreenState extends ConsumerState<AffiliateListScreen> {
  String? _statusFilter;

  @override
  Widget build(BuildContext context) {
    final affiliatesAsync = ref.watch(affiliatesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Affiliates Management'),
        backgroundColor: const Color(0xFF0A2A66),
        foregroundColor: Colors.white,
        actions: [
          // Status filter dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButton<String>(
              value: _statusFilter,
              hint: const Text(
                'Filter by Status',
                style: TextStyle(color: Colors.white),
              ),
              dropdownColor: const Color(0xFF0A2A66),
              style: const TextStyle(color: Colors.white),
              underline: Container(),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('All Statuses'),
                ),
                ...AffiliateStatus.values.map(
                  (status) => DropdownMenuItem(
                    value: status.name,
                    child: Text(status.name.toUpperCase()),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _statusFilter = value;
                });
              },
            ),
          ),
        ],
      ),
      body: affiliatesAsync.when(
        data: (affiliates) {
          // Apply status filter
          final filteredAffiliates = _statusFilter == null
              ? affiliates
              : affiliates
                    .where((a) => a.status.name == _statusFilter)
                    .toList();

          if (filteredAffiliates.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No affiliates found',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    const Color(0xFF0A2A66).withValues(alpha:0.1),
                  ),
                  columns: const [
                    DataColumn(label: Text('Avatar')),
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Email')),
                    DataColumn(label: Text('Phone')),
                    DataColumn(label: Text('Country')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Commission')),
                    DataColumn(label: Text('Total Earnings')),
                    DataColumn(label: Text('Pending Payout')),
                    DataColumn(label: Text('Shipments')),
                    DataColumn(label: Text('Joined')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: filteredAffiliates.map((affiliate) {
                    return DataRow(
                      cells: [
                        // Avatar
                        DataCell(
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: affiliate.photoUrl != null
                                ? NetworkImage(affiliate.photoUrl!)
                                : null,
                            child: affiliate.photoUrl == null
                                ? Text(affiliate.fullName[0].toUpperCase())
                                : null,
                          ),
                        ),
                        // Name
                        DataCell(Text(affiliate.fullName)),
                        // Email
                        DataCell(Text(affiliate.email)),
                        // Phone
                        DataCell(Text(affiliate.phone)),
                        // Country
                        DataCell(Text(affiliate.countryCode ?? 'N/A')),
                        // Status
                        DataCell(_buildStatusBadge(affiliate.status)),
                        // Commission
                        DataCell(Text('${affiliate.commissionRate}%')),
                        // Total Earnings
                        DataCell(
                          Text(
                            '${affiliate.preferredCurrency.symbol}${affiliate.totalEarnings.toStringAsFixed(2)}',
                          ),
                        ),
                        // Pending Payout
                        DataCell(
                          Text(
                            '${affiliate.preferredCurrency.symbol}${affiliate.pendingPayout.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: affiliate.pendingPayout > 0
                                  ? Colors.green
                                  : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Shipments
                        DataCell(Text(affiliate.totalShipments.toString())),
                        // Joined
                        DataCell(Text(_formatDate(affiliate.joinedDate))),
                        // Actions
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // View Details
                              IconButton(
                                icon: const Icon(Icons.visibility, size: 20),
                                tooltip: 'View Details',
                                onPressed: () {
                                  context.go('/affiliates/${affiliate.id}');
                                },
                              ),
                              // Quick Actions Menu
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, size: 20),
                                onSelected: (value) =>
                                    _handleAction(value, affiliate),
                                itemBuilder: (context) => [
                                  if (affiliate.status ==
                                      AffiliateStatus.pending)
                                    const PopupMenuItem(
                                      value: 'approve',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                            size: 18,
                                          ),
                                          SizedBox(width: 8),
                                          Text('Approve'),
                                        ],
                                      ),
                                    ),
                                  if (affiliate.status ==
                                      AffiliateStatus.pending)
                                    const PopupMenuItem(
                                      value: 'reject',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.cancel,
                                            color: Colors.red,
                                            size: 18,
                                          ),
                                          SizedBox(width: 8),
                                          Text('Reject'),
                                        ],
                                      ),
                                    ),
                                  if (affiliate.status ==
                                      AffiliateStatus.approved)
                                    const PopupMenuItem(
                                      value: 'suspend',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.block,
                                            color: Colors.orange,
                                            size: 18,
                                          ),
                                          SizedBox(width: 8),
                                          Text('Suspend'),
                                        ],
                                      ),
                                    ),
                                  if (affiliate.status ==
                                      AffiliateStatus.suspended)
                                    const PopupMenuItem(
                                      value: 'approve',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                            size: 18,
                                          ),
                                          SizedBox(width: 8),
                                          Text('Reactivate'),
                                        ],
                                      ),
                                    ),
                                  if (affiliate.pendingPayout > 0)
                                    const PopupMenuItem(
                                      value: 'generate_payout',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.payment,
                                            color: Colors.blue,
                                            size: 18,
                                          ),
                                          SizedBox(width: 8),
                                          Text('Generate Payout'),
                                        ],
                                      ),
                                    ),
                                  const PopupMenuDivider(),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                          size: 18,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Delete',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading affiliates: $err'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(AffiliateStatus status) {
    Color color;
    IconData icon;

    switch (status) {
      case AffiliateStatus.pending:
        color = Colors.orange;
        icon = Icons.pending;
        break;
      case AffiliateStatus.approved:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case AffiliateStatus.rejected:
        color = Colors.red;
        icon = Icons.cancel;
        break;
      case AffiliateStatus.suspended:
        color = Colors.grey;
        icon = Icons.block;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            status.name.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _handleAction(String action, Affiliate affiliate) async {
    switch (action) {
      case 'approve':
        await _approveAffiliate(affiliate);
        break;
      case 'reject':
        await _rejectAffiliate(affiliate);
        break;
      case 'suspend':
        await _suspendAffiliate(affiliate);
        break;
      case 'generate_payout':
        await _generatePayout(affiliate);
        break;
      case 'delete':
        await _deleteAffiliate(affiliate);
        break;
    }
  }

  Future<void> _approveAffiliate(Affiliate affiliate) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Affiliate'),
        content: Text('Approve ${affiliate.fullName} as an affiliate?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final repository = ref.read(affiliateRepositoryProvider);
        await repository.approveAffiliate(
          affiliate.id,
          'current_admin_id',
        ); // TODO: Get actual admin ID
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${affiliate.fullName} approved successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _rejectAffiliate(Affiliate affiliate) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Affiliate'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Reject ${affiliate.fullName}?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && reasonController.text.isNotEmpty) {
      try {
        final repository = ref.read(affiliateRepositoryProvider);
        await repository.rejectAffiliate(affiliate.id, reasonController.text);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Affiliate rejected'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _suspendAffiliate(Affiliate affiliate) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suspend Affiliate'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Suspend ${affiliate.fullName}?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Suspension Reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Suspend', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && reasonController.text.isNotEmpty) {
      try {
        final repository = ref.read(affiliateRepositoryProvider);
        await repository.suspendAffiliate(affiliate.id, reasonController.text);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Affiliate suspended'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _generatePayout(Affiliate affiliate) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate Payout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Generate payout for ${affiliate.fullName}?'),
            const SizedBox(height: 16),
            Text(
              'Pending Amount: \$${affiliate.pendingPayout.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text(
              'Generate',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final repository = ref.read(affiliateRepositoryProvider);
        final payoutId = await repository.generatePayoutForAffiliate(
          affiliate.id,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                payoutId != null
                    ? 'Payout generated successfully! ID: $payoutId'
                    : 'No unpaid shipments found',
              ),
              backgroundColor: payoutId != null ? Colors.green : Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _deleteAffiliate(Affiliate affiliate) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Affiliate'),
        content: Text(
          'Are you sure you want to delete ${affiliate.fullName}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final repository = ref.read(affiliateRepositoryProvider);
        await repository.deleteAffiliate(affiliate.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Affiliate deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}

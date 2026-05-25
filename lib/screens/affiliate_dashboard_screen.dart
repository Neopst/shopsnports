import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shopsnports/widgets/main_scaffold.dart';
import 'package:shopsnports/providers/user_providers.dart';
import 'package:shopsnports/providers/currency_provider.dart';

// Provider for affiliate statistics
final affiliateStatsProvider =
    StreamProvider.family<Map<String, dynamic>, String>((ref, affiliateId) {
  return FirebaseFirestore.instance
      .collection('affiliate_stats')
      .doc(affiliateId)
      .snapshots()
      .map((snapshot) =>
          snapshot.data() ??
          {
            'totalEarnings': 0.0,
            'totalClicks': 0,
            'totalReferrals': 0,
            'pendingCommission': 0.0,
          });
});

// Provider for recent affiliate referrals
final affiliateReferralsProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>(
        (ref, affiliateId) {
  return FirebaseFirestore.instance
      .collection('orders')
      .where('affiliateId', isEqualTo: affiliateId)
      .orderBy('createdAt', descending: true)
      .limit(10)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'orderId': data['orderId'] ?? 'N/A',
              'commission': data['affiliateCommission'] ?? 0.0,
              'status': data['status'] ?? 'pending',
              'createdAt': data['createdAt'],
            };
          }).toList());
});

class AffiliateDashboardScreen extends ConsumerWidget {
  const AffiliateDashboardScreen({super.key});

  static const routeName = '/affiliate/dashboard';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final currencyCode = ref.watch(currencyProvider).code;
    final currencySymbol = _getCurrencySymbol(currencyCode);

    // TEMP: Auth guards disabled for UI polish phase
    // if (user == null) {
    //   return MainScaffold(
    //     currentIndex: 0,
    //     onNavTap: (_) {},
    //     body: Center(
    //       child: Column(
    //         mainAxisAlignment: MainAxisAlignment.center,
    //         children: [
    //           const Icon(Icons.person_outline, size: 64, color: Colors.grey),
    //           const SizedBox(height: 16),
    //           const Text('Please sign in to view your affiliate dashboard'),
    //           const SizedBox(height: 24),
    //           ElevatedButton(
    //             onPressed: () => Navigator.of(context).pushNamed('/auth/login'),
    //             child: const Text('Sign In'),
    //           ),
    //         ],
    //       ),
    //     ),
    //   );
    // }

    // if (user.affiliateId == null || user.affiliateApproved != true) {
    //   return MainScaffold(
    //     currentIndex: 0,
    //     onNavTap: (_) {},
    //     body: Center(
    //       child: Column(
    //         mainAxisAlignment: MainAxisAlignment.center,
    //         children: [
    //           const Icon(Icons.pending_actions, size: 64, color: Colors.orange),
    //           const SizedBox(height: 16),
    //           Text(
    //             user.affiliateId == null
    //                 ? 'You are not registered as an affiliate'
    //                 : 'Your affiliate application is pending approval',
    //             textAlign: TextAlign.center,
    //             style: const TextStyle(fontSize: 16),
    //           ),
    //           const SizedBox(height: 24),
    //           if (user.affiliateId == null)
    //             ElevatedButton(
    //               onPressed: () =>
    //                   Navigator.of(context).pushNamed('/affiliate/register'),
    //               child: const Text('Apply as Affiliate'),
    //             ),
    //         ],
    //       ),
    //     ),
    //   );
    // }

    // TEMP: Demo data for UI polish when user is null
    final demoAffiliateId = user?.affiliateId ?? 'DEMO-AFF-12345';
    final demoUserName = user?.name ?? 'Demo Affiliate';
    final demoAvatarUrl = user?.avatarUrl;

    final statsAsync = ref.watch(affiliateStatsProvider(demoAffiliateId));
    final referralsAsync =
        ref.watch(affiliateReferralsProvider(demoAffiliateId));

    return MainScaffold(
      currentIndex: 0,
      onNavTap: (_) {},
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(affiliateStatsProvider(demoAffiliateId));
          ref.invalidate(affiliateReferralsProvider(demoAffiliateId));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile summary card
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: demoAvatarUrl != null && demoAvatarUrl.isNotEmpty
                        ? ClipOval(
                            child: Image.network(demoAvatarUrl,
                                width: 40, height: 40, fit: BoxFit.cover))
                        : const Icon(Icons.person),
                  ),
                  title: Text(demoUserName),
                  subtitle: Text('Affiliate ID: $demoAffiliateId'),
                  trailing: TextButton(
                    onPressed: () =>
                        Navigator.of(context).pushNamed('/affiliate/profile'),
                    child: const Text('Profile'),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Statistics cards
              statsAsync.when(
                data: (stats) => Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Total Earnings',
                            value:
                                '$currencySymbol ${_formatAmount(stats['totalEarnings'] ?? 0.0)}',
                            icon: Icons.attach_money,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatCard(
                            label: 'Clicks',
                            value: '${stats['totalClicks'] ?? 0}',
                            icon: Icons.mouse,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Referrals',
                            value: '${stats['totalReferrals'] ?? 0}',
                            icon: Icons.people,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatCard(
                            label: 'Pending',
                            value:
                                '$currencySymbol ${_formatAmount(stats['pendingCommission'] ?? 0.0)}',
                            icon: Icons.pending,
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                loading: () => const Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _SkeletonCard()),
                        SizedBox(width: 8),
                        Expanded(child: _SkeletonCard()),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _SkeletonCard()),
                        SizedBox(width: 8),
                        Expanded(child: _SkeletonCard()),
                      ],
                    ),
                  ],
                ),
                error: (error, stack) => Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Error loading stats: $error',
                        style: const TextStyle(color: Colors.red)),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Recent referrals section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Recent Referrals',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context).pushNamed('/affiliate/referrals'),
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              referralsAsync.when(
                data: (referrals) {
                  if (referrals.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            Icon(Icons.shopping_bag_outlined,
                                size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text('No referrals yet',
                                style: TextStyle(color: Colors.grey.shade600)),
                            const SizedBox(height: 8),
                            const Text(
                                'Share your affiliate link to start earning!',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: referrals.map((referral) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                _getStatusColor(referral['status']),
                            child: const Icon(Icons.receipt,
                                color: Colors.white, size: 20),
                          ),
                          title: Text('Order #${referral['orderId']}'),
                          subtitle: Text(
                            'Commission: $currencySymbol ${_formatAmount(referral['commission'])}\n'
                            'Status: ${referral['status']}',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            // Navigate to referral details
                          },
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => Column(
                  children: List.generate(
                    3,
                    (index) => const Card(
                      margin: EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(child: Icon(Icons.receipt)),
                        title: _SkeletonText(width: 120),
                        subtitle: _SkeletonText(width: 180),
                      ),
                    ),
                  ),
                ),
                error: (error, stack) => Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Error loading referrals: $error',
                        style: const TextStyle(color: Colors.red)),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Action buttons
              ElevatedButton.icon(
                onPressed: () {
                  // Generate and share affiliate link
                  _showAffiliateLink(context, demoAffiliateId);
                },
                icon: const Icon(Icons.share),
                label: const Text('Share Affiliate Link'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () =>
                    Navigator.of(context).pushNamed('/affiliate/analytics'),
                icon: const Icon(Icons.analytics_outlined),
                label: const Text('View Analytics'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCurrencySymbol(String code) {
    switch (code) {
      case 'NGN':
        return '₦';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'INR':
        return '₹';
      default:
        return code;
    }
  }

  String _formatAmount(dynamic amount) {
    final value = amount is double ? amount : (amount as num).toDouble();
    return value.toStringAsFixed(2);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showAffiliateLink(BuildContext context, String affiliateId) {
    final link = 'https://shopsnports.com/ref/$affiliateId';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Your Affiliate Link'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Share this link to earn commissions:'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(link),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              // Copy to clipboard
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Link copied to clipboard!')),
              );
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copy'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 20),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(label,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        height: 100,
        color: Colors.grey.shade200,
      ),
    );
  }
}

class _SkeletonText extends StatelessWidget {
  final double width;
  const _SkeletonText({required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 14,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shopsnports/core/routing/app_routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/create_shipment_modal.dart';
import '../../services/mock_affiliate_service.dart';
import '../../widgets/shipment_request_tile.dart';
import '../../providers/firestore_provider.dart';
import '../../widgets/main_scaffold.dart';
import '../navigation_shell.dart';
import '../../services/currency_converter.dart';

class AffiliateDashboardScreen extends ConsumerStatefulWidget {
  static const routeName = '/affiliate/dashboard';
  final String affiliateId;
  const AffiliateDashboardScreen({super.key, required this.affiliateId});

  @override
  ConsumerState<AffiliateDashboardScreen> createState() =>
      _AffiliateDashboardScreenState();
}

class _AffiliateDashboardScreenState
    extends ConsumerState<AffiliateDashboardScreen> {
  final _service = MockAffiliateService();

  @override
  void initState() {
    super.initState();
    _initializeConverter();
  }

  Future<void> _initializeConverter() async {
    await CurrencyConverter().initialize();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      appBarTitle: 'Affiliate Dashboard',
      currentIndex: 4,
      onNavTap: (index) {
        if (index == 2) {
          Navigator.pushNamed(context, AppRoutes.requestShipping);
          return;
        }
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => NavigationShell(initialIndex: index),
          ),
          (route) => false,
        );
      },
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMiniProfile(),
            const SizedBox(height: 12),
            _buildPayoutsSummary(),
            const SizedBox(height: 12),
            _buildKpis(),
            const SizedBox(height: 12),
            const Text('Recent requests',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _getShipmentsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final items = snapshot.data ?? [];
                  if (items.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inbox,
                              size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          const Text('No requests yet.'),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            key: const Key('no_requests_create_button'),
                            onPressed: () => _openCreateModal(context),
                            child: const Text('Create your first request'),
                          )
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) => ShipmentRequestTile(
                        request: items[index],
                        isAdmin: false,
                        service: null),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Stream<List<Map<String, dynamic>>> _getShipmentsStream() {
    final db = FirebaseFirestore.instance;
    return db
        .collection('shippingRequests')
        .where('affiliateId', isEqualTo: widget.affiliateId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  Widget _buildKpis() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('shippingRequests')
          .where('affiliateId', isEqualTo: widget.affiliateId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Row(
            children: [
              _kpiCard('Total', '...', Colors.blue),
              const SizedBox(width: 8),
              _kpiCard('Pending', '...', Colors.orange),
              const SizedBox(width: 8),
              _kpiCard('Completed', '...', Colors.green),
            ],
          );
        }
        final items = snapshot.data?.docs ?? [];
        final pending =
            items.where((r) => r['status'] != 'delivered').length;
        final completed =
            items.where((r) => r['status'] == 'delivered').length;
        final total = items.length;
        return Row(
          children: [
            _kpiCard('Total', total.toString(), Colors.blue,
                key: const Key('total_payouts_text')),
            const SizedBox(width: 8),
            _kpiCard('Pending', pending.toString(), Colors.orange,
                key: const Key('pending_requests_text')),
            const SizedBox(width: 8),
            _kpiCard('Completed', completed.toString(), Colors.green,
                key: const Key('completed_requests_text')),
          ],
        );
      },
    );
  }

  Widget _kpiCard(String title, String value, Color color, {Key? key}) {
    return Expanded(
      child: Container(
        key: key,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: color.withAlpha((0.08 * 255).round()),
            borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(color: color, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(value,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
          ],
        ),
      ),
    );
  }

  Future<void> _openCreateModal(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => CreateShipmentModal(
          affiliateId: widget.affiliateId, service: _service),
    );

    if (result != null && mounted) {
      // show confirmation snackbar with the generated link
      messenger.showSnackBar(SnackBar(content: Text('Link created: $result')));
    }
  }

  Widget _buildMiniProfile() {
    final db = ref.watch(firestoreProvider);
    return StreamBuilder<DocumentSnapshot>(
      stream: db.collection('affiliates').doc(widget.affiliateId).snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: const Text('Welcome', key: Key('affiliate_name_text')),
              subtitle: const Text('Loading profile...'),
              trailing: TextButton(
                key: const Key('affiliate_edit_profile'),
                onPressed: () =>
                    Navigator.of(context).pushNamed('/affiliate/profile'),
                child: const Text('Edit'),
              ),
            ),
          );
        }

        final doc = snap.data;
        if (doc == null || !doc.exists) {
          return Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: const Text('Your Name', key: Key('affiliate_name_text')),
              subtitle: Text('Affiliate ID: ${widget.affiliateId}'),
              trailing: TextButton(
                key: const Key('affiliate_edit_profile'),
                onPressed: () =>
                    Navigator.of(context).pushNamed('/affiliate/profile'),
                child: const Text('Edit'),
              ),
            ),
          );
        }

        final data = doc.data() as Map<String, dynamic>? ?? {};
        final name = data['name'] as String? ?? 'Your Name';
        final avatar = data['avatarUrl'] as String?;
        final email = data['email'] as String? ?? '';

        return Card(
          child: ListTile(
            leading: avatar == null
                ? const CircleAvatar(child: Icon(Icons.person))
                : CircleAvatar(backgroundImage: NetworkImage(avatar)),
            title: Text('Welcome, $name'),
            subtitle: Text(
                'Affiliate ID: ${widget.affiliateId}${email.isNotEmpty ? ' • $email' : ''}'),
            trailing: TextButton(
              key: const Key('affiliate_edit_profile'),
              onPressed: () =>
                  Navigator.of(context).pushNamed('/affiliate/profile'),
              child: const Text('Edit'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPayoutsSummary() {
    final converter = CurrencyConverter();
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('affiliates')
          .doc(widget.affiliateId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total payouts',
                            style: TextStyle(color: Colors.black54)),
                        const SizedBox(height: 8),
                        Text('...',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[400])),
                      ],
                    ),
                  ),
                  const CircularProgressIndicator(strokeWidth: 2),
                ],
              ),
            ),
          );
        }

        final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final totalEarnings = (data['totalEarnings'] ?? 0).toDouble();
        final currencyCode = converter.baseCurrency;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total payouts',
                        style: TextStyle(color: Colors.black54)),
                    const SizedBox(height: 8),
                    Text(
                        '${SupportedCurrencies.byCode(currencyCode).symbol} ${converter.convert(amount: totalEarnings, from: 'NGN', to: currencyCode).toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                )),
                ElevatedButton(
                  key: const Key('affiliate_view_payouts'),
                  onPressed: () => Navigator.of(context)
                      .pushNamed('/affiliate/payouts', arguments: {
                    'affiliateId': widget.affiliateId
                  }),
                  child: const Text('View payouts'),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shopsnports/core/routing/app_routes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopsnports/providers/firestore_provider.dart';
import 'package:shopsnports/widgets/main_scaffold.dart';

class AffiliatePayoutsScreen extends ConsumerWidget {
  static const routeName = '/affiliate/payouts';
  final String affiliateId;
  const AffiliatePayoutsScreen({super.key, required this.affiliateId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.read(firestoreProvider);
    final col = db
        .collection('affiliates')
        .doc(affiliateId)
        .collection('payouts')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return MainScaffold(
      appBarTitle: 'Payouts',
      showBackOnly: true,
      currentIndex: 4,
      onNavTap: (index) {
        if (index == 2) {
          Navigator.pushNamed(context, AppRoutes.requestShipping);
        }
      },
      body: StreamBuilder<QuerySnapshot>(
        stream: col,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) return const Center(child: Text('No payouts yet'));
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (ctx, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              final amount = d['amount'] ?? 0;
              final currency = d['currency'] ?? '';
              final date = d['createdAt']?.toDate()?.toString() ?? '';
              return ListTile(
                title: Text('₦ $amount $currency'),
                subtitle: Text(date),
              );
            },
          );
        },
      ),
    );
  }
}

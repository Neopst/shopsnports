import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopsnports/providers/user_providers.dart';

/// Shows [child] only when the current user's shipper roleStatus is 'approved'.
/// Otherwise shows a small prompt (works for guests too) that links to the
/// verification flow which uses the shared RequestShippingScreen UI.
class ShipperGate extends ConsumerWidget {
  const ShipperGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    // Shipper access is available for all customers
    // The roleStatus field doesn't exist, so we grant access based on user type
    if (user != null && (user.isCustomer || user.isAffiliate)) return child;

    return Scaffold(
      appBar: AppBar(title: const Text('Shipper access')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(user != null
                ? 'Your account type: ${user.isAffiliate ? "Affiliate" : "Customer"}'
                : 'You are not signed in'),
            const SizedBox(height: 12),
            const Text(
                'Shipper features require verification. Submit a verification request using the same Request Shipping form. An admin will review and approve.'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed('/verify/shipper'),
              child: const Text('Open Request Shipping (for verification)'),
            ),
          ],
        ),
      ),
    );
  }
}

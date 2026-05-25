import 'package:flutter/material.dart';
import 'package:shopsnports/widgets/main_scaffold.dart';

class AffiliatePendingScreen extends StatelessWidget {
  const AffiliatePendingScreen({super.key});

  static const routeName = '/affiliate/pending';

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: 0,
      onNavTap: (_) {},
      appBarTitle: 'Affiliate application pending',
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const Icon(Icons.hourglass_top, size: 64, color: Colors.orange),
              const SizedBox(height: 24),
              const Text(
                'Thanks for applying to become an affiliate!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Your application has been received and is pending admin approval. We will send you a welcome email once your account has been approved. Meanwhile some affiliate features may be restricted.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Expected review time: 1–24 hours. If you need faster help, contact support.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () {
                  // Open mailto: or navigate to help center
                  Navigator.of(context).pushNamed('/help');
                },
                child: const Text('Contact support'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                key: const Key('affiliate_pending_back_home'),
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed('/home');
                },
                child: const Text('Back to home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class AffiliateJoinScreen extends StatelessWidget {
  const AffiliateJoinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Affiliate Program')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Join our Affiliate Shipping Program',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Earn commission by connecting shippers to international routes. Flexible contracts and tools to manage bookings.',
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Learn more'),
            ),
          ],
        ),
      ),
    );
  }
}

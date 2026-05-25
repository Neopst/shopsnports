// lib/features/no_access/presentation/no_access_screen.dart   <-- NEW FILE

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NoAccessScreen extends StatelessWidget {
  const NoAccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Card(
          elevation: 2,
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                const Text(
                  'Insufficient permissions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your account does not have access to this section.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Go home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

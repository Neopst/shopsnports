import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopsnports/providers/user_providers.dart';
import 'package:shopsnports/core/routing/app_routes.dart';

class CustomerHomeScreen extends ConsumerWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Customer Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (user != null) Text('Hello ${user.name}'),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: () {
                  final prefill = <String, dynamic>{
                    'senderName': user?.name ?? 'Demo Customer',
                    'destination': 'Lagos, NG',
                    'description': 'Demo goods',
                  };
                  Navigator.of(context)
                      .pushNamed(AppRoutes.requestShipping, arguments: prefill);
                },
                child: const Text('Request Shipping (open form)'))
          ],
        ),
      ),
    );
  }
}

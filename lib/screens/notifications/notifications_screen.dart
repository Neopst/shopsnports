import 'package:flutter/material.dart';
import 'package:shopsnports/core/routing/app_routes.dart';
import 'package:shopsnports/widgets/main_scaffold.dart';

class NotificationsScreen extends StatelessWidget {
  static const routeName = '/notifications';
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      appBarTitle: 'Notifications',
      showBackOnly: true,
      currentIndex: 0,
      onNavTap: (index) {
        if (index == 2) {
          Navigator.pushNamed(context, AppRoutes.requestShipping);
        }
      },
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: 8,
        itemBuilder: (_, i) => ListTile(
            title: Text('Notification ${i + 1}'),
            subtitle: const Text('Short message')),
      ),
    );
  }
}

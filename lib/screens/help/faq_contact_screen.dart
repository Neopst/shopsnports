import 'package:flutter/material.dart';
import 'package:shopsnports/core/routing/app_routes.dart';
import 'package:shopsnports/widgets/main_scaffold.dart';

class FaqContactScreen extends StatelessWidget {
  static const routeName = '/help/faq';
  const FaqContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      appBarTitle: 'Help & FAQ',
      showBackOnly: true,
      currentIndex: 4,
      onNavTap: (index) {
        if (index == 2) {
          Navigator.pushNamed(context, AppRoutes.requestShipping);
        }
      },
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const ExpansionTile(
            title: Text('How do I return an item?'),
            children: [
              Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('Return policy details...'))
            ],
          ),
          const ExpansionTile(
            title: Text('Shipping times'),
            children: [
              Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('Shipping details...'))
            ],
          ),
          const Divider(),
          ListTile(
              title: const Text('Contact support'),
              subtitle: const Text('support@example.com'),
              trailing:
                  ElevatedButton(onPressed: () {}, child: const Text('Email'))),
        ],
      ),
    );
  }
}

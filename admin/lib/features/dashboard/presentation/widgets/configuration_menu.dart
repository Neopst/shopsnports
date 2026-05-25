import 'package:flutter/material.dart';

class ConfigurationMenu extends StatelessWidget {
  const ConfigurationMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Configuration',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          _configItem(Icons.settings, 'General Config'),
          _configItem(Icons.payment, 'Payment Config'),
          _configItem(Icons.flight, 'Shipping Config'),
          const Divider(),
          TextButton(
            onPressed: () {
              debugPrint('Advanced Settings tapped');
            },
            child: const Text('Advanced Settings →'),
          ),
        ],
      ),
    );
  }

  /// Helper method for building config menu items
  static Widget _configItem(IconData icon, String text) {
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 20),
      title: Text(text),
      onTap: () {
        debugPrint('$text tapped');
      },
    );
  }
}

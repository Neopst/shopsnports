import 'package:flutter/material.dart';

class PlaceholderPage extends StatelessWidget {
  final String title;
  final String imagePath;

  const PlaceholderPage({
    super.key,
    required this.title,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(imagePath, height: 200),
          const SizedBox(height: 20),
          SelectableText(
            // ✅ selectable/copyable title
            title,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 10),
          const SelectableText(
            // ✅ selectable/copyable directory path
            'assets/images/',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

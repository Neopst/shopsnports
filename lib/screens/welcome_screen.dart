import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'package:shopsnports/widgets/main_scaffold.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: 0,
      onNavTap: (_) {},
      appBar: null,
      appBarTitle: 'Welcome',
      showNewsTicker: false,
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const HomeScreen(),
              ),
            );
          },
          child: const Text('Go to Home'),
        ),
      ),
    );
  }
}

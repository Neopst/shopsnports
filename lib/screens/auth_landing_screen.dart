import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopsnports/widgets/main_scaffold.dart';
import 'package:shopsnports/screens/auth_signin_screen.dart';
import 'package:shopsnports/screens/auth_signup_screen.dart';
import 'package:shopsnports/providers/auth_provider.dart';
import 'package:shopsnports/screens/home_screen.dart';
import 'package:shopsnports/screens/phone_login_screen.dart';

class AuthLandingScreen extends ConsumerWidget {
  const AuthLandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(firebaseUserProvider);

    return userAsync.when(
      data: (user) {
        if (user != null) {
          // user already signed in — redirect to home after build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const HomeScreen()));
          });
          return const SizedBox.shrink();
        }

        return MainScaffold(
          currentIndex: 4,
          onNavTap: (_) {},
          body: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              ElevatedButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const AuthSignInScreen())),
                  child: const Text('Sign In')),
              const SizedBox(height: 8),
              OutlinedButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const AuthSignUpScreen())),
                  child: const Text('Create Account')),
              const SizedBox(height: 8),
              TextButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const PhoneLoginScreen())),
                  child: const Text('Phone login (OTP)'))
            ]),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => MainScaffold(
        currentIndex: 4,
        onNavTap: (_) {},
        body: const Center(child: Text('Error loading auth')),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../styles/colors.dart';
import 'package:shopsnports/providers/auth_provider.dart';
import 'package:shopsnports/core/routing/app_routes.dart';
// Onboarding removed - previously opened onboarding tour
import '../screens/placeholder_page.dart';
// url launcher removed - social icons replaced with admin link

class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    // social links removed; helper kept removed to avoid unused-declaration

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: AppColors.primaryColor),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: AssetImage('assets/images/logo.png'),
                  ),
                  SizedBox(height: 8),
                  SelectableText(
                    // ✅ selectable header text
                    'Welcome to ShopsNports',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const SelectableText('Home'),
              onTap: () {
                // Close the drawer then navigate to the home screen as the
                // app root so users return to the real home and not the
                // initial splash screen.
                Navigator.pop(context);
                Navigator.pushNamedAndRemoveUntil(
                    context, AppRoutes.home, (r) => false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite),
              title: const SelectableText('Wishlist'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PlaceholderPage(
                      title: 'Wishlist',
                      imagePath: 'assets/images/2.jpg',
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_bag),
              title: const SelectableText('Orders'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PlaceholderPage(
                      title: 'Orders',
                      imagePath: 'assets/images/3.jpg',
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const SelectableText('Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.profile);
              },
            ),
            // Vendor Profile removed - app is shipping/cargo focused, not eCommerce
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const SelectableText('Affiliate Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.affiliateProfile);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const SelectableText('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.settings);
              },
            ),
            ListTile(
              leading: const Icon(Icons.help),
              title: const SelectableText('Help Center'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PlaceholderPage(
                      title: 'Help Center',
                      imagePath: 'assets/images/4.jpg',
                    ),
                  ),
                );
              },
            ),
            // Logout (uses AuthActions provider to sign out)
            Consumer(
              builder: (ctx, ref, _) => ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () async {
                  final navigator = Navigator.of(context);
                  navigator.pop();
                  try {
                    await ref.read(authActionsProvider).signOut();
                  } catch (_) {}
                  navigator.pushNamedAndRemoveUntil(
                      AppRoutes.login, (r) => false);
                },
              ),
            ),
            // ...existing drawer items...
          ],
        ),
      ),
    );
  }
}

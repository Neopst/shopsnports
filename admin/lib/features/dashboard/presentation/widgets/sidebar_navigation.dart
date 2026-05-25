import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/data/providers/auth_providers.dart';

class SidebarNavigation extends ConsumerStatefulWidget {
  final String currentRoute;

  const SidebarNavigation({super.key, required this.currentRoute});

  @override
  ConsumerState<SidebarNavigation> createState() => _SidebarNavigationState();
}

class _SidebarNavigationState extends ConsumerState<SidebarNavigation> {
  int _selectedIndex = 0;

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.dashboard,
      label: 'Overview',
      route: '/dashboard/overview',
    ),
    NavigationItem(
      icon: Icons.people,
      label: 'Customers',
      route: '/dashboard/customers',
    ),
    // Removed Orders (legacy e-commerce feature)
    // NavigationItem(
    //   icon: Icons.shopping_cart,
    //   label: 'Orders',
    //   route: '/dashboard/orders',
    // ),
    NavigationItem(
      icon:
          Icons.airplanemode_active, // Changed from local_shipping to airplane
      label: 'Shipping',
      route: '/dashboard/shipping-request',
    ),
    NavigationItem(
      icon: Icons.handshake,
      label: 'Affiliates',
      route: '/dashboard/affiliates',
    ),
    NavigationItem(
      icon: Icons.account_balance_wallet,
      label: 'Payouts',
      route: '/dashboard/payouts',
    ),
    NavigationItem(
      icon: Icons.receipt,
      label: 'Invoices',
      route: '/dashboard/invoices',
    ),
    // Removed Analytics - ecommerce focused, use Overview dashboard instead
    // NavigationItem(
    //   icon: Icons.analytics,
    //   label: 'Analytics',
    //   route: '/dashboard/analytics',
    // ),
    NavigationItem(
      icon: Icons.notifications,
      label: 'Notifications',
      route: '/dashboard/notifications',
    ),
    NavigationItem(
      icon: Icons.notifications_active,
      label: 'Push Notifications',
      route: '/dashboard/push-notifications',
    ),
    NavigationItem(
      icon: Icons.newspaper,
      label: 'News Ticker',
      route: '/dashboard/news-ticker',
    ),
    NavigationItem(
      icon: Icons.security,
      label: 'Super Admin',
      route: '/dashboard/super-admin',
    ),
    NavigationItem(
      icon: Icons.content_copy,
      label: 'Content',
      route: '/dashboard/content',
    ),
    NavigationItem(
      icon: Icons.settings,
      label: 'Settings',
      route: '/dashboard/settings',
    ),
    NavigationItem(
      icon: Icons.tune,
      label: 'Configuration',
      route: '/dashboard/configuration',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _updateSelectedIndex();
  }

  @override
  void didUpdateWidget(covariant SidebarNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentRoute != widget.currentRoute) {
      _updateSelectedIndex();
    }
  }

  void _updateSelectedIndex() {
    final currentRoute = widget.currentRoute;
    final index = _navigationItems.indexWhere(
      (item) => item.route == currentRoute,
    );
    if (index != -1) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    context.go(_navigationItems[index].route);
  }

  Widget _buildUserSection() {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const SizedBox();
        }

        return Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.blue[100],
              child: Text(
                (user.displayName?.isNotEmpty ?? false)
                    ? user.displayName![0].toUpperCase()
                    : user.email[0].toUpperCase(),
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName ?? 'User',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    user.role ?? 'User',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            PopupMenuButton(
              icon: const Icon(Icons.more_vert, size: 20),
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: const Row(
                    children: [
                      Icon(Icons.person, size: 18),
                      SizedBox(width: 12),
                      Text('Profile'),
                    ],
                  ),
                  onTap: () {
                    context.go('/profile');
                  },
                ),
                PopupMenuItem(
                  child: const Row(
                    children: [
                      Icon(Icons.logout, size: 18, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Sign Out', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                  onTap: () {
                    _logout(context);
                  },
                ),
              ],
            ),
          ],
        );
      },
      loading: () => const Center(
        child: SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, __) => const SizedBox(),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(signOutProvider.future);
        if (mounted) {
          context.go('/');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final deepBlue =
        Colors.blue[900]; // Using dark blue instead of non-existent deepBlue

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          right: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Logo/Header
          Container(
            height: 80,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                // ShopsNports Logo
                Image.asset(
                  'assets/icons/logo.png',
                  width: 40,
                  height: 40,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      'assets/icons/logo.jpg',
                      width: 40,
                      height: 40,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: deepBlue,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.store, color: Colors.white),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(width: 12),
                Text(
                  'ShopsNports',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: deepBlue,
                  ),
                ),
              ],
            ),
          ),
          // Navigation Items
          Expanded(
            child: ListView.builder(
              itemCount: _navigationItems.length,
              itemBuilder: (context, index) {
                final item = _navigationItems[index];
                final isSelected = _selectedIndex == index;

                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: ListTile(
                    leading: Icon(
                      item.icon,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withAlpha(150),
                    ),
                    title: Text(
                      item.label,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    tileColor: isSelected
                        ? Theme.of(context).colorScheme.primary.withAlpha(30)
                        : Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onTap: () => _onItemTapped(index),
                  ),
                );
              },
            ),
          ),
          // User Profile/Logout Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: _buildUserSection(),
          ),
        ],
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final String label;
  final String route;

  const NavigationItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}

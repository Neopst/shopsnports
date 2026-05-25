// Clean, robust implementation of MainScaffold
// ignore_for_file: prefer_const_constructors, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
// import 'package:shopsnports/screens/wishlist_screen.dart';
import 'package:shopsnports/screens/notifications_screen.dart';
import 'package:shopsnports/providers/user_providers.dart';
import 'package:shopsnports/core/routing/app_routes.dart';
import 'package:shopsnports/providers/auth_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shopsnports/providers/app_state_provider.dart';
// import 'package:shopsnports/providers/cart_provider.dart';
import 'package:shopsnports/providers/active_role_provider.dart';
// Removed unused provider imports; main app provides required providers.
import '../styles/colors.dart';
import 'package:shopsnports/services/push_notification_service.dart';
import 'package:shopsnports/widgets/news_ticker.dart';
import 'package:shopsnports/widgets/nav_item.dart';
import 'package:shopsnports/widgets/currency_selector.dart';
import 'package:shopsnports/screens/navigation_shell.dart';

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({
    super.key,
    this.currentIndex = 0,
    this.onNavTap,
    required this.body,
    this.appBar,
    this.appBarTitle,
    this.showBackOnly = false,
    this.enablePullToRefresh = false,
    this.newsItems,
    this.onRefresh,
    this.onLoadMore,
    this.topWidget,
    this.showNewsTicker = false,
    this.enableInfiniteScroll = false,
  });

  final int currentIndex;
  final void Function(int)? onNavTap;
  final Widget body;
  final PreferredSizeWidget? appBar;
  final String? appBarTitle;
  final bool showBackOnly;
  final bool enablePullToRefresh;
  final List<String>? newsItems;
  final Future<void> Function()? onRefresh;
  final VoidCallback? onLoadMore;
  final bool enableInfiniteScroll;
  final Widget? topWidget;
  final bool showNewsTicker;

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  final ScrollController _primaryScrollController = ScrollController();
  final bool _isLoadingMore = false;
  static const double _loadMoreThreshold = 200;
  String _selectedLanguage = 'EN';

  @override
  void dispose() {
    _primaryScrollController.dispose();
    super.dispose();
  }

  Widget _buildBadgeIcon(IconData icon, int count, Color color) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, color: Colors.black87),
        if (count > 0)
          Positioned(
            right: -6,
            top: -6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              alignment: Alignment.center,
              child: Text(
                '$count',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (widget.onLoadMore == null) return false;
    final metrics = notification.metrics;
    if (metrics.axis == Axis.vertical) {
      final thresholdReached =
          metrics.pixels >= (metrics.maxScrollExtent - _loadMoreThreshold);
      if (thresholdReached && !_isLoadingMore && metrics.maxScrollExtent > 0) {
        widget.onLoadMore!();
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);

    // determine whether this scaffold is being shown inside the NavigationShell
    // (the shell already provides its own bottom navigation bar and FAB).  When
    // true we suppress MainScaffold's bottom bar to avoid duplication.
    final bool insideShell =
        context.findAncestorWidgetOfExactType<NavigationShell>() != null;

    final Widget bodyWithScrollHandling = PrimaryScrollController(
      controller: _primaryScrollController,
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScrollNotification,
        child: widget.body,
      ),
    );

    final PreferredSizeWidget defaultAppBar = AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      iconTheme: const IconThemeData(color: Colors.black87),
      titleSpacing: 0,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu, color: Colors.black87),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
          tooltip: 'Open navigation menu',
        ),
      ),
      title: Row(
        children: [
          // Logo
          Padding(
            padding: const EdgeInsets.only(left: 6.0, right: 6.0),
            child: SizedBox(
              width: 55,
              height: 65,
              child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
            ),
          ),
          // Back button (if showBackOnly is true)
          if (widget.showBackOnly)
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => Navigator.maybePop(context),
            ),
          // Title
          if (widget.appBarTitle != null)
            Flexible(
              child: Text(
                widget.appBarTitle!,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w700,
                  fontSize: widget.showBackOnly ? 16 : 18,
                ),
              ),
            )
          else
            const Spacer(),
        ],
      ),
      actions: [
        // Notifications badge (single icon)
        IconButton(
          icon: _buildBadgeIcon(Icons.notifications_none,
              appState.notificationCount, Colors.blue),
          tooltip: 'Notifications',
          onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen())),
        ),
        // Settings shortcut available on all screens
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          tooltip: 'Settings',
          onPressed: () => Navigator.of(context).pushNamed('/settings'),
        ),
      ],
    );

    final Widget refreshWrapped = widget.enablePullToRefresh
        ? LiquidPullToRefresh(
            onRefresh: widget.onRefresh ?? () async {},
            backgroundColor: Colors.white,
            child: bodyWithScrollHandling,
          )
        : bodyWithScrollHandling;

    // Always build the full Scaffold containing the app bar and drawer.
    // Previously we skipped this when an ancestor Scaffold existed, but that
    // prevented the menu icon (and therefore navigation) from appearing when
    // MainScaffold was used inside a Shell/NavigationShell. Nested scaffolds
    // are now allowed; callers can opt-out by passing their own AppBar or
    // wrapping content differently if needed.

    // Handle back button: if not on home tab (index 0), navigate to home first
    // Otherwise, allow normal back navigation
    return PopScope(
      canPop: widget.currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && widget.currentIndex != 0) {
          widget.onNavTap?.call(0);
        }
      },
      child: Scaffold(
        extendBody: true,
        appBar: widget.appBar ?? defaultAppBar,
        drawer: Drawer(
          child: SafeArea(
            child: Column(
              children: [
                // Header Section
                Consumer(builder: (context, ref, _) {
                  final user = ref.watch(currentUserProvider);
                  // Show email as name if name is empty/missing
                  final displayName = (user?.name.isNotEmpty == true)
                      ? user!.name
                      : user?.email ?? 'Guest User';
                  return UserAccountsDrawerHeader(
                    decoration: BoxDecoration(color: AppColors.primary),
                    accountName: Text(displayName),
                    accountEmail: Text(user?.email ?? 'guest@example.com'),
                    currentAccountPicture: CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 32,
                      child: user?.avatarUrl != null
                          ? ClipOval(
                              child: Image.network(user!.avatarUrl!,
                                  fit: BoxFit.cover))
                          : const Icon(Icons.person, color: Colors.black54),
                    ),
                  );
                }),

                // Role Switcher (only for vendor/affiliate users)
                Consumer(builder: (context, ref, _) {
                  final user = ref.watch(currentUserProvider);
                  final availableRoles = ref.watch(availableRolesProvider);
                  final activeRole = ref.watch(activeRoleProvider);

                  // Only show if user has vendor OR affiliate role
                  final hasBusinessRole = user?.isAffiliate == true;

                  if (!hasBusinessRole || availableRoles.length <= 1) {
                    return const SizedBox.shrink();
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Active Role',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: availableRoles.map((role) {
                            final isActive = activeRole == role.value;
                            return ChoiceChip(
                              label: Text('${role.icon} ${role.label}'),
                              selected: isActive,
                              onSelected: (selected) async {
                                if (selected) {
                                  await ref
                                      .read(activeRoleProvider.notifier)
                                      .setRole(role.value);
                                  final route =
                                      ref.read(roleRouteProvider(role.value));
                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                    Navigator.of(context)
                                        .pushNamedAndRemoveUntil(
                                            route, (r) => false);
                                  }
                                }
                              },
                              selectedColor: AppColors.primary.withValues(alpha: 0.2),
                              labelStyle: TextStyle(
                                fontSize: 13,
                                fontWeight: isActive
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isActive
                                    ? AppColors.primary
                                    : Colors.black87,
                              ),
                            );
                          }).toList(),
                        ),
                        const Divider(height: 24),
                      ],
                    ),
                  );
                }),

                // Scrollable Menu Section
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      // Currency + language switcher with flags
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.currency_exchange, size: 20),
                                const SizedBox(width: 8),
                                const Text('Currency',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Use the new CurrencySelector widget with flags
                            const CurrencySelector(),
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.language, size: 20),
                                const SizedBox(width: 8),
                                const Text('Language',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    value: _selectedLanguage,
                                    underline: const SizedBox(),
                                    items: const [
                                      DropdownMenuItem(
                                          value: 'EN', child: Text('🇺🇸 English')),
                                      DropdownMenuItem(
                                          value: 'ES', child: Text('🇪🇸 Español')),
                                      DropdownMenuItem(
                                          value: 'FR', child: Text('🇫🇷 Français')),
                                      DropdownMenuItem(
                                          value: 'AR', child: Text('🇸🇦 العربية')),
                                      DropdownMenuItem(
                                          value: 'HI', child: Text('🇮🇳 हिंदी')),
                                    ],
                                    onChanged: (val) {
                                      if (val == null) return;
                                      setState(() => _selectedLanguage = val);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Main navigation links
                      ListTile(
                        key: const Key('drawer_home'),
                        leading: const Icon(Icons.home_outlined),
                        title: const Text('Home'),
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            AppRoutes.home,
                            (route) => false,
                          );
                        },
                      ),
                      ListTile(
                        key: const Key('drawer_request_shipping'),
                        leading: const Icon(Icons.local_shipping_outlined),
                        title: const Text('Request Shipping'),
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context)
                              .pushNamed(AppRoutes.requestShipping);
                        },
                      ),
                      ListTile(
                        key: const Key('drawer_shipments'),
                        leading: const Icon(Icons.list_alt_outlined),
                        title: const Text('My Shipments'),
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pushNamed(AppRoutes.shipments);
                        },
                      ),
                      // only show dashboard link to affiliates
                      Consumer(builder: (ctx, ref, _) {
                        final user = ref.watch(currentUserProvider);
                        if (user?.affiliateId == null) {
                          return const SizedBox.shrink();
                        }
                        return ListTile(
                          key: const Key('drawer_affiliate_dashboard'),
                          leading: const Icon(Icons.card_giftcard_outlined),
                          title: const Text('Affiliate Dashboard'),
                          onTap: () {
                            Navigator.of(ctx).pop();
                            Navigator.of(ctx).pushNamed('/affiliate/dashboard');
                          },
                        );
                      }),
                      ListTile(
                        key: const Key('drawer_profile'),
                        leading: const Icon(Icons.person),
                        title: const Text('Profile'),
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pushNamed(AppRoutes.profile);
                        },
                      ),
                      ListTile(
                        key: const Key('drawer_help'),
                        leading: const Icon(Icons.help_outline),
                        title: const Text('Help & Support'),
                        onTap: () => Navigator.of(context).pushNamed('/help'),
                      ),
                      // Single app‑tour entry
                      ListTile(
                        key: const Key('drawer_app_tour'),
                        leading: const Icon(Icons.tour),
                        title: const Text('App tour'),
                        onTap: () {
                          Navigator.of(context).pop(); // Close drawer
                          Navigator.of(context).pushNamed(AppRoutes.splash);
                        },
                      ),
                      ListTile(
                        key: const Key('drawer_affiliate_program'),
                        leading: const Icon(Icons.card_giftcard_outlined),
                        title: const Text('Join our affiliate program'),
                        onTap: () {
                          Navigator.of(context).pop(); // Close drawer
                          Navigator.of(context).pushNamed('/affiliate/intro');
                        },
                      ),

                      // Conditional role-based links (vendor/admin/affiliate)
                      // Removed vendor dashboard, shopping, and wishlist links

                      // Spacer to push social media and settings to bottom
                      // Removed - now using fixed bottom section
                    ],
                  ),
                ),

                // Fixed Bottom Section
                const Divider(height: 1),

                // Social icons row (Facebook, Twitter, Instagram)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        key: const Key('drawer_social_facebook'),
                        icon: const Icon(Icons.facebook),
                        onPressed: () async {
                          final uri = Uri.parse('https://facebook.com');
                          if (await canLaunchUrl(uri)) await launchUrl(uri);
                        },
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        key: const Key('drawer_social_twitter'),
                        icon: const Icon(Icons.alternate_email),
                        onPressed: () async {
                          final uri = Uri.parse('https://twitter.com');
                          if (await canLaunchUrl(uri)) await launchUrl(uri);
                        },
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        key: const Key('drawer_social_instagram'),
                        icon: const Icon(Icons.camera_alt_outlined),
                        onPressed: () async {
                          final uri = Uri.parse('https://instagram.com');
                          if (await canLaunchUrl(uri)) await launchUrl(uri);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Bottom horizontal row: Settings | Login/Logout (Help moved up)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12.0, vertical: 8.0),
                  child: Consumer(builder: (context, ref, _) {
                    final user = ref.watch(currentUserProvider);
                    final isSignedIn = user != null;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            key: const Key('drawer_bottom_settings'),
                            onPressed: () =>
                                Navigator.of(context).pushNamed('/settings'),
                            icon: const Icon(Icons.settings, size: 18),
                            label: const Text('Settings'),
                          ),
                        ),
                        Expanded(
                          child: TextButton.icon(
                            key: const Key('drawer_bottom_login'),
                            onPressed: () async {
                              if (isSignedIn) {
                                // sign out
                                // reset push notification flag so user will be
                                // prompted again after logging in next time
                                await PushNotificationService()
                                    .resetAskedFlag();
                                await ref.read(authActionsProvider).signOut();
                                // Navigate to login and clear entire navigation stack
                                // This prevents user from going back to authenticated screens
                                if (context.mounted) {
                                  Navigator.of(context).pushNamedAndRemoveUntil(
                                    '/auth/login',
                                    (route) => false,
                                  );
                                }
                              } else {
                                Navigator.of(context).pushNamed('/auth/login');
                              }
                            },
                            icon: Icon(isSignedIn ? Icons.logout : Icons.login,
                                size: 18),
                            label: Text(isSignedIn ? 'Logout' : 'Login'),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
        body: Column(
          children: [
            if (widget.topWidget != null)
              widget.topWidget!
            else if (widget.showNewsTicker)
              const NewsTicker(),
            Expanded(child: refreshWrapped),
          ],
        ),
        floatingActionButton: insideShell
            ? null
            : KeyedSubtree(
                key: const Key('create_shipment_fab'),
                child: FloatingActionButton(
                  onPressed: () => widget.onNavTap?.call(2),
                  tooltip: 'Request Shipping',
                  child: const Icon(Icons.add),
                ),
              ),
        floatingActionButtonLocation:
            insideShell ? null : FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: insideShell
            ? null
            : BottomAppBar(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12.0, vertical: 8.0),
                  child: Row(
                    children: [
                      NavItem(
                        icon: Icons.home_outlined,
                        label: 'Home',
                        selected: widget.currentIndex == 0,
                        onTap: () => widget.onNavTap?.call(0),
                      ),
                      NavItem(
                        icon: Icons.local_shipping_outlined,
                        label: 'Request Shipping',
                        selected: widget.currentIndex == 1,
                        onTap: () => widget.onNavTap?.call(1),
                      ),
                      Spacer(),
                      NavItem(
                        icon: Icons.list_alt_outlined,
                        label: 'My Shipments',
                        selected: widget.currentIndex == 2,
                        onTap: () => widget.onNavTap?.call(2),
                      ),
                      NavItem(
                        icon: Icons.card_giftcard_outlined,
                        label: 'Affiliate',
                        selected: widget.currentIndex == 3,
                        onTap: () => widget.onNavTap?.call(3),
                      ),
                      NavItem(
                        icon: Icons.person_outline,
                        label: 'Profile',
                        selected: widget.currentIndex == 4,
                        onTap: () => widget.onNavTap?.call(4),
                      ),
                    ],
                  ),
                ),
              ),
      ), // Close PopScope
    );
  }
}

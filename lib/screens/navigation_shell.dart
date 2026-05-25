import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopsnports/screens/home_screen.dart';
import 'package:shopsnports/screens/shipments/shipments_list_screen.dart';
import 'package:shopsnports/screens/affiliate/affiliate_dashboard_screen.dart';
import 'package:shopsnports/screens/notifications_screen.dart';
import 'package:shopsnports/screens/profile/profile_screen.dart';
import 'package:shopsnports/providers/user_providers.dart';
import 'package:shopsnports/core/theme/app_colors.dart';
import 'package:shopsnports/core/routing/app_routes.dart';

/// NavigationShell manages 5-tab bottom navigation with proper screen switching
/// Tabs:
///   0: Home (Dashboard)
///   1: Shipments (Track & Manage shipments)
///   2: Affiliate (Earnings & Dashboard - conditional if user is affiliate)
///   3: Notifications (Alerts & Updates)
///   4: Profile (Account & Settings)
class NavigationShell extends ConsumerStatefulWidget {
  final int initialIndex;

  const NavigationShell({
    super.key,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends ConsumerState<NavigationShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Widget _getBody() {
    switch (_currentIndex) {
      case 0:
        return const HomeScreen();
      case 1:
        return const ShipmentsListScreen();
      case 2:
        return const AffiliateDashboardScreen();
      case 3:
        return const NotificationsScreen();
      case 4:
        return const ProfileScreen();
      default:
        return const HomeScreen();
    }
  }

  IconData _getTabIcon(int index, bool isActive) {
    switch (index) {
      case 0:
        return isActive ? Icons.home : Icons.home_outlined;
      case 1:
        return isActive ? Icons.local_shipping : Icons.local_shipping_outlined;
      case 2:
        return isActive ? Icons.trending_up : Icons.trending_up_outlined;
      case 3:
        return isActive ? Icons.notifications : Icons.notifications_outlined;
      case 4:
        return isActive ? Icons.person : Icons.person_outlined;
      default:
        return Icons.help;
    }
  }

  String _getTabLabel(int index) {
    switch (index) {
      case 0:
        return 'Home';
      case 1:
        return 'Shipments';
      case 2:
        return 'Affiliate';
      case 3:
        return 'Alerts';
      case 4:
        return 'Profile';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isAffiliate = user?.affiliateApproved == true;
    final theme = Theme.of(context);

    // Dynamically build tab list (exclude Affiliate if not enrolled)
    List<int> visibleTabs = [0, 1, if (isAffiliate) 2, 3, 4];

    // Adjust current index if affiliate tab is no longer visible
    int displayIndex = _currentIndex;
    if (!visibleTabs.contains(_currentIndex)) {
      displayIndex = 0;
      _currentIndex = 0;
    }

    return Scaffold(
      // appBar intentionally removed - child screens supply their own via
      // MainScaffold.  NavigationShell handles only the body and persistent
      // bottom navigation.
      body: _getBody(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: visibleTabs.indexOf(displayIndex),
        onTap: (index) {
          _onNavTap(visibleTabs[index]);
        },
        backgroundColor: theme.scaffoldBackgroundColor,
        selectedItemColor: theme.primaryColor,
        unselectedItemColor: Colors.grey[500],
        selectedLabelStyle:
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        elevation: 8,
        items: visibleTabs
            .map(
              (tabIndex) => BottomNavigationBarItem(
                icon: Icon(_getTabIcon(tabIndex, false)),
                activeIcon: Icon(_getTabIcon(tabIndex, true)),
                label: _getTabLabel(tabIndex),
              ),
            )
            .toList(),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accentYellow,
        onPressed: () {
          Navigator.of(context).pushNamed(AppRoutes.requestShipping);
        },
        tooltip: 'Request Shipping',
        child: const Icon(Icons.local_shipping),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

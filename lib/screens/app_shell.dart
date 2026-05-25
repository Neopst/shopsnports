import 'package:flutter/material.dart';
import 'package:shopsnports/widgets/main_scaffold.dart';
import 'package:shopsnports/screens/home_screen.dart';
import 'package:shopsnports/screens/request_shipping_screen.dart';
import 'package:shopsnports/screens/profile/profile_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  Widget _bodyForIndex(int idx) {
    switch (idx) {
      case 0:
        return const HomeScreen();
      case 1:
        return const RequestShippingScreen(useMainScaffold: false);
      case 2:
        return const ProfileScreen();
      default:
        return const HomeScreen();
    }
  }

  void _onNavTap(int idx) {
    if (idx == _currentIndex) return;
    setState(() => _currentIndex = idx);
  }

  @override
  Widget build(BuildContext context) {
    final screen = _bodyForIndex(_currentIndex);

    // If the screen already returns a full scaffold when used standalone,
    // return it directly so we don't nest two scaffolds and produce
    // duplicated app bars / bottom navigation (as seen in the screenshot).
    //
    // A widget instance like `HomeScreen()` or `CartScreen()` won't be an
    // instance of `MainScaffold` itself, so check the common screen types
    // that intentionally provide their own `MainScaffold` and return them
    // as-is. This is a conservative fix until screens are refactored to
    // expose content-only variants.
    // If the screen widget itself returns a full `MainScaffold` when used
    // standalone, return it directly instead of wrapping in another
    // `MainScaffold` here. This prevents nested scaffolds (two app bars / two
    // bottom navs) when `AppShell` is used as a host for those screens.
    if (screen is HomeScreen ||
        screen is RequestShippingScreen ||
        screen is ProfileScreen) {
      return screen;
    }

    return MainScaffold(
      currentIndex: _currentIndex,
      onNavTap: _onNavTap,
      body: screen,
      // allow per-screen overrides to hide the ticker if they want
      showNewsTicker: true,
    );
  }
}

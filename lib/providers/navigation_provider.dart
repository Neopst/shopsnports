import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopsnports/utils/app_logger.dart';

/// Navigation state provider for bottom navigation persistence
///
/// Persists the selected bottom navigation tab index across app restarts
/// and provides navigation history tracking for analytics.
class NavigationState {
  final int currentIndex;
  final List<int> history;
  final DateTime lastNavigationTime;

  const NavigationState({
    this.currentIndex = 0,
    this.history = const [],
    required this.lastNavigationTime,
  });

  NavigationState copyWith({
    int? currentIndex,
    List<int>? history,
    DateTime? lastNavigationTime,
  }) {
    return NavigationState(
      currentIndex: currentIndex ?? this.currentIndex,
      history: history ?? this.history,
      lastNavigationTime: lastNavigationTime ?? this.lastNavigationTime,
    );
  }
}

/// Notifier for managing navigation state with persistence
class NavigationNotifier extends StateNotifier<NavigationState> {
  static const String _prefsKey = 'bottom_nav_index';
  static const String _historyKey = 'nav_history';
  static const int _maxHistoryLength = 20;

  NavigationNotifier()
      : super(NavigationState(lastNavigationTime: DateTime.now())) {
    _loadPersistedState();
  }

  /// Load the persisted navigation state from SharedPreferences
  Future<void> _loadPersistedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedIndex = prefs.getInt(_prefsKey) ?? 0;
      final historyJson = prefs.getStringList(_historyKey) ?? [];
      final history = historyJson.map((e) => int.tryParse(e) ?? 0).toList();

      // Only restore if the index is valid (0-4 for our 5 tabs)
      if (savedIndex >= 0 && savedIndex <= 4) {
        state = NavigationState(
          currentIndex: savedIndex,
          history: history,
          lastNavigationTime: DateTime.now(),
        );
        AppLogger.debug(
            'Navigation state restored: index=$savedIndex, history=${history.length} items');
      } else {
        AppLogger.debug(
            'Invalid saved navigation index: $savedIndex, using default');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load navigation state', e, stackTrace);
    }
  }

  /// Navigate to a specific tab index
  Future<void> navigateTo(int index) async {
    if (index < 0 || index > 4) {
      AppLogger.error('Invalid navigation index: $index');
      return;
    }

    final now = DateTime.now();
    final newHistory = [...state.history, state.currentIndex];

    // Keep history limited to prevent unbounded growth
    if (newHistory.length > _maxHistoryLength) {
      newHistory.removeAt(0);
    }

    state = NavigationState(
      currentIndex: index,
      history: newHistory,
      lastNavigationTime: now,
    );

    AppLogger.navigation('Bottom nav: $index (${_getTabName(index)})', {
      'from': state.history.isNotEmpty ? state.history.last : null,
      'to': index,
      'timestamp': now.toIso8601String(),
    });

    await _persistState();
  }

  /// Persist current navigation state to SharedPreferences
  Future<void> _persistState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefsKey, state.currentIndex);
      await prefs.setStringList(
        _historyKey,
        state.history.map((e) => e.toString()).toList(),
      );
      AppLogger.debug(
          'Navigation state persisted: index=${state.currentIndex}');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to persist navigation state', e, stackTrace);
    }
  }

  /// Clear navigation history
  Future<void> clearHistory() async {
    state = state.copyWith(history: []);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
      AppLogger.debug('Navigation history cleared');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to clear navigation history', e, stackTrace);
    }
  }

  /// Reset navigation to home (index 0)
  Future<void> resetToHome() async {
    await navigateTo(0);
    await clearHistory();
    AppLogger.debug('Navigation reset to home');
  }

  /// Get tab name for logging
  String _getTabName(int index) {
    switch (index) {
      case 0:
        return 'Home';
      case 1:
        return 'Categories';
      case 2:
        return 'Request Shipping';
      case 3:
        return 'Cart';
      case 4:
        return 'Profile';
      default:
        return 'Unknown';
    }
  }

  /// Get navigation analytics
  Map<String, dynamic> getAnalytics() {
    final tabCounts = <int, int>{};
    for (final index in state.history) {
      tabCounts[index] = (tabCounts[index] ?? 0) + 1;
    }

    return {
      'current_tab': _getTabName(state.currentIndex),
      'current_index': state.currentIndex,
      'history_length': state.history.length,
      'tab_usage': tabCounts.map((k, v) => MapEntry(_getTabName(k), v)),
      'last_navigation': state.lastNavigationTime.toIso8601String(),
    };
  }
}

/// Provider for navigation state
final navigationProvider =
    StateNotifierProvider<NavigationNotifier, NavigationState>(
  (ref) => NavigationNotifier(),
);

/// Convenience provider for current navigation index
final currentNavIndexProvider = Provider<int>((ref) {
  return ref.watch(navigationProvider).currentIndex;
});

import 'package:flutter/material.dart';

// Legacy ChangeNotifier-based app state kept for older widgets.
// Renamed to LegacyAppState to avoid a type collision with the
// Riverpod-based `AppState` defined in `lib/providers/app_state_provider.dart`.
class LegacyAppState extends ChangeNotifier {
  // Notification count
  int notificationCount = 0;

  // Currency
  String baseCurrency = 'NGN';
  String displayCurrency = 'NGN';
  double fxRate = 1.0; // NGN → NGN

  // Notifications demo
  void incrementNotifications() {
    notificationCount++;
    notifyListeners();
  }

  // Currency switch (rate will be fetched externally)
  Future<void> setCurrency(String currencyCode,
      Future<double> Function(String from, String to) fetchRate) async {
    displayCurrency = currencyCode.toUpperCase();
    final rate = await fetchRate(baseCurrency, displayCurrency);
    fxRate = rate;
    notifyListeners();
  }

  // Price conversion helper
  double convert(double amountInBase) => amountInBase * fxRate;
}

// Note: this file defines a legacy ChangeNotifier-based app state used by
// older code. The project also contains a newer Riverpod StateNotifier
// provider at `lib/providers/app_state_provider.dart`. Migrate usages to the
// StateNotifier-based provider when possible.

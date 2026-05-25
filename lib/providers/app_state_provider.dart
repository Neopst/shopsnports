import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ShippingStatus { none, pending, shipped }

enum NotificationStatus { none, info, urgent }

class AppState {
  final int pendingShippingCount;
  final ShippingStatus shippingStatus;

  final int notificationCount;
  final NotificationStatus notificationStatus;

  // currency info
  final String currencyCode;
  final double exchangeRate;

  final List<String> newsItems;

  const AppState({
    this.pendingShippingCount = 0,
    this.shippingStatus = ShippingStatus.none,
    this.notificationCount = 0,
    this.notificationStatus = NotificationStatus.none,
    this.currencyCode = 'NGN',
    this.exchangeRate = 1.0,
    this.newsItems = const [],
  });

  AppState copyWith({
    int? pendingShippingCount,
    ShippingStatus? shippingStatus,
    int? notificationCount,
    NotificationStatus? notificationStatus,
    String? currencyCode,
    double? exchangeRate,
    List<String>? newsItems,
  }) {
    return AppState(
      pendingShippingCount: pendingShippingCount ?? this.pendingShippingCount,
      shippingStatus: shippingStatus ?? this.shippingStatus,
      notificationCount: notificationCount ?? this.notificationCount,
      notificationStatus: notificationStatus ?? this.notificationStatus,
      currencyCode: currencyCode ?? this.currencyCode,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      newsItems: newsItems ?? this.newsItems,
    );
  }
}

class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier() : super(const AppState());

  // set currency + exchange rate
  void setCurrency(String code, double rate) {
    state = state.copyWith(currencyCode: code, exchangeRate: rate);
  }

  // Shipping
  void addPendingShipping() => state = state.copyWith(
        pendingShippingCount: state.pendingShippingCount + 1,
        shippingStatus: ShippingStatus.pending,
      );
  void markShipped() =>
      state = state.copyWith(shippingStatus: ShippingStatus.shipped);
  void clearPendingShipping() => state = state.copyWith(
      pendingShippingCount: 0, shippingStatus: ShippingStatus.none);

  // Notifications
  void addNotification({bool urgent = false}) => state = state.copyWith(
        notificationCount: state.notificationCount + 1,
        notificationStatus:
            urgent ? NotificationStatus.urgent : NotificationStatus.info,
      );
  void clearNotifications() => state = state.copyWith(
      notificationCount: 0, notificationStatus: NotificationStatus.none);

  // News ticker
  void setNewsItems(List<String> items) =>
      state = state.copyWith(newsItems: List.unmodifiable(items));
}

final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>(
    (ref) => AppStateNotifier());

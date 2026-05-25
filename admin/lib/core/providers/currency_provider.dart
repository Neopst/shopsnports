import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/currency.dart';
import '../services/currency_service.dart';

// Dio provider for currency service
final currencyDioProvider = Provider<Dio>((ref) => Dio());

// Currency service provider
final currencyServiceProvider = Provider<CurrencyService>((ref) {
  final dio = ref.watch(currencyDioProvider);
  final service = CurrencyService(dio);

  // Initialize exchange rates on startup
  service.fetchExchangeRates();

  return service;
});

// Selected currency provider (NGN as default) - using modern Riverpod approach
class SelectedCurrencyNotifier extends Notifier<Currency> {
  @override
  Currency build() {
    _loadSavedCurrency();
    return Currency.ngn;
  }

  Future<void> _loadSavedCurrency() async {
    final service = ref.read(currencyServiceProvider);
    final savedCurrency = await service.loadSelectedCurrency();
    state = savedCurrency;
  }

  Future<void> setCurrency(Currency currency) async {
    state = currency;
    final service = ref.read(currencyServiceProvider);
    await service.saveSelectedCurrency(currency.code);

    // Refresh exchange rates when currency changes
    await service.fetchExchangeRates();
  }

  Future<void> refreshRates() async {
    final service = ref.read(currencyServiceProvider);
    await service.fetchExchangeRates();
  }
}

final selectedCurrencyProvider =
    NotifierProvider<SelectedCurrencyNotifier, Currency>(
      SelectedCurrencyNotifier.new,
    );

// Exchange rate provider for a specific currency
final exchangeRateProvider = Provider.family<double, String>((
  ref,
  currencyCode,
) {
  final service = ref.watch(currencyServiceProvider);
  return service.getRate(currencyCode);
});

// Last update time provider
final ratesLastUpdateProvider = Provider<String>((ref) {
  final service = ref.watch(currencyServiceProvider);
  return service.getLastUpdateTime();
});

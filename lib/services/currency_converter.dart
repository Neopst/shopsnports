import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Currency data model
class Currency {
  final String code;
  final String name;
  final String symbol;
  final String flag;

  const Currency({
    required this.code,
    required this.name,
    required this.symbol,
    required this.flag,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Currency && code == code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => '$flag $code ($name)';
}

/// Supported currencies with flags
class SupportedCurrencies {
  static const List<Currency> all = [
    Currency(code: 'NGN', name: 'Nigerian Naira', symbol: '₦', flag: '🇳🇬'),
    Currency(code: 'USD', name: 'US Dollar', symbol: '\$', flag: '🇺🇸'),
    Currency(code: 'EUR', name: 'Euro', symbol: '€', flag: '🇪🇺'),
    Currency(code: 'GBP', name: 'British Pound', symbol: '£', flag: '🇬🇧'),
    Currency(code: 'CNY', name: 'Chinese Yuan', symbol: '¥', flag: '🇨🇳'),
    Currency(code: 'JPY', name: 'Japanese Yen', symbol: '¥', flag: '🇯🇵'),
    Currency(code: 'GHS', name: 'Ghanaian Cedi', symbol: '₵', flag: '🇬🇭'),
    Currency(code: 'ZAR', name: 'South African Rand', symbol: 'R', flag: '🇿🇦'),
    Currency(code: 'KES', name: 'Kenyan Shilling', symbol: 'KSh', flag: '🇰🇪'),
    Currency(code: 'CAD', name: 'Canadian Dollar', symbol: 'C\$', flag: '🇨🇦'),
    Currency(code: 'AUD', name: 'Australian Dollar', symbol: 'A\$', flag: '🇦🇺'),
    Currency(code: 'INR', name: 'Indian Rupee', symbol: '₹', flag: '🇮🇳'),
    Currency(code: 'BRL', name: 'Brazilian Real', symbol: 'R\$', flag: '🇧🇷'),
    Currency(code: 'AED', name: 'UAE Dirham', symbol: 'د.إ', flag: '🇦🇪'),
    Currency(code: 'SGD', name: 'Singapore Dollar', symbol: 'S\$', flag: '🇸🇬'),
  ];

  static Currency byCode(String code) {
    return all.firstWhere(
      (c) => c.code == code,
      orElse: () => all.firstWhere((c) => c.code == 'NGN'),
    );
  }

  static List<Currency> get popular => [
        all.firstWhere((c) => c.code == 'NGN'),
        all.firstWhere((c) => c.code == 'USD'),
        all.firstWhere((c) => c.code == 'EUR'),
        all.firstWhere((c) => c.code == 'GBP'),
        all.firstWhere((c) => c.code == 'CNY'),
      ];
}

/// Currency converter service with live exchange rates
class CurrencyConverter {
  static const String _baseUrl = 'https://api.exchangerate-api.com/v4/latest';
  static const String _prefsRatesKey = 'cached_exchange_rates';
  static const String _prefsTimestampKey = 'rates_timestamp';
  static const Duration _cacheDuration = Duration(hours: 6);

  static CurrencyConverter? _instance;
  static final Map<String, double> _rates = {};
  static String _baseCurrency = 'NGN';
  static DateTime? _lastUpdated;

  factory CurrencyConverter() {
    _instance ??= CurrencyConverter._();
    return _instance!;
  }

  CurrencyConverter._();

  /// Get singleton instance
  static CurrencyConverter get instance {
    _instance ??= CurrencyConverter._();
    return _instance!;
  }

  /// Current base currency
  String get baseCurrency => _baseCurrency;

  /// Last update time
  DateTime? get lastUpdated => _lastUpdated;

  /// Get all supported currencies
  List<Currency> get supportedCurrencies => SupportedCurrencies.all;

  /// Get exchange rates
  Map<String, double> get rates => Map.unmodifiable(_rates);

  /// Initialize and fetch rates
  Future<void> initialize({String base = 'NGN'}) async {
    _baseCurrency = base;

    // Try to load cached rates first
    await _loadCachedRates();

    // Then fetch fresh rates
    try {
      await fetchRates();
    } catch (e) {
      // Use cached rates on failure
    }
  }

  /// Fetch live exchange rates from API
  Future<Map<String, double>> fetchRates({String? base}) async {
    final currency = base ?? _baseCurrency;
    final url = Uri.parse('$_baseUrl/$currency');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final ratesData = data['rates'] as Map<String, dynamic>;

        _rates.clear();
        for (var entry in ratesData.entries) {
          _rates[entry.key] = entry.value.toDouble();
        }

        _baseCurrency = currency;
        _lastUpdated = DateTime.now();

        // Cache the rates
        await _cacheRates();

        return _rates;
      } else {
        throw Exception('Failed to fetch rates: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Convert amount from one currency to another
  double convert({
    required double amount,
    required String from,
    required String to,
  }) {
    if (from == to) return amount;

    // Get rates with base currency
    final rates = _rates;

    // If from is base currency, just multiply by to rate
    if (from == _baseCurrency) {
      final toRate = rates[to];
      if (toRate == null) return amount;
      return amount * toRate;
    }

    // If to is base currency, divide by from rate
    if (to == _baseCurrency) {
      final fromRate = rates[from];
      if (fromRate == null || fromRate == 0) return amount;
      return amount / fromRate;
    }

    // Both are not base currency, convert via base
    final fromRate = rates[from];
    final toRate = rates[to];

    if (fromRate == null || toRate == null || fromRate == 0) return amount;

    // Convert to base, then to target
    final amountInBase = amount / fromRate;
    return amountInBase * toRate;
  }

  /// Format amount with currency symbol
  String format({
    required double amount,
    required String currencyCode,
    int decimalDigits = 2,
  }) {
    final currency = SupportedCurrencies.byCode(currencyCode);
    final converted = convert(
      amount: amount,
      from: 'NGN', // Store everything in NGN, convert for display
      to: currencyCode,
    );

    final formatted = converted.toStringAsFixed(decimalDigits);
    return '${currency.symbol} $formatted';
  }

  /// Format amount with currency code and symbol
  String formatFull({
    required double amount,
    required String currencyCode,
    int decimalDigits = 2,
  }) {
    final currency = SupportedCurrencies.byCode(currencyCode);
    final converted = convert(
      amount: amount,
      from: 'NGN',
      to: currencyCode,
    );

    final formatted = converted.toStringAsFixed(decimalDigits);
    return '${currency.flag} ${currency.symbol}$formatted ${currency.code}';
  }

  /// Get exchange rate between two currencies
  double? getRate(String currency) {
    return _rates[currency];
  }

  /// Save rates to local storage
  Future<void> _cacheRates() async {
    final prefs = await SharedPreferences.getInstance();
    final ratesJson = json.encode(_rates);
    await prefs.setString(_prefsRatesKey, ratesJson);
    await prefs.setString(_prefsTimestampKey, _lastUpdated!.toIso8601String());
  }

  /// Load cached rates from local storage
  Future<void> _loadCachedRates() async {
    final prefs = await SharedPreferences.getInstance();
    final ratesJson = prefs.getString(_prefsRatesKey);
    final timestampStr = prefs.getString(_prefsTimestampKey);

    if (ratesJson != null && timestampStr != null) {
      try {
        final timestamp = DateTime.parse(timestampStr);
        if (DateTime.now().difference(timestamp) < _cacheDuration) {
          final ratesData = json.decode(ratesJson) as Map<String, dynamic>;
          _rates.clear();
          for (var entry in ratesData.entries) {
            _rates[entry.key] = (entry.value as num).toDouble();
          }
          _lastUpdated = timestamp;
          return;
        }
      } catch (e) {
        // Fall through to default rates
      }
    }

    // Initialize with fallback rates if no cache
    _rates.clear();
    _rates['NGN'] = 1.0;
    _rates['USD'] = 1500.0;
    _rates['EUR'] = 1625.0;
    _rates['GBP'] = 1900.0;
    _rates['CNY'] = 207.0;
    _rates['JPY'] = 10.0;
    _rates['GHS'] = 100.0;
    _rates['ZAR'] = 80.0;
    _rates['KES'] = 10.0;
    _rates['CAD'] = 1110.0;
    _rates['AUD'] = 975.0;
    _rates['INR'] = 18.0;
    _rates['BRL'] = 300.0;
    _rates['AED'] = 408.0;
    _rates['SGD'] = 1120.0;
  }

  /// Force refresh rates
  Future<void> refreshRates() async {
    await fetchRates();
  }

  /// Get rate as percentage display
  String getRateDisplay(String currency) {
    if (currency == _baseCurrency) return '1.00';
    final rate = _rates[currency];
    if (rate == null) return 'N/A';
    return rate.toStringAsFixed(4);
  }
}

/// Extension for easy formatting
extension CurrencyFormatting on double {
  String toCurrency({
    required String currencyCode,
    int decimalDigits = 2,
  }) {
    return CurrencyConverter().format(
      amount: this,
      currencyCode: currencyCode,
      decimalDigits: decimalDigits,
    );
  }

  String toCurrencyFull({
    required String currencyCode,
    int decimalDigits = 2,
  }) {
    return CurrencyConverter().formatFull(
      amount: this,
      currencyCode: currencyCode,
      decimalDigits: decimalDigits,
    );
  }
}
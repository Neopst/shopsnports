import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/currency.dart';
import '../utils/app_logger.dart';

class CurrencyService {
  static const String _storageKey = 'selected_currency';
  static const String _ratesKey = 'exchange_rates';
  static const String _ratesTimestampKey = 'rates_timestamp';

  // Free API for exchange rates (no API key needed for basic usage)
  static const String _apiUrl =
      'https://api.exchangerate-api.com/v4/latest/NGN';

  final Dio _dio;
  Map<String, double> _exchangeRates = {};
  DateTime? _lastFetchTime;

  CurrencyService(this._dio) {
    // Initialize with default rates immediately
    _setDefaultRates();
  }

  // Fetch latest exchange rates from API
  Future<void> fetchExchangeRates() async {
    try {
      // Check if we have cached rates less than 1 hour old
      if (_lastFetchTime != null &&
          DateTime.now().difference(_lastFetchTime!) <
              const Duration(hours: 1)) {
        return; // Use cached rates
      }

      final response = await _dio.get(_apiUrl);
      if (response.statusCode == 200) {
        final data = response.data;
        final rates = data['rates'] as Map<String, dynamic>;

        _exchangeRates = {
          'NGN': 1.0, // Base currency
          ...rates.map(
            (key, value) => MapEntry(key, (value as num).toDouble()),
          ),
        };

        _lastFetchTime = DateTime.now();

        // Cache rates to local storage
        await _saveRatesToCache();
      }
    } catch (e) {
      // Fallback to cached rates or default rates
      await _loadRatesFromCache();
      AppLogger.error('Error fetching exchange rates: $e');
    }
  }

  Future<void> _saveRatesToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_ratesKey, jsonEncode(_exchangeRates));
      await prefs.setString(
        _ratesTimestampKey,
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      AppLogger.error('Error saving rates to cache: $e');
    }
  }

  Future<void> _loadRatesFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ratesJson = prefs.getString(_ratesKey);
      final timestamp = prefs.getString(_ratesTimestampKey);

      if (ratesJson != null) {
        final decoded = jsonDecode(ratesJson) as Map<String, dynamic>;
        _exchangeRates = decoded.map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        );

        if (timestamp != null) {
          _lastFetchTime = DateTime.parse(timestamp);
        }
      }
    } catch (e) {
      AppLogger.error('Error loading rates from cache: $e');
      _setDefaultRates();
    }
  }

  void _setDefaultRates() {
    // Fallback exchange rates (approximate, as of Dec 2024)
    _exchangeRates = {
      'NGN': 1.0,
      'USD': 0.00063, // 1 NGN ≈ 0.00063 USD (1 USD ≈ 1580 NGN)
      'GBP': 0.00050, // 1 NGN ≈ 0.0005 GBP
      'EUR': 0.00058, // 1 NGN ≈ 0.00058 EUR
      'CAD': 0.00088, // 1 NGN ≈ 0.00088 CAD
      'AUD': 0.00097, // 1 NGN ≈ 0.00097 AUD
      'JPY': 0.092, // 1 NGN ≈ 0.092 JPY
      'CNY': 0.0045, // 1 NGN ≈ 0.0045 CNY
      'INR': 0.053, // 1 NGN ≈ 0.053 INR
      'ZAR': 0.011, // 1 NGN ≈ 0.011 ZAR
      'GHS': 0.0095, // 1 NGN ≈ 0.0095 GHS
      'KES': 0.081, // 1 NGN ≈ 0.081 KES
    };
  }

  // Convert amount from NGN (base currency) to target currency
  double convert(double amountInNGN, String targetCurrencyCode) {
    final rate = _exchangeRates[targetCurrencyCode] ?? 1.0;
    return amountInNGN * rate;
  }

  // Convert amount from any currency back to NGN
  double convertToBase(double amount, String fromCurrencyCode) {
    final rate = _exchangeRates[fromCurrencyCode] ?? 1.0;
    if (rate == 0) return amount;
    return amount / rate;
  }

  // Get exchange rate for a currency
  double getRate(String currencyCode) {
    return _exchangeRates[currencyCode] ?? 1.0;
  }

  // Save selected currency to local storage
  Future<void> saveSelectedCurrency(String currencyCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, currencyCode);
  }

  // Load selected currency from local storage
  Future<Currency> loadSelectedCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_storageKey) ?? 'NGN';
    return Currency.fromCode(code);
  }

  // Get last update time for exchange rates
  String getLastUpdateTime() {
    if (_lastFetchTime == null) return 'Never';
    final diff = DateTime.now().difference(_lastFetchTime!);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }
}

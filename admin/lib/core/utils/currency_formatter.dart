import 'package:intl/intl.dart';
import '../models/currency.dart';
import '../services/currency_service.dart';

class CurrencyFormatter {
  final CurrencyService _currencyService;
  final Currency _selectedCurrency;

  CurrencyFormatter(this._currencyService, this._selectedCurrency);

  // Format amount (assumed to be in NGN base currency) to selected currency
  String format(
    dynamic amount, {
    int decimalDigits = 2,
    bool showSymbol = true,
  }) {
    final amountValue = _parseAmount(amount);
    final convertedAmount = _currencyService.convert(
      amountValue,
      _selectedCurrency.code,
    );

    if (showSymbol) {
      final formatter = NumberFormat.currency(
        symbol: _selectedCurrency.symbol,
        decimalDigits: decimalDigits,
      );
      return formatter.format(convertedAmount);
    } else {
      final formatter = NumberFormat.currency(
        symbol: '',
        decimalDigits: decimalDigits,
      );
      return formatter.format(convertedAmount).trim();
    }
  }

  // Format without conversion (amount is already in target currency)
  String formatRaw(
    dynamic amount, {
    int decimalDigits = 2,
    bool showSymbol = true,
  }) {
    final amountValue = _parseAmount(amount);

    if (showSymbol) {
      final formatter = NumberFormat.currency(
        symbol: _selectedCurrency.symbol,
        decimalDigits: decimalDigits,
      );
      return formatter.format(amountValue);
    } else {
      final formatter = NumberFormat.currency(
        symbol: '',
        decimalDigits: decimalDigits,
      );
      return formatter.format(amountValue).trim();
    }
  }

  // Format compact (e.g., ₦1.2M, $50K)
  String formatCompact(dynamic amount, {bool showSymbol = true}) {
    final amountValue = _parseAmount(amount);
    final convertedAmount = _currencyService.convert(
      amountValue,
      _selectedCurrency.code,
    );

    final formatter = NumberFormat.compact();
    final compactValue = formatter.format(convertedAmount);

    return showSymbol
        ? '${_selectedCurrency.symbol}$compactValue'
        : compactValue;
  }

  // Get symbol only
  String get symbol => _selectedCurrency.symbol;

  // Get currency code
  String get code => _selectedCurrency.code;

  // Get currency name
  String get name => _selectedCurrency.name;

  // Get currency flag
  String get flag => _selectedCurrency.flag;

  /// Format amount in a specific currency (useful for per-affiliate display)
  /// [amount] is assumed to be in NGN base currency
  /// [targetCurrency] is the affiliate's preferred currency (NGN or USD)
  String formatForAffiliate(
    dynamic amount, {
    required String targetCurrency,
    int decimalDigits = 2,
  }) {
    final amountValue = _parseAmount(amount);
    final target = Currency.fromCode(targetCurrency);

    // If target is NGN, no conversion needed
    if (targetCurrency == 'NGN') {
      final formatter = NumberFormat.currency(
        symbol: target.symbol,
        decimalDigits: decimalDigits,
      );
      return formatter.format(amountValue);
    }

    // Convert NGN to target currency
    final convertedAmount = _currencyService.convert(amountValue, targetCurrency);
    final formatter = NumberFormat.currency(
      symbol: target.symbol,
      decimalDigits: decimalDigits,
    );
    return formatter.format(convertedAmount);
  }

  /// Format amount in native currency stored in payout record
  /// No conversion - formats directly based on stored currency
  String formatNative(
    dynamic amount, {
    required String currencyCode,
    int decimalDigits = 2,
  }) {
    final amountValue = _parseAmount(amount);
    final currency = Currency.fromCode(currencyCode);

    final formatter = NumberFormat.currency(
      symbol: currency.symbol,
      decimalDigits: decimalDigits,
    );
    return formatter.format(amountValue);
  }

  double _parseAmount(dynamic amount) {
    if (amount is num) return amount.toDouble();
    if (amount is String) return double.tryParse(amount) ?? 0.0;
    return 0.0;
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for invoice currency support
class InvoiceCurrency {
  final String id;
  final String code;
  final String name;
  final String symbol;
  final String? symbolPosition; // 'before' or 'after'
  final int? decimalPlaces;
  final String? thousandsSeparator;
  final String? decimalSeparator;
  final String? locale;
  final double? exchangeRate;
  final String? baseCurrency;
  final DateTime? exchangeRateUpdatedAt;
  final bool isActive;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime? updatedAt;

  InvoiceCurrency({
    required this.id,
    required this.code,
    required this.name,
    required this.symbol,
    this.symbolPosition,
    this.decimalPlaces,
    this.thousandsSeparator,
    this.decimalSeparator,
    this.locale,
    this.exchangeRate,
    this.baseCurrency,
    this.exchangeRateUpdatedAt,
    this.isActive = true,
    this.isDefault = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory InvoiceCurrency.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InvoiceCurrency(
      id: doc.id,
      code: data['code'] ?? '',
      name: data['name'] ?? '',
      symbol: data['symbol'] ?? '',
      symbolPosition: data['symbolPosition'],
      decimalPlaces: data['decimalPlaces'],
      thousandsSeparator: data['thousandsSeparator'],
      decimalSeparator: data['decimalSeparator'],
      locale: data['locale'],
      exchangeRate: data['exchangeRate']?.toDouble(),
      baseCurrency: data['baseCurrency'],
      exchangeRateUpdatedAt: data['exchangeRateUpdatedAt'] != null
          ? (data['exchangeRateUpdatedAt'] as Timestamp).toDate()
          : null,
      isActive: data['isActive'] ?? true,
      isDefault: data['isDefault'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'code': code,
      'name': name,
      'symbol': symbol,
      'symbolPosition': symbolPosition,
      'decimalPlaces': decimalPlaces,
      'thousandsSeparator': thousandsSeparator,
      'decimalSeparator': decimalSeparator,
      'locale': locale,
      'exchangeRate': exchangeRate,
      'baseCurrency': baseCurrency,
      'exchangeRateUpdatedAt': exchangeRateUpdatedAt != null
          ? Timestamp.fromDate(exchangeRateUpdatedAt!)
          : null,
      'isActive': isActive,
      'isDefault': isDefault,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  String formatAmount(double amount) {
    final symbolPos = symbolPosition ?? 'before';
    final decimals = decimalPlaces ?? 2;
    final thousandsSep = thousandsSeparator ?? ',';
    final decimalSep = decimalSeparator ?? '.';

    String formatted = amount.toStringAsFixed(decimals);

    // Split into integer and decimal parts
    final parts = formatted.split('.');
    String integerPart = parts[0];
    String decimalPart = parts.length > 1 ? parts[1] : '';

    // Add thousands separator
    if (integerPart.length > 3) {
      final buffer = StringBuffer();
      for (int i = integerPart.length - 1; i >= 0; i--) {
        if ((integerPart.length - 1 - i) % 3 == 0 && i != integerPart.length - 1) {
          buffer.write(thousandsSep);
        }
        buffer.write(integerPart[i]);
      }
      integerPart = buffer.toString().split('').reversed.join('');
    }

    // Combine parts
    formatted = decimalPart.isNotEmpty
        ? '$integerPart$decimalSep$decimalPart'
        : integerPart;

    // Add symbol
    if (symbolPos == 'before') {
      return '$symbol$formatted';
    } else {
      return '$formatted$symbol';
    }
  }

  double convertToBase(double amount) {
    if (exchangeRate == null || baseCurrency == null) return amount;
    return amount * exchangeRate!;
  }

  double convertFromBase(double amount) {
    if (exchangeRate == null || baseCurrency == null || exchangeRate == 0) return amount;
    return amount / exchangeRate!;
  }

  InvoiceCurrency copyWith({
    String? id,
    String? code,
    String? name,
    String? symbol,
    String? symbolPosition,
    int? decimalPlaces,
    String? thousandsSeparator,
    String? decimalSeparator,
    String? locale,
    double? exchangeRate,
    String? baseCurrency,
    DateTime? exchangeRateUpdatedAt,
    bool? isActive,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InvoiceCurrency(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      symbol: symbol ?? this.symbol,
      symbolPosition: symbolPosition ?? this.symbolPosition,
      decimalPlaces: decimalPlaces ?? this.decimalPlaces,
      thousandsSeparator: thousandsSeparator ?? this.thousandsSeparator,
      decimalSeparator: decimalSeparator ?? this.decimalSeparator,
      locale: locale ?? this.locale,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      baseCurrency: baseCurrency ?? this.baseCurrency,
      exchangeRateUpdatedAt:
          exchangeRateUpdatedAt ?? this.exchangeRateUpdatedAt,
      isActive: isActive ?? this.isActive,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Common currencies
class CommonCurrencies {
  static List<InvoiceCurrency> get all => [
    InvoiceCurrency(
      id: 'usd',
      code: 'USD',
      name: 'US Dollar',
      symbol: '\$',
      symbolPosition: 'before',
      decimalPlaces: 2,
      thousandsSeparator: ',',
      decimalSeparator: '.',
      locale: 'en_US',
      isActive: true,
      isDefault: true,
      createdAt: DateTime.now(),
    ),
    InvoiceCurrency(
      id: 'eur',
      code: 'EUR',
      name: 'Euro',
      symbol: '€',
      symbolPosition: 'after',
      decimalPlaces: 2,
      thousandsSeparator: '.',
      decimalSeparator: ',',
      locale: 'de_DE',
      isActive: true,
      isDefault: false,
      createdAt: DateTime.now(),
    ),
    InvoiceCurrency(
      id: 'gbp',
      code: 'GBP',
      name: 'British Pound',
      symbol: '£',
      symbolPosition: 'before',
      decimalPlaces: 2,
      thousandsSeparator: ',',
      decimalSeparator: '.',
      locale: 'en_GB',
      isActive: true,
      isDefault: false,
      createdAt: DateTime.now(),
    ),
    InvoiceCurrency(
      id: 'jpy',
      code: 'JPY',
      name: 'Japanese Yen',
      symbol: '¥',
      symbolPosition: 'before',
      decimalPlaces: 0,
      thousandsSeparator: ',',
      decimalSeparator: '.',
      locale: 'ja_JP',
      isActive: true,
      isDefault: false,
      createdAt: DateTime.now(),
    ),
    InvoiceCurrency(
      id: 'cny',
      code: 'CNY',
      name: 'Chinese Yuan',
      symbol: '¥',
      symbolPosition: 'before',
      decimalPlaces: 2,
      thousandsSeparator: ',',
      decimalSeparator: '.',
      locale: 'zh_CN',
      isActive: true,
      isDefault: false,
      createdAt: DateTime.now(),
    ),
    InvoiceCurrency(
      id: 'inr',
      code: 'INR',
      name: 'Indian Rupee',
      symbol: '₹',
      symbolPosition: 'before',
      decimalPlaces: 2,
      thousandsSeparator: ',',
      decimalSeparator: '.',
      locale: 'en_IN',
      isActive: true,
      isDefault: false,
      createdAt: DateTime.now(),
    ),
    InvoiceCurrency(
      id: 'aud',
      code: 'AUD',
      name: 'Australian Dollar',
      symbol: 'A\$',
      symbolPosition: 'before',
      decimalPlaces: 2,
      thousandsSeparator: ',',
      decimalSeparator: '.',
      locale: 'en_AU',
      isActive: true,
      isDefault: false,
      createdAt: DateTime.now(),
    ),
    InvoiceCurrency(
      id: 'cad',
      code: 'CAD',
      name: 'Canadian Dollar',
      symbol: 'C\$',
      symbolPosition: 'before',
      decimalPlaces: 2,
      thousandsSeparator: ',',
      decimalSeparator: '.',
      locale: 'en_CA',
      isActive: true,
      isDefault: false,
      createdAt: DateTime.now(),
    ),
  ];
}
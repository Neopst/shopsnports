class Currency {
  final String code;
  final String symbol;
  final String name;
  final String flag;

  const Currency({
    required this.code,
    required this.symbol,
    required this.name,
    required this.flag,
  });

  static const ngn = Currency(
    code: 'NGN',
    symbol: '₦',
    name: 'Nigerian Naira',
    flag: '🇳🇬',
  );

  static const usd = Currency(
    code: 'USD',
    symbol: '\$',
    name: 'US Dollar',
    flag: '🇺🇸',
  );

  static const gbp = Currency(
    code: 'GBP',
    symbol: '£',
    name: 'British Pound',
    flag: '🇬🇧',
  );

  static const eur = Currency(
    code: 'EUR',
    symbol: '€',
    name: 'Euro',
    flag: '🇪🇺',
  );

  static const cad = Currency(
    code: 'CAD',
    symbol: 'C\$',
    name: 'Canadian Dollar',
    flag: '🇨🇦',
  );

  static const aud = Currency(
    code: 'AUD',
    symbol: 'A\$',
    name: 'Australian Dollar',
    flag: '🇦🇺',
  );

  static const jpy = Currency(
    code: 'JPY',
    symbol: '¥',
    name: 'Japanese Yen',
    flag: '🇯🇵',
  );

  static const cny = Currency(
    code: 'CNY',
    symbol: '¥',
    name: 'Chinese Yuan',
    flag: '🇨🇳',
  );

  static const inr = Currency(
    code: 'INR',
    symbol: '₹',
    name: 'Indian Rupee',
    flag: '🇮🇳',
  );

  static const zar = Currency(
    code: 'ZAR',
    symbol: 'R',
    name: 'South African Rand',
    flag: '🇿🇦',
  );

  static const ghs = Currency(
    code: 'GHS',
    symbol: 'GH₵',
    name: 'Ghanaian Cedi',
    flag: '🇬🇭',
  );

  static const kes = Currency(
    code: 'KES',
    symbol: 'KSh',
    name: 'Kenyan Shilling',
    flag: '🇰🇪',
  );

  static const List<Currency> all = [
    ngn,
    usd,
    gbp,
    eur,
    cad,
    aud,
    jpy,
    cny,
    inr,
    zar,
    ghs,
    kes,
  ];

  static Currency fromCode(String code) {
    return all.firstWhere(
      (currency) => currency.code == code,
      orElse: () => ngn,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Currency &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;
}

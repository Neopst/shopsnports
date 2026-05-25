import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for invoice number customization
class InvoiceNumberCustomization {
  final String id;
  final String name;
  final String description;
  final String prefix;
  final String suffix;
  final int startNumber;
  final int currentNumber;
  final NumberFormat format;
  final int? paddingLength;
  final String? paddingCharacter;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  InvoiceNumberCustomization({
    required this.id,
    required this.name,
    required this.description,
    required this.prefix,
    required this.suffix,
    required this.startNumber,
    required this.currentNumber,
    required this.format,
    this.paddingLength,
    this.paddingCharacter,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory InvoiceNumberCustomization.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InvoiceNumberCustomization(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      prefix: data['prefix'] ?? '',
      suffix: data['suffix'] ?? '',
      startNumber: data['startNumber'] ?? 1,
      currentNumber: data['currentNumber'] ?? 1,
      format: NumberFormat.fromString(data['format'] ?? 'numeric'),
      paddingLength: data['paddingLength'],
      paddingCharacter: data['paddingCharacter'],
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'prefix': prefix,
      'suffix': suffix,
      'startNumber': startNumber,
      'currentNumber': currentNumber,
      'format': format.value,
      'paddingLength': paddingLength,
      'paddingCharacter': paddingCharacter,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  String generateNextNumber() {
    final nextNumber = currentNumber + 1;
    return formatNumber(nextNumber);
  }

  String formatNumber(int number) {
    String formattedNumber = '';

    switch (format) {
      case NumberFormat.numeric:
        formattedNumber = number.toString();
        break;
      case NumberFormat.alphanumeric:
        formattedNumber = _toAlphanumeric(number);
        break;
      case NumberFormat.roman:
        formattedNumber = _toRoman(number);
        break;
      case NumberFormat.custom:
        formattedNumber = number.toString();
        break;
    }

    // Apply padding if specified
    if (paddingLength != null && paddingLength! > formattedNumber.length) {
      final padChar = paddingCharacter ?? '0';
      formattedNumber = formattedNumber.padLeft(
        paddingLength!,
        padChar.isNotEmpty ? padChar[0] : '0',
      );
    }

    return '$prefix$formattedNumber$suffix';
  }

  String _toAlphanumeric(int number) {
    const chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    String result = '';
    while (number > 0) {
      result = chars[number % chars.length] + result;
      number = number ~/ chars.length;
    }
    return result.isEmpty ? '0' : result;
  }

  String _toRoman(int number) {
    if (number <= 0) return '';

    const values = [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1];
    const symbols = ['M', 'CM', 'D', 'CD', 'C', 'XC', 'L', 'XL', 'X', 'IX', 'V', 'IV', 'I'];

    String result = '';
    for (int i = 0; i < values.length; i++) {
      while (number >= values[i]) {
        result += symbols[i];
        number -= values[i];
      }
    }
    return result;
  }

  InvoiceNumberCustomization copyWith({
    String? id,
    String? name,
    String? description,
    String? prefix,
    String? suffix,
    int? startNumber,
    int? currentNumber,
    NumberFormat? format,
    int? paddingLength,
    String? paddingCharacter,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InvoiceNumberCustomization(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      prefix: prefix ?? this.prefix,
      suffix: suffix ?? this.suffix,
      startNumber: startNumber ?? this.startNumber,
      currentNumber: currentNumber ?? this.currentNumber,
      format: format ?? this.format,
      paddingLength: paddingLength ?? this.paddingLength,
      paddingCharacter: paddingCharacter ?? this.paddingCharacter,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum NumberFormat {
  numeric('numeric'),
  alphanumeric('alphanumeric'),
  roman('roman'),
  custom('custom');

  final String value;
  const NumberFormat(this.value);

  static NumberFormat fromString(String value) {
    return NumberFormat.values.firstWhere(
      (e) => e.value == value,
      orElse: () => NumberFormat.numeric,
    );
  }
}
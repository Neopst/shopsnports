import 'package:cloud_firestore/cloud_firestore.dart';

/// Tax Calculation Service
///
/// Calculates tax based on tax settings from Firestore
class TaxCalculationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Singleton pattern
  static final TaxCalculationService _instance = TaxCalculationService._();
  factory TaxCalculationService() => _instance;
  TaxCalculationService._();

  /// Calculate tax for a payout based on tax settings
  ///
  /// [amount] - Gross amount before tax
  /// [recipientType] - Type of recipient (affiliate, shipper, vendor)
  /// [country] - Optional country code for location-based tax
  ///
  /// Returns tax calculation result
  Future<TaxCalculationResult> calculateTax({
    required double amount,
    required String recipientType,
    String? country,
  }) async {
    try {
      // Get active tax settings that apply to this recipient type
      final taxSettingsSnapshot = await _db
          .collection('tax_settings')
          .where('is_active', isEqualTo: true)
          .where('applies_to', whereIn: ['all', recipientType])
          .get();

      if (taxSettingsSnapshot.docs.isEmpty) {
        // No tax settings found, return zero tax
        return TaxCalculationResult(
          taxAmount: 0,
          taxRate: 0,
          taxName: 'No Tax',
          taxType: 'none',
        );
      }

      // Find applicable tax setting
      TaxSetting? applicableTax;
      final now = DateTime.now();

      for (final doc in taxSettingsSnapshot.docs) {
        final taxSetting = TaxSetting.fromMap(doc.data());

        // Check effective date range
        if (taxSetting.effectiveFrom != null && taxSetting.effectiveFrom!.isAfter(now)) {
          continue; // Not yet effective
        }

        if (taxSetting.effectiveTo != null && taxSetting.effectiveTo!.isBefore(now)) {
          continue; // Expired
        }

        // Check country/region match if specified
        if (country != null && taxSetting.country != null) {
          if (taxSetting.country != country) {
            continue; // Country doesn't match
          }
        }

        // Use this tax setting (first match wins)
        applicableTax = taxSetting;
        break;
      }

      if (applicableTax == null) {
        return TaxCalculationResult(
          taxAmount: 0,
          taxRate: 0,
          taxName: 'No Tax',
          taxType: 'none',
        );
      }

      // Calculate tax amount
      final taxAmount = (amount * applicableTax.taxRate) / 100;

      return TaxCalculationResult(
        taxAmount: _roundToTwoDecimals(taxAmount),
        taxRate: applicableTax.taxRate,
        taxName: applicableTax.taxName,
        taxType: applicableTax.taxType,
      );
    } catch (e) {
      // Return zero tax on error to prevent blocking payouts
      return TaxCalculationResult(
        taxAmount: 0,
        taxRate: 0,
        taxName: 'No Tax',
        taxType: 'none',
      );
    }
  }

  /// Calculate tax breakdown for multiple tax types
  /// (e.g., VAT + withholding tax)
  ///
  /// [amount] - Gross amount before tax
  /// [recipientType] - Type of recipient
  /// [country] - Optional country code
  ///
  /// Returns array of tax calculations
  Future<List<TaxCalculationResult>> calculateTaxBreakdown({
    required double amount,
    required String recipientType,
    String? country,
  }) async {
    try {
      final taxSettingsSnapshot = await _db
          .collection('tax_settings')
          .where('is_active', isEqualTo: true)
          .where('applies_to', whereIn: ['all', recipientType])
          .get();

      if (taxSettingsSnapshot.docs.isEmpty) {
        return [];
      }

      final results = <TaxCalculationResult>[];
      final now = DateTime.now();

      for (final doc in taxSettingsSnapshot.docs) {
        final taxSetting = TaxSetting.fromMap(doc.data());

        // Check effective date range
        if (taxSetting.effectiveFrom != null && taxSetting.effectiveFrom!.isAfter(now)) {
          continue;
        }

        if (taxSetting.effectiveTo != null && taxSetting.effectiveTo!.isBefore(now)) {
          continue;
        }

        // Check country/region match if specified
        if (country != null && taxSetting.country != null) {
          if (taxSetting.country != country) {
            continue;
          }
        }

        // Calculate tax for this setting
        final taxAmount = (amount * taxSetting.taxRate) / 100;

        results.add(TaxCalculationResult(
          taxAmount: _roundToTwoDecimals(taxAmount),
          taxRate: taxSetting.taxRate,
          taxName: taxSetting.taxName,
          taxType: taxSetting.taxType,
        ));
      }

      return results;
    } catch (e) {
      return [];
    }
  }

  double _roundToTwoDecimals(double value) {
    return (value * 100).roundToDouble() / 100;
  }
}

/// Tax Calculation Result
class TaxCalculationResult {
  final double taxAmount;
  final double taxRate;
  final String taxName;
  final String taxType;

  TaxCalculationResult({
    required this.taxAmount,
    required this.taxRate,
    required this.taxName,
    required this.taxType,
  });

  Map<String, dynamic> toJson() {
    return {
      'taxAmount': taxAmount,
      'taxRate': taxRate,
      'taxName': taxName,
      'taxType': taxType,
    };
  }
}

/// Tax Setting Model
class TaxSetting {
  final String id;
  final String taxName;
  final String taxType; // vat, sales_tax, income_tax, withholding
  final double taxRate;
  final String appliesTo; // all, vendors, affiliates, shippers
  final String? country;
  final String? region;
  final DateTime? effectiveFrom;
  final DateTime? effectiveTo;
  final bool isActive;

  TaxSetting({
    required this.id,
    required this.taxName,
    required this.taxType,
    required this.taxRate,
    required this.appliesTo,
    this.country,
    this.region,
    this.effectiveFrom,
    this.effectiveTo,
    required this.isActive,
  });

  factory TaxSetting.fromMap(Map<String, dynamic> map) {
    return TaxSetting(
      id: map['id'] ?? '',
      taxName: map['tax_name'] ?? '',
      taxType: map['tax_type'] ?? '',
      taxRate: (map['tax_rate'] as num?)?.toDouble() ?? 0.0,
      appliesTo: map['applies_to'] ?? '',
      country: map['country'],
      region: map['region'],
      effectiveFrom: (map['effective_from'] as Timestamp?)?.toDate(),
      effectiveTo: (map['effective_to'] as Timestamp?)?.toDate(),
      isActive: map['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tax_name': taxName,
      'tax_type': taxType,
      'tax_rate': taxRate,
      'applies_to': appliesTo,
      'country': country,
      'region': region,
      'effective_from': effectiveFrom != null ? Timestamp.fromDate(effectiveFrom!) : null,
      'effective_to': effectiveTo != null ? Timestamp.fromDate(effectiveTo!) : null,
      'is_active': isActive,
    };
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tax_calculation.dart';

class TaxCalculationRepository {
  final FirebaseFirestore _firestore;

  static const String _collection = 'tax_calculations';
  static const String _configCollection = 'tax_configurations';

  TaxCalculationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Create a new tax calculation
  Future<TaxCalculation> create(TaxCalculation calculation) async {
    final docRef = _firestore.collection(_collection).doc();
    final newCalculation = calculation.copyWith(id: docRef.id);

    await docRef.set(newCalculation.toJson());
    return newCalculation;
  }

  // Get tax calculation by ID
  Future<TaxCalculation?> getById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) return null;

    return TaxCalculation.fromJson(doc.data()!);
  }

  // Get tax calculation by invoice ID
  Future<TaxCalculation?> getByInvoiceId(String invoiceId) async {
    final query = await _firestore
        .collection(_collection)
        .where('invoiceId', isEqualTo: invoiceId)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    return TaxCalculation.fromJson(query.docs.first.data());
  }

  // Get all tax calculations
  Future<List<TaxCalculation>> getAll() async {
    final query = await _firestore
        .collection(_collection)
        .orderBy('updatedAt', descending: true)
        .get();

    return query.docs
        .map((doc) => TaxCalculation.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Get tax calculations by status
  Future<List<TaxCalculation>> getByStatus(TaxCalculationStatus status) async {
    final query = await _firestore
        .collection(_collection)
        .where('status', isEqualTo: status.name)
        .orderBy('updatedAt', descending: true)
        .get();

    return query.docs
        .map((doc) => TaxCalculation.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Update tax calculation
  Future<void> update(TaxCalculation calculation) async {
    await _firestore
        .collection(_collection)
        .doc(calculation.id)
        .update(calculation.copyWith(
          updatedAt: DateTime.now(),
        ).toJson());
  }

  // Delete tax calculation
  Future<void> delete(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  // Calculate tax for an invoice
  Future<TaxCalculation> calculateTax({
    required String invoiceId,
    required String invoiceNumber,
    required double subtotal,
    required String jurisdiction,
    required String userId,
    List<Map<String, dynamic>> lineItems = const [],
  }) async {
    // Get tax configuration for jurisdiction
    final config = await getTaxConfiguration(jurisdiction);
    if (config == null) {
      throw Exception('No tax configuration found for jurisdiction: $jurisdiction');
    }

    final taxItems = <TaxItem>[];
    double totalTax = 0;

    for (final rule in config.rules) {
      // Check if rule applies to any line item
      bool applies = false;
      for (final item in lineItems) {
        final category = item['category'] as String? ?? 'default';
        final amount = (item['amount'] as num).toDouble();
        if (rule.appliesTo(amount, category)) {
          applies = true;
          break;
        }
      }

      // If no line items, check against subtotal
      if (!applies && lineItems.isEmpty) {
        applies = rule.appliesTo(subtotal, 'default');
      }

      if (applies) {
        final taxAmount = (subtotal * rule.rate) / 100;
        totalTax += taxAmount;

        taxItems.add(TaxItem(
          id: DateTime.now().millisecondsSinceEpoch.toString() + rule.id,
          name: rule.name,
          type: rule.type,
          rate: rule.rate,
          amount: taxAmount,
          isInclusive: rule.isInclusive,
          jurisdiction: config.jurisdiction,
          description: rule.description,
        ));
      }
    }

    final totalAmount = subtotal + totalTax;

    final calculation = TaxCalculation(
      id: '',
      invoiceId: invoiceId,
      invoiceNumber: invoiceNumber,
      subtotal: subtotal,
      totalTax: totalTax,
      totalAmount: totalAmount,
      taxItems: taxItems,
      status: TaxCalculationStatus.calculated,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      calculatedBy: userId,
    );

    return await create(calculation);
  }

  // Recalculate tax with adjustments
  Future<TaxCalculation> recalculateTax(
    String calculationId,
    List<TaxItem> adjustedTaxItems,
  ) async {
    final calculation = await getById(calculationId);
    if (calculation == null) {
      throw Exception('Tax calculation not found');
    }

    final totalTax = adjustedTaxItems.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );

    final totalAmount = calculation.subtotal + totalTax;

    final updated = calculation.copyWith(
      taxItems: adjustedTaxItems,
      totalTax: totalTax,
      totalAmount: totalAmount,
      status: TaxCalculationStatus.adjusted,
      updatedAt: DateTime.now(),
    );

    await update(updated);
    return updated;
  }

  // Mark as verified
  Future<void> markAsVerified(String calculationId, String userId) async {
    final calculation = await getById(calculationId);
    if (calculation == null) {
      throw Exception('Tax calculation not found');
    }

    await update(calculation.copyWith(
      status: TaxCalculationStatus.verified,
      calculatedBy: userId,
      updatedAt: DateTime.now(),
    ));
  }

  // Mark as filed
  Future<void> markAsFiled(String calculationId, String userId) async {
    final calculation = await getById(calculationId);
    if (calculation == null) {
      throw Exception('Tax calculation not found');
    }

    await update(calculation.copyWith(
      status: TaxCalculationStatus.filed,
      calculatedBy: userId,
      updatedAt: DateTime.now(),
    ));
  }

  // Stream all tax calculations
  Stream<List<TaxCalculation>> streamAll() {
    return _firestore
        .collection(_collection)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TaxCalculation.fromJson(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Stream by status
  Stream<List<TaxCalculation>> streamByStatus(TaxCalculationStatus status) {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: status.name)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TaxCalculation.fromJson(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Get tax configuration for jurisdiction
  Future<TaxConfiguration?> getTaxConfiguration(String jurisdiction) async {
    final query = await _firestore
        .collection(_configCollection)
        .where('jurisdiction', isEqualTo: jurisdiction)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    return TaxConfiguration.fromJson(query.docs.first.data());
  }

  // Get all tax configurations
  Future<List<TaxConfiguration>> getAllTaxConfigurations() async {
    final query = await _firestore
        .collection(_configCollection)
        .orderBy('jurisdiction')
        .get();

    return query.docs
        .map((doc) => TaxConfiguration.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Create tax configuration
  Future<TaxConfiguration> createTaxConfiguration(
    TaxConfiguration config,
  ) async {
    final docRef = _firestore.collection(_configCollection).doc();
    final newConfig = config.copyWith(id: docRef.id);

    await docRef.set(newConfig.toJson());
    return newConfig;
  }

  // Update tax configuration
  Future<void> updateTaxConfiguration(TaxConfiguration config) async {
    await _firestore
        .collection(_configCollection)
        .doc(config.id)
        .update(config.copyWith(
          updatedAt: DateTime.now(),
        ).toJson());
  }

  // Delete tax configuration
  Future<void> deleteTaxConfiguration(String id) async {
    await _firestore.collection(_configCollection).doc(id).delete();
  }

  // Get tax calculation statistics
  Future<Map<String, dynamic>> getStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    Query query = _firestore.collection(_collection);

    if (startDate != null) {
      query = query.where('createdAt', isGreaterThanOrEqualTo: startDate);
    }
    if (endDate != null) {
      query = query.where('createdAt', isLessThanOrEqualTo: endDate);
    }

    final snapshot = await query.get();
    final calculations = snapshot.docs
        .map((doc) => TaxCalculation.fromJson(doc.data() as Map<String, dynamic>))
        .toList();

    final totalInvoices = calculations.length;
    final totalSubtotal = calculations.fold<double>(
      0,
      (sum, c) => sum + c.subtotal,
    );
    final totalTax = calculations.fold<double>(
      0,
      (sum, c) => sum + c.totalTax,
    );
    final totalAmount = calculations.fold<double>(
      0,
      (sum, c) => sum + c.totalAmount,
    );

    final pending = calculations
        .where((c) => c.status == TaxCalculationStatus.pending)
        .length;
    final calculated = calculations
        .where((c) => c.status == TaxCalculationStatus.calculated)
        .length;
    final verified = calculations
        .where((c) => c.status == TaxCalculationStatus.verified)
        .length;
    final filed = calculations
        .where((c) => c.status == TaxCalculationStatus.filed)
        .length;
    final adjusted = calculations
        .where((c) => c.status == TaxCalculationStatus.adjusted)
        .length;

    // Group by tax type
    final taxByType = <String, double>{};
    for (final calc in calculations) {
      for (final item in calc.taxItems) {
        taxByType[item.type.name] =
            (taxByType[item.type.name] ?? 0) + item.amount;
      }
    }

    return {
      'totalInvoices': totalInvoices,
      'totalSubtotal': totalSubtotal,
      'totalTax': totalTax,
      'totalAmount': totalAmount,
      'averageTaxRate': totalSubtotal > 0 ? (totalTax / totalSubtotal) * 100 : 0,
      'pending': pending,
      'calculated': calculated,
      'verified': verified,
      'filed': filed,
      'adjusted': adjusted,
      'taxByType': taxByType,
    };
  }
}
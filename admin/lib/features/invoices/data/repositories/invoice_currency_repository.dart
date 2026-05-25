import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/invoice_currency.dart';

class InvoiceCurrencyRepository {
  final FirebaseFirestore _firestore;

  static const String _collection = 'invoice_currencies';

  InvoiceCurrencyRepository(this._firestore);

  // Get all currencies
  Stream<List<InvoiceCurrency>> getAllCurrencies() {
    return _firestore
        .collection(_collection)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InvoiceCurrency.fromFirestore(doc))
            .toList());
  }

  // Get active currencies only
  Stream<List<InvoiceCurrency>> getActiveCurrencies() {
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InvoiceCurrency.fromFirestore(doc))
            .toList());
  }

  // Get default currency
  Future<InvoiceCurrency?> getDefaultCurrency() async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('isDefault', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return InvoiceCurrency.fromFirestore(snapshot.docs.first);
  }

  // Get currency by code
  Future<InvoiceCurrency?> getCurrencyByCode(String code) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('code', isEqualTo: code.toUpperCase())
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return InvoiceCurrency.fromFirestore(snapshot.docs.first);
  }

  // Get currency by ID
  Future<InvoiceCurrency?> getCurrencyById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    return InvoiceCurrency.fromFirestore(doc);
  }

  // Create new currency
  Future<String> createCurrency(InvoiceCurrency currency) async {
    final docRef = await _firestore.collection(_collection).add(currency.toFirestore());
    return docRef.id;
  }

  // Update currency
  Future<void> updateCurrency(InvoiceCurrency currency) async {
    await _firestore.collection(_collection).doc(currency.id).update({
      ...currency.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete currency
  Future<void> deleteCurrency(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  // Update exchange rate
  Future<void> updateExchangeRate(String id, double exchangeRate,
      {String? baseCurrency}) async {
    await _firestore.collection(_collection).doc(id).update({
      'exchangeRate': exchangeRate,
      'baseCurrency': baseCurrency,
      'exchangeRateUpdatedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Set as default (only one default)
  Future<void> setAsDefault(String id) async {
    final batch = _firestore.batch();

    // Remove default from all currencies
    final snapshot = await _firestore
        .collection(_collection)
        .where('isDefault', isEqualTo: true)
        .get();

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isDefault': false});
    }

    // Set new default
    batch.update(_firestore.collection(_collection).doc(id), {
      'isDefault': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // Toggle active status
  Future<void> toggleActiveStatus(String id, bool isActive) async {
    await _firestore.collection(_collection).doc(id).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Convert amount between currencies
  Future<double> convertAmount(
      double amount, String fromCurrencyCode, String toCurrencyCode) async {
    if (fromCurrencyCode == toCurrencyCode) return amount;

    final fromCurrency = await getCurrencyByCode(fromCurrencyCode);
    final toCurrency = await getCurrencyByCode(toCurrencyCode);

    if (fromCurrency == null || toCurrency == null) {
      throw Exception('Currency not found');
    }

    // Convert to base currency first
    final baseAmount = fromCurrency.convertToBase(amount);

    // Convert from base to target
    return toCurrency.convertFromBase(baseAmount);
  }

  // Get currency statistics
  Future<Map<String, dynamic>> getCurrencyStatistics() async {
    final snapshot = await _firestore.collection(_collection).get();

    int totalCurrencies = snapshot.docs.length;
    int activeCurrencies =
        snapshot.docs.where((doc) => doc['isActive'] == true).length;
    int currenciesWithExchangeRate = snapshot.docs
        .where((doc) => doc['exchangeRate'] != null)
        .length;

    return {
      'totalCurrencies': totalCurrencies,
      'activeCurrencies': activeCurrencies,
      'inactiveCurrencies': totalCurrencies - activeCurrencies,
      'currenciesWithExchangeRate': currenciesWithExchangeRate,
    };
  }

  // Search currencies
  Stream<List<InvoiceCurrency>> searchCurrencies(String query) {
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      final currencies = snapshot.docs
          .map((doc) => InvoiceCurrency.fromFirestore(doc))
          .toList();
      return currencies
          .where((currency) =>
              currency.name.toLowerCase().contains(query.toLowerCase()) ||
              currency.code.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  // Initialize common currencies
  Future<void> initializeCommonCurrencies() async {
    for (final currency in CommonCurrencies.all) {
      final existing = await getCurrencyByCode(currency.code);
      if (existing == null) {
        await createCurrency(currency.copyWith(
          createdAt: DateTime.now(),
        ));
      }
    }
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:math';

/// Form Share Service - Firestore-based implementation
///
/// Firebase is the single source of truth for all form sharing data
/// No AWS ECS backend - all data comes from Firestore
class FormShareService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Singleton pattern
  static final FormShareService _instance = FormShareService._();
  factory FormShareService() => _instance;
  FormShareService._();

  /// Generate a new form share token and create share record in Firestore
  Future<String?> generateToken({
    required String affiliateId,
    required String affiliateName,
    required String affiliateEmail,
    required String clientEmail,
    String? clientName,
  }) async {
    try {
      // Generate a secure token
      final token = _generateSecureToken();

      // Create share record in Firestore
      await _db.collection('form_shares').add({
        'shareToken': token,
        'affiliateId': affiliateId,
        'affiliateName': affiliateName,
        'affiliateEmail': affiliateEmail,
        'clientEmail': clientEmail,
        'clientName': clientName ?? '',
        'formId': _generateFormId(),
        'used': false,
        'usedAt': null,
        'shippingRequestId': null,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': DateTime.now().add(const Duration(days: 7)),
      });

      return token;
    } catch (e) {
      return null;
    }
  }

  /// Validate and get token data from Firestore
  Future<Map<String, dynamic>?> validateToken(String token) async {
    try {
      final query = await _db
          .collection('form_shares')
          .where('shareToken', isEqualTo: token)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return null;
      }

      final doc = query.docs.first;
      final data = doc.data();

      // Check if expired
      final expiresAt = data['expiresAt'] as Timestamp?;
      if (expiresAt != null && expiresAt.toDate().isBefore(DateTime.now())) {
        return null;
      }

      return {
        'token': data['shareToken'],
        'docId': doc.id,
        'affiliateId': data['affiliateId'],
        'clientEmail': data['clientEmail'],
        'clientName': data['clientName'],
        'affiliateName': data['affiliateName'],
        'affiliateEmail': data['affiliateEmail'],
        'isUsed': data['used'] ?? false,
        'expiresAt': expiresAt?.toDate(),
      };
    } catch (e) {
      return null;
    }
  }

  /// Mark a form share as used when client submits shipping request
  Future<void> markAsUsed(String token, String shippingRequestId) async {
    try {
      final query = await _db
          .collection('form_shares')
          .where('shareToken', isEqualTo: token)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.update({
          'used': true,
          'usedAt': FieldValue.serverTimestamp(),
          'shippingRequestId': shippingRequestId,
        });
      }
    } catch (e) {
      // Silent failure for analytics
    }
  }

  /// Get all form shares for an affiliate
  Future<List<Map<String, dynamic>>> getAffiliateFormShares(
      String affiliateId) async {
    try {
      final query = await _db
          .collection('form_shares')
          .where('affiliateId', isEqualTo: affiliateId)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get form share statistics for an affiliate
  Future<Map<String, int>> getFormShareStats(String affiliateId) async {
    try {
      final query = await _db
          .collection('form_shares')
          .where('affiliateId', isEqualTo: affiliateId)
          .get();

      final total = query.docs.length;
      final used = query.docs
          .where((doc) => (doc.data()['used'] as bool?) == true)
          .length;

      return {'total': total, 'used': used};
    } catch (e) {
      return {'total': 0, 'used': 0};
    }
  }

  /// Get public form URL with token
  String getPublicFormUrl(String token) {
    return 'https://shopsnports.com/public/form/$token';
  }

  /// Delete expired form shares (can be called from Cloud Functions)
  Future<void> deleteExpiredShares() async {
    try {
      final now = DateTime.now();
      final query = await _db
          .collection('form_shares')
          .where('expiresAt', isLessThan: Timestamp.fromDate(now))
          .get();

      final batch = _db.batch();
      for (final doc in query.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      // Silent cleanup failure
    }
  }

  String _generateSecureToken() {
    final random = Random.secure();
    final bytes = List.generate(32, (i) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  String _generateFormId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final random = Random.secure();
    final suffix = List.generate(4, (i) => random.nextInt(16).toRadixString(16)).join();
    return 'FORM-$timestamp-$suffix'.toUpperCase();
  }
}
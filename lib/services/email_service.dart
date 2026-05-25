import 'package:cloud_functions/cloud_functions.dart';

/// Email Service for sending transactional emails via Firebase Functions
/// SMTP configuration is handled server-side in Firebase Functions for security
class EmailService {
  static final EmailService _instance = EmailService._();
  factory EmailService() => _instance;
  EmailService._();

  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Send a templated affiliate email
  ///
  /// [to] - recipient email address
  /// [templateType] - type of template to use
  /// [templateData] - data to populate the template
  Future<void> sendAffiliateEmail({
    required String to,
    required String templateType,
    required Map<String, dynamic> templateData,
  }) async {
    try {
      final callable = _functions.httpsCallable('sendAffiliateEmail');
      final result = await callable.call(<String, dynamic>{
        'to': to,
        'templateType': templateType,
        'templateData': templateData,
      });

      return result.data;
    } on FirebaseFunctionsException catch (e) {
      throw Exception('Failed to send email (${e.code}): ${e.message}');
    } catch (e) {
      throw Exception('Failed to send email: $e');
    }
  }

  /// Send application submitted confirmation email
  Future<void> sendApplicationSubmittedEmail({
    required String email,
    required String fullName,
    required String affiliateId,
  }) async {
    return sendAffiliateEmail(
      to: email,
      templateType: 'applicationSubmitted',
      templateData: {
        'fullName': fullName,
        'affiliateId': affiliateId,
      },
    );
  }

  /// Send application approved email
  Future<void> sendApplicationApprovedEmail({
    required String email,
    required String fullName,
    required String affiliateId,
    required double commissionRate,
  }) async {
    return sendAffiliateEmail(
      to: email,
      templateType: 'applicationApproved',
      templateData: {
        'fullName': fullName,
        'affiliateId': affiliateId,
        'commissionRate': commissionRate,
        'dashboardUrl': 'https://shopsnports.com/affiliate/dashboard',
      },
    );
  }

  /// Send application rejected email
  Future<void> sendApplicationRejectedEmail({
    required String email,
    required String fullName,
    required String affiliateId,
    String? reason,
  }) async {
    return sendAffiliateEmail(
      to: email,
      templateType: 'applicationRejected',
      templateData: {
        'fullName': fullName,
        'affiliateId': affiliateId,
        'reason': reason,
      },
    );
  }

  /// Send payout requested email
  Future<void> sendPayoutRequestedEmail({
    required String email,
    required String fullName,
    required String affiliateId,
    required String payoutId,
    required double amount,
  }) async {
    return sendAffiliateEmail(
      to: email,
      templateType: 'payoutRequested',
      templateData: {
        'fullName': fullName,
        'affiliateId': affiliateId,
        'payoutId': payoutId,
        'amount': amount,
        'currency': 'NGN',
      },
    );
  }

  /// Send payout completed email
  Future<void> sendPayoutCompletedEmail({
    required String email,
    required String fullName,
    required String affiliateId,
    required String payoutId,
    required double amount,
    required String paymentMethod,
    String? transactionReference,
  }) async {
    return sendAffiliateEmail(
      to: email,
      templateType: 'payoutCompleted',
      templateData: {
        'fullName': fullName,
        'affiliateId': affiliateId,
        'payoutId': payoutId,
        'amount': amount,
        'currency': 'NGN',
        'paymentMethod': paymentMethod,
        'transactionReference': transactionReference,
      },
    );
  }

  /// Send commission earned email
  Future<void> sendCommissionEarnedEmail({
    required String email,
    required String fullName,
    required String affiliateId,
    required String trackingNumber,
    required double shipmentValue,
    required double commission,
    required double commissionRate,
    required double totalEarnings,
    required double pendingPayout,
  }) async {
    return sendAffiliateEmail(
      to: email,
      templateType: 'commissionEarned',
      templateData: {
        'fullName': fullName,
        'affiliateId': affiliateId,
        'trackingNumber': trackingNumber,
        'shipmentValue': shipmentValue,
        'commission': commission,
        'commissionRate': commissionRate,
        'totalEarnings': totalEarnings,
        'pendingPayout': pendingPayout,
        'currency': 'NGN',
      },
    );
  }
}
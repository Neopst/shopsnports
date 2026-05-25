import 'package:cloud_firestore/cloud_firestore.dart';

enum AffiliateStatus { pending, approved, rejected, suspended }

enum PayoutSchedule { perJob, weekly, monthly }

enum PayoutStatus { pending, processing, completed, failed }

/// Supported payout currencies
enum AffiliateCurrency { ngn, usd }

extension AffiliateCurrencyExtension on AffiliateCurrency {
  String get code {
    switch (this) {
      case AffiliateCurrency.ngn:
        return 'NGN';
      case AffiliateCurrency.usd:
        return 'USD';
    }
  }

  String get symbol {
    switch (this) {
      case AffiliateCurrency.ngn:
        return '₦';
      case AffiliateCurrency.usd:
        return '\$';
    }
  }

  static AffiliateCurrency fromCountry(String? countryCode) {
    // Nigerian affiliates use NGN, everyone else uses USD
    if (countryCode == null) return AffiliateCurrency.usd;
    switch (countryCode.toUpperCase()) {
      case 'NG':
        return AffiliateCurrency.ngn;
      default:
        return AffiliateCurrency.usd;
    }
  }
}

class Affiliate {
  final String id;
  final String userId;
  final String fullName;
  final String email;
  final String phone;
  final String? photoUrl; // Avatar/thumbnail URL
  final String? companyName;
  final String? address;
  final String? countryCode; // ISO country code (e.g., 'NG' for Nigeria)
  final AffiliateStatus status;
  final double _commissionRate;
  final PayoutSchedule payoutSchedule;
  final AffiliateCurrency preferredCurrency; // Auto-detected based on country
  final String? bankAccountDetails;
  final String? taxId;
  final double totalEarnings;
  final double pendingPayout;
  final int totalShipments;
  final DateTime joinedDate;
  final DateTime? lastPayoutDate;
  final DateTime? approvedAt;
  final String? approvedBy; // Admin ID who approved
  final String? rejectionReason;

  /// Maximum allowed commission rate (100%)
  static const double maxCommissionRate = 100.0;

  /// Minimum allowed commission rate (0%)
  static const double minCommissionRate = 0.0;

  /// Default commission rate for new affiliates
  static const double defaultCommissionRate = 15.0;

  /// Detect currency from email domain or country code
  static AffiliateCurrency detectCurrency(String? email, String? country) {
    if (country != null) {
      return AffiliateCurrencyExtension.fromCountry(country);
    }
    // Fallback: check email domain for Nigerian indicators
    if (email != null && email.toLowerCase().contains('.ng')) {
      return AffiliateCurrency.ngn;
    }
    return AffiliateCurrency.usd;
  }

  Affiliate({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phone,
    this.photoUrl,
    this.companyName,
    this.address,
    this.countryCode,
    required this.status,
    double commissionRate = defaultCommissionRate,
    required this.payoutSchedule,
    AffiliateCurrency? preferredCurrency,
    this.bankAccountDetails,
    this.taxId,
    this.totalEarnings = 0.0,
    this.pendingPayout = 0.0,
    this.totalShipments = 0,
    required this.joinedDate,
    this.lastPayoutDate,
    this.approvedAt,
    this.approvedBy,
    this.rejectionReason,
  })  : _commissionRate = commissionRate.clamp(minCommissionRate, maxCommissionRate),
        preferredCurrency = preferredCurrency ??
            detectCurrency(email, countryCode);

  /// Get commission rate (validated)
  double get commissionRate => _commissionRate;

  /// Validate and set commission rate
  /// Throws ArgumentError if rate is outside valid range
  static double validateCommissionRate(double rate) {
    if (rate < minCommissionRate || rate > maxCommissionRate) {
      throw ArgumentError(
        'Commission rate must be between ${minCommissionRate}% and ${maxCommissionRate}%. '
        'Provided: $rate%'
      );
    }
    return rate;
  }

  /// Check if commission rate is valid
  static bool isValidCommissionRate(double rate) {
    return rate >= minCommissionRate && rate <= maxCommissionRate;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'photoUrl': photoUrl,
      'companyName': companyName,
      'address': address,
      'countryCode': countryCode,
      'status': status.name,
      'commissionRate': _commissionRate,
      'payoutSchedule': payoutSchedule.name,
      'preferredCurrency': preferredCurrency.code,
      'bankAccountDetails': bankAccountDetails,
      'taxId': taxId,
      'totalEarnings': totalEarnings,
      'pendingPayout': pendingPayout,
      'totalShipments': totalShipments,
      'joinedDate': Timestamp.fromDate(joinedDate),
      'lastPayoutDate': lastPayoutDate != null
          ? Timestamp.fromDate(lastPayoutDate!)
          : null,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'approvedBy': approvedBy,
      'rejectionReason': rejectionReason,
    };
  }

  factory Affiliate.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final rawRate = (data['commissionRate'] ?? defaultCommissionRate).toDouble();
    final countryCode = data['countryCode'] as String?;
    final preferredCurrencyCode = data['preferredCurrency'] as String?;

    // Parse preferred currency from stored value, default to auto-detect
    AffiliateCurrency? parsedCurrency;
    if (preferredCurrencyCode != null) {
      switch (preferredCurrencyCode.toUpperCase()) {
        case 'NGN':
          parsedCurrency = AffiliateCurrency.ngn;
          break;
        case 'USD':
        default:
          parsedCurrency = AffiliateCurrency.usd;
          break;
      }
    }

    return Affiliate(
      id: doc.id,
      userId: data['userId'] ?? '',
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      photoUrl: data['photoUrl'],
      companyName: data['companyName'],
      address: data['address'],
      countryCode: countryCode,
      status: AffiliateStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => AffiliateStatus.pending,
      ),
      commissionRate: isValidCommissionRate(rawRate) ? rawRate : defaultCommissionRate,
      payoutSchedule: PayoutSchedule.values.firstWhere(
        (e) => e.name == data['payoutSchedule'],
        orElse: () => PayoutSchedule.monthly,
      ),
      preferredCurrency: parsedCurrency,
      bankAccountDetails: data['bankAccountDetails'],
      taxId: data['taxId'],
      totalEarnings: (data['totalEarnings'] ?? 0).toDouble(),
      pendingPayout: (data['pendingPayout'] ?? 0).toDouble(),
      totalShipments: data['totalShipments'] ?? 0,
      joinedDate: (data['joinedDate'] as Timestamp).toDate(),
      lastPayoutDate: data['lastPayoutDate'] != null
          ? (data['lastPayoutDate'] as Timestamp).toDate()
          : null,
      approvedAt: data['approvedAt'] != null
          ? (data['approvedAt'] as Timestamp).toDate()
          : null,
      approvedBy: data['approvedBy'],
      rejectionReason: data['rejectionReason'],
    );
  }
}

class PayoutRecord {
  final String id;
  final String affiliateId;
  final String affiliateName;
  final double amount;
  final double taxAmount;
  final double netAmount;
  final String period;
  final List<String> shipmentIds;
  final PayoutStatus status;
  final DateTime payoutDate;
  final String? transactionReference;
  final String? notes;

  PayoutRecord({
    required this.id,
    required this.affiliateId,
    required this.affiliateName,
    required this.amount,
    required this.taxAmount,
    required this.netAmount,
    required this.period,
    required this.shipmentIds,
    required this.status,
    required this.payoutDate,
    this.transactionReference,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'affiliateId': affiliateId,
      'affiliateName': affiliateName,
      'amount': amount,
      'taxAmount': taxAmount,
      'netAmount': netAmount,
      'period': period,
      'shipmentIds': shipmentIds,
      'status': status.name,
      'payoutDate': Timestamp.fromDate(payoutDate),
      'transactionReference': transactionReference,
      'notes': notes,
    };
  }

  factory PayoutRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PayoutRecord(
      id: doc.id,
      affiliateId: data['affiliateId'] ?? '',
      affiliateName: data['affiliateName'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      taxAmount: (data['taxAmount'] ?? 0).toDouble(),
      netAmount: (data['netAmount'] ?? 0).toDouble(),
      period: data['period'] ?? '',
      shipmentIds: List<String>.from(data['shipmentIds'] ?? []),
      status: PayoutStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => PayoutStatus.pending,
      ),
      payoutDate: (data['payoutDate'] as Timestamp).toDate(),
      transactionReference: data['transactionReference'],
      notes: data['notes'],
    );
  }
}

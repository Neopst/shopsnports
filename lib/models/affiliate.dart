import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';

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
    if (countryCode == null) return AffiliateCurrency.usd;
    switch (countryCode.toUpperCase()) {
      case 'NG':
        return AffiliateCurrency.ngn;
      default:
        return AffiliateCurrency.usd;
    }
  }
}

/// Affiliate model using Firestore as single source of truth
class Affiliate {
  final String id;
  final String userId; // Firebase UID
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
    this.status = AffiliateStatus.pending,
    double commissionRate = defaultCommissionRate,
    this.payoutSchedule = PayoutSchedule.monthly,
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

  /// Create Affiliate from Firestore document
  factory Affiliate.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Affiliate.fromMap(data, doc.id);
  }

  /// Create Affiliate from Map
  factory Affiliate.fromMap(Map<String, dynamic> map, [String? id]) {
    final rawRate = (map['commissionRate'] as num?)?.toDouble() ?? defaultCommissionRate;
    final countryCode = map['countryCode'] as String?;
    final preferredCurrencyCode = map['preferredCurrency'] as String?;

    // Parse preferred currency
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
      id: id ?? map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      fullName: map['fullName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      companyName: map['companyName'] as String?,
      address: map['address'] as String?,
      countryCode: countryCode,
      status: map['status'] != null
          ? AffiliateStatusExtension.fromJson(map['status'] as String)
          : AffiliateStatus.pending,
      commissionRate: isValidCommissionRate(rawRate) ? rawRate : defaultCommissionRate,
      payoutSchedule: map['payoutSchedule'] != null
          ? PayoutScheduleExtension.fromJson(map['payoutSchedule'] as String)
          : PayoutSchedule.monthly,
      preferredCurrency: parsedCurrency,
      bankAccountDetails: map['bankAccountDetails'] as String?,
      taxId: map['taxId'] as String?,
      totalEarnings: (map['totalEarnings'] as num?)?.toDouble() ?? 0.0,
      pendingPayout: (map['pendingPayout'] as num?)?.toDouble() ?? 0.0,
      totalShipments: map['totalShipments'] as int? ?? 0,
      joinedDate: map['joinedDate'] != null
          ? (map['joinedDate'] as Timestamp).toDate()
          : DateTime.now(),
      lastPayoutDate: map['lastPayoutDate'] != null
          ? (map['lastPayoutDate'] as Timestamp).toDate()
          : null,
      approvedAt: map['approvedAt'] != null
          ? (map['approvedAt'] as Timestamp).toDate()
          : null,
      approvedBy: map['approvedBy'] as String?,
      rejectionReason: map['rejectionReason'] as String?,
    );
  }

  /// Convert to Map for Firestore
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
      'status': status.toJson(),
      'commissionRate': _commissionRate,
      'payoutSchedule': payoutSchedule.toJson(),
      'preferredCurrency': preferredCurrency.code,
      'bankAccountDetails': bankAccountDetails,
      'taxId': taxId,
      'totalEarnings': totalEarnings,
      'pendingPayout': pendingPayout,
      'totalShipments': totalShipments,
      'joinedDate': Timestamp.fromDate(joinedDate),
      'lastPayoutDate':
          lastPayoutDate != null ? Timestamp.fromDate(lastPayoutDate!) : null,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'approvedBy': approvedBy,
      'rejectionReason': rejectionReason,
    };
  }

  /// Convert to JSON for API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'photoUrl': photoUrl,
      'companyName': companyName,
      'address': address,
      'status': status.name,
      'commissionRate': commissionRate,
      'payoutSchedule': payoutSchedule.name,
      'bankAccountDetails': bankAccountDetails,
      'taxId': taxId,
      'totalEarnings': totalEarnings,
      'pendingPayout': pendingPayout,
      'totalShipments': totalShipments,
      'joinedDate': joinedDate.toIso8601String(),
      'lastPayoutDate': lastPayoutDate?.toIso8601String(),
      'approvedAt': approvedAt?.toIso8601String(),
      'approvedBy': approvedBy,
      'rejectionReason': rejectionReason,
    };
  }

  /// Create a copy with updated fields
  /// Note: commissionRate is validated before being set
  Affiliate copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? email,
    String? phone,
    String? photoUrl,
    String? companyName,
    String? address,
    AffiliateStatus? status,
    double? commissionRate,
    PayoutSchedule? payoutSchedule,
    String? bankAccountDetails,
    String? taxId,
    double? totalEarnings,
    double? pendingPayout,
    int? totalShipments,
    DateTime? joinedDate,
    DateTime? lastPayoutDate,
    DateTime? approvedAt,
    String? approvedBy,
    String? rejectionReason,
  }) {
    return Affiliate(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      companyName: companyName ?? this.companyName,
      address: address ?? this.address,
      status: status ?? this.status,
      commissionRate: commissionRate != null
          ? validateCommissionRate(commissionRate)
          : _commissionRate,
      payoutSchedule: payoutSchedule ?? this.payoutSchedule,
      bankAccountDetails: bankAccountDetails ?? this.bankAccountDetails,
      taxId: taxId ?? this.taxId,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      pendingPayout: pendingPayout ?? this.pendingPayout,
      totalShipments: totalShipments ?? this.totalShipments,
      joinedDate: joinedDate ?? this.joinedDate,
      lastPayoutDate: lastPayoutDate ?? this.lastPayoutDate,
      approvedAt: approvedAt ?? this.approvedAt,
      approvedBy: approvedBy ?? this.approvedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  @override
  String toString() {
    return 'Affiliate(id: $id, fullName: $fullName, status: $status, totalShipments: $totalShipments, totalEarnings: $totalEarnings)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Affiliate && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

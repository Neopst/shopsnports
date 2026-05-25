/// Affiliate status enumeration
enum AffiliateStatus {
  pending,
  approved,
  suspended,
}

/// Payout schedule enumeration for affiliates
enum PayoutSchedule {
  perJob,
  weekly,
  monthly,
}

/// Payout status enumeration
enum PayoutStatus {
  pending,
  processing,
  completed,
  failed,
}

/// Invoice status enumeration
enum InvoiceStatus {
  draft,
  sent,
  paid,
  overdue,
  cancelled,
}

/// Shipping type enumeration
enum ShippingType {
  air,
  sea,
}

/// Shipping status enumeration
enum ShippingStatus {
  pending,
  approved,
  inTransit,
  delivered,
  cancelled,
}

/// Shipping priority enumeration
enum ShippingPriority {
  standard,
  express,
  urgent,
}

/// Shipping request status enumeration (legacy - use ShippingStatus)
enum ShippingRequestStatus {
  pending,
  assigned,
  inTransit,
  delivered,
  cancelled,
}

/// Extension methods for AffiliateStatus
extension AffiliateStatusExtension on AffiliateStatus {
  String get displayName {
    switch (this) {
      case AffiliateStatus.pending:
        return 'Pending';
      case AffiliateStatus.approved:
        return 'Approved';
      case AffiliateStatus.suspended:
        return 'Suspended';
    }
  }

  String toJson() => name;

  static AffiliateStatus fromJson(String value) {
    return AffiliateStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AffiliateStatus.pending,
    );
  }
}

/// Extension methods for PayoutSchedule
extension PayoutScheduleExtension on PayoutSchedule {
  String get displayName {
    switch (this) {
      case PayoutSchedule.perJob:
        return 'Per Job';
      case PayoutSchedule.weekly:
        return 'Weekly';
      case PayoutSchedule.monthly:
        return 'Monthly';
    }
  }

  String toJson() => name;

  static PayoutSchedule fromJson(String value) {
    return PayoutSchedule.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PayoutSchedule.monthly,
    );
  }
}

/// Extension methods for PayoutStatus
extension PayoutStatusExtension on PayoutStatus {
  String get displayName {
    switch (this) {
      case PayoutStatus.pending:
        return 'Pending';
      case PayoutStatus.processing:
        return 'Processing';
      case PayoutStatus.completed:
        return 'Completed';
      case PayoutStatus.failed:
        return 'Failed';
    }
  }

  String toJson() => name;

  static PayoutStatus fromJson(String value) {
    return PayoutStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PayoutStatus.pending,
    );
  }
}

/// Extension methods for ShippingType
extension ShippingTypeExtension on ShippingType {
  String get displayName {
    switch (this) {
      case ShippingType.air:
        return 'Air';
      case ShippingType.sea:
        return 'Sea';
    }
  }

  String toJson() => name;

  static ShippingType fromJson(String value) {
    return ShippingType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ShippingType.air,
    );
  }
}

/// Extension methods for ShippingStatus
extension ShippingStatusExtension on ShippingStatus {
  String get displayName {
    switch (this) {
      case ShippingStatus.pending:
        return 'Pending';
      case ShippingStatus.approved:
        return 'Approved';
      case ShippingStatus.inTransit:
        return 'In Transit';
      case ShippingStatus.delivered:
        return 'Delivered';
      case ShippingStatus.cancelled:
        return 'Cancelled';
    }
  }

  String toJson() => name;

  static ShippingStatus fromJson(String value) {
    return ShippingStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ShippingStatus.pending,
    );
  }
}

/// Extension methods for ShippingPriority
extension ShippingPriorityExtension on ShippingPriority {
  String get displayName {
    switch (this) {
      case ShippingPriority.standard:
        return 'Standard';
      case ShippingPriority.express:
        return 'Express';
      case ShippingPriority.urgent:
        return 'Urgent';
    }
  }

  String toJson() => name;

  static ShippingPriority fromJson(String value) {
    return ShippingPriority.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ShippingPriority.standard,
    );
  }
}

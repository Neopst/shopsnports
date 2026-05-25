// lib/config/firestore_constants.dart
//
// FIRESTORE COLLECTIONS & FIELD NAMES
// Centralized Firestore schema configuration
// All collection names and field names defined here
// Use these constants instead of hardcoding strings
//

/// Firestore collection names
/// These must match the collections defined in firestore.rules
class FirestoreConstants {
  // ============================================================================
  // COLLECTIONS
  // ============================================================================

  /// Users collection - User profiles and authentication data
  static const String usersCollection = 'users';

  /// Shipping requests collection - Shipment requests from customers
  static const String shippingRequestsCollection = 'shippingRequests';

  /// Affiliates collection - Affiliate profiles and information
  static const String affiliatesCollection = 'affiliates';

  /// Notifications collection - In-app notifications and alerts
  static const String notificationsCollection = 'notifications';

  /// Notification settings collection - User notification preferences
  static const String notificationSettingsCollection = 'notification_settings';

  /// News ticker collection - News and updates feed
  static const String newsTickerCollection = 'news_ticker';

  /// Banners collection - Promotional banners and ads
  static const String bannersCollection = 'banners';

  /// Content pages collection - Static pages (FAQ, About, Terms, etc.)
  static const String contentPagesCollection = 'content_pages';

  /// Push notification templates collection - Template for push notifications
  static const String pushNotificationTemplatesCollection =
      'push_notifications';

  /// Addresses collection - User delivery addresses
  static const String addressesCollection = 'addresses';

  /// Invoices collection - Shipping invoices and receipts
  static const String invoicesCollection = 'invoices';

  /// Payouts collection - Affiliate payout records
  static const String payoutsCollection = 'payouts';

  /// Activity logs collection - User action history
  static const String activityLogsCollection = 'activity_logs';

  /// Settings collection - Application configuration settings
  static const String settingsCollection = 'settings';

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Get all collection names as list (useful for documentation)
  static const List<String> allCollections = [
    usersCollection,
    shippingRequestsCollection,
    affiliatesCollection,
    notificationsCollection,
    notificationSettingsCollection,
    newsTickerCollection,
    bannersCollection,
    contentPagesCollection,
    pushNotificationTemplatesCollection,
    addressesCollection,
    invoicesCollection,
    payoutsCollection,
    activityLogsCollection,
    settingsCollection,
  ];
}

// ============================================================================
// USER DOCUMENT FIELDS
// ============================================================================

class UserFields {
  static const String id = 'id'; // Firebase Auth UID
  static const String email = 'email';
  static const String displayName = 'displayName';
  static const String phoneNumber = 'phoneNumber';
  static const String profileImageUrl = 'profileImageUrl';
  static const String userType = 'userType'; // customer, shipper, affiliate
  static const String status = 'status'; // active, suspended, inactive
  static const String role = 'role'; // user, admin, super_admin
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';
  static const String lastLoginAt = 'lastLoginAt';
  static const String kycStatus =
      'kycStatus'; // unverified, pending, verified, rejected
  static const String affiliateStatus =
      'affiliateStatus'; // pending, approved, rejected
}

// ============================================================================
// SHIPPING REQUEST DOCUMENT FIELDS
// ============================================================================

class ShippingRequestFields {
  static const String id = 'id';
  static const String userId = 'userId'; // Shipper/customer who created it
  static const String originAddress = 'originAddress';
  static const String destinationAddress = 'destinationAddress';
  static const String weight = 'weight'; // in kg
  static const String dimensions = 'dimensions'; // width, height, depth
  static const String itemDescription = 'itemDescription';
  static const String itemValue = 'itemValue';
  static const String estimatedCost = 'estimatedCost';
  static const String actualCost = 'actualCost';
  static const String status =
      'status'; // pending, quoted, accepted, in_transit, delivered, cancelled
  static const String trackingNumber = 'trackingNumber';
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';
  static const String deliveryDate = 'deliveryDate';
  static const String affiliateId = 'affiliateId'; // If referred by affiliate
  static const String paymentStatus =
      'paymentStatus'; // pending, completed, failed
}

// ============================================================================
// AFFILIATE DOCUMENT FIELDS
// ============================================================================

class AffiliateFields {
  static const String id = 'id';
  static const String userId = 'userId'; // Reference to users collection
  static const String businessName = 'businessName';
  static const String bankName = 'bankName';
  static const String bankAccountNumber = 'bankAccountNumber';
  static const String bankAccountName = 'bankAccountName';
  static const String commissionRate = 'commissionRate'; // percentage
  static const String totalEarnings = 'totalEarnings';
  static const String totalReferrals = 'totalReferrals';
  static const String status =
      'status'; // pending, approved, suspended, rejected
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';
  static const String approvedAt = 'approvedAt';
  static const String affiliateCode =
      'affiliateCode'; // Unique code for referrals
}

// ============================================================================
// NOTIFICATION DOCUMENT FIELDS
// ============================================================================

class NotificationFields {
  static const String id = 'id';
  static const String userId = 'userId'; // Who receives the notification
  static const String title = 'title';
  static const String message = 'message';
  static const String type = 'type'; // shipping, affiliate, system, promotional
  static const String status = 'status'; // unread, read, archived
  static const String actionUrl = 'actionUrl'; // Deep link or navigation URL
  static const String timestamp = 'timestamp';
  static const String readAt = 'readAt';
  static const String createdAt = 'createdAt';
}

// ============================================================================
// NOTIFICATION SETTINGS DOCUMENT FIELDS
// ============================================================================

class NotificationSettingsFields {
  static const String userId = 'userId';
  static const String pushEnabled = 'pushEnabled';
  static const String emailEnabled = 'emailEnabled';
  static const String inAppEnabled = 'inAppEnabled';
  static const String types =
      'types'; // object with shipping, affiliate, system, promotional
  static const String frequency = 'frequency'; // immediate, daily, weekly
  static const String quietHoursEnabled = 'quietHoursEnabled';
  static const String quietHoursStart = 'quietHoursStart'; // 24h format
  static const String quietHoursEnd = 'quietHoursEnd'; // 24h format
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';
}

// ============================================================================
// NEWS TICKER DOCUMENT FIELDS
// ============================================================================

class NewsTickerFields {
  static const String id = 'id';
  static const String title = 'title';
  static const String content = 'content';
  static const String priority = 'priority'; // Higher = display first
  static const String status = 'status'; // published, draft, archived
  static const String imageUrl = 'imageUrl';
  static const String publishedAt = 'publishedAt';
  static const String createdAt = 'createdAt';
  static const String createdBy = 'createdBy'; // Admin ID
}

// ============================================================================
// BANNER DOCUMENT FIELDS
// ============================================================================

class BannerFields {
  static const String id = 'id';
  static const String title = 'title';
  static const String imageUrl = 'imageUrl';
  static const String link = 'link'; // Navigation URL or deep link
  static const String status = 'status'; // active, inactive
  static const String displayOrder = 'displayOrder';
  static const String startDate = 'startDate';
  static const String endDate = 'endDate';
  static const String createdAt = 'createdAt';
}

// ============================================================================
// INVOICE DOCUMENT FIELDS
// ============================================================================

class InvoiceFields {
  static const String id = 'id';
  static const String userId = 'userId';
  static const String shippingRequestId = 'shippingRequestId';
  static const String invoiceNumber = 'invoiceNumber';
  static const String amount = 'amount';
  static const String currency = 'currency'; // NGN, USD, etc.
  static const String status = 'status'; // pending, paid, overdue, cancelled
  static const String issueDate = 'issueDate';
  static const String dueDate = 'dueDate';
  static const String paidDate = 'paidDate';
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';
}

// ============================================================================
// PAYOUT DOCUMENT FIELDS
// ============================================================================

class PayoutFields {
  static const String id = 'id';
  static const String affiliateId = 'affiliateId';
  static const String amount = 'amount';
  static const String currency = 'currency'; // NGN, USD, etc.
  static const String status =
      'status'; // pending, processing, completed, failed, reversed
  static const String paymentMethod =
      'paymentMethod'; // bank_transfer, mobile_money, etc.
  static const String transactionId = 'transactionId';
  static const String createdAt = 'createdAt';
  static const String completedAt = 'completedAt';
  static const String notes = 'notes';
}

// ============================================================================
// CONTENT PAGE DOCUMENT FIELDS
// ============================================================================

class ContentPageFields {
  static const String id = 'id';
  static const String slug = 'slug'; // how-it-works, about, faq, terms, privacy
  static const String title = 'title';
  static const String content = 'content'; // HTML or Markdown
  static const String published = 'published';
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';
}

// ============================================================================
// PUSH NOTIFICATION TEMPLATE FIELDS
// ============================================================================

class PushNotificationTemplateFields {
  static const String id = 'id';
  static const String name =
      'name'; // shipping_update, affiliate_earnings, etc.
  static const String title = 'title';
  static const String message = 'message'; // Can contain {placeholders}
  static const String type = 'type'; // shipping, affiliate, system, promotional
  static const String enabled = 'enabled';
  static const String description = 'description';
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';
}

// ============================================================================
// QUERY CONSTANTS
// ============================================================================

/// Common query filters and conditions
class FirestoreQueryConstants {
  // User types
  static const String userTypeCustomer = 'customer';
  static const String userTypeShipper = 'shipper';
  static const String userTypeAffiliate = 'affiliate';

  // User status
  static const String statusActive = 'active';
  static const String statusSuspended = 'suspended';
  static const String statusInactive = 'inactive';

  // Shipping request status
  static const String shippingStatusPending = 'pending';
  static const String shippingStatusQuoted = 'quoted';
  static const String shippingStatusAccepted = 'accepted';
  static const String shippingStatusInTransit = 'in_transit';
  static const String shippingStatusDelivered = 'delivered';
  static const String shippingStatusCancelled = 'cancelled';

  // Affiliate status
  static const String affiliateStatusPending = 'pending';
  static const String affiliateStatusApproved = 'approved';
  static const String affiliateStatusSuspended = 'suspended';
  static const String affiliateStatusRejected = 'rejected';

  // Notification type
  static const String notificationTypeShipping = 'shipping';
  static const String notificationTypeAffiliate = 'affiliate';
  static const String notificationTypeSystem = 'system';
  static const String notificationTypePromotional = 'promotional';

  // Notification status
  static const String notificationStatusUnread = 'unread';
  static const String notificationStatusRead = 'read';
  static const String notificationStatusArchived = 'archived';

  // Invoice status
  static const String invoiceStatusPending = 'pending';
  static const String invoiceStatusPaid = 'paid';
  static const String invoiceStatusOverdue = 'overdue';
  static const String invoiceStatusCancelled = 'cancelled';

  // Payout status
  static const String payoutStatusPending = 'pending';
  static const String payoutStatusProcessing = 'processing';
  static const String payoutStatusCompleted = 'completed';
  static const String payoutStatusFailed = 'failed';
  static const String payoutStatusReversed = 'reversed';

  // Content page slugs
  static const String pageSlugHowItWorks = 'how-it-works';
  static const String pageSlugAbout = 'about';
  static const String pageSlugFaq = 'faq';
  static const String pageSlugTerms = 'terms';
  static const String pageSlugPrivacy = 'privacy';
}

// ============================================================================
// USAGE EXAMPLES
// ============================================================================

/*
  /// Example 1: Query all active users
  Future<List<User>> getActiveUsers() async {
    final snapshot = await FirebaseFirestore.instance
        .collection(FirestoreConstants.usersCollection)
        .where(FirestoreConstants.UserFields.status,
            isEqualTo: FirestoreQueryConstants.statusActive)
        .get();
    
    return snapshot.docs.map((doc) => User.fromFirestore(doc)).toList();
  }

  /// Example 2: Stream user's notifications
  Stream<List<Notification>> getMyNotifications(String userId) {
    return FirebaseFirestore.instance
        .collection(FirestoreConstants.notificationsCollection)
        .where(FirestoreConstants.NotificationFields.userId, isEqualTo: userId)
        .orderBy(FirestoreConstants.NotificationFields.timestamp, descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Notification.fromFirestore(doc)).toList());
  }

  /// Example 3: Get shipping request by ID
  Future<ShippingRequest?> getShippingRequest(String requestId) async {
    final doc = await FirebaseFirestore.instance
        .collection(FirestoreConstants.shippingRequestsCollection)
        .doc(requestId)
        .get();
    
    return doc.exists ? ShippingRequest.fromFirestore(doc) : null;
  }

  /// Example 4: Query news ticker
  Stream<List<NewsTicker>> getPublishedNews() {
    return FirebaseFirestore.instance
        .collection(FirestoreConstants.newsTickerCollection)
        .where(FirestoreConstants.NewsTickerFields.status,
            isEqualTo: FirestoreQueryConstants.statusActive)
        .orderBy(FirestoreConstants.NewsTickerFields.priority, descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => NewsTicker.fromFirestore(doc)).toList());
  }
*/

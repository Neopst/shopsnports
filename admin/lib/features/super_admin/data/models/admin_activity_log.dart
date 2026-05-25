import 'package:cloud_firestore/cloud_firestore.dart';

enum AdminActivityAction {
  login,
  logout,
  created_admin,
  updated_admin_permissions,
  disabled_admin,
  enabled_admin,
  deleted_admin,
  created_news_item,
  updated_news_item,
  deleted_news_item,
  published_news_item,
  created_content_page,
  updated_content_page,
  deleted_content_page,
  published_content_page,
  created_invoice,
  updated_invoice,
  deleted_invoice,
  sent_invoice_email,
  created_faq,
  updated_faq,
  deleted_faq,
  created_banner,
  updated_banner,
  deleted_banner,
  created_customer,
  updated_customer,
  deleted_customer,
  created_shipping_request,
  updated_shipping_request,
  deleted_shipping_request,
  updated_settings,
  sent_notification,
  sent_push_notification,
  other,
}

extension AdminActivityActionExtension on AdminActivityAction {
  String get displayName {
    final name = this.name.replaceAll('_', ' ');
    return name[0].toUpperCase() + name.substring(1);
  }

  String get module {
    switch (this) {
      case AdminActivityAction.login:
      case AdminActivityAction.logout:
      case AdminActivityAction.created_admin:
      case AdminActivityAction.updated_admin_permissions:
      case AdminActivityAction.disabled_admin:
      case AdminActivityAction.enabled_admin:
      case AdminActivityAction.deleted_admin:
        return 'Admin Management';
      case AdminActivityAction.created_news_item:
      case AdminActivityAction.updated_news_item:
      case AdminActivityAction.deleted_news_item:
      case AdminActivityAction.published_news_item:
        return 'News Ticker';
      case AdminActivityAction.created_content_page:
      case AdminActivityAction.updated_content_page:
      case AdminActivityAction.deleted_content_page:
      case AdminActivityAction.published_content_page:
      case AdminActivityAction.created_faq:
      case AdminActivityAction.updated_faq:
      case AdminActivityAction.deleted_faq:
      case AdminActivityAction.created_banner:
      case AdminActivityAction.updated_banner:
      case AdminActivityAction.deleted_banner:
        return 'Content Management';
      case AdminActivityAction.created_invoice:
      case AdminActivityAction.updated_invoice:
      case AdminActivityAction.deleted_invoice:
      case AdminActivityAction.sent_invoice_email:
        return 'Invoices';
      case AdminActivityAction.created_customer:
      case AdminActivityAction.updated_customer:
      case AdminActivityAction.deleted_customer:
        return 'Customers';
      case AdminActivityAction.created_shipping_request:
      case AdminActivityAction.updated_shipping_request:
      case AdminActivityAction.deleted_shipping_request:
        return 'Shipping';
      case AdminActivityAction.updated_settings:
        return 'Settings';
      case AdminActivityAction.sent_notification:
      case AdminActivityAction.sent_push_notification:
        return 'Notifications';
      case AdminActivityAction.other:
        return 'Other';
    }
  }
}

class AdminActivityLog {
  final String id;
  final String adminId;
  final String adminEmail;
  final AdminActivityAction action;
  final String? itemId; // ID of item being acted upon (news, invoice, etc)
  final String? itemName; // Display name of item
  final Map<String, dynamic>? details; // Additional context
  final DateTime timestamp;
  final String? ipAddress;
  final bool? success;

  AdminActivityLog({
    required this.id,
    required this.adminId,
    required this.adminEmail,
    required this.action,
    this.itemId,
    this.itemName,
    this.details,
    required this.timestamp,
    this.ipAddress,
    this.success,
  });

  /// Format timestamp for display
  String get timeFormatted {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return timestamp.toString().split(' ')[0];
    }
  }

  /// From Firestore
  factory AdminActivityLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminActivityLog.fromMap({...data, 'id': doc.id});
  }

  /// From JSON
  factory AdminActivityLog.fromMap(Map<String, dynamic> map) {
    return AdminActivityLog(
      id: map['id'] as String? ?? '',
      adminId: map['adminId'] as String? ?? '',
      adminEmail: map['adminEmail'] as String? ?? '',
      action: AdminActivityAction.values.firstWhere(
        (e) => e.name == map['action'],
        orElse: () => AdminActivityAction.other,
      ),
      itemId: map['itemId'] as String?,
      itemName: map['itemName'] as String?,
      details: map['details'] as Map<String, dynamic>?,
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      ipAddress: map['ipAddress'] as String?,
      success: map['success'] as bool?,
    );
  }

  /// To Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'adminId': adminId,
      'adminEmail': adminEmail,
      'action': action.name,
      'itemId': itemId,
      'itemName': itemName,
      'details': details,
      'timestamp': Timestamp.fromDate(timestamp),
      'ipAddress': ipAddress,
      'success': success,
    };
  }

  /// To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'adminId': adminId,
      'adminEmail': adminEmail,
      'action': action.name,
      'itemId': itemId,
      'itemName': itemName,
      'details': details,
      'timestamp': timestamp.toIso8601String(),
      'ipAddress': ipAddress,
      'success': success,
    };
  }

  @override
  String toString() {
    return 'AdminActivityLog(id: $id, adminId: $adminId, action: $action, timestamp: $timestamp)';
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'notification_type.dart';
import 'notification_category.dart';

enum TemplateStatus {
  draft,
  active,
  archived,
}

extension TemplateStatusExtension on TemplateStatus {
  String get displayName {
    switch (this) {
      case TemplateStatus.draft:
        return 'Draft';
      case TemplateStatus.active:
        return 'Active';
      case TemplateStatus.archived:
        return 'Archived';
    }
  }

  String get name => toString().split('.').last;

  Color get color {
    switch (this) {
      case TemplateStatus.draft:
        return Color(0xFF9E9E9E);
      case TemplateStatus.active:
        return Color(0xFF4CAF50);
      case TemplateStatus.archived:
        return Color(0xFFFF9800);
    }
  }

  IconData get icon {
    switch (this) {
      case TemplateStatus.draft:
        return Icons.edit_note;
      case TemplateStatus.active:
        return Icons.check_circle;
      case TemplateStatus.archived:
        return Icons.archive;
    }
  }
}

class NotificationTemplate {
  final String id;
  final String name;
  final String description;
  final NotificationType type;
  final NotificationCategory category;
  final String title;
  final String message;
  final String? actionUrl;
  final List<String> variables;
  final TemplateStatus status;
  final bool isDefault;
  final int version;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? lastUsedAt;
  final int usageCount;

  NotificationTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.category,
    required this.title,
    required this.message,
    this.actionUrl,
    this.variables = const [],
    this.status = TemplateStatus.draft,
    this.isDefault = false,
    this.version = 1,
    required this.createdAt,
    this.updatedAt,
    this.lastUsedAt,
    this.usageCount = 0,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'type': type.name,
    'category': category.name,
    'title': title,
    'message': message,
    'actionUrl': actionUrl,
    'variables': variables,
    'status': status.name,
    'isDefault': isDefault,
    'version': version,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    'lastUsedAt': lastUsedAt != null ? Timestamp.fromDate(lastUsedAt!) : null,
    'usageCount': usageCount,
  };

  factory NotificationTemplate.fromMap(Map<String, dynamic> m) {
    return NotificationTemplate(
      id: m['id'] ?? '',
      name: m['name'] ?? '',
      description: m['description'] ?? '',
      type: NotificationType.values.firstWhere(
        (t) => t.name == m['type'],
        orElse: () => NotificationType.system,
      ),
      category: NotificationCategory.values.firstWhere(
        (c) => c.name == m['category'],
        orElse: () => NotificationCategory.system,
      ),
      title: m['title'] ?? '',
      message: m['message'] ?? '',
      actionUrl: m['actionUrl'],
      variables: List<String>.from(m['variables'] ?? []),
      status: TemplateStatus.values.firstWhere(
        (s) => s.name == m['status'],
        orElse: () => TemplateStatus.draft,
      ),
      isDefault: m['isDefault'] ?? false,
      version: m['version'] ?? 1,
      createdAt: m['createdAt'] != null
          ? (m['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: m['updatedAt'] != null
          ? (m['updatedAt'] as Timestamp).toDate()
          : null,
      lastUsedAt: m['lastUsedAt'] != null
          ? (m['lastUsedAt'] as Timestamp).toDate()
          : null,
      usageCount: m['usageCount'] ?? 0,
    );
  }

  NotificationTemplate copyWith({
    String? id,
    String? name,
    String? description,
    NotificationType? type,
    NotificationCategory? category,
    String? title,
    String? message,
    String? actionUrl,
    List<String>? variables,
    TemplateStatus? status,
    bool? isDefault,
    int? version,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastUsedAt,
    int? usageCount,
  }) {
    return NotificationTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      category: category ?? this.category,
      title: title ?? this.title,
      message: message ?? this.message,
      actionUrl: actionUrl ?? this.actionUrl,
      variables: variables ?? this.variables,
      status: status ?? this.status,
      isDefault: isDefault ?? this.isDefault,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      usageCount: usageCount ?? this.usageCount,
    );
  }

  /// Substitute variables in the template
  String substituteTitle(Map<String, dynamic> data) {
    String result = title;
    for (final variable in variables) {
      final placeholder = '{{$variable}}';
      final value = data[variable]?.toString() ?? '';
      result = result.replaceAll(placeholder, value);
    }
    return result;
  }

  /// Substitute variables in the message
  String substituteMessage(Map<String, dynamic> data) {
    String result = message;
    for (final variable in variables) {
      final placeholder = '{{$variable}}';
      final value = data[variable]?.toString() ?? '';
      result = result.replaceAll(placeholder, value);
    }
    return result;
  }

  /// Get all variables used in the template
  List<String> extractVariables() {
    final regex = RegExp(r'\{(\w+)\}');
    final titleMatches = regex.allMatches(title);
    final messageMatches = regex.allMatches(message);

    final variables = <String>{};
    for (final match in titleMatches) {
      variables.add(match.group(1)!);
    }
    for (final match in messageMatches) {
      variables.add(match.group(1)!);
    }

    return variables.toList();
  }

  /// Preview the template with sample data
  Map<String, String> preview(Map<String, dynamic> data) {
    return {
      'title': substituteTitle(data),
      'message': substituteMessage(data),
    };
  }

  @override
  String toString() {
    return 'NotificationTemplate(id: $id, name: $name, type: ${type.displayName}, status: ${status.displayName})';
  }
}

// Default templates
class DefaultNotificationTemplates {
  static NotificationTemplate welcome() {
    return NotificationTemplate(
      id: 'tpl_welcome',
      name: 'Welcome Notification',
      description: 'Welcome message for new users',
      type: NotificationType.system,
      category: NotificationCategory.system,
      title: 'Welcome to ShopsNPorts!',
      message: 'Hi {{userName}}, welcome to ShopsNPorts! Your account has been created successfully.',
      variables: ['userName'],
      status: TemplateStatus.active,
      isDefault: true,
      version: 1,
      createdAt: DateTime.now(),
    );
  }

  static NotificationTemplate orderConfirmed() {
    return NotificationTemplate(
      id: 'tpl_order_confirmed',
      name: 'Order Confirmed',
      description: 'Notification when an order is confirmed',
      type: NotificationType.order,
      category: NotificationCategory.order,
      title: 'Order #{{orderNumber}} Confirmed',
      message: 'Hi {{userName}}, your order #{{orderNumber}} has been confirmed and is being processed.',
      actionUrl: '/orders/{{orderId}}',
      variables: ['userName', 'orderNumber', 'orderId'],
      status: TemplateStatus.active,
      isDefault: true,
      version: 1,
      createdAt: DateTime.now(),
    );
  }

  static NotificationTemplate orderShipped() {
    return NotificationTemplate(
      id: 'tpl_order_shipped',
      name: 'Order Shipped',
      description: 'Notification when an order is shipped',
      type: NotificationType.shipping,
      category: NotificationCategory.shipping,
      title: 'Your Order #{{orderNumber}} Has Been Shipped',
      message: 'Hi {{userName}}, your order #{{orderNumber}} has been shipped! Track it at {{trackingUrl}}.',
      actionUrl: '/shipping/{{trackingNumber}}',
      variables: ['userName', 'orderNumber', 'trackingUrl', 'trackingNumber'],
      status: TemplateStatus.active,
      isDefault: true,
      version: 1,
      createdAt: DateTime.now(),
    );
  }

  static NotificationTemplate orderDelivered() {
    return NotificationTemplate(
      id: 'tpl_order_delivered',
      name: 'Order Delivered',
      description: 'Notification when an order is delivered',
      type: NotificationType.shipping,
      category: NotificationCategory.shipping,
      title: 'Order #{{orderNumber}} Delivered',
      message: 'Hi {{userName}}, your order #{{orderNumber}} has been delivered successfully!',
      actionUrl: '/orders/{{orderId}}',
      variables: ['userName', 'orderNumber', 'orderId'],
      status: TemplateStatus.active,
      isDefault: true,
      version: 1,
      createdAt: DateTime.now(),
    );
  }

  static NotificationTemplate paymentReceived() {
    return NotificationTemplate(
      id: 'tpl_payment_received',
      name: 'Payment Received',
      description: 'Notification when a payment is received',
      type: NotificationType.payment,
      category: NotificationCategory.billing,
      title: 'Payment Received',
      message: 'Hi {{userName}}, we have received your payment of ₦{{amount}} for order #{{orderNumber}}.',
      actionUrl: '/orders/{{orderId}}',
      variables: ['userName', 'amount', 'orderNumber', 'orderId'],
      status: TemplateStatus.active,
      isDefault: true,
      version: 1,
      createdAt: DateTime.now(),
    );
  }

  static NotificationTemplate invoiceCreated() {
    return NotificationTemplate(
      id: 'tpl_invoice_created',
      name: 'Invoice Created',
      description: 'Notification when an invoice is created',
      type: NotificationType.invoice,
      category: NotificationCategory.billing,
      title: 'Invoice #{{invoiceNumber}} Created',
      message: 'Hi {{userName}}, a new invoice #{{invoiceNumber}} for ₦{{amount}} has been created.',
      actionUrl: '/invoices/{{invoiceId}}',
      variables: ['userName', 'invoiceNumber', 'amount', 'invoiceId'],
      status: TemplateStatus.active,
      isDefault: true,
      version: 1,
      createdAt: DateTime.now(),
    );
  }

  static NotificationTemplate promotion() {
    return NotificationTemplate(
      id: 'tpl_promotion',
      name: 'Promotion',
      description: 'Promotional notification',
      type: NotificationType.promotion,
      category: NotificationCategory.sales,
      title: '{{discount}}% Off - Limited Time!',
      message: 'Hi {{userName}}, don\'t miss out! Get {{discount}}% off on {{productName}}. Use code: {{promoCode}}',
      actionUrl: '/promotions/{{promoId}}',
      variables: ['userName', 'discount', 'productName', 'promoCode', 'promoId'],
      status: TemplateStatus.active,
      isDefault: true,
      version: 1,
      createdAt: DateTime.now(),
    );
  }

  static NotificationTemplate systemMaintenance() {
    return NotificationTemplate(
      id: 'tpl_system_maintenance',
      name: 'System Maintenance',
      description: 'Notification for system maintenance',
      type: NotificationType.system,
      category: NotificationCategory.system,
      title: 'Scheduled Maintenance',
      message: 'Hi {{userName}}, we will be performing scheduled maintenance on {{date}} from {{startTime}} to {{endTime}}.',
      variables: ['userName', 'date', 'startTime', 'endTime'],
      status: TemplateStatus.active,
      isDefault: true,
      version: 1,
      createdAt: DateTime.now(),
    );
  }

  static List<NotificationTemplate> all() {
    return [
      welcome(),
      orderConfirmed(),
      orderShipped(),
      orderDelivered(),
      paymentReceived(),
      invoiceCreated(),
      promotion(),
      systemMaintenance(),
    ];
  }
}
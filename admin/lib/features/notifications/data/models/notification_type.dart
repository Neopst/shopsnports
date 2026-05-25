enum NotificationType {
  orderStatus,
  order,
  payment,
  review,
  userActivity,
  inventory,
  system,
  message,
  promotion,
  shipping,
  productReturn,
  refund,
  subscription,
  security,
  compliance,
  support,
  invoice;

  String get displayName {
    switch (this) {
      case NotificationType.orderStatus:
        return 'Order Status';
      case NotificationType.order:
        return 'Order';
      case NotificationType.payment:
        return 'Payment';
      case NotificationType.review:
        return 'Review';
      case NotificationType.userActivity:
        return 'User Activity';
      case NotificationType.inventory:
        return 'Inventory';
      case NotificationType.system:
        return 'System';
      case NotificationType.message:
        return 'Message';
      case NotificationType.promotion:
        return 'Promotion';
      case NotificationType.shipping:
        return 'Shipping';
      case NotificationType.productReturn:
        return 'Return';
      case NotificationType.refund:
        return 'Refund';
      case NotificationType.subscription:
        return 'Subscription';
      case NotificationType.security:
        return 'Security';
      case NotificationType.compliance:
        return 'Compliance';
      case NotificationType.support:
        return 'Support';
      case NotificationType.invoice:
        return 'Invoice';
    }
  }

  String get icon {
    switch (this) {
      case NotificationType.orderStatus:
        return '📦';
      case NotificationType.order:
        return '🛒';
      case NotificationType.payment:
        return '💰';
      case NotificationType.review:
        return '⭐';
      case NotificationType.userActivity:
        return '👤';
      case NotificationType.inventory:
        return '📊';
      case NotificationType.system:
        return '⚙️';
      case NotificationType.message:
        return '💬';
      case NotificationType.promotion:
        return '🎉';
      case NotificationType.shipping:
        return '🚚';
      case NotificationType.productReturn:
        return '↩️';
      case NotificationType.refund:
        return '💸';
      case NotificationType.subscription:
        return '🔄';
      case NotificationType.security:
        return '🔒';
      case NotificationType.compliance:
        return '📋';
      case NotificationType.support:
        return '🎧';
      case NotificationType.invoice:
        return '📄';
    }
  }

  String get description {
    switch (this) {
      case NotificationType.orderStatus:
        return 'Updates about order processing and delivery';
      case NotificationType.order:
        return 'Order-related notifications';
      case NotificationType.payment:
        return 'Payment confirmations and receipts';
      case NotificationType.review:
        return 'New reviews and ratings';
      case NotificationType.userActivity:
        return 'User account activities and updates';
      case NotificationType.inventory:
        return 'Stock level alerts and updates';
      case NotificationType.system:
        return 'System maintenance and updates';
      case NotificationType.message:
        return 'Direct messages and communications';
      case NotificationType.promotion:
        return 'Special offers and promotions';
      case NotificationType.shipping:
        return 'Shipping updates and tracking';
      case NotificationType.productReturn:
        return 'Return request updates';
      case NotificationType.refund:
        return 'Refund processing updates';
      case NotificationType.subscription:
        return 'Subscription renewals and changes';
      case NotificationType.security:
        return 'Security alerts and password changes';
      case NotificationType.compliance:
        return 'Regulatory and compliance updates';
      case NotificationType.support:
        return 'Support ticket updates and responses';
      case NotificationType.invoice:
        return 'Invoice creation and updates';
    }
  }

  bool get requiresUrgentDelivery {
    switch (this) {
      case NotificationType.security:
      case NotificationType.compliance:
      case NotificationType.payment:
        return true;
      default:
        return false;
    }
  }

  bool get isBusinessCritical {
    switch (this) {
      case NotificationType.orderStatus:
      case NotificationType.order:
      case NotificationType.payment:
      case NotificationType.shipping:
      case NotificationType.refund:
      case NotificationType.invoice:
        return true;
      default:
        return false;
    }
  }
}

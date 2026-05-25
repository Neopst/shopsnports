import 'package:cloud_functions/cloud_functions.dart';

/// Service for sending shipping-related email notifications
/// Uses Firebase Cloud Functions server-side for email delivery
class ShippingEmailNotificationService {
  final FirebaseFunctions _functions;

  ShippingEmailNotificationService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  /// Send shipping request confirmation email
  Future<void> sendShippingRequestConfirmation({
    required String toEmail,
    required String customerName,
    required String requestId,
    required String freightType,
    required String origin,
    required String destination,
    required String itemDescription,
  }) async {
    final htmlBody = _buildShippingRequestConfirmationHtml(
      customerName: customerName,
      requestId: requestId,
      freightType: freightType,
      origin: origin,
      destination: destination,
      itemDescription: itemDescription,
    );

    await _sendEmail(
      to: toEmail,
      subject: 'Shipping Request Received - $requestId',
      htmlBody: htmlBody,
    );
  }

  /// Send shipping status update email
  Future<void> sendShippingStatusUpdate({
    required String toEmail,
    required String customerName,
    required String requestId,
    required String oldStatus,
    required String newStatus,
    String? trackingNumber,
    String? additionalInfo,
  }) async {
    final htmlBody = _buildStatusUpdateHtml(
      customerName: customerName,
      requestId: requestId,
      oldStatus: _formatStatus(oldStatus),
      newStatus: _formatStatus(newStatus),
      trackingNumber: trackingNumber,
      additionalInfo: additionalInfo,
    );

    final subject = _getStatusUpdateSubject(newStatus, trackingNumber);

    await _sendEmail(
      to: toEmail,
      subject: subject,
      htmlBody: htmlBody,
    );
  }

  /// Send tracking number assignment email
  Future<void> sendTrackingNumberAssigned({
    required String toEmail,
    required String customerName,
    required String requestId,
    required String trackingNumber,
    String? estimatedDelivery,
  }) async {
    final htmlBody = _buildTrackingAssignedHtml(
      customerName: customerName,
      requestId: requestId,
      trackingNumber: trackingNumber,
      estimatedDelivery: estimatedDelivery,
    );

    await _sendEmail(
      to: toEmail,
      subject: 'Tracking Number Assigned - $requestId',
      htmlBody: htmlBody,
    );
  }

  /// Send email via Firebase Cloud Functions
  Future<void> _sendEmail({
    required String to,
    required String subject,
    required String htmlBody,
  }) async {
    try {
      final callable = _functions.httpsCallable('sendEmail');
      final result = await callable.call({
        'to': to,
        'subject': subject,
        'htmlBody': htmlBody,
        'plainTextBody': _stripHtml(htmlBody),
        'emailType': 'system',
      });

      if (result.data['success'] != true) {
        throw Exception('Email sending failed');
      }
    } catch (e) {
      throw Exception('Failed to send email: $e');
    }
  }

  /// Build shipping request confirmation HTML
  String _buildShippingRequestConfirmationHtml({
    required String customerName,
    required String requestId,
    required String freightType,
    required String origin,
    required String destination,
    required String itemDescription,
  }) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background-color: #0D47A1; color: white; padding: 25px; text-align: center; border-radius: 8px 8px 0 0; }
    .content { background-color: white; padding: 30px; border: 1px solid #e0e0e0; border-top: none; }
    .info-box { background-color: #e3f2fd; padding: 20px; border-radius: 8px; margin: 20px 0; }
    .label { font-weight: bold; color: #0D47A1; min-width: 100px; display: inline-block; }
    .value { color: #333; }
    .footer { text-align: center; font-size: 12px; color: #888; margin-top: 20px; padding-top: 20px; border-top: 1px solid #eee; }
    .button { background-color: #0D47A1; color: white; padding: 14px 28px; text-decoration: none; border-radius: 6px; display: inline-block; margin: 20px 0; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>Shipping Request Received</h1>
    </div>
    <div class="content">
      <p>Hi <strong>$customerName</strong>,</p>
      <p>Thank you for your shipping request! We have received your submission and it is being processed.</p>

      <div class="info-box">
        <p><span class="label">Request ID:</span> <span class="value">$requestId</span></p>
        <p><span class="label">Freight Type:</span> <span class="value">${freightType.toUpperCase()}</span></p>
        <p><span class="label">From:</span> <span class="value">$origin</span></p>
        <p><span class="label">To:</span> <span class="value">$destination</span></p>
        <p><span class="label">Items:</span> <span class="value">$itemDescription</span></p>
      </div>

      <p><strong>Next Steps:</strong></p>
      <ol>
        <li>Our team will review your request</li>
        <li>You will receive a tracking number within 24-48 hours</li>
        <li>You can track your shipment status online</li>
      </ol>

      <p style="text-align: center;">
        <a href="https://shopsnports.com/shipping/track/$requestId" class="button">Track Your Request</a>
      </p>

      <p>If you have any questions, please don't hesitate to contact our support team.</p>
    </div>
    <div class="footer">
      <p>&copy; ${DateTime.now().year} Shop's & Ports. All rights reserved.</p>
    </div>
  </div>
</body>
</html>
''';
  }

  /// Build status update HTML
  String _buildStatusUpdateHtml({
    required String customerName,
    required String requestId,
    required String oldStatus,
    required String newStatus,
    String? trackingNumber,
    String? additionalInfo,
  }) {
    final trackingSection = trackingNumber != null && trackingNumber.isNotEmpty
        ? '''
      <div class="info-box">
        <p><span class="label">Tracking #:</span> <span class="value">$trackingNumber</span></p>
      </div>
'''
        : '';

    final infoSection = additionalInfo != null && additionalInfo.isNotEmpty
        ? '''
      <div class="info-box" style="background-color: #fff3e0;">
        <p><strong>Additional Information:</strong></p>
        <p>$additionalInfo</p>
      </div>
'''
        : '';

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background-color: #0D47A1; color: white; padding: 25px; text-align: center; border-radius: 8px 8px 0 0; }
    .content { background-color: white; padding: 30px; border: 1px solid #e0e0e0; border-top: none; }
    .status-change { background-color: #e8f5e9; padding: 20px; border-radius: 8px; margin: 20px 0; text-align: center; }
    .old-status { text-decoration: line-through; color: #999; }
    .new-status { color: #2e7d32; font-weight: bold; font-size: 18px; }
    .info-box { background-color: #e3f2fd; padding: 20px; border-radius: 8px; margin: 20px 0; }
    .label { font-weight: bold; color: #0D47A1; min-width: 100px; display: inline-block; }
    .value { color: #333; }
    .footer { text-align: center; font-size: 12px; color: #888; margin-top: 20px; padding-top: 20px; border-top: 1px solid #eee; }
    .button { background-color: #0D47A1; color: white; padding: 14px 28px; text-decoration: none; border-radius: 6px; display: inline-block; margin: 20px 0; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>Shipping Status Update</h1>
    </div>
    <div class="content">
      <p>Hi <strong>$customerName</strong>,</p>
      <p>The status of your shipping request has been updated.</p>

      <div class="status-change">
        <p><span class="old-status">$oldStatus</span>
        <span class="arrow">→</span>
        <span class="new-status">$newStatus</span></p>
      </div>

      $trackingSection
      $infoSection

      <p style="text-align: center;">
        <a href="https://shopsnports.com/shipping/track/$requestId" class="button">View Details</a>
      </p>

      <p>If you have any questions about this update, please contact our support team.</p>
    </div>
    <div class="footer">
      <p>&copy; ${DateTime.now().year} Shop's & Ports. All rights reserved.</p>
    </div>
  </div>
</body>
</html>
''';
  }

  /// Build tracking assignment HTML
  String _buildTrackingAssignedHtml({
    required String customerName,
    required String requestId,
    required String trackingNumber,
    String? estimatedDelivery,
  }) {
    final deliverySection = estimatedDelivery != null && estimatedDelivery.isNotEmpty
        ? '''
      <div class="info-box" style="background-color: #e8f5e9;">
        <p><span class="label">Est. Delivery:</span> <span class="value">$estimatedDelivery</span></p>
      </div>
'''
        : '';

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background-color: #2e7d32; color: white; padding: 25px; text-align: center; border-radius: 8px 8px 0 0; }
    .content { background-color: white; padding: 30px; border: 1px solid #e0e0e0; border-top: none; }
    .tracking-box { background-color: #e8f5e9; padding: 20px; border-radius: 8px; margin: 20px 0; text-align: center; }
    .tracking-number { font-family: monospace; font-size: 20px; font-weight: bold; color: #2e7d32; letter-spacing: 2px; }
    .info-box { background-color: #e3f2fd; padding: 20px; border-radius: 8px; margin: 20px 0; }
    .label { font-weight: bold; color: #0D47A1; min-width: 100px; display: inline-block; }
    .value { color: #333; }
    .footer { text-align: center; font-size: 12px; color: #888; margin-top: 20px; padding-top: 20px; border-top: 1px solid #eee; }
    .button { background-color: #2e7d32; color: white; padding: 14px 28px; text-decoration: none; border-radius: 6px; display: inline-block; margin: 20px 0; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>Tracking Number Assigned</h1>
    </div>
    <div class="content">
      <p>Hi <strong>$customerName</strong>,</p>
      <p>Great news! A tracking number has been assigned to your shipping request.</p>

      <div class="tracking-box">
        <p style="margin: 0; color: #666; font-size: 14px;">Tracking Number</p>
        <p class="tracking-number">$trackingNumber</p>
      </div>

      $deliverySection

      <p style="text-align: center;">
        <a href="https://shopsnports.com/shipping/track/$requestId" class="button">Track Your Shipment</a>
      </p>

      <p>You can use this tracking number on the carrier's website for real-time updates.</p>
    </div>
    <div class="footer">
      <p>&copy; ${DateTime.now().year} Shop's & Ports. All rights reserved.</p>
    </div>
  </div>
</body>
</html>
''';
  }

  /// Get subject line based on status
  String _getStatusUpdateSubject(String newStatus, String? trackingNumber) {
    switch (newStatus) {
      case 'approved':
        return 'Your Shipping Request Has Been Approved - Next Steps';
      case 'in_transit':
        return 'Your Shipment Is Now In Transit - Track It Here';
      case 'delivered':
        return 'Your Shipment Has Been Delivered!';
      case 'cancelled':
        return 'Shipping Request Cancelled';
      default:
        return 'Shipping Status Update - $newStatus';
    }
  }

  /// Format status for display
  String _formatStatus(String status) {
    return status
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  /// Strip HTML tags for plain text fallback
  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
import 'package:cloud_functions/cloud_functions.dart';

/// Email service for sending customer-related notification emails
/// Uses Firebase Cloud Functions server-side for email delivery
class CustomerEmailService {
  final FirebaseFunctions _functions;

  CustomerEmailService({
    FirebaseFunctions? functions,
  }) : _functions = functions ?? FirebaseFunctions.instance;

  /// Send welcome email to new customer
  Future<void> sendWelcomeEmail({
    required String customerEmail,
    required String customerName,
    required String role,
  }) async {
    final htmlBody = _buildWelcomeEmailHtml(
      customerName: customerName,
      role: role,
    );

    await _sendEmail(
      to: customerEmail,
      subject: 'Welcome to Shop\'s & Ports!',
      htmlBody: htmlBody,
    );
  }

  /// Send shipping confirmation email
  Future<void> sendShippingConfirmation({
    required String customerEmail,
    required String customerName,
    required String trackingNumber,
    required String origin,
    required String destination,
  }) async {
    final htmlBody = _buildShippingConfirmationHtml(
      customerName: customerName,
      trackingNumber: trackingNumber,
      origin: origin,
      destination: destination,
    );

    await _sendEmail(
      to: customerEmail,
      subject: 'Your Shipment Has Been Confirmed - $trackingNumber',
      htmlBody: htmlBody,
    );
  }

  /// Send shipment delivered notification
  Future<void> sendDeliveredNotification({
    required String customerEmail,
    required String customerName,
    required String trackingNumber,
  }) async {
    final htmlBody = _buildDeliveredNotificationHtml(
      customerName: customerName,
      trackingNumber: trackingNumber,
    );

    await _sendEmail(
      to: customerEmail,
      subject: 'Your Shipment Has Been Delivered! - $trackingNumber',
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

  /// Build welcome email HTML
  String _buildWelcomeEmailHtml({
    required String customerName,
    required String role,
  }) {
    final roleDescription = role == 'affiliate'
        ? 'You can now start earning commissions by referring customers'
        : 'You can now request shipping services and track your shipments';

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
    .footer { text-align: center; font-size: 12px; color: #888; margin-top: 20px; padding-top: 20px; border-top: 1px solid #eee; }
    .button { background-color: #0D47A1; color: white; padding: 14px 28px; text-decoration: none; border-radius: 6px; display: inline-block; margin: 20px 0; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>Welcome to Shop's & Ports!</h1>
    </div>
    <div class="content">
      <p>Hi <strong>$customerName</strong>,</p>
      <p>Thank you for creating an account with Shop's & Ports!</p>

      <div class="info-box">
        <p><strong>Account Type:</strong> ${role[0].toUpperCase() + role.substring(1)}</p>
        <p>$roleDescription</p>
      </div>

      <p><strong>What you can do:</strong></p>
      <ul>
        ${role == 'affiliate' ? '''
        <li>Share your affiliate link with friends and family</li>
        <li>Earn commissions on successful referrals</li>
        <li>Track your earnings in your dashboard</li>
        ''' : '''
        <li>Request shipping for air and sea freight</li>
        <li>Track your shipments in real-time</li>
        <li>Get updates on your shipment status via email</li>
        '''}
      </ul>

      <p style="text-align: center;">
        <a href="https://shopsnports.com" class="button">Visit Website</a>
      </p>

      <p>If you have any questions, our support team is here to help!</p>
    </div>
    <div class="footer">
      <p>&copy; ${DateTime.now().year} Shop's & Ports. All rights reserved.</p>
    </div>
  </div>
</body>
</html>
''';
  }

  /// Build shipping confirmation email HTML
  String _buildShippingConfirmationHtml({
    required String customerName,
    required String trackingNumber,
    required String origin,
    required String destination,
  }) {
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
    .label { font-weight: bold; color: #0D47A1; min-width: 80px; display: inline-block; }
    .footer { text-align: center; font-size: 12px; color: #888; margin-top: 20px; padding-top: 20px; border-top: 1px solid #eee; }
    .button { background-color: #2e7d32; color: white; padding: 14px 28px; text-decoration: none; border-radius: 6px; display: inline-block; margin: 20px 0; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>Shipment Confirmed!</h1>
    </div>
    <div class="content">
      <p>Hi <strong>$customerName</strong>,</p>
      <p>Great news! Your shipping request has been confirmed and your shipment is being processed.</p>

      <div class="tracking-box">
        <p style="margin: 0; color: #666; font-size: 14px;">Tracking Number</p>
        <p class="tracking-number">$trackingNumber</p>
      </div>

      <div class="info-box">
        <p><span class="label">From:</span> $origin</p>
        <p><span class="label">To:</span> $destination</p>
      </div>

      <p><strong>What happens next:</strong></p>
      <ol>
        <li>Your package will be picked up within 24-48 hours</li>
        <li>You'll receive updates as your shipment progresses</li>
        <li>Track your shipment anytime using your tracking number</li>
      </ol>

      <p style="text-align: center;">
        <a href="https://shopsnports.com/track/$trackingNumber" class="button">Track Shipment</a>
      </p>
    </div>
    <div class="footer">
      <p>&copy; ${DateTime.now().year} Shop's & Ports. All rights reserved.</p>
    </div>
  </div>
</body>
</html>
''';
  }

  /// Build delivered notification email HTML
  String _buildDeliveredNotificationHtml({
    required String customerName,
    required String trackingNumber,
  }) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background-color: #1565c0; color: white; padding: 25px; text-align: center; border-radius: 8px 8px 0 0; }
    .content { background-color: white; padding: 30px; border: 1px solid #e0e0e0; border-top: none; }
    .success-box { background-color: #e8f5e9; padding: 25px; border-radius: 8px; margin: 20px 0; text-align: center; }
    .icon { font-size: 48px; margin-bottom: 10px; }
    .footer { text-align: center; font-size: 12px; color: #888; margin-top: 20px; padding-top: 20px; border-top: 1px solid #eee; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>Delivered! 📦</h1>
    </div>
    <div class="content">
      <p>Hi <strong>$customerName</strong>,</p>
      <p>Your shipment <strong>$trackingNumber</strong> has been successfully delivered!</p>

      <div class="success-box">
        <div class="icon">✓</div>
        <p><strong>Delivery Complete</strong></p>
        <p style="color: #666;">Your package has reached its destination.</p>
      </div>

      <p>Thank you for choosing Shop's & Ports for your shipping needs.</p>
      <p>We hope you had a great experience and look forward to serving you again!</p>
    </div>
    <div class="footer">
      <p>&copy; ${DateTime.now().year} Shop's & Ports. All rights reserved.</p>
    </div>
  </div>
</body>
</html>
''';
  }

  /// Strip HTML tags for plain text fallback
  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
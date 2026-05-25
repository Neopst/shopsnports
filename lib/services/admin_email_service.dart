import 'package:cloud_functions/cloud_functions.dart';

/// Email service for sending admin-related notifications
/// Uses Firebase Cloud Functions with SMTP/SendGrid/Mailgun configured server-side
class AdminEmailService {
  final FirebaseFunctions _functions;

  AdminEmailService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  /// Send welcome email to new sub-admin
  Future<void> sendSubAdminWelcomeEmail({
    required String email,
    required String displayName,
    required String tempPassword,
    required String createdBySuperAdminName,
    List<String>? grantedPermissions,
  }) async {
    final permissionsList = grantedPermissions ?? [];
    final permissionsText = permissionsList.isEmpty
        ? 'Default shipping management permissions'
        : 'Custom permissions as assigned';

    final htmlContent = _buildWelcomeEmailHtml(
      displayName: displayName,
      email: email,
      tempPassword: tempPassword,
      createdBy: createdBySuperAdminName,
      permissions: permissionsText,
    );

    await _sendEmail(
      to: email,
      subject: 'Welcome to Shop\'s & Ports Admin Team',
      htmlContent: htmlContent,
    );
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail({
    required String email,
    required String displayName,
    required String resetLink,
  }) async {
    final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background-color: #0D47A1; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0; }
    .content { background-color: white; padding: 30px; border: 1px solid #e0e0e0; }
    .button { background-color: #0D47A1; color: white; padding: 14px 28px; text-decoration: none; border-radius: 6px; display: inline-block; margin: 20px 0; }
    .footer { text-align: center; font-size: 12px; color: #888; margin-top: 20px; padding-top: 20px; border-top: 1px solid #eee; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>Shop's & Ports Admin</h1>
    </div>
    <div class="content">
      <p>Hi $displayName,</p>
      <p>A password reset has been requested for your admin account.</p>
      <p style="text-align: center;">
        <a href="$resetLink" class="button">Reset Password</a>
      </p>
      <p>If you didn't request this, please ignore this email or contact the super admin.</p>
      <p>This link will expire in 1 hour.</p>
    </div>
    <div class="footer">
      <p>&copy; ${DateTime.now().year} Shop's & Ports. All rights reserved.</p>
    </div>
  </div>
</body>
</html>
''';

    await _sendEmail(
      to: email,
      subject: 'Admin Password Reset - Shop\'s & Ports',
      htmlContent: htmlContent,
    );
  }

  /// Send notification about account suspension
  Future<void> sendSuspensionEmail({
    required String email,
    required String displayName,
    required String reason,
    required String suspendedBy,
  }) async {
    final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background-color: #c62828; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0; }
    .content { background-color: white; padding: 30px; border: 1px solid #e0e0e0; }
    .alert { background-color: #ffebee; border-left: 4px solid #c62828; padding: 15px; margin: 20px 0; }
    .footer { text-align: center; font-size: 12px; color: #888; margin-top: 20px; padding-top: 20px; border-top: 1px solid #eee; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>Account Suspended</h1>
    </div>
    <div class="content">
      <p>Hi $displayName,</p>
      <p>Your admin account has been <strong>suspended</strong>.</p>
      <div class="alert">
        <strong>Reason:</strong> $reason<br>
        <strong>Suspended by:</strong> $suspendedBy
      </div>
      <p>If you believe this was done in error, please contact the super admin team.</p>
    </div>
    <div class="footer">
      <p>&copy; ${DateTime.now().year} Shop's & Ports. All rights reserved.</p>
    </div>
  </div>
</body>
</html>
''';

    await _sendEmail(
      to: email,
      subject: 'Your Admin Account Has Been Suspended',
      htmlContent: htmlContent,
    );
  }

  /// Build welcome email HTML
  String _buildWelcomeEmailHtml({
    required String displayName,
    required String email,
    required String tempPassword,
    required String createdBy,
    required String permissions,
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
    .credentials { background-color: #f5f5f5; padding: 20px; border-radius: 8px; margin: 20px 0; }
    .label { font-weight: bold; color: #0D47A1; }
    .value { font-family: monospace; font-size: 14px; background-color: #e3f2fd; padding: 4px 8px; border-radius: 4px; }
    .button { background-color: #0D47A1; color: white; padding: 14px 28px; text-decoration: none; border-radius: 6px; display: inline-block; margin: 20px 0; }
    .footer { text-align: center; font-size: 12px; color: #888; margin-top: 20px; padding-top: 20px; border-top: 1px solid #eee; }
    .permissions { background-color: #fff3e0; padding: 15px; border-radius: 8px; margin: 15px 0; font-size: 14px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>Welcome to the Admin Team!</h1>
    </div>
    <div class="content">
      <p>Hi <strong>$displayName</strong>,</p>
      <p>Congratulations! You have been added as an <strong>Admin</strong> to the Shop's & Ports platform.</p>
      <p>You were invited by: <strong>$createdBy</strong></p>

      <div class="credentials">
        <p><span class="label">Email:</span> <span class="value">$email</span></p>
        <p><span class="label">Temporary Password:</span> <span class="value">$tempPassword</span></p>
      </div>

      <div class="permissions">
        <strong>Your Permissions:</strong><br>
        $permissions
      </div>

      <p><strong>Important Next Steps:</strong></p>
      <ol>
        <li>Click the button below to log in to the admin dashboard</li>
        <li>You will be required to change your password on first login</li>
        <li>Review your assigned permissions in your profile settings</li>
        <li>Contact the super admin if you need any clarification</li>
      </ol>

      <p style="text-align: center;">
        <a href="https://admin.shopsnports.com" class="button">Access Admin Dashboard</a>
      </p>

      <p><strong>Security Reminder:</strong></p>
      <ul>
        <li>Keep your login credentials secure</li>
        <li>Do not share your password with anyone</li>
        <li>Report any suspicious activity immediately</li>
      </ul>
    </div>
    <div class="footer">
      <p>This is an automated message from Shop's & Ports.</p>
      <p>&copy; ${DateTime.now().year} Shop's & Ports. All rights reserved.</p>
    </div>
  </div>
</body>
</html>
''';
  }

  /// Send email via Firebase Cloud Functions
  Future<void> _sendEmail({
    required String to,
    required String subject,
    required String htmlContent,
  }) async {
    try {
      final callable = _functions.httpsCallable('sendEmail');
      final result = await callable.call({
        'to': to,
        'subject': subject,
        'htmlBody': htmlContent,
        'plainTextBody': _stripHtml(htmlContent),
        'emailType': 'system',
      });

      if (result.data['success'] != true) {
        throw Exception('Email sending failed');
      }
    } catch (e) {
      throw Exception('Failed to send email: $e');
    }
  }

  /// Strip HTML tags for plain text fallback
  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
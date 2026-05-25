import 'dart:math';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Email Service for sending emails via Firebase Cloud Functions
///
/// This service provides methods to send emails using nodemailer via Cloud Functions.
/// It uses SMTP configuration stored in Firestore and supports both system and invoice emails.
class EmailService {
  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;

  EmailService({FirebaseFunctions? functions, FirebaseFirestore? firestore})
    : _functions = functions ?? FirebaseFunctions.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  /// Generate a secure random access token for invoice public view
  static String generateAccessToken() {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return List.generate(
      32,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  /// Get SMTP configuration from Firestore
  Future<Map<String, dynamic>> _getSMTPConfig(String emailType) async {
    try {
      final settingsDoc = await _firestore
          .collection('settings')
          .doc('api_settings')
          .get();

      if (!settingsDoc.exists) {
        throw Exception('SMTP settings not configured');
      }

      final data = settingsDoc.data()!;
      final host = data['smtpHost'] as String?;
      final port = data['smtpPort'] as int?;
      final secure = data['smtpSecure'] as bool? ?? true;

      // Select credentials based on email type
      final String? user;
      final String? password;

      if (emailType == 'invoice') {
        user = data['smtpInvoiceEmail'] as String?;
        password = data['smtpInvoicePassword'] as String?;
      } else {
        user = data['smtpNoreplyEmail'] as String?;
        password = data['smtpNoreplyPassword'] as String?;
      }

      if (host == null || port == null || user == null || password == null) {
        throw Exception('Incomplete SMTP configuration for $emailType emails');
      }

      return {
        'host': host,
        'port': port,
        'secure': secure,
        'user': user,
        'password': password,
      };
    } catch (e) {
      throw Exception('Failed to load SMTP configuration: $e');
    }
  }

  /// Send a generic email
  ///
  /// [to] - Recipient email address
  /// [subject] - Email subject
  /// [htmlBody] - HTML content of the email
  /// [plainTextBody] - Plain text fallback (optional)
  /// [emailType] - 'invoice' or 'system' (determines which SMTP account to use)
  Future<void> sendEmail({
    required String to,
    required String subject,
    required String htmlBody,
    String? plainTextBody,
    String emailType = 'system',
  }) async {
    try {
      // Get SMTP configuration
      final smtpConfig = await _getSMTPConfig(emailType);

      // Call Cloud Function
      final callable = _functions.httpsCallable('sendEmail');
      final result = await callable.call({
        'to': to,
        'subject': subject,
        'htmlBody': htmlBody,
        'plainTextBody': plainTextBody,
        'emailType': emailType,
        'smtpConfig': smtpConfig,
      });

      if (result.data['success'] != true) {
        throw Exception('Email sending failed');
      }
    } catch (e) {
      throw Exception('Failed to send email: $e');
    }
  }

  /// Send an invoice email to a customer
  ///
  /// [invoiceId] - Firestore document ID of the invoice
  /// [customerEmail] - Customer's email address
  /// [customerName] - Customer's name
  /// [invoiceNumber] - Invoice number (e.g., INV-2024-001)
  /// [accessToken] - Secure token for public invoice view
  /// [amount] - Total invoice amount
  /// [dueDate] - Invoice due date
  /// [ccAdmin] - Whether to CC admin on the email
  /// [adminEmail] - Admin email to CC (if ccAdmin is true)
  Future<void> sendInvoiceEmail({
    required String invoiceId,
    required String customerEmail,
    required String customerName,
    required String invoiceNumber,
    required String accessToken,
    required double amount,
    required DateTime dueDate,
    bool ccAdmin = true,
    String? adminEmail,
  }) async {
    try {
      // Get SMTP configuration for invoice emails
      final smtpConfig = await _getSMTPConfig('invoice');

      // Get admin email for CC if not provided
      if (ccAdmin && adminEmail == null) {
        try {
          final settingsDoc = await _firestore
              .collection('settings')
              .doc('api_settings')
              .get();
          if (settingsDoc.exists) {
            adminEmail = settingsDoc.data()?['adminEmail'] as String?;
          }
        } catch (e) {
          // Continue without admin email if fetch fails
        }
      }

      // Call specialized Cloud Function for invoice emails
      final callable = _functions.httpsCallable('sendInvoiceEmail');
      final result = await callable.call({
        'invoiceId': invoiceId,
        'customerEmail': customerEmail,
        'customerName': customerName,
        'invoiceNumber': invoiceNumber,
        'accessToken': accessToken,
        'amount': amount,
        'dueDate': _formatDate(dueDate),
        'ccAdmin': ccAdmin,
        'adminEmail': adminEmail,
        'smtpConfig': smtpConfig,
      });

      if (result.data['success'] != true) {
        throw Exception('Invoice email sending failed');
      }

      // Update invoice email tracking
      await _updateInvoiceEmailTracking(invoiceId);
    } catch (e) {
      throw Exception('Failed to send invoice email: $e');
    }
  }

  /// Update invoice email tracking in Firestore
  Future<void> _updateInvoiceEmailTracking(String invoiceId) async {
    try {
      await _firestore.collection('invoices').doc(invoiceId).update({
        'emailSent': true,
        'lastEmailSentAt': FieldValue.serverTimestamp(),
        'emailSentCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Log error but don't throw - email was sent successfully
      print('Error updating email tracking: $e');
    }
  }

  /// Format date for email display
  String _formatDate(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// Send welcome email to new admin
  Future<void> sendAdminWelcomeEmail({
    required String adminEmail,
    required String adminName,
    required String temporaryPassword,
  }) async {
    final htmlBody =
        '''
      <!DOCTYPE html>
      <html>
      <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
        <h2>Welcome to ShopsNSports Admin</h2>
        <p>Dear $adminName,</p>
        <p>Your admin account has been created successfully.</p>
        <p><strong>Login Credentials:</strong></p>
        <p>Email: $adminEmail<br>
        Temporary Password: $temporaryPassword</p>
        <p>Please log in and change your password immediately.</p>
        <p>Best regards,<br>ShopsNSports Team</p>
      </body>
      </html>
    ''';

    await sendEmail(
      to: adminEmail,
      subject: 'Welcome to ShopsNSports Admin',
      htmlBody: htmlBody,
      emailType: 'system',
    );
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail({
    required String email,
    required String resetLink,
  }) async {
    final htmlBody =
        '''
      <!DOCTYPE html>
      <html>
      <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
        <h2>Password Reset Request</h2>
        <p>You requested to reset your password.</p>
        <p>Click the link below to reset your password:</p>
        <p><a href="$resetLink" style="color: #2563eb;">Reset Password</a></p>
        <p>If you didn't request this, please ignore this email.</p>
        <p>This link will expire in 1 hour.</p>
        <p>Best regards,<br>ShopsNSports Team</p>
      </body>
      </html>
    ''';

    await sendEmail(
      to: email,
      subject: 'Password Reset - ShopsNSports',
      htmlBody: htmlBody,
      emailType: 'system',
    );
  }

  /// Send affiliate approval notification
  Future<void> sendAffiliateApprovalEmail({
    required String affiliateEmail,
    required String affiliateName,
  }) async {
    final htmlBody =
        '''
      <!DOCTYPE html>
      <html>
      <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
        <h2>Affiliate Application Approved! 🎉</h2>
        <p>Dear $affiliateName,</p>
        <p>Congratulations! Your affiliate application has been approved.</p>
        <p>You can now start earning commissions by promoting ShopsNSports products.</p>
        <p>Log in to your affiliate dashboard to get started.</p>
        <p>Best regards,<br>ShopsNSports Affiliate Team</p>
      </body>
      </html>
    ''';

    await sendEmail(
      to: affiliateEmail,
      subject: 'Affiliate Application Approved - ShopsNSports',
      htmlBody: htmlBody,
      emailType: 'system',
    );
  }
}

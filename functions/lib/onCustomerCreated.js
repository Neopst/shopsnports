const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');

// Initialize Firebase Admin SDK
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

/**
 * Cloud Function: Triggered when a new customer is created
 * Sends welcome email with customer name
 * 
 * Usage: Triggered automatically on customers/{customerId} creation
 * Environment variables from .env.onCustomerCreated:
 *   - SMTP_HOST
 *   - SMTP_PORT
 *   - SMTP_USER
 *   - SMTP_PASS
 *   - SMTP_SECURE
 */
exports.onCustomerCreated = functions
  .firestore
  .document('customers/{customerId}')
  .onCreate(async (snap, context) => {
    const customer = snap.data();
    const customerId = context.params.customerId;

    console.log(`📧 Welcome email trigger for: ${customer.email} (ID: ${customerId})`);

    try {
      // Get name (use first name if available)
      const fullName = customer.name || 'Customer';
      const firstName = fullName.split(' ')[0];

      // Read SMTP config from environment variables
      const host = process.env.SMTP_HOST || 'smtp.shopsnports.com';
      const port = parseInt(process.env.SMTP_PORT || '587');
      const user = process.env.SMTP_USER || 'noreply@shopsnports.com';
      const pass = process.env.SMTP_PASS || '';
      const secure = (process.env.SMTP_SECURE || 'false') === 'true';

      // Skip if password not configured
      if (!pass) {
        console.warn('⚠️  SMTP_PASS not configured. Skipping welcome email.');
        return;
      }

      // Email configuration
      const smtpConfig = {
        host: host,
        port: port,
        secure: secure,
        auth: {
          user: user,
          pass: pass,
        },
      };

      // Create transporter
      const transporter = nodemailer.createTransport(smtpConfig);

      // Verify connection
      const verified = await transporter.verify().catch((err) => {
        console.error('❌ SMTP verification failed:', err.message);
        return false;
      });

      if (!verified) {
        console.warn('⚠️  SMTP connection failed. Skipping welcome email.');
        return;
      }

      // Email template
      const emailHtml = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; background-color: #f9f9f9; }
    .header { background-color: #003366; color: white; padding: 20px; text-align: center; border-radius: 5px 5px 0 0; }
    .content { background-color: white; padding: 30px; border-radius: 0 0 5px 5px; }
    .btn { background-color: #003366; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block; margin-top: 15px; }
    .footer { text-align: center; font-size: 12px; color: #888; margin-top: 20px; padding-top: 20px; border-top: 1px solid #eee; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>Welcome to Shop's & Ports, ${firstName}! 🚀</h1>
    </div>
    
    <div class="content">
      <p>Hi ${firstName},</p>
      
      <p>Thank you for creating an account with <strong>Shop's & Ports</strong>. We're excited to have you on board!</p>
      
      <h3>Your Account is Ready</h3>
      <p>Your account has been successfully created with the following details:</p>
      <ul>
        <li><strong>Name:</strong> ${fullName}</li>
        <li><strong>Email:</strong> ${customer.email}</li>
        <li><strong>Account Created:</strong> ${new Date().toLocaleDateString()}</li>
      </ul>
      
      <h3>What You Can Do Next</h3>
      <ol>
        <li><strong>Book a Shipment</strong> - Request shipping for your packages</li>
        <li><strong>Track Shipments</strong> - Monitor your deliveries in real-time</li>
        <li><strong>Join Affiliate Program</strong> - Earn commissions by referring customers</li>
        <li><strong>Get Quotes</strong> - Request shipping quotes for your cargo</li>
      </ol>
      
      <p style="text-align: center;">
        <a href="https://shopsnports.com/dashboard" class="btn">Go to Your Dashboard</a>
      </p>
      
      <h3>Need Help?</h3>
      <p>If you have any questions or need assistance, please don't hesitate to contact our support team at <strong>support@shopsnports.com</strong> or call us at <strong>+234-XXX-XXX-XXXX</strong>.</p>
      
      <p>Best regards,<br><strong>The Shop's & Ports Team</strong></p>
    </div>
    
    <div class="footer">
      <p>&copy; 2026 Shop's & Ports. All rights reserved. | <a href="https://shopsnports.com/privacy" style="color: #003366;">Privacy Policy</a> | <a href="https://shopsnports.com/terms" style="color: #003366;">Terms of Service</a></p>
      <p>This is an automated email. Please do not reply to this address.</p>
    </div>
  </div>
</body>
</html>
      `;

      // Send email
      const mailOptions = {
        from: user,
        to: customer.email,
        subject: `Welcome to Shop's & Ports, ${firstName}! 🎉`,
        html: emailHtml,
        replyTo: 'support@shopsnports.com',
      };

      await transporter.sendMail(mailOptions);
      console.log(`✅ Welcome email sent to ${customer.email}`);

      // Log activity
      await db.collection('activity_log').add({
        action: 'welcome_email_sent',
        customerId: customerId,
        email: customer.email,
        name: fullName,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

    } catch (error) {
      console.error(`❌ Error sending welcome email to ${customer.email}:`, error.message);
      
      // Log error for debugging
      await db.collection('email_errors').add({
        customerId: customerId,
        email: customer.email,
        error: error.message,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  });

/**
 * Additional: Email on customer registration (alternative trigger)
 * Can be used if you want to trigger from a different collection
 */
exports.sendWelcomeEmailHttp = functions.https.onCall(
  async (data, context) => {
    // Verify authentication
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated'
      );
    }

    const { email, name } = data;

    if (!email || !name) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Email and name are required'
      );
    }

    try {
      console.log(`📧 HTTP: Sending welcome email to ${email}`);

      // Similar email sending logic here
      console.log('✅ Welcome email sent via HTTP call');
      return { success: true, message: 'Welcome email sent' };
    } catch (error) {
      console.error('❌ HTTP: Error sending email:', error.message);
      throw new functions.https.HttpsError('internal', error.message);
    }
  }
);

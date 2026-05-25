const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');

admin.initializeApp();

/**
 * Send Email via SMTP
 * 
 * Callable function that sends emails using nodemailer with SMTP configuration.
 * Supports both invoice and system emails using different SMTP accounts.
 * 
 * Request data:
 * {
 *   to: string (recipient email),
 *   subject: string,
 *   htmlBody: string,
 *   plainTextBody: string (optional),
 *   emailType: 'invoice' | 'system' (determines which SMTP account to use),
 *   smtpConfig: {
 *     host: string,
 *     port: number,
 *     secure: boolean,
 *     user: string,
 *     password: string
 *   }
 * }
 */
exports.sendEmail = functions.https.onCall(async (data, context) => {
  try {
    // Validate request
    if (!data.to || !data.subject || !data.htmlBody) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Missing required fields: to, subject, htmlBody'
      );
    }

    if (!data.smtpConfig) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'SMTP configuration is required'
      );
    }

    const { host, port, secure, user, password } = data.smtpConfig;

    // Create transporter with provided SMTP config
    const transporter = nodemailer.createTransport({
      host: host,
      port: port,
      secure: secure, // true for 465, false for other ports
      auth: {
        user: user,
        pass: password,
      },
    });

    // Verify connection
    await transporter.verify();

    // Determine sender based on email type
    const fromEmail = data.emailType === 'invoice' 
      ? 'invoices@shopsnports.com' 
      : 'noreply@shopsnports.com';
    
    const fromName = data.emailType === 'invoice'
      ? 'ShopsNSports Billing'
      : 'ShopsNSports';

    // Email options
    const mailOptions = {
      from: `"${fromName}" <${fromEmail}>`,
      to: data.to,
      subject: data.subject,
      text: data.plainTextBody || data.htmlBody.replace(/<[^>]*>/g, ''), // Strip HTML as fallback
      html: data.htmlBody,
    };

    // Send email
    const info = await transporter.sendMail(mailOptions);

    console.log('Email sent successfully:', {
      messageId: info.messageId,
      to: data.to,
      subject: data.subject,
      emailType: data.emailType,
    });

    return {
      success: true,
      messageId: info.messageId,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    };

  } catch (error) {
    console.error('Email sending failed:', error);
    
    // Map nodemailer errors to Firebase errors
    if (error.code === 'EAUTH') {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'SMTP authentication failed. Check credentials.'
      );
    } else if (error.code === 'ECONNECTION') {
      throw new functions.https.HttpsError(
        'unavailable',
        'Could not connect to SMTP server.'
      );
    } else {
      throw new functions.https.HttpsError(
        'internal',
        `Failed to send email: ${error.message}`
      );
    }
  }
});

/**
 * Send Invoice Email
 * 
 * Specialized function for sending invoice emails with professional formatting.
 * Automatically uses the invoices@shopsnports.com account.
 * 
 * Request data:
 * {
 *   invoiceId: string,
 *   customerEmail: string,
 *   customerName: string,
 *   invoiceNumber: string,
 *   accessToken: string,
 *   amount: number,
 *   dueDate: string,
 *   smtpConfig: { host, port, secure, user, password }
 * }
 */
exports.sendInvoiceEmail = functions.https.onCall(async (data, context) => {
  try {
    if (!data.invoiceId || !data.customerEmail || !data.accessToken) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Missing required invoice data'
      );
    }

    // Build invoice view URL (adjust domain as needed)
    const invoiceUrl = `https://admin.shopsnports.com/invoice/${data.accessToken}`;
    
    // Professional invoice email template
    const htmlBody = `
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background-color: #2563eb; color: white; padding: 20px; text-align: center; }
          .content { padding: 30px; background-color: #f9fafb; }
          .invoice-details { background-color: white; padding: 20px; border-radius: 8px; margin: 20px 0; }
          .button { display: inline-block; padding: 12px 30px; background-color: #2563eb; color: white; text-decoration: none; border-radius: 5px; margin: 20px 0; }
          .footer { text-align: center; padding: 20px; font-size: 12px; color: #666; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>Invoice from ShopsNSports</h1>
          </div>
          <div class="content">
            <p>Dear ${data.customerName || 'Valued Customer'},</p>
            <p>Thank you for your business. Please find your invoice details below:</p>
            
            <div class="invoice-details">
              <p><strong>Invoice Number:</strong> ${data.invoiceNumber}</p>
              <p><strong>Amount Due:</strong> ₦${data.amount?.toLocaleString() || '0.00'}</p>
              <p><strong>Due Date:</strong> ${data.dueDate || 'Upon Receipt'}</p>
            </div>

            <p>To view and pay your invoice, please click the button below:</p>
            <center>
              <a href="${invoiceUrl}" class="button">View Invoice</a>
            </center>
            
            <p style="margin-top: 30px;">You can also copy this link: <br><a href="${invoiceUrl}">${invoiceUrl}</a></p>
            
            <p>If you have any questions, please don't hesitate to contact us.</p>
            
            <p>Best regards,<br>ShopsNSports Billing Team</p>
          </div>
          <div class="footer">
            <p>This is an automated email. Please do not reply to this message.</p>
            <p>&copy; 2026 ShopsNSports. All rights reserved.</p>
          </div>
        </div>
      </body>
      </html>
    `;

    const plainTextBody = `
Invoice from ShopsNSports

Dear ${data.customerName || 'Valued Customer'},

Thank you for your business. Please find your invoice details below:

Invoice Number: ${data.invoiceNumber}
Amount Due: ₦${data.amount?.toLocaleString() || '0.00'}
Due Date: ${data.dueDate || 'Upon Receipt'}

View your invoice: ${invoiceUrl}

If you have any questions, please don't hesitate to contact us.

Best regards,
ShopsNSports Billing Team

---
This is an automated email. Please do not reply to this message.
© 2026 ShopsNSports. All rights reserved.
    `;

    // Use the generic sendEmail function
    const result = await exports.sendEmail({
      to: data.customerEmail,
      subject: `Invoice ${data.invoiceNumber} from ShopsNSports`,
      htmlBody: htmlBody,
      plainTextBody: plainTextBody,
      emailType: 'invoice',
      smtpConfig: data.smtpConfig,
    }, context);

    // Update invoice with email sent status
    await admin.firestore()
      .collection('invoices')
      .doc(data.invoiceId)
      .update({
        emailSent: true,
        lastEmailSentAt: admin.firestore.FieldValue.serverTimestamp(),
        emailSentCount: admin.firestore.FieldValue.increment(1),
      });

    return result;

  } catch (error) {
    console.error('Invoice email sending failed:', error);
    throw error;
  }
});

/**
 * Send Push Notification
 * Callable function to send push notifications to specific device tokens or a topic.
 * Request data:
 * {
 *   tokens?: string[],
 *   topic?: string,
 *   title: string,
 *   body: string,
 *   data?: object
 * }
 */
exports.sendPushNotification = functions.https.onCall(async (data, context) => {
  try {
    if (!data || (!data.tokens && !data.topic)) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Provide either `tokens` array or `topic` string.'
      );
    }

    const title = data.title || 'Notification from ShopsNSports';
    const body = data.body || '';
    const payload = data.data || {};

    if (data.tokens && Array.isArray(data.tokens) && data.tokens.length > 0) {
      // Send to multiple tokens
      const message = {
        tokens: data.tokens,
        notification: { title, body },
        data: Object.assign({}, payload),
      };

      const response = await admin.messaging().sendMulticast(message);
      return { success: true, sentCount: response.successCount, failureCount: response.failureCount };
    }

    if (data.topic && typeof data.topic === 'string') {
      const message = {
        topic: data.topic,
        notification: { title, body },
        data: Object.assign({}, payload),
      };

      const response = await admin.messaging().send(message);
      return { success: true, response }; 
    }

    throw new functions.https.HttpsError('invalid-argument', 'No valid target for push notification');
  } catch (error) {
    console.error('Push notification failed:', error);
    throw new functions.https.HttpsError('internal', `Failed to send push notification: ${error.message}`);
  }
});

/**
 * Send Push Notification to User Segment
 * Sends notification to all users of a specific type (customer, affiliate, shipper)
 *
 * Request data:
 * {
 *   targetUserType: 'customer' | 'affiliate' | 'shipper' | 'all',
 *   title: string,
 *   body: string,
 *   category?: string,
 *   actionUrl?: string,
 *   imageUrl?: string,
 *   data?: object
 * }
 */
exports.sendNotificationToSegment = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
    }

    if (!data.targetUserType || !data.title || !data.body) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Missing required fields: targetUserType, title, body'
      );
    }

    // Get all users of the target type with FCM tokens
    const usersSnapshot = await admin.firestore()
      .collection('users')
      .where('roleType', '==', data.targetUserType)
      .where('fcmToken', '!=', null)
      .get();

    if (usersSnapshot.empty) {
      return { success: true, sentCount: 0, message: 'No users found with tokens' };
    }

    // Collect all tokens (deduplicate)
    const tokens = [...new Set(
      usersSnapshot.docs
        .map(doc => doc.data().fcmToken)
        .filter(token => token)
    )];

    // Send multicast (FCM limits to 500 tokens per call)
    const chunks = [];
    for (let i = 0; i < tokens.length; i += 500) {
      chunks.push(tokens.slice(i, i + 500));
    }

    let totalSent = 0;
    let totalFailed = 0;

    for (const tokenChunk of chunks) {
      const message = {
        tokens: tokenChunk,
        notification: {
          title: data.title,
          body: data.body,
        },
        data: {
          category: data.category || 'general',
          actionUrl: data.actionUrl || '',
          ...data.data,
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
            },
          },
        },
      };

      const response = await admin.messaging().sendMulticast(message);
      totalSent += response.successCount;
      totalFailed += response.failureCount;
    }

    // Store notification history
    const historyRef = admin.firestore().collection('push_notifications_history').doc();
    await historyRef.set({
      title: data.title,
      body: data.body,
      category: data.category || 'general',
      targetUserType: data.targetUserType,
      status: 'sent',
      sentBy: context.auth.uid,
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
      sentCount: totalSent,
      failedCount: totalFailed,
      actionUrl: data.actionUrl,
      imageUrl: data.imageUrl,
    });

    console.log(`Notification sent to ${totalSent} devices, ${totalFailed} failed`);

    return {
      success: true,
      sentCount: totalSent,
      failureCount: totalFailed,
      message: `Sent to ${data.targetUserType} users`,
    };
  } catch (error) {
    console.error('Send notification to segment failed:', error);
    throw new functions.https.HttpsError('internal', `Failed to send notification: ${error.message}`);
  }
});

/**
 * Get User FCM Tokens
 * Retrieves FCM tokens for a specific user
 */
exports.getUserTokens = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
    }

    const userId = data.userId || context.auth.uid;
    const userDoc = await admin.firestore().collection('users').doc(userId).get();

    if (!userDoc.exists) {
      return { tokens: [] };
    }

    const tokens = [];
    const fcmToken = userDoc.data().fcmToken;
    if (fcmToken) tokens.push(fcmToken);

    return { tokens };
  } catch (error) {
    console.error('Get user tokens failed:', error);
    throw new functions.https.HttpsError('internal', `Failed to get tokens: ${error.message}`);
  }
});

/**
 * Save FCM Token
 * Saves or updates a user's FCM token
 */
exports.saveFCMToken = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
    }

    if (!data.token) {
      throw new functions.https.HttpsError('invalid-argument', 'Token is required');
    }

    await admin.firestore().collection('users').doc(context.auth.uid).update({
      fcmToken: data.token,
      lastTokenUpdate: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { success: true };
  } catch (error) {
    console.error('Save FCM token failed:', error);
    throw new functions.https.HttpsError('internal', `Failed to save token: ${error.message}`);
  }
});

/**
 * ============== SUPER ADMIN FUNCTIONS ==============
 */

// Constants
const SUPER_ADMIN_EMAIL = 'admin0@shopsnports.com';
const ADMIN_USERS_COLLECTION = 'admin_users';
const RATE_LIMIT_WINDOW = 60 * 60 * 1000; // 1 hour in milliseconds
const RATE_LIMIT_MAX_REQUESTS = 5; // Max 5 admin creations per hour

// Rate limiting storage (in production, use Redis or Firestore)
const rateLimitStore = new Map();

/**
 * Check if IP is whitelisted for super admin operations
 * Returns true if IP is whitelisted or if whitelisting is disabled
 */
async function isIPWhitelisted(superAdminId, ipAddress) {
  try {
    // Get super admin document
    const adminDoc = await admin.firestore()
      .collection(ADMIN_USERS_COLLECTION)
      .doc(superAdminId)
      .get();

    if (!adminDoc.exists) {
      return false;
    }

    const adminData = adminDoc.data();

    // Check if IP whitelisting is enabled for this admin
    if (!adminData.ipWhitelistEnabled) {
      return true; // Whitelisting disabled, allow all
    }

    // Check if IP is in whitelist
    const whitelist = adminData.ipWhitelist || [];
    if (whitelist.length === 0) {
      return true; // Empty whitelist means allow all
    }

    // Check if IP matches any whitelist entry (supports CIDR notation)
    return whitelist.some(whitelistedIP => {
      // Exact match
      if (whitelistedIP === ipAddress) {
        return true;
      }

      // CIDR notation match (e.g., 192.168.1.0/24)
      if (whitelistedIP.includes('/')) {
        return isIPInCIDR(ipAddress, whitelistedIP);
      }

      return false;
    });
  } catch (error) {
    console.error('Error checking IP whitelist:', error);
    return false; // Fail secure
  }
}

/**
 * Check if IP is within CIDR range
 */
function isIPInCIDR(ip, cidr) {
  const [network, prefixLength] = cidr.split('/');
  const mask = parseInt(prefixLength, 10);

  const ipParts = ip.split('.').map(Number);
  const networkParts = network.split('.').map(Number);

  // Convert to binary
  const ipBinary = ipParts.reduce((acc, octet) => (acc << 8) | octet, 0) >>> 0;
  const networkBinary = networkParts.reduce((acc, octet) => (acc << 8) | octet, 0) >>> 0;

  const maskBinary = (0xFFFFFFFF << (32 - mask)) >>> 0;

  return (ipBinary & maskBinary) === (networkBinary & maskBinary);
}

/**
 * Check rate limit for admin creation
 * Returns true if rate limit exceeded, false otherwise
 */
function checkRateLimit(superAdminId) {
  const now = Date.now();
  const userRequests = rateLimitStore.get(superAdminId) || [];

  // Filter out requests outside the time window
  const recentRequests = userRequests.filter(timestamp => now - timestamp < RATE_LIMIT_WINDOW);

  // Check if limit exceeded
  if (recentRequests.length >= RATE_LIMIT_MAX_REQUESTS) {
    return true;
  }

  // Add current request
  recentRequests.push(now);
  rateLimitStore.set(superAdminId, recentRequests);

  return false;
}

/**
 * Check if email already exists in admin_users collection
 */
async function checkEmailExists(email) {
  try {
    const snapshot = await admin.firestore()
      .collection(ADMIN_USERS_COLLECTION)
      .where('email', '==', email)
      .limit(1)
      .get();

    return !snapshot.empty;
  } catch (error) {
    console.error('Error checking email existence:', error);
    return false;
  }
}

/**
 * Create Admin
 * Creates a new admin user with Firebase Auth + Firestore
 *
 * Request data:
 * {
 *   email: string,
 *   displayName: string,
 *   role: 'admin' | 'sub_admin',
 *   permissions: { module: boolean, ... },
 *   smtpConfig: { ... } (for sending email),
 *   expiresAt: string (ISO date string, optional) - Account expiration date
 * }
 */
exports.createAdmin = functions.https.onCall(async (data, context) => {
  try {
    // Verify caller is super admin
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const callerDoc = await admin.firestore().collection(ADMIN_USERS_COLLECTION).doc(context.auth.uid).get();
    if (!callerDoc.exists || callerDoc.data().role !== 'super_admin') {
      throw new functions.https.HttpsError('permission-denied', 'Only super admins can create admins');
    }

    // Check IP whitelist
    const ipAddress = context.rawRequest.ip;
    const isWhitelisted = await isIPWhitelisted(context.auth.uid, ipAddress);
    if (!isWhitelisted) {
      throw new functions.https.HttpsError('permission-denied',
        'Access denied: Your IP address is not whitelisted for admin operations');
    }

    // Validate input
    if (!data.email || !data.displayName || !data.permissions) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing required fields: email, displayName, permissions');
    }

    // Validate email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(data.email)) {
      throw new functions.https.HttpsError('invalid-argument', 'Invalid email format');
    }

    // Validate role
    const role = data.role || 'admin';
    if (role !== 'admin' && role !== 'sub_admin') {
      throw new functions.https.HttpsError('invalid-argument', 'Invalid role. Must be "admin" or "sub_admin"');
    }

    // Check rate limit
    if (checkRateLimit(context.auth.uid)) {
      throw new functions.https.HttpsError('resource-exhausted',
        `Rate limit exceeded. Maximum ${RATE_LIMIT_MAX_REQUESTS} admin creations per hour.`);
    }

    // Check for duplicate email
    const emailExists = await checkEmailExists(data.email);
    if (emailExists) {
      throw new functions.https.HttpsError('already-exists',
        'An admin with this email already exists');
    }

    // Generate a temporary password (will be reset via email link)
    const tempPassword = Math.random().toString(36).slice(-8) +
                         Math.random().toString(36).slice(-8) +
                         '!@#';

    // Create Firebase Auth user
    const userRecord = await admin.auth().createUser({
      email: data.email,
      password: tempPassword,
      displayName: data.displayName,
      emailVerified: false,
      disabled: false,
    });

    // Set custom claims
    await admin.auth().setCustomUserClaims(userRecord.uid, {
      role: role,
    });

    // Save to Firestore (using admin_users collection)
    const adminData = {
      id: userRecord.uid,
      email: data.email,
      displayName: data.displayName,
      role: role,
      status: 'active',
      permissions: data.permissions,
      createdBy: context.auth.uid,
      createdAt: admin.firestore.Timestamp.now(),
      lastLogin: null,
      requirePasswordChange: true,
      expiresAt: data.expiresAt ? admin.firestore.Timestamp.fromDate(new Date(data.expiresAt)) : null,
    };

    await admin.firestore().collection(ADMIN_USERS_COLLECTION).doc(userRecord.uid).set(adminData);

    // Log activity
    await admin.firestore().collection('admin_activity_logs').add({
      adminId: context.auth.uid,
      adminEmail: callerDoc.data().email,
      action: 'created_admin',
      itemId: userRecord.uid,
      itemName: data.displayName,
      details: {
        email: data.email,
        role: role,
        permissions: data.permissions
      },
      timestamp: admin.firestore.Timestamp.now(),
      success: true,
    });

    // Generate password reset link
    const passwordResetLink = await admin.auth().generatePasswordResetLink(data.email);

    // Generate email verification link
    const emailVerificationLink = await admin.auth().generateEmailVerificationLink(data.email);

    // Send email with password reset link
    if (data.smtpConfig) {
      const transporter = nodemailer.createTransport({
        host: data.smtpConfig.host,
        port: data.smtpConfig.port,
        secure: data.smtpConfig.secure,
        auth: {
          user: data.smtpConfig.user,
          pass: data.smtpConfig.password,
        },
      });

      const htmlBody = `
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Welcome to ShopsNPorts Admin Dashboard</title>
          <style>
            body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; line-height: 1.6; color: #333; margin: 0; padding: 0; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: linear-gradient(135deg, #0A2A66, #1a4a8c); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
            .content { background-color: #f9fafb; padding: 30px; border-radius: 0 0 10px 10px; }
            .info-box { background-color: white; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #0A2A66; }
            .button { display: inline-block; padding: 14px 28px; background-color: #0A2A66; color: white; text-decoration: none; border-radius: 6px; font-weight: bold; margin: 20px 0; }
            .footer { text-align: center; padding: 20px; font-size: 12px; color: #666; }
            .warning { background-color: #fff3cd; border: 1px solid #ffc107; border-radius: 4px; padding: 12px; margin: 15px 0; }
            .checklist { background-color: #e8f4fd; border-radius: 8px; padding: 20px; margin: 20px 0; }
            .checklist-item { display: flex; align-items: center; margin: 10px 0; }
            .checklist-item::before { content: "✓"; color: #0A2A66; font-weight: bold; margin-right: 10px; font-size: 18px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>Welcome to ShopsNPorts Admin Dashboard</h1>
            </div>
            <div class="content">
              <p>Dear <strong>${data.displayName}</strong>,</p>
              <p>Your admin account has been created by the super administrator. You now have access to the ShopsNPorts Admin Dashboard.</p>

              <div class="info-box">
                <p><strong>Account Details:</strong></p>
                <p><strong>Email:</strong> ${data.email}</p>
                <p><strong>Role:</strong> ${role === 'sub_admin' ? 'Sub-Admin' : 'Admin'}</p>
                <p><strong>Status:</strong> Active</p>
              </div>

              <div class="warning">
                <strong>⚠️ Security Notice:</strong> For your security, you must verify your email and set your password before accessing the dashboard.
              </div>

              <p><strong>To get started, please follow these steps:</strong></p>

              <div class="checklist">
                <div class="checklist-item">Click the button below to verify your email</div>
                <div class="checklist-item">Set your password on the verification page</div>
                <div class="checklist-item">Choose a strong password (minimum 8 characters)</div>
                <div class="checklist-item">Log in to the admin dashboard</div>
                <div class="checklist-item">Complete your profile setup</div>
              </div>

              <center>
                <a href="${emailVerificationLink}" class="button">Verify Email & Set Password</a>
              </center>

              <p style="text-align: center; margin: 20px 0;">or copy this link:</p>
              <p style="text-align: center; word-break: break-all; color: #0A2A66; font-size: 12px;">${emailVerificationLink}</p>

              <p><strong>Important Information:</strong></p>
              <ul>
                <li>This email verification link will expire in 24 hours</li>
                <li>You must verify your email before accessing the dashboard</li>
                <li>If you don't verify your email within 24 hours, please contact support</li>
                <li>Never share your password with anyone</li>
                <li>Use a strong, unique password for your account</li>
              </ul>

              <p><strong>Login URL:</strong> <a href="https://admin.shopsnports.com">https://admin.shopsnports.com</a></p>

              <p>If you have any questions or need assistance, please contact our support team.</p>

              <p>Best regards,<br>The ShopsNPorts Team</p>
            </div>
            <div class="footer">
              <p>This is an automated email. Please do not reply to this message.</p>
              <p>&copy; 2026 ShopsNPorts. All rights reserved.</p>
            </div>
          </div>
        </body>
        </html>
      `;

      await transporter.sendMail({
        from: data.smtpConfig.user,
        to: data.email,
        subject: 'Your Admin Account Created - Set Your Password - ShopsNPorts',
        html: htmlBody,
      });
    }

    return {
      success: true,
      adminId: userRecord.uid,
      email: data.email,
      role: role,
      message: 'Admin created successfully. Email verification link sent to email.',
    };
  } catch (error) {
    console.error('Create admin failed:', error);

    // Handle specific Firebase Auth errors
    if (error.code === 'auth/email-already-exists') {
      throw new functions.https.HttpsError('already-exists',
        'An account with this email already exists');
    }
    if (error.code === 'auth/invalid-email') {
      throw new functions.https.HttpsError('invalid-argument',
        'Invalid email address');
    }
    if (error.code === 'auth/weak-password') {
      throw new functions.https.HttpsError('invalid-argument',
        'Password is too weak');
    }

    throw new functions.https.HttpsError('internal', `Failed to create admin: ${error.message}`);
  }
});

/**
 * Disable Admin
 * Disables an admin account
 */
exports.disableAdmin = functions.https.onCall(async (data, context) => {
  try {
    // Verify caller is super admin
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const callerDoc = await admin.firestore().collection(ADMIN_USERS_COLLECTION).doc(context.auth.uid).get();
    if (!callerDoc.exists || callerDoc.data().role !== 'super_admin') {
      throw new functions.https.HttpsError('permission-denied', 'Only super admins can disable admins');
    }

    // Validate input
    if (!data.adminId) {
      throw new functions.https.HttpsError('invalid-argument', 'Admin ID required');
    }

    // Get target admin details
    const targetAdmin = await admin.firestore().collection(ADMIN_USERS_COLLECTION).doc(data.adminId).get();

    if (!targetAdmin.exists) {
      throw new functions.https.HttpsError('not-found', 'Admin not found');
    }

    // Prevent disabling the root super admin
    if (targetAdmin.data().email === SUPER_ADMIN_EMAIL) {
      throw new functions.https.HttpsError('permission-denied',
        'Cannot disable the root super admin account');
    }

    // Prevent disabling yourself
    if (data.adminId === context.auth.uid) {
      throw new functions.https.HttpsError('permission-denied',
        'Cannot disable your own account');
    }

    // Update Firebase Auth user
    await admin.auth().updateUser(data.adminId, {
      disabled: true,
    });

    // Update Firestore
    await admin.firestore().collection(ADMIN_USERS_COLLECTION).doc(data.adminId).update({
      status: 'disabled',
    });

    // Log activity
    await admin.firestore().collection('admin_activity_logs').add({
      adminId: context.auth.uid,
      adminEmail: callerDoc.data().email,
      action: 'disabled_admin',
      itemId: data.adminId,
      itemName: targetAdmin.data().displayName,
      details: { targetEmail: targetAdmin.data().email },
      timestamp: admin.firestore.Timestamp.now(),
      success: true,
    });

    return { success: true, message: 'Admin disabled successfully' };
  } catch (error) {
    console.error('Disable admin failed:', error);
    throw new functions.https.HttpsError('internal', `Failed to disable admin: ${error.message}`);
  }
});

/**
 * Delete Admin
 * Permanently deletes an admin account
 */
exports.deleteAdmin = functions.https.onCall(async (data, context) => {
  try {
    // Verify caller is super admin
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const callerDoc = await admin.firestore().collection(ADMIN_USERS_COLLECTION).doc(context.auth.uid).get();
    if (!callerDoc.exists || callerDoc.data().role !== 'super_admin') {
      throw new functions.https.HttpsError('permission-denied', 'Only super admins can delete admins');
    }

    // Validate input
    if (!data.adminId) {
      throw new functions.https.HttpsError('invalid-argument', 'Admin ID required');
    }

    // Get admin details before deleting
    const targetAdmin = await admin.firestore().collection(ADMIN_USERS_COLLECTION).doc(data.adminId).get();

    if (!targetAdmin.exists) {
      throw new functions.https.HttpsError('not-found', 'Admin not found');
    }

    // Prevent deleting the root super admin
    if (targetAdmin.data().email === SUPER_ADMIN_EMAIL) {
      throw new functions.https.HttpsError('permission-denied',
        'Cannot delete the root super admin account');
    }

    // Prevent deleting yourself
    if (data.adminId === context.auth.uid) {
      throw new functions.https.HttpsError('permission-denied',
        'Cannot delete your own account');
    }

    // Delete Firebase Auth user
    await admin.auth().deleteUser(data.adminId);

    // Delete Firestore user doc
    await admin.firestore().collection(ADMIN_USERS_COLLECTION).doc(data.adminId).delete();

    // Log activity (keep logs for audit trail)
    await admin.firestore().collection('admin_activity_logs').add({
      adminId: context.auth.uid,
      adminEmail: callerDoc.data().email,
      action: 'deleted_admin',
      itemId: data.adminId,
      itemName: targetAdmin.data().displayName,
      details: { targetEmail: targetAdmin.data().email },
      timestamp: admin.firestore.Timestamp.now(),
      success: true,
    });

    return { success: true, message: 'Admin deleted permanently' };
  } catch (error) {
    console.error('Delete admin failed:', error);
    throw new functions.https.HttpsError('internal', `Failed to delete admin: ${error.message}`);
  }
});

/**
 * Undo Recent Admin Creation
 * Deletes a recently created admin (within 5 minutes of creation)
 * This is for undoing accidental admin creations
 */
exports.undoAdminCreation = functions.https.onCall(async (data, context) => {
  try {
    // Verify caller is super admin
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const callerDoc = await admin.firestore().collection(ADMIN_USERS_COLLECTION).doc(context.auth.uid).get();
    if (!callerDoc.exists || callerDoc.data().role !== 'super_admin') {
      throw new functions.https.HttpsError('permission-denied', 'Only super admins can undo admin creation');
    }

    // Validate input
    if (!data.adminId) {
      throw new functions.https.HttpsError('invalid-argument', 'Admin ID required');
    }

    // Get admin details
    const targetAdmin = await admin.firestore().collection(ADMIN_USERS_COLLECTION).doc(data.adminId).get();

    if (!targetAdmin.exists) {
      throw new functions.https.HttpsError('not-found', 'Admin not found');
    }

    // Check if admin was created by the current super admin
    if (targetAdmin.data().createdBy !== context.auth.uid) {
      throw new functions.https.HttpsError('permission-denied',
        'Can only undo admins that you created');
    }

    // Check if admin is within the 5-minute undo window
    const createdAt = targetAdmin.data().createdAt;
    const now = admin.firestore.Timestamp.now();
    const fiveMinutesInMs = 5 * 60 * 1000;
    const timeSinceCreation = now.toMillis() - createdAt.toMillis();

    if (timeSinceCreation > fiveMinutesInMs) {
      throw new functions.https.HttpsError('failed-precondition',
        'Undo window has expired. Admins can only be undone within 5 minutes of creation.');
    }

    // Prevent undoing the root super admin
    if (targetAdmin.data().email === SUPER_ADMIN_EMAIL) {
      throw new functions.https.HttpsError('permission-denied',
        'Cannot undo the root super admin account');
    }

    // Delete Firebase Auth user
    await admin.auth().deleteUser(data.adminId);

    // Delete Firestore user doc
    await admin.firestore().collection(ADMIN_USERS_COLLECTION).doc(data.adminId).delete();

    // Log activity
    await admin.firestore().collection('admin_activity_logs').add({
      adminId: context.auth.uid,
      adminEmail: callerDoc.data().email,
      action: 'undone_admin_creation',
      itemId: data.adminId,
      itemName: targetAdmin.data().displayName,
      details: {
        targetEmail: targetAdmin.data().email,
        timeSinceCreation: `${Math.round(timeSinceCreation / 1000)}s`,
      },
      timestamp: admin.firestore.Timestamp.now(),
      success: true,
    });

    return {
      success: true,
      message: 'Admin creation undone successfully',
      timeSinceCreation: `${Math.round(timeSinceCreation / 1000)}s`,
    };
  } catch (error) {
    console.error('Undo admin creation failed:', error);

    // Handle specific Firebase Auth errors
    if (error.code === 'auth/user-not-found') {
      throw new functions.https.HttpsError('not-found',
        'Admin account not found (may have already been deleted)');
    }

    throw new functions.https.HttpsError('internal', `Failed to undo admin creation: ${error.message}`);
  }
});

/**
 * Get Recent Admin Creations
 * Returns admins created by the current super admin within the undo window
 */
exports.getRecentAdminCreations = functions.https.onCall(async (data, context) => {
  try {
    // Verify caller is super admin
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const callerDoc = await admin.firestore().collection(ADMIN_USERS_COLLECTION).doc(context.auth.uid).get();
    if (!callerDoc.exists || callerDoc.data().role !== 'super_admin') {
      throw new functions.https.HttpsError('permission-denied', 'Only super admins can view recent creations');
    }

    const now = admin.firestore.Timestamp.now();
    const fiveMinutesAgo = new Date(now.toMillis() - (5 * 60 * 1000));

    // Get admins created by this super admin within the last 5 minutes
    const snapshot = await admin.firestore()
      .collection(ADMIN_USERS_COLLECTION)
      .where('createdBy', '==', context.auth.uid)
      .where('createdAt', '>=', admin.firestore.Timestamp.fromDate(fiveMinutesAgo))
      .orderBy('createdAt', 'descending')
      .get();

    const recentCreations = snapshot.docs.map(doc => {
      const data = doc.data();
      const createdAt = data.createdAt.toDate();
      const timeSinceCreation = now.toMillis() - data.createdAt.toMillis();
      const remainingTime = (5 * 60 * 1000) - timeSinceCreation;

      return {
        id: doc.id,
        email: data.email,
        displayName: data.displayName,
        role: data.role,
        status: data.status,
        permissions: data.permissions,
        createdAt: data.createdAt.toDate(),
        timeSinceCreation: Math.round(timeSinceCreation / 1000), // in seconds
        remainingTime: Math.max(0, Math.round(remainingTime / 1000)), // in seconds
        canUndo: remainingTime > 0,
      };
    });

    return {
      success: true,
      recentCreations: recentCreations,
      count: recentCreations.length,
    };
  } catch (error) {
    console.error('Get recent admin creations failed:', error);
    throw new functions.https.HttpsError('internal', `Failed to get recent creations: ${error.message}`);
  }
});

/**
 * Update Admin Permissions
 * Updates an admin's module permissions
 */
exports.updateAdminPermissions = functions.https.onCall(async (data, context) => {
  try {
    // Verify caller is super admin
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const callerDoc = await admin.firestore().collection(ADMIN_USERS_COLLECTION).doc(context.auth.uid).get();
    if (!callerDoc.exists || callerDoc.data().role !== 'super_admin') {
      throw new functions.https.HttpsError('permission-denied', 'Only super admins can update permissions');
    }

    // Validate input
    if (!data.adminId || !data.permissions) {
      throw new functions.https.HttpsError('invalid-argument', 'Admin ID and permissions required');
    }

    // Get target admin details
    const targetAdmin = await admin.firestore().collection(ADMIN_USERS_COLLECTION).doc(data.adminId).get();

    if (!targetAdmin.exists) {
      throw new functions.https.HttpsError('not-found', 'Admin not found');
    }

    // Prevent modifying super admin permissions
    if (targetAdmin.data().role === 'super_admin') {
      throw new functions.https.HttpsError('permission-denied',
        'Cannot modify super admin permissions');
    }

    // Update Firestore
    await admin.firestore().collection(ADMIN_USERS_COLLECTION).doc(data.adminId).update({
      permissions: data.permissions,
    });

    // Log activity
    await admin.firestore().collection('admin_activity_logs').add({
      adminId: context.auth.uid,
      adminEmail: callerDoc.data().email,
      action: 'updated_admin_permissions',
      itemId: data.adminId,
      itemName: targetAdmin.data().displayName,
      details: {
        targetEmail: targetAdmin.data().email,
        permissions: data.permissions
      },
      timestamp: admin.firestore.Timestamp.now(),
      success: true,
    });

    return { success: true, message: 'Permissions updated successfully' };
  } catch (error) {
    console.error('Update permissions failed:', error);
    throw new functions.https.HttpsError('internal', `Failed to update permissions: ${error.message}`);
  }
});

/**
 * Log Admin Activity
 * Logs admin activities to the activity log collection
 */
exports.logAdminActivity = functions.https.onCall(async (data, context) => {
  try {
    // Validate required fields
    if (!data.adminId || !data.action) {
      throw new functions.https.HttpsError('invalid-argument', 'Admin ID and action required');
    }

    // Get admin email
    const adminDoc = await admin.firestore().collection(ADMIN_USERS_COLLECTION).doc(data.adminId).get();
    const adminEmail = adminDoc.data()?.email || 'unknown';

    // Save to Firestore
    const logEntry = {
      adminId: data.adminId,
      adminEmail: adminEmail,
      action: data.action,
      itemId: data.itemId || null,
      itemName: data.itemName || null,
      details: data.details || null,
      timestamp: admin.firestore.Timestamp.now(),
      ipAddress: data.ipAddress || null,
      success: data.success !== false,
    };

    const docRef = await admin.firestore().collection('admin_activity_logs').add(logEntry);

    return { success: true, logId: docRef.id };
  } catch (error) {
    console.error('Log activity failed:', error);
    throw new functions.https.HttpsError('internal', `Failed to log activity: ${error.message}`);
  }
});

// ============================================================================
// AFFILIATE EMAIL TEMPLATES
// ============================================================================

const affiliateEmailTemplates = {
  /**
   * Application Submitted Confirmation
   */
  applicationSubmitted: (data) => ({
    subject: 'Your Affiliate Application Received - ShopsNSports',
    html: `
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: linear-gradient(135deg, #0A2A66, #1a4a8c); color: white; padding: 30px; text-align: center; }
          .content { padding: 30px; background-color: #f9fafb; }
          .status-badge { display: inline-block; padding: 8px 16px; background-color: #f59e0b; color: white; border-radius: 20px; font-weight: bold; }
          .info-box { background-color: white; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #0A2A66; }
          .footer { text-align: center; padding: 20px; font-size: 12px; color: #666; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>Affiliate Application Received</h1>
          </div>
          <div class="content">
            <p>Dear ${data.fullName},</p>
            <p>Thank you for applying to become a ShopsNSports Affiliate! We're excited to have you on board.</p>

            <div class="info-box">
              <p><strong>Application Reference:</strong> ${data.affiliateId.substring(0, 8).toUpperCase()}</p>
              <p><strong>Submitted On:</strong> ${new Date().toLocaleDateString()}</p>
              <p><strong>Status:</strong> <span class="status-badge">Under Review</span></p>
            </div>

            <p><strong>What happens next?</strong></p>
            <ul>
              <li>Our team will review your application within 2-3 business days</li>
              <li>You'll receive an email once your application is approved</li>
              <li>Once approved, you can start sharing and earning commissions</li>
            </ul>

            <p>If you have any questions about your application, please contact us at affiliates@shopsnports.com</p>

            <p>Best regards,<br>The ShopsNSports Team</p>
          </div>
          <div class="footer">
            <p>This is an automated email. Please do not reply to this message.</p>
            <p>&copy; 2026 ShopsNSports. All rights reserved.</p>
          </div>
        </div>
      </body>
      </html>
    `,
    text: `
Affiliate Application Received - ShopsNSports

Dear ${data.fullName},

Thank you for applying to become a ShopsNSports Affiliate! We're excited to have you on board.

Application Reference: ${data.affiliateId.substring(0, 8).toUpperCase()}
Submitted On: ${new Date().toLocaleDateString()}
Status: Under Review

What happens next?
- Our team will review your application within 2-3 business days
- You'll receive an email once your application is approved
- Once approved, you can start sharing and earning commissions

If you have any questions about your application, please contact us at affiliates@shopsnports.com

Best regards,
The ShopsNSports Team

---
This is an automated email. Please do not reply to this message.
© 2026 ShopsNSports. All rights reserved.
    `
  }),

  /**
   * Application Approved
   */
  applicationApproved: (data) => ({
    subject: 'Congratulations! Your Affiliate Application is Approved - ShopsNSports',
    html: `
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: linear-gradient(135deg, #059669, #10b981); color: white; padding: 30px; text-align: center; }
          .content { padding: 30px; background-color: #f9fafb; }
          .success-badge { display: inline-block; padding: 8px 16px; background-color: #10b981; color: white; border-radius: 20px; font-weight: bold; }
          .cta-button { display: inline-block; padding: 14px 28px; background-color: #0A2A66; color: white; text-decoration: none; border-radius: 6px; font-weight: bold; margin: 20px 0; }
          .info-box { background-color: white; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #10b981; }
          .footer { text-align: center; padding: 20px; font-size: 12px; color: #666; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>Application Approved!</h1>
          </div>
          <div class="content">
            <p>Dear ${data.fullName},</p>
            <p>Great news! Your affiliate application has been approved. You're now officially part of the ShopsNSports Affiliate Program!</p>

            <div class="info-box">
              <p><strong>Affiliate ID:</strong> ${data.affiliateId}</p>
              <p><strong>Commission Rate:</strong> ${data.commissionRate}%</p>
              <p><strong>Approved On:</strong> ${new Date().toLocaleDateString()}</p>
              <p><span class="success-badge">ACTIVE</span></p>
            </div>

            <p><strong>Getting Started:</strong></p>
            <ul>
              <li>Log into your affiliate dashboard</li>
              <li>Complete your payout settings (bank account details)</li>
              <li>Create shareable shipping forms</li>
              <li>Start sharing and earning commissions!</li>
            </ul>

            <center>
              <a href="${data.dashboardUrl}" class="cta-button">Access Your Dashboard</a>
            </center>

            <p>Welcome aboard! We're thrilled to have you as a partner.</p>
            <p>Best regards,<br>The ShopsNSports Team</p>
          </div>
          <div class="footer">
            <p>This is an automated email. Please do not reply to this message.</p>
            <p>&copy; 2026 ShopsNSports. All rights reserved.</p>
          </div>
        </div>
      </body>
      </html>
    `,
    text: `
Congratulations! Your Affiliate Application is Approved - ShopsNSports

Dear ${data.fullName},

Great news! Your affiliate application has been approved. You're now officially part of the ShopsNSports Affiliate Program!

Affiliate ID: ${data.affiliateId}
Commission Rate: ${data.commissionRate}%
Approved On: ${new Date().toLocaleDateString()}
Status: ACTIVE

Getting Started:
- Log into your affiliate dashboard
- Complete your payout settings (bank account details)
- Create shareable shipping forms
- Start sharing and earning commissions!

Access your dashboard: ${data.dashboardUrl}

Welcome aboard! We're thrilled to have you as a partner.
Best regards,
The ShopsNSports Team

---
This is an automated email. Please do not reply to this message.
© 2026 ShopsNSports. All rights reserved.
    `
  }),

  /**
   * Application Rejected
   */
  applicationRejected: (data) => ({
    subject: 'Affiliate Application Update - ShopsNSports',
    html: `
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: linear-gradient(135deg, #dc2626, #ef4444); color: white; padding: 30px; text-align: center; }
          .content { padding: 30px; background-color: #f9fafb; }
          .rejected-badge { display: inline-block; padding: 8px 16px; background-color: #dc2626; color: white; border-radius: 20px; font-weight: bold; }
          .info-box { background-color: white; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #dc2626; }
          .footer { text-align: center; padding: 20px; font-size: 12px; color: #666; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>Application Update</h1>
          </div>
          <div class="content">
            <p>Dear ${data.fullName},</p>
            <p>Thank you for your interest in the ShopsNSports Affiliate Program. After careful review, we're sorry to inform you that your application was not approved at this time.</p>

            <div class="info-box">
              <p><strong>Reference:</strong> ${data.affiliateId.substring(0, 8).toUpperCase()}</p>
              <p><span class="rejected-badge">NOT APPROVED</span></p>
              ${data.reason ? `<p><strong>Reason:</strong> ${data.reason}</p>` : ''}
            </div>

            <p><strong>This is not the end!</strong></p>
            <ul>
              <li>You may reapply after addressing the feedback provided</li>
              <li>Common reasons for rejection include incomplete information or policy non-compliance</li>
              <li>Contact us at affiliates@shopsnports.com if you'd like more details</li>
            </ul>

            <p>We encourage you to apply again in the future when circumstances change.</p>

            <p>Best regards,<br>The ShopsNSports Team</p>
          </div>
          <div class="footer">
            <p>This is an automated email. Please do not reply to this message.</p>
            <p>&copy; 2026 ShopsNSports. All rights reserved.</p>
          </div>
        </div>
      </body>
      </html>
    `,
    text: `
Affiliate Application Update - ShopsNSports

Dear ${data.fullName},

Thank you for your interest in the ShopsNSports Affiliate Program. After careful review, we're sorry to inform you that your application was not approved at this time.

Reference: ${data.affiliateId.substring(0, 8).toUpperCase()}
Status: NOT APPROVED
${data.reason ? `Reason: ${data.reason}` : ''}

This is not the end!
- You may reapply after addressing the feedback provided
- Common reasons for rejection include incomplete information or policy non-compliance
- Contact us at affiliates@shopsnports.com if you'd like more details

We encourage you to apply again in the future when circumstances change.

Best regards,
The ShopsNSports Team

---
This is an automated email. Please do not reply to this message.
© 2026 ShopsNSports. All rights reserved.
    `
  }),

  /**
   * Payout Requested
   */
  payoutRequested: (data) => ({
    subject: 'Payout Request Received - ShopsNSports',
    html: `
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: linear-gradient(135deg, #0A2A66, #1a4a8c); color: white; padding: 30px; text-align: center; }
          .content { padding: 30px; background-color: #f9fafb; }
          .info-box { background-color: white; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #0A2A66; }
          .amount { font-size: 28px; font-weight: bold; color: #059669; }
          .footer { text-align: center; padding: 20px; font-size: 12px; color: #666; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>Payout Request Received</h1>
          </div>
          <div class="content">
            <p>Dear ${data.fullName},</p>
            <p>We've received your payout request and it's currently being processed.</p>

            <div class="info-box">
              <p><strong>Request ID:</strong> ${data.payoutId}</p>
              <p><strong>Amount:</strong> <span class="amount">${data.currency} ${data.amount.toLocaleString()}</span></p>
              <p><strong>Requested On:</strong> ${new Date().toLocaleDateString()}</p>
              <p><strong>Status:</strong> Processing</p>
            </div>

            <p><strong>Expected Timeline:</strong></p>
            <ul>
              <li>Payouts are typically processed within 2-3 business days</li>
              <li>Bank transfers may take 3-5 additional business days</li>
              <li>You'll receive a confirmation email once the payout is completed</li>
            </ul>

            <p>Track your payout status in your affiliate dashboard.</p>

            <p>Best regards,<br>The ShopsNSports Team</p>
          </div>
          <div class="footer">
            <p>This is an automated email. Please do not reply to this message.</p>
            <p>&copy; 2026 ShopsNSports. All rights reserved.</p>
          </div>
        </div>
      </body>
      </html>
    `,
    text: `
Payout Request Received - ShopsNSports

Dear ${data.fullName},

We've received your payout request and it's currently being processed.

Request ID: ${data.payoutId}
Amount: ${data.currency} ${data.amount.toLocaleString()}
Requested On: ${new Date().toLocaleDateString()}
Status: Processing

Expected Timeline:
- Payouts are typically processed within 2-3 business days
- Bank transfers may take 3-5 additional business days
- You'll receive a confirmation email once the payout is completed

Track your payout status in your affiliate dashboard.

Best regards,
The ShopsNSports Team

---
This is an automated email. Please do not reply to this message.
© 2026 ShopsNSports. All rights reserved.
    `
  }),

  /**
   * Payout Completed
   */
  payoutCompleted: (data) => ({
    subject: 'Payout Completed! - ShopsNSports',
    html: `
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: linear-gradient(135deg, #059669, #10b981); color: white; padding: 30px; text-align: center; }
          .content { padding: 30px; background-color: #f9fafb; }
          .success-badge { display: inline-block; padding: 8px 16px; background-color: #10b981; color: white; border-radius: 20px; font-weight: bold; }
          .info-box { background-color: white; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #10b981; }
          .amount { font-size: 32px; font-weight: bold; color: #059669; }
          .footer { text-align: center; padding: 20px; font-size: 12px; color: #666; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>Payout Completed!</h1>
          </div>
          <div class="content">
            <p>Dear ${data.fullName},</p>
            <p>Great news! Your payout has been successfully processed and sent.</p>

            <div class="info-box">
              <p><strong>Payout ID:</strong> ${data.payoutId}</p>
              <p><strong>Amount Sent:</strong> <span class="amount">${data.currency} ${data.amount.toLocaleString()}</span></p>
              <p><strong>Method:</strong> ${data.paymentMethod.replace(/_/g, ' ').toUpperCase()}</p>
              <p><strong>Transaction Ref:</strong> ${data.transactionReference || 'N/A'}</p>
              <p><strong>Completed On:</strong> ${new Date().toLocaleDateString()}</p>
              <p><span class="success-badge">PAID</span></p>
            </div>

            ${data.nextPayoutDate ? `<p><strong>Next Payout Date:</strong> ${new Date(data.nextPayoutDate).toLocaleDateString()}</p>` : ''}

            <p>Thank you for your continued partnership!</p>

            <p>Best regards,<br>The ShopsNSports Team</p>
          </div>
          <div class="footer">
            <p>This is an automated email. Please do not reply to this message.</p>
            <p>&copy; 2026 ShopsNSports. All rights reserved.</p>
          </div>
        </div>
      </body>
      </html>
    `,
    text: `
Payout Completed! - ShopsNSports

Dear ${data.fullName},

Great news! Your payout has been successfully processed and sent.

Payout ID: ${data.payoutId}
Amount Sent: ${data.currency} ${data.amount.toLocaleString()}
Method: ${data.paymentMethod.replace(/_/g, ' ').toUpperCase()}
Transaction Ref: ${data.transactionReference || 'N/A'}
Completed On: ${new Date().toLocaleDateString()}
Status: PAID

${data.nextPayoutDate ? `Next Payout Date: ${new Date(data.nextPayoutDate).toLocaleDateString()}` : ''}

Thank you for your continued partnership!

Best regards,
The ShopsNSports Team

---
This is an automated email. Please do not reply to this message.
© 2026 ShopsNSports. All rights reserved.
    `
  }),

  /**
   * Commission Earned Notification
   */
  commissionEarned: (data) => ({
    subject: `You Earned ${data.currency} ${data.commission.toLocaleString()}! - ShopsNSports`,
    html: `
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: linear-gradient(135deg, #0A2A66, #1a4a8c); color: white; padding: 30px; text-align: center; }
          .content { padding: 30px; background-color: #f9fafb; }
          .success-box { background-color: #d1fae5; padding: 20px; border-radius: 8px; text-align: center; margin: 20px 0; }
          .amount { font-size: 36px; font-weight: bold; color: #059669; }
          .footer { text-align: center; padding: 20px; font-size: 12px; color: #666; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>You Earned Commission!</h1>
          </div>
          <div class="content">
            <p>Dear ${data.fullName},</p>
            <p>Congratulations! You've just earned a commission from a successful shipment.</p>

            <div class="success-box">
              <p>Commission Earned</p>
              <p class="amount">${data.currency} ${data.commission.toLocaleString()}</p>
            </div>

            <p><strong>Shipment Details:</strong></p>
            <ul>
              <li>Tracking Number: ${data.trackingNumber}</li>
              <li>Shipment Value: ${data.currency} ${data.shipmentValue.toLocaleString()}</li>
              <li>Your Commission Rate: ${data.commissionRate}%</li>
            </ul>

            <p><strong>Your Earnings Summary:</strong></p>
            <ul>
              <li>Total Earnings: ${data.currency} ${data.totalEarnings.toLocaleString()}</li>
              <li>Pending Payout: ${data.currency} ${data.pendingPayout.toLocaleString()}</li>
            </ul>

            <p>Keep up the great work!</p>

            <p>Best regards,<br>The ShopsNSports Team</p>
          </div>
          <div class="footer">
            <p>This is an automated email. Please do not reply to this message.</p>
            <p>&copy; 2026 ShopsNSports. All rights reserved.</p>
          </div>
        </div>
      </body>
      </html>
    `,
    text: `
You Earned Commission! - ShopsNSports

Dear ${data.fullName},

Congratulations! You've just earned a commission from a successful shipment.

Commission Earned: ${data.currency} ${data.commission.toLocaleString()}

Shipment Details:
- Tracking Number: ${data.trackingNumber}
- Shipment Value: ${data.currency} ${data.shipmentValue.toLocaleString()}
- Your Commission Rate: ${data.commissionRate}%

Your Earnings Summary:
- Total Earnings: ${data.currency} ${data.totalEarnings.toLocaleString()}
- Pending Payout: ${data.currency} ${data.pendingPayout.toLocaleString()}

Keep up the great work!

Best regards,
The ShopsNSports Team

---
This is an automated email. Please do not reply to this message.
© 2026 ShopsNSports. All rights reserved.
    `
  }),
};

/**
 * Send Affiliate Email
 * Sends templated affiliate emails (application, approval, payout, etc.)
 */
exports.sendAffiliateEmail = functions.https.onCall(async (data, context) => {
  try {
    if (!data.to || !data.templateType || !data.templateData) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Missing required fields: to, templateType, templateData'
      );
    }

    const template = affiliateEmailTemplates[data.templateType];
    if (!template) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        `Unknown template type: ${data.templateType}`
      );
    }

    const templateData = data.templateData;
    const email = template(templateData);

    const result = await exports.sendEmail({
      to: data.to,
      subject: email.subject,
      htmlBody: email.html,
      plainTextBody: email.text,
      emailType: 'system',
      smtpConfig: data.smtpConfig,
    }, context);

    await admin.firestore().collection('affiliate_emails_log').add({
      affiliateId: templateData.affiliateId,
      to: data.to,
      templateType: data.templateType,
      sentAt: admin.firestore.Timestamp.now(),
      success: true,
      messageId: result.messageId,
    });

    return { success: true, templateType: data.templateType };

  } catch (error) {
    console.error('Affiliate email sending failed:', error);
    throw error;
  }
});

// ============================================================================
// FIRESTORE TRIGGERS FOR AFFILIATE LIFECYCLE
// ============================================================================

exports.onAffiliateCreated = functions.firestore
  .document('affiliates/{affiliateId}')
  .onCreate(async (snap, context) => {
    const affiliateData = snap.data();

    if (affiliateData.status !== 'pending') {
      return null;
    }

    await admin.firestore().collection('affiliate_notifications').add({
      type: 'application_submitted',
      affiliateId: context.params.affiliateId,
      email: affiliateData.email,
      templateType: 'applicationSubmitted',
      templateData: {
        fullName: affiliateData.fullName,
        affiliateId: context.params.affiliateId,
      },
      status: 'pending_email',
      createdAt: admin.firestore.Timestamp.now(),
    });

    return null;
  });

exports.onAffiliateStatusChanged = functions.firestore
  .document('affiliates/{affiliateId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    if (before.status === after.status) {
      return null;
    }

    const affiliateId = context.params.affiliateId;
    const email = after.email;
    const fullName = after.fullName;

    if (after.status === 'approved') {
      await admin.firestore().collection('affiliate_notifications').add({
        type: 'application_approved',
        affiliateId: affiliateId,
        email: email,
        templateType: 'applicationApproved',
        templateData: {
          fullName: fullName,
          affiliateId: affiliateId,
          commissionRate: after.commissionRate || 15,
          dashboardUrl: 'https://shopsnports.com/affiliate/dashboard',
        },
        status: 'pending_email',
        createdAt: admin.firestore.Timestamp.now(),
      });

      if (!after.approvedAt) {
        await change.after.ref.update({
          approvedAt: admin.firestore.Timestamp.now(),
        });
      }
    } else if (after.status === 'rejected') {
      await admin.firestore().collection('affiliate_notifications').add({
        type: 'application_rejected',
        affiliateId: affiliateId,
        email: email,
        templateType: 'applicationRejected',
        templateData: {
          fullName: fullName,
          affiliateId: affiliateId,
          reason: after.rejectionReason,
        },
        status: 'pending_email',
        createdAt: admin.firestore.Timestamp.now(),
      });
    }

    return null;
  });

exports.onPayoutCreated = functions.firestore
  .document('payouts/{payoutId}')
  .onCreate(async (snap, context) => {
    const payoutData = snap.data();

    if (payoutData.status !== 'pending') {
      return null;
    }

    const affiliateDoc = await admin.firestore()
      .collection('affiliates')
      .doc(payoutData.affiliateId)
      .get();

    if (!affiliateDoc.exists) {
      console.error(`Affiliate ${payoutData.affiliateId} not found`);
      return null;
    }

    const affiliate = affiliateDoc.data();

    await admin.firestore().collection('affiliate_notifications').add({
      type: 'payout_requested',
      affiliateId: payoutData.affiliateId,
      payoutId: context.params.payoutId,
      email: affiliate.email,
      templateType: 'payoutRequested',
      templateData: {
        fullName: affiliate.fullName,
        affiliateId: payoutData.affiliateId,
        payoutId: context.params.payoutId,
        amount: payoutData.netAmount || payoutData.amount,
        currency: 'NGN',
      },
      status: 'pending_email',
      createdAt: admin.firestore.Timestamp.now(),
    });

    return null;
  });

exports.onPayoutStatusChanged = functions.firestore
  .document('payouts/{payoutId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    if (before.status === after.status || after.status !== 'completed') {
      return null;
    }

    const payoutId = context.params.payoutId;

    const affiliateDoc = await admin.firestore()
      .collection('affiliates')
      .doc(after.affiliateId)
      .get();

    if (!affiliateDoc.exists) {
      console.error(`Affiliate ${after.affiliateId} not found`);
      return null;
    }

    const affiliate = affiliateDoc.data();

    await admin.firestore().collection('affiliate_notifications').add({
      type: 'payout_completed',
      affiliateId: after.affiliateId,
      payoutId: payoutId,
      email: affiliate.email,
      templateType: 'payoutCompleted',
      templateData: {
        fullName: affiliate.fullName,
        affiliateId: after.affiliateId,
        payoutId: payoutId,
        amount: after.netAmount || after.amount,
        currency: 'NGN',
        paymentMethod: after.paymentMethod || 'bank_transfer',
        transactionReference: after.transactionReference,
        nextPayoutDate: affiliate.nextPayoutDate,
      },
      status: 'pending_email',
      createdAt: admin.firestore.Timestamp.now(),
    });

    return null;
  });

exports.onShippingRequestDelivered = functions.firestore
  .document('shippingRequests/{requestId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    if (before.status === after.status || after.status !== 'delivered') {
      return null;
    }

    const requestId = context.params.requestId;
    const affiliateId = after.affiliateId;

    if (!affiliateId) {
      return null;
    }

    const affiliateDoc = await admin.firestore()
      .collection('affiliates')
      .doc(affiliateId)
      .get();

    if (!affiliateDoc.exists) {
      console.error(`Affiliate ${affiliateId} not found`);
      return null;
    }

    const affiliate = affiliateDoc.data();
    const commissionRate = affiliate.commissionRate || 15;
    const shippingFee = after.shippingFee ?? 0;
    const commission = (shippingFee * commissionRate / 100);

    await admin.firestore().collection('affiliate_notifications').add({
      type: 'commission_earned',
      affiliateId: affiliateId,
      requestId: requestId,
      email: affiliate.email,
      templateType: 'commissionEarned',
      templateData: {
        fullName: affiliate.fullName,
        affiliateId: affiliateId,
        trackingNumber: after.trackingNumber || requestId,
        shipmentValue: shippingFee,
        commission: commission,
        commissionRate: commissionRate,
        totalEarnings: (affiliate.totalEarnings || 0) + commission,
        pendingPayout: (affiliate.pendingPayout || 0) + commission,
        currency: 'NGN',
      },
      status: 'pending_email',
      createdAt: admin.firestore.Timestamp.now(),
    });

    return null;
  });


// ============================================================================
// SCHEDULED TASKS
// ============================================================================

/**
 * Disable Expired Admin Accounts
 * Scheduled function that runs daily to disable expired admin accounts
 */
exports.disableExpiredAdmins = functions.pubsub.schedule('0 0 * * *').onRun(async (context) => {
  try {
    const now = admin.firestore.Timestamp.now();

    // Find all active admins with expiration dates
    const snapshot = await admin.firestore()
      .collection(ADMIN_USERS_COLLECTION)
      .where('status', '==', 'active')
      .where('expiresAt', '!=', null)
      .get();

    let disabledCount = 0;

    for (const doc of snapshot.docs) {
      const adminData = doc.data();

      // Check if account is expired
      if (adminData.expiresAt && adminData.expiresAt.toDate() < now.toDate()) {
        // Disable the account
        await admin.auth().updateUser(doc.id, { disabled: true });

        // Update Firestore
        await admin.firestore().collection(ADMIN_USERS_COLLECTION).doc(doc.id).update({
          status: 'disabled',
          disabledReason: 'account_expired',
          disabledAt: admin.firestore.Timestamp.now(),
        });

        // Log activity
        await admin.firestore().collection('admin_activity_logs').add({
          adminId: 'system',
          adminEmail: 'system@shopsnports.com',
          action: 'disabled_admin',
          itemId: doc.id,
          itemName: adminData.displayName,
          details: {
            targetEmail: adminData.email,
            reason: 'Account expired',
            expiredAt: adminData.expiresAt,
          },
          timestamp: admin.firestore.Timestamp.now(),
          success: true,
        });

        disabledCount++;
        console.log(`Disabled expired admin: ${adminData.email} (expired at ${adminData.expiresAt.toDate()})`);
      }
    }

    console.log(`Disabled ${disabledCount} expired admin accounts`);
    return { success: true, disabledCount };

  } catch (error) {
    console.error('Error disabling expired admins:', error);
    throw error;
  }
});

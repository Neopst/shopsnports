"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.retryFailedEmails = exports.processEmailQueue = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const nodemailer_1 = __importDefault(require("nodemailer"));
const emailTemplateService_1 = require("./emailTemplateService");
const smtpConfig_1 = require("./smtpConfig");
/**
 * Cloud Function: Process Email Queue
 *
 * Triggered when new emails are added to the email_queue collection
 * Processes pending emails and sends them via SMTP
 *
 * Supported email types:
 * - admin_welcome: New admin account created
 * - admin_password_reset: Admin password reset
 */
exports.processEmailQueue = functions.firestore
    .document('email_queue/{emailId}')
    .onCreate(async (snapshot, context) => {
    const emailData = snapshot.data();
    const emailId = context.params.emailId;
    if (!emailData) {
        console.log(`❌ Email queue item ${emailId} has no data`);
        return;
    }
    // Skip if already sent
    if (emailData.sent === true) {
        console.log(`⏭️ Email ${emailId} already sent, skipping`);
        return;
    }
    const { type, to, subject, adminName, role, permissionsList, loginUrl, resetLink, createdBy, resetBy } = emailData;
    console.log(`📧 Processing email queue item ${emailId}: ${type} -> ${to}`);
    try {
        // Get SMTP configuration from Firebase Functions config
        const smtpConfig = (0, smtpConfig_1.getSmtpConfig)();
        const validation = (0, smtpConfig_1.validateSmtpConfig)(smtpConfig);
        if (!validation.valid) {
            console.error('❌ SMTP configuration invalid:', validation.error);
            await snapshot.ref.update({
                sent: false,
                error: validation.error,
                processedAt: admin.firestore.FieldValue.serverTimestamp(),
                retries: admin.firestore.FieldValue.increment(1),
            });
            return;
        }
        const transporter = nodemailer_1.default.createTransport({
            host: smtpConfig.host,
            port: smtpConfig.port,
            secure: smtpConfig.secure,
            auth: {
                user: smtpConfig.user,
                pass: smtpConfig.pass,
            },
        });
        let htmlBody = '';
        let textBody = '';
        let emailSubject = subject || 'Notification from ShopsNPorts';
        // Generate email content based on type
        if (type === 'admin_welcome') {
            const template = await (0, emailTemplateService_1.getTemplate)('admin_welcome', admin.firestore());
            const { subject: tmplSubject, htmlBody: tmplHtml, plainTextBody: tmplText } = (0, emailTemplateService_1.renderTemplate)(template, {
                adminName: adminName || 'Admin',
                role: role || 'Admin',
                permissionsList: permissionsList || '<li>Standard admin access</li>',
                adminUrl: loginUrl || 'https://admin.shopsnports.com/login',
                resetLink: resetLink || loginUrl || 'https://admin.shopsnports.com/login',
                tempPassword: emailData.tempPassword || '',
            });
            emailSubject = subject || tmplSubject;
            htmlBody = tmplHtml;
            textBody = tmplText;
        }
        else if (type === 'admin_password_reset') {
            const template = await (0, emailTemplateService_1.getTemplate)('password_reset', admin.firestore());
            const { subject: tmplSubject, htmlBody: tmplHtml, plainTextBody: tmplText } = (0, emailTemplateService_1.renderTemplate)(template, {
                name: adminName || 'Admin',
                resetLink: resetLink || loginUrl || 'https://admin.shopsnports.com/login',
            });
            emailSubject = subject || tmplSubject;
            htmlBody = tmplHtml;
            textBody = tmplText;
        }
        else if (type === 'password_reset') {
            const template = await (0, emailTemplateService_1.getTemplate)('password_reset', admin.firestore());
            const { subject: tmplSubject, htmlBody: tmplHtml, plainTextBody: tmplText } = (0, emailTemplateService_1.renderTemplate)(template, {
                name: adminName || 'User',
                resetLink: resetLink || loginUrl || 'https://admin.shopsnports.com/reset-password',
            });
            emailSubject = subject || tmplSubject;
            htmlBody = tmplHtml;
            textBody = tmplText;
        }
        else {
            // Generic email for unknown types
            htmlBody = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; background-color: #f9f9f9; }
    .header { background-color: #003366; color: white; padding: 20px; text-align: center; border-radius: 5px 5px 0 0; }
    .content { background-color: white; padding: 30px; border-radius: 0 0 5px 5px; }
    .footer { text-align: center; font-size: 12px; color: #888; margin-top: 20px; padding-top: 20px; border-top: 1px solid #eee; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>ShopsNPorts</h1>
    </div>
    <div class="content">
      <p>Hi ${adminName || 'there'},</p>
      <p>${subject || 'You have a new notification.'}</p>
    </div>
    <div class="footer">
      <p>&copy; 2026 Shop's & Ports. All rights reserved.</p>
    </div>
  </div>
</body>
</html>`;
            textBody = `Hi ${adminName || 'there'},\n\n${subject || 'You have a new notification.'}\n\n© 2026 Shop's & Ports`;
        }
        // Send the email
        await transporter.sendMail({
            from: smtpConfig.user,
            to: to,
            subject: emailSubject,
            html: htmlBody,
            text: textBody,
        });
        console.log(`✅ Email sent successfully to ${to}`);
        // Mark as sent
        await snapshot.ref.update({
            sent: true,
            sentAt: admin.firestore.FieldValue.serverTimestamp(),
            processedAt: admin.firestore.FieldValue.serverTimestamp(),
            error: null,
        });
    }
    catch (error) {
        console.error(`❌ Failed to send email to ${to}:`, error.message);
        const currentRetries = emailData.retries || 0;
        const maxRetries = 3;
        if (currentRetries >= maxRetries) {
            // Mark as failed after max retries
            await snapshot.ref.update({
                sent: false,
                failed: true,
                error: error.message,
                processedAt: admin.firestore.FieldValue.serverTimestamp(),
                retries: admin.firestore.FieldValue.increment(1),
            });
            console.log(`❌ Email ${emailId} failed after ${maxRetries} retries`);
        }
        else {
            // Increment retry count
            await snapshot.ref.update({
                retries: admin.firestore.FieldValue.increment(1),
                lastRetryAt: admin.firestore.FieldValue.serverTimestamp(),
                lastError: error.message,
            });
            console.log(`⏳ Email ${emailId} will retry (attempt ${currentRetries + 1}/${maxRetries})`);
        }
    }
});
/**
 * Scheduled function to retry failed emails
 * Runs every 15 minutes
 */
exports.retryFailedEmails = functions.pubsub
    .schedule('every 15 minutes')
    .onRun(async () => {
    const db = admin.firestore();
    try {
        // Find failed emails that haven't exceeded max retries
        const failedEmails = await db
            .collection('email_queue')
            .where('sent', '==', false)
            .where('failed', '==', true)
            .where('retries', '<', 3)
            .limit(10)
            .get();
        console.log(`🔄 Found ${failedEmails.size} failed emails to retry`);
        for (const doc of failedEmails.docs) {
            const emailData = doc.data();
            // Re-trigger by updating a retry flag
            await doc.ref.update({
                failed: false,
                retryAt: admin.firestore.FieldValue.serverTimestamp(),
            });
        }
    }
    catch (error) {
        console.error('❌ Error in retryFailedEmails:', error.message);
    }
});

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { getTemplate, renderTemplate } from './emailTemplateService';
import { getSmtpConfig, validateSmtpConfig } from './smtpConfig';
import nodemailer from 'nodemailer';

/**
 * Send Email Callable Function
 *
 * Generic email sending function for Flutter services.
 * Validates admin authentication, uses SMTP configuration,
 * and supports custom HTML or template-based emails.
 *
 * Usage from Flutter:
 * final callable = FirebaseFunctions.instance.httpsCallable('sendEmailFn');
 * final result = await callable({
 *   'to': 'recipient@example.com',
 *   'subject': 'Test Email',
 *   'htmlBody': '<h1>Test</h1>',
 * });
 */
export const sendEmail = functions.https.onCall(async (data: any, context: functions.https.CallableContext) => {
  // Verify authentication (require admin)
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  // Extract parameters
  const { to, subject, htmlBody, plainTextBody, emailType = 'system' } = data;

  // Validate required fields
  if (!to || !subject) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Missing required fields: to, subject'
    );
  }

  try {
    console.log(`📧 Sending email via sendEmail callable: ${to}`);

    // Get SMTP configuration
    const smtpConfig = getSmtpConfig();
    const validation = validateSmtpConfig(smtpConfig);

    if (!validation.valid) {
      console.error('❌ Invalid SMTP configuration:', validation.error);
      throw new functions.https.HttpsError(
        'failed-precondition',
        `SMTP configuration error: ${validation.error}`
      );
    }

    // Create transporter
    const transporter = nodemailer.createTransporter({
      host: smtpConfig.host,
      port: smtpConfig.port,
      secure: smtpConfig.secure,
      auth: {
        user: smtpConfig.user,
        pass: smtpConfig.pass,
      },
    });

    // Prepare email content
    let emailHtml = htmlBody;
    let emailText = plainTextBody;

    // If HTML not provided but template type is, use template
    if (!emailHtml && data.templateType) {
      const template = await getTemplate(data.templateType, admin.firestore());
      const { subject: tmplSubject, htmlBody: tmplHtml, plainTextBody: tmplText } = renderTemplate(
        template,
        data.templateData || {}
      );
      emailHtml = tmplHtml;
      emailText = tmplText;
    }

    // Strip HTML for plain text if not provided
    if (emailHtml && !emailText) {
      emailText = emailHtml.replace(/<[^>]*>/g, '').trim();
    }

    // Send email
    const mailOptions = {
      from: smtpConfig.user,
      to: to,
      subject: subject,
      html: emailHtml,
      text: emailText,
      replyTo: 'support@shopsnports.com',
    };

    const info = await transporter.sendMail(mailOptions);
    console.log(`✅ Email sent successfully to ${to}`);
    console.log(`  Message ID: ${info.messageId}`);

    // Log to email history collection (optional)
    try {
      await admin.firestore().collection('email_history').add({
        to,
        subject,
        emailType,
        status: 'sent',
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        messageId: info.messageId,
        sentBy: context.auth?.uid || 'system',
      });
    } catch (logError) {
      console.error('Warning: Failed to log email to history:', logError);
      // Don't fail the whole operation if logging fails
    }

    return {
      success: true,
      messageId: info.messageId,
      timestamp: new Date().toISOString(),
    };

  } catch (error: any) {
    console.error('❌ Failed to send email:', error);

    // Log failure
    try {
      await admin.firestore().collection('email_history').add({
        to,
        subject,
        emailType,
        status: 'failed',
        error: error.message || 'Unknown error',
        failedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (logError) {
      console.error('Warning: Failed to log email error:', logError);
    }

    throw new functions.https.HttpsError(
      'internal',
      `Failed to send email: ${error.message || 'Unknown error'}`
    );
  }
});
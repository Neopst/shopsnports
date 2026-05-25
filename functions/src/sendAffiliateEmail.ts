import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { getTemplate, renderTemplate } from './emailTemplateService';
import { getSmtpConfig, validateSmtpConfig } from './smtpConfig';
import nodemailer from 'nodemailer';

/**
 * Send Affiliate Email Callable Function
 *
 * Sends affiliate-related emails using template system.
 * Supports all affiliate template types defined in emailTemplateService.
 *
 * Usage from Flutter:
 * final callable = FirebaseFunctions.instance.httpsCallable('sendAffiliateEmailFn');
 * final result = await callable({
 *   'to': 'affiliate@example.com',
 *   'templateType': 'affiliate_welcome',
 *   'templateData': {
 *     'affiliateName': 'John Doe',
 *     'referralCode': 'SHOP-12345',
 *     'commissionRate': '15'
 *   }
 * });
 */
export const sendAffiliateEmail = functions.https.onCall(async (data: any, context: functions.https.CallableContext) => {
  // Verify authentication (require admin or authenticated user for their own emails)
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  // Extract parameters
  const { to, templateType, templateData } = data;

  // Validate required fields
  if (!to || !templateType) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Missing required fields: to, templateType'
    );
  }

  // Valid affiliate template types
  const validTemplateTypes = [
    'affiliate_welcome',
    'affiliate_approved',
    'affiliate_rejected',
    'affiliate_suspended',
    'affiliate_commission_earned',
    'affiliate_payout_processed',
  ];

  if (!validTemplateTypes.includes(templateType)) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      `Invalid template type: ${templateType}. Valid types: ${validTemplateTypes.join(', ')}`
    );
  }

  try {
    console.log(`📧 Sending affiliate email: ${to}, template: ${templateType}`);

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

    // Get and render template
    const template = await getTemplate(templateType as any, admin.firestore());
    const { subject, htmlBody, plainTextBody } = renderTemplate(
      template,
      templateData || {}
    );

    // Send email
    const mailOptions = {
      from: smtpConfig.user,
      to: to,
      subject: subject,
      html: htmlBody,
      text: plainTextBody,
      replyTo: 'affiliates@shopsnports.com',
    };

    const info = await transporter.sendMail(mailOptions);
    console.log(`✅ Affiliate email sent successfully to ${to}`);
    console.log(`  Template: ${templateType}`);
    console.log(`  Message ID: ${info.messageId}`);

    // Log to affiliate email history
    try {
      await admin.firestore().collection('affiliate_email_history').add({
        to,
        templateType,
        templateData,
        status: 'sent',
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        messageId: info.messageId,
        sentBy: context.auth?.uid || 'system',
      });
    } catch (logError) {
      console.error('Warning: Failed to log affiliate email to history:', logError);
      // Don't fail the whole operation if logging fails
    }

    return {
      success: true,
      templateType,
      messageId: info.messageId,
      timestamp: new Date().toISOString(),
    };

  } catch (error: any) {
    console.error('❌ Failed to send affiliate email:', error);

    // Log failure
    try {
      await admin.firestore().collection('affiliate_email_history').add({
        to,
        templateType,
        templateData,
        status: 'failed',
        error: error.message || 'Unknown error',
        failedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (logError) {
      console.error('Warning: Failed to log affiliate email error:', logError);
    }

    throw new functions.https.HttpsError(
      'internal',
      `Failed to send affiliate email: ${error.message || 'Unknown error'}`
    );
  }
});
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
exports.sendEmail = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const emailTemplateService_1 = require("./emailTemplateService");
const smtpConfig_1 = require("./smtpConfig");
const nodemailer_1 = __importDefault(require("nodemailer"));
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
exports.sendEmail = functions.https.onCall(async (data, context) => {
    // Verify authentication (require admin)
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    // Extract parameters
    const { to, subject, htmlBody, plainTextBody, emailType = 'system' } = data;
    // Validate required fields
    if (!to || !subject) {
        throw new functions.https.HttpsError('invalid-argument', 'Missing required fields: to, subject');
    }
    try {
        console.log(`📧 Sending email via sendEmail callable: ${to}`);
        // Get SMTP configuration
        const smtpConfig = (0, smtpConfig_1.getSmtpConfig)();
        const validation = (0, smtpConfig_1.validateSmtpConfig)(smtpConfig);
        if (!validation.valid) {
            console.error('❌ Invalid SMTP configuration:', validation.error);
            throw new functions.https.HttpsError('failed-precondition', `SMTP configuration error: ${validation.error}`);
        }
        // Create transporter
        const transporter = nodemailer_1.default.createTransporter({
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
            const template = await (0, emailTemplateService_1.getTemplate)(data.templateType, admin.firestore());
            const { subject: tmplSubject, htmlBody: tmplHtml, plainTextBody: tmplText } = (0, emailTemplateService_1.renderTemplate)(template, data.templateData || {});
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
        }
        catch (logError) {
            console.error('Warning: Failed to log email to history:', logError);
            // Don't fail the whole operation if logging fails
        }
        return {
            success: true,
            messageId: info.messageId,
            timestamp: new Date().toISOString(),
        };
    }
    catch (error) {
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
        }
        catch (logError) {
            console.error('Warning: Failed to log email error:', logError);
        }
        throw new functions.https.HttpsError('internal', `Failed to send email: ${error.message || 'Unknown error'}`);
    }
});

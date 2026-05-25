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
exports.sendAffiliateEmail = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const emailTemplateService_1 = require("./emailTemplateService");
const smtpConfig_1 = require("./smtpConfig");
const nodemailer_1 = __importDefault(require("nodemailer"));
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
exports.sendAffiliateEmail = functions.https.onCall(async (data, context) => {
    // Verify authentication (require admin or authenticated user for their own emails)
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    // Extract parameters
    const { to, templateType, templateData } = data;
    // Validate required fields
    if (!to || !templateType) {
        throw new functions.https.HttpsError('invalid-argument', 'Missing required fields: to, templateType');
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
        throw new functions.https.HttpsError('invalid-argument', `Invalid template type: ${templateType}. Valid types: ${validTemplateTypes.join(', ')}`);
    }
    try {
        console.log(`📧 Sending affiliate email: ${to}, template: ${templateType}`);
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
        // Get and render template
        const template = await (0, emailTemplateService_1.getTemplate)(templateType, admin.firestore());
        const { subject, htmlBody, plainTextBody } = (0, emailTemplateService_1.renderTemplate)(template, templateData || {});
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
        }
        catch (logError) {
            console.error('Warning: Failed to log affiliate email to history:', logError);
            // Don't fail the whole operation if logging fails
        }
        return {
            success: true,
            templateType,
            messageId: info.messageId,
            timestamp: new Date().toISOString(),
        };
    }
    catch (error) {
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
        }
        catch (logError) {
            console.error('Warning: Failed to log affiliate email error:', logError);
        }
        throw new functions.https.HttpsError('internal', `Failed to send affiliate email: ${error.message || 'Unknown error'}`);
    }
});

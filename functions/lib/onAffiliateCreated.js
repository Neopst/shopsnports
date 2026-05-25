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
exports.onAffiliateUpdated = exports.onAffiliateCreated = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const nodemailer_1 = __importDefault(require("nodemailer"));
const emailTemplateService_1 = require("./emailTemplateService");
const smtpConfig_1 = require("./smtpConfig");
/**
 * Cloud Function: Triggered when a new affiliate document is created in Firestore
 * - Sends notification to admins about new affiliate application
 * - Logs the affiliate registration activity
 * - Sends welcome email when affiliate is approved (via onAffiliateUpdated)
 */
exports.onAffiliateCreated = functions.firestore
    .document('affiliates/{affiliateId}')
    .onCreate(async (snapshot, context) => {
    const affiliateId = context.params.affiliateId;
    const affiliateData = snapshot.data();
    if (!affiliateData) {
        console.error('No data found for affiliate:', affiliateId);
        return;
    }
    console.log(`Processing new affiliate application: ${affiliateId} (${affiliateData.fullName})`);
    const db = admin.firestore();
    try {
        // ========== NOTIFY ADMINS OF NEW AFFILIATE APPLICATION ==========
        try {
            // Get all admin users
            const adminsSnapshot = await db.collection('users')
                .where('isAdmin', '==', true)
                .get();
            if (!adminsSnapshot.empty) {
                const adminIds = adminsSnapshot.docs.map(doc => doc.id);
                // Create notification for each admin
                const batch = db.batch();
                const now = admin.firestore.FieldValue.serverTimestamp();
                adminIds.forEach(adminId => {
                    const notificationRef = db.collection('notifications').doc();
                    batch.set(notificationRef, {
                        userId: adminId,
                        type: 'affiliate',
                        category: 'affiliate',
                        title: 'New Affiliate Application',
                        message: `${affiliateData.fullName} has applied to become an affiliate.`,
                        actionUrl: `/admin/affiliates/${affiliateId}`,
                        isRead: false,
                        readAt: null,
                        metadata: {
                            affiliateId: affiliateId,
                            affiliateEmail: affiliateData.email,
                            affiliateName: affiliateData.fullName,
                            companyName: affiliateData.companyName,
                        },
                        priority: 'normal',
                        createdAt: now,
                        updatedAt: now,
                    });
                });
                await batch.commit();
                console.log(`✅ Notified ${adminIds.length} admins of new affiliate application`);
            }
        }
        catch (notifyError) {
            console.error('Error notifying admins:', notifyError);
            // Don't throw - notification failure shouldn't fail the whole function
        }
        // ========== LOG ACTIVITY ==========
        await db.collection('activity_logs').add({
            type: 'affiliate_registration',
            affiliateId: affiliateId,
            email: affiliateData.email,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            details: {
                fullName: affiliateData.fullName,
                phone: affiliateData.phone,
                companyName: affiliateData.companyName,
                commissionRate: affiliateData.commissionRate,
                payoutSchedule: affiliateData.payoutSchedule,
            },
        });
        console.log(`Successfully processed affiliate registration: ${affiliateId}`);
        return { success: true, affiliateId };
    }
    catch (error) {
        console.error('Error in onAffiliateCreated:', error);
        throw error;
    }
});
/**
 * Cloud Function: Triggered when an affiliate document is updated in Firestore
 * - Sends welcome email when affiliate is approved
 * - Sends rejection email when affiliate is rejected
 * - Sends notification to affiliate when status changes
 */
exports.onAffiliateUpdated = functions.firestore
    .document('affiliates/{affiliateId}')
    .onUpdate(async (change, context) => {
    const affiliateId = context.params.affiliateId;
    const beforeData = change.before.data();
    const afterData = change.after.data();
    if (!beforeData || !afterData) {
        console.error('No data found for affiliate update:', affiliateId);
        return;
    }
    // Check if status changed
    const beforeStatus = beforeData.status;
    const afterStatus = afterData.status;
    if (beforeStatus === afterStatus) {
        console.log(`Status unchanged for affiliate ${affiliateId}, skipping`);
        return;
    }
    console.log(`Affiliate ${affiliateId} status changed from ${beforeStatus} to ${afterStatus}`);
    const db = admin.firestore();
    try {
        // ========== SEND EMAIL BASED ON STATUS CHANGE ==========
        try {
            const smtpConfig = (0, smtpConfig_1.getSmtpConfig)();
            const validation = (0, smtpConfig_1.validateSmtpConfig)(smtpConfig);
            if (validation.valid && afterData.email) {
                const transporter = nodemailer_1.default.createTransport({
                    host: smtpConfig.host,
                    port: smtpConfig.port,
                    secure: smtpConfig.secure,
                    auth: {
                        user: smtpConfig.user,
                        pass: smtpConfig.pass,
                    },
                });
                let templateName = 'affiliate_approved';
                let templateData = {
                    displayName: afterData.fullName || 'there',
                };
                if (afterStatus === 'approved') {
                    // Send welcome email for approved affiliate
                    templateName = 'affiliate_approved';
                    templateData = {
                        ...templateData,
                        commissionRate: afterData.commissionRate,
                        payoutSchedule: afterData.payoutSchedule,
                        dashboardUrl: 'https://app.shopsnports.com/affiliate/dashboard',
                    };
                }
                else if (afterStatus === 'rejected') {
                    // Send rejection email
                    templateName = 'affiliate_rejected';
                    templateData = {
                        ...templateData,
                        rejectionReason: afterData.rejectionReason || 'No reason provided',
                    };
                }
                else if (afterStatus === 'suspended') {
                    // Send suspension email
                    templateName = 'affiliate_suspended';
                    templateData = {
                        ...templateData,
                        suspensionReason: afterData.suspensionReason || 'No reason provided',
                    };
                }
                else {
                    // No email needed for other status changes
                    console.log(`No email needed for status: ${afterStatus}`);
                    return;
                }
                // Get template from Firestore or use default
                const template = await (0, emailTemplateService_1.getTemplate)(templateName, db);
                const { subject, htmlBody, plainTextBody } = (0, emailTemplateService_1.renderTemplate)(template, templateData);
                await transporter.sendMail({
                    from: smtpConfig.user,
                    to: afterData.email,
                    subject: subject,
                    html: htmlBody,
                    text: plainTextBody,
                    replyTo: 'support@shopsnports.com',
                });
                console.log(`✅ ${templateName} email sent to: ${afterData.email}`);
            }
            else {
                console.warn('⚠️ SMTP_PASS not configured or email missing. Email not sent.');
            }
        }
        catch (emailError) {
            console.error('⚠️ Error sending affiliate status email:', emailError);
            // Don't throw - email failure shouldn't fail the whole function
        }
        // ========== CREATE NOTIFICATION FOR AFFILIATE ==========
        try {
            let notificationTitle = '';
            let notificationMessage = '';
            if (afterStatus === 'approved') {
                notificationTitle = 'Affiliate Application Approved';
                notificationMessage = 'Congratulations! Your affiliate application has been approved. You can start earning commissions now.';
            }
            else if (afterStatus === 'rejected') {
                notificationTitle = 'Affiliate Application Rejected';
                notificationMessage = `Your affiliate application has been rejected. Reason: ${afterData.rejectionReason || 'No reason provided'}`;
            }
            else if (afterStatus === 'suspended') {
                notificationTitle = 'Affiliate Account Suspended';
                notificationMessage = `Your affiliate account has been suspended. Reason: ${afterData.suspensionReason || 'No reason provided'}`;
            }
            else {
                return;
            }
            await db.collection('notifications').add({
                userId: affiliateId,
                type: 'affiliate',
                category: 'affiliate',
                title: notificationTitle,
                message: notificationMessage,
                actionUrl: '/affiliate/dashboard',
                isRead: false,
                readAt: null,
                metadata: {
                    affiliateId: affiliateId,
                    status: afterStatus,
                },
                priority: afterStatus === 'approved' ? 'high' : 'normal',
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            console.log(`✅ Notification created for affiliate ${affiliateId}`);
        }
        catch (notifyError) {
            console.error('Error creating affiliate notification:', notifyError);
            // Don't throw - notification failure shouldn't fail the whole function
        }
        // ========== LOG ACTIVITY ==========
        await db.collection('activity_logs').add({
            type: 'affiliate_status_changed',
            affiliateId: affiliateId,
            email: afterData.email,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            details: {
                fullName: afterData.fullName,
                previousStatus: beforeStatus,
                newStatus: afterStatus,
                approvedBy: afterData.approvedBy,
                rejectionReason: afterData.rejectionReason,
                suspensionReason: afterData.suspensionReason,
            },
        });
        console.log(`Successfully processed affiliate status change: ${affiliateId}`);
        return { success: true, affiliateId, newStatus: afterStatus };
    }
    catch (error) {
        console.error('Error in onAffiliateUpdated:', error);
        throw error;
    }
});

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
exports.onUserCreated = void 0;
const admin = __importStar(require("firebase-admin"));
const nodemailer_1 = __importDefault(require("nodemailer"));
const emailTemplateService_1 = require("./emailTemplateService");
const smtpConfig_1 = require("./smtpConfig");
/**
 * Cloud Function: Triggered when a new user is created in Firebase Auth
 * - Creates user profile document in Firestore
 * - Sends welcome email to the new user (using Firestore template or default)
 * - Logs the registration activity
 */
const onUserCreated = async (user, context) => {
    const { email, displayName, uid, photoURL } = user;
    const db = admin.firestore();
    console.log(`Processing new user registration: ${uid} (${email})`);
    try {
        // ========== CREATE USER PROFILE IN FIRESTORE ==========
        const userProfile = {
            uid: uid,
            email: email,
            displayName: displayName || null,
            photoUrl: photoURL || null,
            phoneNumber: user.phoneNumber || null,
            emailVerified: user.emailVerified,
            disabled: user.disabled,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            lastLoginAt: admin.firestore.FieldValue.serverTimestamp(),
            role: 'customer',
            roles: ['customer'],
            roleStatus: {
                shipper: 'none',
                affiliate: 'none',
                vendor: 'none',
            },
            affiliateApproved: false,
            isAdmin: false,
            affiliateId: null,
            notifications: {
                emailEnabled: true,
                pushEnabled: false,
                smsEnabled: false,
            },
            preferences: {
                currency: 'NGN',
                language: 'en',
                timezone: 'Africa/Lagos',
            },
        };
        await db.collection('users').doc(uid).set(userProfile);
        console.log(`Created user profile for: ${uid}`);
        // ========== CREATE CUSTOMER DOCUMENT (for customer role) ==========
        if (userProfile.role === 'customer') {
            try {
                const customerProfile = {
                    id: uid,
                    name: displayName || 'Customer',
                    email: email,
                    phone: user.phoneNumber || null,
                    avatarUrl: photoURL || null,
                    status: 'active',
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    lastLogin: admin.firestore.FieldValue.serverTimestamp(),
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                    businessName: null,
                    address: null,
                    city: null,
                    state: null,
                    country: null,
                    zipCode: null,
                    gender: null,
                    dateOfBirth: null,
                    emailVerified: user.emailVerified,
                    phoneVerified: false,
                    notes: null,
                    totalOrders: 0,
                    totalSpent: 0,
                    pendingOrders: 0,
                    pendingAmount: 0,
                };
                await db.collection('customers').doc(uid).set(customerProfile);
                console.log(`Created customer document for: ${uid}`);
            }
            catch (customerError) {
                console.error('Error creating customer document:', customerError);
                // Don't throw - customer doc creation shouldn't fail the whole function
            }
        }
        // ========== SEND WELCOME EMAIL (using template service) ==========
        try {
            const smtpConfig = (0, smtpConfig_1.getSmtpConfig)();
            const validation = (0, smtpConfig_1.validateSmtpConfig)(smtpConfig);
            if (validation.valid && email) {
                const transporter = nodemailer_1.default.createTransport({
                    host: smtpConfig.host,
                    port: smtpConfig.port,
                    secure: smtpConfig.secure,
                    auth: {
                        user: smtpConfig.user,
                        pass: smtpConfig.pass,
                    },
                });
                // Get template from Firestore or use default
                const template = await (0, emailTemplateService_1.getTemplate)('welcome', db);
                const { subject, htmlBody, plainTextBody } = (0, emailTemplateService_1.renderTemplate)(template, {
                    displayName: displayName || 'there',
                });
                await transporter.sendMail({
                    from: smtpConfig.user,
                    to: email,
                    subject: subject,
                    html: htmlBody,
                    text: plainTextBody,
                    replyTo: 'support@shopsnports.com',
                });
                console.log(`✅ Welcome email sent to: ${email}`);
            }
            else {
                console.warn('⚠️ SMTP_PASS not configured or email missing. Welcome email not sent.');
            }
        }
        catch (emailError) {
            console.error('⚠️ Error sending welcome email:', emailError);
            // Don't throw - email failure shouldn't fail the whole function
        }
        // ========== LOG ACTIVITY ==========
        await db.collection('activity_logs').add({
            type: 'user_registration',
            userId: uid,
            email: email,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            details: {
                displayName: displayName,
                phoneNumber: user.phoneNumber,
                emailVerified: user.emailVerified,
            },
        });
        // ========== NOTIFY ADMINS OF NEW CUSTOMER REGISTRATION ==========
        if (userProfile.role === 'customer') {
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
                            type: 'customer',
                            category: 'customer',
                            title: 'New Customer Registration',
                            message: `${displayName || 'A new customer'} has registered as a customer.`,
                            actionUrl: `/dashboard/customers/${uid}`,
                            isRead: false,
                            readAt: null,
                            metadata: {
                                customerId: uid,
                                customerEmail: email,
                                customerName: displayName,
                            },
                            priority: 'normal',
                            createdAt: now,
                            updatedAt: now,
                        });
                    });
                    await batch.commit();
                    console.log(`✅ Notified ${adminIds.length} admins of new customer registration`);
                }
            }
            catch (notifyError) {
                console.error('Error notifying admins:', notifyError);
                // Don't throw - notification failure shouldn't fail the whole function
            }
        }
        // ========== SEND WELCOME PUSH NOTIFICATION ==========
        try {
            // Get user's FCM tokens
            const userDoc = await db.collection('users').doc(uid).get();
            if (userDoc.exists) {
                const userData = userDoc.data();
                const fcmTokens = userData?.fcmTokens;
                if (fcmTokens && fcmTokens.length > 0) {
                    const welcomeNotification = {
                        notification: {
                            title: 'Welcome to ShopsNPorts!',
                            body: `Thank you for joining us, ${displayName || 'there'}! Start shipping today.`,
                        },
                        data: {
                            type: 'welcome',
                            userId: uid,
                            click_action: 'FLUTTER_NOTIFICATION_CLICK',
                        },
                        android: {
                            notification: {
                                clickAction: 'FLUTTER_NOTIFICATION_CLICK',
                                sound: 'default',
                            },
                            priority: 'high',
                        },
                        apns: {
                            payload: {
                                aps: {
                                    sound: 'default',
                                    badge: 1,
                                },
                            },
                        },
                    };
                    await admin.messaging().sendMulticast({
                        ...welcomeNotification,
                        tokens: fcmTokens,
                    });
                    console.log(`✅ Welcome push notification sent to user: ${uid}`);
                }
                else {
                    console.log(`ℹ️ No FCM tokens found for user ${uid} - push notification skipped`);
                }
            }
        }
        catch (pushError) {
            console.error('⚠️ Error sending welcome push notification:', pushError);
            // Don't throw - email already sent successfully
        }
        console.log(`Successfully processed user registration: ${uid}`);
        return { success: true, userId: uid };
    }
    catch (error) {
        console.error('Error in onUserCreated:', error);
        throw error;
    }
};
exports.onUserCreated = onUserCreated;

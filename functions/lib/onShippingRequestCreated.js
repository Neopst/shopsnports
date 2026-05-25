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
exports.onShippingRequestCreated = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const generateAffiliateTokens_1 = require("./generateAffiliateTokens");
const nodemailer_1 = __importDefault(require("nodemailer"));
const emailTemplateService_1 = require("./emailTemplateService");
const validation_1 = require("./validation");
/**
 * Cloud Function: Triggered when a new shipping request is submitted
 * - Validates shipping request data
 * - Validates affiliate token (if provided)
 * - Marks token as used
 * - Creates notifications for admin and affiliate
 * - Sends FCM notifications
 * - Logs activity
 *
 * Trigger: Create event on shippingRequests collection
 */
const onShippingRequestCreated = async (snapshot, context) => {
    try {
        const requestId = context.params.requestId;
        const requestData = snapshot.data();
        // ========== VALIDATE SHIPPING REQUEST DATA ==========
        try {
            (0, validation_1.validateShippingRequest)(requestData);
        }
        catch (validationError) {
            if (validationError instanceof validation_1.ValidationError) {
                console.error(`❌ Validation failed for request ${requestId}:`, validationError.message);
                // Delete the invalid request document
                await admin.firestore().collection('shippingRequests').doc(requestId).delete();
                throw new functions.https.HttpsError('invalid-argument', `Validation failed: ${validationError.message}`, { field: validationError.field, code: validationError.code });
            }
            throw validationError;
        }
        // Get Firestore instance
        const db = admin.firestore();
        const messaging = admin.messaging();
        console.log(`Processing new shipping request: ${requestId}`);
        console.log('Request data:', requestData);
        // ========== HANDLE AFFILIATE TOKEN (IF PROVIDED) ==========
        let affiliateTokenId = null;
        if (requestData.affiliateToken) {
            try {
                // Validate token
                const tokenQuery = await db
                    .collection('affiliate_tokens')
                    .where('token', '==', requestData.affiliateToken.toUpperCase())
                    .limit(1)
                    .get();
                if (!tokenQuery.empty) {
                    const tokenDoc = tokenQuery.docs[0];
                    const tokenData = tokenDoc.data();
                    affiliateTokenId = tokenDoc.id;
                    // Check if token is already used
                    if (tokenData.used) {
                        console.warn(`⚠️ Token ${requestData.affiliateToken} already used for request: ${tokenData.usedForRequest}`);
                    }
                    else if (new Date() > tokenData.expiresAt.toDate()) {
                        console.warn(`⚠️ Token ${requestData.affiliateToken} has expired`);
                    }
                    else {
                        // Mark token as used
                        await (0, generateAffiliateTokens_1.markTokenUsed)(db, requestData.affiliateToken, requestId, requestData.senderEmail);
                        // Tag the affiliate from the token
                        if (tokenData.affiliateId) {
                            await db
                                .collection('shippingRequests')
                                .doc(requestId)
                                .update({
                                affiliate: tokenData.affiliateId,
                                affiliateToken: requestData.affiliateToken,
                                affiliateTokenId: affiliateTokenId,
                                category: 'affiliate', // ensure category stays in sync
                                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                            });
                            console.log(`✅ Affiliate ${tokenData.affiliateId} auto-tagged from token`);
                        }
                    }
                }
                else {
                    console.warn(`Token ${requestData.affiliateToken} not found`);
                }
            }
            catch (tokenError) {
                console.error('Error validating affiliate token:', tokenError);
                // Continue - token validation is not critical for request creation
            }
        }
        // ========== GENERATE TRACKING NUMBER & UPDATE REQUEST ==========
        // Generate tracking number in format: SHP-YYYYMMDD-XXXXX
        const now = new Date();
        const dateStr = now.toISOString().split('T')[0].replace(/-/g, '');
        const randomSuffix = Math.random().toString(36).substring(2, 7).toUpperCase();
        const trackingNumber = `SHP-${dateStr}-${randomSuffix}`;
        // Update the request document with tracking number
        await db.collection('shippingRequests').doc(requestId).update({
            trackingNumber: trackingNumber,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log(`✅ Generated tracking number: ${trackingNumber}`);
        // ========== UPDATE REQUEST DATA AFTER TOKEN PROCESSING ==========
        // Re-read the request to get any affiliate auto-tagging
        const updatedRequestSnapshot = await db
            .collection('shippingRequests')
            .doc(requestId)
            .get();
        const updatedRequestData = updatedRequestSnapshot.data() || requestData;
        // 1. Create notification for ADMIN
        const adminNotification = {
            type: 'new_shipping_request',
            requestId: requestId,
            category: updatedRequestData.category || 'guest',
            senderName: updatedRequestData.clientName || updatedRequestData.senderName || 'Guest',
            senderEmail: updatedRequestData.clientEmail || updatedRequestData.senderEmail,
            senderPhone: updatedRequestData.clientPhone || updatedRequestData.senderPhone,
            freightType: updatedRequestData.type || updatedRequestData.freightType,
            destination: updatedRequestData.destination || updatedRequestData.destinationLocation,
            weight: updatedRequestData.weight || updatedRequestData.shipmentWeightKg,
            tokenUsed: !!updatedRequestData.affiliateToken,
            affiliateId: updatedRequestData.affiliate || null,
            targetRole: 'admin',
            targetUserId: null,
            read: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            message: `New shipping request from ${updatedRequestData.clientName || updatedRequestData.senderName}. Destination: ${updatedRequestData.destination || updatedRequestData.destinationLocation}${updatedRequestData.affiliate
                ? ` [Affiliate: ${updatedRequestData.affiliate}]`
                : ''}`,
            actionUrl: `/admin/shipping-requests/${requestId}`,
        };
        const adminNotifRef = await db
            .collection('notifications')
            .add(adminNotification);
        console.log(`Created admin notification: ${adminNotifRef.id}`);
        // 2. Create notification for AFFILIATE (if tagged)
        if (updatedRequestData.affiliate) {
            const affiliateNotification = {
                type: 'affiliate_request',
                requestId: requestId,
                category: updatedRequestData.category || 'guest',
                senderName: updatedRequestData.senderName || 'Guest',
                senderEmail: updatedRequestData.senderEmail,
                freightType: updatedRequestData.freightType,
                destination: updatedRequestData.destinationLocation,
                tokenUsed: !!updatedRequestData.affiliateToken,
                token: updatedRequestData.affiliateToken || null, // Display token to affiliate
                targetRole: 'affiliate',
                targetUserId: updatedRequestData.affiliate,
                read: false,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                message: `New referral: ${updatedRequestData.senderName} submitted a shipping request (${updatedRequestData.destinationLocation})${updatedRequestData.affiliateToken
                    ? ` using token: ${updatedRequestData.affiliateToken}`
                    : ''}`,
                actionUrl: `/affiliate/requests/${requestId}`,
            };
            const affiliateNotifRef = await db
                .collection('notifications')
                .add(affiliateNotification);
            console.log(`Created affiliate notification: ${affiliateNotifRef.id}`);
        }
        // 3. Get admin users for FCM notification (batch query)
        const adminSnapshot = await db
            .collection('users')
            .where('role', '==', 'admin')
            .limit(10) // Safety limit
            .get();
        const adminTokens = [];
        adminSnapshot.forEach((doc) => {
            const user = doc.data();
            if (user.fcmTokens && Array.isArray(user.fcmTokens)) {
                adminTokens.push(...user.fcmTokens);
            }
        });
        // 4. Send FCM to admins
        if (adminTokens.length > 0) {
            try {
                const adminPayload = {
                    notification: {
                        title: 'New Shipping Request',
                        body: `${updatedRequestData.senderName} → ${updatedRequestData.destinationLocation}`,
                        clickAction: 'FLUTTER_NOTIFICATION_CLICK',
                    },
                    data: {
                        type: 'new_shipping_request',
                        requestId: requestId,
                        senderName: updatedRequestData.senderName || 'Guest',
                        destination: updatedRequestData.destinationLocation,
                        ...(updatedRequestData.affiliate && {
                            affiliateId: updatedRequestData.affiliate,
                        }),
                    },
                };
                const adminFcmResponse = await messaging.sendMulticast({
                    ...adminPayload,
                    tokens: adminTokens,
                });
                console.log(`Sent FCM to ${adminFcmResponse.successCount} admin device(s)`);
                console.log(`Failed: ${adminFcmResponse.failureCount}`);
            }
            catch (fcmError) {
                console.error('FCM error for admins:', fcmError);
                // Continue even if FCM fails - notifications are already in Firestore
            }
        }
        // 5. Send FCM to affiliate if tagged
        if (updatedRequestData.affiliate) {
            try {
                const affiliateQuery = await db
                    .collection('users')
                    .doc(updatedRequestData.affiliate)
                    .get();
                if (affiliateQuery.exists) {
                    const affiliateData = affiliateQuery.data();
                    if (affiliateData?.fcmTokens && Array.isArray(affiliateData.fcmTokens)) {
                        const affiliatePayload = {
                            notification: {
                                title: 'New Referral Shipping Request',
                                body: `${updatedRequestData.senderName} → ${updatedRequestData.destinationLocation}`,
                                clickAction: 'FLUTTER_NOTIFICATION_CLICK',
                            },
                            data: {
                                type: 'affiliate_request',
                                requestId: requestId,
                                senderName: updatedRequestData.senderName || 'Guest',
                                ...(updatedRequestData.affiliateToken && {
                                    token: updatedRequestData.affiliateToken,
                                }),
                            },
                        };
                        const affiliateFcmResponse = await messaging.sendMulticast({
                            ...affiliatePayload,
                            tokens: affiliateData.fcmTokens,
                        });
                        console.log(`Sent FCM to affiliate: ${affiliateFcmResponse.successCount} device(s)`);
                    }
                }
            }
            catch (affiliateError) {
                console.error('Error sending FCM to affiliate:', affiliateError);
                // Continue - Firestore notification already created
            }
        }
        // 6. Send confirmation email to customer (using template service)
        try {
            const smtpHost = process.env.SMTP_HOST || 'smtp.shopsnports.com';
            const smtpPort = parseInt(process.env.SMTP_PORT || '587');
            const smtpUser = process.env.SMTP_USER || 'noreply@shopsnports.com';
            const smtpPass = process.env.SMTP_PASS || '';
            const smtpSecure = (process.env.SMTP_SECURE || 'false') === 'true';
            if (smtpPass) {
                const transporter = nodemailer_1.default.createTransport({
                    host: smtpHost,
                    port: smtpPort,
                    secure: smtpSecure,
                    auth: {
                        user: smtpUser,
                        pass: smtpPass,
                    },
                });
                const finalTrackingNumber = updatedRequestData.trackingNumber || trackingNumber;
                const senderName = updatedRequestData.clientName || updatedRequestData.senderName || 'Valued Customer';
                const destination = updatedRequestData.destination || updatedRequestData.destinationLocation || 'Unknown';
                const recipientEmail = updatedRequestData.clientEmail || updatedRequestData.senderEmail;
                // Determine if guest or registered user
                const templateType = updatedRequestData.userId ? 'shipping_confirmation' : 'guest_shipping_confirmation';
                // Get template from Firestore or use default
                const template = await (0, emailTemplateService_1.getTemplate)(templateType, db);
                const { subject, htmlBody, plainTextBody } = (0, emailTemplateService_1.renderTemplate)(template, {
                    senderName,
                    trackingNumber: finalTrackingNumber,
                    destination,
                    createdDate: new Date().toLocaleDateString(),
                    freightType: updatedRequestData.type || updatedRequestData.freightType || 'standard',
                });
                await transporter.sendMail({
                    from: smtpUser,
                    to: recipientEmail,
                    subject: subject,
                    html: htmlBody,
                    text: plainTextBody,
                    replyTo: 'support@shopsnports.com',
                });
                console.log(`✅ Confirmation email sent to ${recipientEmail} using template: ${templateType}`);
            }
            else {
                console.warn('⚠️ SMTP_PASS not configured. Confirmation email not sent.');
            }
        }
        catch (emailError) {
            console.error('⚠️ Error sending confirmation email:', emailError);
            // Continue - email is not critical for request creation
        }
        // 7. Log to activity feed
        await db.collection('activity_log').add({
            type: 'shipping_request_created',
            requestId: requestId,
            senderEmail: updatedRequestData.clientEmail || updatedRequestData.senderEmail,
            affiliateId: updatedRequestData.affiliate || null,
            affiliateToken: updatedRequestData.affiliateToken || null,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            details: {
                type: updatedRequestData.type || updatedRequestData.freightType,
                destination: updatedRequestData.destination || updatedRequestData.destinationLocation,
                weight: updatedRequestData.weight || updatedRequestData.shipmentWeightKg,
            },
        });
        console.log(`Successfully processed shipping request: ${requestId}`);
        return { success: true, requestId };
    }
    catch (error) {
        console.error('Error in onShippingRequestCreated:', error);
        throw error;
    }
};
exports.onShippingRequestCreated = onShippingRequestCreated;

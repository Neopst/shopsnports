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
Object.defineProperty(exports, "__esModule", { value: true });
exports.notifyShippingUpdate = exports.notifyAdmins = exports.sendPushNotification = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const validation_1 = require("./validation");
const notificationHistoryService_1 = require("./notificationHistoryService");
/**
 * Cloud Function: Send Push Notification
 * - Sends FCM push notifications to users, tokens, or topics
 * - Supports single user, multiple users, or topic-based targeting
 * - Logs statistics for delivery tracking
 *
 * Trigger: HTTPS Callable
 */
const sendPushNotification = async (data, context) => {
    const db = admin.firestore();
    const messaging = admin.messaging();
    const notificationHistoryService = (0, notificationHistoryService_1.createNotificationHistoryService)(db);
    // Validate request using validation module
    try {
        (0, validation_1.validateString)(data.title, { required: true, minLength: 1, maxLength: 200, fieldName: 'title' });
        (0, validation_1.validateString)(data.body, { required: true, minLength: 1, maxLength: 1000, fieldName: 'body' });
        if (data.targetUserIds !== undefined) {
            (0, validation_1.validateArray)(data.targetUserIds, { maxLength: 100, fieldName: 'targetUserIds' });
        }
        if (data.targetTokens !== undefined) {
            (0, validation_1.validateArray)(data.targetTokens, { maxLength: 500, fieldName: 'targetTokens' });
        }
    }
    catch (validationError) {
        if (validationError instanceof validation_1.ValidationError) {
            throw new functions.https.HttpsError('invalid-argument', validationError.message);
        }
        throw validationError;
    }
    const tokens = [];
    const targetedUsers = data.targetUserIds || [];
    const statsId = `stats_${Date.now()}`;
    const notificationId = `notif_${Date.now()}_${Math.random().toString(36).substring(7)}`;
    console.log(`📱 Sending push notification: "${data.title}"`);
    // Log to notification history
    const historyEntry = {
        notificationId,
        type: data.notificationType || 'push',
        title: data.title,
        body: data.body,
        targetUserId: targetedUsers.length > 0 ? targetedUsers[0] : undefined,
        targetTokens: data.targetTokens,
        targetTopic: data.targetTopic,
        deliveryStatus: 'pending',
        sentCount: 0,
        deliveredCount: 0,
        openedCount: 0,
        clickedCount: 0,
        failedCount: 0,
        metadata: {
            imageUrl: data.imageUrl,
            clickAction: data.clickAction,
            customData: data.data,
        },
        createdBy: context.auth?.uid || 'system',
        createdByRole: context.auth?.token.admin ? 'admin' : 'system',
    };
    await notificationHistoryService.logNotification(historyEntry);
    try {
        // ==================== GATHER TOKENS ====================
        // If targeting users, get their FCM tokens
        if (targetedUsers.length > 0) {
            const tokensSnapshot = await db
                .collection('fcm_tokens')
                .where('userId', 'in', targetedUsers.length > 10 ? targetedUsers.slice(0, 10) : targetedUsers)
                .where('isActive', '==', true)
                .get();
            tokensSnapshot.docs.forEach((doc) => {
                const token = doc.data().token;
                if (token && !tokens.includes(token)) {
                    tokens.push(token);
                }
            });
            console.log(`Found ${tokens.length} active tokens for ${targetedUsers.length} users`);
        }
        // Add explicitly provided tokens
        if (data.targetTokens && data.targetTokens.length > 0) {
            data.targetTokens.forEach((token) => {
                if (!tokens.includes(token)) {
                    tokens.push(token);
                }
            });
        }
        // ==================== SEND NOTIFICATION ====================
        let successCount = 0;
        let failureCount = 0;
        // Build FCM payload
        const notificationPayload = {
            title: data.title,
            body: data.body,
            imageUrl: data.imageUrl,
        };
        const payload = {
            tokens: tokens, // tokens is defined earlier in the function
            notification: notificationPayload,
            data: data.data ? {
                ...data.data,
                click_action: data.clickAction || 'FLUTTER_NOTIFICATION_CLICK',
                notificationId: notificationId,
            } : {
                click_action: data.clickAction || 'FLUTTER_NOTIFICATION_CLICK',
                notificationId: notificationId,
            },
            android: {
                notification: {
                    clickAction: data.clickAction || 'FLUTTER_NOTIFICATION_CLICK',
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
        // Send to tokens
        if (tokens.length > 0) {
            payload.tokens = tokens;
            const response = await messaging.sendMulticast(payload);
            successCount = response.successCount;
            failureCount = response.failureCount;
            console.log(`Multicast sent: ${successCount} success, ${failureCount} failures`);
            // Update notification history
            await notificationHistoryService.updateDeliveryStatus(notificationId, 'sent', {
                sentCount: successCount,
                failedCount: failureCount,
            });
            // Handle failed tokens
            if (response.failureCount > 0) {
                const failedTokens = [];
                response.responses.forEach((resp, idx) => {
                    if (!resp.success) {
                        failedTokens.push(tokens[idx]);
                        console.error(`Failed token ${idx}:`, resp.error);
                    }
                });
                // Deactivate failed/invalid tokens
                if (failedTokens.length > 0) {
                    const batch = db.batch();
                    const invalidTokens = await db
                        .collection('fcm_tokens')
                        .where('token', 'in', failedTokens)
                        .get();
                    invalidTokens.docs.forEach((docSnapshot) => {
                        batch.update(docSnapshot.ref, { isActive: false });
                    });
                    await batch.commit();
                    console.log(`Deactivated ${failedTokens.length} invalid tokens`);
                }
            }
        }
        // Send to topic
        if (data.targetTopic) {
            const topicPayload = {
                topic: data.targetTopic,
                notification: notificationPayload,
                data: payload.data,
                android: payload.android,
                apns: payload.apns,
            };
            await messaging.send(topicPayload);
            console.log(`✅ Sent to topic: ${data.targetTopic}`);
        }
        // ==================== LOG STATISTICS ====================
        await db.collection('push_notification_stats').doc(statsId).set({
            campaignId: statsId,
            notificationId,
            title: data.title,
            body: data.body,
            sentCount: successCount + (data.targetTopic ? 1 : 0),
            deliveredCount: 0, // Updated when delivery receipts received
            openedCount: 0,
            failedCount: failureCount,
            targetedUsers: targetedUsers,
            targetTopic: data.targetTopic,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            createdBy: context.auth?.uid || 'system',
            status: 'completed',
        });
        return {
            success: true,
            statsId,
            notificationId,
            sentCount: successCount + (data.targetTopic ? 1 : 0),
            failureCount,
            message: `Notification sent to ${successCount} devices${data.targetTopic ? ' + topic subscribers' : ''}`,
        };
    }
    catch (error) {
        console.error('❌ Error sending push notification:', error);
        // Update notification history with failed status
        await notificationHistoryService.updateDeliveryStatus(notificationId, 'failed', {
            errorMessage: String(error),
        });
        // Log failed attempt
        await db.collection('push_notification_stats').doc(statsId).set({
            campaignId: statsId,
            notificationId,
            title: data.title,
            body: data.body,
            sentCount: 0,
            deliveredCount: 0,
            openedCount: 0,
            failedCount: 0,
            error: String(error),
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            createdBy: context.auth?.uid || 'system',
            status: 'failed',
        });
        throw new functions.https.HttpsError('internal', 'Failed to send push notification', error);
    }
};
exports.sendPushNotification = sendPushNotification;
/**
 * Cloud Function: Send notification to all admin users
 * Convenience function for admin alerts
 */
const notifyAdmins = async (data, context) => {
    const db = admin.firestore();
    const messaging = admin.messaging();
    // Get all admin users with FCM tokens
    const adminSnapshot = await db
        .collection('users')
        .where('role', '==', 'admin')
        .get();
    const adminTokens = [];
    adminSnapshot.docs.forEach((doc) => {
        const tokens = doc.data().fcmTokens;
        if (tokens && Array.isArray(tokens)) {
            adminTokens.push(...tokens);
        }
    });
    if (adminTokens.length === 0) {
        console.log('No admin tokens found');
        return { success: true, message: 'No admins to notify' };
    }
    const notification = {
        title: data.title,
        body: data.body,
    };
    const payload = {
        tokens: adminTokens,
        notification,
        data: {
            type: data.type || 'admin_alert',
            ...data.metadata || {},
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
    };
    const response = await messaging.sendMulticast(payload);
    return {
        success: true,
        sentCount: response.successCount,
        failureCount: response.failureCount,
        message: `Admin notification sent to ${response.successCount} devices`,
    };
};
exports.notifyAdmins = notifyAdmins;
/**
 * Cloud Function: Notify user of shipping request update
 * Called from onShippingRequestUpdated trigger
 */
const notifyShippingUpdate = async (data) => {
    const db = admin.firestore();
    const messaging = admin.messaging();
    // Get user's FCM tokens
    const tokensSnapshot = await db
        .collection('fcm_tokens')
        .where('userId', '==', data.userId)
        .where('isActive', '==', true)
        .get();
    if (tokensSnapshot.empty) {
        console.log(`No FCM tokens found for user ${data.userId}`);
        return { success: false, message: 'No tokens' };
    }
    const tokens = tokensSnapshot.docs.map((doc) => doc.data().token);
    const notification = {
        title: data.title,
        body: data.body,
    };
    const payload = {
        tokens: tokens,
        notification,
        data: {
            type: 'shipping_update',
            requestId: data.requestId,
            status: data.status,
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
    };
    const response = await messaging.sendMulticast(payload);
    return {
        success: true,
        sentCount: response.successCount,
        failureCount: response.failureCount,
    };
};
exports.notifyShippingUpdate = notifyShippingUpdate;

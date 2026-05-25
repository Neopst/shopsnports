import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { validateString, validateArray, validateNumber, ValidationError } from './validation';
import { createNotificationHistoryService, NotificationHistoryEntry } from './notificationHistoryService';

/**
 * Cloud Function: Send Push Notification
 * - Sends FCM push notifications to users, tokens, or topics
 * - Supports single user, multiple users, or topic-based targeting
 * - Logs statistics for delivery tracking
 *
 * Trigger: HTTPS Callable
 */
export const sendPushNotification = async (
  data: {
    targetUserIds?: string[];
    targetTokens?: string[];
    targetTopic?: string;
    title: string;
    body: string;
    imageUrl?: string;
    data?: Record<string, string>;
    clickAction?: string;
    notificationType?: string;
  },
  context: functions.https.CallableContext
) => {
  const db = admin.firestore();
  const messaging = admin.messaging();
  const notificationHistoryService = createNotificationHistoryService(db);

  // Validate request using validation module
  try {
    validateString(data.title, { required: true, minLength: 1, maxLength: 200, fieldName: 'title' });
    validateString(data.body, { required: true, minLength: 1, maxLength: 1000, fieldName: 'body' });
    if (data.targetUserIds !== undefined) {
      validateArray(data.targetUserIds, { maxLength: 100, fieldName: 'targetUserIds' });
    }
    if (data.targetTokens !== undefined) {
      validateArray(data.targetTokens, { maxLength: 500, fieldName: 'targetTokens' });
    }
  } catch (validationError) {
    if (validationError instanceof ValidationError) {
      throw new functions.https.HttpsError('invalid-argument', validationError.message);
    }
    throw validationError;
  }

  const tokens: string[] = [];
  const targetedUsers: string[] = data.targetUserIds || [];
  const statsId = `stats_${Date.now()}`;
  const notificationId = `notif_${Date.now()}_${Math.random().toString(36).substring(7)}`;

  console.log(`📱 Sending push notification: "${data.title}"`);

  // Log to notification history
  const historyEntry: NotificationHistoryEntry = {
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
    const notificationPayload: admin.messaging.Notification = {
      title: data.title,
      body: data.body,
      imageUrl: data.imageUrl,
    };

    const payload: admin.messaging.MulticastMessage = {
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
        priority: 'high' as const,
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
        const failedTokens: string[] = [];
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
      const topicPayload: admin.messaging.Message = {
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
  } catch (error) {
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

    throw new functions.https.HttpsError(
      'internal',
      'Failed to send push notification',
      error
    );
  }
};

/**
 * Cloud Function: Send notification to all admin users
 * Convenience function for admin alerts
 */
export const notifyAdmins = async (
  data: {
    title: string;
    body: string;
    type?: string;
    metadata?: Record<string, string>;
  },
  context: functions.https.CallableContext
) => {
  const db = admin.firestore();
  const messaging = admin.messaging();

  // Get all admin users with FCM tokens
  const adminSnapshot = await db
    .collection('users')
    .where('role', '==', 'admin')
    .get();

  const adminTokens: string[] = [];
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

  const notification: admin.messaging.Notification = {
    title: data.title,
    body: data.body,
  };

  const payload: admin.messaging.MulticastMessage = {
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

/**
 * Cloud Function: Notify user of shipping request update
 * Called from onShippingRequestUpdated trigger
 */
export const notifyShippingUpdate = async (
  data: {
    userId: string;
    requestId: string;
    status: string;
    title: string;
    body: string;
  }
) => {
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

  const tokens = tokensSnapshot.docs.map((doc) => doc.data().token as string);

  const notification: admin.messaging.Notification = {
    title: data.title,
    body: data.body,
  };

  const payload: admin.messaging.MulticastMessage = {
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
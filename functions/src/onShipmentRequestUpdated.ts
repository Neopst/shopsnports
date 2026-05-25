import * as admin from 'firebase-admin';
import { Change, EventContext } from 'firebase-functions';
// Removed admin.initializeApp() - Firebase Functions auto-initializes firebase-admin

export async function onShipmentRequestUpdated(change: any, context: EventContext) {
  const before = change.before?.data?.();
  const after = change.after?.data?.();

  // Only handle transition to completed
  if (!before || !after) return null;
  if (before.status === 'completed' || after.status !== 'completed') return null;

  const affiliateId = after.affiliateId;
  const requestId = context.params.requestId;

  // Create a payout record for the affiliate (amount may be provided on request)
  const payoutAmount = after.payoutAmount ?? after.affiliatePayout ?? 0;
  const payoutDoc = {
    amount: payoutAmount,
    currency: after.currency ?? 'NGN',
    requestId,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  try {
    if (affiliateId) {
      await admin.firestore().collection('affiliates').doc(affiliateId).collection('payouts').add(payoutDoc);
    }

    // Create notification documents for admin and affiliate
    const notifForAdmin = {
      title: 'Shipment request completed',
      body: `Request ${requestId} marked completed by admin`,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      meta: { requestId }
    };
    await admin.firestore().collection('notifications').add(notifForAdmin);

    if (affiliateId) {
      const notifForAffiliate = {
        title: 'Your shipment request was completed',
        body: `Request ${requestId} has been completed and payout created`,
        userId: affiliateId,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        meta: { requestId }
      };
      await admin.firestore().collection('notifications').add(notifForAffiliate);
    }

    // FCM sends (best-effort)
    try {
      const payload = {
        notification: {
          title: 'Shipment request completed',
          body: `Request ${requestId} is completed`,
        },
        data: { requestId, type: 'shipment_completed' }
      };
      await admin.messaging().sendToTopic('admins', payload as any);
      if (affiliateId) {
        await admin.messaging().sendToTopic(`affiliate-${affiliateId}`, payload as any);
      }
    } catch (fcmErr) {
      console.error('FCM send error on update', fcmErr);
    }

    return true;
  } catch (err) {
    console.error('Error handling shipmentRequest update', err);
    return null;
  }
}

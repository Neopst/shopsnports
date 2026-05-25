import * as admin from 'firebase-admin';
import { Change, EventContext } from 'firebase-functions';
// Removed admin.initializeApp() - Firebase Functions auto-initializes firebase-admin

export async function onShipmentRequestCreated(snapshot: any, context: EventContext) {
  const data = snapshot.data();
  const affiliateId = data?.affiliateId;
  // Create notification documents for admin and affiliate
  const notifForAdmin = {
    title: 'New shipment request',
    body: `Request ${context.params.requestId} from affiliate ${affiliateId}`,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    meta: { requestId: context.params.requestId }
  };
  await admin.firestore().collection('notifications').add(notifForAdmin);

  const notifForAffiliate = {
    title: 'Client submitted a shipment request',
    body: `We received a new request. ID: ${context.params.requestId}`,
    userId: affiliateId,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    meta: { requestId: context.params.requestId }
  };
  await admin.firestore().collection('notifications').add(notifForAffiliate);

  // Send FCM to admin topic and affiliate topic (requires clients to subscribe)
  try {
    const payloadForAdmin = {
      notification: {
        title: 'New shipment request',
        body: `Request ${context.params.requestId} from affiliate ${affiliateId}`,
      },
      data: { requestId: context.params.requestId, type: 'shipment_request' }
    };
    await admin.messaging().sendToTopic('admins', payloadForAdmin as any);

    if (affiliateId) {
      const topic = `affiliate-${affiliateId}`;
      const payloadForAff = {
        notification: {
          title: 'Client submitted a shipment request',
          body: `Request ID: ${context.params.requestId}`,
        },
        data: { requestId: context.params.requestId, type: 'shipment_request' }
      };
      await admin.messaging().sendToTopic(topic, payloadForAff as any);
    }
  } catch (err) {
    // Log but do not crash the trigger
    console.error('FCM send error', err);
  }

  return true;
}

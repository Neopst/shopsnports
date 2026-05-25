import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

/**
 * Cloud Function: Shipment Delivery Notification
 *
 * DEPRECATED: Commission calculation moved to onShippingRequestUpdated
 * This function now only logs delivery events for analytics
 *
 * Triggered when shipping request status changes to "delivered"
 * Logs delivery activity for analytics and reporting
 */
export const onShipmentDelivered = functions.firestore
  .document('shippingRequests/{requestId}')
  .onUpdate(async (change, context) => {
    const requestId = context.params.requestId;
    const beforeData = change.before.data();
    const afterData = change.after.data();

    if (!beforeData || !afterData) {
      console.error('No data found for shipment update:', requestId);
      return;
    }

    // Check if status changed to "delivered"
    const beforeStatus = beforeData.status;
    const afterStatus = afterData.status;

    if (beforeStatus === afterStatus || afterStatus !== 'delivered') {
      console.log(`Status not changed to delivered for request ${requestId}, skipping`);
      return;
    }

    console.log(`Shipment ${requestId} marked as delivered - logging for analytics`);

    const db = admin.firestore();

    try {
      // Log delivery activity for analytics
      await db.collection('activity_log').add({
        type: 'shipment_delivered',
        requestId: requestId,
        affiliateId: afterData.affiliateId || afterData.affiliate || null,
        freightType: afterData.type || afterData.freightType || 'unknown',
        destination: afterData.destination || afterData.destinationLocation || 'unknown',
        shipmentPrice: afterData.shipmentPrice || afterData.totalPrice || 0,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        performedBy: 'system',
      });

      // Update shipping request with delivery timestamp
      await db.collection('shippingRequests').doc(requestId).update({
        actualDeliveryDate: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`✅ Delivery logged for shipment ${requestId}`);
      return { success: true, requestId };

    } catch (error) {
      console.error('Error in onShipmentDelivered:', error);
      // Don't throw - logging failure shouldn't fail the shipment update
      return { success: false, error: error.message };
    }
  });
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { validateId, validateNumber, ValidationError } from './validation';

/**
 * Cloud Function: Calculate commission for affiliate on shipping request completion
 * 
 * Triggered manually by admin OR auto-triggered when shipping request status = "delivered"
 * 
 * Commission = shipmentPrice × affiliateCommissionRate
 * Example: $100 shipment × 15% = $15 commission
 */
export const calculateCommission = async (
  data: {
    shippingRequestId: string;
    affiliateId: string;
    shipmentPrice: number;
    commissionRate?: number; // Defaults to affiliate's rate from affiliates/ collection
  },
  context: functions.https.CallableContext
) => {
  try {
    // Verify admin authentication
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'Must be authenticated'
      );
    }

    if (!context.auth.token.admin) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Only admins can calculate commissions'
      );
    }

    const db = admin.firestore();
    const {
      shippingRequestId,
      affiliateId,
      shipmentPrice,
      commissionRate,
    } = data;

    // Validate inputs using validation module
    try {
      validateId(shippingRequestId, 'shippingRequestId');
      validateId(affiliateId, 'affiliateId');
      validateNumber(shipmentPrice, { required: true, min: 0.01, max: 1000000, fieldName: 'shipmentPrice' });
      if (commissionRate !== undefined) {
        validateNumber(commissionRate, { min: 0, max: 100, fieldName: 'commissionRate' });
      }
    } catch (validationError) {
      if (validationError instanceof ValidationError) {
        throw new functions.https.HttpsError('invalid-argument', validationError.message);
      }
      throw validationError;
    }

    console.log(`Calculating commission:
      Request: ${shippingRequestId}
      Affiliate: ${affiliateId}
      Price: $${shipmentPrice}
      Rate: ${commissionRate || 'fetch from profile'}%`);

    // Get affiliate profile to fetch commission rate if not provided
    let rate = commissionRate ?? 15.0; // Default 15%
    if (!commissionRate) {
      const affiliateDoc = await db
        .collection('affiliates')
        .doc(affiliateId)
        .get();

      if (affiliateDoc.exists) {
        const affiliateData = affiliateDoc.data();
        rate = affiliateData?.commissionRate ?? 15.0;
      }
    }

    // Calculate commission amount
    const commissionAmount = (shipmentPrice * rate) / 100;

    console.log(`Commission calculated: $${shipmentPrice} × ${rate}% = $${commissionAmount.toFixed(2)}`);

    // Use transaction for atomic multi-document operations
    const result = await db.runTransaction(async (transaction) => {
      // Check if commission already exists for this request
      const existingCommission = await transaction.get(
        db.collection('commissions')
          .where('shippingRequestId', '==', shippingRequestId)
          .where('affiliateId', '==', affiliateId)
          .limit(1)
      );

      if (!existingCommission.empty) {
        console.log('Commission already exists, updating...');
        const existingId = existingCommission.docs[0].id;

        transaction.update(db.collection('commissions').doc(existingId), {
          commissionAmount,
          commissionRate: rate,
          shipmentPrice,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        return { existingId, isUpdate: true };
      }

      // Create new commission record
      const commissionRef = db.collection('commissions').doc();
      transaction.set(commissionRef, {
        shippingRequestId,
        affiliateId,
        shipmentPrice,
        commissionRate: rate,
        commissionAmount,
        status: 'pending', // pending → approved → paid
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        createdBy: context.auth.uid,
      });

      // Update affiliate's totalEarnings counter within transaction
      const affiliateRef = db.collection('affiliates').doc(affiliateId);
      transaction.update(affiliateRef, {
        totalEarnings: admin.firestore.FieldValue.increment(commissionAmount),
        lastCommissionDate: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Create notification for affiliate within transaction
      const notificationRef = db.collection('notifications').doc();
      transaction.set(notificationRef, {
        type: 'commission_earned',
        commissionId: commissionRef.id,
        shippingRequestId,
        affiliateId,
        targetUserId: affiliateId,
        targetRole: 'affiliate',
        read: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        message: `You earned $${commissionAmount.toFixed(2)} commission!`,
        actionUrl: `/affiliate/commissions/${commissionRef.id}`,
      });

      // Log activity within transaction
      const activityRef = db.collection('activity_log').doc();
      transaction.set(activityRef, {
        type: 'commission_calculated',
        commissionId: commissionRef.id,
        shippingRequestId,
        affiliateId,
        amount: commissionAmount,
        rate,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        performedBy: context.auth.uid,
      });

      console.log(`Commission created: ${commissionRef.id}`);
      return { commissionId: commissionRef.id, isUpdate: false };
    });

    return {
      success: true,
      message: result.isUpdate ? 'Commission updated' : 'Commission calculated and recorded',
      commissionId: result.existingId || result.commissionId,
      amount: commissionAmount,
      rate,
    };
  } catch (error) {
    console.error('Commission calculation error:', error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError(
      'internal',
      'Commission calculation failed'
    );
  }
};

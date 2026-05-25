import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { validateString, ValidationError } from './validation';

/**
 * Cloud Function: Generate Invoice on Shipment Delivery
 *
 * This function is triggered when a shipping request is marked as "delivered"
 * It creates TWO types of invoices:
 * 1. Affiliate Commission Invoice: For affiliate requests (shows commission earned)
 * 2. Service Invoice: For customer/guest requests (shows shipping fee)
 *
 * Invoices are created as "draft" - admin must fill details and mark as "sent"
 *
 * Trigger: Custom callable OR automatic on delivery status change
 */

/**
 * Validate generate invoice input
 */
function validateGenerateInvoiceInput(data: any): void {
  if (!data || typeof data !== 'object') {
    throw new ValidationError('Request data must be an object', 'data', 'INVALID_TYPE');
  }

  const { shippingRequestId } = data;

  validateString(shippingRequestId, {
    required: true,
    minLength: 10,
    maxLength: 100,
    fieldName: 'shippingRequestId'
  });
}

export const generateInvoice = functions.https.onCall(
  async (data, context) => {
    try {
      // Verify caller is authenticated
      if (!context.auth) {
        throw new functions.https.HttpsError(
          'unauthenticated',
          'User must be authenticated'
        );
      }

      // Validate input
      validateGenerateInvoiceInput(data);

      const { shippingRequestId } = data;

      const db = admin.firestore();

      // Get the shipping request
      const requestDoc = await db
        .collection('shippingRequests')
        .doc(shippingRequestId)
        .get();

      if (!requestDoc.exists) {
        throw new functions.https.HttpsError(
          'not-found',
          `Shipping request ${shippingRequestId} not found`
        );
      }

      const requestData = requestDoc.data()!;

      console.log(`📄 Generating invoice for shipping request: ${shippingRequestId}`, {
        senderType: requestData.senderType,
        affiliate: requestData.affiliate,
        price: requestData.shipmentPrice,
      });

      // Generate invoice number
      const invoiceNumber = `INV-${Date.now()}-${Math.floor(
        Math.random() * 1000
      )}`;

      // Determine invoice type based on request
      const isAffiliateRequest = !!requestData.affiliate;
      let invoiceType: 'affiliate_commission' | 'service_fee' | 'vendor';
      let recipientType: 'affiliate' | 'customer' | 'guest';
      let invoiceAmount: number;
      let invoiceTitle: string;
      let invoiceDescription: string;

      if (isAffiliateRequest) {
        // ========== AFFILIATE COMMISSION INVOICE ==========
        recipientType = 'affiliate';
        invoiceType = 'affiliate_commission';

        // Get the commission record that was auto-generated
        const commissionsQuery = await db
          .collection('commissions')
          .where('shippingRequestId', '==', shippingRequestId)
          .where('affiliateId', '==', requestData.affiliate)
          .limit(1)
          .get();

        if (commissionsQuery.empty) {
          throw new functions.https.HttpsError(
            'failed-precondition',
            'Commission record not found. Make sure shipment was marked as delivered first.'
          );
        }

        const commissionData = commissionsQuery.docs[0].data();
        invoiceAmount = commissionData.commissionAmount;
        invoiceTitle = 'Commission Invoice';
        invoiceDescription = `Commission earned on shipment from ${requestData.senderName} to ${requestData.receiverName}`;

        console.log(`📋 Creating affiliate commission invoice: $${invoiceAmount.toFixed(2)}`);
      } else {
        // ========== CUSTOMER/GUEST SERVICE FEE INVOICE ==========
        recipientType =
          requestData.senderType === 'guest' ? 'guest' : 'customer';
        invoiceType = 'service_fee';
        invoiceAmount = requestData.shipmentPrice || 0;
        invoiceTitle = 'Service Fee Invoice';
        invoiceDescription = `Service fee for shipping request from ${requestData.senderName} to ${requestData.receiverName}`;

        console.log(
          `📋 Creating customer invoice: $${invoiceAmount.toFixed(2)}`
        );
      }

      // ========== CREATE INVOICE DOCUMENT WITH TRANSACTION ==========
      // Use transaction for atomic invoice creation and shipping request update
      const invoiceResult = await db.runTransaction(async (transaction) => {
        const invoiceRef = db.collection('invoices').doc();

        const invoiceData = {
          // System fields
          invoiceNumber,
          invoiceType,
          status: 'draft',
          recipientType,

          // Links
          shippingRequestId,
          affiliateId: requestData.affiliate || null,
          customerId: requestData.userId || null,
          guestEmail: requestData.senderEmail || null,

          // Invoice details
          amount: invoiceAmount,
          currency: 'USD',
          lineItems: [
            {
              description: invoiceDescription,
              quantity: 1,
              unitPrice: invoiceAmount,
              total: invoiceAmount,
            },
          ],

          // Recipient info
          billTo: {
            name:
              recipientType === 'affiliate'
                ? requestData.affiliate
                : requestData.senderName,
            email: requestData.senderEmail,
            phone: requestData.senderPhone || null,
            address: requestData.departingLocation,
          },

        // Shipment details (for reference)
        shipmentDetails: {
          senderName: requestData.senderName,
          senderEmail: requestData.senderEmail,
          receiverName: requestData.receiverName,
          receiverEmail: requestData.receiverEmail,
          freightType: requestData.freightType,
          itemDescription: requestData.itemDescription,
          weight: requestData.shipmentWeightKg,
          departingLocation: requestData.departingLocation,
          destinationLocation: requestData.destinationLocation,
        },

        // Commission info (if affiliate)
        ...(isAffiliateRequest && {
          commissionRate: requestData.commissionRate || 15.0,
          commissionAmount: invoiceAmount,
          earnedBy: requestData.affiliate,
        }),

        // Admin editing fields
        notes: '', // Admin can add custom notes
        adminNotes: `Auto-generated for ${recipientType}`,
        filledBy: null, // Will be filled when admin marks as "sent"
        sentBy: null,

        // Timestamps
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        createdBy: 'system-auto-generation',
        sentAt: null,
        paidAt: null,
        viewedAt: null,
        lastModifiedAt: admin.firestore.FieldValue.serverTimestamp(),
        };

        // Set invoice within transaction
        transaction.set(invoiceRef, invoiceData);

        // Update shipping request with invoice reference within transaction
        transaction.update(
          db.collection('shippingRequests').doc(shippingRequestId),
          {
            invoiceId: invoiceRef.id,
            invoiceStatus: 'draft',
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          }
        );

        return { invoiceRef, invoiceData };
      });

      console.log(`✅ Invoice created: ${invoiceResult.invoiceRef.id}`);

      // ========== CREATE NOTIFICATION FOR ADMIN (outside transaction - not critical) ==========
      await db.collection('notifications').add({
        type: 'invoice_ready_for_review',
        invoiceId: invoiceResult.invoiceRef.id,
        shippingRequestId,
        targetRole: 'admin',
        read: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        message: `📄 Invoice #${invoiceNumber} ready for review (${recipientType})`,
        actionUrl: `/admin/invoices/${invoiceResult.invoiceRef.id}`,
      });

      // ========== LOG ACTIVITY (outside transaction - not critical) ==========
      await db.collection('activity_log').add({
        type: 'invoice_generated',
        invoiceId: invoiceResult.invoiceRef.id,
        invoiceNumber,
        shippingRequestId,
        invoiceType,
        recipientType,
        amount: invoiceAmount,
        createdBy: 'system-auto-generation',
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      return {
        success: true,
        invoiceId: invoiceResult.invoiceRef.id,
        invoiceNumber,
        invoiceType,
        amount: invoiceAmount,
        status: 'draft',
      };
    } catch (error) {
      console.error('Error generating invoice:', error);
      throw error;
    }
  }
);

/**
 * Alternative: Export as HTTPS function for admin dashboard integration
 * This allows invoice generation to be triggered from admin panel as well
 */
export const generateInvoiceHttp = functions.https.onRequest(
  async (req, res) => {
    try {
      const { shippingRequestId } = req.body;

      if (!shippingRequestId) {
        res.status(400).json({
          error: 'shippingRequestId is required',
        });
        return;
      }

      const db = admin.firestore();

      // Get the shipping request
      const requestDoc = await db
        .collection('shippingRequests')
        .doc(shippingRequestId)
        .get();

      if (!requestDoc.exists) {
        res.status(404).json({
          error: `Shipping request ${shippingRequestId} not found`,
        });
        return;
      }

      const requestData = requestDoc.data()!;

      // Generate invoice
      const invoiceNumber = `INV-${Date.now()}-${Math.floor(
        Math.random() * 1000
      )}`;
      const isAffiliateRequest = !!requestData.affiliate;
      const invoiceAmount = isAffiliateRequest
        ? requestData.commissionAmount || requestData.shipmentPrice
        : requestData.shipmentPrice;

      const invoiceRef = await db.collection('invoices').add({
        invoiceNumber,
        invoiceType: isAffiliateRequest
          ? 'affiliate_commission'
          : 'service_fee',
        status: 'draft',
        recipientType: isAffiliateRequest ? 'affiliate' : 'customer',
        shippingRequestId,
        affiliateId: requestData.affiliate || null,
        amount: invoiceAmount,
        currency: 'USD',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      res.json({
        success: true,
        invoiceId: invoiceRef.id,
        invoiceNumber,
      });
    } catch (error) {
      console.error('Error in generateInvoiceHttp:', error);
      res.status(500).json({
        error: 'Failed to generate invoice',
      });
    }
  }
);

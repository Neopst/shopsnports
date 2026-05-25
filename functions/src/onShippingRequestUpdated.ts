import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import nodemailer from 'nodemailer';
import { getTemplate, renderTemplate } from './emailTemplateService';
import { getSmtpConfig, validateSmtpConfig } from './smtpConfig';
import { calculateTax } from './taxCalculation';
import { calculatePayoutBreakdown } from './commissionCalculation';

/**
 * Cloud Function: Triggered when a shipping request is updated
 * - Sends notification when status changes
 * - Notifies shipper when assigned
 * - Sends EMAIL notifications for status updates (including guests) using Firestore templates
 * - AUTOMATIC: Generates payout when marked as delivered (if affiliate tagged)
 *
 * Trigger: Update event on shippingRequests collection
 */
export const onShippingRequestUpdated = async (
  change: any,
  context: functions.EventContext
) => {
  try {
    const requestId = context.params.requestId;
    const previousData = change.before.data();
    const newData = change.after.data();

    const db = admin.firestore();
    const messaging = admin.messaging();

    // Check what changed
    const statusChanged = previousData.status !== newData.status;
    const assignedChanged =
      previousData.assignedTo !== newData.assignedTo;

    console.log(`Shipping request ${requestId} updated:`, {
      previousStatus: previousData.status,
      newStatus: newData.status,
      previousAssigned: previousData.assignedTo,
      newAssigned: newData.assignedTo,
      previousAffiliate: previousData.affiliate,
      newAffiliate: newData.affiliate,
    });

    // If affiliate was just assigned after creation, keep category synced
    if (!previousData.affiliate && newData.affiliate) {
      console.log(`Affiliate ${newData.affiliate} added, updating category`);
      await db.collection('shippingRequests').doc(requestId).update({
        category: 'affiliate',
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    // ========== AUTOMATIC PAYOUT GENERATION ON DELIVERY ==========
    // This is the KEY change: When admin marks as "delivered", auto-generate payout for affiliate
    if (statusChanged && newData.status === 'delivered' && newData.affiliate) {
      console.log(`🎉 Shipment marked delivered! Affiliate tagged: ${newData.affiliate}`);
      console.log(`Auto-generating payout for affiliate ${newData.affiliate}`);

      // ========== PREVENT DOUBLE PAYOUT: Check if commission already exists ==========
      const existingCommission = await db
        .collection('commissions')
        .where('shippingRequestId', '==', requestId)
        .where('affiliateId', '==', newData.affiliate)
        .limit(1)
        .get();

      if (!existingCommission.empty) {
        console.warn(
          `⚠️ Commission already exists for shipping request ${requestId} and affiliate ${newData.affiliate}. Skipping duplicate payout generation.`
        );
      } else {
        // Get shipment price (admin must have set this before marking delivered)
        const shipmentPrice = newData.shipmentPrice || 0;
        if (shipmentPrice <= 0) {
          console.warn(
            `⚠️ Shipment price not set for request ${requestId}, skipping auto payout generation`
          );
        } else {
          try {
            // Get affiliate commission rate
            const affiliateDoc = await db
              .collection('affiliates')
              .doc(newData.affiliate)
              .get();

            if (affiliateDoc.exists) {
              const affiliateData = affiliateDoc.data();
              const commissionRate = affiliateData?.commissionRate ?? 15.0;
              const commissionAmount = (shipmentPrice * commissionRate) / 100;

              // 1. CREATE COMMISSION RECORD
              const commissionRef = await db.collection('commissions').add({
              shippingRequestId: requestId,
              affiliateId: newData.affiliate,
              shipmentPrice,
              commissionRate,
              commissionAmount,
              status: 'pending',
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
              createdBy: 'system-auto-delivery',
            });

            console.log(
              `✅ Commission created: ${commissionRef.id} for $${commissionAmount.toFixed(2)}`
            );

            // 2. UPDATE AFFILIATE'S TOTAL EARNINGS
            await db.collection('affiliates').doc(newData.affiliate).update({
              totalEarnings: admin.firestore.FieldValue.increment(commissionAmount),
              lastCommissionDate: admin.firestore.FieldValue.serverTimestamp(),
            });

            // 3. AUTOMATICALLY GENERATE PAYOUT REQUEST
            // Generate payout number: PAY-YYYYMMDD-XXXXX
            const now = new Date();
            const dateStr = now.toISOString().split('T')[0].replace(/-/g, '');
            const randomSuffix = Math.random().toString(36).substring(2, 7).toUpperCase();
            const payoutNumber = `PAY-${dateStr}-${randomSuffix}`;

            // Calculate payout amounts
            const grossAmount = shipmentPrice;
            const taxCalculation = await calculateTax(db, commissionAmount, 'affiliate');
            const taxAmount = taxCalculation.taxAmount;
            const netAmount = commissionAmount - taxAmount;

            // Set period dates (for single commission, use current date)
            const periodStart = admin.firestore.Timestamp.fromDate(now);
            const periodEnd = admin.firestore.Timestamp.fromDate(now);

            const payoutRef = await db.collection('payouts').add({
              payoutNumber,
              recipientType: 'affiliate',
              recipientId: newData.affiliate,
              recipientName: affiliateData?.fullName || 'Unknown',
              grossAmount,
              commissionAmount,
              taxAmount,
              netAmount,
              currency: 'USD',
              affiliateId: newData.affiliate,
              affiliateName: affiliateData?.fullName || 'Unknown',
              affiliateEmail: affiliateData?.email,
              amount: commissionAmount,
              commissionIds: [commissionRef.id],
              status: 'pending', // Ready for admin to process manually
              bankAccountDetails: affiliateData?.bankAccountDetails,
              period: new Date().toISOString().slice(0, 7),
              periodStart,
              periodEnd,
              requestedAt: admin.firestore.FieldValue.serverTimestamp(),
              requestedBy: 'system-auto-delivery',
              notes: `Auto-generated on shipment delivery: $${shipmentPrice} × ${commissionRate}%`,
              paymentMethod: 'bank_transfer',
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });

            console.log(
              `✅ Payout auto-generated: ${payoutRef.id} for $${commissionAmount.toFixed(2)}`
            );

            // 4. UPDATE COMMISSION TO LINK TO PAYOUT
            await commissionRef.update({
              status: 'approved', // Auto-approved since price was set
              payoutId: payoutRef.id,
              approvedAt: admin.firestore.FieldValue.serverTimestamp(),
            });

            // 5. AUTOMATICALLY GENERATE INVOICE
            try {
              const invoiceNumber = `INV-${Date.now()}-${Math.floor(
                Math.random() * 1000
              )}`;

              const invoiceRef = await db.collection('invoices').add({
                invoiceNumber,
                invoiceType: 'affiliate_commission',
                status: 'draft', // Admin fills details and sends
                recipientType: 'affiliate',
                shippingRequestId: requestId,
                affiliateId: newData.affiliate,
                customerId: newData.userId || null,
                guestEmail: newData.senderEmail || null,
                amount: commissionAmount,
                currency: 'USD',
                lineItems: [
                  {
                    description: `Commission earned on shipment from ${newData.senderName} to ${newData.receiverName}`,
                    quantity: 1,
                    unitPrice: commissionAmount,
                    total: commissionAmount,
                  },
                ],
                billTo: {
                  name: newData.affiliate || 'Affiliate',
                  email: affiliateData?.email,
                  phone: affiliateData?.phone || null,
                  address: newData.departingLocation || 'N/A',
                },
                shipmentDetails: {
                  senderName: newData.senderName,
                  senderEmail: newData.senderEmail,
                  receiverName: newData.receiverName,
                  receiverEmail: newData.receiverEmail,
                  freightType: newData.freightType,
                  itemDescription: newData.itemDescription,
                  weight: newData.shipmentWeightKg,
                  departingLocation: newData.departingLocation,
                  destinationLocation: newData.destinationLocation,
                },
                commissionRate,
                commissionAmount,
                earnedBy: newData.affiliate,
                notes: '',
                adminNotes: `Auto-generated for affiliate on delivery`,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                createdBy: 'system-auto-delivery',
                sentAt: null,
                paidAt: null,
              });

              console.log(
                `✅ Affiliate commission invoice created: ${invoiceRef.id}`
              );

              // Update shipping request with invoice reference
              await db
                .collection('shippingRequests')
                .doc(requestId)
                .update({
                  invoiceId: invoiceRef.id,
                  invoiceStatus: 'draft',
                });
            } catch (invoiceError) {
              console.error(
                `❌ Error auto-generating affiliate invoice for request ${requestId}:`,
                invoiceError
              );
              // Don't throw - continue with other notifications
            }

            // 6. AUTOMATICALLY GENERATE CUSTOMER INVOICE (if customer/guest request)
            // (Only affiliates get commission invoice, but everyone gets service invoice)
            // For now, skip customer invoice - can add later if needed

            // 7. NOTIFY AFFILIATE
            await db.collection('notifications').add({
              type: 'payout_ready',
              payoutId: payoutRef.id,
              shippingRequestId: requestId,
              commissionId: commissionRef.id,
              affiliateId: newData.affiliate,
              targetUserId: newData.affiliate,
              targetRole: 'affiliate',
              read: false,
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
              message: `🎉 Your shipment from ${newData.senderName} was delivered! You earned $${commissionAmount.toFixed(2)} commission. Payout is being processed.`,
              actionUrl: `/affiliate/payouts/${payoutRef.id}`,
            });

            // 8. NOTIFY ADMIN
            await db.collection('notifications').add({
              type: 'payout_auto_generated',
              payoutId: payoutRef.id,
              affiliateId: newData.affiliate,
              targetRole: 'admin',
              read: false,
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
              message: `Payout auto-generated for ${affiliateData?.fullName}: $${commissionAmount.toFixed(2)}`,
              actionUrl: `/admin/payouts/${payoutRef.id}`,
            });

            // 9. LOG ACTIVITY
            await db.collection('activity_log').add({
              type: 'payout_auto_generated_on_delivery',
              requestId,
              payoutId: payoutRef.id,
              commissionId: commissionRef.id,
              affiliateId: newData.affiliate,
              amount: commissionAmount,
              rate: commissionRate,
              timestamp: admin.firestore.FieldValue.serverTimestamp(),
            });
          }
        } catch (payoutError) {
          console.error(
            `❌ Error auto-generating payout for request ${requestId}:`,
            payoutError
          );
          // Don't throw - let notification still go to sender
        }
        }
      }
    } else if (statusChanged && newData.status === 'delivered') {
      // ========== HANDLE CUSTOMER/GUEST DELIVERY (NO AFFILIATE) ==========
      console.log(`📦 Shipment delivered (customer/guest request - no affiliate)`);

      // For non-affiliate requests, just send delivery notification
      // Invoice can be manually created by admin later if needed

      // Send delivery confirmation to sender
      await db.collection('notifications').add({
        type: 'shipment_delivered_confirmation',
        shippingRequestId: requestId,
        senderEmail: newData.senderEmail,
        targetRole: 'customer',
        read: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        message: `📦 Your shipment to ${newData.receiverName} has been delivered!`,
        actionUrl: `/tracking/${requestId}`,
      });
    }

    // ========== STATUS CHANGE NOTIFICATION (FOR ALL TYPES) ==========
    if (statusChanged) {
      const statusMessages: { [key: string]: string } = {
        pending: 'Your shipping request has been received',
        approved: 'Your request has been approved',
        assigned: 'A shipper has been assigned',
        'in-transit': 'Your shipment is on its way',
        delivered: 'Your shipment has been delivered',
        cancelled: 'Request cancelled',
        rejected: 'Request cannot be processed',
      };

      const statusMessage =
        statusMessages[newData.status] || 'Status updated';

      // Notify sender (customer, guest, or affiliate)
      const senderNotification = {
        type: 'shipping_request_status_update',
        requestId: requestId,
        previousStatus: previousData.status,
        newStatus: newData.status,
        targetRole: 'customer',
        targetUserId: newData.userId || null,
        targetEmail: newData.senderEmail,
        read: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        message: `Shipping Update: ${statusMessage}`,
        actionUrl: `/tracking/${requestId}`,
      };

      await db.collection('notifications').add(senderNotification);

      // ========== SEND EMAIL NOTIFICATION (using template service - works for guests too!) ==========
      try {
        const smtpConfig = getSmtpConfig();
        const validation = validateSmtpConfig(smtpConfig);

        if (validation.valid && newData.senderEmail) {
          const transporter = nodemailer.createTransport({
            host: smtpConfig.host,
            port: smtpConfig.port,
            secure: smtpConfig.secure,
            auth: {
              user: smtpConfig.user,
              pass: smtpConfig.pass,
            },
          });

          const trackingNumber = newData.trackingNumber || requestId;
          const senderName = newData.senderName || 'Valued Customer';
          const destination = newData.destinationLocation || 'Unknown';

          // Get template from Firestore or use default
          const template = await getTemplate('shipping_status_update', db);
          const { subject, htmlBody, plainTextBody } = renderTemplate(template, {
            senderName,
            status: newData.status.toUpperCase(),
            statusMessage: statusMessage,
            trackingNumber: trackingNumber,
            destination: destination,
            updatedDate: new Date().toLocaleDateString(),
          });

          await transporter.sendMail({
            from: smtpConfig.user,
            to: newData.senderEmail,
            subject: subject,
            html: htmlBody,
            text: plainTextBody,
            replyTo: 'support@shopsnports.com',
          });

          console.log(`✅ Status update email sent to: ${newData.senderEmail}`);
        }
      } catch (emailError) {
        console.error('Error sending status update email:', emailError);
        // Don't throw - email failure shouldn't fail the whole function
      }

      // Send FCM to sender
      try {
        const senderQuery = await db
          .collection('users')
          .where('email', '==', newData.senderEmail)
          .limit(1)
          .get();

        if (!senderQuery.empty) {
          const senderData = senderQuery.docs[0].data();
          if (senderData.fcmTokens && Array.isArray(senderData.fcmTokens)) {
            const payload = {
              notification: {
                title: 'Shipping Request Update',
                body: statusMessage,
                clickAction: 'FLUTTER_NOTIFICATION_CLICK',
              },
              data: {
                type: 'status_update',
                requestId: requestId,
                status: newData.status,
              },
            };

            await messaging.sendMulticast({
              ...payload,
              tokens: senderData.fcmTokens,
            });

            console.log(`Sent status update FCM to sender: ${newData.senderEmail}`);
          }
        }
      } catch (senderFcmError) {
        console.error('Error sending FCM to sender:', senderFcmError);
      }
    }

    // ========== ASSIGNMENT NOTIFICATION ==========
    if (assignedChanged && newData.assignedTo) {
      // Notify assigned shipper
      const shipperNotification = {
        type: 'shipment_assigned',
        requestId: requestId,
        senderName: newData.senderName || 'Guest',
        destination: newData.destinationLocation,
        weight: newData.shipmentWeightKg,
        targetRole: 'shipper',
        targetUserId: newData.assignedTo,
        read: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        message: `New shipment assigned: ${newData.destinationLocation}`,
        actionUrl: `/shipper/shipments/${requestId}`,
      };

      await db.collection('notifications').add(shipperNotification);

      // Send FCM to shipper
      try {
        const shipperQuery = await db
          .collection('users')
          .doc(newData.assignedTo)
          .get();

        if (shipperQuery.exists) {
          const shipperData = shipperQuery.data();
          if (shipperData?.fcmTokens && Array.isArray(shipperData.fcmTokens)) {
            const payload = {
              notification: {
                title: 'New Shipment Assigned',
                body: `${newData.senderName} → ${newData.destinationLocation}`,
                clickAction: 'FLUTTER_NOTIFICATION_CLICK',
              },
              data: {
                type: 'shipment_assigned',
                requestId: requestId,
                weight: newData.shipmentWeightKg.toString(),
              },
            };

            await messaging.sendMulticast({
              ...payload,
              tokens: shipperData.fcmTokens,
            });

            console.log(`Sent assignment FCM to shipper: ${newData.assignedTo}`);
          }
        }
      } catch (shipperFcmError) {
        console.error('Error sending FCM to shipper:', shipperFcmError);
      }
    }

    // LOG ALL UPDATES
    await db.collection('activity_log').add({
      type: 'shipping_request_updated',
      requestId: requestId,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      changes: {
        statusChanged,
        newStatus: newData.status,
        assignedChanged,
        newAssignedTo: newData.assignedTo,
      },
    });

    console.log(`✅ Successfully processed update for shipping request: ${requestId}`);

    return { success: true, requestId };
  } catch (error) {
    console.error('Error in onShippingRequestUpdated:', error);
    throw error;
  }
};

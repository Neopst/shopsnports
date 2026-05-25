import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { markTokenUsed } from './generateAffiliateTokens';
import { validateId, validateString, ValidationError } from './validation';
import { rateLimitFormShare, RateLimitError } from './rateLimiter';

/**
 * Cloud Function: Handle shipping request submitted via Form Share
 * 
 * When a client submits a shipping form that was shared by an affiliate,
 * this function:
 * 1. Validates the form share token
 * 2. Auto-tags the affiliate from the token
 * 3. Marks the token as used
 * 4. Generates affiliate token (for commission tracking)
 * 5. Triggers all auto-generation workflows (commission, payout, invoice)
 * 6. Sends notifications
 * 7. Logs activity
 * 
 * This prevents duplicate flows - form shares use same tokenization as direct entries
 * 
 * Trigger: Custom callable when form submitted with formShareToken
 */
export const onFormShareTokenUsed = functions.https.onCall(
  async (data, context) => {
    try {
      // Check rate limit first
      try {
        await rateLimitFormShare(data, context);
      } catch (rateError) {
        if (rateError instanceof RateLimitError) {
          throw new functions.https.HttpsError('resource-exhausted', rateError.message);
        }
        throw rateError;
      }

      // Validate input data using validation module
      const { shippingRequestId, formShareToken, clientEmail, clientName } = data;

      try {
        validateId(shippingRequestId, 'shippingRequestId');
        validateString(formShareToken, { required: true, minLength: 10, maxLength: 200, fieldName: 'formShareToken' });
      } catch (validationError) {
        if (validationError instanceof ValidationError) {
          throw new functions.https.HttpsError('invalid-argument', validationError.message);
        }
        throw validationError;
      }

      const db = admin.firestore();

      console.log(
        `📋 Processing form share submission with token: ${formShareToken}`
      );

      // ========== STEP 1: VALIDATE FORM SHARE TOKEN ==========
      const tokenQuery = await db
        .collection('form_shares')
        .where('token', '==', formShareToken.toUpperCase())
        .limit(1)
        .get();

      if (tokenQuery.empty) {
        throw new functions.https.HttpsError(
          'not-found',
          'Form share token not found. Link may have expired.'
        );
      }

      const tokenDoc = tokenQuery.docs[0];
      const tokenData = tokenDoc.data();

      // Check if already used
      if (tokenData.used) {
        throw new functions.https.HttpsError(
          'already-exists',
          `This form link has already been used for request: ${tokenData.resultingShippingRequestId}`
        );
      }

      // Check if expired (7 days)
      const expiryDate = tokenData.expiresAt.toDate();
      if (new Date() > expiryDate) {
        throw new functions.https.HttpsError(
          'deadline-exceeded',
          'Form share link has expired. Ask the affiliate for a new link.'
        );
      }

      console.log(`✅ Form share token validated. Affiliate: ${tokenData.affiliateId}`);

      // ========== STEP 2: GET SHIPPING REQUEST & UPDATE WITH AFFILIATE ==========
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

      // Auto-tag affiliate from form share token
      await db
        .collection('shippingRequests')
        .doc(shippingRequestId)
        .update({
          affiliate: tokenData.affiliateId,
          affiliateTokenId: tokenData.affiliateTokenId || null,
          formShareToken: formShareToken.toUpperCase(),
          formShareTokenEmail: clientEmail,
          submissionType: 'form_share', // Track how it was submitted
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

      console.log(
        `✅ Shipping request tagged with affiliate: ${tokenData.affiliateId}`
      );

      // ========== STEP 3: MARK FORM SHARE TOKEN AS USED ==========
      await tokenDoc.ref.update({
        used: true,
        usedAt: admin.firestore.FieldValue.serverTimestamp(),
        usedBy: clientEmail,
        resultingShippingRequestId: shippingRequestId,
      });

      console.log(`✅ Form share token marked as used`);

      // ========== STEP 4: UPDATE AFFILIATE'S SHARE STATISTICS ==========
      const affiliateDoc = await db
        .collection('affiliates')
        .doc(tokenData.affiliateId)
        .get();

      if (affiliateDoc.exists) {
        await affiliateDoc.ref.update({
          formSharesUsed: admin.firestore.FieldValue.increment(1),
          lastFormUsedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      // ========== STEP 5: CREATE NOTIFICATION FOR AFFILIATE ==========
      await db.collection('notifications').add({
        type: 'form_share_used',
        shippingRequestId,
        formShareToken: formShareToken,
        affiliateId: tokenData.affiliateId,
        clientEmail,
        clientName: clientName || 'Client',
        targetRole: 'affiliate',
        targetUserId: tokenData.affiliateId,
        read: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        message: `🎉 Client ${clientName || clientEmail} used your shared form! Shipping request created.`,
        actionUrl: `/affiliate/requests/${shippingRequestId}`,
      });

      // ========== STEP 6: CREATE NOTIFICATION FOR ADMIN ==========
      await db.collection('notifications').add({
        type: 'form_share_submission',
        shippingRequestId,
        formShareToken,
        affiliateId: tokenData.affiliateId,
        clientEmail,
        targetRole: 'admin',
        read: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        message: `📋 Affiliate ${tokenData.affiliateName} received form submission from ${clientEmail}`,
        actionUrl: `/admin/shipping-requests/${shippingRequestId}`,
      });

      // ========== STEP 7: LOG ACTIVITY ==========
      await db.collection('activity_log').add({
        type: 'form_share_token_used',
        shippingRequestId,
        formShareToken,
        affiliateId: tokenData.affiliateId,
        clientEmail,
        submittedBy: clientEmail,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(
        `✅ Form share workflow completed for request ${shippingRequestId}`
      );

      return {
        success: true,
        shippingRequestId,
        affiliateId: tokenData.affiliateId,
        formShareToken,
      };
    } catch (error) {
      console.error('Error in onFormShareTokenUsed:', error);
      throw error;
    }
  }
);

/**
 * Cloud Function: Generate shareable form link
 * 
 * Affiliate creates a new shareable link that they can send to clients
 * Client clicks link and fills out the form
 * 
 * Returns: Shareable URL with form token
 */
export const generateFormShareLink = functions.https.onCall(
  async (data, context) => {
    try {
      if (!context.auth) {
        throw new functions.https.HttpsError(
          'unauthenticated',
          'User must be authenticated'
        );
      }

      const affiliateId = context.auth.uid;
      const { clientEmail, clientName } = data;

      // Check rate limit for form share link generation
      try {
        await rateLimitFormShare(data, context);
      } catch (rateError) {
        if (rateError instanceof RateLimitError) {
          throw new functions.https.HttpsError('resource-exhausted', rateError.message);
        }
        throw rateError;
      }

      if (!clientEmail) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'clientEmail is required'
        );
      }

      const db = admin.firestore();

      // Verify user is an affiliate
      const affiliateDoc = await db
        .collection('affiliates')
        .doc(affiliateId)
        .get();

      if (!affiliateDoc.exists) {
        throw new functions.https.HttpsError(
          'permission-denied',
          'User is not registered as an affiliate'
        );
      }

      const affiliateData = affiliateDoc.data()!;

      console.log(
        `🔗 Generating form share link for affiliate: ${affiliateData.fullName}`
      );

      // Generate unique token for this share
      const formShareToken = `SHARE-AFF-${new Date().getFullYear()}-${Math.floor(
        Math.random() * 100000
      )
        .toString()
        .padStart(5, '0')}`;

      // Create form share document
      const formShareRef = await db.collection('form_shares').add({
        token: formShareToken,
        affiliateId,
        affiliateName: affiliateData.fullName,
        affiliateEmail: affiliateData.email,
        clientEmail: clientEmail.toLowerCase(),
        clientName: clientName || null,
        used: false,
        usedAt: null,
        usedBy: null,
        resultingShippingRequestId: null,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7 days
        metadata: {
          userAgent: data.userAgent || 'mobile',
          platform: data.platform || 'iOS',
        },
      });

      console.log(
        `✅ Form share link created: ${formShareToken} for client: ${clientEmail}`
      );

      // Update affiliate's share count
      await affiliateDoc.ref.update({
        formSharesGenerated: admin.firestore.FieldValue.increment(1),
        lastFormShareGeneratedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Build shareable URL
      const shareUrl = `https://app.shopsnports.com/shipping/share?token=${formShareToken}`;

      // Create notification
      await db.collection('notifications').add({
        type: 'form_share_created',
        affiliateId,
        targetRole: 'affiliate',
        targetUserId: affiliateId,
        read: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        message: `🔗 Form share link created for ${clientName || clientEmail}. Valid for 7 days.`,
        actionUrl: `/affiliate/form-shares`,
      });

      // Log activity
      await db.collection('activity_log').add({
        type: 'form_share_link_generated',
        formShareToken,
        affiliateId,
        clientEmail,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      return {
        success: true,
        formShareToken,
        shareUrl,
        expiresIn: '7 days',
        clientEmail,
        clientName,
      };
    } catch (error) {
      console.error('Error generating form share link:', error);
      throw error;
    }
  }
);

/**
 * Cloud Function: Cleanup expired form share links
 * 
 * Runs daily to mark expired links and clean up old records
 */
export const cleanupExpiredFormShares = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async (context) => {
    try {
      const db = admin.firestore();

      console.log('🧹 Cleaning up expired form share links...');

      // Find expired, unused tokens
      const expiredQuery = await db
        .collection('form_shares')
        .where('used', '==', false)
        .where('expiresAt', '<', new Date())
        .get();

      console.log(`Found ${expiredQuery.size} expired form shares`);

      // Mark as expired (for record keeping)
      const batch = db.batch();
      expiredQuery.docs.forEach((doc) => {
        batch.update(doc.ref, {
          status: 'expired',
          expiredAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      });

      await batch.commit();

      console.log(`✅ Cleaned up ${expiredQuery.size} expired form shares`);

      return { success: true, expiredCount: expiredQuery.size };
    } catch (error) {
      console.error('Error cleaning up expired form shares:', error);
      throw error;
    }
  });

/**
 * Cloud Function: Get affiliate's form share analytics
 * 
 * Returns:
 * - Total shares created
 * - Total successfully used
 * - Conversion rate
 * - List of active and used links
 */
export const getFormShareAnalytics = functions.https.onCall(
  async (data, context) => {
    try {
      if (!context.auth) {
        throw new functions.https.HttpsError(
          'unauthenticated',
          'User must be authenticated'
        );
      }

      const affiliateId = context.auth.uid;
      const db = admin.firestore();

      console.log(`📊 Getting form share analytics for affiliate: ${affiliateId}`);

      // Get all form shares for this affiliate
      const allSharesQuery = await db
        .collection('form_shares')
        .where('affiliateId', '==', affiliateId)
        .orderBy('createdAt', 'desc')
        .get();

      // Separate used and unused
      const activeShares: any[] = [];
      const usedShares: any[] = [];

      allSharesQuery.docs.forEach((doc) => {
        const data = doc.data();
        const share = {
          id: doc.id,
          token: data.token,
          clientEmail: data.clientEmail,
          clientName: data.clientName,
          createdAt: data.createdAt.toDate(),
          expiresAt: data.expiresAt.toDate(),
        };

        if (data.used) {
          usedShares.push({
            ...share,
            usedAt: data.usedAt?.toDate(),
            resultingShippingRequestId: data.resultingShippingRequestId,
          });
        } else if (new Date() < data.expiresAt.toDate()) {
          activeShares.push(share);
        }
      });

      const totalShares = allSharesQuery.size;
      const successfulUses = usedShares.length;
      const conversionRate =
        totalShares > 0 ? ((successfulUses / totalShares) * 100).toFixed(1) : '0';

      console.log(`📊 Analytics: ${totalShares} shares, ${successfulUses} used`);

      return {
        success: true,
        analytics: {
          totalSharesCreated: totalShares,
          successfulSubmissions: successfulUses,
          conversionRate: `${conversionRate}%`,
          activeLinks: activeShares.length,
          expiredLinks: totalShares - activeShares.length - usedShares.length,
        },
        activeShares,
        usedShares,
      };
    } catch (error) {
      console.error('Error getting form share analytics:', error);
      throw error;
    }
  }
);

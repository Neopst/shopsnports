import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { calculateTax } from './taxCalculation';

/**
 * Cloud Function: Auto-generate payouts based on affiliate payout schedule
 *
 * Runs daily to check for affiliates with pending commissions
 * Generates payout requests based on their payout schedule:
 * - perJob: Generate immediately when commission is earned
 * - weekly: Generate every Sunday
 * - monthly: Generate on the 1st of each month
 */
export const autoGeneratePayouts = functions.pubsub
  .schedule('0 2 * * *') // Run daily at 2 AM UTC
  .timeZone('UTC')
  .onRun(async (context) => {
    console.log('🔄 Starting auto-generate payouts...');

    const db = admin.firestore();
    const now = new Date();
    const dayOfWeek = now.getUTCDay(); // 0 = Sunday, 6 = Saturday
    const dayOfMonth = now.getUTCDate(); // 1-31

    console.log(`Current time: ${now.toISOString()}`);
    console.log(`Day of week: ${dayOfWeek}, Day of month: ${dayOfMonth}`);

    try {
      // Get all approved affiliates
      const affiliatesSnapshot = await db
        .collection('affiliates')
        .where('status', '==', 'approved')
        .get();

      if (affiliatesSnapshot.empty) {
        console.log('No approved affiliates found');
        return { success: true, message: 'No affiliates to process', payoutsGenerated: 0 };
      }

      console.log(`Found ${affiliatesSnapshot.size} approved affiliates`);

      let totalPayoutsGenerated = 0;
      const results: any[] = [];

      for (const affiliateDoc of affiliatesSnapshot.docs) {
        const affiliateId = affiliateDoc.id;
        const affiliateData = affiliateDoc.data();
        const payoutSchedule = affiliateData.payoutSchedule || 'monthly';

        console.log(`Processing affiliate ${affiliateId} with schedule: ${payoutSchedule}`);

        // Check if we should generate payout for this affiliate based on schedule
        let shouldGenerate = false;

        switch (payoutSchedule) {
          case 'perJob':
            // Generate immediately when commission is earned (handled by commission calculation)
            // This scheduled job is for weekly/monthly schedules only
            shouldGenerate = false;
            break;

          case 'weekly':
            // Generate on Sundays (dayOfWeek === 0)
            shouldGenerate = dayOfWeek === 0;
            break;

          case 'monthly':
            // Generate on the 1st of each month (dayOfMonth === 1)
            shouldGenerate = dayOfMonth === 1;
            break;

          default:
            console.warn(`Unknown payout schedule: ${payoutSchedule}`);
            shouldGenerate = false;
        }

        if (!shouldGenerate) {
          console.log(`Skipping affiliate ${affiliateId} - not scheduled for today`);
          continue;
        }

        // Get pending commissions for this affiliate
        const pendingCommissions = await db
          .collection('commissions')
          .where('affiliateId', '==', affiliateId)
          .where('status', '==', 'pending')
          .get();

        if (pendingCommissions.empty) {
          console.log(`No pending commissions for affiliate ${affiliateId}`);
          continue;
        }

        console.log(`Found ${pendingCommissions.size} pending commissions for affiliate ${affiliateId}`);

        // Calculate total amount
        let totalAmount = 0.0;
        const commissionIds: string[] = [];

        for (const doc of pendingCommissions.docs) {
          const commission = doc.data();
          totalAmount += (commission.commissionAmount as number);
          commissionIds.push(doc.id);
        }

        if (totalAmount <= 0) {
          console.warn(`Invalid total amount for affiliate ${affiliateId}: ${totalAmount}`);
          continue;
        }

        // Check minimum payout threshold (e.g., $50)
        const MIN_PAYOUT_THRESHOLD = 50.0;
        if (totalAmount < MIN_PAYOUT_THRESHOLD) {
          console.log(`Total amount $${totalAmount.toFixed(2)} below threshold $${MIN_PAYOUT_THRESHOLD}, skipping`);
          continue;
        }

        console.log(`Generating payout for affiliate ${affiliateId}: $${totalAmount.toFixed(2)}`);

        // Create payout request
        // Generate payout number: PAY-YYYYMMDD-XXXXX
        const dateStr = now.toISOString().split('T')[0].replace(/-/g, '');
        const randomSuffix = Math.random().toString(36).substring(2, 7).toUpperCase();
        const payoutNumber = `PAY-${dateStr}-${randomSuffix}`;

        // Calculate payout amounts
        const grossAmount = totalAmount;
        const taxCalculation = await calculateTax(db, totalAmount, 'affiliate');
        const taxAmount = taxCalculation.taxAmount;
        const netAmount = grossAmount - taxAmount;

        // Set period dates
        const periodStart = admin.firestore.Timestamp.fromDate(now);
        const periodEnd = admin.firestore.Timestamp.fromDate(now);

        const payoutRef = await db.collection('payouts').add({
          payoutNumber,
          recipientType: 'affiliate',
          recipientId: affiliateId,
          recipientName: affiliateData.fullName || 'Unknown',
          grossAmount,
          commissionAmount: totalAmount,
          taxAmount,
          netAmount,
          currency: 'USD',
          affiliateId: affiliateId,
          affiliateName: affiliateData.fullName || 'Unknown',
          affiliateEmail: affiliateData.email,
          amount: Math.round(totalAmount * 100) / 100,
          commissionIds: commissionIds,
          status: 'pending',
          bankAccountDetails: affiliateData.bankAccountDetails,
          period: `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`,
          periodStart,
          periodEnd,
          requestedAt: admin.firestore.FieldValue.serverTimestamp(),
          requestedBy: 'system',
          notes: `Auto-generated from ${commissionIds.length} commissions (${payoutSchedule} schedule)`,
          paymentMethod: 'bank_transfer',
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Mark commissions as approved
        const batch = db.batch();
        for (const commissionId of commissionIds) {
          batch.update(db.collection('commissions').doc(commissionId), {
            status: 'approved',
            payoutId: payoutRef.id,
            approvedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }
        await batch.commit();

        // Create notification for affiliate
        await db.collection('notifications').add({
          userId: affiliateId,
          type: 'affiliate',
          category: 'payout',
          title: 'Payout Generated',
          message: `Your payout of $${totalAmount.toFixed(2)} has been generated and is being processed.`,
          actionUrl: `/affiliate/payouts/${payoutRef.id}`,
          isRead: false,
          readAt: null,
          metadata: {
            payoutId: payoutRef.id,
            amount: totalAmount,
            commissionCount: commissionIds.length,
          },
          priority: 'high',
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Create notification for admins
        await db.collection('notifications').add({
          type: 'payout',
          category: 'payout',
          title: 'Auto-Generated Payout',
          message: `Payout of $${totalAmount.toFixed(2)} generated for ${affiliateData.fullName}`,
          actionUrl: `/admin/payouts/${payoutRef.id}`,
          isRead: false,
          readAt: null,
          metadata: {
            payoutId: payoutRef.id,
            affiliateId: affiliateId,
            affiliateName: affiliateData.fullName,
          },
          priority: 'normal',
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Log activity
        await db.collection('activity_logs').add({
          type: 'payout_auto_generated',
          payoutId: payoutRef.id,
          affiliateId: affiliateId,
          amount: totalAmount,
          commissionCount: commissionIds.length,
          schedule: payoutSchedule,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          performedBy: 'system',
        });

        totalPayoutsGenerated++;
        results.push({
          affiliateId,
          affiliateName: affiliateData.fullName,
          payoutId: payoutRef.id,
          amount: totalAmount,
          commissionCount: commissionIds.length,
        });

        console.log(`✅ Payout generated for affiliate ${affiliateId}: ${payoutRef.id}`);
      }

      console.log(`✅ Auto-generate payouts completed. Total payouts: ${totalPayoutsGenerated}`);

      return {
        success: true,
        message: `Generated ${totalPayoutsGenerated} payouts`,
        payoutsGenerated: totalPayoutsGenerated,
        results,
      };

    } catch (error) {
      console.error('Error in autoGeneratePayouts:', error);
      throw error;
    }
  });

/**
 * Cloud Function: Generate payout for perJob affiliates immediately
 *
 * Called when commission is earned for affiliates with perJob schedule
 */
export const generatePerJobPayout = async (
  db: admin.firestore.Firestore,
  affiliateId: string,
  commissionId: string,
  commissionAmount: number
): Promise<string | null> => {
  try {
    // Get affiliate details
    const affiliateDoc = await db.collection('affiliates').doc(affiliateId).get();
    if (!affiliateDoc.exists) {
      console.warn(`Affiliate ${affiliateId} not found`);
      return null;
    }

    const affiliateData = affiliateDoc.data();
    const payoutSchedule = affiliateData?.payoutSchedule;

    // Only generate for perJob schedule
    if (payoutSchedule !== 'perJob') {
      console.log(`Affiliate ${affiliateId} has ${payoutSchedule} schedule, skipping perJob payout`);
      return null;
    }

    // Check minimum payout threshold
    const MIN_PAYOUT_THRESHOLD = 10.0; // Lower threshold for perJob
    if (commissionAmount < MIN_PAYOUT_THRESHOLD) {
      console.log(`Commission amount $${commissionAmount.toFixed(2)} below perJob threshold $${MIN_PAYOUT_THRESHOLD}, skipping`);
      return null;
    }

    console.log(`Generating perJob payout for affiliate ${affiliateId}: $${commissionAmount.toFixed(2)}`);

    // Create payout request
    // Generate payout number: PAY-YYYYMMDD-XXXXX
    const now = new Date();
    const dateStr = now.toISOString().split('T')[0].replace(/-/g, '');
    const randomSuffix = Math.random().toString(36).substring(2, 7).toUpperCase();
    const payoutNumber = `PAY-${dateStr}-${randomSuffix}`;

    // Calculate payout amounts
    const grossAmount = commissionAmount;
    const taxCalculation = await calculateTax(db, commissionAmount, 'affiliate');
    const taxAmount = taxCalculation.taxAmount;
    const netAmount = grossAmount - taxAmount;

    // Set period dates
    const periodStart = admin.firestore.Timestamp.fromDate(now);
    const periodEnd = admin.firestore.Timestamp.fromDate(now);

    const payoutRef = await db.collection('payouts').add({
      payoutNumber,
      recipientType: 'affiliate',
      recipientId: affiliateId,
      recipientName: affiliateData?.fullName || 'Unknown',
      grossAmount,
      commissionAmount,
      taxAmount,
      netAmount,
      currency: 'USD',
      affiliateId: affiliateId,
      affiliateName: affiliateData?.fullName || 'Unknown',
      affiliateEmail: affiliateData?.email,
      amount: Math.round(commissionAmount * 100) / 100,
      commissionIds: [commissionId],
      status: 'pending',
      bankAccountDetails: affiliateData?.bankAccountDetails,
      period: new Date().toISOString().slice(0, 7),
      periodStart,
      periodEnd,
      requestedAt: admin.firestore.FieldValue.serverTimestamp(),
      requestedBy: 'system',
      notes: 'Auto-generated from single commission (perJob schedule)',
      paymentMethod: 'bank_transfer',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Mark commission as approved
    await db.collection('commissions').doc(commissionId).update({
      status: 'approved',
      payoutId: payoutRef.id,
      approvedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`✅ PerJob payout generated: ${payoutRef.id}`);
    return payoutRef.id;

  } catch (error) {
    console.error('Error in generatePerJobPayout:', error);
    return null;
  }
};
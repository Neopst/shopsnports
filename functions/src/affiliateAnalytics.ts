import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

/**
 * Cloud Function: Get comprehensive affiliate analytics
 *
 * Returns detailed analytics for a specific affiliate including:
 * - Earnings trends (daily, weekly, monthly)
 * - Commission breakdown
 * - Form share analytics
 * - Conversion rates
 * - Performance metrics
 */
export const getAffiliateAnalytics = functions.https.onCall(
  async (data, context) => {
    try {
      if (!context.auth) {
        throw new functions.https.HttpsError(
          'unauthenticated',
          'User must be authenticated'
        );
      }

      const affiliateId = context.auth.uid;
      const { period = '30d' } = data; // 7d, 30d, 90d, 1y

      const db = admin.firestore();
      console.log(`Getting analytics for affiliate ${affiliateId}, period: ${period}`);

      // Calculate date range
      const now = new Date();
      let startDate: Date;

      switch (period) {
        case '7d':
          startDate = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
          break;
        case '30d':
          startDate = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
          break;
        case '90d':
          startDate = new Date(now.getTime() - 90 * 24 * 60 * 60 * 1000);
          break;
        case '1y':
          startDate = new Date(now.getTime() - 365 * 24 * 60 * 60 * 1000);
          break;
        default:
          startDate = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
      }

      // Get affiliate profile
      const affiliateDoc = await db.collection('affiliates').doc(affiliateId).get();
      if (!affiliateDoc.exists) {
        throw new functions.https.HttpsError(
          'not-found',
          'Affiliate not found'
        );
      }

      const affiliateData = affiliateDoc.data();

      // Get commissions in date range
      const commissionsSnapshot = await db
        .collection('commissions')
        .where('affiliateId', '==', affiliateId)
        .where('createdAt', '>=', admin.firestore.Timestamp.fromDate(startDate))
        .orderBy('createdAt', 'desc')
        .get();

      // Get payouts in date range
      const payoutsSnapshot = await db
        .collection('payouts')
        .where('affiliateId', '==', affiliateId)
        .where('requestedAt', '>=', admin.firestore.Timestamp.fromDate(startDate))
        .orderBy('requestedAt', 'desc')
        .get();

      // Get form shares in date range
      const formSharesSnapshot = await db
        .collection('form_shares')
        .where('affiliateId', '==', affiliateId)
        .where('createdAt', '>=', admin.firestore.Timestamp.fromDate(startDate))
        .orderBy('createdAt', 'desc')
        .get();

      // Get affiliate tokens in date range
      const tokensSnapshot = await db
        .collection('affiliate_tokens')
        .where('affiliateId', '==', affiliateId)
        .where('createdAt', '>=', admin.firestore.Timestamp.fromDate(startDate))
        .orderBy('createdAt', 'desc')
        .get();

      // Calculate earnings trends
      const earningsByDay = new Map<string, number>();
      const earningsByWeek = new Map<string, number>();
      const earningsByMonth = new Map<string, number>();

      let totalEarnings = 0.0;
      let totalCommissions = 0;
      let totalShipments = 0;

      for (const doc of commissionsSnapshot.docs) {
        const commission = doc.data();
        const amount = (commission.commissionAmount as number);
        const createdAt = (commission.createdAt as admin.firestore.Timestamp).toDate();

        totalEarnings += amount;
        totalCommissions++;

        // Group by day
        const dayKey = createdAt.toISOString().slice(0, 10);
        earningsByDay.set(dayKey, (earningsByDay.get(dayKey) || 0) + amount);

        // Group by week
        const weekKey = getWeekKey(createdAt);
        earningsByWeek.set(weekKey, (earningsByWeek.get(weekKey) || 0) + amount);

        // Group by month
        const monthKey = createdAt.toISOString().slice(0, 7);
        earningsByMonth.set(monthKey, (earningsByMonth.get(monthKey) || 0) + amount);
      }

      // Calculate payout stats
      let totalPaidOut = 0.0;
      let pendingPayouts = 0.0;
      let completedPayouts = 0;

      for (const doc of payoutsSnapshot.docs) {
        const payout = doc.data();
        const amount = (payout.amount as number);

        if (payout.status === 'completed') {
          totalPaidOut += amount;
          completedPayouts++;
        } else if (payout.status === 'pending') {
          pendingPayouts += amount;
        }
      }

      // Calculate form share analytics
      let totalShares = formSharesSnapshot.size;
      let usedShares = 0;
      let expiredShares = 0;

      for (const doc of formSharesSnapshot.docs) {
        const share = doc.data();
        if (share.used) {
          usedShares++;
        } else if (new Date() > (share.expiresAt as admin.firestore.Timestamp).toDate()) {
          expiredShares++;
        }
      }

      const conversionRate = totalShares > 0 ? (usedShares / totalShares) * 100 : 0;

      // Calculate token analytics
      let totalTokens = tokensSnapshot.size;
      let usedTokens = 0;

      for (const doc of tokensSnapshot.docs) {
        const token = doc.data();
        if (token.used) {
          usedTokens++;
        }
      }

      // Calculate performance metrics
      const avgCommissionPerShipment = totalCommissions > 0 ? totalEarnings / totalCommissions : 0;
      const avgShipmentsPerDay = totalCommissions > 0 ? totalCommissions / Math.max(1, getDaysBetween(startDate, now)) : 0;

      // Get recent activity
      const recentCommissions = commissionsSnapshot.docs.slice(0, 10).map(doc => ({
        id: doc.id,
        amount: doc.data().commissionAmount,
        shipmentPrice: doc.data().shipmentPrice,
        rate: doc.data().commissionRate,
        status: doc.data().status,
        createdAt: (doc.data().createdAt as admin.firestore.Timestamp).toDate().toISOString(),
      }));

      const recentPayouts = payoutsSnapshot.docs.slice(0, 5).map(doc => ({
        id: doc.id,
        amount: doc.data().amount,
        status: doc.data().status,
        requestedAt: (doc.data().requestedAt as admin.firestore.Timestamp).toDate().toISOString(),
        completedAt: doc.data().completedAt
          ? (doc.data().completedAt as admin.firestore.Timestamp).toDate().toISOString()
          : null,
      }));

      console.log(`✅ Analytics generated for affiliate ${affiliateId}`);

      return {
        success: true,
        period,
        startDate: startDate.toISOString(),
        endDate: now.toISOString(),
        summary: {
          totalEarnings,
          totalCommissions,
          totalShipments,
          avgCommissionPerShipment,
          avgShipmentsPerDay,
          totalPaidOut,
          pendingPayouts,
          completedPayouts,
        },
        earnings: {
          byDay: Object.fromEntries(earningsByDay),
          byWeek: Object.fromEntries(earningsByWeek),
          byMonth: Object.fromEntries(earningsByMonth),
        },
        formShares: {
          total: totalShares,
          used: usedShares,
          expired: expiredShares,
          active: totalShares - usedShares - expiredShares,
          conversionRate: Math.round(conversionRate * 100) / 100,
        },
        tokens: {
          total: totalTokens,
          used: usedTokens,
          unused: totalTokens - usedTokens,
        },
        recentActivity: {
          commissions: recentCommissions,
          payouts: recentPayouts,
        },
        profile: {
          commissionRate: affiliateData?.commissionRate,
          payoutSchedule: affiliateData?.payoutSchedule,
          status: affiliateData?.status,
          joinedDate: (affiliateData?.joinedDate as admin.firestore.Timestamp)?.toDate()?.toISOString(),
        },
      };

    } catch (error) {
      console.error('Error in getAffiliateAnalytics:', error);
      throw error;
    }
  }
);

/**
 * Cloud Function: Get affiliate leaderboard
 *
 * Returns top-performing affiliates based on earnings, shipments, or conversion rate
 */
export const getAffiliateLeaderboard = functions.https.onCall(
  async (data, context) => {
    try {
      const { metric = 'earnings', limit = 10, period = '30d' } = data;

      const db = admin.firestore();
      console.log(`Getting leaderboard: metric=${metric}, limit=${limit}, period=${period}`);

      // Calculate date range
      const now = new Date();
      let startDate: Date;

      switch (period) {
        case '7d':
          startDate = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
          break;
        case '30d':
          startDate = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
          break;
        case '90d':
          startDate = new Date(now.getTime() - 90 * 24 * 60 * 60 * 1000);
          break;
        case 'all':
          startDate = new Date(0); // Beginning of time
          break;
        default:
          startDate = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
      }

      let query: admin.firestore.Query;

      switch (metric) {
        case 'earnings':
          // Get all approved affiliates and calculate earnings from commissions
          const affiliatesSnapshot = await db
            .collection('affiliates')
            .where('status', '==', 'approved')
            .get();

          const leaderboard: any[] = [];

          for (const doc of affiliatesSnapshot.docs) {
            const affiliateId = doc.id;
            const affiliateData = doc.data();

            // Get commissions in date range
            const commissionsSnapshot = await db
              .collection('commissions')
              .where('affiliateId', '==', affiliateId)
              .where('createdAt', '>=', admin.firestore.Timestamp.fromDate(startDate))
              .get();

            let totalEarnings = 0.0;
            let totalShipments = 0;

            for (const commissionDoc of commissionsSnapshot.docs) {
              totalEarnings += (commissionDoc.data().commissionAmount as number);
              totalShipments++;
            }

            leaderboard.push({
              affiliateId,
              fullName: affiliateData.fullName,
              email: affiliateData.email,
              photoUrl: affiliateData.photoUrl,
              totalEarnings,
              totalShipments,
              commissionRate: affiliateData.commissionRate,
            });
          }

          // Sort by earnings descending
          leaderboard.sort((a, b) => b.totalEarnings - a.totalEarnings);

          return {
            success: true,
            metric,
            period,
            leaderboard: leaderboard.slice(0, limit),
          };

        case 'shipments':
          // Sort by total shipments
          query = db
            .collection('affiliates')
            .where('status', '==', 'approved')
            .orderBy('totalShipments', 'desc')
            .limit(limit);
          break;

        case 'conversion':
          // Calculate conversion rate from form shares
          const allAffiliates = await db
            .collection('affiliates')
            .where('status', '==', 'approved')
            .get();

          const conversionLeaderboard: any[] = [];

          for (const doc of allAffiliates.docs) {
            const affiliateId = doc.id;
            const affiliateData = doc.data();

            // Get form shares in date range
            const formSharesSnapshot = await db
              .collection('form_shares')
              .where('affiliateId', '==', affiliateId)
              .where('createdAt', '>=', admin.firestore.Timestamp.fromDate(startDate))
              .get();

            let totalShares = formSharesSnapshot.size;
            let usedShares = 0;

            for (const shareDoc of formSharesSnapshot.docs) {
              if (shareDoc.data().used) {
                usedShares++;
              }
            }

            const conversionRate = totalShares > 0 ? (usedShares / totalShares) * 100 : 0;

            conversionLeaderboard.push({
              affiliateId,
              fullName: affiliateData.fullName,
              email: affiliateData.email,
              photoUrl: affiliateData.photoUrl,
              totalShares,
              usedShares,
              conversionRate,
            });
          }

          // Sort by conversion rate descending
          conversionLeaderboard.sort((a, b) => b.conversionRate - a.conversionRate);

          return {
            success: true,
            metric,
            period,
            leaderboard: conversionLeaderboard.slice(0, limit),
          };

        default:
          throw new functions.https.HttpsError(
            'invalid-argument',
            `Invalid metric: ${metric}`
          );
      }

      const snapshot = await query.get();

      const leaderboard = snapshot.docs.map(doc => {
        const data = doc.data();
        return {
          affiliateId: doc.id,
          fullName: data.fullName,
          email: data.email,
          photoUrl: data.photoUrl,
          totalShipments: data.totalShipments || 0,
          totalEarnings: data.totalEarnings || 0,
          commissionRate: data.commissionRate || 0,
        };
      });

      return {
        success: true,
        metric,
        period,
        leaderboard,
      };

    } catch (error) {
      console.error('Error in getAffiliateLeaderboard:', error);
      throw error;
    }
  }
);

// Helper function to get week key (YYYY-Www)
function getWeekKey(date: Date): string {
  const d = new Date(date);
  d.setHours(0, 0, 0, 0);
  d.setDate(d.getDate() + 4 - (d.getDay() || 7));
  const year = d.getFullYear();
  const week = Math.ceil((((d.getTime() - new Date(year, 0, 1).getTime()) / 86400000) + 1) / 7);
  return `${year}-W${String(week).padStart(2, '0')}`;
}

// Helper function to get days between two dates
function getDaysBetween(startDate: Date, endDate: Date): number {
  const oneDay = 24 * 60 * 60 * 1000;
  return Math.round(Math.abs((endDate.getTime() - startDate.getTime()) / oneDay));
}
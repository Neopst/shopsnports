/**
 * Monitoring & Alerting Module
 *
 * Provides health check endpoints and alerting for system events.
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

/**
 * System health check response
 */
export interface HealthCheckResponse {
  status: 'healthy' | 'degraded' | 'unhealthy';
  timestamp: admin.firestore.Timestamp;
  checks: {
    firestore: { status: 'ok' | 'error'; latency?: number; error?: string };
    auth: { status: 'ok' | 'error'; error?: string };
    storage: { status: 'ok' | 'error'; error?: string };
    functions: { status: 'ok' | 'error'; error?: string };
  };
  version: string;
}

/**
 * Health check function
 */
export const healthCheck = functions.https.onRequest(async (req, res) => {
  const startTime = Date.now();
  const checks: HealthCheckResponse['checks'] = {
    firestore: { status: 'ok' },
    auth: { status: 'ok' },
    storage: { status: 'ok' },
    functions: { status: 'ok' },
  };

  try {
    // Check Firestore
    const firestoreStart = Date.now();
    await admin.firestore().collection('_health').limit(1).get();
    checks.firestore.latency = Date.now() - firestoreStart;
  } catch (error: any) {
    checks.firestore.status = 'error';
    checks.firestore.error = error.message;
  }

  try {
    // Check Auth
    await admin.auth().getUserByEmail('system@healthcheck.shopsnports.com').catch(() => {
      // Expected to fail - just checking the service is responsive
    });
  } catch (error: any) {
    checks.auth.status = 'error';
    checks.auth.error = error.message;
  }

  try {
    // Check Storage
    await admin.storage().bucket().file('_health').getMetadata().catch(() => {
      // Expected to fail - just checking the service is responsive
    });
  } catch (error: any) {
    checks.storage.status = 'error';
    checks.storage.error = error.message;
  }

  // Determine overall status
  const hasErrors = Object.values(checks).some((check) => check.status === 'error');
  const hasWarnings = Object.values(checks).some((check) => (check as any).latency && (check as any).latency > 1000);

  const response: HealthCheckResponse = {
    status: hasErrors ? 'unhealthy' : hasWarnings ? 'degraded' : 'healthy',
    timestamp: admin.firestore.FieldValue.serverTimestamp() as any,
    checks,
    version: process.env.FUNCTIONS_EMULATOR ? 'local' : 'production',
  };

  res.status(hasErrors ? 503 : 200).json(response);
});

/**
 * System metrics for monitoring
 */
export interface SystemMetrics {
  timestamp: admin.firestore.Timestamp;
  activeUsers24h: number;
  activeAdmins: number;
  activeAffiliates: number;
  pendingShippingRequests: number;
  pendingPayouts: number;
  pendingCommissions: number;
  failedEmails24h: number;
  failedNotifications24h: number;
  avgResponseTimeMs: number;
}

/**
 * Collect system metrics
 */
export async function collectSystemMetrics(db: admin.firestore.Firestore): Promise<SystemMetrics> {
  const now = admin.firestore.Timestamp.now();
  const oneDayAgo = new Date(now.toDate().getTime() - 24 * 60 * 60 * 1000);

  // Get counts using aggregation queries would be better, but using simple counts for now
  const [usersSnap, adminsSnap, affiliatesSnap, requestsSnap, payoutsSnap, commissionsSnap] = await Promise.all([
    db.collection('users').where('lastLogin', '>=', admin.firestore.Timestamp.fromDate(oneDayAgo)).get(),
    db.collection('admin_users').where('isActive', '==', true).get(),
    db.collection('affiliates').where('isActive', '==', true).get(),
    db.collection('shippingRequests').where('status', 'in', ['submitted', 'processing']).get(),
    db.collection('payouts').where('status', '==', 'pending').get(),
    db.collection('commissions').where('status', '==', 'pending').get(),
  ]);

  // Get failed messages
  const [failedEmailsSnap, failedNotifsSnap] = await Promise.all([
    db.collection('email_queue').where('failed', '==', true).where('createdAt', '>=', admin.firestore.Timestamp.fromDate(oneDayAgo)).get(),
    db.collection('push_notification_stats').where('status', '==', 'failed').where('createdAt', '>=', admin.firestore.Timestamp.fromDate(oneDayAgo)).get(),
  ]);

  return {
    timestamp: now,
    activeUsers24h: usersSnap.size,
    activeAdmins: adminsSnap.size,
    activeAffiliates: affiliatesSnap.size,
    pendingShippingRequests: requestsSnap.size,
    pendingPayouts: payoutsSnap.size,
    pendingCommissions: commissionsSnap.size,
    failedEmails24h: failedEmailsSnap.size,
    failedNotifications24h: failedNotifsSnap.size,
    avgResponseTimeMs: 0, // Would need custom tracking
  };
}

/**
 * Store metrics in Firestore (called periodically)
 */
export async function storeMetrics(db: admin.firestore.Firestore): Promise<void> {
  const metrics = await collectSystemMetrics(db);
  await db.collection('system_metrics').add(metrics);
  console.log('System metrics stored');
}

/**
 * Alert thresholds
 */
export const ALERT_THRESHOLDS = {
  failedEmailsCritical: 100,
  failedEmailsWarning: 50,
  failedNotificationsCritical: 100,
  failedNotificationsWarning: 50,
  pendingRequestsCritical: 1000,
  pendingRequestsWarning: 500,
  pendingPayoutsCritical: 100,
  pendingPayoutsWarning: 50,
};

/**
 * Check thresholds and create alerts
 */
export async function checkAlertThresholds(db: admin.firestore.Firestore): Promise<void> {
  const metrics = await collectSystemMetrics(db);

  const alerts: string[] = [];

  if (metrics.failedEmails24h >= ALERT_THRESHOLDS.failedEmailsCritical) {
    alerts.push(`CRITICAL: ${metrics.failedEmails24h} failed emails in 24h`);
  } else if (metrics.failedEmails24h >= ALERT_THRESHOLDS.failedEmailsWarning) {
    alerts.push(`WARNING: ${metrics.failedEmails24h} failed emails in 24h`);
  }

  if (metrics.failedNotifications24h >= ALERT_THRESHOLDS.failedNotificationsCritical) {
    alerts.push(`CRITICAL: ${metrics.failedNotifications24h} failed notifications in 24h`);
  }

  if (metrics.pendingShippingRequests >= ALERT_THRESHOLDS.pendingRequestsCritical) {
    alerts.push(`CRITICAL: ${metrics.pendingShippingRequests} pending shipping requests`);
  }

  if (metrics.pendingPayouts >= ALERT_THRESHOLDS.pendingPayoutsCritical) {
    alerts.push(`CRITICAL: ${metrics.pendingPayouts} pending payouts`);
  }

  if (alerts.length > 0) {
    // Create alert notification for admins
    const alertDoc = {
      type: 'system_alert',
      severity: alerts.some((a) => a.includes('CRITICAL')) ? 'critical' : 'warning',
      title: 'System Alert',
      message: alerts.join(' | '),
      metrics: metrics,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      read: false,
    };

    // Add to notifications collection
    const adminSnapshot = await db.collection('users').where('role', '==', 'admin').get();
    const batch = db.batch();

    adminSnapshot.docs.forEach((doc) => {
      const notifRef = db.collection('notifications').doc();
      batch.set(notifRef, { ...alertDoc, targetUserId: doc.id, targetRole: 'admin' });
    });

    await batch.commit();
    console.log('Alert created for admins:', alerts);
  }
}

/**
 * Scheduled function to collect metrics and check alerts
 * Runs every hour
 */
export const metricsCollector = functions.pubsub
  .schedule('0 * * * *')
  .timeZone('UTC')
  .onRun(async () => {
    console.log('Running hourly metrics collection...');
    const db = admin.firestore();

    try {
      await storeMetrics(db);
      await checkAlertThresholds(db);
      console.log('Metrics collection completed');
    } catch (error) {
      console.error('Error in metrics collection:', error);
    }

    return null;
  });

/**
 * Get recent metrics for dashboard
 */
export async function getRecentMetrics(
  db: admin.firestore.Firestore,
  hours: number = 24
): Promise<SystemMetrics[]> {
  const startDate = new Date();
  startDate.setHours(startDate.getHours() - hours);

  const snapshot = await db.collection('system_metrics')
    .orderBy('timestamp', 'desc')
    .where('timestamp', '>=', admin.firestore.Timestamp.fromDate(startDate))
    .get();

  return snapshot.docs.map((doc) => doc.data() as SystemMetrics);
}
"use strict";
/**
 * Monitoring & Alerting Module
 *
 * Provides health check endpoints and alerting for system events.
 */
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.metricsCollector = exports.ALERT_THRESHOLDS = exports.healthCheck = void 0;
exports.collectSystemMetrics = collectSystemMetrics;
exports.storeMetrics = storeMetrics;
exports.checkAlertThresholds = checkAlertThresholds;
exports.getRecentMetrics = getRecentMetrics;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
/**
 * Health check function
 */
exports.healthCheck = functions.https.onRequest(async (req, res) => {
    const startTime = Date.now();
    const checks = {
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
    }
    catch (error) {
        checks.firestore.status = 'error';
        checks.firestore.error = error.message;
    }
    try {
        // Check Auth
        await admin.auth().getUserByEmail('system@healthcheck.shopsnports.com').catch(() => {
            // Expected to fail - just checking the service is responsive
        });
    }
    catch (error) {
        checks.auth.status = 'error';
        checks.auth.error = error.message;
    }
    try {
        // Check Storage
        await admin.storage().bucket().file('_health').getMetadata().catch(() => {
            // Expected to fail - just checking the service is responsive
        });
    }
    catch (error) {
        checks.storage.status = 'error';
        checks.storage.error = error.message;
    }
    // Determine overall status
    const hasErrors = Object.values(checks).some((check) => check.status === 'error');
    const hasWarnings = Object.values(checks).some((check) => check.latency && check.latency > 1000);
    const response = {
        status: hasErrors ? 'unhealthy' : hasWarnings ? 'degraded' : 'healthy',
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        checks,
        version: process.env.FUNCTIONS_EMULATOR ? 'local' : 'production',
    };
    res.status(hasErrors ? 503 : 200).json(response);
});
/**
 * Collect system metrics
 */
async function collectSystemMetrics(db) {
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
async function storeMetrics(db) {
    const metrics = await collectSystemMetrics(db);
    await db.collection('system_metrics').add(metrics);
    console.log('System metrics stored');
}
/**
 * Alert thresholds
 */
exports.ALERT_THRESHOLDS = {
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
async function checkAlertThresholds(db) {
    const metrics = await collectSystemMetrics(db);
    const alerts = [];
    if (metrics.failedEmails24h >= exports.ALERT_THRESHOLDS.failedEmailsCritical) {
        alerts.push(`CRITICAL: ${metrics.failedEmails24h} failed emails in 24h`);
    }
    else if (metrics.failedEmails24h >= exports.ALERT_THRESHOLDS.failedEmailsWarning) {
        alerts.push(`WARNING: ${metrics.failedEmails24h} failed emails in 24h`);
    }
    if (metrics.failedNotifications24h >= exports.ALERT_THRESHOLDS.failedNotificationsCritical) {
        alerts.push(`CRITICAL: ${metrics.failedNotifications24h} failed notifications in 24h`);
    }
    if (metrics.pendingShippingRequests >= exports.ALERT_THRESHOLDS.pendingRequestsCritical) {
        alerts.push(`CRITICAL: ${metrics.pendingShippingRequests} pending shipping requests`);
    }
    if (metrics.pendingPayouts >= exports.ALERT_THRESHOLDS.pendingPayoutsCritical) {
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
exports.metricsCollector = functions.pubsub
    .schedule('0 * * * *')
    .timeZone('UTC')
    .onRun(async () => {
    console.log('Running hourly metrics collection...');
    const db = admin.firestore();
    try {
        await storeMetrics(db);
        await checkAlertThresholds(db);
        console.log('Metrics collection completed');
    }
    catch (error) {
        console.error('Error in metrics collection:', error);
    }
    return null;
});
/**
 * Get recent metrics for dashboard
 */
async function getRecentMetrics(db, hours = 24) {
    const startDate = new Date();
    startDate.setHours(startDate.getHours() - hours);
    const snapshot = await db.collection('system_metrics')
        .orderBy('timestamp', 'desc')
        .where('timestamp', '>=', admin.firestore.Timestamp.fromDate(startDate))
        .get();
    return snapshot.docs.map((doc) => doc.data());
}

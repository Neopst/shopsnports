"use strict";
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
exports.unlockAdminAccount = exports.clearFailedLoginAttempts = exports.acknowledgeSecurityAlert = exports.getSecurityAlerts = exports.monitorAdminActivity = exports.trackFailedLogin = exports.SecurityAlertLevel = exports.SecurityEventType = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
/**
 * Security Monitoring Module
 *
 * Provides real-time monitoring and alerts for suspicious activities.
 * Detects and responds to potential security threats.
 */
/**
 * Security event types
 */
var SecurityEventType;
(function (SecurityEventType) {
    SecurityEventType["MULTIPLE_FAILED_LOGINS"] = "multiple_failed_logins";
    SecurityEventType["UNUSUAL_LOGIN_LOCATION"] = "unusual_login_location";
    SecurityEventType["UNUSUAL_LOGIN_TIME"] = "unusual_login_time";
    SecurityEventType["RAPID_PASSWORD_CHANGES"] = "rapid_password_changes";
    SecurityEventType["UNAUTHORIZED_ACCESS_ATTEMPT"] = "unauthorized_access_attempt";
    SecurityEventType["SUSPICIOUS_ADMIN_ACTIVITY"] = "suspicious_admin_activity";
    SecurityEventType["RATE_LIMIT_EXCEEDED"] = "rate_limit_exceeded";
    SecurityEventType["ACCOUNT_LOCKOUT"] = "account_lockout";
})(SecurityEventType || (exports.SecurityEventType = SecurityEventType = {}));
/**
 * Security alert levels
 */
var SecurityAlertLevel;
(function (SecurityAlertLevel) {
    SecurityAlertLevel["LOW"] = "low";
    SecurityAlertLevel["MEDIUM"] = "medium";
    SecurityAlertLevel["HIGH"] = "high";
    SecurityAlertLevel["CRITICAL"] = "critical";
})(SecurityAlertLevel || (exports.SecurityAlertLevel = SecurityAlertLevel = {}));
/**
 * Track failed login attempts
 *
 * Monitors multiple failed login attempts and triggers alerts
 */
exports.trackFailedLogin = functions.https.onCall(async (data, context) => {
    try {
        const { email, ipAddress, userAgent } = data;
        if (!email || !ipAddress) {
            throw new functions.https.HttpsError('invalid-argument', 'Email and IP address are required');
        }
        const db = admin.firestore();
        const now = new Date();
        const oneHourAgo = new Date(now.getTime() - 60 * 60 * 1000);
        // Get recent failed attempts for this email
        const failedAttemptsQuery = await db
            .collection('failed_login_attempts')
            .where('email', '==', email.toLowerCase())
            .where('timestamp', '>=', oneHourAgo)
            .get();
        const attemptCount = failedAttemptsQuery.size;
        // Log this failed attempt
        await db.collection('failed_login_attempts').add({
            email: email.toLowerCase(),
            ipAddress,
            userAgent: userAgent || 'unknown',
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
        // Check if threshold exceeded
        const MAX_FAILED_ATTEMPTS = 5;
        if (attemptCount >= MAX_FAILED_ATTEMPTS) {
            // Create security alert
            await createSecurityAlert({
                type: SecurityEventType.MULTIPLE_FAILED_LOGINS,
                level: SecurityAlertLevel.HIGH,
                adminEmail: email.toLowerCase(),
                ipAddress,
                userAgent,
                details: {
                    attemptCount: attemptCount + 1,
                    timeWindow: '1 hour',
                },
                timestamp: admin.firestore.FieldValue.serverTimestamp(),
            });
            // Check if admin account exists and lock it
            const adminQuery = await db
                .collection('admin_users')
                .where('email', '==', email.toLowerCase())
                .limit(1)
                .get();
            if (!adminQuery.empty) {
                const adminDoc = adminQuery.docs[0];
                await adminDoc.ref.update({
                    accountLocked: true,
                    lockedAt: admin.firestore.FieldValue.serverTimestamp(),
                    lockReason: 'Multiple failed login attempts',
                });
                // Create account lockout alert
                await createSecurityAlert({
                    type: SecurityEventType.ACCOUNT_LOCKOUT,
                    level: SecurityAlertLevel.CRITICAL,
                    adminId: adminDoc.id,
                    adminEmail: email.toLowerCase(),
                    ipAddress,
                    userAgent,
                    details: {
                        attemptCount: attemptCount + 1,
                    },
                    timestamp: admin.firestore.FieldValue.serverTimestamp(),
                });
            }
            console.log(`🚨 Multiple failed login attempts detected: ${email}`);
        }
        return {
            success: true,
            attemptCount: attemptCount + 1,
            locked: attemptCount >= MAX_FAILED_ATTEMPTS,
        };
    }
    catch (error) {
        console.error('❌ Error in trackFailedLogin:', error);
        throw error;
    }
});
/**
 * Monitor for suspicious admin activity
 *
 * Analyzes admin activity patterns and detects anomalies
 */
exports.monitorAdminActivity = functions.firestore
    .document('admin_activity_logs/{logId}')
    .onCreate(async (snap, context) => {
    try {
        const logData = snap.data();
        const adminId = logData.adminId;
        const action = logData.action;
        const timestamp = logData.timestamp?.toDate() || new Date();
        const db = admin.firestore();
        // Get admin info
        const adminDoc = await db.collection('admin_users').doc(adminId).get();
        if (!adminDoc.exists) {
            return;
        }
        const adminData = adminDoc.data();
        // Check for rapid password changes
        if (action === 'reset_admin_password' || action === 'PASSWORD_CHANGE') {
            const oneHourAgo = new Date(timestamp.getTime() - 60 * 60 * 1000);
            const recentPasswordChanges = await db
                .collection('admin_activity_logs')
                .where('adminId', '==', adminId)
                .where('action', 'in', ['reset_admin_password', 'PASSWORD_CHANGE'])
                .where('timestamp', '>=', oneHourAgo)
                .get();
            if (recentPasswordChanges.size > 3) {
                await createSecurityAlert({
                    type: SecurityEventType.RAPID_PASSWORD_CHANGES,
                    level: SecurityAlertLevel.HIGH,
                    adminId,
                    adminEmail: adminData?.email,
                    ipAddress: logData.ipAddress,
                    userAgent: logData.userAgent,
                    details: {
                        changeCount: recentPasswordChanges.size,
                        timeWindow: '1 hour',
                    },
                    timestamp: admin.firestore.FieldValue.serverTimestamp(),
                });
                console.log(`🚨 Rapid password changes detected for admin: ${adminId}`);
            }
        }
        // Check for unusual login time (outside business hours)
        if (action === 'login') {
            const hour = timestamp.getHours();
            const isUnusualTime = hour < 6 || hour > 22; // Outside 6 AM - 10 PM
            if (isUnusualTime) {
                await createSecurityAlert({
                    type: SecurityEventType.UNUSUAL_LOGIN_TIME,
                    level: SecurityAlertLevel.MEDIUM,
                    adminId,
                    adminEmail: adminData?.email,
                    ipAddress: logData.ipAddress,
                    userAgent: logData.userAgent,
                    details: {
                        loginTime: timestamp.toISOString(),
                        hour,
                    },
                    timestamp: admin.firestore.FieldValue.serverTimestamp(),
                });
            }
        }
        // Check for suspicious admin operations
        const suspiciousActions = [
            'created_admin',
            'updated_custom_claims',
            'grant_super_admin',
            'delete_admin',
        ];
        if (suspiciousActions.includes(action)) {
            // Check if this is a new admin performing sensitive operations
            const adminCreatedAt = adminData?.createdAt?.toDate() || new Date();
            const daysSinceCreation = (timestamp.getTime() - adminCreatedAt.getTime()) / (1000 * 60 * 60 * 24);
            if (daysSinceCreation < 7) {
                await createSecurityAlert({
                    type: SecurityEventType.SUSPICIOUS_ADMIN_ACTIVITY,
                    level: SecurityAlertLevel.HIGH,
                    adminId,
                    adminEmail: adminData?.email,
                    ipAddress: logData.ipAddress,
                    userAgent: logData.userAgent,
                    details: {
                        action,
                        daysSinceCreation: Math.floor(daysSinceCreation),
                    },
                    timestamp: admin.firestore.FieldValue.serverTimestamp(),
                });
                console.log(`🚨 Suspicious admin activity detected: ${adminId} performed ${action}`);
            }
        }
    }
    catch (error) {
        console.error('❌ Error in monitorAdminActivity:', error);
    }
});
/**
 * Create a security alert
 */
async function createSecurityAlert(event) {
    const db = admin.firestore();
    // Create alert document
    const alertRef = await db.collection('security_alerts').add({
        ...event,
        acknowledged: false,
        acknowledgedBy: null,
        acknowledgedAt: null,
    });
    // Notify super admins
    const superAdminsQuery = await db
        .collection('admin_users')
        .where('role', '==', 'super_admin')
        .where('isActive', '==', true)
        .get();
    const notifications = superAdminsQuery.docs.map((adminDoc) => {
        const adminData = adminDoc.data();
        return db.collection('notifications').add({
            type: 'security_alert',
            title: `Security Alert: ${event.type}`,
            message: getAlertMessage(event),
            level: event.level,
            adminId: adminDoc.id,
            adminEmail: adminData.email,
            alertId: alertRef.id,
            read: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
    });
    await Promise.all(notifications);
    // Send push notification to super admins
    const pushNotificationData = {
        title: 'Security Alert',
        body: getAlertMessage(event),
        level: event.level,
        alertId: alertRef.id,
    };
    // Queue push notifications
    await db.collection('push_notification_queue').add({
        topic: 'super_admins',
        data: pushNotificationData,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        sent: false,
        retries: 0,
    });
    console.log(`🚨 Security alert created: ${event.type} (${event.level})`);
}
/**
 * Get human-readable alert message
 */
function getAlertMessage(event) {
    switch (event.type) {
        case SecurityEventType.MULTIPLE_FAILED_LOGINS:
            return `Multiple failed login attempts detected for ${event.adminEmail}. ${event.details.attemptCount} attempts in ${event.details.timeWindow}.`;
        case SecurityEventType.UNUSUAL_LOGIN_LOCATION:
            return `Unusual login location detected for ${event.adminEmail}.`;
        case SecurityEventType.UNUSUAL_LOGIN_TIME:
            return `Unusual login time detected for ${event.adminEmail} at ${event.details.hour}:00.`;
        case SecurityEventType.RAPID_PASSWORD_CHANGES:
            return `Rapid password changes detected for ${event.adminEmail}. ${event.details.changeCount} changes in ${event.details.timeWindow}.`;
        case SecurityEventType.UNAUTHORIZED_ACCESS_ATTEMPT:
            return `Unauthorized access attempt detected from ${event.ipAddress}.`;
        case SecurityEventType.SUSPICIOUS_ADMIN_ACTIVITY:
            return `Suspicious admin activity detected. Admin ${event.adminEmail} performed ${event.details.action} ${event.details.daysSinceCreation} days after account creation.`;
        case SecurityEventType.RATE_LIMIT_EXCEEDED:
            return `Rate limit exceeded for ${event.adminEmail}.`;
        case SecurityEventType.ACCOUNT_LOCKOUT:
            return `Account locked for ${event.adminEmail} due to ${event.details.attemptCount} failed login attempts.`;
        default:
            return 'Security event detected.';
    }
}
/**
 * Get security alerts (super admin only)
 */
exports.getSecurityAlerts = functions.https.onCall(async (data, context) => {
    try {
        if (!context.auth) {
            throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
        }
        const callerId = context.auth.uid;
        const { limit = 50, acknowledged = false } = data;
        const db = admin.firestore();
        // Verify caller is super admin
        const callerDoc = await db.collection('admin_users').doc(callerId).get();
        if (!callerDoc.exists || callerDoc.data().role !== 'super_admin') {
            throw new functions.https.HttpsError('permission-denied', 'Only super admins can view security alerts');
        }
        // Get security alerts
        let query = db
            .collection('security_alerts')
            .orderBy('timestamp', 'desc')
            .limit(limit);
        if (acknowledged !== undefined) {
            query = query.where('acknowledged', '==', acknowledged);
        }
        const alertsQuery = await query.get();
        const alerts = alertsQuery.docs.map((doc) => ({
            id: doc.id,
            ...doc.data(),
            timestamp: doc.data().timestamp?.toDate() || new Date(),
        }));
        return {
            success: true,
            alerts,
            total: alertsQuery.size,
        };
    }
    catch (error) {
        console.error('❌ Error in getSecurityAlerts:', error);
        throw error;
    }
});
/**
 * Acknowledge security alert (super admin only)
 */
exports.acknowledgeSecurityAlert = functions.https.onCall(async (data, context) => {
    try {
        if (!context.auth) {
            throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
        }
        const callerId = context.auth.uid;
        const { alertId } = data;
        if (!alertId) {
            throw new functions.https.HttpsError('invalid-argument', 'Alert ID is required');
        }
        const db = admin.firestore();
        // Verify caller is super admin
        const callerDoc = await db.collection('admin_users').doc(callerId).get();
        if (!callerDoc.exists || callerDoc.data().role !== 'super_admin') {
            throw new functions.https.HttpsError('permission-denied', 'Only super admins can acknowledge security alerts');
        }
        // Acknowledge the alert
        await db.collection('security_alerts').doc(alertId).update({
            acknowledged: true,
            acknowledgedBy: callerId,
            acknowledgedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log(`✅ Security alert acknowledged: ${alertId}`);
        return {
            success: true,
            message: 'Alert acknowledged',
        };
    }
    catch (error) {
        console.error('❌ Error in acknowledgeSecurityAlert:', error);
        throw error;
    }
});
/**
 * Clear failed login attempts (super admin only)
 */
exports.clearFailedLoginAttempts = functions.https.onCall(async (data, context) => {
    try {
        if (!context.auth) {
            throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
        }
        const callerId = context.auth.uid;
        const { email } = data;
        if (!email) {
            throw new functions.https.HttpsError('invalid-argument', 'Email is required');
        }
        const db = admin.firestore();
        // Verify caller is super admin
        const callerDoc = await db.collection('admin_users').doc(callerId).get();
        if (!callerDoc.exists || callerDoc.data().role !== 'super_admin') {
            throw new functions.https.HttpsError('permission-denied', 'Only super admins can clear failed login attempts');
        }
        // Delete failed login attempts for this email
        const failedAttemptsQuery = await db
            .collection('failed_login_attempts')
            .where('email', '==', email.toLowerCase())
            .get();
        const batch = db.batch();
        failedAttemptsQuery.docs.forEach((doc) => {
            batch.delete(doc.ref);
        });
        await batch.commit();
        console.log(`✅ Cleared ${failedAttemptsQuery.size} failed login attempts for: ${email}`);
        return {
            success: true,
            clearedCount: failedAttemptsQuery.size,
        };
    }
    catch (error) {
        console.error('❌ Error in clearFailedLoginAttempts:', error);
        throw error;
    }
});
/**
 * Unlock admin account (super admin only)
 */
exports.unlockAdminAccount = functions.https.onCall(async (data, context) => {
    try {
        if (!context.auth) {
            throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
        }
        const callerId = context.auth.uid;
        const { adminId } = data;
        if (!adminId) {
            throw new functions.https.HttpsError('invalid-argument', 'Admin ID is required');
        }
        const db = admin.firestore();
        // Verify caller is super admin
        const callerDoc = await db.collection('admin_users').doc(callerId).get();
        if (!callerDoc.exists || callerDoc.data().role !== 'super_admin') {
            throw new functions.https.HttpsError('permission-denied', 'Only super admins can unlock admin accounts');
        }
        // Unlock the account
        await db.collection('admin_users').doc(adminId).update({
            accountLocked: false,
            lockedAt: null,
            lockReason: null,
            unlockedBy: callerId,
            unlockedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log(`✅ Admin account unlocked: ${adminId}`);
        return {
            success: true,
            message: 'Account unlocked',
        };
    }
    catch (error) {
        console.error('❌ Error in unlockAdminAccount:', error);
        throw error;
    }
});

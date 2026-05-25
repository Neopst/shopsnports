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
exports.getAdminActivityLogs = exports.getAdminActivityStats = exports.onAdminLogout = exports.onAdminLogin = exports.logAdminActivity = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
/**
 * Cloud Function: Log Admin Activity
 *
 * Triggered whenever certain admin operations occur.
 * Tracks:
 * - Admin login/logout
 * - Admin creation
 * - Permission changes
 * - Password resets
 * - Enable/disable admin
 * - Delete admin
 * - All dashboard operations (invoices, shipping, etc.)
 *
 * Callable Cloud Function for manual logging,
 * and hooks into other triggers for automatic logging
 */
exports.logAdminActivity = functions.https.onCall(async (data, context) => {
    try {
        if (!context.auth) {
            throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
        }
        const adminId = context.auth.uid;
        const { action, // Enum: login, logout, created_admin, updated_permissions, etc.
        targetAdminId, // Optional: admin being modified
        details, // Object: additional context
         } = data;
        if (!action) {
            throw new functions.https.HttpsError('invalid-argument', 'action is required');
        }
        const db = admin.firestore();
        // Get admin info
        const adminDoc = await db.collection('admin_users').doc(adminId).get();
        if (!adminDoc.exists) {
            throw new functions.https.HttpsError('permission-denied', 'Admin account not found');
        }
        const adminData = adminDoc.data();
        // Create activity log entry
        const logEntry = {
            adminId: adminId,
            adminEmail: adminData.email,
            adminName: adminData.displayName,
            adminRole: adminData.role,
            action: action,
            targetAdminId: targetAdminId || null,
            details: details || {},
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            ipAddress: context.rawRequest.ip,
            userAgent: context.rawRequest.headers['user-agent'],
        };
        // Write to activity logs
        const logRef = await db.collection('admin_activity_logs').add(logEntry);
        console.log(`✅ Admin activity logged: ${action} by ${adminData.email}`);
        return {
            success: true,
            logId: logRef.id,
            message: 'Activity logged successfully',
        };
    }
    catch (error) {
        console.error('❌ Error logging admin activity:', error);
        throw error;
    }
});
/**
 * Triggered on admin login (via custom claim or auth trigger)
 * Logs every admin login
 */
exports.onAdminLogin = functions.https.onCall(async (data, context) => {
    try {
        if (!context.auth) {
            throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
        }
        const adminId = context.auth.uid;
        const db = admin.firestore();
        // Verify caller is in admin_users collection
        const adminDoc = await db.collection('admin_users').doc(adminId).get();
        if (!adminDoc.exists) {
            throw new functions.https.HttpsError('permission-denied', 'User is not an admin');
        }
        const adminData = adminDoc.data();
        // Log login activity
        await db.collection('admin_activity_logs').add({
            adminId: adminId,
            adminEmail: adminData.email,
            action: 'login',
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            ipAddress: context.rawRequest.ip,
            userAgent: context.rawRequest.headers['user-agent'],
        });
        // Update last login
        await db.collection('admin_users').doc(adminId).update({
            lastLogin: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log(`✅ Admin login logged: ${adminData.email}`);
        return { success: true };
    }
    catch (error) {
        console.error('❌ Error logging admin login:', error);
        throw error;
    }
});
/**
 * Triggered on admin logout
 * Logs every admin logout
 */
exports.onAdminLogout = functions.https.onCall(async (data, context) => {
    try {
        if (!context.auth) {
            throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
        }
        const adminId = context.auth.uid;
        const db = admin.firestore();
        // Verify caller is in admin_users collection
        const adminDoc = await db.collection('admin_users').doc(adminId).get();
        if (!adminDoc.exists) {
            throw new functions.https.HttpsError('permission-denied', 'User is not an admin');
        }
        const adminData = adminDoc.data();
        // Log logout activity
        await db.collection('admin_activity_logs').add({
            adminId: adminId,
            adminEmail: adminData.email,
            action: 'logout',
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            ipAddress: context.rawRequest.ip,
            userAgent: context.rawRequest.headers['user-agent'],
        });
        console.log(`✅ Admin logout logged: ${adminData.email}`);
        return { success: true };
    }
    catch (error) {
        console.error('❌ Error logging admin logout:', error);
        throw error;
    }
});
/**
 * Get admin activity statistics for dashboard
 * Shows: login counts, action counts, etc.
 * Only super admins can view other admins' stats.
 * Regular admins can only view their own stats.
 */
exports.getAdminActivityStats = functions.https.onCall(async (data, context) => {
    try {
        if (!context.auth) {
            throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
        }
        const callerId = context.auth.uid;
        const { targetAdminId, timeRange = '30d' } = data;
        if (!targetAdminId) {
            throw new functions.https.HttpsError('invalid-argument', 'targetAdminId is required');
        }
        const db = admin.firestore();
        // ========== AUTHORIZATION CHECK ==========
        const callerDoc = await db.collection('admin_users').doc(callerId).get();
        if (!callerDoc.exists) {
            throw new functions.https.HttpsError('permission-denied', 'Caller is not an admin');
        }
        const callerData = callerDoc.data();
        const isSuperAdmin = callerData.role === 'super_admin';
        // Regular admins can only view their own stats
        if (!isSuperAdmin && callerId !== targetAdminId) {
            throw new functions.https.HttpsError('permission-denied', 'You can only view your own activity stats');
        }
        // Calculate date range
        const now = new Date();
        let startDate = new Date();
        if (timeRange === '7d')
            startDate.setDate(now.getDate() - 7);
        else if (timeRange === '30d')
            startDate.setDate(now.getDate() - 30);
        else if (timeRange === '90d')
            startDate.setDate(now.getDate() - 90);
        else
            startDate.setFullYear(now.getFullYear() - 1); // 1 year
        // Get activity logs for target admin
        const logsQuery = await db
            .collection('admin_activity_logs')
            .where('adminId', '==', targetAdminId)
            .where('timestamp', '>=', startDate)
            .get();
        // Count by action type
        const actionCounts = {};
        let loginCount = 0;
        let logoutCount = 0;
        logsQuery.docs.forEach((doc) => {
            const data = doc.data();
            const action = data.action;
            if (action === 'login')
                loginCount++;
            else if (action === 'logout')
                logoutCount++;
            else {
                actionCounts[action] = (actionCounts[action] || 0) + 1;
            }
        });
        console.log(`📊 Activity stats retrieved for admin: ${targetAdminId}, ${logsQuery.size} total activities`);
        return {
            success: true,
            timeRange,
            startDate: startDate.toISOString(),
            endDate: now.toISOString(),
            totalActivities: logsQuery.size,
            loginCount,
            logoutCount,
            actionCounts,
        };
    }
    catch (error) {
        console.error('❌ Error getting activity stats:', error);
        throw error;
    }
});
/**
 * Get activity logs for a specific admin
 * Used by admin activity log screen
 * Only super admins can view other admins' logs.
 * Regular admins can only view their own logs.
 */
exports.getAdminActivityLogs = functions.https.onCall(async (data, context) => {
    try {
        if (!context.auth) {
            throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
        }
        const callerId = context.auth.uid;
        const { targetAdminId, limit = 50, offset = 0 } = data;
        if (!targetAdminId) {
            throw new functions.https.HttpsError('invalid-argument', 'targetAdminId is required');
        }
        const db = admin.firestore();
        // ========== AUTHORIZATION CHECK ==========
        const callerDoc = await db.collection('admin_users').doc(callerId).get();
        if (!callerDoc.exists) {
            throw new functions.https.HttpsError('permission-denied', 'Caller is not an admin');
        }
        const callerData = callerDoc.data();
        const isSuperAdmin = callerData.role === 'super_admin';
        // Regular admins can only view their own logs
        if (!isSuperAdmin && callerId !== targetAdminId) {
            throw new functions.https.HttpsError('permission-denied', 'You can only view your own activity logs');
        }
        // Get activity logs
        const logsQuery = await db
            .collection('admin_activity_logs')
            .where('adminId', '==', targetAdminId)
            .orderBy('timestamp', 'desc')
            .limit(limit + offset)
            .get();
        const logs = logsQuery.docs.slice(offset).map((doc) => ({
            id: doc.id,
            ...doc.data(),
            timestamp: doc.data().timestamp?.toDate?.() || new Date(),
        }));
        console.log(`📋 Retrieved ${logs.length} activity logs for admin: ${targetAdminId}`);
        return {
            success: true,
            logs,
            total: logsQuery.size,
            limit,
            offset,
        };
    }
    catch (error) {
        console.error('❌ Error getting activity logs:', error);
        throw error;
    }
});

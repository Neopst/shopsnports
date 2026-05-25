"use strict";
/**
 * Audit Trail Module
 *
 * Provides comprehensive audit logging for critical operations.
 * Tracks who, what, when, and outcome of all sensitive actions.
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
exports.createAuditEntry = createAuditEntry;
exports.logAuditSuccess = logAuditSuccess;
exports.logAuditFailure = logAuditFailure;
exports.auditAdminCreate = auditAdminCreate;
exports.auditAdminUpdate = auditAdminUpdate;
exports.auditPayoutApprove = auditPayoutApprove;
exports.auditPayoutReject = auditPayoutReject;
exports.auditCommissionCalculate = auditCommissionCalculate;
exports.auditInvoiceGenerate = auditInvoiceGenerate;
exports.auditSettingsUpdate = auditSettingsUpdate;
exports.auditSecurityEvent = auditSecurityEvent;
exports.queryAuditTrail = queryAuditTrail;
exports.getAuditStats = getAuditStats;
const admin = __importStar(require("firebase-admin"));
/**
 * Create an audit entry
 */
async function createAuditEntry(db, entry) {
    const auditRef = db.collection('audit_trail').doc();
    await auditRef.set({
        ...entry,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
    console.log(`Audit: ${entry.actorEmail} - ${entry.action} ${entry.resourceType}:${entry.resourceId} [${entry.outcome}]`);
    return auditRef.id;
}
/**
 * Log a successful operation
 */
async function logAuditSuccess(db, actorId, actorEmail, actorRole, action, resourceType, resourceId, options) {
    return createAuditEntry(db, {
        actorId,
        actorEmail,
        actorRole,
        action,
        resourceType,
        resourceId,
        outcome: 'success',
        ...options,
    });
}
/**
 * Log a failed operation
 */
async function logAuditFailure(db, actorId, actorEmail, actorRole, action, resourceType, resourceId, errorMessage, options) {
    return createAuditEntry(db, {
        actorId,
        actorEmail,
        actorRole,
        action,
        resourceType,
        resourceId,
        outcome: 'failure',
        errorMessage,
        ...options,
    });
}
/**
 * Specialized audit loggers for common operations
 */
// Admin user operations
async function auditAdminCreate(db, actorId, actorEmail, actorRole, newAdminId, newAdminEmail, ipAddress) {
    return logAuditSuccess(db, actorId, actorEmail, actorRole, 'CREATE', 'admin_user', newAdminId, {
        metadata: { targetEmail: newAdminEmail },
        ipAddress,
    });
}
async function auditAdminUpdate(db, actorId, actorEmail, actorRole, targetAdminId, changes, ipAddress) {
    return logAuditSuccess(db, actorId, actorEmail, actorRole, 'UPDATE', 'admin_user', targetAdminId, {
        changes,
        ipAddress,
    });
}
// Payout operations
async function auditPayoutApprove(db, actorId, actorEmail, actorRole, payoutId, amount, ipAddress) {
    return logAuditSuccess(db, actorId, actorEmail, actorRole, 'APPROVE', 'payout', payoutId, {
        metadata: { amount },
        ipAddress,
    });
}
async function auditPayoutReject(db, actorId, actorEmail, actorRole, payoutId, reason, ipAddress) {
    return logAuditSuccess(db, actorId, actorEmail, actorRole, 'REJECT', 'payout', payoutId, {
        metadata: { reason },
        ipAddress,
    });
}
// Commission operations
async function auditCommissionCalculate(db, actorId, actorEmail, actorRole, commissionId, shippingRequestId, amount, ipAddress) {
    return logAuditSuccess(db, actorId, actorEmail, actorRole, 'PROCESS', 'commission', commissionId, {
        metadata: { shippingRequestId, amount },
        ipAddress,
    });
}
// Invoice operations
async function auditInvoiceGenerate(db, actorId, actorEmail, actorRole, invoiceId, shippingRequestId, amount, ipAddress) {
    return logAuditSuccess(db, actorId, actorEmail, actorRole, 'CREATE', 'invoice', invoiceId, {
        metadata: { shippingRequestId, amount },
        ipAddress,
    });
}
// Settings operations
async function auditSettingsUpdate(db, actorId, actorEmail, actorRole, settingKey, changes, ipAddress) {
    return logAuditSuccess(db, actorId, actorEmail, actorRole, 'UPDATE', 'settings', settingKey, {
        changes,
        ipAddress,
    });
}
// Security operations
async function auditSecurityEvent(db, actorId, actorEmail, actorRole, action, resourceType, resourceId, outcome, errorMessage, ipAddress) {
    if (outcome === 'failure') {
        return logAuditFailure(db, actorId, actorEmail, actorRole, action, resourceType, resourceId, errorMessage || 'Unknown error', { ipAddress });
    }
    return logAuditSuccess(db, actorId, actorEmail, actorRole, action, resourceType, resourceId, { ipAddress });
}
/**
 * Query audit entries
 */
async function queryAuditTrail(db, options) {
    let query = db.collection('audit_trail');
    if (options.actorId) {
        query = query.where('actorId', '==', options.actorId);
    }
    if (options.resourceType) {
        query = query.where('resourceType', '==', options.resourceType);
    }
    if (options.resourceId) {
        query = query.where('resourceId', '==', options.resourceId);
    }
    if (options.action) {
        query = query.where('action', '==', options.action);
    }
    if (options.outcome) {
        query = query.where('outcome', '==', options.outcome);
    }
    query = query.orderBy('timestamp', 'desc');
    if (options.limit) {
        query = query.limit(options.limit);
    }
    const snapshot = await query.get();
    let entries = snapshot.docs.map((doc) => doc.data());
    // Filter by date range (Firestore doesn't support date range queries well)
    if (options.startDate) {
        const startTimestamp = admin.firestore.Timestamp.fromDate(options.startDate);
        entries = entries.filter((entry) => entry.timestamp.toMillis() >= startTimestamp.toMillis());
    }
    if (options.endDate) {
        const endTimestamp = admin.firestore.Timestamp.fromDate(options.endDate);
        entries = entries.filter((entry) => entry.timestamp.toMillis() <= endTimestamp.toMillis());
    }
    return entries;
}
/**
 * Get audit statistics for dashboard
 */
async function getAuditStats(db, days = 7) {
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);
    const snapshot = await db.collection('audit_trail')
        .where('timestamp', '>=', admin.firestore.Timestamp.fromDate(startDate))
        .get();
    const stats = {
        totalEvents: 0,
        successCount: 0,
        failureCount: 0,
        byAction: {},
        byResourceType: {},
        topActors: [],
    };
    const actorCounts = {};
    snapshot.forEach((doc) => {
        const data = doc.data();
        stats.totalEvents++;
        if (data.outcome === 'success')
            stats.successCount++;
        else
            stats.failureCount++;
        stats.byAction[data.action] = (stats.byAction[data.action] || 0) + 1;
        stats.byResourceType[data.resourceType] = (stats.byResourceType[data.resourceType] || 0) + 1;
        actorCounts[data.actorEmail] = (actorCounts[data.actorEmail] || 0) + 1;
    });
    // Get top 5 actors
    stats.topActors = Object.entries(actorCounts)
        .sort(([, a], [, b]) => b - a)
        .slice(0, 5)
        .map(([actorEmail, count]) => ({ actorEmail, count }));
    return stats;
}

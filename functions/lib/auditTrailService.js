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
exports.AuditTrailService = void 0;
exports.createAuditTrailService = createAuditTrailService;
const admin = __importStar(require("firebase-admin"));
class AuditTrailService {
    constructor(db) {
        this.db = db;
    }
    /**
     * Log an audit entry
     */
    async log(entry) {
        const docRef = await this.db.collection('audit_trail').add({
            ...entry,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log(`Audit log created: ${docRef.id} for ${entry.entityType}:${entry.entityId}`);
        return docRef.id;
    }
    /**
     * Log a payout creation
     */
    async logPayoutCreated(payoutId, payoutData, performedBy, performedByRole = 'admin') {
        return this.log({
            entityType: 'payout',
            entityId: payoutId,
            action: 'created',
            performedBy,
            performedByRole,
            newValues: this.sanitizeData(payoutData),
            metadata: {
                payoutNumber: payoutData.payoutNumber,
                amount: payoutData.amount,
                affiliateId: payoutData.affiliateId,
            },
        });
    }
    /**
     * Log a payout status change
     */
    async logPayoutStatusChanged(payoutId, previousStatus, newStatus, performedBy, performedByRole = 'admin', metadata) {
        return this.log({
            entityType: 'payout',
            entityId: payoutId,
            action: 'status_changed',
            performedBy,
            performedByRole,
            changes: {
                status: {
                    oldValue: previousStatus,
                    newValue: newStatus,
                    field: 'status',
                },
            },
            previousValues: { status: previousStatus },
            newValues: { status: newStatus },
            metadata,
        });
    }
    /**
     * Log a payout processing
     */
    async logPayoutProcessed(payoutId, transactionId, paymentProvider, performedBy, performedByRole = 'admin') {
        return this.log({
            entityType: 'payout',
            entityId: payoutId,
            action: 'processed',
            performedBy,
            performedByRole,
            metadata: {
                transactionId,
                paymentProvider,
            },
        });
    }
    /**
     * Log a commission creation
     */
    async logCommissionCreated(commissionId, commissionData, performedBy = 'system', performedByRole = 'system') {
        return this.log({
            entityType: 'commission',
            entityId: commissionId,
            action: 'created',
            performedBy,
            performedByRole,
            newValues: this.sanitizeData(commissionData),
            metadata: {
                amount: commissionData.commissionAmount,
                affiliateId: commissionData.affiliateId,
                shipmentId: commissionData.shipmentId,
            },
        });
    }
    /**
     * Log a commission status change
     */
    async logCommissionStatusChanged(commissionId, previousStatus, newStatus, performedBy = 'system', performedByRole = 'system', metadata) {
        return this.log({
            entityType: 'commission',
            entityId: commissionId,
            action: 'status_changed',
            performedBy,
            performedByRole,
            changes: {
                status: {
                    oldValue: previousStatus,
                    newValue: newStatus,
                    field: 'status',
                },
            },
            previousValues: { status: previousStatus },
            newValues: { status: newStatus },
            metadata,
        });
    }
    /**
     * Log an affiliate creation
     */
    async logAffiliateCreated(affiliateId, affiliateData, performedBy, performedByRole = 'user') {
        return this.log({
            entityType: 'affiliate',
            entityId: affiliateId,
            action: 'created',
            performedBy,
            performedByRole,
            newValues: this.sanitizeData(affiliateData),
            metadata: {
                name: affiliateData.fullName || affiliateData.name,
                email: affiliateData.email,
            },
        });
    }
    /**
     * Log an affiliate status change
     */
    async logAffiliateStatusChanged(affiliateId, previousStatus, newStatus, performedBy, performedByRole = 'admin') {
        return this.log({
            entityType: 'affiliate',
            entityId: affiliateId,
            action: 'status_changed',
            performedBy,
            performedByRole,
            changes: {
                status: {
                    oldValue: previousStatus,
                    newValue: newStatus,
                    field: 'status',
                },
            },
            previousValues: { status: previousStatus },
            newValues: { status: newStatus },
        });
    }
    /**
     * Log payment settings update
     */
    async logPaymentSettingsUpdated(previousSettings, newSettings, performedBy, performedByRole = 'admin') {
        const changes = this.detectChanges(previousSettings, newSettings);
        return this.log({
            entityType: 'payment_settings',
            entityId: 'payment',
            action: 'updated',
            performedBy,
            performedByRole,
            changes,
            previousValues: previousSettings,
            newValues: newSettings,
        });
    }
    /**
     * Log payout schedule creation
     */
    async logPayoutScheduleCreated(scheduleId, scheduleData, performedBy, performedByRole = 'admin') {
        return this.log({
            entityType: 'payout_schedule',
            entityId: scheduleId,
            action: 'created',
            performedBy,
            performedByRole,
            newValues: this.sanitizeData(scheduleData),
            metadata: {
                scheduleType: scheduleData.scheduleType,
                minimumThreshold: scheduleData.minimumThreshold,
            },
        });
    }
    /**
     * Log payout schedule update
     */
    async logPayoutScheduleUpdated(scheduleId, previousData, newData, performedBy, performedByRole = 'admin') {
        const changes = this.detectChanges(previousData, newData);
        return this.log({
            entityType: 'payout_schedule',
            entityId: scheduleId,
            action: 'updated',
            performedBy,
            performedByRole,
            changes,
            previousValues: previousData,
            newValues: newData,
        });
    }
    /**
     * Log payout schedule deletion
     */
    async logPayoutScheduleDeleted(scheduleId, scheduleData, performedBy, performedByRole = 'admin') {
        return this.log({
            entityType: 'payout_schedule',
            entityId: scheduleId,
            action: 'deleted',
            performedBy,
            performedByRole,
            previousValues: this.sanitizeData(scheduleData),
            metadata: {
                scheduleType: scheduleData.scheduleType,
                minimumThreshold: scheduleData.minimumThreshold,
            },
        });
    }
    /**
     * Get audit trail for an entity
     */
    async getAuditTrail(entityType, entityId, limit = 50) {
        return this.db
            .collection('audit_trail')
            .where('entityType', '==', entityType)
            .where('entityId', '==', entityId)
            .orderBy('timestamp', 'desc')
            .limit(limit)
            .get();
    }
    /**
     * Get audit trail for a user
     */
    async getUserAuditTrail(userId, limit = 100) {
        return this.db
            .collection('audit_trail')
            .where('performedBy', '==', userId)
            .orderBy('timestamp', 'desc')
            .limit(limit)
            .get();
    }
    /**
     * Get recent audit entries
     */
    async getRecentAuditEntries(entityType, limit = 50) {
        let query = this.db
            .collection('audit_trail')
            .orderBy('timestamp', 'desc')
            .limit(limit);
        if (entityType) {
            query = query.where('entityType', '==', entityType);
        }
        return query.get();
    }
    /**
     * Detect changes between two objects
     */
    detectChanges(previous, current) {
        const changes = {};
        const allKeys = new Set([...Object.keys(previous), ...Object.keys(current)]);
        for (const key of allKeys) {
            const oldValue = previous[key];
            const newValue = current[key];
            if (JSON.stringify(oldValue) !== JSON.stringify(newValue)) {
                changes[key] = {
                    oldValue,
                    newValue,
                    field: key,
                };
            }
        }
        return changes;
    }
    /**
     * Sanitize data to remove sensitive information
     */
    sanitizeData(data) {
        const sanitized = {};
        const sensitiveFields = [
            'password',
            'token',
            'apiKey',
            'secret',
            'bankAccountNumber',
            'routingNumber',
            'ssn',
            'creditCard',
        ];
        for (const [key, value] of Object.entries(data)) {
            const isSensitive = sensitiveFields.some((field) => key.toLowerCase().includes(field.toLowerCase()));
            if (isSensitive && value) {
                sanitized[key] = '***REDACTED***';
            }
            else if (typeof value === 'object' && value !== null) {
                sanitized[key] = this.sanitizeData(value);
            }
            else {
                sanitized[key] = value;
            }
        }
        return sanitized;
    }
    /**
     * Clean up old audit entries (older than specified days)
     */
    async cleanupOldEntries(daysToKeep = 90) {
        const cutoffDate = new Date();
        cutoffDate.setDate(cutoffDate.getDate() - daysToKeep);
        const snapshot = await this.db
            .collection('audit_trail')
            .where('timestamp', '<', admin.firestore.Timestamp.fromDate(cutoffDate))
            .limit(500)
            .get();
        if (snapshot.empty) {
            return 0;
        }
        const batch = this.db.batch();
        for (const doc of snapshot.docs) {
            batch.delete(doc.ref);
        }
        await batch.commit();
        return snapshot.size;
    }
}
exports.AuditTrailService = AuditTrailService;
/**
 * Create audit trail service instance
 */
function createAuditTrailService(db) {
    return new AuditTrailService(db);
}

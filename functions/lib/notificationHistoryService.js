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
exports.NotificationHistoryService = void 0;
exports.createNotificationHistoryService = createNotificationHistoryService;
const admin = __importStar(require("firebase-admin"));
class NotificationHistoryService {
    constructor(db) {
        this.db = db;
    }
    /**
     * Log a notification to history
     */
    async logNotification(entry) {
        const docRef = await this.db.collection('notification_history').add({
            ...entry,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log(`Notification history logged: ${docRef.id}`);
        return docRef.id;
    }
    /**
     * Update notification delivery status
     */
    async updateDeliveryStatus(notificationId, status, metadata) {
        const updates = {
            deliveryStatus: status,
        };
        if (status === 'sent') {
            updates.sentAt = admin.firestore.FieldValue.serverTimestamp();
        }
        else if (status === 'delivered') {
            updates.deliveredAt = admin.firestore.FieldValue.serverTimestamp();
            updates.deliveredCount = admin.firestore.FieldValue.increment(1);
        }
        else if (status === 'opened') {
            updates.openedAt = admin.firestore.FieldValue.serverTimestamp();
            updates.openedCount = admin.firestore.FieldValue.increment(1);
        }
        else if (status === 'clicked') {
            updates.clickedAt = admin.firestore.FieldValue.serverTimestamp();
            updates.clickedCount = admin.firestore.FieldValue.increment(1);
        }
        else if (status === 'failed') {
            updates.failedCount = admin.firestore.FieldValue.increment(1);
        }
        if (metadata) {
            updates.metadata = metadata;
        }
        await this.db
            .collection('notification_history')
            .where('notificationId', '==', notificationId)
            .get()
            .then((snapshot) => {
            const batch = this.db.batch();
            snapshot.docs.forEach((doc) => {
                batch.update(doc.ref, updates);
            });
            return batch.commit();
        });
    }
    /**
     * Get notification history with filters
     */
    async getNotificationHistory(filters) {
        let query = this.db
            .collection('notification_history')
            .orderBy('createdAt', 'desc');
        if (filters.type) {
            query = query.where('type', '==', filters.type);
        }
        if (filters.targetRole) {
            query = query.where('targetRole', '==', filters.targetRole);
        }
        if (filters.targetUserId) {
            query = query.where('targetUserId', '==', filters.targetUserId);
        }
        if (filters.deliveryStatus) {
            query = query.where('deliveryStatus', '==', filters.deliveryStatus);
        }
        if (filters.startDate) {
            query = query.where('createdAt', '>=', admin.firestore.Timestamp.fromDate(filters.startDate));
        }
        if (filters.endDate) {
            query = query.where('createdAt', '<=', admin.firestore.Timestamp.fromDate(filters.endDate));
        }
        const limit = filters.limit || 100;
        return query.limit(limit).get();
    }
    /**
     * Get notification statistics
     */
    async getNotificationStatistics(filters) {
        let query = this.db.collection('notification_history');
        if (filters?.type) {
            query = query.where('type', '==', filters.type);
        }
        if (filters?.targetRole) {
            query = query.where('targetRole', '==', filters.targetRole);
        }
        if (filters?.startDate) {
            query = query.where('createdAt', '>=', admin.firestore.Timestamp.fromDate(filters.startDate));
        }
        if (filters?.endDate) {
            query = query.where('createdAt', '<=', admin.firestore.Timestamp.fromDate(filters.endDate));
        }
        const snapshot = await query.get();
        let total = 0;
        let sent = 0;
        let delivered = 0;
        let opened = 0;
        let clicked = 0;
        let failed = 0;
        snapshot.docs.forEach((doc) => {
            const data = doc.data();
            total++;
            if (data.deliveryStatus === 'sent' || data.deliveryStatus === 'delivered' ||
                data.deliveryStatus === 'opened' || data.deliveryStatus === 'clicked') {
                sent += data.sentCount;
            }
            delivered += data.deliveredCount;
            opened += data.openedCount;
            clicked += data.clickedCount;
            failed += data.failedCount;
        });
        return {
            total,
            sent,
            delivered,
            opened,
            clicked,
            failed,
            deliveryRate: sent > 0 ? (delivered / sent * 100).toFixed(2) : '0',
            openRate: delivered > 0 ? (opened / delivered * 100).toFixed(2) : '0',
            clickRate: opened > 0 ? (clicked / opened * 100).toFixed(2) : '0',
        };
    }
    /**
     * Search notifications by message content
     */
    async searchNotifications(query, limit = 50) {
        // Note: Firestore doesn't support full-text search natively
        // This is a simple implementation that searches title and body
        // For production, consider using Algolia or similar service
        const snapshot = await this.db
            .collection('notification_history')
            .orderBy('createdAt', 'desc')
            .limit(limit)
            .get();
        // Filter client-side (not ideal for large datasets)
        const filteredDocs = snapshot.docs.filter((doc) => {
            const data = doc.data();
            const title = data.title?.toLowerCase() || '';
            const body = data.body?.toLowerCase() || '';
            const searchQuery = query.toLowerCase();
            return title.includes(searchQuery) || body.includes(searchQuery);
        });
        // Return as a QuerySnapshot-like object
        return {
            docs: filteredDocs,
            empty: filteredDocs.length === 0,
            size: filteredDocs.length,
            forEach: (callback) => filteredDocs.forEach(callback),
        };
    }
    /**
     * Get failed notifications for retry
     */
    async getFailedNotifications(limit = 100) {
        return this.db
            .collection('notification_history')
            .where('deliveryStatus', '==', 'failed')
            .orderBy('createdAt', 'desc')
            .limit(limit)
            .get();
    }
    /**
     * Clean up old notification history entries
     */
    async cleanupOldEntries(daysToKeep = 90) {
        const cutoffDate = new Date();
        cutoffDate.setDate(cutoffDate.getDate() - daysToKeep);
        const snapshot = await this.db
            .collection('notification_history')
            .where('createdAt', '<', admin.firestore.Timestamp.fromDate(cutoffDate))
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
    /**
     * Get notification by ID
     */
    async getNotificationById(notificationId) {
        const doc = await this.db.collection('notification_history').doc(notificationId).get();
        return doc.exists ? doc : null;
    }
    /**
     * Get notifications for a specific user
     */
    async getUserNotifications(userId, limit = 50) {
        return this.db
            .collection('notification_history')
            .where('targetUserId', '==', userId)
            .orderBy('createdAt', 'desc')
            .limit(limit)
            .get();
    }
    /**
     * Get notifications by type
     */
    async getNotificationsByType(type, limit = 50) {
        return this.db
            .collection('notification_history')
            .where('type', '==', type)
            .orderBy('createdAt', 'desc')
            .limit(limit)
            .get();
    }
}
exports.NotificationHistoryService = NotificationHistoryService;
/**
 * Create notification history service instance
 */
function createNotificationHistoryService(db) {
    return new NotificationHistoryService(db);
}

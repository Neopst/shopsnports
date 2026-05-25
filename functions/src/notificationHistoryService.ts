import * as admin from 'firebase-admin';

/**
 * Notification History Service
 *
 * Tracks all sent notifications with delivery status
 * Provides search and filter functionality
 * Stores notification statistics
 */

export interface NotificationHistoryEntry {
  id?: string;
  notificationId: string;
  type: string;
  title: string;
  body: string;
  targetUserId?: string;
  targetRole?: string;
  targetTopic?: string;
  targetTokens?: string[];
  deliveryStatus: 'pending' | 'sent' | 'delivered' | 'failed' | 'opened' | 'clicked';
  sentCount: number;
  deliveredCount: number;
  openedCount: number;
  clickedCount: number;
  failedCount: number;
  errorMessage?: string;
  metadata?: Record<string, any>;
  createdAt?: admin.firestore.FieldValue;
  sentAt?: admin.firestore.FieldValue;
  deliveredAt?: admin.firestore.FieldValue;
  openedAt?: admin.firestore.FieldValue;
  clickedAt?: admin.firestore.FieldValue;
  createdBy?: string;
  createdByRole?: 'admin' | 'system' | 'affiliate' | 'user';
}

export class NotificationHistoryService {
  private db: admin.firestore.Firestore;

  constructor(db: admin.firestore.Firestore) {
    this.db = db;
  }

  /**
   * Log a notification to history
   */
  async logNotification(entry: NotificationHistoryEntry): Promise<string> {
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
  async updateDeliveryStatus(
    notificationId: string,
    status: 'sent' | 'delivered' | 'failed' | 'opened' | 'clicked',
    metadata?: Record<string, any>
  ): Promise<void> {
    const updates: Record<string, any> = {
      deliveryStatus: status,
    };

    if (status === 'sent') {
      updates.sentAt = admin.firestore.FieldValue.serverTimestamp();
    } else if (status === 'delivered') {
      updates.deliveredAt = admin.firestore.FieldValue.serverTimestamp();
      updates.deliveredCount = admin.firestore.FieldValue.increment(1);
    } else if (status === 'opened') {
      updates.openedAt = admin.firestore.FieldValue.serverTimestamp();
      updates.openedCount = admin.firestore.FieldValue.increment(1);
    } else if (status === 'clicked') {
      updates.clickedAt = admin.firestore.FieldValue.serverTimestamp();
      updates.clickedCount = admin.firestore.FieldValue.increment(1);
    } else if (status === 'failed') {
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
  async getNotificationHistory(filters: {
    type?: string;
    targetRole?: string;
    targetUserId?: string;
    deliveryStatus?: string;
    startDate?: Date;
    endDate?: Date;
    limit?: number;
  }): Promise<admin.firestore.QuerySnapshot> {
    let query: admin.firestore.Query = this.db
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
  async getNotificationStatistics(filters?: {
    type?: string;
    targetRole?: string;
    startDate?: Date;
    endDate?: Date;
  }): Promise<Record<string, any>> {
    let query: admin.firestore.Query = this.db.collection('notification_history');

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
      const data = doc.data() as NotificationHistoryEntry;
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
  async searchNotifications(query: string, limit: number = 50): Promise<admin.firestore.QuerySnapshot> {
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
      const data = doc.data() as NotificationHistoryEntry;
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
    } as any;
  }

  /**
   * Get failed notifications for retry
   */
  async getFailedNotifications(limit: number = 100): Promise<admin.firestore.QuerySnapshot> {
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
  async cleanupOldEntries(daysToKeep: number = 90): Promise<number> {
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
  async getNotificationById(notificationId: string): Promise<admin.firestore.DocumentSnapshot | null> {
    const doc = await this.db.collection('notification_history').doc(notificationId).get();
    return doc.exists ? doc : null;
  }

  /**
   * Get notifications for a specific user
   */
  async getUserNotifications(
    userId: string,
    limit: number = 50
  ): Promise<admin.firestore.QuerySnapshot> {
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
  async getNotificationsByType(
    type: string,
    limit: number = 50
  ): Promise<admin.firestore.QuerySnapshot> {
    return this.db
      .collection('notification_history')
      .where('type', '==', type)
      .orderBy('createdAt', 'desc')
      .limit(limit)
      .get();
  }
}

/**
 * Create notification history service instance
 */
export function createNotificationHistoryService(db: admin.firestore.Firestore): NotificationHistoryService {
  return new NotificationHistoryService(db);
}
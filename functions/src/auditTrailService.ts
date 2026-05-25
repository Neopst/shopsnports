import * as admin from 'firebase-admin';

/**
 * Audit Trail Service
 *
 * Tracks all changes to important entities:
 * - Payouts (created, updated, status changes)
 * - Commissions (created, updated, status changes)
 * - Affiliates (created, updated, status changes)
 * - Payment settings (updated)
 * - Payout schedules (created, updated, deleted)
 */

export interface AuditLogEntry {
  id?: string;
  entityType: 'payout' | 'commission' | 'affiliate' | 'payment_settings' | 'payout_schedule' | 'user' | 'admin';
  entityId: string;
  action: 'created' | 'updated' | 'deleted' | 'status_changed' | 'processed' | 'approved' | 'rejected';
  performedBy: string;
  performedByRole?: 'admin' | 'system' | 'affiliate' | 'user';
  changes?: Record<string, ChangeDetail>;
  previousValues?: Record<string, any>;
  newValues?: Record<string, any>;
  metadata?: Record<string, any>;
  timestamp?: admin.firestore.FieldValue;
  ipAddress?: string;
  userAgent?: string;
}

export interface ChangeDetail {
  oldValue?: any;
  newValue?: any;
  field: string;
}

export class AuditTrailService {
  private db: admin.firestore.Firestore;

  constructor(db: admin.firestore.Firestore) {
    this.db = db;
  }

  /**
   * Log an audit entry
   */
  async log(entry: AuditLogEntry): Promise<string> {
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
  async logPayoutCreated(
    payoutId: string,
    payoutData: Record<string, any>,
    performedBy: string,
    performedByRole: 'admin' | 'system' = 'admin'
  ): Promise<string> {
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
  async logPayoutStatusChanged(
    payoutId: string,
    previousStatus: string,
    newStatus: string,
    performedBy: string,
    performedByRole: 'admin' | 'system' = 'admin',
    metadata?: Record<string, any>
  ): Promise<string> {
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
  async logPayoutProcessed(
    payoutId: string,
    transactionId: string,
    paymentProvider: string,
    performedBy: string,
    performedByRole: 'admin' | 'system' = 'admin'
  ): Promise<string> {
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
  async logCommissionCreated(
    commissionId: string,
    commissionData: Record<string, any>,
    performedBy: string = 'system',
    performedByRole: 'system' = 'system'
  ): Promise<string> {
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
  async logCommissionStatusChanged(
    commissionId: string,
    previousStatus: string,
    newStatus: string,
    performedBy: string = 'system',
    performedByRole: 'system' = 'system',
    metadata?: Record<string, any>
  ): Promise<string> {
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
  async logAffiliateCreated(
    affiliateId: string,
    affiliateData: Record<string, any>,
    performedBy: string,
    performedByRole: 'admin' | 'user' = 'user'
  ): Promise<string> {
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
  async logAffiliateStatusChanged(
    affiliateId: string,
    previousStatus: string,
    newStatus: string,
    performedBy: string,
    performedByRole: 'admin' = 'admin'
  ): Promise<string> {
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
  async logPaymentSettingsUpdated(
    previousSettings: Record<string, any>,
    newSettings: Record<string, any>,
    performedBy: string,
    performedByRole: 'admin' = 'admin'
  ): Promise<string> {
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
  async logPayoutScheduleCreated(
    scheduleId: string,
    scheduleData: Record<string, any>,
    performedBy: string,
    performedByRole: 'admin' = 'admin'
  ): Promise<string> {
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
  async logPayoutScheduleUpdated(
    scheduleId: string,
    previousData: Record<string, any>,
    newData: Record<string, any>,
    performedBy: string,
    performedByRole: 'admin' = 'admin'
  ): Promise<string> {
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
  async logPayoutScheduleDeleted(
    scheduleId: string,
    scheduleData: Record<string, any>,
    performedBy: string,
    performedByRole: 'admin' = 'admin'
  ): Promise<string> {
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
  async getAuditTrail(
    entityType: string,
    entityId: string,
    limit: number = 50
  ): Promise<admin.firestore.QuerySnapshot> {
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
  async getUserAuditTrail(
    userId: string,
    limit: number = 100
  ): Promise<admin.firestore.QuerySnapshot> {
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
  async getRecentAuditEntries(
    entityType?: string,
    limit: number = 50
  ): Promise<admin.firestore.QuerySnapshot> {
    let query = this.db
      .collection('audit_trail')
      .orderBy('timestamp', 'desc')
      .limit(limit);

    if (entityType) {
      query = query.where('entityType', '==', entityType) as any;
    }

    return query.get();
  }

  /**
   * Detect changes between two objects
   */
  private detectChanges(
    previous: Record<string, any>,
    current: Record<string, any>
  ): Record<string, ChangeDetail> {
    const changes: Record<string, ChangeDetail> = {};
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
  private sanitizeData(data: Record<string, any>): Record<string, any> {
    const sanitized: Record<string, any> = {};
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
      const isSensitive = sensitiveFields.some((field) =>
        key.toLowerCase().includes(field.toLowerCase())
      );

      if (isSensitive && value) {
        sanitized[key] = '***REDACTED***';
      } else if (typeof value === 'object' && value !== null) {
        sanitized[key] = this.sanitizeData(value);
      } else {
        sanitized[key] = value;
      }
    }

    return sanitized;
  }

  /**
   * Clean up old audit entries (older than specified days)
   */
  async cleanupOldEntries(daysToKeep: number = 90): Promise<number> {
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

/**
 * Create audit trail service instance
 */
export function createAuditTrailService(db: admin.firestore.Firestore): AuditTrailService {
  return new AuditTrailService(db);
}
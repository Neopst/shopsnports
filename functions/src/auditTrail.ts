/**
 * Audit Trail Module
 *
 * Provides comprehensive audit logging for critical operations.
 * Tracks who, what, when, and outcome of all sensitive actions.
 */

import * as admin from 'firebase-admin';

/**
 * Audit action types
 */
export type AuditAction =
  | 'CREATE'
  | 'UPDATE'
  | 'DELETE'
  | 'VIEW'
  | 'EXPORT'
  | 'APPROVE'
  | 'REJECT'
  | 'PROCESS'
  | 'LOGIN'
  | 'LOGOUT'
  | 'PASSWORD_CHANGE'
  | 'PERMISSION_CHANGE';

/**
 * Audit resource types
 */
export type AuditResourceType =
  | 'admin_user'
  | 'affiliate'
  | 'shipping_request'
  | 'commission'
  | 'payout'
  | 'invoice'
  | 'settings'
  | 'security_settings';

/**
 * Audit entry interface
 */
export interface AuditEntry {
  id?: string;
  timestamp: admin.firestore.Timestamp;
  actorId: string;
  actorEmail: string;
  actorRole: string;
  action: AuditAction;
  resourceType: AuditResourceType;
  resourceId: string;
  changes?: Record<string, { before: any; after: any }>;
  outcome: 'success' | 'failure';
  errorMessage?: string;
  ipAddress?: string;
  userAgent?: string;
  metadata?: Record<string, any>;
}

/**
 * Create an audit entry
 */
export async function createAuditEntry(
  db: admin.firestore.Firestore,
  entry: Omit<AuditEntry, 'id' | 'timestamp'>
): Promise<string> {
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
export async function logAuditSuccess(
  db: admin.firestore.Firestore,
  actorId: string,
  actorEmail: string,
  actorRole: string,
  action: AuditAction,
  resourceType: AuditResourceType,
  resourceId: string,
  options?: {
    changes?: Record<string, { before: any; after: any }>;
    ipAddress?: string;
    userAgent?: string;
    metadata?: Record<string, any>;
  }
): Promise<string> {
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
export async function logAuditFailure(
  db: admin.firestore.Firestore,
  actorId: string,
  actorEmail: string,
  actorRole: string,
  action: AuditAction,
  resourceType: AuditResourceType,
  resourceId: string,
  errorMessage: string,
  options?: {
    ipAddress?: string;
    userAgent?: string;
    metadata?: Record<string, any>;
  }
): Promise<string> {
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
export async function auditAdminCreate(
  db: admin.firestore.Firestore,
  actorId: string,
  actorEmail: string,
  actorRole: string,
  newAdminId: string,
  newAdminEmail: string,
  ipAddress?: string
): Promise<string> {
  return logAuditSuccess(db, actorId, actorEmail, actorRole, 'CREATE', 'admin_user', newAdminId, {
    metadata: { targetEmail: newAdminEmail },
    ipAddress,
  });
}

export async function auditAdminUpdate(
  db: admin.firestore.Firestore,
  actorId: string,
  actorEmail: string,
  actorRole: string,
  targetAdminId: string,
  changes: Record<string, { before: any; after: any }>,
  ipAddress?: string
): Promise<string> {
  return logAuditSuccess(db, actorId, actorEmail, actorRole, 'UPDATE', 'admin_user', targetAdminId, {
    changes,
    ipAddress,
  });
}

// Payout operations
export async function auditPayoutApprove(
  db: admin.firestore.Firestore,
  actorId: string,
  actorEmail: string,
  actorRole: string,
  payoutId: string,
  amount: number,
  ipAddress?: string
): Promise<string> {
  return logAuditSuccess(db, actorId, actorEmail, actorRole, 'APPROVE', 'payout', payoutId, {
    metadata: { amount },
    ipAddress,
  });
}

export async function auditPayoutReject(
  db: admin.firestore.Firestore,
  actorId: string,
  actorEmail: string,
  actorRole: string,
  payoutId: string,
  reason: string,
  ipAddress?: string
): Promise<string> {
  return logAuditSuccess(db, actorId, actorEmail, actorRole, 'REJECT', 'payout', payoutId, {
    metadata: { reason },
    ipAddress,
  });
}

// Commission operations
export async function auditCommissionCalculate(
  db: admin.firestore.Firestore,
  actorId: string,
  actorEmail: string,
  actorRole: string,
  commissionId: string,
  shippingRequestId: string,
  amount: number,
  ipAddress?: string
): Promise<string> {
  return logAuditSuccess(db, actorId, actorEmail, actorRole, 'PROCESS', 'commission', commissionId, {
    metadata: { shippingRequestId, amount },
    ipAddress,
  });
}

// Invoice operations
export async function auditInvoiceGenerate(
  db: admin.firestore.Firestore,
  actorId: string,
  actorEmail: string,
  actorRole: string,
  invoiceId: string,
  shippingRequestId: string,
  amount: number,
  ipAddress?: string
): Promise<string> {
  return logAuditSuccess(db, actorId, actorEmail, actorRole, 'CREATE', 'invoice', invoiceId, {
    metadata: { shippingRequestId, amount },
    ipAddress,
  });
}

// Settings operations
export async function auditSettingsUpdate(
  db: admin.firestore.Firestore,
  actorId: string,
  actorEmail: string,
  actorRole: string,
  settingKey: string,
  changes: Record<string, { before: any; after: any }>,
  ipAddress?: string
): Promise<string> {
  return logAuditSuccess(db, actorId, actorEmail, actorRole, 'UPDATE', 'settings', settingKey, {
    changes,
    ipAddress,
  });
}

// Security operations
export async function auditSecurityEvent(
  db: admin.firestore.Firestore,
  actorId: string,
  actorEmail: string,
  actorRole: string,
  action: AuditAction,
  resourceType: AuditResourceType,
  resourceId: string,
  outcome: 'success' | 'failure',
  errorMessage?: string,
  ipAddress?: string
): Promise<string> {
  if (outcome === 'failure') {
    return logAuditFailure(db, actorId, actorEmail, actorRole, action, resourceType, resourceId, errorMessage || 'Unknown error', { ipAddress });
  }
  return logAuditSuccess(db, actorId, actorEmail, actorRole, action, resourceType, resourceId, { ipAddress });
}

/**
 * Query audit entries
 */
export async function queryAuditTrail(
  db: admin.firestore.Firestore,
  options: {
    actorId?: string;
    resourceType?: AuditResourceType;
    resourceId?: string;
    action?: AuditAction;
    outcome?: 'success' | 'failure';
    startDate?: Date;
    endDate?: Date;
    limit?: number;
  }
): Promise<AuditEntry[]> {
  let query = db.collection('audit_trail') as admin.firestore.Query;

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

  let entries = snapshot.docs.map((doc) => doc.data() as AuditEntry);

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
export async function getAuditStats(
  db: admin.firestore.Firestore,
  days: number = 7
): Promise<{
  totalEvents: number;
  successCount: number;
  failureCount: number;
  byAction: Record<string, number>;
  byResourceType: Record<string, number>;
  topActors: Array<{ actorEmail: string; count: number }>;
}> {
  const startDate = new Date();
  startDate.setDate(startDate.getDate() - days);

  const snapshot = await db.collection('audit_trail')
    .where('timestamp', '>=', admin.firestore.Timestamp.fromDate(startDate))
    .get();

  const stats = {
    totalEvents: 0,
    successCount: 0,
    failureCount: 0,
    byAction: {} as Record<string, number>,
    byResourceType: {} as Record<string, number>,
    topActors: [] as Array<{ actorEmail: string; count: number }>,
  };

  const actorCounts: Record<string, number> = {};

  snapshot.forEach((doc) => {
    const data = doc.data() as AuditEntry;
    stats.totalEvents++;

    if (data.outcome === 'success') stats.successCount++;
    else stats.failureCount++;

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
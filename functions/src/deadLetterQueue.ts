/**
 * Dead Letter Queue Module
 *
 * Tracks failed messages (emails, push notifications) for retry
 * and analysis. Failed messages are moved to a dead letter queue
 * after max retries are exceeded.
 */

import * as admin from 'firebase-admin';

/**
 * Dead letter entry types
 */
export type DeadLetterType = 'email' | 'push_notification' | 'sms' | 'webhook';

/**
 * Dead letter entry status
 */
export type DeadLetterStatus = 'pending' | 'retrying' | 'failed' | 'resolved';

/**
 * Dead letter entry interface
 */
export interface DeadLetterEntry {
  id?: string;
  type: DeadLetterType;
  originalCollection: string;
  originalDocId: string;
  payload: Record<string, any>;
  errorMessage: string;
  errorCode?: string;
  retryCount: number;
  maxRetries: number;
  status: DeadLetterStatus;
  createdAt: admin.firestore.Timestamp;
  lastAttemptAt?: admin.firestore.Timestamp;
  resolvedAt?: admin.firestore.Timestamp;
  resolvedBy?: string;
  resolutionNote?: string;
}

/**
 * Add entry to dead letter queue
 */
export async function addToDeadLetterQueue(
  db: admin.firestore.Firestore,
  type: DeadLetterType,
  originalCollection: string,
  originalDocId: string,
  payload: Record<string, any>,
  error: Error | string,
  retryCount: number = 0,
  maxRetries: number = 3
): Promise<string> {
  const errorMessage = typeof error === 'string' ? error : error.message;
  const errorCode = typeof error === 'string' ? undefined : (error as any).code;

  const deadLetterRef = db.collection('dead_letter_queue').doc();

  await deadLetterRef.set({
    type,
    originalCollection,
    originalDocId,
    payload,
    errorMessage,
    errorCode,
    retryCount,
    maxRetries,
    status: retryCount >= maxRetries ? 'failed' : 'pending',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log(`Added to dead letter queue: ${type} - ${originalDocId} (${retryCount}/${maxRetries} retries)`);

  return deadLetterRef.id;
}

/**
 * Retry a dead letter entry
 */
export async function retryDeadLetter(
  db: admin.firestore.Firestore,
  deadLetterId: string
): Promise<{ success: boolean; message: string }> {
  const deadLetterRef = db.collection('dead_letter_queue').doc(deadLetterId);
  const deadLetterDoc = await deadLetterRef.get();

  if (!deadLetterDoc.exists) {
    return { success: false, message: 'Dead letter entry not found' };
  }

  const data = deadLetterDoc.data() as DeadLetterEntry;

  if (data.status === 'resolved') {
    return { success: false, message: 'Dead letter already resolved' };
  }

  // Update status to retrying
  await deadLetterRef.update({
    status: 'retrying',
    lastAttemptAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  try {
    // Retry based on type
    switch (data.type) {
      case 'email':
        // Email retry logic would go here
        console.log(`Retrying email: ${data.originalDocId}`);
        break;
      case 'push_notification':
        // Push notification retry logic would go here
        console.log(`Retrying push notification: ${data.originalDocId}`);
        break;
      default:
        console.log(`Retrying ${data.type}: ${data.originalDocId}`);
    }

    // Increment retry count
    const newRetryCount = data.retryCount + 1;

    if (newRetryCount >= data.maxRetries) {
      // Max retries exceeded, mark as failed
      await deadLetterRef.update({
        retryCount: newRetryCount,
        status: 'failed',
      });
      return { success: false, message: 'Max retries exceeded' };
    }

    // Update retry count, set back to pending
    await deadLetterRef.update({
      retryCount: newRetryCount,
      status: 'pending',
    });

    return { success: true, message: `Retry ${newRetryCount}/${data.maxRetries} scheduled` };
  } catch (error) {
    await deadLetterRef.update({
      status: 'pending',
    });
    throw error;
  }
}

/**
 * Resolve a dead letter entry (manually)
 */
export async function resolveDeadLetter(
  db: admin.firestore.Firestore,
  deadLetterId: string,
  resolvedBy: string,
  resolutionNote?: string
): Promise<void> {
  await db.collection('dead_letter_queue').doc(deadLetterId).update({
    status: 'resolved',
    resolvedAt: admin.firestore.FieldValue.serverTimestamp(),
    resolvedBy,
    resolutionNote: resolutionNote || 'Manually resolved',
  });
}

/**
 * Get dead letter statistics
 */
export async function getDeadLetterStats(
  db: admin.firestore.Firestore
): Promise<{
  total: number;
  pending: number;
  retrying: number;
  failed: number;
  resolved: number;
  byType: Record<string, number>;
}> {
  const snapshot = await db.collection('dead_letter_queue').get();

  const stats = {
    total: 0,
    pending: 0,
    retrying: 0,
    failed: 0,
    resolved: 0,
    byType: {} as Record<string, number>,
  };

  snapshot.forEach((doc) => {
    const data = doc.data() as DeadLetterEntry;
    stats.total++;

    if (data.status === 'pending') stats.pending++;
    else if (data.status === 'retrying') stats.retrying++;
    else if (data.status === 'failed') stats.failed++;
    else if (data.status === 'resolved') stats.resolved++;

    stats.byType[data.type] = (stats.byType[data.type] || 0) + 1;
  });

  return stats;
}

/**
 * Cleanup old resolved dead letter entries
 * Should be called periodically (e.g., weekly)
 */
export async function cleanupResolvedDeadLetters(
  db: admin.firestore.Firestore,
  daysOld: number = 30
): Promise<number> {
  const cutoffDate = new Date();
  cutoffDate.setDate(cutoffDate.getDate() - daysOld);

  const resolvedSnap = await db.collection('dead_letter_queue')
    .where('status', '==', 'resolved')
    .where('resolvedAt', '<', admin.firestore.Timestamp.fromDate(cutoffDate))
    .limit(500)
    .get();

  if (resolvedSnap.empty) {
    return 0;
  }

  const batch = db.batch();
  resolvedSnap.docs.forEach((doc) => {
    batch.delete(doc.ref);
  });

  await batch.commit();
  console.log(`Cleaned up ${resolvedSnap.size} resolved dead letter entries`);

  return resolvedSnap.size;
}
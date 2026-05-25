"use strict";
/**
 * Dead Letter Queue Module
 *
 * Tracks failed messages (emails, push notifications) for retry
 * and analysis. Failed messages are moved to a dead letter queue
 * after max retries are exceeded.
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
exports.addToDeadLetterQueue = addToDeadLetterQueue;
exports.retryDeadLetter = retryDeadLetter;
exports.resolveDeadLetter = resolveDeadLetter;
exports.getDeadLetterStats = getDeadLetterStats;
exports.cleanupResolvedDeadLetters = cleanupResolvedDeadLetters;
const admin = __importStar(require("firebase-admin"));
/**
 * Add entry to dead letter queue
 */
async function addToDeadLetterQueue(db, type, originalCollection, originalDocId, payload, error, retryCount = 0, maxRetries = 3) {
    const errorMessage = typeof error === 'string' ? error : error.message;
    const errorCode = typeof error === 'string' ? undefined : error.code;
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
async function retryDeadLetter(db, deadLetterId) {
    const deadLetterRef = db.collection('dead_letter_queue').doc(deadLetterId);
    const deadLetterDoc = await deadLetterRef.get();
    if (!deadLetterDoc.exists) {
        return { success: false, message: 'Dead letter entry not found' };
    }
    const data = deadLetterDoc.data();
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
    }
    catch (error) {
        await deadLetterRef.update({
            status: 'pending',
        });
        throw error;
    }
}
/**
 * Resolve a dead letter entry (manually)
 */
async function resolveDeadLetter(db, deadLetterId, resolvedBy, resolutionNote) {
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
async function getDeadLetterStats(db) {
    const snapshot = await db.collection('dead_letter_queue').get();
    const stats = {
        total: 0,
        pending: 0,
        retrying: 0,
        failed: 0,
        resolved: 0,
        byType: {},
    };
    snapshot.forEach((doc) => {
        const data = doc.data();
        stats.total++;
        if (data.status === 'pending')
            stats.pending++;
        else if (data.status === 'retrying')
            stats.retrying++;
        else if (data.status === 'failed')
            stats.failed++;
        else if (data.status === 'resolved')
            stats.resolved++;
        stats.byType[data.type] = (stats.byType[data.type] || 0) + 1;
    });
    return stats;
}
/**
 * Cleanup old resolved dead letter entries
 * Should be called periodically (e.g., weekly)
 */
async function cleanupResolvedDeadLetters(db, daysOld = 30) {
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

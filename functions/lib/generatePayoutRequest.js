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
exports.exportPayouts = exports.bulkProcessPayouts = exports.processPayout = exports.generatePayoutRequest = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const validation_1 = require("./validation");
const taxCalculation_1 = require("./taxCalculation");
const paymentService_1 = require("./paymentService");
/**
 * Cloud Function: Generate Payout Request from Commissions
 *
 * MANUAL PROCESS: Admin reviews commissions and generates payout request
 * Triggered: When admin clicks "Generate Payout" or "Pay Affiliate"
 *
 * Flow:
 * 1. Admin selects commissions to include (single/multiple)
 * 2. System aggregates commission amount
 * 3. Creates payout_request document
 * 4. Sends notification to affiliate
 * 5. Admin can process payout manually (bank transfer, etc)
 */
/**
 * Validate payout request input
 */
function validatePayoutRequestInput(data) {
    if (!data || typeof data !== 'object') {
        throw new validation_1.ValidationError('Request data must be an object', 'data', 'INVALID_TYPE');
    }
    const { affiliateId, commissionIds, amount, notes } = data;
    // Validate affiliateId
    (0, validation_1.validateString)(affiliateId, {
        required: true,
        minLength: 5,
        maxLength: 100,
        fieldName: 'affiliateId'
    });
    // Validate commissionIds
    if (!commissionIds || !Array.isArray(commissionIds)) {
        throw new validation_1.ValidationError('Commission IDs must be an array', 'commissionIds', 'INVALID_TYPE');
    }
    if (commissionIds.length === 0) {
        throw new validation_1.ValidationError('At least one commission must be selected', 'commissionIds', 'EMPTY');
    }
    if (commissionIds.length > 100) {
        throw new validation_1.ValidationError('Cannot include more than 100 commissions in a single payout', 'commissionIds', 'TOO_MANY');
    }
    // Validate each commission ID
    for (const id of commissionIds) {
        (0, validation_1.validateString)(id, {
            required: true,
            minLength: 5,
            maxLength: 100,
            fieldName: 'commissionIds'
        });
    }
    // Validate optional amount
    if (amount !== undefined) {
        (0, validation_1.validateNumber)(amount, {
            required: false,
            min: 0.01,
            max: 1000000,
            fieldName: 'amount'
        });
    }
    // Validate optional notes
    if (notes) {
        (0, validation_1.validateString)(notes, {
            required: false,
            maxLength: 1000,
            fieldName: 'notes'
        });
    }
}
const generatePayoutRequest = async (data, context) => {
    try {
        // Verify admin authentication
        if (!context.auth) {
            throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
        }
        if (!context.auth.token.admin) {
            throw new functions.https.HttpsError('permission-denied', 'Only admins can generate payout requests');
        }
        // Validate input data
        validatePayoutRequestInput(data);
        const db = admin.firestore();
        const { affiliateId, commissionIds, amount, period, notes } = data;
        console.log(`Generating payout request for affiliate ${affiliateId}`);
        console.log(`Commissions: ${commissionIds.join(', ')}`);
        // Fetch all commissions to validate and calculate total
        let totalAmount = amount ?? 0;
        const commissionSnapshots = await Promise.all(commissionIds.map((id) => db.collection('commissions').doc(id).get()));
        const commissions = [];
        for (const snap of commissionSnapshots) {
            if (!snap.exists) {
                throw new functions.https.HttpsError('not-found', `Commission ${snap.id} not found`);
            }
            const commission = snap.data();
            // Verify commission belongs to this affiliate
            if (commission.affiliateId !== affiliateId) {
                throw new functions.https.HttpsError('permission-denied', `Commission ${snap.id} does not belong to affiliate ${affiliateId}`);
            }
            // Only 'pending' or 'approved' commissions can be included in payout
            if (commission.status === 'paid') {
                throw new functions.https.HttpsError('invalid-argument', `Commission ${snap.id} is already paid`);
            }
            commissions.push({
                id: snap.id,
                amount: commission.commissionAmount,
                ...commission,
            });
            if (!amount) {
                totalAmount += commission.commissionAmount;
            }
        }
        if (totalAmount <= 0) {
            throw new functions.https.HttpsError('invalid-argument', 'Total payout amount must be greater than 0');
        }
        // Get affiliate info for payout record
        const affiliateDoc = await db.collection('affiliates').doc(affiliateId).get();
        if (!affiliateDoc.exists) {
            throw new functions.https.HttpsError('not-found', 'Affiliate not found');
        }
        const affiliateData = affiliateDoc.data();
        const bankDetails = affiliateData?.bankAccountDetails;
        // Calculate tax before transaction
        const taxCalculation = await (0, taxCalculation_1.calculateTax)(db, totalAmount, 'affiliate');
        const taxAmount = taxCalculation.taxAmount;
        // Use transaction for atomic operations
        const payoutResult = await db.runTransaction(async (transaction) => {
            // Create payout request within transaction
            const payoutRef = db.collection('payouts').doc();
            // Generate payout number: PAY-YYYYMMDD-XXXXX
            const now = new Date();
            const dateStr = now.toISOString().split('T')[0].replace(/-/g, '');
            const randomSuffix = Math.random().toString(36).substring(2, 7).toUpperCase();
            const payoutNumber = `PAY-${dateStr}-${randomSuffix}`;
            // Calculate payout amounts
            const grossAmount = totalAmount;
            const netAmount = grossAmount - taxAmount;
            // Set period dates
            const periodStart = admin.firestore.Timestamp.fromDate(now);
            const periodEnd = admin.firestore.Timestamp.fromDate(now);
            const payoutData = {
                payoutNumber,
                recipientType: 'affiliate',
                recipientId: affiliateId,
                recipientName: affiliateData?.fullName || 'Unknown',
                grossAmount,
                commissionAmount: totalAmount,
                taxAmount,
                netAmount,
                currency: 'USD',
                affiliateId,
                affiliateName: affiliateData?.fullName || 'Unknown',
                affiliateEmail: affiliateData?.email,
                amount: Math.round(totalAmount * 100) / 100,
                commissionIds,
                status: 'pending',
                bankAccountDetails: bankDetails,
                period: period || new Date().toISOString().slice(0, 7),
                periodStart,
                periodEnd,
                requestedAt: admin.firestore.FieldValue.serverTimestamp(),
                requestedBy: context.auth.uid,
                notes: notes || '',
                paymentMethod: 'bank_transfer',
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            };
            transaction.set(payoutRef, payoutData);
            // Mark commissions as "approved" within transaction
            for (const commission of commissions) {
                transaction.update(db.collection('commissions').doc(commission.id), {
                    status: 'approved',
                    payoutId: payoutRef.id,
                    approvedAt: admin.firestore.FieldValue.serverTimestamp(),
                });
            }
            return { payoutRef, payoutData };
        });
        console.log(`Payout request created: ${payoutResult.payoutRef.id} for $${totalAmount.toFixed(2)}`);
        console.log(`Updated ${commissions.length} commissions to 'approved' status`);
        // Create notifications (outside transaction - not critical)
        await db.collection('notifications').add({
            type: 'payout_ready',
            payoutId: payoutResult.payoutRef.id,
            affiliateId,
            targetUserId: affiliateId,
            targetRole: 'affiliate',
            read: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            message: `Your payout of $${totalAmount.toFixed(2)} is being processed. You'll receive it within 2-5 business days.`,
            actionUrl: `/affiliate/payouts/${payoutResult.payoutRef.id}`,
        });
        await db.collection('notifications').add({
            type: 'payout_generated',
            payoutId: payoutResult.payoutRef.id,
            affiliateId,
            targetRole: 'admin',
            read: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            message: `Payout request created for ${affiliateData?.fullName}: $${totalAmount.toFixed(2)}`,
            actionUrl: `/admin/payouts/${payoutResult.payoutRef.id}`,
        });
        // Log activity
        await db.collection('activity_log').add({
            type: 'payout_request_generated',
            payoutId: payoutResult.payoutRef.id,
            affiliateId,
            amount: totalAmount,
            commissionCount: commissionIds.length,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            performedBy: context.auth.uid,
        });
        return {
            success: true,
            message: 'Payout request generated successfully',
            payoutId: payoutResult.payoutRef.id,
            amount: parseFloat(totalAmount.toFixed(2)),
            commissionCount: commissions.length,
            affiliateName: affiliateData?.fullName,
        };
    }
    catch (error) {
        console.error('Payout generation error:', error);
        if (error instanceof functions.https.HttpsError) {
            throw error;
        }
        throw new functions.https.HttpsError('internal', 'Payout generation failed');
    }
};
exports.generatePayoutRequest = generatePayoutRequest;
/**
 * Cloud Function: Process Payout (Manual - Admin clicks "Pay Now")
 *
 * Updates payout status to "completed"
 * Marks all related commissions as "paid"
 * Sends confirmation to affiliate
 */
const processPayout = async (data, context) => {
    try {
        if (!context.auth?.token.admin) {
            throw new functions.https.HttpsError('permission-denied', 'Only admins can process payouts');
        }
        const db = admin.firestore();
        const { payoutId, transactionReference, notes, paymentProvider = 'manual' } = data;
        // Fetch payout
        const payoutDoc = await db.collection('payouts').doc(payoutId).get();
        if (!payoutDoc.exists) {
            throw new functions.https.HttpsError('not-found', 'Payout not found');
        }
        const payoutData = payoutDoc.data();
        if (payoutData?.status === 'completed') {
            throw new functions.https.HttpsError('invalid-argument', 'Payout already processed');
        }
        // Process payment using payment service
        const paymentService = (0, paymentService_1.createPaymentService)(db);
        const payoutRequestData = {
            payoutId,
            payoutNumber: payoutData?.payoutNumber || payoutId,
            amount: payoutData?.amount || 0,
            currency: payoutData?.currency || 'USD',
            recipientName: payoutData?.affiliateName || 'Unknown',
            recipientEmail: payoutData?.affiliateEmail || '',
            recipientType: 'affiliate',
            recipientId: payoutData?.affiliateId || '',
            bankAccountDetails: payoutData?.bankAccountDetails,
            paymentMethod: payoutData?.paymentMethod || 'bank_transfer',
            notes,
        };
        const paymentResult = await paymentService.processPayout(payoutRequestData, paymentProvider);
        if (!paymentResult.success) {
            throw new functions.https.HttpsError('internal', `Payment processing failed: ${paymentResult.errorMessage}`);
        }
        // Update payout status
        await payoutDoc.ref.update({
            status: paymentResult.status,
            transactionReference: paymentResult.transactionReference || transactionReference || 'manual',
            transactionId: paymentResult.transactionId,
            paymentProvider,
            notes: notes || '',
            completedAt: admin.firestore.FieldValue.serverTimestamp(),
            processedBy: context.auth.uid,
            paymentMetadata: paymentResult.metadata,
        });
        // Mark all commissions as paid
        const batch = db.batch();
        const commissionIds = payoutData?.commissionIds || [];
        for (const commissionId of commissionIds) {
            batch.update(db.collection('commissions').doc(commissionId), {
                status: 'paid',
                paidAt: admin.firestore.FieldValue.serverTimestamp(),
            });
        }
        await batch.commit();
        // Create notification for affiliate
        await db.collection('notifications').add({
            type: 'payout_completed',
            payoutId: payoutId,
            affiliateId: payoutData?.affiliateId,
            targetUserId: payoutData?.affiliateId,
            targetRole: 'affiliate',
            read: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            message: `Your payout of $${payoutData?.amount} has been paid! Transaction ID: ${paymentResult.transactionReference || 'N/A'}`,
            actionUrl: `/affiliate/payouts/${payoutId}`,
        });
        // Log activity
        await db.collection('activity_log').add({
            type: 'payout_processed',
            payoutId,
            affiliateId: payoutData?.affiliateId,
            amount: payoutData?.amount,
            paymentProvider,
            transactionId: paymentResult.transactionId,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            performedBy: context.auth.uid,
        });
        return {
            success: true,
            message: 'Payout processed successfully',
            payoutId,
            amount: payoutData?.amount,
            transactionId: paymentResult.transactionId,
            transactionReference: paymentResult.transactionReference,
        };
    }
    catch (error) {
        console.error('Payout processing error:', error);
        if (error instanceof functions.https.HttpsError) {
            throw error;
        }
        throw new functions.https.HttpsError('internal', 'Payout processing failed');
    }
};
exports.processPayout = processPayout;
/**
 * Cloud Function: Bulk Process Payouts
 *
 * Processes multiple payouts at once
 * Updates payout status to "completed"
 * Marks all related commissions as "paid"
 * Sends confirmation to affiliates
 */
const bulkProcessPayouts = async (data, context) => {
    try {
        if (!context.auth?.token.admin) {
            throw new functions.https.HttpsError('permission-denied', 'Only admins can process payouts');
        }
        const db = admin.firestore();
        const { payoutIds, transactionReference, notes, paymentProvider = 'manual' } = data;
        // Validate input
        if (!payoutIds || !Array.isArray(payoutIds) || payoutIds.length === 0) {
            throw new functions.https.HttpsError('invalid-argument', 'At least one payout ID must be provided');
        }
        if (payoutIds.length > 50) {
            throw new functions.https.HttpsError('invalid-argument', 'Cannot process more than 50 payouts at once');
        }
        console.log(`Bulk processing ${payoutIds.length} payouts with provider: ${paymentProvider}`);
        // Initialize payment service
        const paymentService = (0, paymentService_1.createPaymentService)(db);
        // Fetch all payouts
        const payoutDocs = await Promise.all(payoutIds.map((id) => db.collection('payouts').doc(id).get()));
        const results = [];
        const errors = [];
        let totalAmount = 0;
        // Process each payout
        for (const doc of payoutDocs) {
            if (!doc.exists) {
                errors.push({
                    payoutId: doc.id,
                    error: 'Payout not found',
                });
                continue;
            }
            const payoutData = doc.data();
            if (payoutData?.status === 'completed') {
                errors.push({
                    payoutId: doc.id,
                    error: 'Payout already processed',
                });
                continue;
            }
            try {
                // Process payment using payment service
                const payoutRequestData = {
                    payoutId: doc.id,
                    payoutNumber: payoutData?.payoutNumber || doc.id,
                    amount: payoutData?.amount || 0,
                    currency: payoutData?.currency || 'USD',
                    recipientName: payoutData?.affiliateName || 'Unknown',
                    recipientEmail: payoutData?.affiliateEmail || '',
                    recipientType: 'affiliate',
                    recipientId: payoutData?.affiliateId || '',
                    bankAccountDetails: payoutData?.bankAccountDetails,
                    paymentMethod: payoutData?.paymentMethod || 'bank_transfer',
                    notes,
                };
                const paymentResult = await paymentService.processPayout(payoutRequestData, paymentProvider);
                if (!paymentResult.success) {
                    errors.push({
                        payoutId: doc.id,
                        error: paymentResult.errorMessage || 'Payment processing failed',
                    });
                    continue;
                }
                // Update payout status
                await doc.ref.update({
                    status: paymentResult.status,
                    transactionReference: paymentResult.transactionReference || transactionReference || 'bulk-manual',
                    transactionId: paymentResult.transactionId,
                    paymentProvider,
                    notes: notes || '',
                    completedAt: admin.firestore.FieldValue.serverTimestamp(),
                    processedBy: context.auth.uid,
                    paymentMetadata: paymentResult.metadata,
                });
                // Mark all commissions as paid
                const batch = db.batch();
                const commissionIds = payoutData?.commissionIds || [];
                for (const commissionId of commissionIds) {
                    batch.update(db.collection('commissions').doc(commissionId), {
                        status: 'paid',
                        paidAt: admin.firestore.FieldValue.serverTimestamp(),
                    });
                }
                await batch.commit();
                // Create notification for affiliate
                await db.collection('notifications').add({
                    type: 'payout_completed',
                    payoutId: doc.id,
                    affiliateId: payoutData?.affiliateId,
                    targetUserId: payoutData?.affiliateId,
                    targetRole: 'affiliate',
                    read: false,
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    message: `Your payout of $${payoutData?.amount} has been paid! Transaction ID: ${paymentResult.transactionReference || 'N/A'}`,
                    actionUrl: `/affiliate/payouts/${doc.id}`,
                });
                totalAmount += payoutData?.amount || 0;
                results.push({
                    payoutId: doc.id,
                    affiliateId: payoutData?.affiliateId,
                    amount: payoutData?.amount,
                    status: paymentResult.status,
                    transactionId: paymentResult.transactionId,
                });
            }
            catch (error) {
                console.error(`Error processing payout ${doc.id}:`, error);
                errors.push({
                    payoutId: doc.id,
                    error: error instanceof Error ? error.message : 'Unknown error',
                });
            }
        }
        // Log activity
        await db.collection('activity_log').add({
            type: 'payout_bulk_processed',
            payoutIds,
            totalAmount,
            successCount: results.length,
            errorCount: errors.length,
            paymentProvider,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            performedBy: context.auth.uid,
        });
        return {
            success: true,
            message: `Processed ${results.length} payouts successfully`,
            totalProcessed: results.length,
            totalErrors: errors.length,
            totalAmount,
            results,
            errors,
        };
    }
    catch (error) {
        console.error('Bulk payout processing error:', error);
        if (error instanceof functions.https.HttpsError) {
            throw error;
        }
        throw new functions.https.HttpsError('internal', 'Bulk payout processing failed');
    }
};
exports.bulkProcessPayouts = bulkProcessPayouts;
/**
 * Cloud Function: Export Payouts to CSV
 *
 * Exports payout data to CSV format for download
 * Supports filtering by date range, status, affiliate
 */
const exportPayouts = async (data, context) => {
    try {
        if (!context.auth?.token.admin) {
            throw new functions.https.HttpsError('permission-denied', 'Only admins can export payouts');
        }
        const db = admin.firestore();
        const { startDate, endDate, status, affiliateId, format = 'csv' } = data;
        console.log(`Exporting payouts with filters:`, { startDate, endDate, status, affiliateId });
        // Build query
        let query = db.collection('payouts').orderBy('requestedAt', 'desc');
        // Apply filters
        if (startDate) {
            const startTimestamp = admin.firestore.Timestamp.fromDate(new Date(startDate));
            query = query.where('requestedAt', '>=', startTimestamp);
        }
        if (endDate) {
            const endTimestamp = admin.firestore.Timestamp.fromDate(new Date(endDate));
            query = query.where('requestedAt', '<=', endTimestamp);
        }
        if (status) {
            query = query.where('status', '==', status);
        }
        if (affiliateId) {
            query = query.where('affiliateId', '==', affiliateId);
        }
        // Limit to 1000 records for performance
        const snapshot = await query.limit(1000).get();
        if (snapshot.empty) {
            throw new functions.https.HttpsError('not-found', 'No payouts found matching the criteria');
        }
        // Generate CSV content
        const headers = [
            'Payout Number',
            'Payout ID',
            'Affiliate ID',
            'Affiliate Name',
            'Affiliate Email',
            'Gross Amount',
            'Commission Amount',
            'Tax Amount',
            'Net Amount',
            'Currency',
            'Status',
            'Payment Method',
            'Period Start',
            'Period End',
            'Requested At',
            'Completed At',
            'Transaction Reference',
            'Notes',
            'Commission Count',
        ];
        const rows = snapshot.docs.map((doc) => {
            const data = doc.data();
            const requestedAt = data.requestedAt?.toDate() || new Date();
            const completedAt = data.completedAt?.toDate();
            const periodStart = data.periodStart?.toDate();
            const periodEnd = data.periodEnd?.toDate();
            return [
                data.payoutNumber || '',
                doc.id,
                data.affiliateId || '',
                data.affiliateName || '',
                data.affiliateEmail || '',
                (data.grossAmount || 0).toFixed(2),
                (data.commissionAmount || 0).toFixed(2),
                (data.taxAmount || 0).toFixed(2),
                (data.netAmount || 0).toFixed(2),
                data.currency || 'USD',
                data.status || '',
                data.paymentMethod || '',
                periodStart ? periodStart.toISOString().split('T')[0] : '',
                periodEnd ? periodEnd.toISOString().split('T')[0] : '',
                requestedAt.toISOString(),
                completedAt ? completedAt.toISOString() : '',
                data.transactionReference || '',
                data.notes || '',
                (data.commissionIds || []).length,
            ];
        });
        // Build CSV string
        const csvContent = [
            headers.join(','),
            ...rows.map((row) => row.map((cell) => {
                // Escape quotes and wrap in quotes if contains comma
                const cellStr = String(cell);
                if (cellStr.includes(',') || cellStr.includes('"') || cellStr.includes('\n')) {
                    return `"${cellStr.replace(/"/g, '""')}"`;
                }
                return cellStr;
            }).join(',')),
        ].join('\n');
        // Generate filename
        const now = new Date();
        const dateStr = now.toISOString().split('T')[0];
        const filename = `payouts_export_${dateStr}.csv`;
        return {
            success: true,
            filename,
            contentType: 'text/csv',
            content: csvContent,
            recordCount: snapshot.size,
            message: `Exported ${snapshot.size} payout records`,
        };
    }
    catch (error) {
        console.error('Payout export error:', error);
        if (error instanceof functions.https.HttpsError) {
            throw error;
        }
        throw new functions.https.HttpsError('internal', 'Payout export failed');
    }
};
exports.exportPayouts = exportPayouts;

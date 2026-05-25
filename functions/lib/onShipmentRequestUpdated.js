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
exports.onShipmentRequestUpdated = onShipmentRequestUpdated;
const admin = __importStar(require("firebase-admin"));
// Removed admin.initializeApp() - Firebase Functions auto-initializes firebase-admin
async function onShipmentRequestUpdated(change, context) {
    const before = change.before?.data?.();
    const after = change.after?.data?.();
    // Only handle transition to completed
    if (!before || !after)
        return null;
    if (before.status === 'completed' || after.status !== 'completed')
        return null;
    const affiliateId = after.affiliateId;
    const requestId = context.params.requestId;
    // Create a payout record for the affiliate (amount may be provided on request)
    const payoutAmount = after.payoutAmount ?? after.affiliatePayout ?? 0;
    const payoutDoc = {
        amount: payoutAmount,
        currency: after.currency ?? 'NGN',
        requestId,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    try {
        if (affiliateId) {
            await admin.firestore().collection('affiliates').doc(affiliateId).collection('payouts').add(payoutDoc);
        }
        // Create notification documents for admin and affiliate
        const notifForAdmin = {
            title: 'Shipment request completed',
            body: `Request ${requestId} marked completed by admin`,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            meta: { requestId }
        };
        await admin.firestore().collection('notifications').add(notifForAdmin);
        if (affiliateId) {
            const notifForAffiliate = {
                title: 'Your shipment request was completed',
                body: `Request ${requestId} has been completed and payout created`,
                userId: affiliateId,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                meta: { requestId }
            };
            await admin.firestore().collection('notifications').add(notifForAffiliate);
        }
        // FCM sends (best-effort)
        try {
            const payload = {
                notification: {
                    title: 'Shipment request completed',
                    body: `Request ${requestId} is completed`,
                },
                data: { requestId, type: 'shipment_completed' }
            };
            await admin.messaging().sendToTopic('admins', payload);
            if (affiliateId) {
                await admin.messaging().sendToTopic(`affiliate-${affiliateId}`, payload);
            }
        }
        catch (fcmErr) {
            console.error('FCM send error on update', fcmErr);
        }
        return true;
    }
    catch (err) {
        console.error('Error handling shipmentRequest update', err);
        return null;
    }
}

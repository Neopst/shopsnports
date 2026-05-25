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
exports.onShipmentDelivered = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
/**
 * Cloud Function: Shipment Delivery Notification
 *
 * DEPRECATED: Commission calculation moved to onShippingRequestUpdated
 * This function now only logs delivery events for analytics
 *
 * Triggered when shipping request status changes to "delivered"
 * Logs delivery activity for analytics and reporting
 */
exports.onShipmentDelivered = functions.firestore
    .document('shippingRequests/{requestId}')
    .onUpdate(async (change, context) => {
    const requestId = context.params.requestId;
    const beforeData = change.before.data();
    const afterData = change.after.data();
    if (!beforeData || !afterData) {
        console.error('No data found for shipment update:', requestId);
        return;
    }
    // Check if status changed to "delivered"
    const beforeStatus = beforeData.status;
    const afterStatus = afterData.status;
    if (beforeStatus === afterStatus || afterStatus !== 'delivered') {
        console.log(`Status not changed to delivered for request ${requestId}, skipping`);
        return;
    }
    console.log(`Shipment ${requestId} marked as delivered - logging for analytics`);
    const db = admin.firestore();
    try {
        // Log delivery activity for analytics
        await db.collection('activity_log').add({
            type: 'shipment_delivered',
            requestId: requestId,
            affiliateId: afterData.affiliateId || afterData.affiliate || null,
            freightType: afterData.type || afterData.freightType || 'unknown',
            destination: afterData.destination || afterData.destinationLocation || 'unknown',
            shipmentPrice: afterData.shipmentPrice || afterData.totalPrice || 0,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            performedBy: 'system',
        });
        // Update shipping request with delivery timestamp
        await db.collection('shippingRequests').doc(requestId).update({
            actualDeliveryDate: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log(`✅ Delivery logged for shipment ${requestId}`);
        return { success: true, requestId };
    }
    catch (error) {
        console.error('Error in onShipmentDelivered:', error);
        // Don't throw - logging failure shouldn't fail the shipment update
        return { success: false, error: error.message };
    }
});

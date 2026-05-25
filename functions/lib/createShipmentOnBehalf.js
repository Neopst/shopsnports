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
exports.createShipmentOnBehalf = createShipmentOnBehalf;
const admin = __importStar(require("firebase-admin"));
// Removed admin.initializeApp() - Firebase Functions auto-initializes firebase-admin
async function createShipmentOnBehalf(data, context) {
    const { affiliateId: affiliateIdFromData, client } = data || {};
    if (!client) {
        throw new Error('client required');
    }
    // Prefer deriving affiliateId from auth context to prevent spoofing
    let affiliateId;
    const auth = context.auth;
    if (auth && auth.uid) {
        // Try to find an affiliate doc which lists this uid (simple mapping)
        const maybe = await admin.firestore().collection('affiliates').where('userId', '==', auth.uid).limit(1).get();
        if (!maybe.empty) {
            affiliateId = maybe.docs[0].id;
        }
        // If mapping not found, allow affiliateId to be stored on the affiliate doc keyed by uid
        if (!affiliateId) {
            // fallback: check a dedicated mapping doc
            const mapDoc = await admin.firestore().collection('affiliateMappings').doc(auth.uid).get();
            if (mapDoc.exists) {
                const m = mapDoc.data();
                affiliateId = m?.['affiliateId'];
            }
        }
    }
    // Emulator / fallback: allow passing affiliateId in data if auth is not present
    if (!affiliateId)
        affiliateId = affiliateIdFromData;
    if (!affiliateId) {
        throw new Error('affiliateId not available (authenticated caller required)');
    }
    // Create a shipment request doc with affiliateId attached server-side
    const docRef = await admin.firestore().collection('shippingRequests').add({
        affiliateId,
        client,
        status: 'submitted',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    const shortLink = `https://example.com/shipment-request?id=${docRef.id}`;
    return { id: docRef.id, link: shortLink };
}

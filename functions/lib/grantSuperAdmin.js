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
exports.grantSuperAdmin = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const corsConfig_1 = require("./corsConfig");
const validation_1 = require("./validation");
// Firebase Functions auto-initializes firebase-admin
exports.grantSuperAdmin = functions.https.onRequest(async (req, res) => {
    const corsConfig = (0, corsConfig_1.getCorsConfig)();
    // Handle preflight OPTIONS request
    if ((0, corsConfig_1.handleCorsPreflight)(req, res, corsConfig)) {
        return;
    }
    // Validate CORS for request
    if (!(0, corsConfig_1.validateCorsRequest)(req, res, corsConfig)) {
        return;
    }
    if (req.method !== 'POST') {
        res.status(405).json({ success: false, error: 'Method not allowed' });
        return;
    }
    try {
        // ========== STEP 1: VERIFY CALLER AUTHENTICATION ==========
        const authHeader = req.headers.authorization;
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            res.status(401).json({ success: false, error: 'Unauthorized - no token' });
            return;
        }
        const idToken = authHeader.substring(7);
        let decodedToken;
        try {
            decodedToken = await admin.auth().verifyIdToken(idToken);
        }
        catch (tokenError) {
            res.status(401).json({ success: false, error: 'Invalid token' });
            return;
        }
        const callerId = decodedToken.uid;
        // ========== STEP 2: VERIFY CALLER IS SUPER ADMIN ==========
        const db = admin.firestore();
        const callerDoc = await db.collection('admin_users').doc(callerId).get();
        if (!callerDoc.exists) {
            res.status(403).json({ success: false, error: 'Caller is not an admin' });
            return;
        }
        const callerData = callerDoc.data();
        if (callerData.role !== 'super_admin') {
            res.status(403).json({ success: false, error: 'Only super admins can grant super admin access' });
            return;
        }
        // ========== STEP 3: GET TARGET USER EMAIL ==========
        const { email } = req.body;
        // Validate email
        try {
            (0, validation_1.validateEmail)(email);
        }
        catch (error) {
            if (error instanceof validation_1.ValidationError) {
                res.status(400).json({
                    success: false,
                    error: error.message,
                    field: error.field,
                    code: error.code,
                });
                return;
            }
            res.status(400).json({ success: false, error: 'Invalid email' });
            return;
        }
        const auth = admin.auth();
        const snapshot = await db.collection('admin_users').where('email', '==', email.toLowerCase()).get();
        if (snapshot.empty) {
            res.status(404).json({ success: false, error: 'User not found' });
            return;
        }
        const doc = snapshot.docs[0];
        const uid = doc.id;
        // Update Firestore document
        await doc.ref.update({
            role: 'super_admin',
            isSuperAdmin: true,
            permissions: {
                dashboard: true,
                orders: true,
                shipments: true,
                payouts: true,
                customers: true,
                affiliates: true,
                shippingRequests: true,
                shipments_tracking: true,
                push_notifications: true,
                analytics: true,
                admin_users: true,
                settings: true,
                email_templates: true,
                audit_logs: true,
            }
        });
        // Update Firebase Auth custom claims
        await auth.setCustomUserClaims(uid, {
            admin: true,
            role: 'super_admin',
            dashboard: true,
            orders: true,
            shipments: true,
            payouts: true,
            customers: true,
            affiliates: true,
            shippingRequests: true,
            shipments_tracking: true,
            push_notifications: true,
            analytics: true,
            admin_users: true,
            settings: true,
            email_templates: true,
            audit_logs: true,
        });
        res.status(200).json({ success: true, message: `${email} is now a super_admin with custom claims updated` });
    }
    catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

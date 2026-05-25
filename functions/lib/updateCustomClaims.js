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
exports.updateCustomClaims = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const corsConfig_1 = require("./corsConfig");
// Firebase Functions auto-initializes firebase-admin
exports.updateCustomClaims = functions.https.onRequest(async (req, res) => {
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
            res.status(403).json({ success: false, error: 'Only super admins can modify custom claims' });
            return;
        }
        // ========== STEP 3: UPDATE CUSTOM CLAIMS ==========
        const { uid, role, permissions } = req.body;
        if (!uid) {
            res.status(400).json({ success: false, error: 'UID required' });
            return;
        }
        const claims = {
            admin: true,
            role: role || 'admin',
        };
        if (permissions) {
            Object.entries(permissions).forEach(([key, value]) => {
                if (value === true) {
                    claims[key] = true;
                }
            });
        }
        await admin.auth().setCustomUserClaims(uid, claims);
        // ========== STEP 4: LOG ACTIVITY ==========
        await db.collection('admin_activity_logs').add({
            adminId: callerId,
            adminEmail: callerData.email,
            adminName: callerData.displayName,
            action: 'updated_custom_claims',
            actionType: 'admin_management',
            targetAdminId: uid,
            details: { role: role || 'admin', permissionsChanged: !!permissions },
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            ipAddress: req.ip,
        });
        res.status(200).json({ success: true, message: `Claims updated for ${uid}`, claims });
    }
    catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

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
exports.fixAdminClaims = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
/**
 * Cloud Function: Fix missing admin claims
 *
 * Callable by any authenticated user.
 * If user is in admin_users collection, sets required custom claims.
 * This fixes permission issues when admins don't have custom claims set.
 *
 * Callable Cloud Function
 */
exports.fixAdminClaims = functions.https.onCall(async (data, context) => {
    try {
        // Verify caller is authenticated
        if (!context.auth) {
            throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
        }
        const userId = context.auth.uid;
        const db = admin.firestore();
        const auth = admin.auth();
        console.log(`🔍 Checking admin status for user: ${userId}`);
        // ========== CHECK IF USER IS ADMIN ==========
        const adminDoc = await db.collection('admin_users').doc(userId).get();
        if (!adminDoc.exists) {
            console.log(`❌ User ${userId} is not in admin_users collection`);
            throw new functions.https.HttpsError('permission-denied', 'You are not registered as an admin');
        }
        const adminData = adminDoc.data();
        const email = adminData.email || 'unknown';
        const role = adminData.role || 'admin';
        console.log(`✅ User is admin: ${email} (role: ${role})`);
        // ========== SET CUSTOM CLAIMS ==========
        await auth.setCustomUserClaims(userId, {
            admin: true,
            role: role,
        });
        console.log(`✅ Custom claims set for: ${email}`);
        return {
            success: true,
            message: `Custom claims updated for ${email}. Please refresh the app to see changes.`,
            email: email,
            role: role,
        };
    }
    catch (error) {
        console.error('❌ Error in fixAdminClaims:', error.message);
        if (error.code === 'permission-denied') {
            throw error;
        }
        throw new functions.https.HttpsError('internal', `Failed to fix claims: ${error.message}`);
    }
});

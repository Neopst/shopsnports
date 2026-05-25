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
exports.setCustomClaimsOnSignIn = void 0;
const admin = __importStar(require("firebase-admin"));
// Firebase Functions auto-initializes firebase-admin
/**
 * Cloud Function: Set custom claims when admin user signs in
 * Triggered on first sign-in or token refresh
 * Fetches role from Firestore and sets custom claims
 */
const setCustomClaimsOnSignIn = async (user, context) => {
    const { uid, email } = user;
    const db = admin.firestore();
    const auth = admin.auth();
    console.log(`Processing sign-in for user: ${uid} (${email})`);
    try {
        // Check if user is in admin_users collection
        const adminDoc = await db.collection('admin_users').doc(uid).get();
        if (!adminDoc.exists) {
            // Not an admin, skip custom claims
            console.log(`User ${uid} is not an admin - skipping custom claims`);
            return;
        }
        const adminData = adminDoc.data();
        // Only set claims for active admins
        if (!adminData.isActive || adminData.status === 'disabled') {
            console.log(`Admin ${uid} is disabled - skipping custom claims`);
            return;
        }
        // Build custom claims from Firestore data
        const customClaims = {
            admin: true,
            role: adminData.role || 'admin',
        };
        // Add individual permissions if they exist
        if (adminData.permissions) {
            Object.entries(adminData.permissions).forEach(([key, value]) => {
                if (value === true) {
                    customClaims[key] = true;
                }
            });
        }
        // Set custom claims in Firebase Auth
        await auth.setCustomUserClaims(uid, customClaims);
        console.log(`✅ Set custom claims for admin ${uid}: role=${customClaims.role}`);
        // Update last login in Firestore
        await adminDoc.ref.update({
            lastLogin: admin.firestore.FieldValue.serverTimestamp(),
        });
        // Log activity
        await db.collection('admin_activity_logs').add({
            adminId: uid,
            adminEmail: adminData.email,
            adminName: adminData.displayName,
            action: 'signed_in',
            actionType: 'auth',
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
    }
    catch (error) {
        console.error(`❌ Error setting custom claims for ${uid}:`, error.message);
        // Don't throw - auth sign-in should succeed even if claims fail
    }
};
exports.setCustomClaimsOnSignIn = setCustomClaimsOnSignIn;
/**
 * Cloud Function: Clear custom claims when user is disabled
 * Note: onDisable trigger doesn't exist in Firebase Functions
 * This function is kept for reference but not exported
 */
/*
export const clearCustomClaimsOnDisable = functions.auth.user().onDisable(async (user) => {
  const { uid } = user;
  const db = admin.firestore();
  const auth = admin.auth();

  console.log(`Processing user disable for: ${uid}`);

  try {
    // Clear custom claims
    await auth.setCustomUserClaims(uid, null);

    console.log(`✅ Cleared custom claims for disabled user ${uid}`);

    // Log activity if user is an admin
    const adminDoc = await db.collection('admin_users').doc(uid).get();
    if (adminDoc.exists) {
      const adminData = adminDoc.data()!;
      await db.collection('admin_activity_logs').add({
        adminId: uid,
        adminEmail: adminData.email,
        adminName: adminData.displayName,
        action: 'account_disabled',
        actionType: 'auth',
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Update admin status
      await adminDoc.ref.update({
        isActive: false,
        status: 'disabled',
        disabledAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    return { success: true };

  } catch (error: any) {
    console.error(`❌ Error clearing custom claims for ${uid}:`, error.message);
    return { success: false, error: error.message };
  }
});
*/
// End of commented clearCustomClaimsOnDisable function

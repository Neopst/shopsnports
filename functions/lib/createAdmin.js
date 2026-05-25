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
exports.resetAdminPassword = exports.createAdmin = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const crypto = __importStar(require("crypto"));
const corsConfig_1 = require("./corsConfig");
const validation_1 = require("./validation");
// Firebase Functions auto-initializes firebase-admin
/**
 * Generate a secure random password
 * 16 characters: 4 lowercase + 4 uppercase + 4 digits + 4 special
 */
function generateSecurePassword() {
    const lowercase = 'abcdefghijklmnopqrstuvwxyz';
    const uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const digits = '0123456789';
    const special = '!@#$%^&*';
    const random = (str, n) => {
        const bytes = crypto.randomBytes(n);
        let result = '';
        for (let i = 0; i < n; i++) {
            result += str[bytes[i] % str.length];
        }
        return result;
    };
    return (random(lowercase, 4) +
        random(uppercase, 4) +
        random(digits, 4) +
        random(special, 4));
}
// Use onRequest instead of onCall to avoid Node.js 20 compatibility issue
exports.createAdmin = functions.https.onRequest(async (req, res) => {
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
        // Get ID token from Authorization header
        const authHeader = req.headers.authorization;
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            res.status(401).json({ success: false, error: 'Unauthorized - no token' });
            return;
        }
        const idToken = authHeader.substring(7);
        // Verify the ID token
        let decodedToken;
        try {
            decodedToken = await admin.auth().verifyIdToken(idToken);
        }
        catch (tokenError) {
            console.error('Token verification failed:', tokenError.message);
            res.status(401).json({ success: false, error: 'Invalid token' });
            return;
        }
        const callerId = decodedToken.uid;
        const { email, displayName, permissions } = req.body;
        // Validate inputs using validation module
        try {
            (0, validation_1.validateAdminCreation)({ email, displayName, permissions });
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
            res.status(400).json({ success: false, error: 'Validation failed' });
            return;
        }
        const db = admin.firestore();
        const auth = admin.auth();
        console.log(`🔐 Creating admin account for: ${email}`);
        // ========== STEP 1: VERIFY CALLER IS SUPER ADMIN ==========
        const callerDoc = await db.collection('admin_users').doc(callerId).get();
        if (!callerDoc.exists) {
            res.status(403).json({ success: false, error: 'Caller is not an admin' });
            return;
        }
        const callerData = callerDoc.data();
        if (callerData.role !== 'super_admin') {
            res.status(403).json({ success: false, error: 'Only super admins can create new admins' });
            return;
        }
        console.log(`✅ Verified caller is super admin: ${callerData.displayName}`);
        // ========== STEP 2: RATE LIMITING ==========
        const now = new Date();
        const rateLimitHour = `${now.getFullYear()}${String(now.getMonth() + 1).padStart(2, '0')}${String(now.getDate()).padStart(2, '0')}${String(now.getHours()).padStart(2, '0')}`;
        const rateLimitDocId = `rate_limit:${callerId}:${rateLimitHour}`;
        const rateLimitRef = db.collection('rate_limits').doc(rateLimitDocId);
        const rateLimitDoc = await rateLimitRef.get();
        const currentCount = rateLimitDoc.exists ? (rateLimitDoc.data().count || 0) : 0;
        const MAX_ADMIN_CREATIONS_PER_HOUR = 5;
        if (currentCount >= MAX_ADMIN_CREATIONS_PER_HOUR) {
            res.status(429).json({
                success: false,
                error: `Rate limit exceeded. You can only create ${MAX_ADMIN_CREATIONS_PER_HOUR} admins per hour. Please try again later.`,
                retryAfter: '1 hour',
            });
            return;
        }
        console.log(`✅ Rate limit check passed: ${currentCount}/${MAX_ADMIN_CREATIONS_PER_HOUR} admins created this hour`);
        // ========== STEP 3: CHECK EMAIL NOT ALREADY ADMIN ==========
        const existingAdminQuery = await db
            .collection('admin_users')
            .where('email', '==', email.toLowerCase())
            .limit(1)
            .get();
        if (!existingAdminQuery.empty) {
            res.status(409).json({ success: false, error: 'An admin account already exists with this email' });
            return;
        }
        // ========== STEP 4: CREATE FIREBASE AUTH USER ==========
        const securePassword = generateSecurePassword();
        let newUser;
        try {
            newUser = await auth.createUser({
                email: email.toLowerCase(),
                password: securePassword,
                displayName: displayName,
                disabled: false,
            });
            console.log(`✅ Created Firebase Auth user: ${newUser.uid}`);
        }
        catch (authError) {
            console.error('❌ Auth error:', authError.message);
            if (authError.code === 'auth/email-already-exists') {
                res.status(409).json({ success: false, error: 'Email is already registered in authentication' });
                return;
            }
            res.status(500).json({ success: false, error: `Failed to create auth user: ${authError.message}` });
            return;
        }
        // ========== STEP 5: CREATE FIRESTORE ADMIN_USERS DOCUMENT ==========
        const adminUserDoc = {
            id: newUser.uid,
            email: email.toLowerCase(),
            displayName: displayName,
            role: 'subAdmin',
            status: 'active',
            permissions: permissions,
            createdBy: callerId,
            createdByName: callerData.displayName,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            lastLogin: null,
            requirePasswordChange: true,
            passwordResetCount: 0,
            isActive: true,
            isSuperAdmin: false,
        };
        await db.collection('admin_users').doc(newUser.uid).set(adminUserDoc);
        console.log(`✅ Created Firestore admin document: ${newUser.uid}`);
        // ========== STEP 6: SET CUSTOM CLAIMS FOR AUTH ==========
        await auth.setCustomUserClaims(newUser.uid, {
            admin: true,
            role: 'subAdmin',
        });
        console.log(`✅ Set custom claims for Auth user: ${newUser.uid}`);
        // ========== STEP 7: LOG ACTIVITY ==========
        await db.collection('admin_activity_logs').add({
            adminId: callerId,
            adminEmail: callerData.email,
            adminName: callerData.displayName,
            action: 'created_admin',
            actionType: 'admin_management',
            targetAdminId: newUser.uid,
            targetAdminEmail: email.toLowerCase(),
            targetAdminName: displayName,
            details: {
                permissions: permissions,
                requirePasswordChange: true,
            },
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            ipAddress: req.ip,
            userAgent: req.headers['user-agent'],
        });
        console.log(`✅ Logged activity: admin_created by ${callerData.displayName}`);
        // ========== STEP 8: GENERATE PASSWORD RESET LINK ==========
        let passwordResetLink = '';
        try {
            passwordResetLink = await auth.generatePasswordResetLink(email.toLowerCase(), {
                url: 'https://admin.shopsnports.com/login?reset=true',
            });
            console.log(`✅ Generated password reset link for: ${email}`);
        }
        catch (linkError) {
            console.error('⚠️ Failed to generate reset link:', linkError.message);
            passwordResetLink = `https://admin.shopsnports.com/login?reset=true&email=${encodeURIComponent(email.toLowerCase())}`;
        }
        // ========== STEP 9: SEND WELCOME EMAIL ==========
        try {
            await db.collection('email_queue').add({
                type: 'admin_welcome',
                to: email.toLowerCase(),
                subject: 'ShopsNPorts Admin Account Created',
                adminName: displayName,
                loginUrl: 'https://admin.shopsnports.com/login',
                resetLink: passwordResetLink,
                tempPassword: securePassword,
                role: 'Admin',
                permissionsList: _formatPermissionsList(permissions),
                createdBy: callerData.displayName,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                sent: false,
                retries: 0,
            });
            console.log(`✅ Queued welcome email for: ${email}`);
        }
        catch (emailError) {
            console.error('⚠️ Failed to queue email:', emailError);
        }
        // ========== STEP 10: INCREMENT RATE LIMIT COUNTER ==========
        try {
            await rateLimitRef.set({
                count: currentCount + 1,
                createdBy: callerId,
                period: rateLimitHour,
                lastCreatedAt: admin.firestore.FieldValue.serverTimestamp(),
            }, { merge: true });
            console.log(`✅ Rate limit counter incremented: ${currentCount + 1}/${MAX_ADMIN_CREATIONS_PER_HOUR}`);
        }
        catch (rateLimitError) {
            console.error('⚠️ Failed to update rate limit:', rateLimitError);
        }
        // ========== STEP 11: RETURN SUCCESS ==========
        console.log(`✅ Successfully created admin account: ${email}`);
        res.status(200).json({
            success: true,
            adminId: newUser.uid,
            email: email.toLowerCase(),
            displayName: displayName,
            tempPassword: securePassword,
            requirePasswordChange: true,
            message: 'Admin account created successfully. Password sent via email.',
        });
    }
    catch (error) {
        console.error('❌ Error in createAdmin:', error);
        res.status(500).json({ success: false, error: error.message || 'Internal error' });
    }
});
/**
 * Cloud Function: Reset Admin Password
 */
exports.resetAdminPassword = functions.https.onRequest(async (req, res) => {
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
        const authHeader = req.headers.authorization;
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            res.status(401).json({ success: false, error: 'Unauthorized' });
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
        const { targetAdminId } = req.body;
        if (!targetAdminId) {
            res.status(400).json({ success: false, error: 'targetAdminId is required' });
            return;
        }
        const db = admin.firestore();
        const auth = admin.auth();
        console.log(`🔐 Resetting password for admin: ${targetAdminId}`);
        // Verify caller is super admin
        const callerDoc = await db.collection('admin_users').doc(callerId).get();
        if (!callerDoc.exists || callerDoc.data().role !== 'super_admin') {
            res.status(403).json({ success: false, error: 'Only super admins can reset passwords' });
            return;
        }
        // Get target admin
        const targetAdminDoc = await db.collection('admin_users').doc(targetAdminId).get();
        if (!targetAdminDoc.exists) {
            res.status(404).json({ success: false, error: 'Admin account not found' });
            return;
        }
        const targetAdminData = targetAdminDoc.data();
        if (targetAdminData.role === 'super_admin') {
            res.status(403).json({ success: false, error: 'Cannot reset super admin password' });
            return;
        }
        // Generate new password
        const newPassword = 'TempPass123!';
        await auth.updateUser(targetAdminId, { password: newPassword });
        // Update Firestore
        await targetAdminDoc.ref.update({
            requirePasswordChange: true,
            passwordResetAt: admin.firestore.FieldValue.serverTimestamp(),
            lastResetBy: callerId,
        });
        // Log activity
        await db.collection('admin_activity_logs').add({
            adminId: callerId,
            adminEmail: callerDoc.data().email,
            adminName: callerDoc.data().displayName,
            action: 'reset_admin_password',
            actionType: 'admin_management',
            targetAdminId: targetAdminId,
            targetAdminEmail: targetAdminData.email,
            targetAdminName: targetAdminData.displayName,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
        res.status(200).json({
            success: true,
            adminId: targetAdminId,
            email: targetAdminData.email,
            displayName: targetAdminData.displayName,
            requirePasswordChange: true,
        });
    }
    catch (error) {
        console.error('❌ Error in resetAdminPassword:', error);
        res.status(500).json({ success: false, error: error.message || 'Internal error' });
    }
});
/**
 * Format permissions object into HTML list items
 */
function _formatPermissionsList(permissions) {
    const permissionLabels = {
        dashboard: 'Dashboard',
        orders: 'Orders Management',
        shipments: 'Shipments Management',
        payouts: 'Payouts Management',
        customers: 'Customer Management',
        affiliates: 'Affiliate Management',
        shippingRequests: 'Shipping Requests',
        shipments_tracking: 'Shipment Tracking',
        push_notifications: 'Push Notifications',
        analytics: 'Analytics & Reports',
        admin_users: 'Admin User Management',
        settings: 'System Settings',
        email_templates: 'Email Templates',
        audit_logs: 'Audit Logs',
    };
    const enabledPermissions = Object.entries(permissions)
        .filter(([_, enabled]) => enabled)
        .map(([key]) => `<li>${permissionLabels[key] || key}</li>`);
    return enabledPermissions.join('\n') || '<li>Standard admin access</li>';
}

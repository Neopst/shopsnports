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
exports.updateCustomClaimsFn = exports.grantSuperAdminFn = exports.sendAffiliateEmail = exports.sendEmail = exports.retryFailedEmailsFn = exports.processEmail = exports.notifyShippingUpdateFn = exports.notifyAllAdmins = exports.sendPushNotificationFn = exports.onUserSignIn = exports.affiliateUpdated = exports.affiliateCreated = exports.userCreated = exports.fixAdminAuthClaims = exports.fetchAdminActivityLogs = exports.fetchAdminActivityStats = exports.recordAdminLogout = exports.recordAdminLogin = exports.recordAdminActivity = exports.resetAdminPasswordFn = exports.createNewAdmin = exports.collectMetrics = exports.systemHealthCheck = exports.cleanupRateLimits = exports.cleanupFormShares = exports.checkFormShareAnalytics = exports.processFormShare = exports.createFormShareLink = exports.checkAffiliateToken = exports.adminCreateAffiliateTokens = exports.getAffiliateTokens = exports.createInvoiceHttp = exports.createInvoice = exports.exportPayments = exports.bulkProcessPayments = exports.processPayment = exports.generatePayment = exports.calculateAffiliateCommission = exports.admin = exports.generateScheduledPayouts = exports.shipmentDelivered = exports.shippingRequestUpdated = exports.shippingRequestCreated = void 0;
const functions = __importStar(require("firebase-functions"));
const rateLimiter_1 = require("./rateLimiter");
const monitoring_1 = require("./monitoring");
const onShippingRequestCreated_1 = require("./onShippingRequestCreated");
const onShippingRequestUpdated_1 = require("./onShippingRequestUpdated");
const adminOperations_1 = require("./adminOperations");
const fixAdminClaims_1 = require("./fixAdminClaims");
const grantSuperAdmin_1 = require("./grantSuperAdmin");
const updateCustomClaims_1 = require("./updateCustomClaims");
const calculateCommission_1 = require("./calculateCommission");
const generatePayoutRequest_1 = require("./generatePayoutRequest");
const generateInvoice_1 = require("./generateInvoice");
const generateInvoice_2 = require("./generateInvoice");
const generateAffiliateTokens_1 = require("./generateAffiliateTokens");
const onFormShareTokenUsed_1 = require("./onFormShareTokenUsed");
const createAdmin_1 = require("./createAdmin");
const processEmailQueue_1 = require("./processEmailQueue");
const adminActivityLogger_1 = require("./adminActivityLogger");
const onUserCreated_1 = require("./onUserCreated");
const onAffiliateCreated_1 = require("./onAffiliateCreated");
const onShipmentDelivered_1 = require("./onShipmentDelivered");
const autoGeneratePayouts_1 = require("./autoGeneratePayouts");
const setCustomClaimsOnSignIn_1 = require("./setCustomClaimsOnSignIn");
const sendPushNotification_1 = require("./sendPushNotification");
const sendEmail_1 = require("./sendEmail");
const sendAffiliateEmail_1 = require("./sendAffiliateEmail");
// ========== SHIPPING REQUEST FUNCTIONS ==========
// Trigger for new simplified shipping requests (Firebase-only)
// NOTE: collection name changed to camelCase to match mobile/admin clients
exports.shippingRequestCreated = functions.firestore
    .document('shippingRequests/{requestId}')
    .onCreate(onShippingRequestCreated_1.onShippingRequestCreated);
// Trigger for shipping request updates (status changes, assignments)
// AUTO-GENERATES: Commission, Payout, Invoice when marked as delivered
exports.shippingRequestUpdated = functions.firestore
    .document('shippingRequests/{requestId}')
    .onUpdate(onShippingRequestUpdated_1.onShippingRequestUpdated);
// Auto-calculate commission when shipment is delivered
exports.shipmentDelivered = functions.firestore
    .document('shippingRequests/{requestId}')
    .onUpdate(onShipmentDelivered_1.onShipmentDelivered);
// Auto-generate payouts based on affiliate payout schedule (daily at 2 AM UTC)
exports.generateScheduledPayouts = autoGeneratePayouts_1.autoGeneratePayouts;
// ========== ADMIN OPERATIONS ==========
// Admin operations: assign shipper, update status, tag affiliate, etc.
exports.admin = functions.https.onCall(adminOperations_1.adminOperations);
// ========== COMMISSION & PAYOUT FUNCTIONS ==========
// Calculate commission for affiliate when shipment completed
exports.calculateAffiliateCommission = functions.https.onCall(calculateCommission_1.calculateCommission);
// Generate payout request from commissions (manual process)
exports.generatePayment = functions.https.onCall(generatePayoutRequest_1.generatePayoutRequest);
// Process payout (mark as completed)
exports.processPayment = functions.https.onCall(generatePayoutRequest_1.processPayout);
// Bulk process multiple payouts at once
exports.bulkProcessPayments = functions.https.onCall(generatePayoutRequest_1.bulkProcessPayouts);
// Export payouts to CSV
exports.exportPayments = functions.https.onCall(generatePayoutRequest_1.exportPayouts);
// ========== INVOICE FUNCTIONS ==========
// Generate invoices for shipping requests (can be called manually from admin, or auto-triggered)
// Different logic for affiliate commission invoices vs customer service fee invoices
exports.createInvoice = functions.https.onCall(generateInvoice_1.generateInvoice);
exports.createInvoiceHttp = functions.https.onRequest(generateInvoice_2.generateInvoiceHttp);
// ========== AFFILIATE TOKEN FUNCTIONS ==========
// Affiliate requests new batch of tokens to share with customers
// Format: "SHOP-AFF-2026-12345" for easy tracking and communication
exports.getAffiliateTokens = functions.https.onCall(generateAffiliateTokens_1.generateAffiliateTokens);
// Admin pre-generates tokens for an affiliate and batches
exports.adminCreateAffiliateTokens = functions.https.onCall(generateAffiliateTokens_1.adminGenerateAffiliateTokens);
// Validate affiliate token when creating shipping request
exports.checkAffiliateToken = functions.https.onCall(generateAffiliateTokens_1.validateAffiliateToken);
// ========== FORM SHARE FUNCTIONS ==========
// Affiliate generates shareable form link for clients
// Link token (7-day valid) allows client to pre-fill with affiliate info
exports.createFormShareLink = functions.https.onCall(onFormShareTokenUsed_1.generateFormShareLink);
// Process form submission when client uses form share link
exports.processFormShare = functions.https.onCall(onFormShareTokenUsed_1.onFormShareTokenUsed);
// Get analytics on form shares (sent, used, conversion rate)
exports.checkFormShareAnalytics = functions.https.onCall(onFormShareTokenUsed_1.getFormShareAnalytics);
// Cleanup expired form share links (daily scheduled)
exports.cleanupFormShares = onFormShareTokenUsed_1.cleanupExpiredFormShares;
// Cleanup expired rate limits (daily at 3am)
exports.cleanupRateLimits = functions.pubsub
    .schedule('0 3 * * *')
    .timeZone('UTC')
    .onRun(async () => {
    console.log('Running scheduled cleanup of expired rate limits...');
    try {
        const deleted = await (0, rateLimiter_1.cleanupExpiredRateLimits)();
        console.log(`Cleaned up ${deleted} expired rate limit entries`);
    }
    catch (error) {
        console.error('Error cleaning up rate limits:', error);
    }
    return null;
});
// ========== MONITORING FUNCTIONS ==========
// Health check endpoint
exports.systemHealthCheck = functions.https.onRequest(monitoring_1.healthCheck);
// Hourly metrics collection and alerting
exports.collectMetrics = monitoring_1.metricsCollector;
// ========== ADMIN MANAGEMENT FUNCTIONS ==========
// Super admin creates new sub-admin accounts with secure passwords
exports.createNewAdmin = functions.https.onRequest(createAdmin_1.createAdmin);
// Super admin resets sub-admin password (generates new temporary password)
exports.resetAdminPasswordFn = functions.https.onRequest(createAdmin_1.resetAdminPassword);
// Admin changes password on first login or later password reset
// export const changeAdminPassword = changeAdminPassword; // Disabled - conflicts with import
// ========== ADMIN ACTIVITY LOGGING FUNCTIONS ==========
// Manual activity logging endpoint (can be triggered by any admin action)
exports.recordAdminActivity = functions.https.onCall(adminActivityLogger_1.logAdminActivity);
// Auto-log admin login (call this after successful auth)
exports.recordAdminLogin = functions.https.onCall(adminActivityLogger_1.onAdminLogin);
// Auto-log admin logout (call this when user logs out)
exports.recordAdminLogout = functions.https.onCall(adminActivityLogger_1.onAdminLogout);
// Get activity statistics for an admin (used in dashboard)
exports.fetchAdminActivityStats = functions.https.onCall(adminActivityLogger_1.getAdminActivityStats);
// Get detailed activity logs for an admin (pagination support)
exports.fetchAdminActivityLogs = functions.https.onCall(adminActivityLogger_1.getAdminActivityLogs);
// ========== CLAIM FIXING FUNCTION ==========
// Admins can call this to fix missing custom claims after permission errors
exports.fixAdminAuthClaims = functions.https.onCall(fixAdminClaims_1.fixAdminClaims);
// ========== USER AUTH TRIGGERS ==========
// Trigger when new user registers via Firebase Auth
// Creates user profile and sends welcome email
exports.userCreated = functions.auth.user().onCreate(onUserCreated_1.onUserCreated);
// ========== AFFILIATE TRIGGERS ==========
// Trigger when new affiliate document is created
// Notifies admins of new affiliate applications
exports.affiliateCreated = functions.firestore
    .document('affiliates/{affiliateId}')
    .onCreate(onAffiliateCreated_1.onAffiliateCreated);
// Trigger when affiliate document is updated
// Sends welcome email when approved, rejection email when rejected
exports.affiliateUpdated = functions.firestore
    .document('affiliates/{affiliateId}')
    .onUpdate(onAffiliateCreated_1.onAffiliateUpdated);
// Trigger when user signs in - sets custom claims from Firestore
exports.onUserSignIn = functions.auth.user().beforeSignIn(setCustomClaimsOnSignIn_1.setCustomClaimsOnSignIn);
// Note: onDisable trigger doesn't exist in Firebase Functions
// Custom claims are cleared when account is deleted via onDelete if needed
// export const onUserDisable = functions.auth.user().onDisable(clearCustomClaimsOnDisable);
// ========== PUSH NOTIFICATION FUNCTIONS ==========
// Send push notifications to users, tokens, or topics
exports.sendPushNotificationFn = functions.https.onCall(sendPushNotification_1.sendPushNotification);
// Convenience function to notify all admins
exports.notifyAllAdmins = functions.https.onCall(sendPushNotification_1.notifyAdmins);
// Notify user of shipping status update (called from triggers)
exports.notifyShippingUpdateFn = functions.https.onCall(sendPushNotification_1.notifyShippingUpdate);
// ========== EMAIL QUEUE PROCESSOR ==========
// Process emails from the email queue and send via SMTP
exports.processEmail = functions.firestore
    .document('email_queue/{emailId}')
    .onCreate(processEmailQueue_1.processEmailQueue);
// Retry failed emails periodically
exports.retryFailedEmailsFn = processEmailQueue_1.retryFailedEmails;
// ========== EMAIL CALLABLE FUNCTIONS ==========
// Generic email sending function for Flutter services
exports.sendEmail = sendEmail_1.sendEmail;
// Affiliate email sending function
exports.sendAffiliateEmail = sendAffiliateEmail_1.sendAffiliateEmail;
// ========== TEMP: GRANT SUPER ADMIN ==========
exports.grantSuperAdminFn = functions.https.onRequest(grantSuperAdmin_1.grantSuperAdmin);
// TEMP: Update custom claims
exports.updateCustomClaimsFn = functions.https.onRequest(updateCustomClaims_1.updateCustomClaims);

import * as functions from 'firebase-functions';
import { generateShipmentLink } from './generateShipmentLink';
import { submitShipmentRequest } from './submitShipmentRequest';
import { cleanupExpiredRateLimits } from './rateLimiter';
import { healthCheck, metricsCollector } from './monitoring';
import { onShipmentRequestCreated } from './onShipmentRequestCreated';
import { onShipmentRequestUpdated } from './onShipmentRequestUpdated';
import { createShipmentOnBehalf } from './createShipmentOnBehalf';
import { onShippingRequestCreated } from './onShippingRequestCreated';
import { onShippingRequestUpdated } from './onShippingRequestUpdated';
import { adminOperations } from './adminOperations';
import { fixAdminClaims } from './fixAdminClaims';
import { grantSuperAdmin } from './grantSuperAdmin';
import { updateCustomClaims } from './updateCustomClaims';
import { calculateCommission } from './calculateCommission';
import { generatePayoutRequest, processPayout, bulkProcessPayouts, exportPayouts } from './generatePayoutRequest';
import { generateInvoice } from './generateInvoice';
import { generateInvoiceHttp } from './generateInvoice';
import {
  generateAffiliateTokens,
  adminGenerateAffiliateTokens,
  validateAffiliateToken,
} from './generateAffiliateTokens';
import {
  onFormShareTokenUsed,
  generateFormShareLink,
  cleanupExpiredFormShares,
  getFormShareAnalytics,
} from './onFormShareTokenUsed';
import { createAdmin, resetAdminPassword } from './createAdmin';
import { processEmailQueue, retryFailedEmails } from './processEmailQueue';
import {
  logAdminActivity,
  onAdminLogin,
  onAdminLogout,
  getAdminActivityStats,
  getAdminActivityLogs,
} from './adminActivityLogger';
import { onUserCreated } from './onUserCreated';
import { onAffiliateCreated, onAffiliateUpdated } from './onAffiliateCreated';
import { onShipmentDelivered } from './onShipmentDelivered';
import { autoGeneratePayouts } from './autoGeneratePayouts';
import { getAffiliateAnalytics, getAffiliateLeaderboard } from './affiliateAnalytics';
import { setCustomClaimsOnSignIn } from './setCustomClaimsOnSignIn';
import { sendPushNotification, notifyAdmins, notifyShippingUpdate } from './sendPushNotification';
import { sendEmail as sendEmailCallable } from './sendEmail';
import { sendAffiliateEmail as sendAffiliateEmailCallable } from './sendAffiliateEmail';

// ========== SHIPPING REQUEST FUNCTIONS ==========
// Trigger for new simplified shipping requests (Firebase-only)
// NOTE: collection name changed to camelCase to match mobile/admin clients
export const shippingRequestCreated = functions.firestore
  .document('shippingRequests/{requestId}')
  .onCreate(onShippingRequestCreated);

// Trigger for shipping request updates (status changes, assignments)
// AUTO-GENERATES: Commission, Payout, Invoice when marked as delivered
export const shippingRequestUpdated = functions.firestore
  .document('shippingRequests/{requestId}')
  .onUpdate(onShippingRequestUpdated);

// Auto-calculate commission when shipment is delivered
export const shipmentDelivered = functions.firestore
  .document('shippingRequests/{requestId}')
  .onUpdate(onShipmentDelivered);

// Auto-generate payouts based on affiliate payout schedule (daily at 2 AM UTC)
export const generateScheduledPayouts = autoGeneratePayouts;

// ========== ADMIN OPERATIONS ==========
// Admin operations: assign shipper, update status, tag affiliate, etc.
export const admin = functions.https.onCall(adminOperations);

// ========== COMMISSION & PAYOUT FUNCTIONS ==========
// Calculate commission for affiliate when shipment completed
export const calculateAffiliateCommission = functions.https.onCall(calculateCommission);

// Generate payout request from commissions (manual process)
export const generatePayment = functions.https.onCall(generatePayoutRequest);

// Process payout (mark as completed)
export const processPayment = functions.https.onCall(processPayout);

// Bulk process multiple payouts at once
export const bulkProcessPayments = functions.https.onCall(bulkProcessPayouts);

// Export payouts to CSV
export const exportPayments = functions.https.onCall(exportPayouts);

// ========== INVOICE FUNCTIONS ==========
// Generate invoices for shipping requests (can be called manually from admin, or auto-triggered)
// Different logic for affiliate commission invoices vs customer service fee invoices
export const createInvoice = functions.https.onCall(generateInvoice as any);
export const createInvoiceHttp = functions.https.onRequest(generateInvoiceHttp);

// ========== AFFILIATE TOKEN FUNCTIONS ==========
// Affiliate requests new batch of tokens to share with customers
// Format: "SHOP-AFF-2026-12345" for easy tracking and communication
export const getAffiliateTokens = functions.https.onCall(generateAffiliateTokens as any);

// Admin pre-generates tokens for an affiliate and batches
export const adminCreateAffiliateTokens = functions.https.onCall(
  adminGenerateAffiliateTokens as any
);

// Validate affiliate token when creating shipping request
export const checkAffiliateToken = functions.https.onCall(validateAffiliateToken as any);

// ========== FORM SHARE FUNCTIONS ==========
// Affiliate generates shareable form link for clients
// Link token (7-day valid) allows client to pre-fill with affiliate info
export const createFormShareLink = functions.https.onCall(generateFormShareLink as any);

// Process form submission when client uses form share link
export const processFormShare = functions.https.onCall(onFormShareTokenUsed as any);

// Get analytics on form shares (sent, used, conversion rate)
export const checkFormShareAnalytics = functions.https.onCall(getFormShareAnalytics as any);

// Cleanup expired form share links (daily scheduled)
export const cleanupFormShares = cleanupExpiredFormShares;

// Cleanup expired rate limits (daily at 3am)
export const cleanupRateLimits = functions.pubsub
  .schedule('0 3 * * *')
  .timeZone('UTC')
  .onRun(async () => {
    console.log('Running scheduled cleanup of expired rate limits...');
    try {
      const deleted = await cleanupExpiredRateLimits();
      console.log(`Cleaned up ${deleted} expired rate limit entries`);
    } catch (error) {
      console.error('Error cleaning up rate limits:', error);
    }
    return null;
  });

// ========== MONITORING FUNCTIONS ==========
// Health check endpoint
export const systemHealthCheck = functions.https.onRequest(healthCheck);

// Hourly metrics collection and alerting
export const collectMetrics = metricsCollector;

// ========== ADMIN MANAGEMENT FUNCTIONS ==========
// Super admin creates new sub-admin accounts with secure passwords
export const createNewAdmin = functions.https.onRequest(createAdmin);

// Super admin resets sub-admin password (generates new temporary password)
export const resetAdminPasswordFn = functions.https.onRequest(resetAdminPassword);

// Admin changes password on first login or later password reset
// export const changeAdminPassword = changeAdminPassword; // Disabled - conflicts with import

// ========== ADMIN ACTIVITY LOGGING FUNCTIONS ==========
// Manual activity logging endpoint (can be triggered by any admin action)
export const recordAdminActivity = functions.https.onCall(logAdminActivity as any);

// Auto-log admin login (call this after successful auth)
export const recordAdminLogin = functions.https.onCall(onAdminLogin as any);

// Auto-log admin logout (call this when user logs out)
export const recordAdminLogout = functions.https.onCall(onAdminLogout as any);

// Get activity statistics for an admin (used in dashboard)
export const fetchAdminActivityStats = functions.https.onCall(getAdminActivityStats as any);

// Get detailed activity logs for an admin (pagination support)
export const fetchAdminActivityLogs = functions.https.onCall(getAdminActivityLogs as any);

// ========== CLAIM FIXING FUNCTION ==========
// Admins can call this to fix missing custom claims after permission errors
export const fixAdminAuthClaims = functions.https.onCall(fixAdminClaims as any);

// ========== USER AUTH TRIGGERS ==========
// Trigger when new user registers via Firebase Auth
// Creates user profile and sends welcome email
export const userCreated = functions.auth.user().onCreate(onUserCreated);

// ========== AFFILIATE TRIGGERS ==========
// Trigger when new affiliate document is created
// Notifies admins of new affiliate applications
export const affiliateCreated = functions.firestore
  .document('affiliates/{affiliateId}')
  .onCreate(onAffiliateCreated);

// Trigger when affiliate document is updated
// Sends welcome email when approved, rejection email when rejected
export const affiliateUpdated = functions.firestore
  .document('affiliates/{affiliateId}')
  .onUpdate(onAffiliateUpdated);

// Trigger when user signs in - sets custom claims from Firestore
export const onUserSignIn = functions.auth.user().beforeSignIn(setCustomClaimsOnSignIn);

// Note: onDisable trigger doesn't exist in Firebase Functions
// Custom claims are cleared when account is deleted via onDelete if needed
// export const onUserDisable = functions.auth.user().onDisable(clearCustomClaimsOnDisable);

// ========== PUSH NOTIFICATION FUNCTIONS ==========
// Send push notifications to users, tokens, or topics
export const sendPushNotificationFn = functions.https.onCall(sendPushNotification as any);

// Convenience function to notify all admins
export const notifyAllAdmins = functions.https.onCall(notifyAdmins as any);

// Notify user of shipping status update (called from triggers)
export const notifyShippingUpdateFn = functions.https.onCall(notifyShippingUpdate as any);

// ========== EMAIL QUEUE PROCESSOR ==========
// Process emails from the email queue and send via SMTP
export const processEmail = functions.firestore
  .document('email_queue/{emailId}')
  .onCreate(processEmailQueue);

// Retry failed emails periodically
export const retryFailedEmailsFn = retryFailedEmails;

// ========== EMAIL CALLABLE FUNCTIONS ==========
// Generic email sending function for Flutter services
export const sendEmail = sendEmailCallable;

// Affiliate email sending function
export const sendAffiliateEmail = sendAffiliateEmailCallable;

// ========== TEMP: GRANT SUPER ADMIN ==========
export const grantSuperAdminFn = functions.https.onRequest(grantSuperAdmin);

// TEMP: Update custom claims
export const updateCustomClaimsFn = functions.https.onRequest(updateCustomClaims);

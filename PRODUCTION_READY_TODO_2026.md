# 🎯 PRODUCTION READY TODO LIST - SHOPSNPORTS

**Project:** ShopsNPorts Mobile + Admin Dashboard  
**Current Status:** 45% Production Ready  
**Target:** 100% Production Ready by February 28, 2026  
**Estimated Effort:** 109 hours (8-9 business days)  
**Team:** 1 Flutter Dev (full-time) + 1 Backend Engineer (4-5 days) + 1 QA Engineer (3-4 days)

---

## 📊 ROADMAP AT A GLANCE

```
Phase 0 (Day 1)      → Firebase Foundations [8h]        ✓ CRITICAL PATH
Phase 1 (Days 2-3)   → Payments & Backend [35h]         ✓ REVENUE CRITICAL
Phase 2 (Days 4-5)   → Error Handling [16h]             ✓ USER EXPERIENCE
Phase 3 (Days 6-7)   → Testing & Monitoring [38h]       ✓ QUALITY GATES
Phase 4 (Day 8)      → Production Deployment [12h]      ✓ GO LIVE
```

---

# PHASE 0: FIREBASE FOUNDATIONS (Day 1 - 8 Hours)
## Status: ⏳ NOT STARTED

These tasks MUST complete before moving to Phase 1. They are blockers for everything else.

### ✓ TASK 0.1: Deploy Firestore Security Rules (2 hours)
**Severity:** 🔴 CRITICAL  
**Blocks:** Everything (data access depends on this)  
**Owner:** Flutter Dev + DevOps  

**Current State:**
- Rules file exists: [firestore.rules](firestore.rules)
- Status: Example rules only, NOT deployed
- Risk: Without rules, data is unprotected in production

**Action Items:**
- [ ] **0.1.1** Review firestore.rules for completeness
  - Verify all collections have rules defined
  - Check admin-only collections are protected
  - Ensure user-specific data isolation
  - File: [firestore.rules](firestore.rules) - Lines 1-150

- [ ] **0.1.2** Test rules in Firebase Emulator
  ```bash
  firebase emulators:start --import=./firestore-export
  ```
  - Test admin write access
  - Test user read-only access
  - Test shipping request creation by guest
  - Test cross-user data isolation

- [ ] **0.1.3** Deploy to Firebase Production
  ```bash
  firebase deploy --only firestore:rules
  ```
  - Verify deployment successful
  - Check Firebase Console rules are updated

**Acceptance Criteria:**
- ✅ Rules deployed to Firebase Console
- ✅ No data access without authentication (except public collections)
- ✅ Admins can read/write all collections
- ✅ Users can only access their own data
- ✅ Guests can create shipping requests but not read others

**Testing Checklist:**
- [ ] Admin reads affiliates collection → Success
- [ ] User reads another user's data → Denied
- [ ] Guest creates shipping request → Success (if rules allow)
- [ ] Guest reads shipping requests → Limited to own requests
- [ ] Cloud Functions can write to collections → Success

---

### ✓ TASK 0.2: Create Missing Firestore Collections (3 hours)
**Severity:** 🔴 CRITICAL  
**Blocks:** Mobile app features, Admin reporting  
**Owner:** Flutter Dev

**Current State:**
- Collections created: affiliates, shippingRequests, banners, news_ticker, users
- Collections missing: notifications, announcements, customers, commissions, payouts, invoices, content_pages

**Action Items:**
- [ ] **0.2.1** Create `notifications` collection
  - Document schema: { id, userId, title, body, type, read, createdAt, actionUrl }
  - Seed 5 test notifications
  - Set up index for userId + createdAt

- [ ] **0.2.2** Create `customers` collection
  - Document schema: { id, userId, name, email, phone, tier, totalShipments, createdAt }
  - Seed 10 test customers
  - Index for userId

- [ ] **0.2.3** Create `orders` collection
  - Document schema: { id, customerId, items[], total, status, createdAt }
  - Seed 5 test orders
  - Index for customerId + status

- [ ] **0.2.4** Create `commissions` collection
  - Document schema: { id, affiliateId, shipmentId, amount, status, createdAt }
  - Seed 3 test records
  - Index for affiliateId + status

- [ ] **0.2.5** Create `payouts` collection
  - Document schema: { id, affiliateId, amount, status, createdAt }
  - Seed 2 test payouts
  - Index for affiliateId + status

- [ ] **0.2.6** Create `invoices` collection
  - Document schema: { id, customerId, items[], total, status, issueDate, dueDate }
  - Seed 2 test invoices
  - Index for customerId + status

- [ ] **0.2.7** Create `announcements` collection
  - Document schema: { id, title, body, type, priority, visible, createdAt }
  - Seed 3 emergency announcements
  - Index for priority

- [ ] **0.2.8** Create `content_pages` collection
  - Document schema: { id, slug, title, body, published, createdAt, updatedAt }
  - Seed: Terms of Service, Privacy Policy, About
  - Index for slug + published

**Acceptance Criteria:**
- ✅ All 8 collections exist in Firestore Console
- ✅ Each collection has test data
- ✅ Schemas match mobile app models
- ✅ Indexes created for common queries
- ✅ Android app can read all collections

**Verification:**
```bash
# In Firebase Console:
# 1. Click "Firestore Database"
# 2. Verify collections: notifications, customers, orders, commissions, payouts, invoices, announcements, content_pages
# 3. Each has 2-10 documents
```

---

### ✓ TASK 0.3: Deploy Firestore Indexes (1 hour)
**Severity:** 🟡 HIGH  
**Blocks:** Admin filtering & searching  
**Owner:** DevOps

**Current State:**
- Index file: [firestore.indexes.json](firestore.indexes.json)
- Status: Defined but not deployed

**Action Items:**
- [ ] **0.3.1** Review indexes in firestore.indexes.json
  - Verify indexes for common queries
  - Examples: affiliates by status, shipping by type, etc.

- [ ] **0.3.2** Deploy indexes
  ```bash
  firebase deploy --only firestore:indexes
  ```
  - Wait for "✓ firestore:indexes completed successfully"
  - Verify in Firebase Console under "Indexes" tab

**Acceptance Criteria:**
- ✅ Indexes deployed successfully
- ✅ Visible in Firebase Console
- ✅ Admin filtering queries perform well (< 200ms)

---

### ✓ TASK 0.4: Verify Admin ↔ Mobile Firestore Sync (2 hours)
**Severity:** 🔴 CRITICAL  
**Blocks:** Core functionality verification  
**Owner:** Flutter Dev (both apps)

**Current State:**
- Shipping request sync: Likely working but untested
- Status update sync: Untested
- Payment sync: Not implemented
- Notification sync: Not tested

**Action Items:**
- [ ] **0.4.1** Test Mobile → Admin Sync (Shipping Request)
  ```
  1. Open admin app, navigate to [Shipping Requests](admin/lib/features/dashboard/presentation/shipping_request_screen.dart)
  2. Open mobile app, submit new shipping request via [Request Shipping Screen](lib/screens/request_shipping_screen.dart)
  3. Verify: Immediately appears in admin shipping list (real-time)
  4. Document: Response time, data accuracy
  ```

- [ ] **0.4.2** Test Admin → Mobile Sync (Status Update)
  ```
  1. In admin app, find a shipping request
  2. Change status: pending → assigned
  3. Open mobile app, go to active shipments
  4. Verify: Status updated in real-time
  5. Document: Notification received?
  ```

- [ ] **0.4.3** Test Affiliate → Admin Sync
  ```
  1. Verify admin sees all affiliates from [affiliate_repository_firestore.dart](admin/lib/features/affiliates/data/affiliate_repository_firestore.dart)
  2. Verify mobile affiliate dashboard shows own data
  3. Document: Data consistency
  ```

- [ ] **0.4.4** Test Real-Time Listeners
  ```
  1. Open admin shipping screen in two browser tabs
  2. Submit request from mobile
  3. Verify: Both tabs show update in < 2 seconds
  4. Measure: Database latency
  ```

**Acceptance Criteria:**
- ✅ Mobile → Admin sync works in < 2 seconds
- ✅ Admin → Mobile sync works in < 2 seconds
- ✅ Data accuracy verified (no corruption)
- ✅ Real-time listeners active
- ✅ No errors in browser console

**Expected Results Document:**
- Create [SYNC_TEST_RESULTS_PHASE_0.md](SYNC_TEST_RESULTS_PHASE_0.md)
  ```markdown
  # Sync Test Results
  
  ## Mobile → Admin (Shipping Request)
  - Time to appear: 1.2 seconds
  - Data accurate: Yes
  - Real-time listener: Working
  
  ## Admin → Mobile (Status Update)
  - Time to update: 1.8 seconds
  - Push notification: Received
  - Data accurate: Yes
  ```

**Blocker? If NO to any requirement:** Cannot proceed to Phase 1

---

## 🎯 PHASE 0 SUMMARY

| Task | Hours | Severity | Status |
|------|-------|----------|--------|
| Deploy Firestore Rules | 2 | CRITICAL | ⏳ TODO |
| Create Missing Collections | 3 | CRITICAL | ⏳ TODO |
| Deploy Firestore Indexes | 1 | HIGH | ⏳ TODO |
| Verify Admin-Mobile Sync | 2 | CRITICAL | ⏳ TODO |
| **TOTAL** | **8** | **CRITICAL** | **⏳ TODO** |

**GO/NO-GO Decision:** If Phase 0 tasks not 100% complete, DO NOT start Phase 1

---

---

# PHASE 1: PAYMENTS & BACKEND (Days 2-3 - 35 Hours)
## Status: ⏳ BLOCKED (Waiting for Phase 0)

Critical business functionality: Revenue generation and order processing.

### ✓ TASK 1.1: Complete Payment Integration (20 hours)
**Severity:** 🔴 CRITICAL  
**Blocks:** Revenue generation  
**Owner:** Flutter Dev + Backend Engineer  

**Current State:**
- Stripe SDK: ✅ Integrated
- Flutterwave SDK: ✅ Integrated
- Paystack SDK: ✅ Integrated
- Flow completeness: ⚠️ 30% (incomplete payment verification, no transaction logging)
- Webhook handling: ❌ Not implemented

**Files Involved:**
- [lib/core/config/payment_config.dart](lib/core/config/payment_config.dart)
- [lib/screens/payment_billing_screen.dart](lib/screens/payment_billing_screen.dart)
- [lib/services/payment_service.dart](lib/services/payment_service.dart) (if exists)
- functions/src/ (Cloud Functions for webhooks)

**Action Items:**
- [ ] **1.1.1** Implement Complete Payment Flow with Stripe (8 hours)
  - User enters amount
  - System calculates fees
  - User can choose payment method
  - Payment processed via Stripe API
  - Transaction saved to Firestore `transactions` collection
  - Receipt sent to user
  - Success screen with confirmation number
  
  **Acceptance Criteria:**
  - ✅ Test payment with Stripe test card
  - ✅ Transaction appears in Firestore
  - ✅ Receipt generated
  - ✅ Success screen shown
  - ✅ Failure handling (declined card) works

- [ ] **1.1.2** Implement Complete Payment Flow with Flutterwave (6 hours)
  - Same process as Stripe
  - OTP verification if required
  - Webhook callback handling
  
  **Acceptance Criteria:**
  - ✅ Test payment with Flutterwave sandbox
  - ✅ Transaction saved to Firestore
  - ✅ OTP flow works
  - ✅ Webhook callback processes correctly

- [ ] **1.1.3** Implement Complete Payment Flow with Paystack (4 hours)
  - Same process as Flutterwave
  - Verify payment status before confirming
  
  **Acceptance Criteria:**
  - ✅ Test payment with Paystack test account
  - ✅ Payment verification succeeds
  - ✅ Transaction logged

- [ ] **1.1.4** Create Payment Verification Service (2 hours)
  ```dart
  // lib/services/payment_verification_service.dart
  class PaymentVerificationService {
    Future<bool> verifyStripePayment(String paymentIntentId);
    Future<bool> verifyFlutterwave(String transactionReference);
    Future<bool> verifyPaystack(String reference);
  }
  ```
  
  **Acceptance Criteria:**
  - ✅ Service verifies payment with provider's API
  - ✅ Returns accurate status

- [ ] **1.1.5** Create Transaction Logging Service (1 hour)
  ```dart
  // lib/services/transaction_logging_service.dart
  class TransactionLoggingService {
    Future<void> logTransaction(PaymentTransaction transaction);
    Future<List<PaymentTransaction>> getTransactionHistory(String userId);
  }
  ```
  
  Create Firestore collection: `transactions`
  Schema:
  ```json
  {
    "id": "tx_123",
    "userId": "user_456",
    "amount": 1000,
    "currency": "NGN",
    "provider": "stripe|flutterwave|paystack",
    "externalId": "external_ref_123",
    "status": "success|failed|pending",
    "createdAt": "2026-02-19T10:00:00Z",
    "metadata": { "shipmentId": "ship_123" }
  }
  ```

- [ ] **1.1.6** Create Refund Handler (2 hours)
  ```dart
  // lib/services/refund_service.dart
  class RefundService {
    Future<bool> requestRefund(String transactionId, String reason);
    Future<RefundStatus> checkRefundStatus(String refundId);
  }
  ```
  
  **Acceptance Criteria:**
  - ✅ Can request refund via UI
  - ✅ Notification sent to user
  - ✅ Admin notified
  - ✅ Status trackable

- [ ] **1.1.7** Create Backend Webhook Handler (2 hours)
  - File: `functions/src/onPaymentWebhook.ts`
  - Handles webhooks from: Stripe, Flutterwave, Paystack
  - Verifies webhook signature
  - Updates transaction status
  - Triggers order fulfillment if applicable
  - Sends user notification

**Integration Test Checklist:**
- [ ] User can select payment method
- [ ] Cart total correctly calculated
- [ ] Fees applied correctly
- [ ] Payment processed successfully
- [ ] Transaction logged to Firestore
- [ ] Receipt generated
- [ ] User notification sent
- [ ] Admin sees transaction

**Payment Test Cases:**
```
1. Successful payment with valid card ✓
2. Failed payment with invalid card ✓
3. Payment with insufficient funds ✓
4. Timeout handling ✓
5. Duplicate transaction prevention ✓
6. Currency conversion (if applicable) ✓
7. Multi-currency support ✓
```

---

### ✓ TASK 1.2: Move Secrets to Environment Variables (3 hours)
**Severity:** 🟡 HIGH  
**Blocks:** Production deployment  
**Owner:** DevOps + Backend Engineer

**Current State:**
- Payment API keys: Hardcoded in [payment_config.dart](lib/core/config/payment_config.dart)
- Firebase config: Partially hardcoded
- Stripe public key: May be in code
- Risk: Secrets exposed in git history

**Action Items:**
- [ ] **1.2.1** Create .env files for all environments
  ```
  .env.development
  .env.staging
  .env.production
  ```
  
  Content for each:
  ```
  STRIPE_PUBLIC_KEY=pk_test_...
  STRIPE_SECRET_KEY=sk_test_...
  FLUTTERWAVE_PUBLIC_KEY=...
  FLUTTERWAVE_SECRET_KEY=...
  PAYSTACK_PUBLIC_KEY=...
  PAYSTACK_SECRET_KEY=...
  FIREBASE_API_KEY=...
  APP_ID=...
  ```

- [ ] **1.2.2** Remove hardcoded secrets from code
  - Remove from: [payment_config.dart](lib/core/config/payment_config.dart)
  - Remove from: [firebase_options.dart](lib/firebase_options.dart) (if applicable)
  - Verify: No secrets in git history
  - Use `.gitignore` to prevent accidental commits

- [ ] **1.2.3** Implement Environment Configuration Loading
  ```dart
  // lib/core/config/environment_config.dart
  class EnvironmentConfig {
    static String get stripePublicKey => _getValue('STRIPE_PUBLIC_KEY');
    static String get flutterwave => _getValue('FLUTTERWAVE_PUBLIC_KEY');
    // ... other keys
    
    static String _getValue(String key) {
      // Load from env, Remote Config, or default
    }
  }
  ```

- [ ] **1.2.4** Update Payment Config to Use Environment
  ```dart
  // Update lib/core/config/payment_config.dart
  class PaymentConfig {
    static final String stripePublicKey = EnvironmentConfig.stripePublicKey;
    // Use from env instead of hardcoded
  }
  ```

- [ ] **1.2.5** Setup Firebase Remote Config (Optional but Recommended)
  - Create Firebase Remote Config for feature flags
  - Setup: Payment provider enablement per environment
  - Benefits: Can toggle providers without app update

**Acceptance Criteria:**
- ✅ No secrets in code
- ✅ No secrets in git history
- ✅ Environment-specific config works
- ✅ Production keys are secure
- ✅ Developers can use test keys locally

---

### ✓ TASK 1.3: Deploy Cloud Functions (12 hours)
**Severity:** 🟡 HIGH  
**Blocks:** Payment webhooks, notifications  
**Owner:** Backend Engineer

**Current State:**
- Functions directory: functions/src/
- Status: Partially implemented (Phase 13-14 deliverables)
- Deployed: ❌ Not yet

**Existing Functions (From Phase 13-14):**
- ✅ onShippingRequestCreated.ts - Notifications on new request
- ✅ onShippingRequestUpdated.ts - Notifications on status change
- ✅ adminOperations.ts - Admin functions

**New Functions Needed for Payment:**
- ❌ onPaymentWebhook.ts - Handle payment callbacks
- ❌ onTransactionCreated.ts - Log and notify on transaction
- ❌ processAffiliateCommission.ts - Calculate & store commission
- ❌ onRefundRequested.ts - Handle refund requests
- ❌ sendWeeklyPayoutReminder.ts - Scheduled function

**Action Items:**
- [ ] **1.3.1** Create Payment Webhook Handler (3 hours)
  ```typescript
  // functions/src/onPaymentWebhook.ts
  exports.onPaymentWebhook = functions.https.onRequest(async (req, res) => {
    // 1. Verify webhook signature
    // 2. Parse event type (payment.success, payment.failed, etc.)
    // 3. Update transaction status in Firestore
    // 4. Create commission record if applicable
    // 5. Send notifications
    // 6. Return 200 OK
  });
  ```
  
  **Acceptance Criteria:**
  - ✅ Verifies webhook signature
  - ✅ Updates transaction status
  - ✅ Handles all event types
  - ✅ Error handling & logging
  - ✅ Idempotent (safe to call multiple times)

- [ ] **1.3.2** Create Transaction Logger Function (2 hours)
  ```typescript
  // functions/src/onTransactionCreated.ts
  exports.onTransactionCreated = functions.firestore
    .document('transactions/{transactionId}')
    .onCreate(async (snap) => {
      // 1. Get transaction data
      // 2. Send receipt email
      // 3. Create admin notification
      // 4. Update user balance
      // 5. Log to analytics
    });
  ```

- [ ] **1.3.3** Create Affiliate Commission Calculator (3 hours)
  ```typescript
  // functions/src/processAffiliateCommission.ts
  exports.processAffiliateCommission = functions.firestore
    .document('shippingRequests/{requestId}')
    .onUpdate(async (change) => {
      if (change.after.get('status') === 'completed') {
        // 1. Get shipper affiliate ID
        // 2. Calculate commission (amount * rate)
        // 3. Create commission record
        // 4. Notify affiliate
      }
    });
  ```

- [ ] **1.3.4** Create Refund Handler (2 hours)
  ```typescript
  // functions/src/onRefundRequested.ts
  exports.onRefundRequested = functions.firestore
    .document('refunds/{refundId}')
    .onCreate(async (snap) => {
      // 1. Verify transaction can be refunded
      // 2. Call payment provider refund API
      // 3. Update transaction status
      // 4. Notify user & admin
    });
  ```

- [ ] **1.3.5** Create Scheduled Payout Reminder (1 hour)
  ```typescript
  // functions/src/weeklyPayoutReminder.ts
  exports.weeklyPayoutReminder = functions.pubsub
    .schedule('every monday 09:00')
    .onRun(async (context) => {
      // 1. Find affiliates with pending payouts
      // 2. Send reminder email
      // 3. Send in-app notification
    });
  ```

- [ ] **1.3.6** Update functions/src/index.ts Exports
  ```typescript
  // Export all functions
  export { onShippingRequestCreated } from './onShippingRequestCreated';
  export { onShippingRequestUpdated } from './onShippingRequestUpdated';
  export { adminOperations } from './adminOperations';
  export { onPaymentWebhook } from './onPaymentWebhook'; // NEW
  export { onTransactionCreated } from './onTransactionCreated'; // NEW
  export { processAffiliateCommission } from './processAffiliateCommission'; // NEW
  export { onRefundRequested } from './onRefundRequested'; // NEW
  export { weeklyPayoutReminder } from './weeklyPayoutReminder'; // NEW
  ```

- [ ] **1.3.7** Test Cloud Functions Locally (1 hour)
  ```bash
  cd functions
  npm run build
  firebase emulators:start --import=./firestore-export
  ```
  - Test each function endpoint
  - Verify Firestore updates
  - Check error handling

- [ ] **1.3.8** Deploy to Firebase Production (1 hour)
  ```bash
  firebase deploy --only functions
  ```
  - Monitor deployment
  - Verify in Firebase Console

**Acceptance Criteria:**
- ✅ All functions deploy successfully
- ✅ Functions execute without errors
- ✅ Firestore data updated correctly
- ✅ Notifications sent on trigger
- ✅ Logs visible in Cloud Functions UI
- ✅ No cold start issues after first run

---

## 🎯 PHASE 1 SUMMARY

| Task | Hours | Severity | Status |
|------|-------|----------|--------|
| Complete Payment Integration | 20 | CRITICAL | ⏳ TODO |
| Move Secrets to Env Vars | 3 | HIGH | ⏳ TODO |
| Deploy Cloud Functions | 12 | HIGH | ⏳ TODO |
| **TOTAL** | **35** | **HIGH** | **⏳ TODO** |

**Prerequisite:** Phase 0 must be 100% complete  
**Go-Live Requirement:** Payment integration full test passed

---

---

# PHASE 2: ERROR HANDLING & VALIDATION (Days 4-5 - 16 Hours)
## Status: ⏳ BLOCKED (Waiting for Phase 0)

Focus: User experience and system reliability.

### ✓ TASK 2.1: Implement Comprehensive Input Validation (6 hours)
**Severity:** 🟡 HIGH  
**Blocks:** Production release (security requirement)  
**Owner:** Flutter Dev

**Current State:**
- Some forms have validation ✅
- Some forms lack validation ❌
- No cross-field validation
- No async validation (checking if email exists, etc.)

**Forms Needing Validation:**
1. Registration form
2. Login form
3. Shipping request form
4. Payment billing form
5. Affiliate settings form
6. User profile form

**Action Items:**
- [ ] **2.1.1** Create Form Validator Service (1 hour)
  ```dart
  // lib/services/form_validator_service.dart
  class FormValidator {
    // Email validation
    static String? validateEmail(String? value);
    
    // Password validation (min 8 chars, number, special char)
    static String? validatePassword(String? value);
    
    // Phone validation
    static String? validatePhone(String? value);
    
    // Min/max length
    static String? validateLength(String? value, int min, int max);
    
    // Custom patterns (international phone, postal code, etc.)
    static String? validatePattern(String? value, String pattern);
    
    // Async validators
    static Future<String?> validateEmailUnique(String email);
    static Future<String?> validatePhoneUnique(String phone);
  }
  ```

- [ ] **2.1.2** Add Validation to Registration Form (1 hour)
  - File: lib/screens/auth/register_screen.dart
  - Validate: Email, Password, Phone, Name
  - Show inline error messages
  - Disable submit until all valid

- [ ] **2.1.3** Add Validation to Login Form (0.5 hours)
  - File: lib/screens/auth/login_screen.dart
  - Validate: Email, Password
  - Show helpful error messages

- [ ] **2.1.4** Add Validation to Shipping Request Form (2 hours)
  - File: [lib/screens/request_shipping_screen.dart](lib/screens/request_shipping_screen.dart#L1-L100)
  - Validate: Origin, Destination, Weight, Email
  - Validate: Document formats (if file upload)
  - Show field-level errors

- [ ] **2.1.5** Add Validation to Payment Form (0.5 hours)
  - File: [lib/screens/payment_billing_screen.dart](lib/screens/payment_billing_screen.dart)
  - Validate: Card number, Expiry, CVV
  - Validate: Billing address
  - Server-side validation before processing

- [ ] **2.1.6** Add Validation to User Forms (1 hour)
  - Profile editing form
  - Address management form
  - Settings form

**Acceptance Criteria:**
- ✅ All forms validate inputs
- ✅ Invalid inputs show error messages
- ✅ Invalid inputs prevent submission
- ✅ Async validators check uniqueness
- ✅ Security validation (XSS prevention, SQL injection)

---

### ✓ TASK 2.2: Implement Error Recovery & Retry Logic (8 hours)
**Severity:** 🟡 HIGH  
**Blocks:** Production stability  
**Owner:** Flutter Dev

**Current State:**
- Basic error handling exists ✅
- Retry logic: ⚠️ Minimal
- Exponential backoff: ❌ Not implemented
- Network error recovery: ⚠️ Partial

**Action Items:**
- [ ] **2.2.1** Create Retry Service with Exponential Backoff (2 hours)
  ```dart
  // lib/services/retry_service.dart
  class RetryService {
    Future<T> executeWithRetry<T>(
      Future<T> Function() operation, {
      int maxRetries = 3,
      Duration initialDelay = const Duration(milliseconds: 100),
      double backoffMultiplier = 2.0,
    });
    
    // Usage:
    // final data = await retryService.executeWithRetry(() => apiService.fetchData());
  }
  ```
  
  **Strategy:**
  - 1st retry: 100ms
  - 2nd retry: 200ms
  - 3rd retry: 400ms
  - Then fail with user-friendly message

- [ ] **2.2.2** Add Retry Logic to API Services (2 hours)
  - Update [lib/services/affiliate_api_service.dart](lib/services/affiliate_api_service.dart)
  - Update [lib/services/shipping_firestore_service.dart](lib/services/shipping_firestore_service.dart)
  - Add retry to all network calls

- [ ] **2.2.3** Implement Offline Detection & Caching (2 hours)
  ```dart
  // lib/services/connectivity_service.dart
  class ConnectivityService {
    Stream<bool> get isConnected;
    
    Future<T> callWithFallback<T>(
      Future<T> Function() onlineCall,
      Future<T> Function() offlineCall,
    );
  }
  ```
  
  - Cache recent requests
  - Use cache when offline
  - Sync when back online

- [ ] **2.2.4** Add Graceful Degradation (1 hour)
  - Show cached data while loading
  - Don't block UI on network failure
  - Offer "Retry" button on error
  - Show "Limited offline mode" banner

- [ ] **2.2.5** Implement Error Boundary Improvements (1 hour)
  - File: [lib/widgets/error_boundary.dart](lib/widgets/error_boundary.dart)
  - Catch all build errors
  - Show user-friendly error screen
  - Include "Report Issue" button
  - Allow app to recover

**Acceptance Criteria:**
- ✅ Network errors handled gracefully
- ✅ Automatic retry on failure
- ✅ Offline mode with caching
- ✅ User can manually retry
- ✅ No raw error messages shown
- ✅ App doesn't crash on error

**Error Scenarios to Test:**
- [ ] Network timeout → Retry
- [ ] Connection lost → Show offline banner
- [ ] Server 500 error → Show error message
- [ ] Invalid JSON response → Handle gracefully
- [ ] Firebase connection lost → Use cache

---

### ✓ TASK 2.3: Implement Admin Claim Verification (2 hours)
**Severity:** 🟡 HIGH  
**Blocks:** Admin security  
**Owner:** Flutter Dev (admin app)

**Current State:**
- Admin screens: Accessible without verification ❌
- Custom claims: Set up in Firebase ✅
- Verification: Not implemented ❌
- Risk: Any authenticated user can access admin features

**Action Items:**
- [ ] **2.3.1** Create Custom Claims Checker (1 hour)
  ```dart
  // admin/lib/core/auth/custom_claims_checker.dart
  class CustomClaimsChecker {
    Future<bool> hasAdminClaim(User user) async {
      final idTokenResult = await user.getIdTokenResult(true);
      return idTokenResult.claims?['admin'] == true;
    }
    
    Future<String?> getUserRole(User user) async {
      final idTokenResult = await user.getIdTokenResult(true);
      return idTokenResult.claims?['role'];
    }
  }
  ```

- [ ] **2.3.2** Add Route Guard for Admin Routes (1 hour)
  - File: [admin/lib/core/routing/app_router.dart](admin/lib/core/routing/app_router.dart)
  - On app launch, check admin claim
  - If not admin, redirect to login or forbidden screen
  - Verify on every navigation to protected route

  ```dart
  // Add route guard
  @riverpod
  Future<bool> isUserAdmin(IsUserAdminRef ref) async {
    final authProvider = ref.watch(firebaseAuthProvider);
    
    if (authProvider is! AsyncData || authProvider.value == null) {
      return false;
    }
    
    final user = authProvider.value!;
    final isClaimed = await _customClaimsChecker.hasAdminClaim(user);
    
    if (!isClaimed) {
      // Redirect to forbidden screen
    }
    
    return true;
  }
  ```

**Acceptance Criteria:**
- ✅ Non-admin users cannot access admin screens
- ✅ Route guards work on all admin routes
- ✅ Custom claims checked on app launch
- ✅ Claims refreshed every 1 hour
- ✅ Forbidden screen shown for non-admins

---

## 🎯 PHASE 2 SUMMARY

| Task | Hours | Severity | Status |
|------|-------|----------|--------|
| Implement Input Validation | 6 | HIGH | ⏳ TODO |
| Error Recovery & Retry Logic | 8 | HIGH | ⏳ TODO |
| Admin Claim Verification | 2 | HIGH | ⏳ TODO |
| **TOTAL** | **16** | **HIGH** | **⏳ TODO** |

**Prerequisite:** Phase 1 must be 90% complete

---

---

# PHASE 3: TESTING & MONITORING (Days 6-7 - 38 Hours)
## Status: ⏳ BLOCKED

Critical for production quality and reliability.

### ✓ TASK 3.1: Create Unit Tests (20 hours)
**Severity:** 🔴 CRITICAL  
**Blocks:** Production deployment  
**Owner:** Flutter Dev + QA Engineer

**Current Test Coverage:**
- Unit tests: 0% ❌
- Widget tests: 0% ❌
- Integration tests: 0% ❌
- **Target:** 70% coverage

**Test Files to Create:**

| Module | Test File | Hours | Classes | Coverage |
|--------|-----------|-------|---------|----------|
| **Models** | `test/models/` | 4 | 20+ | 95% |
| **Services** | `test/services/` | 6 | 15+ | 90% |
| **Repositories** | `test/repositories/` | 4 | 10+ | 85% |
| **Validators** | `test/validators/` | 2 | 8+ | 100% |
| **Providers** | `test/providers/` | 4 | 12+ | 80% |

**Action Items:**
- [ ] **3.1.1** Create Model Tests (4 hours)
  ```dart
  // test/models/shipping_request_model_test.dart
  void main() {
    group('ShippingRequest', () {
      test('creates instance with valid data', () { });
      test('toJson() returns correct map', () { });
      test('fromJson() creates instance from map', () { });
      test('validates required fields', () { });
    });
  }
  ```
  
  Test classes:
  - ShippingRequest
  - Affiliate
  - PaymentTransaction
  - User
  - Order
  - Commission
  - Payout
  - Notification
  - etc.

- [ ] **3.1.2** Create Service Tests (6 hours)
  ```dart
  // test/services/auth_service_test.dart
  // test/services/payment_service_test.dart
  // test/services/retry_service_test.dart
  ```
  
  Use Riverpod testing utilities:
  - Mock dependencies
  - Test error cases
  - Test success cases

- [ ] **3.1.3** Create Repository Tests (4 hours)
  ```dart
  // test/repositories/affiliate_repository_test.dart
  // test/repositories/shipping_repository_test.dart
  ```
  
  Mock Firestore:
  - Test read operations
  - Test write operations
  - Test error handling

- [ ] **3.1.4** Create Validator Tests (2 hours)
  ```dart
  // test/services/form_validator_test.dart
  void main() {
    group('FormValidator', () {
      test('validateEmail() accepts valid email', () {
        expect(FormValidator.validateEmail('test@example.com'), isNull);
      });
      test('validateEmail() rejects invalid email', () {
        expect(FormValidator.validateEmail('invalid'), isNotNull);
      });
      // ... more tests
    });
  }
  ```

- [ ] **3.1.5** Create Provider Tests (4 hours)
  ```dart
  // test/providers/auth_provider_test.dart
  // test/providers/affiliate_provider_test.dart
  ```
  
  Test Riverpod providers:
  - Initialization
  - State changes
  - Dependencies

**Run Tests:**
```bash
flutter test --coverage
```

**Report:**
```
Test coverage report:
- Statements: 72%
- Branches: 65%
- Functions: 80%
- Lines: 75%
```

---

### ✓ TASK 3.2: Create Integration Tests (12 hours)
**Severity:** 🟡 HIGH  
**Blocks:** Feature verification  
**Owner:** QA Engineer + Flutter Dev

**Test Scenarios:**

| Scenario | Steps | Hours |
|----------|-------|-------|
| **User Registration Flow** | 1. Register 2. Verify email 3. Login | 2 |
| **Shipping Request Submission** | 1. Fill form 2. Upload doc 3. Submit 4. Verify Firestore | 2 |
| **Payment Processing** | 1. Enter payment info 2. Process 3. Verify transaction | 2 |
| **Admin Views Data** | 1. Admin login 2. View shipping 3. Filter 4. Update status | 2 |
| **Real-time Sync** | 1. Mobile creates 2. Admin sees immediately | 2 |
| **Affiliate Commission** | 1. Verify shipment 2. Commission created 3. Showing in dashboard | 2 |

**Action Items:**
- [ ] **3.2.1** Create Registration Flow Test (2 hours)
  ```dart
  // integration_test/auth_flow_test.dart
  void main() {
    group('Authentication Flow', () {
      testWidgets('User can register', (WidgetTester tester) async {
        // Launch app
        // Fill registration form
        // Submit
        // Verify email verification screen
        // Verify user in Firestore
      });
    });
  }
  ```

- [ ] **3.2.2** Create Shipping Request Test (2 hours)
  ```dart
  // integration_test/shipping_request_test.dart
  void main() {
    group('Shipping Request', () {
      testWidgets('User can submit shipping request', (tester) async {
        // Navigate to shipping form
        // Fill form (origin, destination, weight)
        // Upload document
        // Submit
        // Verify success screen
        // Verify in Firestore
        // Verify admin sees in list
      });
    });
  }
  ```

- [ ] **3.2.3** Create Payment Integration Test (2 hours)
  ```dart
  // integration_test/payment_test.dart
  testWidgets('User can make payment', (tester) async {
    // Add item to cart
    // Proceed to checkout
    // Enter payment info
    // Process payment
    // Verify transaction in Firestore
    // Verify receipt sent
  });
  ```

- [ ] **3.2.4** Create Admin Data View Test (2 hours)
  ```dart
  // integration_test/admin_dashboard_test.dart
  testWidgets('Admin can view and manage data', (tester) async {
    // Login as admin
    // View shipping requests
    // Filter by status
    // Update status
    // Verify mobile sees update
  });
  ```

- [ ] **3.2.5** Create Real-time Sync Test (2 hours)
  ```dart
  // integration_test/realtime_sync_test.dart
  testWidgets('Mobile to Admin sync works', (tester) async {
    // In mobile app: Create shipping request
    // Verify immediate appearance in admin
    // Measure latency
    // Verify data accuracy
  });
  ```

- [ ] **3.2.6** Create Affiliate Commission Test (2 hours)
  ```dart
  // integration_test/affiliate_test.dart
  testWidgets('Affiliate commission calculation', (tester) async {
    // Create matching shipment + affiliate
    // Verify commission created in Firestore
    // Verify showing in affiliate dashboard
    // Verify showing in admin payout calculations
  });
  ```

**Run Integration Tests:**
```bash
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/app_test.dart
```

---

### ✓ TASK 3.3: Setup Monitoring & Alerting (6 hours)
**Severity:** 🟡 HIGH  
**Blocks:** Production readiness  
**Owner:** DevOps + Backend Engineer

**Current State:**
- Firebase Crashlytics: ✅ Integrated
- Analytics: ✅ Integrated
- Performance Monitoring: ❌ Not setup
- Error Tracking: ⚠️ Partial
- Custom Metrics: ❌ Not setup

**Action Items:**
- [ ] **3.3.1** Setup Firebase Performance Monitoring (2 hours)
  - Identify critical user flows
  - Set custom traces:
    - "shipping_request_submission" (target: < 2000ms)
    - "payment_processing" (target: < 3000ms)
    - "admin_data_load" (target: < 1000ms)
  - Monitor inthash:
    - Network latency
    - Database query time
    - Function execution time

  ```dart
  // In lib/services/performance_service.dart
  final trace = FirebasePerformance.instance.newTrace("shipping_request");
  trace.start();
  // ... do work ...
  trace.stop();
  ```

- [ ] **3.3.2** Setup Firebase Crashlytics Dashboard (1 hour)
  - Verify crashes tracked
  - Create error grouping
  - Setup alerts for new crashes
  - Monitor crash-free user percentage

- [ ] **3.3.3** Create Custom Metrics (2 hours)
  ```dart
  // lib/services/analytics_service.dart
  class AnalyticsService {
    void trackShippingRequestSubmitted(ShippingRequest request) {
      FirebaseAnalytics.instance.logEvent(
        name: 'shipping_request_submitted',
        parameters: {
          'type': request.type,
          'weight': request.weight,
          'destination': request.destination,
        },
      );
    }
    
    void trackPaymentProcessed(PaymentTransaction txn) {
      FirebaseAnalytics.instance.logEvent(
        name: 'payment_processed',
        parameters: {
          'amount': txn.amount,
          'provider': txn.provider,
          'status': txn.status,
        },
      );
    }
    
    // ... more events
  }
  ```

- [ ] **3.3.4** Setup Alerting Rules (1 hour)
  - Alert on: Error rate > 5%
  - Alert on: Payment failures > 3 in 10 min
  - Alert on: API response time > 5 seconds
  - Alert on: Firestore quota exceeded
  - Notification channels: Email, Slack, etc.

**Monitoring Dashboard Checklist:**
- [ ] Crash rate visible
- [ ] Error tracking active
- [ ] Performance metrics tracked
- [ ] Custom events logged
- [ ] Alerts configured
- [ ] Dashboards created

---

### ✓ TASK 3.4: Create E2E Tests (Not required for MVP but recommended)
**Severity:** 🩵 MEDIUM  
**Time Required:** 10 hours (not in critical path for MVP)  
**Owner:** QA Engineer

---

## 🎯 PHASE 3 SUMMARY

| Task | Hours | Severity | Status |
|------|-------|----------|--------|
| Create Unit Tests | 20 | CRITICAL | ⏳ TODO |
| Create Integration Tests | 12 | HIGH | ⏳ TODO |
| Setup Monitoring & Alerting | 6 | HIGH | ⏳ TODO |
| **TOTAL** | **38** | **HIGH** | **⏳ TODO** |

**Prerequisite:** Phase 1 & 2 complete

---

---

# PHASE 4: PRODUCTION DEPLOYMENT (Day 8 - 12 Hours)
## Status: ⏳ BLOCKED

Go-live readiness and deployment automation.

### ✓ TASK 4.1: Setup CI/CD Pipeline (8 hours)
**Severity:** 🟡 HIGH  
**Blocks:** Continuous deployment capability  
**Owner:** DevOps

**Action Items:**
- [ ] **4.1.1** Create GitHub Actions Workflow for Flutter Builds (4 hours)
  ```yaml
  # .github/workflows/flutter-build.yml
  name: Flutter Build & Test
  
  on: [push, pull_request]
  
  jobs:
    test:
      runs-on: ubuntu-latest
      steps:
        - uses: actions/checkout@v3
        - uses: subosito/flutter-action@v2
        - run: flutter pub get
        - run: flutter test --coverage
        - run: flutter analyze
        - uses: codecov/codecov-action@v3
    
    build:
      needs: test
      runs-on: ubuntu-latest
      steps:
        - uses: actions/checkout@v3
        - uses: subosito/flutter-action@v2
        - run: flutter pub get
        - run: flutter build apk --release
        - uses: actions/upload-artifact@v3
          with:
            name: app-release.apk
            path: build/app/outputs/flutter-apk/app-release.apk
  ```

- [ ] **4.1.2** Create GitHub Actions for Admin Dashboard Deployment (2 hours)
  ```yaml
  # .github/workflows/admin-deploy.yml
  # Build and deploy admin app to Firebase Hosting
  ```

- [ ] **4.1.3** Create Environment Secrets (1 hour)
  - GitHub Secrets for:
    - Firebase credentials
    - Payment API keys
    - Sendgrid API key
    - Slack webhook (for notifications)

- [ ] **4.1.4** Setup Automated Testing on PR (1 hour)
  - Run tests on every pull request
  - Block merge if tests fail
  - Block merge if coverage < 70%

---

### ✓ TASK 4.2: Final Security Audit (4 hours)
**Severity:** 🔴 CRITICAL  
**Blocks:** Production approval  
**Owner:** Security Engineer (can be Flutter Dev)

**Checklist:**
- [ ] No hardcoded secrets in code
- [ ] CORS headers properly configured
- [ ] Rate limiting implemented
- [ ] Input validation on all endpoints
- [ ] Authentication required for sensitive operations
- [ ] Authorization rules verified
- [ ] Data encryption in transit (HTTPS)
- [ ] Data encryption at rest
- [ ] No SQL injection vulnerabilities
- [ ] No XSS vulnerabilities
- [ ] No CSRF vulnerabilities
- [ ] Firebase rules don't allow public write access
- [ ] API keys restricted to authorized domains
- [ ] Payment data not logged
- [ ] Logs don't contain sensitive information
- [ ] Third-party dependencies up to date
- [ ] No known CVEs in dependencies

---

## 🎯 PHASE 4 SUMMARY

| Task | Hours | Severity | Status |
|------|-------|----------|--------|
| Setup CI/CD Pipeline | 8 | HIGH | ⏳ TODO |
| Final Security Audit | 4 | CRITICAL | ⏳ TODO |
| **TOTAL** | **12** | **CRITICAL** | **⏳ TODO** |

**Prerequisite:** Phase 3 complete, all tests passing

---

---

# 📋 GO-LIVE CHECKLIST

Before releasing to production, verify ALL of the following:

## Code Quality (MUST PASS)
- [ ] ✅ No compilation errors
- [ ] ✅ Flutter analyze: 0 errors
- [ ] ✅ Test coverage: >= 70%
- [ ] ✅ All tests passing (unit + integration + e2e)
- [ ] ✅ Code reviewed by 2+ team members
- [ ] ✅ No TODO or FIXME comments in production code

## Firebase Setup (MUST BE DONE)
- [ ] ✅ Firestore rules deployed
- [ ] ✅ Firestore indexes deployed
- [ ] ✅ All 8 required collections created + seeded
- [ ] ✅ Firebase Admin SDK credentials secure
- [ ] ✅ Backups configured (automatic daily)
- [ ] ✅ Deletion protection enabled
- [ ] ✅ Monitoring alerts configured

## Payment System (MUST WORK)
- [ ] ✅ Stripe / Flutterwave / Paystack payment tested
- [ ] ✅ Real test transaction completed end-to-end
- [ ] ✅ Transaction appears in Firestore
- [ ] ✅ Receipt sent to user
- [ ] ✅ Admin sees transaction in dashboard
- [ ] ✅ Webhook callbacks working
- [ ] ✅ Refund flow tested
- [ ] ✅ Duplicate transaction prevention working

## Mobile App (MUST WORK)
- [ ] ✅ Registration flow works
- [ ] ✅ Login flow works
- [ ] ✅ Shipping request submission works
- [ ] ✅ Real-time sync with admin verified
- [ ] ✅ Push notifications working
- [ ] ✅ Offline mode tested
- [ ] ✅ No crashes on real device
- [ ] ✅ Performance acceptable (app opens < 3s)

## Admin Dashboard (MUST WORK)
- [ ] ✅ Admin login works
- [ ] ✅ Can view all shipping requests
- [ ] ✅ Can update request status
- [ ] ✅ Real-time updates from mobile visible
- [ ] ✅ Financial dashboard shows accurate data
- [ ] ✅ Affiliate management works
- [ ] ✅ No auth bypass vulnerabilities

## Security (MUST PASS)
- [ ] ✅ No secrets in code
- [ ] ✅ HTTPS enforced
- [ ] ✅ Rate limiting active
- [ ] ✅ Input validation on all forms
- [ ] ✅ Admin claims verified
- [ ] ✅ Security headers configured
- [ ] ✅ CORS configured correctly
- [ ] ✅ Payment data encrypted

## Operations (MUST BE READY)
- [ ] ✅ Error monitoring configured (Crashlytics)
- [ ] ✅ Performance monitoring configured
- [ ] ✅ Analytics tracking working
- [ ] ✅ Alerts configured for critical issues
- [ ] ✅ On-call rotation established
- [ ] ✅ Runbooks created for common issues
- [ ] ✅ Disaster recovery plan documented
- [ ] ✅ Rollback procedure tested

## Documentation (MUST BE COMPLETE)
- [ ] ✅ API documentation up-to-date
- [ ] ✅ Database schema documented
- [ ] ✅ Firebase setup guide complete
- [ ] ✅ Deployment procedure documented
- [ ] ✅ Troubleshooting guide created
- [ ] ✅ User documentation provided

---

# 📊 PROGRESS TRACKING

## Current Status: February 19, 2026

| Phase | Tasks | Completed | Progress | Status |
|-------|-------|-----------|----------|--------|
| **Phase 0** | 4 | 0 | 0% | ⏳ BLOCKED (CRITICAL PATH) |
| **Phase 1** | 3 | 0 | 0% | ⏳ BLOCKED (Waiting Phase 0) |
| **Phase 2** | 3 | 0 | 0% | ⏳ BLOCKED (Waiting Phase 1) |
| **Phase 3** | 4 | 0 | 0% | ⏳ BLOCKED (Waiting Phase 2) |
| **Phase 4** | 2 | 0 | 0% | ⏳ BLOCKED (Waiting Phase 3) |
| **TOTAL** | **17** | **0** | **0%** | **⏳ NOT STARTED** |

---

# 🎯 RECOMMENDED START TIME

**Recommendation:** Start Phase 0 **IMMEDIATELY**

- If started today (Feb 19): Completion by **Feb 28, 2026**
- Team: 1-2 developers, 1 DevOps engineer

---

# ❓ FREQUENTLY ASKED QUESTIONS

**Q: Can we skip any phase?**  
A: No. Each phase depends on the previous. Phase 0 is a hard blocker.

**Q: How long does each phase take?**  
A: 1-2 days per phase with focused team, following sequentially.

**Q: What if we hit blockers?**  
A: Each task has potential issues documented. Escalate immediately.

**Q: Can we do phases in parallel?**  
A: No. E.g., Phase 2 requires Phase 1 complete.

**Q: What if a task fails?**  
A: Restart from beginning of that task. Don't skip forward.

**Q: How do we know when to move to next phase?**  
A: All tasks in current phase must be 100% complete and tested.

---

# 📞 TEAM CONTACTS

| Role | Responsibility | Contact |
|------|-----------------|----------|
| **Flutter Dev** | Code implementation | TBD |
| **Backend Engineer** | Cloud Functions | TBD |
| **QA Engineer** | Testing & verification | TBD |
| **DevOps** | Infrastructure & CI/CD | TBD |
| **Security** | Security audit | TBD |

---

---

**Generated:** February 19, 2026  
**Prepared by:** GitHub Copilot (Claude Haiku 4.5)  
**Status:** Ready for Execution  
**Next Action:** Start Phase 0 immediately

# 🔥 FIREBASE INTEGRATION REFERENCE GUIDE

**Version:** 1.0  
**Date:** February 17, 2026  

---

## 📋 QUICK REFERENCE: WHAT GOES WHERE

### 🟢 MUST BE IN FIREBASE (Dynamic, Real-time Content)

```
┌─────────────────────────────────────────────────────────────────┐
│ REAL-TIME UPDATES - Changes frequently, needs instant syncing    │
├─────────────────────────────────────────────────────────────────┤

COLLECTION: banners/
├─ Use for: Home screen carousel, promotional banners
├─ Update frequency: Weekly (marketing team manages)
├─ Real-time needed: Yes (listeners on home screen)
├─ Schema:
│  ├─ title: string
│  ├─ subtitle: string
│  ├─ imageUrl: string
│  ├─ actionUrl: string (deep link)
│  ├─ active: boolean (toggle on/off)
│  ├─ order: number (sorting)
│  └─ createdAt: timestamp
└─ Why Firebase: Marketing team can update without app release

COLLECTION: announcements/
├─ Use for: App-wide alerts, notifications
├─ Update frequency: Daily
├─ Real-time needed: Yes
├─ Schema:
│  ├─ title: string
│  ├─ body: string
│  ├─ type: enum (info|warning|alert)
│  ├─ active: boolean
│  ├─ createdAt: timestamp
│  └─ expiresAt: timestamp
└─ Why Firebase: Instant broadcast to all users

COLLECTION: news_items/
├─ Use for: Home screen news ticker
├─ Update frequency: Daily (content team)
├─ Real-time needed: Yes
├─ Schema: Same as announcements
└─ Why Firebase: Real-time feed updates

COLLECTION: content_pages/
├─ Use for: Terms of Service, Privacy Policy, About Us
├─ Update frequency: Quarterly (legal team)
├─ Real-time needed: No (but nice to have)
├─ Schema:
│  ├─ slug: string (terms, privacy, about)
│  ├─ title: string
│  ├─ body: string (markdown or HTML)
│  ├─ version: number
│  ├─ updatedAt: timestamp
│  └─ effectiveDate: timestamp
└─ Why Firebase: Legal can update without delays

REMOTE CONFIG: Feature Flags
├─ Use for: Enable/disable payment methods, A/B testing
├─ Parameters needed:
│  ├─ enable_payment_stripe: boolean (default: true)
│  ├─ enable_payment_flutterwave: boolean (default: true)
│  ├─ enable_payment_paystack: boolean (default: true)
│  ├─ app_maintenance_mode: boolean (default: false)
│  ├─ minimum_app_version: string (e.g., "1.0.0")
│  ├─ announcement_text: string
│  ├─ help_center_enabled: boolean (default: true)
│  └─ feature_new_checkout: boolean (default: false)
├─ Cache expiration: 5 minutes default
├─ Update frequency: On-demand (ops team)
└─ Why Firebase: Instant control without app release

COLLECTION: shipping_rates/
├─ Use for: Dynamic shipping price calculation
├─ Update frequency: Weekly (logistics team)
├─ Real-time needed: Yes
├─ Schema:
│  ├─ zone: string (state/region)
│  ├─ baseRate: number
│  ├─ perKgRate: number
│  ├─ active: boolean
│  └─ updatedAt: timestamp
└─ Why Firebase: Rates change frequently based on logistics

COLLECTION: categories/
├─ Use for: Product browsing categories (if dynamic)
├─ Update frequency: Monthly
├─ Real-time needed: No
├─ Schema:
│  ├─ name: string
│  ├─ image: string
│  ├─ order: number
│  └─ active: boolean
└─ Why Firebase: Business can add/remove categories instantly

COLLECTION: notifications/ (User-specific)
├─ Use for: Real-time order updates, alerts
├─ Update frequency: Real-time
├─ Real-time needed: Yes
├─ Schema:
│  ├─ userId: string
│  ├─ type: string (order_update|payment|shipping)
│  ├─ title: string
│  ├─ body: string
│  ├─ read: boolean
│  ├─ createdAt: timestamp
│  └─ metadata: map
└─ Why Firebase: Real-time updates using listeners

COLLECTION: help_articles/ (Searchable content)
├─ Use for: Help center FAQ
├─ Update frequency: Weekly (support team)
├─ Real-time needed: No
├─ Schema:
│  ├─ title: string
│  ├─ slug: string (unique)
│  ├─ body: string
│  ├─ category: string
│  ├─ order: number
│  └─ updatedAt: timestamp
└─ Why Firebase: Support team can update independently

└─────────────────────────────────────────────────────────────────┘
```

---

### 🟡 HYBRID (Sometimes Firebase, Sometimes Hardcoded)

```
ORDERS / PAYMENTS / SHIPMENTS
├─ Master data: PostgreSQL (backend)
│  ├─ Order details stored for auditing
│  ├─ Payment verification data
│  ├─ Shipping tracking (backend generates)
│  └─ Financial records
│
├─ Real-time status: Firestore (for app)
│  ├─ Order collection synced from backend
│  ├─ Status updates written by backend
│  ├─ App listens for real-time changes
│  └─ Lightweight documents (status only)
│
└─ Why hybrid:
   ├─ PostgreSQL: ACID compliance, audit trail, financial safety
   ├─ Firestore: Real-time updates for users
   └─ Backend Cloud Function writes to both on state change

USER DATA
├─ Authentication: Firebase Auth (verified, secure)
│  ├─ Email, password hashing, phone verification
│  └─ Session management
│
├─ Profile: Both
│  ├─ Firebase: User profile (display name, photo, basics)
│  ├─ PostgreSQL: Extended profile, settings, preferences
│  └─ Sync: Backend writes profile changes to Firestore after save
│
└─ Performance: Firestore for read, PostgreSQL for write authoritative

VENDORS / MERCHANTS
├─ Master: PostgreSQL (auditable, business records)
├─ Real-time search: Firestore (indexed, searchable)
└─ Sync: Batch sync every hour, or on change event
```

---

### 🔵 MUST BE HARDCODED (Configuration, Build-time Secrets)

```
┌─────────────────────────────────────────────────────────────────┐
│ CONFIGURATION - Set at build/runtime, doesn't change per-user    │
├─────────────────────────────────────────────────────────────────┤

BUILD-TIME CONSTANTS (pubspec.yaml)
├─ App version: "1.0.0"
├─ App name: "ShopsNPorts"
├─ Min SDK version: 23 (Android), 11.0 (iOS)
└─ Build variables

RUNTIME CONFIG (lib/core/config/app_config.dart)
├─ API base URL: "https://api.shopsnports.com"
├─ Feature toggles:
│  ├─ forceSignOutOnStart: false
│  ├─ useEmulator: false (dev only)
│  └─ loggingLevel: "info"
├─ Timeouts:
│  ├─ apiTimeout: Duration(seconds: 30)
│  ├─ firebaseTimeout: Duration(seconds: 5)
│  └─ cacheExpiry: Duration(hours: 1)
└─ App constants:
   ├─ maxUploadSize: 10MB
   ├─ maxRetries: 3
   ├─ retryDelay: 1 second
   └─ Theme colors, fonts

ANDROID CONSTANTS (android/app/build.gradle.kts)
├─ Application ID: "com.example.shopsnports"
├─ Min SDK: 23
├─ Target SDK: 36
├─ Compile SDK: 36
└─ Signing config (prod only)

iOS CONSTANTS (ios/Runner.xcodeproj)
├─ Bundle ID: "com.example.shopsnports"
├─ Min iOS: 11.0
├─ Team ID (prod)
└─ Signing identities

ENVIRONMENT-SPECIFIC CONFIG
├─ Development: .env.dev
│  ├─ API_URL=http://localhost:3000
│  ├─ FIREBASE_PROJECT=shopsnports-dev
│  └─ DEBUG=true
├─ Staging: .env.staging
│  ├─ API_URL=https://api-staging.shopsnports.com
│  ├─ FIREBASE_PROJECT=shopsnports-staging
│  └─ DEBUG=false
└─ Production: .env.prod
   ├─ API_URL=https://api.shopsnports.com
   ├─ FIREBASE_PROJECT=shopsnports
   └─ DEBUG=false

DESIGN SYSTEM (lib/styles/theme.dart)
├─ Primary color: #2A7F62 (green)
├─ Secondary color: #FFC914 (yellow)
├─ Error color: #FF6B6B (red)
├─ Font family: Roboto, Poppins
├─ Typography scale: 12, 14, 16, 18, 20, 24, 32, 48
└─ Spacing scale: 4, 8, 12, 16, 24, 32, 48

ROUTE DEFINITIONS (lib/core/routing/app_router.dart)
├─ /: home
├─ /sign-in: authentication
├─ /sign-up: registration
├─ /products: product list
├─ /product/:id: product detail
├─ /cart: shopping cart
├─ /checkout: payment
├─ /orders: order history
├─ /profile: user profile
└─ ... (all routes defined statically)

ERROR CATEGORIES (lib/core/errors/)
├─ ValidationException: Input validation failed
├─ NetworkException: No internet/timeout
├─ AuthenticationException: User not authenticated
├─ AuthorizationException: User not authorized
├─ ServerException: 5xx server error
└─ PaymentException: Payment processing failed

CONSTANTS (lib/utils/constants.dart)
├─ Numeric limits:
│  ├─ MIN_PASSWORD_LENGTH: 8
│  ├─ MAX_FILE_SIZE: 10485760 (10MB)
│  ├─ MIN_CART_VALUE: 100 (currency units)
│  └─ MAX_CART_VALUE: 1000000
├─ Timeouts:
│  ├─ API_TIMEOUT: 30 seconds
│  ├─ IMAGE_UPLOAD_TIMEOUT: 60 seconds
│  └─ INITIAL_LOAD_TIMEOUT: 5 seconds
├─ Retry policies:
│  ├─ MAX_RETRIES: 3
│  ├─ INITIAL_RETRY_DELAY: 1 second
│  └─ RETRY_BACKOFF: exponential (2x)
└─ Business rules:
   ├─ SHIPPING_INDUSTRIES: ["food", "goods", "documents"]
   ├─ MIN_ORDER_VALUE: 500
   └─ COMMISSION_RATE: 0.05 (5%)

WHY HARDCODED:
├─ Never changes per-user
├─ Same across all installations
├─ Requires app release to change
├─ Build reproducibility
├─ Security (secrets via env vars, not in code)
└─ Performance (no runtime lookups)

└─────────────────────────────────────────────────────────────────┘
```

---

## 🔐 REQUEST: Firebase vs BACKEND

### Router Pattern: Who Owns What?

```
REQUEST FLOW:

┌─ USER ACTION
├─ App triggers event
└─ Decision: Firebase? or Backend?

IF Real-time, user-facing, small:
   └─ TRY FIREBASE FIRST
      ├─ Notifications: Firestore listener
      ├─ Status updates: Firestore listener
      ├─ Profile photo: Firebase Storage
      ├─ Settings: Firestore document
      └─ Advantages: Instant, no latency, offline support

IF Financial, audit trail, complex:
   └─ USE BACKEND ALWAYS
      ├─ Order creation: REST API
      ├─ Payment processing: REST API
      ├─ Inventory updates: REST API
      ├─ Shipping requests: REST API → Firestore (async)
      └─ Advantages: ACID, verification, permanent record

IF Needs to search/aggregate:
   └─ FIRESTORE (secondary index only)
      ├─ Search users: Firestore index query
      ├─ Search products: Firestore index query
      ├─ Filter orders: Backend API (source of truth)
      └─ Pattern: Backend is source, Firestore is search index

DECISION TREE:
                      ┌──── Needs real-time?
                      │─ Yes: Firestore
                      │─ No: Could be either
                      │
                      ├──── Financial/audit?
                      │─ Yes: Backend (PostgreSQL)
                      │─ No: Could be either
                      │
                      ├──── Searchable/indexed?
                      │─ Yes: Firestore (query engine)
                      │─ No: Could be either
                      │
                      ├──── User creates/updates?
                      │─ Yes: Backend validates, writes both
                      │─ No: Admin only, backend writes
                      │
                      └───→ DECISION MADE
```

### Example: Order Flow

```
STEP 1: USER VIEWS CART
├─ Source: Firestore (real-time listener)
├─ Reads: Cached cart from local storage
├─ Real-time: Cart updates show instantly
└─ Backend: Not involved

STEP 2: USER TAPS CHECKOUT
├─ Frontend: Validates cart locally
├─ Frontend: Collects address & payment method
└─ Both in app state (not saved yet)

STEP 3: USER TAPS "PLACE ORDER"
├─ App sends: REST POST /api/v1/orders
├─ Request includes:
│  ├─ Authorization: Firebase ID token
│  ├─ Cart items
│  ├─ Shipping address
│  ├─ Payment method
│  └─ Total amount
│
├─ BACKEND DOES:
│  ├─ Verify Firebase token
│  ├─ Validate address
│  ├─ Verify items exist
│  ├─ Check inventory
│  ├─ Create order in PostgreSQL
│  ├─ Process payment
│  ├─ Update inventory in PostgreSQL
│  └─ Create Cloud Function task
│
├─ CLOUD FUNCTION DOES:
│  ├─ Create `orders/{orderId}` in Firestore
│  ├─ Create notification for user
│  ├─ Send confirmation email
│  └─ Trigger shipping system (if applicable)
│
└─ APP DOES:
   ├─ Clear cart from Firestore
   ├─ Listen to `orders/{orderId}` in Firestore
   ├─ Show order confirmation
   ├─ Show real-time status updates
   └─ Push notifications as order progresses

SOURCE OF TRUTH:
├─ Order master data: PostgreSQL (backend system)
├─ Order status: Firestore (real-time sync)
├─ Cart: Firestore (user's current session)
├─ Notifications: Firestore (app listener)
└─ Inventory: PostgreSQL (business system)
```

---

## 📱 IMPLEMENTATION CHECKLIST

### Phase 1: Foundation (Must Deploy Before Launch)

- [ ] **Bootstrap Firestore Collections**
  ```bash
  node scripts/seed_firestore.js
  # Creates: banners, news_items, users (if public), legal_documents, etc.
  ```

- [ ] **Deploy Firestore Rules**
  ```bash
  firebase deploy --only firestore:rules
  ```

- [ ] **Deploy Firestore Indexes**
  ```bash
  firebase deploy --only firestore:indexes
  ```

- [ ] **Test Rules in Emulator**
  ```bash
  npm run firestore:emulator
  # Run security rule tests
  firebase emulators:start --only firestore
  ```

- [ ] **Configure Remote Config**
  - [ ] Go to Firebase Console > Remote Config
  - [ ] Add 8 parameters (see REMOTE CONFIG above)
  - [ ] Set cache expiration to 5 minutes (default)
  - [ ] Deploy

- [ ] **Deploy Cloud Functions**
  ```bash
  cd functions
  firebase deploy --only functions
  ```

- [ ] **Enable Firebase Analytics**
  - [ ] Verify firebase_analytics dependency
  - [ ] Check Firebase Console > Analytics
  - [ ] Create dashboard for key metrics

- [ ] **Verify Firebase Messaging (Optional)**
  - [ ] If version conflicts resolved
  - [ ] Topic subscriptions tested
  - [ ] Push notifications working

### Phase 2: Data Synchronization (Week 2)

- [ ] **Backend Writes to Firestore**
  - [ ] On order creation: Cloud Function writes to `orders/{orderId}`
  - [ ] On order status change: Cloud Function updates `orders/{orderId}`
  - [ ] On notification: Backend triggers Cloud Function to write

- [ ] **App Listens to Firestore**
  - [ ] Home screen listens to `banners/` collection
  - [ ] Order detail listens to `orders/{orderId}`
  - [ ] Notifications screen listens to `notifications/` filtered by userId
  - [ ] Use FutureBuilder or StreamBuilder for each

- [ ] **Offline Support (Optional)**
  - [ ] Enable Firestore offline persistence
  - [ ] Test app works with localStorage fallback
  - [ ] Sync when back online

### Phase 3: Monitoring (Week 3)

- [ ] **Firestore Metrics**
  - [ ] Monitor collection size growth
  - [ ] Monitor query performance
  - [ ] Monitor document write rate
  - [ ] Check empty collections (unused data)

- [ ] **Remote Config**
  - [ ] Monitor parameter changes
  - [ ] Log parameter values in app
  - [ ] Set up alerts for stale cache

- [ ] **Cloud Functions**
  - [ ] Monitor function duration
  - [ ] Monitor error rate
  - [ ] Monitor cold start time

---

## 🔄 MIGRATION STRATEGY: Mock → Real

### Current State (Pre-Production)
```dart
// lib/services/affiliate_api_service.dart
static const bool _useMockData = true;  // ❌ REMOVE
```

### Day of Migration
```
1. BACKUP
   - Export current Firestore data (if any)
   - Screenshot current app state
   
2. CUTOVER
   - Set _useMockData = false
   - Restart app
   - Test critical paths
   
3. VERIFY
   - Check network calls are real
   - Verify backend returns data
   - Check no fallback to mock data
   
4. MONITOR
   - Watch Crashlytics for errors
   - Monitor API success rate
   - Track user feedback
```

---

## 🚀 LAUNCH READINESS CHECKLIST

### Firebase Checklist (Must Complete Before APK Release)

**Collections:**
- [ ] `banners/` - Created and seeded (≥5 banners)
- [ ] `announcements/` - Created and seeded
- [ ] `news_items/` - Created and seeded
- [ ] `content_pages/` - Created (Terms, Privacy, About)
- [ ] `users/` - Ready to receive signups
- [ ] `notifications/` - Ready for real-time updates
- [ ] `orders/` - Ready to receive orders
- [ ] `shipping_requests/` - Ready for requests

**Rules:**
- [ ] Rules reviewed by security expert
- [ ] Rules tested in emulator
- [ ] Rules deployed to Firebase
- [ ] All collections accessible per rules
- [ ] No overly permissive rules

**Indexes:**
- [ ] All composite indexes created
- [ ] Indexes deployed to Firebase
- [ ] Query performance verified

**Remote Config:**
- [ ] Parameters configured (8 minimum)
- [ ] Cache expiration set (5 min default)
- [ ] Parameters tested in app
- [ ] Fallback values working

**Cloud Functions:**
- [ ] All functions written
- [ ] All functions deployed
- [ ] Triggers tested
- [ ] Error handling implemented

**Monitoring:**
- [ ] Crashlytics enabled
- [ ] Analytics enabled
- [ ] Audit logging enabled
- [ ] Alerts configured

**Testing:**
- [ ] Mock data disabled
- [ ] Real data from backend verified
- [ ] Offline mode tested (if supported)
- [ ] Sync verified

### Backend Integration Checklist

**API Endpoints:**
- [ ] All required endpoints built
- [ ] All endpoints return correct format
- [ ] Authentication on all endpoints
- [ ] Authorization checks
- [ ] Input validation

**Database:**
- [ ] PostgreSQL running
- [ ] Migrations applied
- [ ] Backup configured
- [ ] Restore tested

**Synchronization:**
- [ ] Backend writes to Firestore on order creation
- [ ] Backend writes to Firestore on status updates
- [ ] App listens for real-time updates
- [ ] No race conditions

### Testing Checklist

**Happy Paths:**
- [ ] Sign up → Order → Payment → Shipment
- [ ] Search → Cart → Checkout → Payment
- [ ] Affiliate token usage

**Error Paths:**
- [ ] Network timeout
- [ ] Invalid data
- [ ] Payment failure
- [ ] Server error

**Platform:**
- [ ] Android (API 23+)
- [ ] iOS (11.0+)
- [ ] Tab (if applicable)

---

## 📊 MONITORING QUERIES

### Firebase Console Queries

```javascript
// See all banners
db.collection("banners").where("active", "==", true)

// See latest announcements
db.collection("announcements")
  .orderBy("createdAt", "desc")
  .limit(10)

// See user notifications
db.collection("notifications")
  .where("userId", "==", currentUser.uid)
  .where("read", "==", false)
  .orderBy("createdAt", "desc")

// See orders for status check
db.collection("orders")
  .where("status", "==", "pending")
  .orderBy("createdAt", "desc")
```

### Metrics to Track Post-Launch

```
Firestore:
├─ Total documents stored
├─ Active listeners (real-time)
├─ Query latency (p95)
├─ Write throughput
└─ Errors (quota exceeded, permission denied, etc)

Remote Config:
├─ Parameter fetch latency
├─ Cache hit rate
├─ Parameter values (audit trail)
└─ Errors (fetch failures)

Cloud Functions:
├─ Execution duration (p95)
├─ Error rate
├─ Cold start time
└─ Timeout events
```

---

## ⚠️ COMMON MISTAKES TO AVOID

```
❌ DON'T:
├─ Enable client-side write access to sensitive collections
│  └─ Firestore rules should restrict who can write
│
├─ Store authentication tokens in Firestore
│  └─ Keep tokens in secure storage only
│
├─ Hard-code Firestore data in app
│  └─ Always read from collections
│
├─ Forget to test Firestore rules
│  └─ Use emulator before deploying
│
├─ Mix roles in security rules
│  └─ Use custom claims consistently
│
├─ Write orders directly from app
│  └─ Backend must write for auditing
│
├─ Store API keys in Firestore
│  └─ Use environment variables only
│
└─ Deploy rules without review
   └─ Have security expert review first

✅ DO:
├─ Test rules thoroughly
├─ Review security regularly
├─ Monitor metrics
├─ Have escalation process
├─ Document decisions
├─ Audit access patterns
└─ Back up important data
```

---

**Document Version:** 1.0  
**Last Updated:** February 17, 2026  
**Next Review:** Before App Store submission  


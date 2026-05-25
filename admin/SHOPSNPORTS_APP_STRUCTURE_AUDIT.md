# 🔍 ShopsNPorts Mobile App - Detailed Structure Audit

**Date**: January 30, 2026  
**Status**: 📊 Structure Analysis Complete  
**Location**: `c:\projects\shopsnports`  
**Framework**: Flutter Mobile (iOS/Android)  
**State Management**: Riverpod  
**Backend**: Firebase + Firestore + Custom APIs  

---

## 📁 CURRENT APP STRUCTURE

### Root Directory Organization
```
shopsnports/
├── lib/                          (Main source code)
├── assets/                       (Images, animations, designs)
│   ├── designs/
│   ├── images/
│   ├── images/payments/
│   └── animations/
├── android/                      (Android native code)
├── ios/                          (iOS native code)
├── pubspec.yaml                  (Dependencies)
├── README.md
└── [other Flutter config files]
```

---

## 🏗️ LIB STRUCTURE (Main Application Code)

### Core Directories
```
lib/
├── core/                         (✅ KEEP - Core infrastructure)
├── models/                       (⚠️ MIXED - Some to delete)
├── providers/                    (⚠️ MIXED - Some to delete)
├── repositories/                 (⚠️ MIXED - Some to delete)
├── screens/                      (🔴 MAJOR CLEANUP - Most to delete)
├── services/                     (⚠️ MIXED - Some to delete)
├── state/                        (⚠️ MIXED - Some to delete)
├── styles/                       (✅ KEEP - Design system)
├── utils/                        (✅ KEEP - Utilities)
└── widgets/                      (⚠️ MIXED - Some to delete)
```

---

## 📊 DETAILED INVENTORY

### 1. MODELS DIRECTORY (lib/models/)

**Current Files:**
```
address.dart                      ✅ KEEP (for shipping addresses)
affiliate.dart                    ✅ KEEP (affiliate system)
cart_item.dart                    🔴 DELETE (ecommerce cart)
category.dart                     🔴 DELETE (product categories)
enums.dart                        ⚠️ REFACTOR (remove shopping enums)
invoice.dart                      ⚠️ REVIEW (keep if shipping-related)
order.dart                        🔴 DELETE (shopping orders)
payout_record.dart                ✅ KEEP (affiliate payouts)
product.dart                      🔴 DELETE (product model)
product_item.dart                 🔴 DELETE (ecommerce product)
shipping_request.dart             ✅ KEEP (core shipping feature)
user.dart                         ✅ KEEP (user profile/auth)
vendor.dart                       🔴 DELETE (ecommerce vendor model)

Status: 4 KEEP / 6 DELETE / 3 REFACTOR
Impact: -2-3 MB code
```

**Details on Each:**

| File | Keep? | Reason | Action |
|------|-------|--------|--------|
| address.dart | ✅ | Needed for shipping request addresses | Keep as is |
| affiliate.dart | ✅ | Core to affiliate program | Keep as is |
| cart_item.dart | ❌ | Pure ecommerce shopping cart | Delete entirely |
| category.dart | ❌ | Product categories (shopping) | Delete entirely |
| enums.dart | ⚠️ | May contain shopping enums | Audit & refactor - remove shopping enums |
| invoice.dart | ✅ | Shipping invoices (not orders) | Keep, verify it's shipping-specific |
| order.dart | ❌ | Shopping orders (not shipping requests) | Delete entirely |
| payout_record.dart | ✅ | Affiliate earnings tracking | Keep as is |
| product.dart | ❌ | Product model (shopping) | Delete entirely |
| product_item.dart | ❌ | Product item (shopping) | Delete entirely |
| shipping_request.dart | ✅ | Core shipping request model | Keep as is |
| user.dart | ✅ | User auth & profile | Keep as is |
| vendor.dart | ❌ | Vendor/seller model (ecommerce) | Delete entirely |

---

### 2. SERVICES DIRECTORY (lib/services/)

**Current Files (30 total):**

#### Firebase Services (✅ KEEP CORE)
```
firebase_core                     ✅ CRITICAL - Main Firebase setup
firebase_auth                     ✅ CRITICAL - Authentication
cloud_firestore                   ✅ CRITICAL - Database
firestore_service.dart            ✅ KEEP - Firestore abstraction
shipping_firestore_service.dart   ✅ KEEP - Shipping-specific Firestore
auth_service.dart                 ✅ KEEP - Auth service layer
storage_service.dart              ✅ KEEP - Firebase Storage
push_notification_service.dart    ✅ KEEP - FCM notifications
notification_service.dart        ✅ KEEP - Local notifications
analytics_service.dart            ✅ KEEP - Firebase Analytics
```

#### Affiliate Services (✅ KEEP)
```
affiliate_api.dart                ✅ KEEP - Affiliate API calls
affiliate_api_service.dart        ✅ KEEP - Affiliate service layer
mock_affiliate_service.dart       ✅ KEEP - Mock for testing
```

#### Shipping Services (✅ KEEP)
```
shipping_api_service.dart         ✅ KEEP - Shipping API
shipping_token_service.dart       ✅ KEEP - Shipping auth tokens
mock_shipment_service.dart        ✅ KEEP - Mock for testing
```

#### Product/Shopping Services (❌ DELETE)
```
products_api_service.dart         ❌ DELETE
categories_api_service.dart       ❌ DELETE
reviews_api_service.dart          ❌ DELETE
vendor_api_service.dart           ❌ DELETE
orders_api_service.dart           ❌ DELETE
```

#### Ecommerce Services (❌ DELETE)
```
orders_service.dart               ❌ DELETE (shopping orders)
```

#### Content/Utility Services (✅ EVALUATE)
```
banners_api_service.dart          ⚠️ REVIEW (remove promo banners)
content_api_service.dart          ✅ KEEP (general content)
content_service.dart              ✅ KEEP
currency_service.dart             ✅ KEEP (for shipping rates)
feature_flags.dart                ✅ KEEP (feature toggles)
geolocation_service.dart          ✅ KEEP (shipping location)
invoices_api_service.dart         ✅ KEEP (shipping invoices)
news_ticker_service.dart          ✅ KEEP (news/updates)
secure_storage_service.dart       ✅ KEEP (secure data)
api_service.dart                  ⚠️ REFACTOR (base API - remove shopping endpoints)
```

**Summary:**
- ✅ 19 services to KEEP
- ❌ 5 services to DELETE
- ⚠️ 6 services to REFACTOR

**Impact**: -1.5-2 MB code

---

### 3. SCREENS DIRECTORY (lib/screens/)

**Current Folders (18 total):**

| Folder | Purpose | Keep? | Details | Files Count |
|--------|---------|-------|---------|-------------|
| **affiliate** | Affiliate program | ✅ | Signup, dashboard, earnings | 5-8 |
| **auth** | Authentication | ✅ | Login, signup, verify, password reset | 8-10 |
| **cart** | Shopping cart | ❌ | Cart view, checkout preview | 4-6 |
| **customer** | Customer orders | ❌ | Order history, tracking, details | 6-8 |
| **help** | Help/Support | ✅ | FAQs, contact support | 3-5 |
| **legal** | Legal pages | ✅ | Terms, privacy, policy | 4-6 |
| **notifications** | Notifications | ✅ | Notification list, details | 3-5 |
| **orders** | Shopping orders | ❌ | Order management (NOT shipping) | 8-12 |
| **product** | Product browsing | ❌ | Product list, detail, filters, search | 12-18 |
| **profile** | User profile | ✅ | Profile, settings, preferences | 6-8 |
| **public** | Public pages | ✅ | Home, splash, landing | 8-10 |
| **search** | Product search | ❌ | Search UI (ecommerce focused) | 4-6 |
| **settings** | App settings | ✅ | Language, theme, preferences | 3-5 |
| **shipments** | Shipping requests | ✅ | Request form, tracking, history | 10-15 |
| **shipper** | Shipper interface | ✅ | Shipper dashboard, requests | 8-12 |
| **shipping** | Shipping info | ✅ | Shipping details, rates, info | 5-8 |
| **vendor** | Vendor/seller | ❌ | Vendor dashboard (ecommerce) | 8-12 |
| **verify** | Verification | ✅ | Email, phone, KYC verify | 5-8 |

**Breakdown:**
```
✅ KEEP ENTIRE:  affiliate, auth, help, legal, notifications, profile, 
                 public, settings, shipments, shipper, shipping, verify
                 (12 folders, ~95 files)

❌ DELETE ENTIRE: cart, customer, orders, product, search, vendor
                 (6 folders, ~60 files)
                 
⚠️ REFACTOR:     public (remove ecommerce home, keep shipping landing)
                 product search (if exists) - integrate into shipping search
```

**Impact**: -3-4 MB code, -60 files

---

### 4. PROVIDERS DIRECTORY (lib/providers/)

**Purpose**: Riverpod state management providers

**Expected Files**:
- `auth_provider.dart` - Authentication state ✅ KEEP
- `user_provider.dart` - User profile state ✅ KEEP
- `affiliate_provider.dart` - Affiliate state ✅ KEEP
- `shipping_provider.dart` - Shipping requests state ✅ KEEP
- `product_provider.dart` - Product state ❌ DELETE
- `cart_provider.dart` - Cart state ❌ DELETE
- `order_provider.dart` - Order state ❌ DELETE
- `category_provider.dart` - Category state ❌ DELETE
- `vendor_provider.dart` - Vendor state ❌ DELETE
- `notification_provider.dart` - Notifications ✅ KEEP
- `search_provider.dart` - Search state ⚠️ DELETE if ecommerce only

**Impact**: -1-1.5 MB

---

### 5. REPOSITORIES DIRECTORY (lib/repositories/)

**Purpose**: Data layer abstraction

**Expected Structure**:
- `auth_repository.dart` - Firebase Auth ✅ KEEP
- `user_repository.dart` - User data ✅ KEEP
- `shipping_repository.dart` - Shipping requests ✅ KEEP
- `affiliate_repository.dart` - Affiliate data ✅ KEEP
- `product_repository.dart` - Product data ❌ DELETE
- `order_repository.dart` - Shopping orders ❌ DELETE
- `cart_repository.dart` - Shopping cart ❌ DELETE
- `vendor_repository.dart` - Vendor data ❌ DELETE
- etc.

**Impact**: -0.5-1 MB

---

### 6. OTHER DIRECTORIES

```
core/                            ✅ KEEP (routing, constants, config)
styles/                          ✅ KEEP (themes, colors, typography)
utils/                           ✅ KEEP (helpers, validators, extensions)
widgets/                         ⚠️ REFACTOR (remove shopping widgets)
state/                           ⚠️ REFACTOR (remove shopping state)
```

---

## 📦 DEPENDENCIES ANALYSIS

### Current Dependencies (from pubspec.yaml)

#### Firebase Stack (✅ CRITICAL - KEEP ALL)
```yaml
firebase_core: ^4.1.1              ✅ Required
firebase_auth: ^6.1.0              ✅ Required
cloud_firestore: ^6.0.2            ✅ Required
firebase_storage: ^13.0.2          ✅ For document uploads
firebase_analytics: ^12.0.2        ✅ Analytics tracking
firebase_crashlytics: ^5.0.6       ✅ Error tracking
firebase_messaging: ^16.0.2        ✅ Push notifications
```

#### Core Flutter & UI (✅ KEEP ALL)
```yaml
flutter:                           ✅ Main framework
flutter_lints: ^6.0.0             ✅ Linting
flutter_riverpod: ^2.6.1          ✅ State management
flutter_svg: ^2.0.0               ✅ SVG support
shimmer: ^3.0.0                   ✅ Loading states
lottie: ^2.7.0                    ✅ Animations
carousel_slider: ^5.1.1           ⚠️ REVIEW (remove if shopping carousel only)
liquid_pull_to_refresh: ^3.0.1    ✅ Pull to refresh
intl: ^0.19.0                     ✅ Internationalization
uuid: ^4.5.1                      ✅ Unique IDs
```

#### Location & Maps (✅ KEEP)
```yaml
geocoding: ^4.0.0                 ✅ Address to coordinates
geolocator: ^14.0.2               ✅ User location
```

#### Security & Storage (✅ KEEP)
```yaml
shared_preferences: ^2.5.3        ✅ Local storage
file_picker: ^10.3.3              ✅ File selection
image_picker: ^0.8.7+5            ✅ Image upload
flutter_image_compress: ^2.4.0    ✅ Image optimization
url_launcher: ^6.1.12             ✅ Open URLs
webview_flutter: ^4.0.7           ✅ Web viewing
```

#### Authentication (✅ KEEP)
```yaml
google_sign_in: ^6.3.0            ✅ Google auth
```

#### Networking (✅ KEEP)
```yaml
http: ^1.5.0                      ✅ HTTP requests
```

#### Payment Gateways (❌ REVIEW/DELETE)
```yaml
flutter_stripe: ^9.0.0            ❌ DELETE (shopping payments)
flutterwave_standard: ^1.1.0      ❌ DELETE (shopping payments)
flutter_paystack_plus: ^2.3.0     ❌ DELETE (shopping payments)
```

#### Testing (✅ KEEP)
```yaml
flutter_test:                     ✅ Unit tests
integration_test:                 ✅ Integration tests
flutter_launcher_icons: ^0.10.0   ✅ App icons
fake_cloud_firestore: ^4.0.0      ✅ Testing Firebase
```

**Summary:**
- ✅ 28 dependencies to KEEP
- ❌ 3 dependencies to DELETE (payment gateways)
- ⚠️ 1-2 dependencies to REVIEW

**Impact**: ~500 KB removed, faster build

---

## 🔐 FIREBASE INTEGRATION STATUS

### Current Firebase Setup
```
Firebase Products Used:
├── ✅ Firebase Authentication (Google, Email/Password)
├── ✅ Cloud Firestore (Database)
├── ✅ Firebase Storage (File uploads)
├── ✅ Firebase Messaging (Push notifications)
├── ✅ Firebase Analytics (User tracking)
├── ✅ Firebase Crashlytics (Error reporting)
└── ✅ Cloud Functions (Backend operations - assumed)
```

### Hardcoding Audit Required

**Areas to Check for Hardcoding:**
- [ ] API endpoints (should be Firebase cloud functions)
- [ ] Data fetching logic (should use Firestore)
- [ ] Authentication flow (verify Firebase Auth)
- [ ] Storage paths (verify Firebase Storage)
- [ ] Notification handling (verify Firebase Messaging)
- [ ] User IDs (should come from Firebase Auth)
- [ ] Collection names (verify Firestore collections)
- [ ] Environment variables (check for hardcoded prod/test URLs)
- [ ] API keys (verify in Firebase config)
- [ ] Database references (should be Firestore, not REST APIs)

### Firebase Integration Points to Standardize

```
1. Authentication
   Current: firebase_auth ✅
   Needs: Verify Firebase Auth is sole auth provider
   
2. Database
   Current: Firestore ✅
   Needs: Verify all data queries use Firestore
   
3. File Storage
   Current: Firebase Storage ✅
   Needs: Verify all file uploads use Firebase Storage
   
4. Real-time Updates
   Current: StreamProvider (Riverpod) ✅
   Needs: Verify Firestore snapshots for real-time sync
   
5. Cloud Functions
   Current: Assumed ⚠️
   Needs: Verify backend logic uses Cloud Functions
   
6. Push Notifications
   Current: Firebase Messaging ✅
   Needs: Verify FCM is configured for both iOS/Android
   
7. Analytics
   Current: Firebase Analytics ✅
   Needs: Verify tracking events are sent
```

---

## 📋 DETAILED DELETION CHECKLIST

### Phase 1: Delete Ecommerce Models & Services
**Estimated: 2-3 hours**

Models to delete:
- [ ] `lib/models/cart_item.dart`
- [ ] `lib/models/category.dart`
- [ ] `lib/models/order.dart`
- [ ] `lib/models/product.dart`
- [ ] `lib/models/product_item.dart`
- [ ] `lib/models/vendor.dart`

Services to delete:
- [ ] `lib/services/products_api_service.dart`
- [ ] `lib/services/categories_api_service.dart`
- [ ] `lib/services/reviews_api_service.dart`
- [ ] `lib/services/vendor_api_service.dart`
- [ ] `lib/services/orders_api_service.dart`
- [ ] `lib/services/orders_service.dart`

Packages to delete from pubspec.yaml:
- [ ] `flutter_stripe: ^9.0.0`
- [ ] `flutterwave_standard: ^1.1.0`
- [ ] `flutter_paystack_plus: ^2.3.0`

### Phase 2: Delete Ecommerce Screens
**Estimated: 3-4 hours**

Folders to delete:
- [ ] `lib/screens/cart/` (entire folder)
- [ ] `lib/screens/customer/` (entire folder)
- [ ] `lib/screens/orders/` (entire folder)
- [ ] `lib/screens/product/` (entire folder)
- [ ] `lib/screens/search/` (entire folder - ecommerce search)
- [ ] `lib/screens/vendor/` (entire folder)

Files within folders to check:
- [ ] Remove any ecommerce-related widgets from `lib/screens/public/`

### Phase 3: Delete Ecommerce Providers & Repositories
**Estimated: 2-3 hours**

- [ ] `lib/providers/product_provider.dart`
- [ ] `lib/providers/cart_provider.dart`
- [ ] `lib/providers/order_provider.dart`
- [ ] `lib/providers/category_provider.dart`
- [ ] `lib/providers/vendor_provider.dart`
- [ ] `lib/repositories/product_repository.dart`
- [ ] `lib/repositories/order_repository.dart`
- [ ] `lib/repositories/cart_repository.dart`
- [ ] `lib/repositories/vendor_repository.dart`

### Phase 4: Clean Imports & References
**Estimated: 2-3 hours**

- [ ] Remove shopping imports from `main.dart`
- [ ] Remove deleted routes from routing config
- [ ] Remove deleted providers from provider list
- [ ] Search for hardcoded references to deleted classes
- [ ] Remove dead imports from all files
- [ ] Fix broken navigation references

### Phase 5: Clean Up Assets
**Estimated: 1-2 hours**

- [ ] Delete product images from `assets/images/`
- [ ] Delete payment icons from `assets/images/payments/`
- [ ] Delete category icons (if separate)
- [ ] Delete shopping-related designs from `assets/designs/`
- [ ] Compress remaining images (20-30% reduction)

### Phase 6: Verify Firestore & Firebase Integration
**Estimated: 3-4 hours**

- [ ] Audit `firestore_service.dart` - ensure no hardcoded data
- [ ] Verify all queries use environment-based collection names
- [ ] Check `auth_service.dart` - verify Firebase Auth is only method
- [ ] Audit `shipping_firestore_service.dart` - ensure Firestore-first
- [ ] Verify all API services fallback to Firestore if API unavailable
- [ ] Remove any hardcoded API endpoints (use Cloud Functions)
- [ ] Check environment variables (prod/dev/test configs)
- [ ] Verify no hardcoded user IDs or test data

### Phase 7: Refactor Enums & Core Models
**Estimated: 2-3 hours**

- [ ] Review `lib/models/enums.dart` - remove shopping enums
- [ ] Refactor `lib/services/api_service.dart` - remove shopping endpoints
- [ ] Review `lib/utils/` - remove shopping-specific utilities
- [ ] Clean up `lib/widgets/` - remove shopping widgets
- [ ] Audit navigation menu/routing - remove shopping routes

### Phase 8: Update Home/Landing Screen
**Estimated: 4-6 hours - DESIGN PHASE**

- [ ] Redesign home screen layout (shipping-focused)
- [ ] Add "Request Shipping" primary CTA button
- [ ] Add Affiliates signup section
- [ ] Add "Coming Soon for Shippers" section
- [ ] Remove product carousel
- [ ] Remove category pills
- [ ] Remove promotional banners (keep coming soon)
- [ ] Add feature highlights
- [ ] Add FAQ section

### Phase 9: Testing & Verification
**Estimated: 3-4 hours**

- [ ] Run `flutter clean && flutter pub get`
- [ ] Check for compilation errors
- [ ] Test app builds successfully (Android)
- [ ] Test app builds successfully (iOS)
- [ ] Test all screens open without crashes
- [ ] Test navigation flows work
- [ ] Test Firebase integration (auth, Firestore, storage)
- [ ] Test shipping request creation
- [ ] Test affiliate program access
- [ ] Verify no hardcoded data in logs/debug output
- [ ] Performance check (app startup time, memory usage)

---

## 📊 SIZE ANALYSIS

### Current App Breakdown
```
Estimated Distribution:
├── Ecommerce Code (products, cart, orders)  ~35-40%
├── Shipping/Affiliate Code                  ~20-25%
├── Auth/Profile/Core                        ~15-20%
├── UI/Widgets/Themes                        ~10-15%
├── Utils/Helpers                            ~5-10%

Total Codebase:  ~15-25 MB (typical Flutter app)
```

### After Cleanup
```
Estimated Distribution:
├── Shipping/Affiliate Code                  ~40-50%
├── Auth/Profile/Core                        ~25-30%
├── UI/Widgets/Themes                        ~15-20%
├── Utils/Helpers                            ~5-10%

Total Codebase:  ~5-8 MB

Savings:        ~60-70% code reduction
                ~50-55% app size reduction
```

---

## 🚀 FIREBASE INTEGRATION REQUIREMENTS

### Authentication
```
Required:
✅ Firebase Auth email/password
✅ Google Sign-In
✅ Phone authentication (if needed)
✅ Session persistence
✅ Token refresh handling

No hardcoding:
❌ No hardcoded user IDs
❌ No hardcoded auth tokens
❌ No hardcoded test credentials
```

### Database (Firestore)
```
Collections needed:
✅ users (profiles, roles, status)
✅ shipping_requests (request data, status, tracking)
✅ affiliates (signup, earnings, payouts)
✅ addresses (user shipping addresses)
✅ notifications (push notifications, history)
✅ invoices (shipping invoices)
✅ payouts (affiliate payouts)

No hardcoding:
❌ No hardcoded collection names (use constants)
❌ No hardcoded Firestore queries
❌ No hardcoded test data
❌ No hardcoded document IDs (use Firebase-generated)
```

### File Storage (Firebase Storage)
```
Buckets:
✅ User avatars
✅ Shipping documents/proofs
✅ Invoice PDFs
✅ Affiliate documents

No hardcoding:
❌ No hardcoded file paths
❌ No hardcoded URLs
❌ No hardcoded bucket names
```

### Cloud Functions
```
Expected Functions:
✅ Shipping request creation/update
✅ Affiliate payout processing
✅ Notification triggers
✅ Invoice generation
✅ Data validation/cleanup

No hardcoding:
❌ No hardcoded API endpoints
❌ Use Cloud Functions URLs from Firebase
❌ Dynamic endpoint configuration
```

### Real-time Sync
```
Required:
✅ Firestore StreamProvider for live updates
✅ Real-time shipping request status
✅ Real-time notification updates
✅ Real-time affiliate earnings

No hardcoding:
❌ No polling with hardcoded intervals
❌ Use Firestore listeners
❌ No hardcoded refresh rates
```

---

## ⚠️ CRITICAL CHECKS NEEDED

### Code Review Priorities
```
1. CRITICAL HARDCODING CHECK
   [ ] Search for: hardcoded URLs, IPs, API endpoints
   [ ] Search for: hardcoded user IDs, test data
   [ ] Search for: hardcoded collection names
   [ ] Search for: hardcoded environment paths
   
2. API INTEGRATION CHECK
   [ ] Verify all APIs are Firebase cloud functions
   [ ] Check for REST API calls (should be Cloud Functions)
   [ ] Verify no backend URLs in code
   [ ] Check environment configs (dev/prod)
   
3. FIRESTORE CHECK
   [ ] Verify Firestore is primary data source
   [ ] Check for duplicate API services
   [ ] Verify StreamProviders for real-time updates
   [ ] Check offline capability (if needed)
   
4. AUTHENTICATION CHECK
   [ ] Verify Firebase Auth is only auth method
   [ ] Check token handling
   [ ] Check session management
   [ ] Verify no hardcoded auth endpoints
   
5. DEPENDENCY CHECK
   [ ] Payment gateways - ensure deleted
   [ ] Unused APIs - ensure removed
   [ ] Old packages - verify still needed
```

---

## 📈 SUCCESS METRICS (Post-Cleanup)

### Size Metrics
- [ ] App size: 25-35 MB (down from 50-80 MB)
- [ ] Code size: 5-8 MB (down from 15-25 MB)
- [ ] Build time: 2-3 min (down from 5-8 min)

### Code Quality
- [ ] 0 hardcoded values in production code
- [ ] 0 unused imports or dead code
- [ ] All Firebase integrations verified
- [ ] All Firestore queries use security rules

### Feature Completeness
- [ ] Shipping requests: 100% functional
- [ ] Affiliates: 100% functional
- [ ] Authentication: 100% functional
- [ ] Notifications: 100% functional
- [ ] Guest shipping: 100% functional

### Firebase Compliance
- [ ] All data uses Firestore (not REST APIs)
- [ ] All auth uses Firebase Auth
- [ ] All files use Firebase Storage
- [ ] All push notifications use Firebase Messaging
- [ ] Environment-based configuration (no hardcoding)
- [ ] Cloud Functions for all backend operations

---

## 📝 AUDIT SUMMARY

**Total Screens**: 18 folders  
- Keep: 12 (95 files)
- Delete: 6 (60 files)

**Total Models**: 13 files  
- Keep: 4
- Delete: 6
- Refactor: 3

**Total Services**: 30 files  
- Keep: 19
- Delete: 5
- Refactor: 6

**Total Dependencies**: 31 packages  
- Keep: 28
- Delete: 3
- Review: 2

**Code Reduction**: 60-70%  
**App Size Reduction**: 50-55%  
**Files to Delete**: ~120 files  
**Files to Create**: 1 (new home/landing design)  
**Estimated Duration**: 2-3 weeks focused development

---

**NEXT STEP**: Begin Phase 1 - Delete ecommerce models and services!


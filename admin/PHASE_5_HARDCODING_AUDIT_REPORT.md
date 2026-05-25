# 🔐 PHASE 5: FIREBASE HARDCODING AUDIT REPORT

**Date**: January 31, 2026  
**Status**: 🚨 HARDCODING FOUND - NEEDS REMEDIATION  
**Critical Findings**: 15+ instances of hardcoded values  
**Severity**: MEDIUM-HIGH  

---

## 📊 AUDIT SUMMARY

| Category | Count | Status | Notes |
|----------|-------|--------|-------|
| API Endpoints | 6 | 🔴 NEEDS FIX | Legacy ecommerce endpoints, some already deleted |
| Firestore Collections | 12+ | 🔴 NEEDS FIX | Hardcoded in quotes, should be in constants |
| Hardcoded URLs | 8 | 🟡 MIXED | Placeholder/social/internal URLs - need review |
| Storage Keys | 4 | 🟢 GOOD | Storage service constants - acceptable |
| Configuration | 2 | 🔴 NEEDS FIX | Project ID and storage bucket hardcoded |

**Overall Status**: 🟠 **REQUIRES REMEDIATION BEFORE PRODUCTION**

---

## 🔴 CRITICAL FINDINGS

### 1. API Configuration (HIGHEST PRIORITY)

**File**: [lib/utils/api_config.dart](lib/utils/api_config.dart)

**Current Code**:
```dart
static const String apiVersion = 'v1';
static const String localhostHost = 'localhost:3001';
static const String awsHost = 'marketplace-api-alb-1242236330.us-east-1.elb.amazonaws.com';

static String get baseUrl =>
    isDevelopment
        ? 'http://$localhostHost/api/$apiVersion'
        : 'http://$awsHost/api/$apiVersion';

static String get baseUrlWithoutApi =>
    isDevelopment ? 'http://$localhostHost' : 'http://$awsHost';
```

**Issues**:
- ❌ Hardcoded REST API endpoints (CRITICAL for ecommerce - now mostly deleted)
- ❌ AWS ALB DNS hardcoded (should be environment variable)
- ❌ Development localhost mixed with production

**Why It's Wrong**:
```
We deleted all ecommerce code but left the API config pointing to it!
This is dead code now - should be removed or migrated to Firebase Functions.
```

**Action Required**: 
```
DELETE entire file - it's for the deleted REST API endpoints.
Replace with Firebase Cloud Functions calls instead.
```

**Deliverable**: Remove api_config.dart completely

---

### 2. Firestore Collection Hardcoding (HIGH PRIORITY)

**Findings**:

**a) orders_service.dart**
```dart
.collection('orders')  // ❌ HARDCODED
```

**b) firestore_service.dart**
```dart
.collection('news')     // ❌ HARDCODED
.collection('products') // ❌ HARDCODED (already deleted from schema)
```

**c) content_service.dart**
```dart
.collection('categories')  // ❌ HARDCODED (already deleted)
.collection('products')    // ❌ HARDCODED (already deleted)
.collection('banners')     // ❌ HARDCODED
```

**d) affiliate_api.dart**
```dart
.collection('shipment_requests')  // ❌ HARDCODED
```

**e) verify/shipper_verification_screen.dart**
```dart
.collection('shipper_verifications')  // ❌ HARDCODED
.collection('admin_notifications')   // ❌ HARDCODED
```

**f) shipping_firestore_service.dart**
```dart
static const String _collectionName = 'shippingRequests';  // ✅ GOOD (but inconsistent naming)
```

**Issues**:
- ❌ Collection names scattered throughout codebase
- ❌ Inconsistent naming (camelCase vs snake_case)
- ❌ Hard to maintain across multiple files
- ❌ Difficult to rename if schema changes

**Why It's Wrong**:
```
If Firestore schema changes (rename collection), must update every .dart file.
Also, no single source of truth for collection structure.
```

**Action Required**: 
```
1. Create lib/config/firestore_constants.dart
2. Move ALL collection names to this file
3. Replace all hardcoded strings with constants
4. Example: .collection(FirestoreConstants.shipmentRequests)
```

**Deliverable**: firestore_constants.dart with all collections defined

---

### 3. Firebase Project ID (HIGH PRIORITY)

**File**: [lib/utils/api_config.dart](lib/utils/api_config.dart)

**Current Code**:
```dart
static const String projectId = 'shopsnports';
static const String storageBucket = '$projectId.appspot.com';
```

**Issues**:
- ❌ Project ID is hardcoded (should be from Firebase config)
- ❌ No distinction between dev/prod projects
- ❌ Will fail if Firebase project name changes

**Why It's Wrong**:
```
We have DIFFERENT Firebase projects for dev and prod:
- Dev: shopsnports-dev
- Prod: shopsnports (or different)

Current code can't differentiate.
```

**Action Required**: 
```
1. Create lib/config/firebase_config.dart
2. Set up environment-based project selection
3. Use FirebaseOptions.currentPlatform for initialization
4. Remove hardcoded project ID from api_config.dart
```

**Deliverable**: firebase_config.dart with dev/prod project IDs

---

### 4. REST API Endpoints in Services (MEDIUM PRIORITY)

**File**: [lib/widgets/create_shipment_modal.dart](lib/widgets/create_shipment_modal.dart)

**Current Code**:
```dart
resp = await api.createShipmentOnBehalf(...)
url = await api.createShipmentLink(affiliateId: ...)
```

**Issues**:
- ⚠️  API calls to `api` service (need to verify if Firebase-based)
- ⚠️  Check if these are REST or Cloud Functions

**Action Required**: 
```
Verify that these calls:
1. Use Cloud Functions (httpsCallable)
2. OR are migrated to Firestore
3. Check affiliate_api.dart implementation
```

---

### 5. Legacy Endpoints (DELETE - MEDIUM PRIORITY)

**Files Found**:

**a) lib/screens/backend_test_screen.dart**
```
_status = 'Testing products API...'
```
Status: ⚠️ **Testing screen - DELETE if no longer used**

**b) lib/utils/api_config.dart**
```
static const String paystackCredentials = '/paystack/credentials';
static const String paystackInitialize = '/paystack/initialize';
static const String stripePublishableKey = '/stripe/publishable-key';
static const String flutterwavePublicKey = '/flutterwave/public-key';
```
Status: 🔴 **DELETE - Payment gateways removed in Phase 1**

**c) admin_flutter deprecated code**
```
'http://localhost:3000/admin/users?limit=...'
'http://marketplace-api-alb-1242236330.us-east-1.elb.amazonaws.com/api/v1/admin/login'
```
Status: 🔴 **DELETE - Separate admin app, not part of mobile**

---

### 6. Social/External URLs (REVIEW - MEDIUM PRIORITY)

**Files**: main_scaffold.dart, help_center_screen.dart

**Current Code**:
```dart
final uri = Uri.parse('https://facebook.com');
final uri = Uri.parse('https://twitter.com');
final uri = Uri.parse('https://instagram.com');
final uri = Uri.parse('https://wa.me/$whatsappNumber');
final uri = Uri.parse('https://example.com/faq');
```

**Issues**:
- ⚠️ Social media URLs are fine (external links)
- ⚠️ 'https://example.com' placeholder needs real FAQ URL
- ⚠️ WhatsApp URL needs to be configurable (not hardcoded number)

**Action Required**: 
```
1. Create lib/config/external_links_config.dart
2. Move FAQ URL to config (not 'example.com')
3. Move WhatsApp number to environment config
4. Store in Firestore or env variables for easy updates
```

---

### 7. Placeholder Images (LOW PRIORITY - ACCEPTABLE)

**Current Code**:
```dart
'https://via.placeholder.com/1200x400/4CAF50/FFFFFF?text=Welcome+Banner'
'https://via.placeholder.com/1200x400/FF5722/FFFFFF?text=Flash+Sale'
'https://example.com/welcome.jpg'
'https://example.com/flash-sale.jpg'
```

**Status**: 🟡 **ACCEPTABLE** - These are test/placeholder images
- Will be replaced with Firebase Storage URLs in Firestore
- Not a security issue

---

## ✅ WHAT'S GOOD

### Well-Structured Hardcoding

**✅ Storage Service Constants**
```dart
static const String _authTokenKey = 'auth_token';
static const String _refreshTokenKey = 'refresh_token';
static const String _userIdKey = 'user_id';
static const String _apiKeyKey = 'api_key';
```
Status: ✅ GOOD - Local storage keys don't need to be configurable

---

**✅ Firebase Usage**
```dart
final db = FirebaseFirestore.instance;
final auth = FirebaseAuth.instance;
```
Status: ✅ GOOD - Using Firebase services correctly

---

**✅ Navigation Routes**
```dart
static const routeName = '/wishlist';
static const routeName = '/vendor/products';
```
Status: ✅ GOOD - Route names should be constants

---

## 🛠️ REMEDIATION PLAN

### Priority 1 (CRITICAL - Must Fix Before Prod)

1. **Delete lib/utils/api_config.dart**
   - [ ] Remove file entirely
   - [ ] Update any imports (likely none since REST API deleted)
   - [ ] Verify Flutter build succeeds

2. **Create lib/config/firebase_config.dart**
   - [ ] Dev Firebase project ID: shopsnports-dev
   - [ ] Prod Firebase project ID: shopsnports
   - [ ] Firebase API keys from console
   - [ ] Storage bucket configuration
   - [ ] Environment detection

3. **Create lib/config/firestore_constants.dart**
   - [ ] Collection names (users, shipments, affiliates, etc.)
   - [ ] Field names (user_id, email, status, etc.)
   - [ ] Document path constants
   - [ ] Query constants

---

### Priority 2 (HIGH - Must Fix Before Prod)

4. **Update all Firestore calls**
   - [ ] orders_service.dart - use constants
   - [ ] firestore_service.dart - use constants  
   - [ ] content_service.dart - use constants
   - [ ] affiliate_api.dart - use constants
   - [ ] shipper_verification_screen.dart - use constants

5. **Create lib/config/external_links_config.dart**
   - [ ] FAQ URL (configurable, not example.com)
   - [ ] WhatsApp number (configurable)
   - [ ] Social media handles (configurable)
   - [ ] Store in Firestore for remote updates

---

### Priority 3 (MEDIUM - Should Fix Before Prod)

6. **Verify Cloud Functions Usage**
   - [ ] Check affiliate_api.dart implementation
   - [ ] Verify createShipmentLink uses Cloud Functions
   - [ ] Verify createShipmentOnBehalf uses Cloud Functions
   - [ ] Replace REST calls with httpsCallable if needed

---

## 📋 VERIFICATION CHECKLIST

After remediation, verify:

```
Firestore Collections:
- [ ] All .collection('...') replaced with constants
- [ ] No hardcoded collection names in quotes
- [ ] Consistent naming across app

Firebase Configuration:
- [ ] firebase_config.dart created
- [ ] Dev/prod Firebase projects defined
- [ ] Environment detection working
- [ ] No hardcoded project IDs in code

API Endpoints:
- [ ] api_config.dart deleted
- [ ] No REST API endpoints in mobile app
- [ ] All calls use Cloud Functions or Firestore
- [ ] No localhost URLs in code

External Links:
- [ ] FAQ URL in config file
- [ ] WhatsApp number in config
- [ ] Social media handles in config
- [ ] No hardcoded URLs (except social links)

Environment Variables:
- [ ] .env files created for dev/prod
- [ ] Build commands use --dart-define flags
- [ ] Production build has IS_PRODUCTION=true
```

---

## 🚀 NEXT STEPS

### Immediate (Next 30 minutes)
1. Read this report ✓
2. Review findings in context
3. Decide on remediation approach

### Short-term (Next 2-3 hours)
1. Create firebase_config.dart ← **START HERE**
2. Create firestore_constants.dart
3. Delete api_config.dart
4. Update all Firestore calls
5. Verify Flutter build

### Medium-term (Next 4-6 hours)
1. Create external_links_config.dart
2. Verify Cloud Functions usage
3. Test dev/prod environment switching
4. Document Firebase setup for team

---

## 📝 SUMMARY

| Task | Count | Effort | Impact |
|------|-------|--------|--------|
| Create firebase_config.dart | 1 | 30 min | Critical |
| Create firestore_constants.dart | 1 | 30 min | Critical |
| Delete api_config.dart | 1 | 5 min | Medium |
| Update Firestore calls | 5 files | 45 min | Critical |
| Create external_links_config.dart | 1 | 20 min | Medium |
| Verify Cloud Functions | 3 calls | 30 min | Critical |

**Total Effort**: ~3 hours

**Production Ready After**: ✅ Yes (after remediation)

---

## 🎯 SUCCESS CRITERIA

After Phase 5 remediation completes:

```
✅ api_config.dart deleted
✅ firebase_config.dart with dev/prod config
✅ firestore_constants.dart with all collections
✅ All .collection() calls use constants
✅ All API endpoints are Cloud Functions
✅ Zero hardcoded project IDs
✅ Zero hardcoded Firestore paths
✅ Environment variables properly configured
✅ Builds successfully for dev and prod
```

---

**Status**: 🚨 **REQUIRES REMEDIATION**  
**Estimated Completion**: 3-4 hours  
**Ready to Proceed**: YES - Start with Priority 1 tasks


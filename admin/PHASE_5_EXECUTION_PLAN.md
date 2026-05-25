# 🔐 PHASE 5: FIREBASE INTEGRATION AUDIT - EXECUTION PLAN

**Date**: January 31, 2026  
**Status**: 🚀 READY TO BEGIN  
**Scope**: Full Firebase hardcoding audit + config setup  
**Estimated Duration**: 3-4 hours  
**Critical**: ZERO HARDCODING ALLOWED  

---

## 🎯 PHASE 5 OBJECTIVES

### Objective 1: Audit for Hardcoded Values
```
CRITICAL: Every hardcoded value must be identified and replaced with:
  - Firebase configuration (for project IDs)
  - Environment variables (for deployment settings)
  - Firestore collections/documents (for data)
  - Cloud Functions calls (for operations)
  - Firebase Auth state (for user data)
```

### Objective 2: Verify Firebase-First Architecture
```
REQUIREMENT: All operations must flow through Firebase, NOT custom APIs

✅ ALLOWED:
  - FirebaseAuth.instance for authentication
  - FirebaseFirestore.instance for data
  - FirebaseStorage.instance for files
  - FirebaseFunctions for backend logic
  
❌ NOT ALLOWED:
  - REST API calls (except Cloud Functions)
  - Hardcoded backend URLs
  - Local data storage (except cache)
  - Custom authentication
```

### Objective 3: Set Up Environment Configs
```
REQUIREMENT: Separate dev/prod Firebase projects with proper config

DELIVERABLES:
  - lib/config/firebase_config.dart (with dev/prod selection)
  - Environment-based Firebase initialization
  - Development Firebase project setup
  - Production Firebase project setup
```

---

## 📋 AUDIT EXECUTION PLAN

### Step 1: Search for Hardcoded Values (30 minutes)

**Search Pattern 1: API Endpoints**
```bash
grep -r "http://" lib/
grep -r "https://" lib/
grep -r "api\." lib/
grep -r "\.com/" lib/
grep -r "localhost:" lib/
grep -r "127\.0\.0\.1" lib/
```

**Expected findings:**
- REST API endpoints (should be Cloud Functions only)
- Hardcoded URLs
- Backend service URLs

**Action:**
- Document all findings
- Identify which should be Cloud Functions
- Replace with dynamic values

---

**Search Pattern 2: User/Environment Hardcoding**
```bash
grep -r "const.*user" lib/
grep -r "const.*id.*=" lib/
grep -r "'user_" lib/
grep -r "\"user_" lib/
grep -r "admin_001" lib/
grep -r "test_" lib/
```

**Expected findings:**
- Hardcoded user IDs
- Hardcoded test data
- Hardcoded environment indicators

**Action:**
- Replace with auth state
- Use FirebaseAuth.instance.currentUser
- Remove test data

---

**Search Pattern 3: Firestore Collection Names**
```bash
grep -r "collection('" lib/
grep -r "collection(\"" lib/
grep -r "\.doc('" lib/
grep -r "\.doc(\"" lib/
```

**Expected findings:**
- Hardcoded collection names in quotes
- Should be in constants file

**Action:**
- Create constants file
- Move all collection names to constants
- Replace hardcoded strings with constants

---

**Search Pattern 4: Firebase Project/Config**
```bash
grep -r "PROJECT_ID" lib/
grep -r "project" lib/
grep -r "firebase_config" lib/
grep -r "dev\|prod" lib/
```

**Expected findings:**
- Project-specific configuration
- Environment-specific settings

**Action:**
- Create environment config file
- Set up dev/prod separation
- Document which is production

---

### Step 2: Create Firebase Configuration (1 hour)

**File 1: lib/config/firebase_config.dart**
```dart
class FirebaseConfig {
  // Development Firebase Project
  static const String devProjectId = 'shopsnports-dev';
  static const String devApiKey = '...from Firebase console...';
  
  // Production Firebase Project
  static const String prodProjectId = 'shopsnports-prod';
  static const String prodApiKey = '...from Firebase console...';
  
  // Current environment (set via build flag or env variable)
  static bool isProduction = const bool.fromEnvironment(
    'IS_PRODUCTION',
    defaultValue: false,
  );
  
  // Active project selection
  static String get activeProjectId =>
      isProduction ? prodProjectId : devProjectId;
}
```

**File 2: lib/utils/firebase_constants.dart**
```dart
class FirestoreCollections {
  static const String users = 'users';
  static const String shippingRequests = 'shipping_requests';
  static const String affiliates = 'affiliates';
  static const String addresses = 'addresses';
  static const String notifications = 'notifications';
  static const String invoices = 'invoices';
  static const String payouts = 'payouts';
  static const String activityLogs = 'activity_logs';
}

class FirestoreFields {
  // User fields
  static const String userId = 'user_id';
  static const String userEmail = 'email';
  static const String userName = 'name';
  // ... etc
}
```

**File 3: lib/main.dart Update**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with environment-specific config
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Log current environment (for debugging)
  debugPrint('Running in ${FirebaseConfig.isProduction ? 'PRODUCTION' : 'DEVELOPMENT'} mode');
  
  runApp(const MyApp());
}
```

---

### Step 3: Verify Firebase Services (1 hour)

**Check 1: Authentication Service**
```dart
// lib/services/auth_service.dart

✅ CORRECT:
Future<UserCredential> signInWithEmail(String email, String password) async {
  return await FirebaseAuth.instance.signInWithEmailAndPassword(
    email: email,
    password: password,
  );
}

❌ WRONG:
const String authUrl = 'https://api.example.com/auth';
final response = await http.post(Uri.parse(authUrl), body: {...});
```

---

**Check 2: Firestore Service**
```dart
// lib/services/firestore_service.dart

✅ CORRECT:
Future<DocumentSnapshot> getUser(String userId) async {
  return await FirebaseFirestore.instance
      .collection(FirestoreCollections.users)
      .doc(userId)
      .get();
}

❌ WRONG:
const String usersUrl = 'https://api.example.com/users';
final response = await http.get(Uri.parse('$usersUrl/$userId'));
```

---

**Check 3: Cloud Functions Usage**
```dart
// lib/services/shipping_api_service.dart

✅ CORRECT:
Future<ShippingQuote> getQuote(String from, String to) async {
  final callable = FirebaseFunctions.instance.httpsCallable('getShippingQuote');
  final result = await callable.call({
    'origin': from,
    'destination': to,
  });
  return ShippingQuote.fromJson(result.data);
}

❌ WRONG:
const String quotesUrl = 'https://api.example.com/shipping/quotes';
final response = await http.post(Uri.parse(quotesUrl), body: {...});
```

---

**Check 4: Storage Usage**
```dart
// lib/services/storage_service.dart

✅ CORRECT:
Future<void> uploadFile(File file, String userId) async {
  final ref = FirebaseStorage.instance
      .ref('users/$userId/documents/${file.path.split('/').last}');
  await ref.putFile(file);
}

❌ WRONG:
const String uploadUrl = 'https://api.example.com/upload';
// Don't upload to custom server
```

---

### Step 4: Set Up Environment Configs (30 minutes)

**Build Command for Development**
```bash
flutter run -d chrome
# Automatically uses development Firebase project
```

**Build Command for Production**
```bash
flutter run -d chrome --dart-define=IS_PRODUCTION=true
# Uses production Firebase project
```

**Deploy Command**
```bash
flutter build apk --release --dart-define=IS_PRODUCTION=true
flutter build appbundle --release --dart-define=IS_PRODUCTION=true
flutter build ios --release --dart-define=IS_PRODUCTION=true
```

---

### Step 5: Verify Firestore Security Rules (30 minutes)

**Required Rules Structure**
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own documents
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }
    
    // Shipping requests - user can read/write own
    match /shipping_requests/{requestId} {
      allow create: if request.auth != null;
      allow read, update, delete: if request.auth.uid == resource.data.user_id;
    }
    
    // Affiliates - user can read/write their own
    match /affiliates/{affiliateId} {
      allow create: if request.auth != null;
      allow read, update: if request.auth.uid == resource.data.user_id;
    }
  }
}
```

---

## ✅ VERIFICATION CHECKLIST

### API Endpoints Check
- [ ] No hardcoded REST API URLs in code
- [ ] All backend operations use Cloud Functions
- [ ] No `http.get()` or `http.post()` for business logic
- [ ] All API calls properly error-handled

### User/Auth Check
- [ ] No hardcoded user IDs
- [ ] No test credentials in code
- [ ] All auth via Firebase Auth
- [ ] User ID always from `FirebaseAuth.instance.currentUser`

### Firestore Check
- [ ] No hardcoded collection names (all in constants)
- [ ] All Firestore queries use constants
- [ ] No hardcoded document IDs
- [ ] StreamProvider used for real-time updates

### Configuration Check
- [ ] Firebase config file created
- [ ] Constants file created
- [ ] Dev/prod Firebase projects setup
- [ ] Environment selection working

### Service Check
- [ ] Auth service uses Firebase Auth only
- [ ] Database service uses Firestore only
- [ ] Storage service uses Firebase Storage only
- [ ] All backend ops use Cloud Functions

---

## 🚀 EXECUTION STEPS

### Now (Phase 5 Start)
1. Run comprehensive hardcoding search
2. Document all findings
3. Create firebase_config.dart
4. Create firebase_constants.dart
5. Update main.dart
6. Update all services

### Testing
1. Build dev version
2. Build prod version (with flag)
3. Run Flutter analyze
4. Verify no hardcoded values in logs

### Documentation
1. Create Firebase setup guide
2. Document cloud functions needed
3. Create environment setup instructions
4. Add deployment guide

---

## 📊 EXPECTED FINDINGS

### Typical Hardcoding Issues Found In Ecommerce Apps
```
Likely issues:
  - REST API endpoints for deleted services (now removed)
  - Hardcoded collection names scattered throughout code
  - Test user IDs in some files
  - Environment-specific URLs mixed in code
  
Good news:
  - Since we deleted all ecommerce code, less to audit
  - Focus now on shipping/affiliate features only
  - Fewer moving parts = easier to secure
```

---

## 📝 DELIVERABLES (After Phase 5)

- [x] Comprehensive hardcoding audit report
- [x] Firebase configuration files created
- [x] Constants file with all collection names
- [x] Verified all services use Firebase
- [x] Dev/prod environment setup complete
- [x] Firestore security rules documented
- [x] Zero hardcoded values in production code

---

## 🎯 SUCCESS CRITERIA

After Phase 5 completes:
```
✅ 0 hardcoded API endpoints in code
✅ 0 hardcoded user IDs or test data
✅ 0 hardcoded collection names (all in constants)
✅ 0 hardcoded Firebase config (all in env configs)
✅ All operations flow through Firebase
✅ Cloud Functions for all backend logic
✅ Dev/prod environments properly separated
✅ Ready for home screen redesign (Phase 6)
```

---

**Status**: 🚀 **READY TO BEGIN PHASE 5**  
**Next Action**: Start hardcoding search (Step 1)  
**Estimated Duration**: 3-4 hours  
**Critical**: Zero hardcoding allowed in final code


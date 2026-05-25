# 🔐 ShopsNPorts Firebase Integration Checklist

**Status**: Comprehensive Integration Verification Required  
**Scope**: Ensure NO hardcoded values, all data flows through Firebase/Firestore  
**Target**: 100% Firebase-native, zero REST API hardcoding  

---

## 🎯 HARDCODING AUDIT - CRITICAL ITEMS

### 1. API ENDPOINTS

**Search Pattern**: `http://`, `https://`, `api.`, `localhost:`, `.com/api`

**Items to Check**:
- [ ] `lib/services/api_service.dart` - Base API class
  - Verify: No hardcoded base URLs
  - Verify: All endpoints are Cloud Functions calls
  - Verify: Environment-based endpoint configuration
  
- [ ] `lib/services/affiliate_api_service.dart`
  - Verify: Affiliate operations use Firestore (not REST)
  - Verify: Payout processing uses Cloud Functions
  
- [ ] `lib/services/shipping_api_service.dart`
  - Verify: Shipping operations use Firestore (not REST)
  - Verify: Quote calculation uses Cloud Functions
  
- [ ] Any other `*_api_service.dart` files
  - Verify: Deleted if ecommerce
  - Verify: Migrated to Firestore if core feature

**Required Changes**:
```dart
❌ WRONG:
const String baseUrl = 'https://api.example.com';
final response = await http.get(Uri.parse('$baseUrl/products'));

✅ RIGHT:
// Use Cloud Functions
final response = await FirebaseFunctions.instance
    .httpsCallable('getShippingQuote')
    .call({'origin': origin, 'destination': destination});

// Or use Firestore directly
final doc = await FirebaseFirestore.instance
    .collection('shipping_requests')
    .doc(id)
    .get();
```

---

### 2. USER IDS & AUTHENTICATION

**Search Pattern**: `'admin_001'`, `'user_'`, hardcoded `uid:`, `userId =`

**Items to Check**:
- [ ] `lib/services/auth_service.dart`
  - Verify: All auth comes from `FirebaseAuth.instance.currentUser`
  - Verify: No hardcoded test credentials
  - Verify: Token refresh is automatic
  
- [ ] `lib/models/user.dart`
  - Verify: User ID comes from Firebase Auth
  - Verify: No default/test user IDs
  
- [ ] `lib/providers/auth_provider.dart`
  - Verify: Uses `FirebaseAuth` state
  - Verify: No hardcoded user data
  
- [ ] All screen constructors
  - Verify: User ID fetched from auth state, not hardcoded
  - Search for patterns like: `.get('/:userId')`, `'/profile/$userId'`

**Required Changes**:
```dart
❌ WRONG:
const String currentUserId = 'user_12345'; // HARDCODED!

✅ RIGHT:
final user = FirebaseAuth.instance.currentUser;
final userId = user?.uid;
```

---

### 3. FIRESTORE COLLECTION NAMES

**Search Pattern**: `collection(`, `.doc(`, `'users'`, `'shipping_requests'`

**Items to Check**:
- [ ] `lib/services/firestore_service.dart`
  - Verify: Collection names are in constants file
  - Verify: No string literals scattered in code
  - Verify: All queries use `FirebaseFirestore.instance`
  
- [ ] `lib/utils/constants.dart` (or similar)
  - Should contain: All Firestore collection names
  - Should contain: All document reference paths
  
- [ ] `lib/models/` - All model files
  - Verify: No hardcoded collection names in models
  - Verify: Models use generic field names (not hardcoded to specific collections)

**Required Constants File**:
```dart
// lib/utils/firebase_constants.dart

class FirestoreCollections {
  static const String users = 'users';
  static const String shippingRequests = 'shipping_requests';
  static const String affiliates = 'affiliates';
  static const String addresses = 'addresses';
  static const String notifications = 'notifications';
  static const String invoices = 'invoices';
  static const String payouts = 'payouts';
  static const String activity_logs = 'activity_logs';
}

class FirestoreFields {
  // Users collection
  static const String userId = 'user_id';
  static const String userEmail = 'email';
  static const String userName = 'name';
  // ... etc
}
```

**Required Changes**:
```dart
❌ WRONG:
final users = await FirebaseFirestore.instance
    .collection('users')  // String literal!
    .doc(userId)
    .get();

✅ RIGHT:
final users = await FirebaseFirestore.instance
    .collection(FirestoreCollections.users)  // Constant!
    .doc(userId)
    .get();
```

---

### 4. FIRESTORE QUERIES & PATHS

**Search Pattern**: `collection(`, `.where(`, `.orderBy(`, `snapshot.docs`

**Items to Check**:
- [ ] `lib/repositories/shipping_repository.dart`
  - Verify: All queries against Firestore collections
  - Verify: No hardcoded query limits/pagination
  - Verify: Uses StreamProvider for real-time updates
  
- [ ] `lib/repositories/affiliate_repository.dart`
  - Verify: Affiliate data from Firestore only
  - Verify: Payout queries correct
  
- [ ] `lib/services/shipping_firestore_service.dart`
  - Verify: Shipping-specific Firestore operations
  - Verify: No REST API calls
  
- [ ] All other repositories
  - Verify: Deleted if ecommerce
  - Verify: Using Firestore if core feature

**Required Changes**:
```dart
❌ WRONG:
// Hardcoded limit and no streaming
final docs = await FirebaseFirestore.instance
    .collection('shipping_requests')
    .limit(10)  // Hardcoded
    .get();

✅ RIGHT:
// Use StreamProvider for real-time updates
final shippingRequestsProvider = StreamProvider<List<ShippingRequest>>((ref) {
  return FirebaseFirestore.instance
      .collection(FirestoreCollections.shippingRequests)
      .where('user_id', isEqualTo: userId)
      .orderBy('created_at', descending: true)
      .limit(pageSize)  // Use variable
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => ShippingRequest.fromFirestore(doc))
          .toList());
});
```

---

### 5. FIREBASE STORAGE PATHS

**Search Pattern**: `FirebaseStorage`, `getBytes`, `putFile`, `ref.child(`

**Items to Check**:
- [ ] `lib/services/storage_service.dart`
  - Verify: All upload/download through Firebase Storage
  - Verify: No hardcoded file paths
  - Verify: Uses environment-based bucket paths
  
- [ ] Image upload screens
  - Verify: Images stored in Firebase Storage
  - Verify: URLs stored in Firestore documents
  - Verify: No base64 encoding (use Storage references)

**Required Changes**:
```dart
❌ WRONG:
final ref = FirebaseStorage.instance.ref('uploads/user_123/image.jpg');

✅ RIGHT:
final userId = FirebaseAuth.instance.currentUser?.uid;
final timestamp = DateTime.now().millisecondsSinceEpoch;
final ref = FirebaseStorage.instance
    .ref('users/$userId/documents/invoice_$timestamp.pdf');
```

---

### 6. CLOUD FUNCTIONS CALLS

**Search Pattern**: `httpsCallable(`, `CloudFunctions`, `functions.`

**Items to Check**:
- [ ] All backend operations should use Cloud Functions
  - Shipping quote calculation
  - Affiliate payout processing
  - Invoice generation
  - Email notifications
  - Data cleanup/validation

**Required Functions**:
```
- getShippingQuote(origin, destination)
- createShippingRequest(requestData)
- updateShippingStatus(requestId, newStatus)
- processAffiliatePayouts()
- generateInvoice(requestId)
- sendNotification(userId, message)
- validateAndCleanData()
```

**Implementation Pattern**:
```dart
✅ RIGHT - Cloud Function call:
Future<ShippingQuote> getShippingQuote({
  required String origin,
  required String destination,
}) async {
  try {
    final callable = FirebaseFunctions.instance.httpsCallable('getShippingQuote');
    final result = await callable.call({
      'origin': origin,
      'destination': destination,
    });
    return ShippingQuote.fromJson(result.data);
  } catch (e) {
    throw ShippingException('Failed to get quote: $e');
  }
}
```

---

### 7. ENVIRONMENT CONFIGURATION

**Search Pattern**: `const String`, `build.gradle`, `Info.plist`, environment vars

**Items to Check**:
- [ ] Create `lib/config/firebase_config.dart`
  - Development Firebase project
  - Production Firebase project
  - Staging Firebase project (if needed)
  
- [ ] `lib/main.dart`
  - Verify: Firebase initialized based on environment
  - Verify: No hardcoded project IDs
  
- [ ] Android/iOS native configs
  - Verify: `google-services.json` uses environment-based config
  - Verify: `GoogleService-Info.plist` uses environment-based config

**Required Config Structure**:
```dart
// lib/config/firebase_config.dart

class FirebaseConfig {
  static const String _devProjectId = 'shopsnports-dev';
  static const String _prodProjectId = 'shopsnports-prod';
  
  static const bool isProduction = bool.fromEnvironment('IS_PRODUCTION', defaultValue: false);
  
  static String get projectId => isProduction ? _prodProjectId : _devProjectId;
}

// Usage in main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize based on environment
  await Firebase.initializeApp(
    options: isProduction 
        ? DefaultFirebaseOptions.currentPlatform
        : DefaultFirebaseOptions.currentPlatform, // Dev config
  );
  
  runApp(const MyApp());
}
```

---

### 8. NOTIFICATION HANDLING

**Search Pattern**: `push_notification`, `notification_service`, `onMessage`, `onMessageOpenedApp`

**Items to Check**:
- [ ] `lib/services/push_notification_service.dart`
  - Verify: Uses Firebase Messaging only
  - Verify: No hardcoded topic subscriptions
  - Verify: Handles notification payload from Firestore
  
- [ ] Token management
  - Verify: Device tokens stored in Firestore `users` collection
  - Verify: Token refresh handled automatically
  
- [ ] Notification payload
  - Verify: All notification data from Firestore or Cloud Functions
  - Verify: No hardcoded notification messages

**Required Implementation**:
```dart
✅ RIGHT - Firebase Messaging:
Future<void> initNotifications() async {
  // Request permission
  await messaging.requestPermission();
  
  // Get and store device token
  final token = await messaging.getToken();
  if (token != null) {
    await _storeDeviceToken(token);
  }
  
  // Listen to messages
  FirebaseMessaging.onMessage.listen((message) {
    _handleNotification(message);
  });
  
  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    _navigateFromNotification(message);
  });
}

Future<void> _storeDeviceToken(String token) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId != null) {
    await FirebaseFirestore.instance
        .collection(FirestoreCollections.users)
        .doc(userId)
        .update({'device_token': token});
  }
}
```

---

### 9. SECURITY RULES & DATA ACCESS

**Items to Check**:
- [ ] Firestore Security Rules are configured
  - Verify: Users can only read/write their own data
  - Verify: Admins can access all data
  - Verify: Public collections (if any) properly scoped
  
- [ ] Firebase Storage Rules are configured
  - Verify: Users can only access their own files
  - Verify: File size limits enforced
  - Verify: File type restrictions
  
- [ ] Cloud Functions authentication
  - Verify: All functions check `context.auth`
  - Verify: User can only modify own documents

**Example Security Rules**:
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
    
    // Affiliates - users can read/write their own
    match /affiliates/{affiliateId} {
      allow create: if request.auth != null;
      allow read, update: if request.auth.uid == resource.data.user_id;
    }
  }
}
```

---

### 10. LOGGING & DEBUG OUTPUT

**Search Pattern**: `print(`, `debugPrint(`, `log(`, `console.log`

**Items to Check**:
- [ ] No sensitive data in logs
  - Verify: No user IDs in logs (use last 4 chars only if needed)
  - Verify: No tokens in logs
  - Verify: No passwords in logs
  - Verify: No Firebase project IDs in logs
  
- [ ] Firebase Crashlytics configuration
  - Verify: Errors sent to Firebase
  - Verify: No sensitive data in crash reports
  
- [ ] Analytics events
  - Verify: Events don't contain sensitive data
  - Verify: User IDs not tracked (use anonymized identifiers)

---

## ✅ VERIFICATION CHECKLIST

### Phase 1: Code Search & Audit
- [ ] Search entire codebase for `http://` or `https://` (excluding comments)
- [ ] Search for hardcoded user IDs like `'user_'`, `'admin_'`
- [ ] Search for hardcoded API endpoints
- [ ] Search for hardcoded collection names (should use constants)
- [ ] Search for hardcoded test data
- [ ] Search for `localhost:` or `127.0.0.1`

### Phase 2: Firebase Services Review
- [ ] Review `auth_service.dart` - verify Firebase Auth only
- [ ] Review `firestore_service.dart` - verify abstraction layer
- [ ] Review `storage_service.dart` - verify Storage usage
- [ ] Review all `*_api_service.dart` - ensure using Cloud Functions, not REST
- [ ] Check for API keys in code (should be in Firebase config)

### Phase 3: Provider & Repository Audit
- [ ] All providers use Firestore for data
- [ ] All repositories use Firestore queries
- [ ] StreamProvider used for real-time updates
- [ ] Pagination handled properly (not hardcoded limits)
- [ ] No duplicate data sources

### Phase 4: Screen & Widget Verification
- [ ] No hardcoded user data in screens
- [ ] Navigation uses environment-based routes
- [ ] Forms submit to Firestore/Cloud Functions
- [ ] No test/mock data in production screens
- [ ] All API calls use proper error handling

### Phase 5: Configuration & Deployment
- [ ] Create `lib/config/` folder with environment configs
- [ ] Set up dev/prod Firebase projects
- [ ] Configure `google-services.json` for both environments
- [ ] Configure `GoogleService-Info.plist` for both environments
- [ ] Document environment setup for team

### Phase 6: Testing & Validation
- [ ] Unit tests use fake Firebase for isolation
- [ ] Integration tests use dev Firebase project
- [ ] No hardcoded data in test fixtures
- [ ] Performance tests verify Firestore efficiency
- [ ] Network throttling tests verify offline behavior

---

## 📋 FINAL CHECKLIST BEFORE DEPLOYMENT

### Pre-Production
- [ ] All hardcoded values removed
- [ ] All APIs use Cloud Functions
- [ ] All data in Firestore (not local/hardcoded)
- [ ] Firebase Security Rules applied
- [ ] Environment configuration complete
- [ ] No test/mock data in code
- [ ] Crashlytics configured
- [ ] Analytics events configured
- [ ] Push notifications working
- [ ] All Firebase services initialized properly

### Production
- [ ] Separate production Firebase project created
- [ ] Database replication verified
- [ ] Backups enabled
- [ ] Monitoring and alerts set up
- [ ] Rate limiting configured
- [ ] Cost monitoring enabled
- [ ] Documentation complete
- [ ] Team trained on Firebase integration
- [ ] Rollback plan in place

---

**IMPORTANT**: Every single hardcoded value removed during cleanup must be replaced with:
1. Firebase configuration (for project IDs, etc.)
2. Environment variables (for dev/prod)
3. Firestore collections/documents (for data)
4. Cloud Functions calls (for operations)
5. Firebase Auth state (for user data)

**NO EXCEPTIONS**


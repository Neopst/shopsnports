# 🔔 FCM INTEGRATION & ADMIN REAL-TIME VERIFICATION GUIDE

**Date:** March 3, 2026  
**Status:** ⚠️ VERIFICATION REQUIRED  
**Priority:** 🔴 CRITICAL

---

## 📱 FCM INTEGRATION - VERIFICATION CHECKLIST

### Step 1: Check FCM Token Generation in Mobile App

**Expected Behavior:**
- App initializes Firebase Messaging on startup
- FCM token is generated automatically
- Token is saved to Firestore at: `users/{userId}/fcmTokens` (array)

**How to Verify:**

**Option A: Check Firestore Console**
```
1. Go to Firebase Console: console.firebase.google.com
2. Select Project: shopsnports
3. Firestore Database → Collections
4. Open "users" collection
5. Click on a user document
6. Look for field: "fcmTokens" (should be array)
7. Should contain 1+ token strings (long alphanumeric)

Expected: ✅ fcmTokens array with tokens
If missing: ❌ Token not being saved
```

**Option B: Check Mobile App Logs**
```
Flutter Console Output:

Look for:
✅ "FCM token: eyJhbGciOiJSUzI1NiIsInR5..." (token appears)
or
❌ "FCM token Error: PlatformException..."

Steps:
1. Run app: flutter run
2. Watch console for "FCM token" message
3. If not found, FCM token generation failed
```

**Option C: Check NotificationService Initialization**
```
File: lib/services/notification_service.dart

Current Code (Line 31-44):
```dart
Future<void> init() async {
  try {
    // Request permissions where necessary
    await _messaging.requestPermission(
        alert: true, badge: true, sound: true);
    
    // ... TLS code ...
    
    if (kDebugMode) {
      try {
        final token = await _messaging.getToken();
        AppLogger.debug('FCM token', token);  // ← Token logged here
      } catch (e) {
        // ignore token failures in debug
      }
    }
  }
}
```

**ISSUE FOUND:** ❌ Token is only logged in debug mode, not saved to Firestore!

---

### Step 2: Critical Issue - FCM Token Not Saved to Firestore

**Problem:**
```
Current Code:
- Requests FCM token ✅
- Logs token to console ✅
- Does NOT save to Firestore ❌

Result:
- Cloud Functions can't target notifications to specific users
- Can only send notifications to topic (admins, affiliates)
- Can't send personal notifications to individual users
```

**Fix Required:**

```dart
// After line 43 in notification_service.dart, add:
if (kDebugMode) {
  try {
    final token = await _messaging.getToken();
    AppLogger.debug('FCM token', token);
    
    // ✅ ADD THIS: Save token to Firestore
    if (token != null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'fcmTokens': FieldValue.arrayUnion([token])
            });
        AppLogger.debug('✅ FCM token saved to Firestore', token);
      }
    }
  } catch (e) {
    AppLogger.error('FCM token save error', e);
  }
}
```

---

### Step 3: Check Background Message Handler

**Expected Behavior:**
- When app is in background and notification arrives
- Notification shown in system tray
- User taps notification → App opens
- App navigates to correct screen (shipping detail)

**Current Implementation Status:**

```dart
// File: lib/services/notification_service.dart
// Lines 43-50: onMessage handler (FOREGROUND - working ✅)

FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  try {
    _showForegroundNotification(message);  // Shows dialog in app ✅
  } catch (e) {
    AppLogger.error('onMessage handling error', e);
  }
});
```

**ISSUE FOUND:** ❌ Missing handler for `onMessageOpenedApp` (background taps)

**What's Missing:**
```dart
// ADD THIS (not found in current code):

// Handle notifications when app opened from background
FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  // Parse request ID from notification data
  final requestId = message.data['requestId'];
  
  // Navigate to shipping detail screen
  if (requestId != null) {
    navigatorKey.currentState?.pushNamed(
      '/shipping-detail',
      arguments: requestId,
    );
  }
});
```

---

### Step 4: Check FCM Permissions

**Expected Behavior:**
- iOS: User grants notification permission
- Android: Permission granted automatically (on 12+)
- Web: Browser shows permission prompt

**How to Verify:**

**iOS:**
```
Settings App → ShopsNPorts → Notifications
Expected: ✅ "Allow Notifications" is ON
If OFF: ❌ User won't receive notifications
```

**Android:**
```
Settings App → Apps → ShopsNPorts → Permissions
Expected: ✅ "Notifications" permission granted
If not: ❌ Notifications blocked
```

**In-App Check:**
```dart
// Test by adding to app
final settings = await FirebaseMessaging.instance.getNotificationSettings();
print('Permission status: ${settings.authorizationStatus}');

// Should print: 
// AuthorizationStatus.authorized (✅)
// or AuthorizationStatus.denied (❌)
```

---

### Step 5: Test FCM Notification Flow

**Manual Test Procedure:**

**Prerequisites:**
- Mobile app installed and running
- User logged in
- Firestore has user document

**Test Steps:**

```
1. Open Mobile App
   - Keep app open (FOREGROUND TEST)
   - Trigger a request with: flutter run

2. In separate window, create shipping request via admin or form
   - Go to: http://localhost:3000/admin (or similar)
   - Create new shipping request
   
3. Watch Mobile App
   Expected: ✅ Dialog appears with notification
   If fails: ❌ No dialog shown

4. Close Mobile App to background
   - Press home button or minimize app
   
5. Create another shipping request
   
6. Watch Device/Emulator
   Expected: ✅ Notification in system tray
   If fails: ❌ No system notification
   
7. Tap Notification on Device
   Expected: ✅ App opens to shipping detail
   If fails: ❌ App opens to home screen or doesn't open
```

---

### Step 6: Check Cloud Function FCM Sending

**File:** `functions/src/onShippingRequestCreated.ts`

**What's Implemented:**

```typescript
// Lines 168-192: Send FCM to admins ✅
const adminFcmResponse = await messaging.sendMulticast({
  notification: {...},
  data: {...},
  tokens: adminTokens,  // Admin tokens array
});

// Lines 194-222: Send FCM to affiliate ✅
const affiliateFcmResponse = await messaging.sendMulticast({
  notification: {...},
  data: {...},
  tokens: affiliateData.fcmTokens,  // Affiliate tokens
});
```

**What's Working:**
- ✅ Fetches admin FCM tokens from users collection
- ✅ Sends multicast FCM to all admin devices
- ✅ Handles affiliate FCM if affiliate tagged
- ✅ Logs success/failure counts

**What's Missing:**
- ❌ Send FCM to individual user (requester) when status updates
- ❌ Handle individual user notifications

---

## 🖥️ ADMIN DASHBOARD - REAL-TIME VERIFICATION

### Step 1: Check Firestore Stream Providers

**File:** `admin/admin/lib/features/shipping/presentation/providers/shipping_requests_providers_admin.dart`

**Expected Providers:**
```dart
// Stream provider for all shipping requests (real-time)
final adminAllShippingRequestsProvider = StreamProvider<List<ShippingRequest>>((ref) {
  return shippingRequestsStream();  // Should be Firestore stream
});
```

**How to Verify:**

**Option A: Check Admin App Logs**
```
1. Run admin: cd admin/admin && flutter run -d web
2. Open DevTools → Console
3. Look for Firestore connection logs
4. Expected: ✅ "Connected to Firestore stream"
5. If error: ❌ Stream connection failed
```

**Option B: Check Firestore Security Rules**
```
Firebase Console → Firestore Database → Rules

Current rules should allow:
- Admin role → read all shipping_requests
- Users → read only own requests

Example rule:
match /shipping_requests/{document=**} {
  allow read: if request.auth.token.admin == true;
  allow create: if request.auth != null || /* guest */;
}
```

---

### Step 2: Real-Time Update Test

**Manual Test Procedure:**

**Prerequisites:**
- Admin dashboard open and logged in as admin
- Shipping list loading (no errors)
- Firestore connected

**Test Steps:**

```
1. Open Two Windows:
   - Window A: Admin Dashboard (shipping list)
   - Window B: Mobile app or web form

2. Observe Shipping List (Window A)
   - Note the number of requests visible
   - Check timestamps

3. Create New Shipping Request (Window B)
   - Fill form with test data
   - Submit request

4. Watch Admin Dashboard (Window A)
   Expected: ✅ New request appears within 2 seconds
   If fails: ❌ Doesn't appear (need to refresh manually)

5. Check Timestamps
   Expected: ✅ New request has current timestamp
   If wrong: ❌ Timestamp is old/incorrect

6. Change Status in Admin (Window A)
   - Open request detail
   - Change status: PENDING → APPROVED
   - Click save

7. Check Cloud Function Logs
   - Firebase Console → Cloud Functions → Logs
   Expected: ✅ "✅ Confirmation email sent to [email]"
   If missing: ❌ Function didn't execute

8. Check Mobile App (Window B)
   Expected: ✅ Notification received within 30 seconds
   (If FCM working)
   If fails: ❌ No notification
```

---

### Step 3: Check Stream Connection Stability

**What to Monitor:**

```
1. Keep admin dashboard open for 10+ minutes
2. Every 5 minutes, create a new request
3. Observe:
   - Does list update every time?
   - Are there latency spikes?
   - Does connection ever drop?

Expected: ✅ Consistent < 2 second updates
Warning: 🟡 Updates take 5-10 seconds
Error: ❌ Updates take > 30 seconds or don't happen
```

---

### Step 4: Check for Memory Leaks

**Mobile App:**
```
1. Run: flutter run --profile
2. Open DevTools → Memory tab
3. Create 5 shipping requests
4. Watch memory growth
5. Navigate between screens
6. Memory should stabilize, not keep growing

Expected: ✅ Memory stable after actions
Warning: 🟡 Memory slowly growing (5-10MB per request)
Error: ❌ Memory rapidly growing (> 20MB per request)
```

**Admin Dashboard:**
```
1. Open: http://localhost:3000/admin
2. Open DevTools → Performance tab
3. Keep admin open for 5 minutes
4. Watch memory in DevTools
5. Memory should be < 100MB

Expected: ✅ Memory < 100MB
Warning: 🟡 Memory 100-200MB
Error: ❌ Memory > 200MB (connection leak)
```

---

## 🧪 COMPREHENSIVE TEST SUITE

### Test 1: End-to-End FCM Flow

**Duration:** ~5 minutes

**Steps:**
1. Mobile app: Login or continue as guest
2. Check Firestore: User document has fcmTokens array
3. Mobile app: Keep open (foreground)
4. Admin: Create shipping request
5. Mobile app: Should show dialog notification
6. Mobile app: Close to background
7. Admin: Change status to APPROVED
8. Mobile app: Notification should appear in system tray
9. Mobile app: Tap notification
10. Mobile app: Should navigate to shipping detail screen

**Success Criteria:**
- ✅ Steps 2, 5 work = FCM partially working
- ✅ Steps 8, 9, 10 work = FCM fully working
- ❌ Neither works = FCM not working

---

### Test 2: Admin Real-Time Dashboard

**Duration:** ~5 minutes

**Steps:**
1. Admin: Open dashboard, note request count
2. Mobile: Create 3 new requests rapidly
3. Admin: Watch dashboard update
4. Measure: Note time from submission to appearance
5. Admin: Open one request detail
6. Admin: Change status
7. Admin: Watch list update to reflect new status

**Success Criteria:**
- ✅ New requests appear within 2 seconds
- ✅ Status changes within 1 second
- ❌ Takes > 5 seconds = performance issue
- ❌ Manual refresh needed = not real-time

---

### Test 3: Email Notifications

**Duration:** ~5 minutes

**Steps:**
1. Mobile: Create shipping request with real email
2. Email: Wait 60 seconds
3. Email: Check inbox for confirmation email
4. Admin: Change status to APPROVED
5. Email: Wait 60 seconds
6. Email: Check for approval email
7. Check: Email content is correct

**Success Criteria:**
- ✅ Both emails received within 60 seconds
- ✅ Content is correct and professional
- ⚠️ Email in spam folder = domain issue
- ❌ Email never arrives = SMTP issue

---

## 🐛 TROUBLESHOOTING

### Issue: "FCM token not found in Firestore"

**Solution:**
1. Check if user is authenticated (logged in)
2. Check if Firebase messaging is initialized
3. Check app permissions (iOS: Settings → Notifications)
4. Restart app and wait 5 seconds
5. Check Firestore console for user document

### Issue: "No notification received"

**Solution:**
1. Check if FCM token exists in Firestore
2. Check Cloud Function logs for errors
3. Verify Firebase project ID matches
4. Check device notification permissions
5. Test with debug: `firebase functions:log`

### Issue: "Admin dashboard not updating in real-time"

**Solution:**
1. Check Firestore connection in DevTools
2. Verify security rules allow admin read
3. Check browser console for errors
4. Try manual refresh to confirm data is there
5. Restart admin dashboard app

### Issue: "Email not delivering"

**Solution:**
1. Check SMTP credentials in Firebase
2. Check email provider queue
3. Test SMTP connection: `telnet smtp.shopsnports.com 587`
4. Check email spam folder
5. Verify domain reputation

---

## ✅ FINAL VERIFICATION CHECKLIST

Before marking feature as "DONE", verify:

**Mobile App:**
- [ ] FCM token appears in Firestore under user's fcmTokens
- [ ] Foreground notification shows as dialog
- [ ] Background notification shows in system tray
- [ ] Tapping notification opens app to correct screen
- [ ] Without FCM token, notifications still work via database listeners

**Admin Dashboard:**
- [ ] New requests appear within 2 seconds
- [ ] Status changes visible immediately
- [ ] No manual refresh needed
- [ ] Dashboard stays responsive after 10+ minutes
- [ ] Memory usage stays under 150MB

**Email System:**
- [ ] Confirmation email sent within 60 seconds
- [ ] Email subject includes tracking number
- [ ] Email HTML rendering correct
- [ ] No spam folder placement (or configure domain)
- [ ] Status update emails sent correctly

**Cloud Functions:**
- [ ] No errors in logs
- [ ] Execution time < 10 seconds
- [ ] All triggers working (create, update)
- [ ] FCM sending succeeds (logs show success count > 0)

---

## 📊 METRICS TO MONITOR

| Metric | Target | Current |
|--------|--------|---------|
| FCM Token Gen Time | < 5s | ? |
| Admin Update Latency | < 2s | ? |
| Email Delivery Time | < 60s | ? |
| Function Execution | < 10s | ? |
| Dashboard Memory | < 150MB | ? |
| Foreground Notification | < 1s | ? |
| Background Notification | < 5s | ? |

---

## 🎯 IMPLEMENTATION PRIORITY

### Must Do First:
1. **Save FCM token to Firestore** (critical)
2. **Add onMessageOpenedApp handler** (critical)
3. **Create Shipping History Screen** ✅ DONE
4. **Verify admin real-time working** (critical)

### Then Do:
5. **Test end-to-end flow** (1 hour)
6. **Fix any issues found** (2-4 hours)
7. **Optimize performance** (1-2 hours)
8. **Production deployment** (1 hour)

---

**Verification Status:** ⏳ PENDING  
**Next Step:** Run tests and document findings

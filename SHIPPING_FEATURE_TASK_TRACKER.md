# 📋 SHIPPING REQUEST FEATURE - TASK TRACKER

**Status:** In Progress (85% Complete)  
**Priority:** CRITICAL (Core Feature)  
**Last Updated:** March 2, 2026  

---

## 🔴 PRIORITY 1 - CRITICAL (Must Complete This Week)

### Task 1.1 - Create Shipping History Screen
**Status:** 🔴 NOT STARTED  
**Severity:** CRITICAL  
**Impact:** Users cannot view their past shipping requests  
**Time Estimate:** 2-3 hours  
**Owner:** [Assign]  
**Deadline:** This week

**Description:**
Users need a dedicated screen to view all their shipping requests in one place. Currently, only tracking number lookup exists (TrackingLookupScreen), which doesn't allow browsing request history.

**What to Build:**
- New screen: `lib/screens/shipping/shipping_history_screen.dart`
- List of all user's shipping requests
- Real-time updates using `watchUserShippingRequestsProvider`
- Filter by status (Pending, Approved, In Transit, Delivered, Cancelled)
- Sort by date (newest first)
- Each item shows:
  - Request ID / Reference Number
  - Status (with color coding)
  - Destination city
  - Created date
  - Tracking number (if available)
- Tap item to view full details
- Copy tracking number button
- Empty state when no requests

**Requirements:**
- Use existing Riverpod provider (already created)
- Material Design UI
- Mobile responsive
- Real-time Firestore sync
- Handle loading/error states

**Dependencies:**
- ✅ `watchUserShippingRequestsProvider` exists
- ✅ `ShippingRequestSimplified` model exists
- ✅ `shipping_detail_screen.dart` reference

**Acceptance Criteria:**
- [ ] Screen renders without errors
- [ ] All user's requests display
- [ ] Real-time updates work (create request, verify it appears)
- [ ] Filters and sorts work
- [ ] Tap opens detail screen
- [ ] Copy tracking number works
- [ ] No null pointer errors
- [ ] Loading/error states handled

**Blocking:** Mobile app shipping history feature

---

### Task 1.2 - Verify Mobile App FCM Integration
**Status:** 🟡 UNKNOWN  
**Severity:** CRITICAL  
**Impact:** Users won't receive real-time status notifications  
**Time Estimate:** 1-2 hours  
**Owner:** [Assign]  
**Deadline:** This week

**Description:**
Verify that the mobile app correctly receives Firebase Cloud Messaging (FCM) push notifications and that the token is properly sent to Firestore for the Cloud Function to reach the user.

**What to Verify:**
1. **FCM Token Generation**
   - [ ] App initializes Firebase Messaging on startup
   - [ ] App requests notification permission (iOS)
   - [ ] Token is generated successfully
   - [ ] Token is saved to `users/{userId}/fcmTokens` array

2. **Notification Reception**
   - [ ] `onMessageReceived` handler exists in main.dart or service
   - [ ] App receives FCM message while running (foreground)
   - [ ] App receives FCM message while backgrounded
   - [ ] Notification displays in system tray

3. **Notification Display**
   - [ ] Title and body display correctly
   - [ ] No crashes on notification received
   - [ ] Notification can be dismissed
   - [ ] Notification persists in history

4. **Deep Linking**
   - [ ] Tapping notification opens correct screen
   - [ ] User navigates to shipping detail screen
   - [ ] Correct request ID is passed
   - [ ] Navigation state is correct

**Files to Check:**
- `lib/main.dart` - FCM initialization
- `lib/services/firebase_messaging_service.dart` (if exists)
- Firebase Console - FCM configuration
- `pubspec.yaml` - firebase_messaging dependency

**Testing Steps:**
```
1. Run app on real device
2. Create shipping request
3. Go to admin dashboard
4. Verify FCM token saved to Firestore:
   - Firebase Console → Data → users → [userId] → fcmTokens
5. Update shipping status in admin
6. Check mobile device for notification in system tray
7. Tap notification and verify it opens shipping detail
```

**Acceptance Criteria:**
- [ ] FCM token generated and saved
- [ ] Notification received in foreground
- [ ] Notification received in background
- [ ] Notification displayed in system tray
- [ ] Tap notification navigates to correct screen
- [ ] No errors in console logs
- [ ] Works on both iOS and Android

**Blocking:** Real-time push notification feature

---

### Task 1.3 - Verify Admin Dashboard Real-Time Sync
**Status:** 🟡 UNKNOWN  
**Severity:** CRITICAL  
**Impact:** Admin won't see new shipping requests in real-time  
**Time Estimate:** 1 hour  
**Owner:** [Assign]  
**Deadline:** This week

**Description:**
Verify that the admin dashboard displays new shipping requests in real-time using Firestore stream providers. Test that the list updates automatically when a new request is created in the mobile app.

**What to Verify:**
1. **Stream Provider Connection**
   - [ ] `adminAllShippingRequestsProvider` correctly configured
   - [ ] Uses `.snapshots()` stream from Firestore
   - [ ] Properly converts documents to `ShippingRequestSimplified`

2. **Real-Time Updates**
   - [ ] Admin dashboard contains shipping list
   - [ ] List displays current requests
   - [ ] New request appears within 2 seconds of creation
   - [ ] Stream doesn't drop connection after 5 minutes
   - [ ] No duplicate requests shown
   - [ ] List updates when status changes

3. **UI Responsiveness**
   - [ ] List scrolls smoothly with items
   - [ ] No jank when updates occur
   - [ ] Memory doesn't leak during updates
   - [ ] Performance acceptable (< 100ms update)

**Files to Check:**
- `admin/admin/lib/features/shipping/presentation/providers/shipping_requests_providers_admin.dart`
- `admin/admin/lib/features/shipping/presentation/screens/shipping_list_screen.dart`
- Firestore security rules

**Testing Steps:**
```
1. Open admin dashboard (web)
2. Open shipping list screen
3. In mobile app: Create new shipping request
4. Watch admin dashboard
5. Verify request appears in list within 2 seconds
6. Check status, details are accurate
7. In admin app: Change status to "Approved"
8. Watch mobile app
9. Verify status update appears in mobile app
```

**Acceptance Criteria:**
- [ ] Stream provider connected correctly
- [ ] New requests appear in admin list
- [ ] Updates appear within 2 seconds
- [ ] No connection drops
- [ ] No duplicates
- [ ] Performance acceptable
- [ ] Mobile app sees updates from admin changes

**Blocking:** Admin real-time viewing feature

---

## 🟡 PRIORITY 2 - HIGH (Complete By End of Week 2)

### Task 2.1 - Implement In-App Notification Banner
**Status:** 🔴 NOT STARTED  
**Severity:** HIGH  
**Impact:** Users may miss notifications  
**Time Estimate:** 1-2 hours  
**Owner:** [Assign]  
**Deadline:** End of Week 2

**Description:**
Create an in-app notification banner that displays at the top of the screen when the app is open and the user receives a notification. This supplements push notifications and improves notification visibility.

**What to Build:**
- Notification banner widget
- Listens to incoming FCM messages
- Displays notification for 5 seconds (auto-dismiss)
- Shows title and body
- Animated appearance/disappearance
- Tap banner to navigate to shipping detail
- Supports notification icons
- Handles multiple notifications (queue or dismiss previous)

**Files to Create:**
- `lib/widgets/notification_banner.dart`

**Integration Points:**
- Connect to `firebase_messaging` service
- Add to `NavigationShell` or main app wrapper
- Display on top of content (overlay)

**Acceptance Criteria:**
- [ ] Banner displays when notification received
- [ ] Title and body show correctly
- [ ] Auto-dismisses after 5 seconds
- [ ] Tap banner navigates to shipping detail
- [ ] Animation smooth
- [ ] Handles multiple notifications
- [ ] No crashes

---

### Task 2.2 - Implement Backend HTTP API Routes
**Status:** 🔴 NOT STARTED  
**Severity:** HIGH  
**Impact:** Limited third-party integration options  
**Time Estimate:** 2-4 hours  
**Owner:** [Assign]  
**Deadline:** End of Week 2

**Description:**
Create REST API endpoints for shipping requests to support third-party integrations, bulk operations, and alternative submission methods.

**Endpoints to Create:**
```
POST /api/shipping/submit
  - Alternative to direct Firestore submission
  - Request body: ShippingRequestSimplified
  - Returns: { requestId, trackingNumber, status }

GET /api/shipping/search
  - Query parameters: status, userId, createdAfter, limit
  - Returns: List<ShippingRequestSimplified>

PUT /api/shipping/{id}/status
  - Body: { status, reason }
  - Returns: updated request

POST /api/shipping/{id}/assign
  - Body: { adminId }
  - Returns: assignment confirmation

GET /api/shipping/{id}/tracking
  - Returns: just tracking number and status
  - No auth required (for public tracking)
```

**Files to Create:**
- `functions/src/routes/shippingRoutes.ts` (new)

**Requirements:**
- Input validation
- Error handling
- Logging
- Authentication (where needed)
- Rate limiting
- CORS headers

---

### Task 2.3 - Create Status-Specific Email Templates
**Status:** 🟡 PARTIAL  
**Severity:** HIGH  
**Impact:** Better customer experience  
**Time Estimate:** 1-2 hours  
**Owner:** [Assign]  
**Deadline:** End of Week 2

**Description:**
Create separate, optimized email templates for each shipping status to provide more relevant and engaging customer communications.

**Templates Needed:**
1. **APPROVED** - "Your request was approved!"
   - Next steps
   - Expected timeline
   - Contact info

2. **IN_TRANSIT** - "Your shipment is on the way!"
   - Tracking number
   - Estimated delivery
   - Carrier info (if available)
   - Tracking link

3. **DELIVERED** - "Your shipment has arrived!"
   - Delivery date/time
   - Receiver name
   - Request for feedback/rating
   - Contact for issues

4. **CANCELLED** - "Request Cancelled"
   - Cancellation reason
   - Refund info (if applicable)
   - Contact support

**Files to Update:**
- `functions/src/emailTemplates/` (create directory)
- `functions/src/onShippingRequestUpdated.ts` (use templates)

**Acceptance Criteria:**
- [ ] 4 templates created
- [ ] HTML formatting consistent
- [ ] All variables interpolated correctly
- [ ] Mobile responsive
- [ ] Links work
- [ ] No broken images

---

## 🟠 PRIORITY 3 - MEDIUM (Complete By End of Week 3)

### Task 3.1 - Add QR Code Tracking Support
**Status:** 🔴 NOT STARTED  
**Severity:** MEDIUM  
**Time Estimate:** 1-2 hours  
**Deadline:** End of Week 3

**Description:**
Allow users to scan QR codes to track shipments. Generate QR codes for tracking numbers and display them in emails and mobile app.

**What to Build:**
- Generate QR code for tracking number
- Display QR code in confirmation email
- QR code scanner in `TrackingLookupScreen`
- QR code in shipping detail screen
- Share QR code functionality

---

### Task 3.2 - Implement Shipping Ratings & Feedback
**Status:** 🔴 NOT STARTED  
**Severity:** MEDIUM  
**Time Estimate:** 1-2 hours  
**Deadline:** End of Week 3

**Description:**
Allow users to rate their shipping experience after delivery. Gather feedback for quality improvement.

**What to Build:**
- Feedback form (5-star rating + comments)
- Show only for DELIVERED requests
- Save to Firestore `feedback` collection
- Admin can view feedback in dashboard
- Calculate average rating

---

### Task 3.3 - PDF Invoice Generation
**Status:** 🔴 NOT STARTED  
**Severity:** MEDIUM  
**Time Estimate:** 2-3 hours  
**Deadline:** End of Week 3

**Description:**
Generate downloadable PDF invoices for users to keep records of their shipping requests.

**What to Generate:**
- Request details
- Sender/receiver info
- Cost breakdown
- Company logo
- Terms and conditions
- Tracking number

---

## ✅ COMPLETED TASKS

### ✅ Done - Mobile App Form Creation
- [x] Shipping request form screen (21 fields)
- [x] Simplified form (6 fields)
- [x] Form validation
- [x] File upload support
- [x] Guest user support
- [x] Affiliate token support

### ✅ Done - Firestore Schema
- [x] `shippingRequests` collection designed
- [x] All fields documented
- [x] Security rules configured
- [x] Indexes created

### ✅ Done - Cloud Functions
- [x] `onShippingRequestCreated` - Email, notifications, tracking
- [x] `onShippingRequestUpdated` - Status change notifications
- [x] Affiliate token validation
- [x] Admin notifications
- [x] FCM push notifications
- [x] Activity logging

### ✅ Done - Email System
- [x] SMTP configured
- [x] HTML templates created
- [x] Tracking number included
- [x] Professional design
- [x] Deployed and verified

### ✅ Done - Admin Dashboard
- [x] Shipping list screen
- [x] Shipping detail screen
- [x] Real-time stream providers
- [x] Filter and sort functionality
- [x] Status management
- [x] Document viewer

### ✅ Done - Mobile Providers/Repositories
- [x] `ShippingRequestRepository` queries
- [x] `shippingSubmissionProvider` form submission
- [x] `trackingLookupProvider` search
- [x] `watchUserShippingRequestsProvider` real-time
- [x] `affiliateShippingRequestsProvider` referrals

---

## 📊 QUICK STATS

| Metric | Value |
|--------|-------|
| **Total Tasks** | 12 |
| **Completed** | 7 |
| **In Progress** | 0 |
| **Not Started** | 5 |
| **Completion %** | 58% (Features) / 85% (Code) |
| **Blocking Tasks** | 3 (Critical) |
| **Est. Time to Complete** | 5-7 hours |

---

## 🚀 NEXT STEPS

1. **Today:** Start Task 1.1 (Shipping History Screen) - 2-3 hours
2. **Today:** Verify Task 1.2 (FCM Integration) - 1-2 hours
3. **Today:** Test Task 1.3 (Admin Real-Time Sync) - 30 min
4. **This Week:** Complete all Priority 1 tasks
5. **Week 2:** Complete all Priority 2 tasks
6. **Week 3:** Complete all Priority 3 tasks (optional enhancements)

---

## 📝 NOTES

**Current System Flow:**
```
Mobile App → Firestore (Create Request)
      ↓
Cloud Function Trigger (onShippingRequestCreated)
      ↓
Email Sent + Notifications Published
      ↓
Admin Dashboard Updates (Real-Time)
      ↓
Admin Updates Status
      ↓
Cloud Function Trigger (onShippingRequestUpdated)
      ↓
Email Sent + Notifications Published
      ↓
Mobile App Updates (Real-Time)
```

**Key Files To Know:**
- Mobile form: `lib/screens/shipping/shipping_request_form_screen.dart`
- Cloud Function: `functions/src/onShippingRequestCreated.ts`
- Admin dashboard: `admin/admin/lib/features/shipping/`
- Providers: `lib/providers/shipping_providers.dart`

---

**Last Updated:** March 2, 2026  
**Version:** 1.0.0  
**Status:** Ready for Implementation

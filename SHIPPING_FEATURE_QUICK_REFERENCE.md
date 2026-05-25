# 🚀 SHIPPING REQUEST FEATURE - QUICK REFERENCE GUIDE

**Last Updated:** March 2, 2026  
**For:** ShopsNPorts Shipping Platform Team

---

## 📱 MOBILE APP CHECKLIST

### What Works ✅
- [x] Create shipping request (full form + simple form)
- [x] Upload documents
- [x] Guest user support
- [x] Form validation
- [x] Success confirmation screen
- [x] Track by tracking number
- [x] Real-time provider support

### What's Missing 🔴
- [ ] **Shipping History Screen** - Users can't see all their past requests
- [ ] **In-App Notification Banner** - Notifications only appear as push
- [ ] **Share Tracking Link** - No way to share tracking with others

### Critical Files
- `lib/screens/shipping/shipping_request_form_screen.dart` - Form UI
- `lib/models/shipping_request_simplified.dart` - Data model
- `lib/providers/shipping_submission_provider.dart` - Form submission
- `lib/providers/shipping_providers.dart` - Providers/queries
- `lib/repositories/shipping_request_repository.dart` - Firestore queries

---

## ☁️ CLOUD FUNCTIONS CHECKLIST

### What Works ✅
- [x] onShippingRequestCreated - Full implementation
- [x] onShippingRequestUpdated - Full implementation
- [x] Email sending - SMTP configured
- [x] FCM notifications - Deployed
- [x] Tracking number generation - Auto-generated (SHP-YYYYMMDD-XXXXX)
- [x] Activity logging - Admin activity tracked
- [x] Affiliate token validation - Auto-tags affiliate

### Needs Manual Setup ⚠️
- [ ] SMTP credentials in Firebase Console (sensitive - already done locally)
- [ ] Cloud Function environment variables configured
- [ ] Email templates verified in production

### Critical Files
- `functions/src/onShippingRequestCreated.ts` - New request handler
- `functions/src/onShippingRequestUpdated.ts` - Status change handler
- `functions/src/index.ts` - Function registration
- `EMAIL_QUICK_START.md` - Email setup guide

---

## 🗄️ FIRESTORE CHECKLIST

### What Works ✅
- [x] shippingRequests collection schema designed
- [x] Security rules created
- [x] Indexes for queries created
- [x] Guest users can create (rule: authenticated OR beforeSignIn)
- [x] Real-time stream support

### Document Fields (21 total)
1. **Identifiers:** id, requesterId, affiliateId
2. **Status:** status, trackingNumber
3. **Freight:** freightType
4. **Shipment:** itemDescription, hsCode, departure/arrival, weight, dimensions, packaging
5. **Sender:** senderName, senderAddress, senderPhone, senderEmail
6. **Receiver:** receiverName, receiverAddress, receiverPhone, receiverEmail
7. **Attachments:** attachments (array)
8. **Notes:** otherInformation
9. **System:** createdAt, updatedAt

### Status Values
- `pending` - Initial state
- `approved` - Admin approved
- `in_transit` - Shipment sent
- `delivered` - Arrived at destination
- `cancelled` - Request rejected

---

## 📊 ADMIN DASHBOARD CHECKLIST

### What Works ✅
- [x] Real-time list of all requests
- [x] Filter by status (pending, approved, in_transit, delivered, cancelled)
- [x] Filter by freight type (door_to_door, airport_to_airport)
- [x] Sort by date (ascending/descending)
- [x] Search by name or tracking number
- [x] Status change dropdown
- [x] Admin actions (approve, deny, mark in transit, mark delivered, cancel)
- [x] Document viewer
- [x] Affiliate information display

### UI Screens
- **Shipping List Screen** - All requests with filters
- **Shipping Detail Screen** - Full request info + actions

### Real-Time Features
- New requests appear within 2 seconds
- Status changes reflected immediately
- No polling required (using Firestore streams)

---

## 📧 EMAIL SYSTEM CHECKLIST

### Supported Scenarios ✅
- [x] Request Created - Tracking number included
- [x] Request Approved - Confirmation message
- [x] In Transit - Tracking link
- [x] Delivered - Confirmation
- [x] Cancelled - Reason provided

### Email Configuration
```
SMTP Server: smtp.shopsnports.com
Port: 587
Username: noreply@shopsnports.com
Password: [ROTATED - USE NEW PASSWORD] (in Firebase Secrets)
TLS: Enabled
From: ShopsNPorts <noreply@shopsnports.com>
```

### Template Features
- [x] Professional HTML design
- [x] Responsive (mobile-friendly)
- [x] Tracking number prominently displayed
- [x] Contact information included
- [x] Company branding
- [x] Clear call-to-action

---

## 🔔 NOTIFICATIONS CHECKLIST

### Push Notifications (FCM) ✅
- [x] Admin receives on new request
- [x] Affiliate receives on referral
- [x] Customer receives on status update
- [x] Title: Clear and actionable
- [x] Body: Relevant shipment info
- [x] Deep link: Opens shipping detail screen

### In-App Notifications 🔴
- [ ] NOT IMPLEMENTED - Users won't see notifications while app open
- [ ] Needs banner widget at top of screen
- [ ] Should auto-dismiss after 5 seconds

---

## 🔗 DATA FLOW DIAGRAM

```
USER CREATES REQUEST (Mobile)
        ↓
   Firestore Write
   shippingRequests/{requestId}
        ↓
   Cloud Function: onShippingRequestCreated
        ├─→ Validate affiliate token
        ├─→ Create admin notification
        ├─→ Create affiliate notification
        ├─→ Send FCM to admins
        ├─→ Send HTML email
        └─→ Generate tracking number
        ↓
   ADMIN SEES REQUEST
   Admin Dashboard Real-Time Update
        ↓
   ADMIN APPROVES (Changes status: pending → approved)
        ↓
   Cloud Function: onShippingRequestUpdated
        ├─→ Send FCM to customer
        ├─→ Send HTML email: "Approved"
        └─→ Update notification
        ↓
   USER SEES UPDATE
   Mobile app real-time update
   Email notification
   Push notification
```

---

## 🎯 IMPLEMENTATION ROADMAP

### Phase 1: CREATE & SUBMIT (✅ DONE)
- [x] Form creation
- [x] Validation
- [x] Firestore submission
- [x] Success confirmation

### Phase 2: NOTIFICATIONS (✅ DONE)
- [x] Cloud Function triggers
- [x] Email system
- [x] FCM notifications
- [x] Activity logging

### Phase 3: ADMIN MANAGEMENT (✅ DONE)
- [x] Dashboard list screen
- [x] Detail screen
- [x] Status management
- [x] Real-time sync

### Phase 4: USER HISTORY (🔴 MISSING)
- [ ] Shipping history screen
- [ ] Real-time history updates
- [ ] Filter & sort
- [ ] Tracking number display

### Phase 5: ENHANCEMENTS (🟠 TODO)
- [ ] In-app notifications
- [ ] QR code tracking
- [ ] Customer feedback/ratings
- [ ] PDF invoices
- [ ] Backend API routes

---

## 🐛 COMMON ISSUES & SOLUTIONS

### Problem: Users don't see their requests
**Solution:** Create shipping_history_screen.dart (TASK 1.1)
- Provider exists: `watchUserShippingRequestsProvider`
- Just need UI screen to display them

### Problem: No notifications on device
**Solution:** Verify FCM integration (TASK 1.2)
- Check FCM token saved to Firestore
- Verify notification handler in main.dart
- Test on real device (not emulator)

### Problem: Admin dashboard doesn't update
**Solution:** Verify stream provider (TASK 1.3)
- Check `adminAllShippingRequestsProvider` is connected
- Verify Firestore security rules allow reading
- Check network connection

### Problem: Email not sending
**Solution:** Check Firebase Functions logs
```
firebase functions:log
```
- Look for "SMTP_PASS not configured"
- Check SMTP credentials in Firebase Console
- Verify firebase.config.js has SMTP settings

---

## 🚀 TESTING CHECKLIST

### End-to-End Test (15 minutes)
```
1. [ ] Create shipping request in mobile app
   └─> Should see success screen with reference number

2. [ ] Check admin dashboard
   └─> Should see new request appear within 2 seconds

3. [ ] Check user's email
   └─> Should receive confirmation email within 1 minute

4. [ ] In admin dashboard, change status to "Approved"
   └─> Should see status update in detail screen

5. [ ] Check mobile app for notification
   └─> Should see push notification or in-app banner

6. [ ] Check mobile shipping history (once created)
   └─> Should show all requests with status updates

7. [ ] Check email for status update notification
   └─> Should receive "Approved" email within 1 minute
```

---

## 📞 QUICK SUPPORT

**Mobile App Issues?**
- Check: `lib/screens/shipping/` directory
- Debug: Add console logs in providers
- Test: Use `flutter run -v` for verbose output

**Cloud Function Issues?**
- Check: `firebase functions:log`
- Debug: Look for error messages
- Test: Use local emulator first

**Firestore Issues?**
- Check: Firebase Console → Data tab
- Debug: Verify security rules
- Test: Query from mobile app directly

**Email Issues?**
- Check: Firebase Console → Functions logs
- Debug: Look for SMTP errors
- Test: Use test email address first

---

## 📚 KEY DOCUMENTATION

| Document | Purpose | Link |
|----------|---------|------|
| Firestore Schema | Database structure | FIRESTORE_COLLECTIONS_SCHEMA_2026.md |
| Email Setup | SMTP configuration | EMAIL_QUICK_START.md |
| Backend Routes | API endpoints | [TODO - Create] |
| Admin Dashboard | Web interface guide | [See code] |
| Shipping Guide | User documentation | [Marketing] |

---

## 🎓 ARCHITECTURE SUMMARY

```
┌─────────────────────────────────────────────────────┐
│          MOBILE APP (Flutter)                        │
│  ├─ ShippingRequestFormScreen (Collect data)        │
│  ├─ ShippingHistoryScreen (Show history) 🔴 MISSING │
│  ├─ TrackingLookupScreen (Search tracking)          │
│  └─ ShippingDetailScreen (View full details)        │
└────────────┬────────────────────────────────────────┘
             │ Writes/Reads
             ↓
┌─────────────────────────────────────────────────────┐
│        FIRESTORE (Real-time Database)               │
│  ├─ shippingRequests (Documents + Stream)           │
│  ├─ notifications (Admin/Affiliate)                 │
│  └─ users (FCM tokens)                              │
└────────────┬────────────────────────────────────────┘
             │ Triggers
             ↓
┌─────────────────────────────────────────────────────┐
│     CLOUD FUNCTIONS (Firebase Serverless)           │
│  ├─ onShippingRequestCreated                        │
│  │  ├─→ Send SMTP email                            │
│  │  ├─→ Create notifications                       │
│  │  └─→ Send FCM push                              │
│  └─ onShippingRequestUpdated                        │
│     ├─→ Send SMTP email                            │
│     └─→ Send FCM push                              │
└────────────┬────────────────────────────────────────┘
             │
    ┌────────┴────────┐
    ↓                 ↓
┌──────────────┐ ┌──────────────────┐
│ EMAIL        │ │ PUSH NOTIFICATION│
│ SYSTEM       │ │ (FCM)            │
└──────────────┘ └──────────────────┘
    └────────┬────────┘
             ↓
┌─────────────────────────────────────────────────────┐
│      ADMIN DASHBOARD (Web/Flutter)                  │
│  ├─ ShippingListScreen (Real-time list)            │
│  └─ ShippingDetailScreen (Full management)         │
└─────────────────────────────────────────────────────┘
```

---

## ✨ FEATURE COMPLETION STATUS

| Feature | Status | Effort |
|---------|--------|--------|
| Submit Request | ✅ 100% | Done |
| View History | 🔴 0% | 2-3h |
| Track Shipment | ✅ 100% | Done |
| Receive Email | ✅ 100% | Done |
| Push Notification | 🟡 50% | 1-2h |
| Admin Approval | ✅ 100% | Done |
| Admin Dashboard | ✅ 100% | Done |
| Real-Time Sync | ✅ 100% | Done |

**Total:** 85% Complete | **Time to 100%:** 5-7 hours

---

**Generated:** March 2, 2026  
**Version:** 1.0.0  
**Status:** Reference Document - Implementation in Progress

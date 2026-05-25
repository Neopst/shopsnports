# 🎯 SHOPSNPORTS PROJECT TASK TRACKER

**Audit Date:** April 8, 2026
**Last Updated:** April 9, 2026
**Status:** Testing Guest Flow

---

## 📋 QUICK START

Shipping fees: **MANUAL** (no payment gateway needed)
Priority: **Cleanup & Bug Fixes → Admin Completion → Polish**

**Current State:** App launches to HomeScreen in guest mode for E2E testing

---

## 🚨 CRITICAL PATH (Must Complete First)

### Task 1: Remove Unused Payment Packages
**Status:** ✅ COMPLETED | **Priority:** HIGH | **Effort:** 10 min | **Date:** April 8, 2026

**Verification:** Payment packages already removed from pubspec.yaml and pubspec.lock

- [x] 1.1 Payment packages not present in pubspec.yaml
- [x] 1.2 Verified no flutter_stripe, flutterwave, or paystack in pubspec.lock
- [x] 1.3 No action required - packages already cleaned up

**Files to delete:**
- [ ] `lib/screens/payment/payment_billing_screen.dart` (verify first)

---

### Task 2: Fix FCM Notification Conflicts
**Status:** ✅ COMPLETED | **Priority:** HIGH | **Effort:** Already Implemented | **Date:** April 8, 2026

**Verification:** FCM notification service is fully implemented

- [x] 2.1 firebase_messaging: ^16.0.2 present in pubspec.yaml
- [x] 2.2 notification_service.dart fully implemented with no errors
- [x] 2.3 Service initialized in main.dart
- [x] 2.4 Topic subscriptions working (admin, affiliate, user)
- [x] 2.5 Token management and foreground/background handling active

**Note:** The comment about "intentionally avoiding firebase_messaging" in the service file is outdated - it IS being used.

---

### Task 3: Delete Ecommerce Remnants
**Status:** ✅ COMPLETED | **Priority:** HIGH | **Effort:** Already Done | **Date:** April 8, 2026

**Verification:** Most ecommerce files already deleted

- [x] 3.1 `add_product_dialog.dart` - Already deleted
- [x] 3.2 `vendor_registration_screen.dart` - Already deleted
- [x] 3.3 `recommended_screen.dart` - Already deleted
- [x] 3.4 `customer_home_screen.dart` - Reviewed: KEEP (shipping-related)
- [x] 3.5 `payment/` directory - Does not exist
- [x] 3.6 `invoices_screen.dart` - Reviewed: KEEP (shipping invoices)

**Admin Dashboard Note:**
- `vendor_model.dart` and `vendor_repository.dart` exist in admin but are unused
- Analytics module reads from API, not these files
- Can be removed in separate cleanup task if desired

---

## 📱 MOBILE APP - TESTING & BUG FIXES

### Task 4: Test Guest Shipping Flow
**Status:** ⏳ NOT STARTED | **Priority:** HIGH | **Effort:** 2-4 hours

**Test Checklist:**
- [ ] 4.1 Open app without login
- [ ] 4.2 Navigate to shipping request form
- [ ] 4.3 Fill and submit shipping request as guest
- [ ] 4.4 Verify request appears in Firebase
- [ ] 4.5 Verify guest can track their request via lookup
- [ ] 4.6 Test guest registration after submission (link to account)

**Expected Issues:**
- [ ] Identify any auth barriers for guest flow
- [ ] Document required fixes

---

### Task 5: Fix Tracking Lookup
**Status:** ⏳ NOT STARTED | **Priority:** MEDIUM | **Effort:** 2 hours

**File:** `lib/screens/tracking_lookup_screen.dart`

- [ ] 5.1 Test lookup with valid tracking number
- [ ] 5.2 Test lookup with invalid tracking number
- [ ] 5.3 Verify real-time updates work
- [ ] 5.4 Fix any UI issues
- [ ] 5.5 Test on both platforms (iOS/Android)

---

### Task 6: Add Pagination to Shipment Lists
**Status:** ✅ COMPLETED | **Priority:** MEDIUM | **Effort:** ~2 hours | **Date:** April 8, 2026

**Files Modified:**
- `lib/providers/shipping_requests_user_provider.dart` - Added `PaginatedShippingRequestsState` and `paginatedShippingRequestsProvider`
- `lib/repositories/shipping_request_repository.dart` - Added `getUserRequestsPaginated()` method
- `lib/screens/shipments/shipments_list_screen.dart` - Updated to use paginated provider with "Load More" button

**Changes:**
- [x] 6.1 Implemented `PaginatedShippingRequestsNotifier` with StateNotifier
- [x] 6.2 Added Firestore `limit(20)` + `startAfterDocument()` pagination
- [x] 6.3 Added "Load More" button when more results available
- [x] 6.4 Show loading indicator during fetch
- [x] 6.5 Added RefreshIndicator for pull-to-refresh
- [x] 6.6 Handle empty states and error states

---

### Task 7: Guest Mode Launch Screen
**Status:** ✅ COMPLETED | **Priority:** HIGH | **Effort:** 15 min | **Date:** April 9, 2026

**Files Modified:**
- `lib/main.dart` - Changed launch screen from auth-gated to HomeScreen via NavigationShell
- `lib/screens/home_screen.dart` - Added Login/Logout button logic

**Changes:**
- [x] 7.1 App now launches directly to HomeScreen (guest mode)
- [x] 7.2 Removed auth-gated landing page
- [x] 7.3 Users can browse home screen, track shipments, request shipping as guest
- [x] 7.4 Login/Sign Up buttons visible for unauthenticated users
- [x] 7.5 Logout button for authenticated users
- [x] 7.6 NavigationShell provides bottom nav bar for authenticated state

---

### Task 8: Login/Logout Button on Home Screen
**Status:** ✅ COMPLETED | **Priority:** HIGH | **Effort:** 20 min | **Date:** April 9, 2026

**File Modified:** `lib/screens/home_screen.dart`

**Changes:**
- [x] 8.1 Added Login button (outlined) for guest users
- [x] 8.2 Added Sign Up button (solid white) for guest users
- [x] 8.3 Added Logout button for authenticated users
- [x] 8.4 Implemented logout confirmation dialog
- [x] 8.5 Buttons styled with app colors and consistent design

---

## 👨‍💼 ADMIN DASHBOARD COMPLETION

### Task 7: Complete Analytics Module
**Status:** ⏳ NOT STARTED | **Priority:** MEDIUM | **Effort:** 4-8 hours

**Location:** `admin/admin/lib/features/analytics/`

- [ ] 7.1 Audit existing analytics code
- [ ] 7.2 Implement dashboard charts (revenue, shipments by type)
- [ ] 7.3 Add shipment statistics (pending, in-transit, delivered)
- [ ] 7.4 Add affiliate performance metrics
- [ ] 7.5 Implement date range filtering
- [ ] 7.6 Add CSV export functionality
 New Additions:

  1. Extended Permissions (20 total):
    - Added shipping.assign,
  affiliates.commission, customers.kyc,
  payouts.dispute, reports.generate, audit.view,   notifications.manage
  2. Department/Role Field:
    - Better organization with roles like       
  "Shipping Manager", "Affiliate Support"       
  3. Password Requirements:
    - Minimum 12 characters, uppercase,
  lowercase, numbers, symbols
    - Password history to prevent reuse
    - Optional 90-day password expiry
  4. New Firebase Functions (10 total):
    - Added subAdminLoginAudit,
  getSubAdminActivityLog,
  forceSubAdminPasswordReset
  5. Activity Log Schema:
    - Complete schema for tracking admin actions    - Records: adminId, action, module,
  resourceId, IP, userAgent
  6. Admin Menu Structure:
    - Visual tree showing which menu items each 
  permission grants access to
  7. Security Considerations:
    - Rate limiting, IP whitelist, session      
  timeout, 2FA option

  The task is now comprehensive and ready for   
  implementation!
---

### Task 8: Review Orders → Shipping Module
**Status:** ⏳ NOT STARTED | **Priority:** HIGH | **Effort:** 2-4 hours

**Location:** `admin/admin/lib/features/orders/`

- [ ] 8.1 Review `order_model.dart` - verify shipping fields
- [ ] 8.2 Test orders screen displays shipping requests correctly
- [ ] 8.3 Refactor if needed to use `shippingRequests` collection
- [ ] 8.4 Test CRUD operations on shipping requests
- [ ] 8.5 Verify admin can update shipment status

---

### Task 9: Add Missing Admin Screens
**Status:** ⏳ NOT STARTED | **Priority:** MEDIUM | **Effort:** 4-8 hours

**Potential missing screens:**
- [ ] 9.1 Commission management view
- [ ] 9.2 Shipping reports (daily/weekly/monthly)
- [ ] 9.3 Customer detailed view with history
- [ ] 9.4 Audit log viewer

---

## 🎨 UI/UX ENHANCEMENTS

### Task 10: Skeleton Loading Screens
**Status:** ⏳ NOT STARTED | **Priority:** MEDIUM | **Effort:** 2-4 hours

- [ ] 10.1 Add shimmer skeletons to shipment lists
- [ ] 10.2 Add skeletons to affiliate dashboard
- [ ] 10.3 Add skeletons to analytics charts
- [ ] 10.4 Add skeletons to customer list

---

### Task 11: Improve Error Handling
**Status:** ⏳ NOT STARTED | **Priority:** MEDIUM | **Effort:** 2-4 hours

- [ ] 11.1 Add error boundaries to main screens
- [ ] 11.2 Implement retry UI for failed network requests
- [ ] 11.3 Add offline indicator
- [ ] 11.4 Show user-friendly error messages

---

## 📊 PROGRESS TRACKER

| Task | Status | Effort | Completed Date |
|------|--------|--------|----------------|
| 1. Remove Payment Packages | ✅ Done | 10 min | Apr 8, 2026 |
| 2. Fix FCM Conflicts | ✅ Done | Already Impl | Apr 8, 2026 |
| 3. Delete Ecommerce Files | ✅ Done | Already Done | Apr 8, 2026 |
| 4. Test Guest Flow | 🔄 IN PROGRESS | 2-4 hrs | - |
| 5. Fix Tracking Lookup | ⏳ Pending | 2 hrs | - |
| 6. Add Pagination | ✅ Done | ~2 hrs | Apr 8, 2026 |
| 7. Fix Compilation Errors | ✅ Done | 30 min | Apr 8, 2026 |
| 8. Guest Mode Launch | ✅ Done | 15 min | Apr 9, 2026 |
| 9. Login/Logout Button | ✅ Done | 20 min | Apr 9, 2026 |
| 10. Complete Analytics | ⏳ Pending | 4-8 hrs | - |
| 11. Review Orders Module | ⏳ Pending | 2-4 hrs | - |
| 12. Add Missing Admin Screens | ⏳ Pending | 4-8 hrs | - |
| 13. Skeleton Loading | ⏳ Pending | 2-4 hrs | - |
| 14. Error Handling | ⏳ Pending | 2-4 hrs | - |

---

## 📦 COMPLETED MILESTONES

- [x] **Audit Report** - April 8, 2026
- [x] **Task Tracker Created** - April 8, 2026
- [x] **Task 1: Remove Payment Packages** - Already cleaned up
- [x] **Task 2: Fix FCM Conflicts** - Already fully implemented
- [x] **Task 3: Delete Ecommerce Remnants** - Already cleaned up
- [x] **Task 6: Add Pagination to Shipments** - April 8, 2026
- [x] **Fix Compilation Errors** - April 8, 2026
  - Fixed `user_role.dart` extension constructor error
  - Fixed `main_scaffold.dart` undefined `roles` getter
  - Fixed `active_role_provider.dart` UserRole enum issues
  - Fixed `shipper_gate.dart` undefined `roleStatus`
  - Fixed `shipment_request_form.dart` undefined `_trackingNumber`
  - Fixed `role_selection_screen.dart` missing superAdmin case
  - Fixed `shipping_requests_user_provider.dart` type casting
  - Fixed `shipping_request_repository.dart` DocumentSnapshot type
  - Fixed `create_sub_admin_dialog.dart` Family provider error
- [x] **Guest Mode Launch Screen** - April 9, 2026
  - App launches directly to HomeScreen in guest mode
  - Users can test full shipping flow without login
- [x] **Login/Logout Button** - April 9, 2026
  - Added Login and Sign Up buttons for guests
  - Added Logout button with confirmation dialog for logged-in users

---

## 🔗 REFERENCE LINKS

- **Firebase Console:** https://console.firebase.google.com/project/shopsnports
- **Firestore Rules:** [firestore.rules](firestore.rules)
- **Storage Rules:** [storage.rules](storage.rules)
- **Cloud Functions:** [functions/src/](functions/src/)
- **Admin Dashboard:** [admin/admin/lib/](admin/admin/lib/)
- **Mobile App:** [lib/](lib/)

---

*Tracker last updated: April 9, 2026*
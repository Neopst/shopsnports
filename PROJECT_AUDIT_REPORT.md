# SHOPSNPORTS COMPREHENSIVE AUDIT REPORT
## Freight/Cargo/Sea Shipping Platform
### Audit Date: March 27, 2026

---

## EXECUTIVE SUMMARY

| Aspect | Status | Health |
|--------|--------|--------|
| **Mobile App** | 70-80% Complete | GOOD |
| **Flutter Admin Dashboard** | 50-60% Complete | NEEDS WORK |
| **Firebase Functions** | 80% Complete | GOOD |
| **Ecommerce Cleanup** | PARTIAL | ACTION NEEDED |

---

## 1. FLUTTER MOBILE APP (lib/)

### Project Structure
```
lib/
├── screens/          (~100+ screens)
├── widgets/          (~40+ widgets)
├── providers/        (~20 providers - Riverpod)
├── services/         (~15 services)
├── models/           (~15 models)
├── repositories/     (~8 repositories)
└── core/             (config, routing, theme)
```

### ✅ SHIPPING FEATURES - IMPLEMENTED

| Feature | File(s) | Status |
|---------|---------|--------|
| **Shipping Request Forms** | `simple_shipping_request_form.dart`, `shipping_request_screen_new.dart`, `shipment_form.dart` | ✅ DONE |
| **Shipment Tracking** | `track_shipment_screen.dart`, `shipment_detail_screen.dart` | ✅ DONE |
| **Shipments List** | `shipments_list_screen.dart`, `shipments_screen.dart` | ✅ DONE |
| **Shipping History** | `shipping_history_screen.dart` | ✅ DONE |
| **Quote Request** | `quote_request_screen.dart` | ✅ DONE |
| **Tracking Lookup** | `tracking_lookup_screen.dart` | ✅ DONE |
| **Pickup Scheduling** | `pickup_scheduling_screen.dart` | ✅ DONE |

### ✅ AFFILIATE SYSTEM - IMPLEMENTED

| Feature | File(s) | Status |
|---------|---------|--------|
| **Affiliate Registration** | `affiliate_registration_screen.dart` | ✅ DONE |
| **Affiliate Dashboard** | `affiliate_dashboard_screen.dart`, `dashboard_screen.dart` | ✅ DONE |
| **Commission Tracking** | `commission_tracking_screen.dart` | ✅ DONE |
| **Payout Management** | `payouts_screen.dart`, `payout_management_screen.dart` | ✅ DONE |
| **Share Form Dialog** | `share_form_dialog.dart` | ✅ DONE |
| **Shipments List (Affiliate)** | `affiliate/shipments_list_screen.dart` | ✅ DONE |
| **Affiliate Profile** | `affiliate/profile_screen.dart` | ✅ DONE |

### ✅ AUTHENTICATION - IMPLEMENTED

| Feature | Status |
|---------|--------|
| **Email/Password** | ✅ DONE |
| **Phone Login** | ✅ DONE (`phone_login_screen.dart`) |
| **Google Sign-In** | ✅ DONE (via google_sign_in package) |
| **Role Selection** | ✅ DONE (`role_selection_screen.dart`) |
| **Forgot Password** | ✅ DONE |

### ⚠️ FCM NOTIFICATIONS - PARTIAL/BLOCKED

- `notification_service.dart` exists
- Has dependency conflicts with `firebase_analytics`
- **Action Required:** Resolve version conflicts

### ❌ PAYMENT GATEWAY - PARTIAL

| Package | Status |
|---------|--------|
| flutter_stripe ^9.0.0 | Present but NOT integrated |
| flutterwave_standard ^1.1.0 | Present but NOT integrated |
| flutter_paystack_plus ^2.3.0 | Present but NOT integrated |

**Question:** Do you need payment for shipping fees, or is this from the ecommerce pivot?

---

## 2. FLUTTER ADMIN DASHBOARD (admin/admin/lib/)

**Note:** Only the Flutter admin dashboard (NOT web-admin HTML) is in scope.

### Admin Features Structure

```
admin/admin/lib/features/
├── dashboard/           ✅ Admin dashboard
├── shipping/            ✅ Shipping request management
│   ├── shipping_list_screen.dart
│   ├── shipping_detail_screen.dart
│   └── shipping_request_management_screen.dart
├── affiliates/          ✅ Affiliate management
│   ├── affiliate_list_screen.dart
│   ├── affiliate_detail_screen.dart
│   └── affiliate_screen.dart
├── customers/           ✅ Customer management
├── orders/              ⚠️ NEEDS REVIEW
├── invoices/            ✅ Invoice management
├── payouts/             ✅ Payout management
├── analytics/           ⬜ Not reviewed
├── content/             ⬜ Content management
├── news_ticker/         ✅ News ticker management
├── banners/             ✅ Banner management
├── notifications/       ✅ Push notifications
├── auth/                ✅ Admin auth
├── settings/            ✅ Admin settings
└── super_admin/         ✅ Super admin features
```

### Admin Status

| Module | Files | Status | Notes |
|--------|-------|--------|-------|
| **Shipping Management** | 15+ files | ✅ COMPLETE | List, detail, documents |
| **Affiliate Management** | 7 files | ✅ COMPLETE | List, detail, status |
| **Customer Management** | Multiple | ✅ DONE | Standard CRUD |
| **Invoice Management** | Multiple | ✅ DONE | Invoice viewing |
| **Payout Management** | Multiple | ✅ DONE | Payout tracking |
| **Orders Module** | 10 files | ⚠️ CHECK | May need refactor for shipping |
| **Analytics** | Unknown | ⬜ NOT REVIEWED | Needs audit |
| **Content/Page Builder** | Unknown | ⬜ NOT REVIEWED | Needs audit |
| **Settings** | Multiple | ✅ DONE | Standard settings |

---

## 3. ECOMMERCE FILES TO DELETE/REFACTOR

### Files Requiring IMMEDIATE Action

| File Path | Type | Action |
|-----------|------|--------|
| `lib/widgets/add_product_dialog.dart` | Widget | **DELETE** - Pure ecommerce |
| `lib/screens/auth/vendor_registration_screen.dart` | Screen | **DELETE** - Vendor registration |
| `lib/screens/recommended_screen.dart` | Screen | **DELETE** - Ecommerce recommendations |
| `lib/screens/customer/customer_home_screen.dart` | Screen | **REFACTOR** or DELETE - May have mixed content |

### Files Requiring REVIEW

| File Path | Notes |
|-----------|-------|
| `lib/screens/payment/payment_billing_screen.dart` | Card storage - needed for shipping payments? |
| `lib/screens/customer/invoices_screen.dart` | May be shipping invoices, keep if relevant |
| `lib/screens/customer/invoice_detail_screen.dart` | Keep if shipping-related |

### Admin Orders Module - CHECK

```
admin/admin/lib/features/orders/
├── order_model.dart         - Has OrderType.freight, cargo, parcel
├── orders_screen.dart       - Uses OrderService
└── order_edit_drawer.dart
```

**Assessment:** The orders module appears refactored for shipping but needs verification.

---

## 4. FIREBASE CLOUD FUNCTIONS (functions/src/)

### All Functions - SHIPPING RELATED ✅

| Function | Purpose |
|----------|---------|
| `submitShipmentRequest.ts` | Handle form submissions |
| `createShipmentOnBehalf.ts` | Admin creates for clients |
| `onShipmentRequestCreated.ts` | Trigger on new shipment |
| `onShipmentRequestUpdated.ts` | Trigger on status changes |
| `onShippingRequestCreated.ts` | New simplified trigger |
| `onShippingRequestUpdated.ts` | Status update with auto commission |
| `generateShipmentLink.ts` | Shareable tracking links |
| `calculateCommission.ts` | Calculate affiliate commission |
| `generatePayoutRequest.ts` | Payout processing |
| `generateInvoice.ts` | Invoice generation |
| `generateAffiliateTokens.ts` | Token management |
| `onFormShareTokenUsed.ts` | Form share tracking |
| `createAdmin.ts` | Admin account creation |
| `changeAdminPassword.ts` | Password changes |
| `adminActivityLogger.ts` | Activity logging |
| `adminOperations.ts` | General admin tasks |

**Status:** ✅ All 18 functions are shipping-related. No ecommerce remnants found.

---

## 5. FIRESTORE COLLECTIONS

### Current Collections (from firestore.rules)

```
✅ KEEP (Shipping-related):
- customers/           - User profiles
- banners/             - Home carousel
- news_ticker/         - Announcements
- shippingRequests/    - Main shipping collection
- admins/              - Admin accounts
- affiliate_tokens/    - Affiliate tracking
- form_shares/         - Form sharing

⬜ NEED TO CHECK:
- shipment_requests/   - Legacy collection (marked deprecated in rules)
```

**Note:** No ecommerce collections (products, cart, wishlist, orders) found in rules.

---

## 6. DEPENDENCIES TO CLEAN (pubspec.yaml)

### Ecommerce Packages - RECOMMEND REMOVAL

```yaml
flutter_stripe: ^9.0.0         # DELETE unless needed for shipping payments
flutterwave_standard: ^1.1.0   # DELETE unless needed for shipping payments
flutter_paystack_plus: ^2.3.0  # DELETE unless needed for shipping payments
```

### Core Shipping Packages - KEEP

```yaml
firebase_core, firebase_auth, cloud_firestore, firebase_storage
firebase_messaging, firebase_analytics, firebase_crashlytics
geocoding, geolocator, http, intl, uuid
flutter_riverpod, shared_preferences, url_launcher
carousel_slider, file_picker, image_picker
```

---

## 7. USER ROLES & FLOWS

### Guest User (Unauthenticated)
```
1. View landing page
2. Create shipping request (guest checkout)
3. Track shipment via lookup
```

### Registered User (Shipper)
```
1. Full shipping request creation
2. View shipping history
3. Track own shipments
4. Profile management
5. Address management
```

### Affiliate
```
1. View commission dashboard
2. Track referrals via shared forms
3. Request payouts
4. View shipment details for referred requests
```

### Admin
```
1. Full shipping request management (CRUD)
2. Customer management
3. Affiliate management
4. Payout processing
5. Analytics & reports
```

---

## 8. ROADMAP TO COMPLETION

### Phase 1: CLEANUP (Week 1)

| Task | Priority | Effort |
|------|----------|--------|
| Delete `add_product_dialog.dart` | HIGH | 5 min |
| Delete `vendor_registration_screen.dart` | HIGH | 5 min |
| Delete `recommended_screen.dart` | HIGH | 5 min |
| Review `customer_home_screen.dart` | HIGH | 30 min |
| Review `payment_billing_screen.dart` | HIGH | 30 min |
| Clean up pubspec.yaml (payment packages) | MEDIUM | 10 min |
| Delete web-admin folder if present | LOW | 5 min |

### Phase 2: BUG FIXES & FCM (Week 1-2)

| Task | Priority | Effort |
|------|----------|--------|
| Fix FCM notification dependency conflicts | HIGH | 2-4 hours |
| Verify all shipping forms work end-to-end | HIGH | 4-8 hours |
| Test guest shipping request flow | HIGH | 2-4 hours |
| Verify tracking lookup works | MEDIUM | 2 hours |

### Phase 3: ADMIN DASHBOARD COMPLETION (Week 2-3)

| Task | Priority | Effort |
|------|----------|--------|
| Complete analytics module | HIGH | 4-8 hours |
| Complete content management | MEDIUM | 4 hours |
| Review/refactor orders → shipping module | HIGH | 2-4 hours |
| Add missing admin screens | MEDIUM | 4-8 hours |
| Admin reporting/analytics dashboard | MEDIUM | 4-8 hours |

### Phase 4: PAYMENT INTEGRATION (Week 3-4) - OPTIONAL

| Task | Priority | Effort |
|------|----------|--------|
| Decide: Include payment for shipping fees? | HIGH | - |
| If yes: Integrate Stripe/Flutterwave/Paystack | HIGH | 2-4 days |
| Add payment flow to shipping request | HIGH | 1-2 days |

### Phase 5: POLISH & LAUNCH (Week 4-5)

| Task | Priority | Effort |
|------|----------|--------|
| UI/UX enhancements | MEDIUM | 1-2 days |
| Testing & QA | HIGH | 2-3 days |
| Firebase deployment | HIGH | 1 day |
| App Store preparation | MEDIUM | 1 day |

---

## 9. ESTIMATED TIMELINE

| Phase | Duration | Total with Buffer |
|-------|----------|-------------------|
| Phase 1: Cleanup | 1-2 days | 1-2 days |
| Phase 2: Bug Fixes & FCM | 1 week | 1.5 weeks |
| Phase 3: Admin Completion | 2 weeks | 3.5 weeks |
| Phase 4: Payment (optional) | 1 week | 4.5 weeks |
| Phase 5: Polish & Launch | 1 week | 5.5 weeks |

**Realistic Estimate:** **6-8 weeks** to full production ready state

---

## 10. CRITICAL QUESTIONS

Before we proceed, please clarify:

1. **Payment Processing:** Do you need to collect shipping fees in-app, or is this handled separately?
   - If NO: Remove all payment packages and `payment_billing_screen.dart`
   - If YES: Integrate one payment gateway (recommend Stripe)

2. **Admin Dashboard:** Is the current Flutter admin sufficient, or do you want additional features?

3. **Guest Checkout:** Is the guest shipping request flow tested and working?

4. **Affiliate Flow:** Is the token-based affiliate tracking working end-to-end?

---

## 11. FILES TO DELETE IMMEDIATELY

```bash
# Run these deletions:
lib/widgets/add_product_dialog.dart
lib/screens/auth/vendor_registration_screen.dart
lib/screens/recommended_screen.dart
```

---

## NEXT STEPS

1. ✅ Review this report
2. ✅ Answer critical questions (Section 10)
3. ⬜ Approve cleanup Phase 1
4. ⬜ Start execution

---

*Report generated: March 27, 2026*
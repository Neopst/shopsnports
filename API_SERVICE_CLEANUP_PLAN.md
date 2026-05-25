# API SERVICE CLEANUP & MIGRATION PLAN

**Status:** Ready for Implementation  
**Date:** February 18, 2026  
**Scope:** Remove all REST API services, migrate to Firebase-only

---

## SERVICES TO REMOVE (REST API - Deprecated)

### 1. `lib/services/shipping_api_service.dart`
**Current Usage:** 
- `lib/screens/shipping/shipping_request_screen.dart`
- `lib/screens/shipping/shipping_request_screen_new.dart`
- `lib/screens/shipping/track_shipment_screen.dart`

**Action:** Delete file
**Migration:** Use `FirestoreShippingService` instead

---

### 2. `lib/services/affiliate_api_service.dart`
**Current Usage:**
- `lib/screens/affiliate/payout_management_screen.dart`
- `lib/screens/affiliate/commission_tracking_screen.dart`
- `lib/screens/affiliate/affiliate_dashboard_screen.dart`
- `lib/repositories/affiliate_shipment_repository.dart`
- `lib/providers/api_providers.dart`
- `lib/providers/affiliate_shipment_providers.dart`

**Action:** Delete file
**Migration:** Create `lib/services/affiliate_firestore_service.dart` with Firestore reads

---

### 3. `lib/services/invoices_api_service.dart`
**Current Usage:** Admin dashboard

**Action:** Delete file
**Migration:** Use direct Firestore `invoices/` collection queries

---

### 4. `lib/services/affiliate_api.dart` (if exists)
**Action:** Delete file

---

## PROVIDERS TO UPDATE

### 1. `lib/providers/affiliate_api_provider.dart`
**Current:** Uses `affiliate_api.dart`
**Action:** Update to use Firestore listeners instead

---

## CLOUD FUNCTIONS TO DELETE (Legacy - Deprecated)

### Files in `functions/src/`:

1. **onShipmentRequestCreated.ts** - OLD shipment_requests trigger
2. **onShipmentRequestUpdated.ts** - OLD shipment_requests trigger
3. **submitShipmentRequest.ts** - OLD REST API function
4. **generateShipmentLink.ts** - OLD REST API function
5. **createShipmentOnBehalf.ts** - OLD REST API function

**Keep:** These 5 files can be removed after migration is complete

---

## NEW FIRESTORE SERVICES TO CREATE

### 1. `lib/services/affiliate_firestore_service.dart`
**Purpose:** Replace `affiliate_api_service.dart`
**Methods:**
- `getAffiliate(affiliateId)` - Stream
- `getCommissions(affiliateId)` - Stream (filtered for this affiliate)
- `getPayouts(affiliateId)` - Stream
- `updateBankDetails(affiliateId, details)` - Callable function
- `getEarningsSummary(affiliateId)` - Calculated from commissions

**Status:** ⏳ TO CREATE

---

### 2. `lib/services/commission_firestore_service.dart`
**Purpose:** Handle commission operations
**Methods:**
- `getAffiliateCommissions(affiliateId)` - Stream
- `getAdminCommissions()` - Stream for admin
- `watchPendingCommissions()` - Real-time for admin
- Call Cloud Function: `calculateAffiliateCommission`

**Status:** ⏳ TO CREATE

---

### 3. `lib/services/payout_firestore_service.dart`
**Purpose:** Handle payout operations
**Methods:**
- `getAffiliatePayouts(affiliateId)` - Stream
- `getAllPayouts()` - Stream for admin
- Call Cloud Function: `generatePayment`
- Call Cloud Function: `processsPayment` (note the typo in export!)

**Status:** ⏳ TO CREATE

---

## MIGRATION CHECKLIST

**Phase 1: Update Screens**
- [ ] Update `shipping_request_screen.dart` - Use FirestoreShippingService
- [ ] Update `shipping_request_screen_new.dart` - Use FirestoreShippingService
- [ ] Update `track_shipment_screen.dart` - Use Firestore listeners

**Phase 2: Update Affiliate Screens**
- [ ] Update `affiliate_dashboard_screen.dart` - Use new Firestore services
- [ ] Update `commission_tracking_screen.dart` - Use CommissionFirestoreService
- [ ] Update `payout_management_screen.dart` - Use PayoutFirestoreService

**Phase 3: Create New Services**
- [ ] Create `affiliate_firestore_service.dart`
- [ ] Create `commission_firestore_service.dart`
- [ ] Create `payout_firestore_service.dart`

**Phase 4: Update Providers**
- [ ] Update `affiliate_api_provider.dart` - Use Firestore
- [ ] Update `api_providers.dart` - Remove REST API references
- [ ] Update `affiliate_shipment_providers.dart` - Use Firestore

**Phase 5: Delete Old Files**
- [ ] Delete `affiliate_api_service.dart`
- [ ] Delete `shipping_api_service.dart`
- [ ] Delete `invoices_api_service.dart`
- [ ] Delete Cloud Functions (after full migration):
  - onShipmentRequestCreated.ts
  - onShipmentRequestUpdated.ts
  - submitShipmentRequest.ts
  - generateShipmentLink.ts
  - createShipmentOnBehalf.ts

**Phase 6: Cleanup**
- [ ] Update `functions/src/index.ts` - Remove legacy exports
- [ ] Test all flows end-to-end
- [ ] Verify no broken imports

---

## COMPLETION CRITERIA

✅ All screens use Firestore services  
✅ All state management uses Firestore listeners  
✅ All API calls eliminated  
✅ All REST API services deleted  
✅ Cloud Functions only include new shipping_requests functions  
✅ Firebase is the only source of truth  
✅ E2E tests all pass  

---

## TIMELINE

**Estimated:** 3-4 hours  
**Start:** After user approval  
**Dependency:** Phase 14D (this document)

---

## NOTES

- This is a **breaking change** - cannot run old and new side-by-side
- Must test thoroughly after each phase
- Database will be Firebase only (no PostgreSQL)
- All mobile app features will read/write directly to Firestore
- No backend API layer except Cloud Functions for business logic

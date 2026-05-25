# Firestore Cleanup & Fresh Start Guide

**Status:** All mock data removed from code ✅

## Summary

All hardcoded mock shipping data has been removed from the codebase:
- ❌ Removed `seedSampleData()` method from `shipping_repository_firestore.dart`
- ❌ Disabled `lib/seed_shipping.dart` seeding script
- ❌ Disabled `admin/admin/seed_shipping_simple.dart` seeding script  
- ❌ Removed `sampleRequestSummary` field from mobile form submissions

**All code now uses LIVE Firestore `shippingRequests` collection only.**

---

## Step 1: Delete Old Mock Data from Firestore

### Via Firebase Console (Recommended)

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select **shopsnports** project
3. Navigate to **Firestore Database**
4. Find the **shippingRequests** collection
5. For each document, click the **menu (⋮)** → **Delete document**
   - Repeat until collection is empty, OR
6. **Delete entire collection:**
   - Click the **menu (⋮)** next to collection name → **Delete collection**
   - Confirm deletion
   - **Note:** Collection will be auto-recreated when first document is added

### Via Firebase Admin SDK (Bash/Node.js)

```bash
# Install Firebase CLI if needed
npm install -g firebase-tools

# Login
firebase login

# Set project
firebase use shopsnports

# Run shell
firebase firestore:delete shippingRequests --all
```

---

## Step 2: Verify Collection Structure

**Firestore Collection: `shippingRequests`**

Expected fields per document:
```dart
{
  id: string (auto-generated doc ID)
  requesterId: string (Firebase UID of requester)
  affiliateId: string (optional - affiliate partner)
  clientName: string
  clientEmail: string (validated email)
  clientPhone: string
  
  // Shipment details
  type: string (enum: 'air', 'sea', 'land')
  status: string (enum: 'pending', 'approved', 'inTransit', 'delivered', 'rejected', 'cancelled')
  priority: string (enum: 'economy', 'standard', 'express', 'urgent')
  
  origin: string (city or coordinates)
  destination: string (city or coordinates)
  description: string
  
  // Dimensions & weight
  weight: double (kg)
  length: double (cm)
  width: double (cm)
  height: double (cm)
  
  // Costs
  estimatedCost: double (USD)
  actualCost: double (USD, 0 until delivered)
  estimatedDelivery: timestamp (optional)
  actualDelivery: timestamp (optional)
  
  // Insurance & customs
  requiresInsurance: boolean
  requiresCustomsClearance: boolean
  
  // Affiliate
  affiliateCommission: double (USD, 0 if no affiliate)
  
  // Tracking
  trackingNumber: string (format: SHP-YYYYMMDD-XXXXX)
  
  // Metadata
  createdAt: timestamp (server time)
  updatedAt: timestamp (server time)
}
```

---

## Step 3: Verify Security Rules

✅ **Security rules already applied** in `firestore.rules`

Key rules:
- Only authenticated users can create/read own requests
- Admin can read/update all requests
- Affiliates can read requests they're associated with
- Timestamps auto-generated server-side

---

## Step 4: Verify Indexes

✅ **5 composite indexes already created:**

Index 1: `shippingRequests` (status, createdAt DESC)
Index 2: `shippingRequests` (requesterId, createdAt DESC)
Index 3: `shippingRequests` (status, createdAt DESC, requesterId)
Index 4: `shippingRequests` (affiliateId, status, createdAt DESC)
Index 5: `shippingRequests` (status, priority, createdAt DESC)

View indexes: [Firebase Console → Firestore → Indexes](https://console.firebase.google.com/project/shopsnports/firestore/indexes)

---

## Step 5: Collection Name Verification

✅ **All codebase verified** - Using `'shippingRequests'` consistently:

**Mobile (Flutter):**
- `lib/models/shipping_request_simplified.dart` → Model definition
- `lib/repositories/shipping_request_repository.dart` → All 5 queries
- `lib/providers/shipping_submission_provider.dart` → Submission handler
- `lib/services/shipping_firestore_service.dart` → Service layer
- `lib/screens/shipping/simple_shipping_request_form.dart` → Form submission

**Admin (Flutter Web):**
- `admin/admin/lib/features/shipping/data/repositories/shipping_repository_firestore.dart` → Repository (collection: 'shippingRequests')
- `admin/admin/lib/features/shipping/presentation/providers/shipping_requests_providers_admin.dart` → All providers

**Cloud Functions:**
- `functions/src/onShippingRequestCreated.ts` → Listens to `shippingRequests` collection

---

## Step 6: Test Live Data Flow

### Create Real Test Data

**Option A: Mobile App**
1. Run mobile app on emulator (ensure network enabled)
2. Create user account
3. Navigate to **Shipping** tab
4. Fill out shipping form with real data
5. Submit
6. Check Firestore Console → Should see new document in `shippingRequests`

**Option B: Admin Dashboard** (create manually)
1. Open [Firebase Console](https://console.firebase.google.com)
2. Go to Firestore → `shippingRequests`
3. Click **Add document**
4. Fill in required fields
5. Save

### Verify Mobile<→Firestore<→Admin Sync

1. **Mobile app** submits shipping request
   - ✅ Document created in `shippingRequests`
   - ✅ Tracking number generated: `SHP-YYYYMMDD-XXXXX`
   - ✅ Confirmation email sent to customer (if SMTP configured)

2. **Admin dashboard** displays request
   - Open dashboard in browser
   - Check **Shipping List** screen
   - Should show real-time request from Firestore

3. **Admin approves request**
   - Status changes: pending → approved
   - Mobile app sees real-time update (streaming)

4. **Admin marks in transit**
   - Status changes: approved → inTransit
   - Mobile tracking screen shows updated status

---

## Step 7: SMTP Configuration (For Email Notifications)

Cloud Functions are deployed and ready to send emails. Configure SMTP credentials:

### Set Environment Variables in Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/project/shopsnports/functions)
2. Select **Functions** → **onCustomerCreated** (or onShippingRequestCreated)
3. Click **Edit**
4. In **Runtime environment variables**, add:
   ```
   SMTP_HOST=smtp.gmail.com
   SMTP_PORT=587
   SMTP_USER=your-email@gmail.com
   SMTP_PASS=your-app-password
   SMTP_SECURE=false
   ```

5. Save and redeploy

**Result:** Customers will receive:
- Welcome email when creating account
- Shipment confirmation email with tracking number

---

## Troubleshooting

### "Collection 'shippingRequests' does not exist"
- **Cause:** Collection auto-deleted when empty
- **Fix:** Submit new request through mobile app to recreate it

### "No data showing in admin dashboard"
- **Check:**
  1. Admin Dashboard running? (Flutter web server)
  2. Mobile app submitted request? (Check Firestore Console)
  3. Real-time provider refreshing? (Check browser console for errors)

### "Tracking number not generated"
- **Cause:** Cloud Function not deployed
- **Fix:** Run `firebase deploy --only functions` from `/functions` folder

### "Emails not sending"
- **Cause:** SMTP env vars not set
- **Fix:** Configure in Firebase Console (see Step 7)

---

## Code Usage Summary

### Mobile App - Submit Request
```dart
// lib/providers/shipping_submission_provider.dart
final response = await shippingRequestRepository.createShippingRequest(
  requesterId: userId,
  data: formData, // Auto-generates trackingNumber
);
// Auto-generated tracking format: SHP-20260302-ABC12
```

### Admin Dashboard - Read Requests
```dart
// admin/admin/lib/features/shipping/presentation/providers/shipping_requests_providers_admin.dart
final requests = await repository.getShippingRequests(
  status: selectedStatus,
  shippingType: selectedType,
);
// Real-time streaming available via streamShippingRequests()
```

### Cloud Functions - Listen for New Requests
```typescript
// functions/src/onShippingRequestCreated.ts
export const onShippingRequestCreated = functions.firestore
  .document('shippingRequests/{docId}')
  .onCreate(async (snap, context) => {
    // Sends email with tracking number
    // Sends push notifications to admins
  });
```

---

## Timeline

| Step | Status | Details |
|------|--------|---------|
| 1. Delete old data | ⏳ Manual | Via Firebase Console |
| 2. Verify structure | ✅ Auto | Fields match all models |
| 3. Security rules | ✅ Auto | Already deployed |
| 4. Indexes | ✅ Auto | 5 composite indexes active |
| 5. Collection naming | ✅ Auto | All code verified |
| 6. Test live data | ⏳ Manual | Run mobile + admin apps |
| 7. SMTP config | ⏳ Manual | Set env vars in Firebase Console |

---

## Success Criteria

✅ You'll know it's working when:
1. Mobile app submits request → Firestore has new document in `shippingRequests`
2. Admin dashboard auto-refreshes to show new request
3. Tracking number present in request document (format: `SHP-YYYYMMDD-XXXXX`)
4. Admin approves request → Mobile app sees status change in real-time
5. Confirmation email received (requires SMTP setup)

---

**Need help?** Check recent tool outputs or Cloud Functions logs in Firebase Console.

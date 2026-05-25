# Complete Customer/Guest Shipper Journey - Testing & Verification

**Status:** ✅ All systems integrated and ready for end-to-end testing

---

## System Overview

```
Customer/Guest A submits shipping request from mobile app
              ↓
         Auto-generate tracking number (SHP-YYYYMMDD-XXXXX)
              ↓
         Save to Firestore: shippingRequests collection
              ↓
         Cloud Function triggered: onShippingRequestCreated
              ↓
    ┌─────────┼─────────┬──────────┐
    ↓         ↓         ↓          ↓
Email to   Push Notify  Admin Notif  Affiliate Notif
Customer   Devices      Created      Created
(if SMTP)  (if FCM)     (Firestore)  (Firestore)
    ↓         ↓         ↓          ↓
Tracking#   Real-time   Real-time   Real-time
+ Message   Updates     Admin Panel Updates
    
              ↓
         Admin Dashboard views in real-time
              ↓
         Admin approves/updates status
              ↓
         Customer sees update in "My Shipments"
         + Push notification (if enabled)
```

---

## Complete Test Checklist

### **Test 1: User Account & Setup (Pre-Submission)**

- [ ] **Create a new test account in mobile app**
  - Go to mobile app
  - Click "Sign Up"
  - Email: `test_customer@example.com`
  - Name: `Test Customer`
  - Password: Any strong password
  - Click "Create Account"
  - Verify: App shows "Account Created" ✅

- [ ] **Verify user is authenticated in Firebase**
  - Go to Firebase Console → Authentication
  - Find `test_customer@example.com`
  - User appears in list ✅

---

### **Test 2: Mobile App - Ship Request Submission**

- [ ] **Navigate to Shipping form**
  - In mobile app, click **Shipping** tab
  - Click **Create New Shipment** button
  - Form loads with all 21 fields ✅

- [ ] **Fill shipping form with test data**

| Field | Test Value |
|-------|---|
| Sender Name | Test Customer |
| Sender Email | test_customer@example.com |
| Sender Phone | +1-555-0100 |
| **Type** | Air |
| **Priority** | Standard |
| **Origin** | New York, USA |
| **Destination** | Lagos, Nigeria |
| **Description** | Test electronics shipment |
| **Weight** | 50.5 kg |
| **Length** | 80 cm |
| **Width** | 60 cm |
| **Height** | 50 cm |
| **Estimated Cost** | 2500 USD |
| **Insurance Required** | ✅ Yes |
| **Customs Clearance** | ✅ Yes |
| **Attachments** | Upload 1 file (optional) |

- [ ] **Submit the form**
  - Click **Submit Shipment**
  - Wait for response
  - Verify: Success message displays ✅
  - Check: Tracking number visible (format: SHP-YYYYMMDD-XXXXX) ✅

---

### **Test 3: Firestore - Document Verification**

- [ ] **Check Firestore console**
  - Go to [Firebase Console](https://console.firebase.google.com/project/shopsnports/firestore/data)
  - Click **shippingRequests** collection
  - **Should show 2 documents:**
    - Original sample document (SHP-20260302-SAMPLE)
    - New test document from mobile submission ✅

- [ ] **Verify document structure**
  - Click new test document
  - **Fields present:**
    - [ ] id: (Firestore auto-generated)
    - [ ] requesterId: (matches logged-in user UID)
    - [ ] trackingNumber: (SHP-YYYYMMDD-XXXXX format)
    - [ ] status: "pending"
    - [ ] clientName: "Test Customer"
    - [ ] clientEmail: "test_customer@example.com"
    - [ ] clientPhone: "+1-555-0100"
    - [ ] type: "air"
    - [ ] origin: "New York, USA"
    - [ ] destination: "Lagos, Nigeria"
    - [ ] weight: 50.5
    - [ ] createdAt: (server timestamp) ✅
    - [ ] All other fields populated ✅

---

### **Test 4: Email Notification**

- [ ] **Check confirmation email**
  - Subject: `Shipping Request Confirmed - Tracking: SHP-...`
  - Recipient: `test_customer@example.com`
  - **Email contains:**
    - [ ] ✅ Tracking number prominently displayed
    - [ ] ✅ "One of our agents will contact you shortly"
    - [ ] ✅ Destination: "Lagos, Nigeria"
    - [ ] ✅ Contact info: support@shopsnports.com
    - [ ] ✅ Professional HTML template

  **Note:** If email not received:
  - Check spam folder
  - Verify SMTP env vars set in Firebase Console (see Requirements section)

---

### **Test 5: Admin Dashboard - Real-Time Display**

- [ ] **Open admin dashboard**
  - Run: `cd admin/admin && flutter run -d chrome`
  - Navigate to **Shipping** section
  - Click **Shipping List** tab

- [ ] **Verify real-time display**
  - **Should show 2 shipping requests:**
    - Sample request (manually created)
    - New test request (from mobile) ✅

- [ ] **Verify fields display correctly**
  - Test request card shows:
    - [ ] Shipment ID (first 8 chars)
    - [ ] Status: "pending"
    - [ ] Route: "New York, USA → Lagos, Nigeria"
    - [ ] Recipient: "Test Customer"
    - [ ] Tracking number: SHP-...
    - [ ] Date: Today's date ✅

---

### **Test 6: User's Shipping History - Mobile App**

- [ ] **Navigate to user's shipments**
  - In mobile app, go to **My Account** → **My Shipments**
  - OR click **Shipping History** tab

- [ ] **Verify shipping history**
  - **Should display:**
    - [ ] Newly submitted request ✅
    - [ ] Status shows: "Processing"
    - [ ] Tracking number visible
    - [ ] Route shown
    - [ ] Date shown

- [ ] **Complete filtering test**
  - Filter by "Processing" → Only test request shows ✅
  - Filter by "Delivered" → No requests shown ✅
  - Filter by "All" → Shows all requests ✅

---

### **Test 7: Admin Actions & Real-Time Sync**

- [ ] **Admin approves request**
  - In admin dashboard, click test request
  - Click **Approve** button
  - Status changes: "pending" → "approved"
  - Verify: Admin list updates in real-time ✅

- [ ] **Mobile app shows real-time update**
  - Go back to mobile app's "My Shipments"
  - **Verify:** Status changed to "Approved" ✅
  - No manual refresh needed (streaming) ✅

- [ ] **Admin marks as "In Transit"**
  - In admin dashboard, click **Mark as In Transit**
  - Status changes: "approved" →"inTransit"

- [ ] **Mobile app real-time update**
  - Mobile "My Shipments" shows "In Transit" ✅
  - No manual refresh (real-time streaming) ✅

---

### **Test 8: Tracking Number Generation**

- [ ] **Verify tracking number format**
  - Format must be: `SHP-YYYYMMDD-XXXXX`
  - Example: `SHP-20260302-ABC12`
  - [ ] Contains: SHP prefix ✅
  - [ ] Contains: Today's date (YYYYMMDD) ✅
  - [ ] Contains: 5 random alphanumeric chars ✅

- [ ] **Test multiple submissions**
  - Submit 3 more test requests
  - Each should have unique tracking number
  - Verify: All follow correct format ✅

---

### **Test 9: Guest User Handling** (If applicable)

- [ ] **Create request without account**
  - If available, find "Guest Submission" flow
  - OR create request as separate user

- [ ] **Verify guest data flow:**
  - Form submission works ✅
  - Data appears in Firestore ✅
  - Admin can see request ✅
  - Email sends (if address provided) ✅

---

### **Test 10: Data Integrity**

- [ ] **Verify requesterId filtering**
  - Each user sees ONLY their own requests ✅
  - No cross-user data leakage ✅

- [ ] **Verify timestamps**
  - createdAt: Set to submission time ✅
  - updatedAt: Updates when status changes ✅

- [ ] **Verify status mapping**
  - Firestore value → UI display:
    - pending → "Processing" ✅
    - approved → "Approved" ✅
    - inTransit → "In Transit" ✅
    - delivered → "Delivered" ✅
    - cancelled/rejected → "Cancelled" ✅

---

## Requirements Before Full Test

### **Email Notifications**

For emails to send, you must configure SMTP:

1. Go to [Firebase Console](https://console.firebase.google.com/project/shopsnports/functions/details)
2. Find **onCustomerCreated** or **onShippingRequestCreated** function
3. Click **Edit** → **Runtime environment variables**
4. Set:
   ```
   SMTP_HOST=smtp.gmail.com
   SMTP_PORT=587
   SMTP_USER=noreply@shopsnports.com
   SMTP_PASS=<your-app-password>
   SMTP_SECURE=false
   ```
5. **Save and redeploy**

Without this, emails won't send (but all other flows work).

---

## Troubleshooting

### "Shipment appears in Firestore but not in admin dashboard"
- [ ] Refresh admin dashboard (F5)
- [ ] Verify admin logged in
- [ ] Check browser console for errors

### "No shipments showing in 'My Shipments'"
- [ ] Verify user is logged in to mobile app
- [ ] Check requesterId in Firestore matches logged-in user UID
- [ ] Refresh list (pull-down)

### "Tracking number not generating"
- [ ] Verify `_generateTrackingNumber()` in `shipping_submission_provider.dart`
- [ ] Check Firestore document has trackingNumber field

### "Email not received"
- [ ] Check spam/promotions folder
- [ ] Verify SMTP_PASS is correct in Firebase Console
- [ ] Check Cloud Functions logs for errors

### "Admin doesn't see status updates in real-time"
- [ ] Verify Firestore security rules allow reads
- [ ] Check browser console for streaming errors
- [ ] Verify user has admin role

---

## Success Criteria ✅

You'll know everything works when:

1. ✅ Mobile user submits shipping request
2. ✅ Tracking number auto-generated (SHP-YYYYMMDD-XXXXX format)
3. ✅ Data saved to Firestore shippingRequests collection
4. ✅ Admin dashboard shows request in real-time (no refresh needed)
5. ✅ Admin approves request
6. ✅ Mobile app shows "Approved" status in real-time (no refresh needed)
7. ✅ Confirmation email received with tracking number and agent contact message
8. ✅ User's "My Shipments" page shows only their requests
9. ✅ All fields display correctly in all interfaces
10. ✅ Status filtering works correctly

---

## Next Steps After Testing

Once customer/guest flow complete:
1. ✅ Verify all 10 tests pass
2. ✅ Document any issues/fixes needed
3. → **Move to Affiliate Integration Phase**
   - Affiliate tokens
   - Commission tracking
   - Affiliate dashboard/history

---

## Files Modified/Created For This Test

| File | Change | Status |
|------|--------|--------|
| `lib/providers/shipping_requests_user_provider.dart` | NEW - Firestore provider with status mapping | ✅ Created |
| `lib/screens/shipments/shipments_list_screen.dart` | Updated to use Firestore instead of mock | ✅ Updated |
| `functions/src/onShippingRequestCreated.ts` | Added "agents will contact shortly" to email | ✅ Updated |

---

**Ready to test?** Start with **Test 1** above and work through all 10 tests systematically. Report results!

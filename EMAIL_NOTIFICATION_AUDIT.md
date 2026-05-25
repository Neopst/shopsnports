# EMAIL NOTIFICATION SYSTEM AUDIT & TESTING GUIDE

**Last Updated:** March 2, 2026  
**Status:** ⏳ COMPREHENSIVE AUDIT IN PROGRESS

---

## 1. SYSTEM OVERVIEW

The system uses **Cloud Functions + Nodemailer** to send emails on two main events:

### 1.1 Email Triggers

| Event | Function | Recipient | Email Type |
|-------|----------|-----------|-----------|
| Shipping request created | `onShippingRequestCreated` | Customer (requester) | Confirmation + Tracking # |
| Shipping request updated (future) | `onShippingRequestUpdated` | Customer + Admin | Status change notification |
| Customer account created (legacy) | `onCustomerCreated.js` | New customer | Welcome email |

---

## 2. CONFIGURATION STATUS

### 2.1 SMTP Configuration
- **Host:** smtp.shopsnports.com ✅
- **Port:** 587 ✅
- **User:** noreply@shopsnports.com ✅
- **Password:** Stored in `.env.onCustomerCreated` ✅
- **Secure (TLS):** false ✅
- **Location:** `c:\projects\shopsnports\functions\.env.onCustomerCreated`

### 2.2 Environment Variables Deployment
- **Status:** ⏳ NEEDS VERIFICATION
- **Question:** Are `.env` variables loaded into Cloud Functions runtime?
- **Expected:** Firebase CLI should deploy `.env` to function environment during `firebase deploy --only functions`
- **Command to deploy:**
  ```bash
  firebase deploy --only functions --debug
  ```

---

## 3. CLOUD FUNCTION IMPLEMENTATION

### 3.1 onShippingRequestCreated.ts - COMPREHENSIVE ANALYSIS

**File:** `functions/src/onShippingRequestCreated.ts` (380 lines)  
**Type:** Firestore trigger  
**Trigger:** `onCreate` for `shipping_requests/{requestId}`

#### Functionality:
1. ✅ **Affiliate Token Validation** (Lines 26-79)
   - Validates affiliate token if provided
   - Marks token as used
   - Tags affiliate from token

2. ✅ **Admin Notification** (Lines 85-106)
   - Creates Firestore notification document
   - Includes request details, sender info, affiliate tagging

3. ✅ **Affiliate Notification** (Lines 109-135)
   - Creates Firestore notification for tagged affiliate
   - Includes token info

4. ✅ **FCM Push Notifications** (Lines 138-195)
   - Sends push to admin devices
   - Sends push to affiliate devices (if tagged)
   - Includes request details

5. ✅ **EMAIL NOTIFICATION - CUSTOMER** (Lines 198-328)
   - **SMTP Connection:** Lines 228-237
     - Uses Nodemailer with SMTP config
     - Reads from `process.env.SMTP_HOST/PORT/USER/PASS/SECURE`
   - **Email Content:** Lines 239-328
     - Professional HTML template
     - Includes tracking number prominently
     - Contains "One of our agents will contact you shortly"
     - Includes destination, request date, next steps
     - Contact info: support@shopsnports.com, +234 803 123 4567
   - **Subject:** "Shipping Request Confirmed - Tracking: {trackingNumber}"
   - **From:** noreply@shopsnports.com
   - **To:** `updatedRequestData.senderEmail`
   - **Error Handling:** Lines 322-327 (logs warning if SMTP_PASS not configured)

6. ✅ **Activity Logging** (Lines 330-344)
   - Logs event to `activity_log` collection
   - Records affiliate token usage
   - Includes shipping details

#### Issues Found:
None critical - function looks complete!

---

## 4. EMAIL DELIVERY ANALYSIS

### 4.1 Field Mappings in onShippingRequestCreated
```typescript
// Lines accessing database fields:
const trackingNumber = updatedRequestData.trackingNumber || requestId;  // ✅
const senderName = updatedRequestData.senderName || 'Valued Customer';  // ✅
const destination = updatedRequestData.destinationLocation || 'Unknown';  // ✅
```

**Note:** Function uses old field names (senderEmail, senderName, destinationLocation)  
**Status:** ✅ CONSISTENT with database schema (ShippingRequestSimplified model)

### 4.2 Email Template Quality
```html
✅ Professional branding (Shop's & Ports)
✅ Tracking number prominently displayed (24pt, bold, monospace)
✅ Clear CTAs (tracking link placeholder ready)
✅ Contact information provided
✅ Agent contact promise included
✅ HTML5 + inline CSS for compatibility
✅ Responsive design (max-width: 600px)
```

---

## 5. DEPENDENCIES VERIFICATION

### 5.1 Package Dependencies
| Package | Version | Purpose | Status |
|---------|---------|---------|--------|
| firebase-functions | 4.9.0 | Cloud Functions runtime | ✅ |
| firebase-admin | ^5.0.0 | Firestore + Auth | ✅ |
| nodemailer | 6.9.7 | SMTP email sending | ✅ |

**File:** `functions/package.json`

### 5.2 Imports in onShippingRequestCreated.ts
```typescript
import * as functions from 'firebase-functions';      // ✅
import * as admin from 'firebase-admin';             // ✅
import nodemailer from 'nodemailer';                 // ✅
```

All dependencies present and available.

---

## 6. DEPLOYMENT STATUS

### 6.1 Current Deployment
- **Last Deploy:** Unknown - need to check Firebase Console
- **Function Export:** Lines 47-50 in `functions/src/index.ts`
  ```typescript
  export const shippingRequestCreated = functions.firestore
    .document('shipping_requests/{requestId}')
    .onCreate(onShippingRequestCreated);
  ```
- **Status:** ✅ Properly exported

### 6.2 Build Status
- **TypeScript Compilation:** Need to verify `npm run build`
- **Output:** `functions/lib/onShippingRequestCreated.js` should exist
- **Status:** ⏳ NEEDS VERIFICATION

---

## 7. TESTING STRATEGY

### 7.1 Unit Test: Email Configuration
```typescript
// Test: Verify SMTP config loads
const config = {
  host: process.env.SMTP_HOST,
  port: parseInt(process.env.SMTP_PORT || '587'),
  user: process.env.SMTP_USER,
  pass: process.env.SMTP_PASS,
  secure: (process.env.SMTP_SECURE || 'false') === 'true'
};
// Expected: All fields populated from .env
```

### 7.2 Integration Test: Email on Request Creation
**Steps:**
1. Start emulator: `firebase emulators:start`
2. Create shipping request via mobile app
3. Check Firebase Console Functions logs
4. Search for: "✅ Confirmation email sent to"
5. Verify email fields logged

### 7.3 End-to-End Test: Production Email
**Steps:**
1. Deploy functions: `firebase deploy --only functions`
2. Create shipping request with real email
3. Wait 30 seconds
4. Check email inbox
5. Verify tracking number received
6. Verify agent contact message
7. Test tracking link (if implemented)

### 7.4 Load Test: Multiple Requests
**Steps:**
1. Create 5 shipping requests rapidly
2. All should generate emails
3. Monitor function logs for errors
4. Check for rate limiting issues

---

## 8. COMMON ISSUES & DIAGNOSIS

### Issue #1: Email Not Sending
**Symptom:** Function logs say "SMTP_PASS not configured"  
**Cause:** Environment variables not deployed  
**Fix:**
```bash
firebase functions:config:set smtp.password="YOUR_PASS"
firebase deploy --only functions
```

### Issue #2: Email Sent But Not Received
**Symptom:** Logs show "✅ email sent" but inbox empty  
**Causes:**
- SMTP server down (smtp.shopsnports.com)
- Email blocked by spam filter
- Wrong recipient email in database
**Diagnosis:**
- Test SMTP: `telnet smtp.shopsnports.com 587`
- Check spam folder
- Log recipient email from database

### Issue #3: SMTP Connection Timeout
**Symptom:** "Error connecting to SMTP host"  
**Cause:** Network/firewall blocking port 587  
**Fix:**
- Verify SMTP_HOST is reachable
- Check firewall rules
- Try different SMTP port (25, 465, 587)

### Issue #4: Email Template Rendering
**Symptom:** Email received but formatting broken  
**Cause:** HTML not rendering in inbox  
**Fix:**
- Use `html` field instead of `text` ✅ (already done)
- Inline all CSS (done)
- Test with various email clients

---

## 9. FIRESTORE NOTIFICATIONS DATABASE

### 9.1 Notifications Collection Schema
When email sent, Firestore document also created:
```json
{
  "type": "new_shipping_request",
  "requestId": "req_123",
  "senderName": "John Doe",
  "senderEmail": "john@example.com",
  "targetRole": "admin",
  "read": false,
  "createdAt": "2026-03-02T10:00:00Z",
  "message": "New shipping request from John Doe..."
}
```

---

## 10. ACTION ITEMS

### Phase 1 - Immediate (Today)
- [ ] Verify SMTP config deployed to Firebase
  ```bash
  firebase functions:config:get
  ```
- [ ] Check function logs in Firebase Console
  - Go to: https://console.firebase.google.com → Functions → Logs
  - Filter: `onShippingRequestCreated`
  - Look for "✅ Confirmation email sent to"

- [ ] Test email send with emulator
  ```bash
  firebase emulators:start
  # Create request, check logs
  ```

### Phase 2 - Production Testing
- [ ] Deploy latest functions
  ```bash
  firebase deploy --only functions --debug
  ```
- [ ] Create real shipping request
- [ ] Verify email received with:
  - ✅ Correct tracking number
  - ✅ Customer name (senderName)
  - ✅ Destination (destinationLocation)
  - ✅ Agent contact message
  - ✅ Support contact info

### Phase 3 - Monitoring
- [ ] Set up email error alerts
- [ ] Monitor email delivery rate
- [ ] Create dashboard for failed emails
- [ ] Document troubleshooting procedures

---

## 11. CURRENT BLOCKERS

| Issue | Priority | Status | Resolution |
|-------|----------|--------|-----------|
| Verify SMTP deployed | High | ⏳ TO DO | Run `firebase functions:config:get` |
| Test email send | High | ⏳ TO DO | Create test request, check logs |
| Email delivery confirmation | Med | ⏳ TO DO | Check production email inbox |
| Template rendering | Med | ⏳ TO DO | Test in various clients |
| Load testing | Low | ⏳ TO DO | Create 5+ requests rapidly |

---

## 12. REFERENCE DOCUMENTS

- [onShippingRequestCreated.ts](functions/src/onShippingRequestCreated.ts) - Source code
- [Nodemailer Docs](https://nodemailer.com) - Email library
- [Firebase Functions Config](https://firebase.google.com/docs/functions/config-env) - Env setup
- [ShippingRequestSimplified Model](lib/models/shipping_request_simplified.dart) - Field names

---

**Next Step:** Check Firebase Console function logs to verify email sending is working.

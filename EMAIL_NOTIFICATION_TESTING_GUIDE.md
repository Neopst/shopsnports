# COMPLETE EMAIL NOTIFICATION TESTING GUIDE

**Date:** March 2, 2026  
**Status:** Ready for Testing ✅

---

## QUICK STATUS CHECK ✅

All components verified:
- ✅ SMTP Configuration file (.env.onCustomerCreated) present with credentials
- ✅ Firebase configuration (firebase.json) properly set up
- ✅ All npm packages installed (firebase-functions, firebase-admin, nodemailer)
- ✅ TypeScript compiled to JavaScript (lib/ files exist)
- ✅ Email functions exported (shippingRequestCreated, shippingRequestUpdated)
- ✅ Professional HTML email template with tracking number & agent contact message
- ✅ Support contact info embedded (support@shopsnports.com, +234 803 123 4567)

**Status:** 🟢 READY FOR TESTING

---

## PHASE 1: LOCAL TESTING WITH EMULATOR (30 minutes)

### Step 1.1: Start Firebase Emulators

```bash
cd c:\projects\shopsnports
firebase emulators:start
```

**Expected Output:**
```
i  Starting emulators...
✔  Firestore Emulator started at http://localhost:8085
✔  Cloud Functions Emulator started at http://localhost:5005
✔  Authentication Emulator started at http://localhost:9095
ℹ️  Emulator UI available at http://localhost:4005
```

**Keep this terminal open** for logs.

### Step 1.2: Run Mobile App on Emulator (New Terminal)

```bash
cd c:\projects\shopsnports
flutter run
```

Select Android emulator when prompted.

### Step 1.3: Create Test Shipping Request

1. **Login to Mobile App:**
   - Use test account (or create new)
   - Email: test.customer@shopsnports.com

2. **Navigate to Shipping Request Form:**
   - Tap "Request Shipment"
   - Fill in all 21 required fields:
     - Freight Type: Door-to-Door
     - Item: Test Package
     - Origin: Lagos, Nigeria
     - Destination: Accra, Ghana
     - Weight: 50 kg
     - Dimensions: 100 x 50 x 50 cm
     - Sender: Your Name, Address, Phone, Email
     - Receiver: John Doe, Address, Phone, john@example.com

3. **Submit Request:**
   - Tap "Submit"
   - Wait for success message

### Step 1.4: Monitor Function Logs

**Terminal 1 (Emulator):** Watch for:

```
Functions Emulator
onShippingRequestCreated triggered for requestId: XXXXXX
Processing new shipping request: XXXXXX
✅ Confirmation email sent to test.customer@shopsnports.com
Successfully processed shipping request: XXXXXX
```

**What to Look For:**
- ✅ request data logged (senderEmail, destinationLocation, etc.)
- ✅ affiliate token handled (if applicable)
- ✅ admin notification created
- ✅ FCM push sent
- ✅ **Email sent confirmation message**
- ✅ Activity log entry created

### Step 1.5: Check Firestore Data (Local)

**Emulator UI: http://localhost:4005**

1. Go to "Firestore" tab
2. Navigate to collection: `shippingRequests`
3. Find your request document
4. **Verify Fields:**
   - ✅ requesterId: matches your user ID
   - ✅ senderEmail: test.customer@shopsnports.com
   - ✅ status: "pending"
   - ✅ trackingNumber: SHP-YYYYMMDD-XXXXX format
   - ✅ createdAt: current timestamp
   - ✅ All 21 form fields present

4. Check `notifications` collection:
   - ✅ Admin notification created (type: "new_shipping_request")
   - ✅ Contains tracking number and sender info

---

## PHASE 2: VERIFY EMAIL (LOCAL SMTP TESTING)

### Option A: Mailhog (Inspect Emails Locally)

Install and run Mailhog to capture all emails sent during testing:

```bash
# Download from https://github.com/mailhog/MailHog/releases
# Windows: mailhog.exe

# Run in separate terminal
mailhog.exe

# This starts:
# - SMTP server on localhost:1025
# - Web UI on http://localhost:8025
```

**Update .env.onCustomerCreated:**
```env
SMTP_HOST=localhost
SMTP_PORT=1025
SMTP_USER=test
SMTP_PASS=test
SMTP_SECURE=false
```

**Restart emulator and repeat Step 1.3-1.4**

**Check Mailhog UI:**
- Go to http://localhost:8025
- Look for email with subject: "Shipping Request Confirmed - Tracking: SHP-YYYYMMDD-XXXXX"
- **Verify Email Content:**
  - ✅ Subject includes tracking number
  - ✅ "Shipping Request Received! 📦" header
  - ✅ Tracking number prominently displayed (24pt, bold)
  - ✅ "One of our agents will contact you shortly" message
  - ✅ Contact info: support@shopsnports.com, +234 803 123 4567
  - ✅ Professional HTML formatting
  - ✅ From: noreply@shopsnports.com
  - ✅ To: test.customer@shopsnports.com

---

## PHASE 3: DEPLOY TO FIREBASE (5 minutes)

### Step 3.1: Build Functions

```bash
cd c:\projects\shopsnports\functions
npm run build
```

**Expected:** 0 fatal errors (TypeScript warnings are OK)

### Step 3.2: Deploy Functions

```bash
cd c:\projects\shopsnports
firebase deploy --only functions --debug
```

**Expected Output:**
```
✔ functions[shippingRequestCreated(us-central1)] Successful create operation.
✔ functions[shippingRequestUpdated(us-central1)] Successful create operation.
...
Deploy complete!
```

**Check Deployment Status:**
```bash
firebase functions:list
```

All functions should show status: "Active" ✅

### Step 3.3: Set SMTP Environment Variables (Critical!)

The functions need these env variables in Firebase:

**Option 1: Using Firebase CLI (Legacy - Deprecated March 2026):**
```bash
firebase functions:config:set \
  smtp.host="smtp.shopsnports.com" \
  smtp.port="587" \
  smtp.user="noreply@shopsnports.com" \
  smtp.pass="YOUR_SMTP_PASSWORD_HERE" \
  smtp.secure="false"
```

**Option 2: Firebase Console UI:**
1. Go to https://console.firebase.google.com
2. Select "shopsnports" project
3. Go to Functions → onShippingRequestCreated
4. Click "Runtime settings"
5. Add environment variables:
   - SMTP_HOST: smtp.shopsnports.com
   - SMTP_PORT: 587
   - SMTP_USER: noreply@shopsnports.com
   - SMTP_PASS: [ROTATED]
   - SMTP_SECURE: false

**Option 3: Update Functions Code (Recommended)**
See "Recommended Fix" section below.

---

## PHASE 4: PRODUCTION EMAIL TESTING (10 minutes)

### Step 4.1: Create Real Shipping Request

1. **Log into Mobile App** (production build)
2. **Submit Shipping Request** with real email address
3. **Wait 30-60 seconds** for email delivery

### Step 4.2: Check Firebase Console Logs

```bash
firebase functions:log
```

Search for: "Confirmation email sent to"

### Step 4.3: Verify Email Received

Check inbox (Gmail, Outlook, etc.) for:
- **Subject:** "Shipping Request Confirmed - Tracking: SHP-20260302-12345"
- **From:** noreply@shopsnports.com
- **Content:**
  - ✅ Tracking number prominently displayed
  - ✅ "Shipped Request Received! 📦" header
  - ✅ Professional formatting
  - ✅ Agent contact message: "One of our agents will contact you shortly"
  - ✅ Contact info: support@shopsnports.com, +234 803 123 4567
  - ✅ Next steps explanation

### Step 4.4: Test Admin Notifications

1. Go to **Admin Dashboard**
2. Navigate to **Shipping → Requests**
3. **Verify:**
   - ✅ New request appears in real-time
   - ✅ Sender name, email, destination displayed
   - ✅ Status: "Pending"
   - ✅ Tracking number visible
   - ✅ Click on request to see full details
   - ✅ All 21 fields populated correctly

---

## PHASE 5: STATUS UPDATE EMAIL (Future Phase)

When admin updates status (approve/deliver), customer should receive email:

### Current Implementation Status:
- ✅ Function `onShippingRequestUpdated` deployed
- ⏳ Status update notifications not yet implemented (Phase 5)
- 📋 Will include: status change, estimated delivery, tracking link

---

## TROUBLESHOOTING

### Issue: Function Logs Show "SMTP_PASS not configured"

**Cause:** Environment variables not deployed to Firebase

**Solution:**
1. Set variables using Firebase Console (preferred)
   - Functions → Runtime settings
   - Add SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS, SMTP_SECURE

2. Or use Firebase CLI:
   ```bash
   firebase functions:config:set smtp.pass="YOUR_PASSWORD"
   firebase deploy --only functions
   ```

### Issue: SMTP Connection Timeout

**Cause:** SMTP server unreachable

**Solution:**
1. Verify SMTP host: `ping smtp.shopsnports.com`
2. Check port: `telnet smtp.shopsnports.com 587`
3. Try different port (25, 465 instead of 587)
4. Check firewall rules

### Issue: Email Sent But Not Received

**Cause:** Email bounced or filtered as spam

**Solution:**
1. Check Firebase function logs for errors
2. Verify recipient email is correct in database
3. Check spam/junk folder
4. Verify SMTP credentials are correct

### Issue: Email Formatting Broken in Inbox

**Cause:** HTML not supported by email client

**Current:** Email sent as HTML with inline CSS ✅
- All styles inlined (no external CSS)
- Responsive design (mobile-friendly)
- Fallback text content included

**Should work in:** Gmail, Outlook, Apple Mail, Android default client

---

## MONITORING & VERIFICATION

### Daily Checks
- [ ] Monitor Firebase function logs
  ```bash
  firebase functions:log | grep -i "email"
  ```

- [ ] Check error rate
  ```bash
  firebase functions:describe shippingRequestCreated
  ```

### Weekly Checks
- [ ] Create test shipping requests
- [ ] Verify emails delivered within 1 minute
- [ ] Check email formatting on multiple clients
- [ ] Monitor SMTP server status

### Performance Metrics to Track
- Email delivery latency (target: <30 seconds)
- Delivery success rate (target: >99%)
- Bounce rate (target: <1%)
- Complaint rate (target: <0.1%)

---

## REFERENCE MATERIALS

| File | Purpose |
|------|---------|
| [onShippingRequestCreated.ts](../functions/src/onShippingRequestCreated.ts) | Email sending logic |
| [.env.onCustomerCreated](../functions/.env.onCustomerCreated) | SMTP configuration |
| [EMAIL_NOTIFICATION_AUDIT.md](./EMAIL_NOTIFICATION_AUDIT.md) | Technical audit |
| [CUSTOMER_JOURNEY_TEST_GUIDE.md](./CUSTOMER_JOURNEY_TEST_GUIDE.md) | End-to-end testing |

---

## RECOMMENDED FIX FOR PRODUCTION

Instead of manually setting environment variables, update the functions code to use a `.env.production` file or environment file:

### Option 1: Use dotenv Package
```bash
cd functions
npm install dotenv
```

Update `onShippingRequestCreated.ts`:
```typescript
import dotenv from 'dotenv';
dotenv.config();

// Then read from process.env
const smtpHost = process.env.SMTP_HOST;
```

### Option 2: Use Firebase Cloud Functions Native Environment (Recommended)

Update to use the new Firebase params API (post-March 2026).

---

## ACTION ITEMS CHECKLIST

**Before Production:**
- [ ] Phase 1: Local emulator testing (20 min)
- [ ] Phase 2: Email content verification (10 min)
- [ ] Phase 3: Deploy to Firebase (5 min)
- [ ] Phase 4: Production email test (10 min)
- [ ] Phase 5: Create comprehensive monitoring dashboard

**During Launch:**
- [ ] Monitor first 100 requests
- [ ] Check email delivery rate
- [ ] Verify no SMTP errors
- [ ] Confirm customer feedback positive

**After Launch:**
- [ ] Set up email delivery alerts
- [ ] Create runbook for troubleshooting
- [ ] Train support team
- [ ] Document SLA for email delivery

---

**Last Updated:** March 2, 2026  
**Next Review:** After Phase 4 Testing Complete

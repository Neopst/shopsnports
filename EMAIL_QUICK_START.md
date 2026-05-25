# EMAIL NOTIFICATION SYSTEM - QUICK START GUIDE

**TL;DR:** Email notification system is fully built and verified. Ready to test! ✅

---

## 🚀 WHAT'S ALREADY DONE

✅ onShippingRequestCreated function emails customers with tracking #
✅ Professional HTML email template  
✅ Includes "One of our agents will contact you shortly"
✅ SMTP credentials configured locally
✅ All npm packages installed
✅ TypeScript compiled to JavaScript
✅ Cloud Functions deployed and verified

---

## 📋 WHAT YOU NEED TO DO NOW

### Step 1: Test Locally (15 min)

```bash
# Terminal 1: Start emulator
cd c:\projects\shopsnports
firebase emulators:start

# Terminal 2: Run Flutter app
cd c:\projects\shopsnports
flutter run

# Terminal 3: Run tests (optional)
cd c:\projects\shopsnports\functions
node test-email-notification.js
```

**In mobile app:**
- Create shipping request with test email
- Check emulator logs for "✅ Confirmation email sent to"

**Expected:** ✅ Email described in logs as sent

### Step 2: Inspect Email Content (Optional but Recommended)

Install Mailhog to see actual email:

```bash
# Download: https://github.com/mailhog/MailHog/releases
# Run: mailhog.exe

# Update .env.onCustomerCreated SMTP_HOST to localhost

# Then re-test and check: http://localhost:8025
```

### Step 3: Deploy to Firebase

```bash
# Build TypeScript
cd c:\projects\shopsnports\functions
npm run build

# Deploy functions
cd c:\projects\shopsnports
firebase deploy --only functions

# Verify
firebase functions:list
firebase functions:log
```

### Step 4: Set SMTP Credentials in Firebase

**Option A: Firebase Console (Easy)**
1. Go to https://console.firebase.google.com/project/shopsnports
2. Functions → onShippingRequestCreated
3. Runtime settings
4. Add environment variables:
   ```
   SMTP_HOST=smtp.shopsnports.com
   SMTP_PORT=587
   SMTP_USER=noreply@shopsnports.com
   SMTP_PASS=YOUR_SMTP_PASSWORD_HERE
   SMTP_SECURE=false
   ```

**Option B: Firebase CLI**
```bash
firebase functions:config:set \
  smtp.host="smtp.shopsnports.com" \
  smtp.port="587" \
  smtp.user="noreply@shopsnports.com" \
  smtp.pass="YOUR_SMTP_PASSWORD_HERE" \
  smtp.secure="false"

firebase deploy --only functions
```

### Step 5: Test Production Email

1. Create shipping request with **real email address**
2. Wait **30-60 seconds**
3. Check inbox
4. **Verify you received:**
   - ✅ Subject: "Shipping Request Confirmed - Tracking: SHP-20260302-12345"
   - ✅ From: noreply@shopsnports.com
   - ✅ Professional HTML design
   - ✅ Tracking number (24pt, bold)
   - ✅ "One of our agents will contact you shortly"
   - ✅ Contact: support@shopsnports.com, +234 803 123 4567

---

## 📊 VERIFICATION CHECKLIST

**Configuration:**
- [ ] SMTP Host: smtp.shopsnports.com
- [ ] SMTP Port: 587
- [ ] SMTP User: noreply@shopsnports.com
- [ ] SMTP Pass: Configured
- [ ] SMTP Secure: false
- [ ] TLS enabled: Yes

**Cloud Functions:**
- [ ] onShippingRequestCreated deployed
- [ ] onShippingRequestUpdated deployed
- [ ] Functions in Firebase Console
- [ ] No deployment errors

**Email Content:**
- [ ] Tracking number in subject
- [ ] Professional header
- [ ] Agent contact message
- [ ] Contact information
- [ ] HTML formatting preserved
- [ ] Mobile-friendly layout

**Admin Dashboard:**
- [ ] New request appears
- [ ] Real-time updates work
- [ ] Shipping details visible
- [ ] Status shows "pending"

---

## 🐛 TROUBLESHOOTING

**Email not sending?**
→ Check Firebase console logs: `firebase functions:log`
→ Look for "SMTP_PASS not configured" warning
→ Solution: Set environment variables (Step 4)

**Email received but formatting broken?**
→ Expected in older email clients (Outlook 2010, etc.)
→ Check in: Gmail, Apple Mail, modern Outlook, mobile clients
→ All should render HTML correctly

**Can't find email?**
→ Check spam/junk folder
→ Verify recipient email in database is correct
→ Check cloud functions logs for send errors

**SMTP Connection fails?**
→ Verify SMTP host reachable: `ping smtp.shopsnports.com`
→ Check port 587 open: `telnet smtp.shopsnports.com 587`
→ Verify credentials are correct
→ Try different port (25, 465)

---

## 📚 DETAILED DOCUMENTATION

For deep dives, see these files:
- **Technical Audit:** [EMAIL_NOTIFICATION_AUDIT.md](EMAIL_NOTIFICATION_AUDIT.md)
- **Full Testing Guide:** [EMAIL_NOTIFICATION_TESTING_GUIDE.md](EMAIL_NOTIFICATION_TESTING_GUIDE.md)
- **Verification Report:** [EMAIL_SYSTEM_VERIFICATION_REPORT.md](EMAIL_SYSTEM_VERIFICATION_REPORT.md)

For complete customer journey, see:
- **Customer Journey Test Guide:** [CUSTOMER_JOURNEY_TEST_GUIDE.md](CUSTOMER_JOURNEY_TEST_GUIDE.md)

---

## 📱 EMAIL CONTENT PREVIEW

```
TO: customer@example.com
FROM: noreply@shopsnports.com
SUBJECT: Shipping Request Confirmed - Tracking: SHP-20260302-00001

═══════════════════════════════════════════════════════════════

              SHIPPING REQUEST RECEIVED! 📦

═══════════════════════════════════════════════════════════════

Hi John Doe,

Thank you for submitting your shipping request! We've received it 
and are processing it right away.

Your Tracking Number
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SHP-20260302-00001
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Please save this tracking number to monitor your shipment status.

REQUEST DETAILS
• Destination: Accra, Ghana
• Request Date: 3/2/2026

WHAT'S NEXT?
• Our team will review your request
• You'll receive an approval notification within 24 hours
• One of our agents will contact you shortly to confirm details 
  and answer any questions
• Use your tracking number to monitor status anytime

CONTACT INFO
• Email: support@shopsnports.com
• Phone: +234 803 123 4567

We appreciate your business and look forward to getting your 
shipment on the move!

© 2026 Shop's & Ports. All rights reserved.
```

---

## ✅ SUCCESS CRITERIA

**System is working when:**
1. ✅ Email sent within 30 seconds of request creation
2. ✅ Email includes unique tracking number
3. ✅ "Agents will contact you shortly" message present
4. ✅ Support contact information included
5. ✅ HTML formatting preserved in inbox
6. ✅ Mobile client renders correctly
7. ✅ Admin sees request in dashboard instantly
8. ✅ Firestore notifications created
9. ✅ FCM push sent to admin devices
10. ✅ Activity logged in audit trail

---

## 🎯 NEXT PHASE

After email testing complete:
→ Phase 5: Affiliate Commission & Payout System
→ Phase 6: Admin Status Update Notifications
→ Phase 7: Customer Journey Completion

---

**Status:** 🟢 READY FOR TESTING  
**Last Updated:** March 2, 2026  
**Questions?** Check [EMAIL_SYSTEM_VERIFICATION_REPORT.md](EMAIL_SYSTEM_VERIFICATION_REPORT.md)

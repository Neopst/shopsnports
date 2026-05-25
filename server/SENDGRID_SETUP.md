# SendGrid Email Service Setup

## ✅ Completed Implementation

The email service is now fully integrated with the following features:

### Email Templates Created:
1. **Shipper Verification** - Notifies admin when shipper requests verification
2. **Shipper Approval** - Sent to shipper when approved
3. **Shipper Rejection** - Sent to shipper when rejected
4. **Affiliate Shipping Request** - Sent to affiliate when request is created
5. **Order Confirmation** - Sent to customer after successful order

### API Endpoints Created:
- `POST /api/v1/shippers/verify` - Submit shipper verification
- `PUT /admin/api/shippers/:id/approve` - Approve shipper (admin)
- `PUT /admin/api/shippers/:id/reject` - Reject shipper (admin)
- `GET /admin/api/shippers/pending` - List pending verifications (admin)
- `POST /api/v1/shipping/affiliate-request` - Create shipping request with email

---

## 📝 Setup Instructions

### Step 1: Sign Up for SendGrid (2 minutes)

1. Go to: https://signup.sendgrid.com/
2. Create free account with your email
3. Verify your email address
4. Complete the setup wizard

### Step 2: Get Your API Key

1. Log in to SendGrid dashboard
2. Go to **Settings** → **API Keys**
3. Click **Create API Key**
4. Give it a name: "ShopsNSports Production"
5. Select **Full Access** (or at minimum: Mail Send permission)
6. Click **Create & View**
7. **COPY THE API KEY** (starts with `SG.`) - you won't see it again!

### Step 3: Update .env File

Open `server/.env` and replace the placeholder:

```env
SENDGRID_API_KEY=SG.your_actual_api_key_here
SENDGRID_FROM_EMAIL=noreply@shopsnports.com
SENDGRID_FROM_NAME=ShopsNSports
ADMIN_EMAIL=your_actual_admin_email@gmail.com
```

**Important:** 
- Replace `ADMIN_EMAIL` with your actual email to receive notifications
- For production, you'll need to verify your sender email/domain in SendGrid

### Step 4: Test Email Service

Start the server and test:

```bash
cd server
node -e "require('./src/services/email').sendShipperVerificationToAdmin({ shipperName: 'Test User', shipperEmail: 'test@test.com', shipperPhone: '123456789', vehicleDetails: 'Honda Motorcycle', verificationId: '123' })"
```

Or use the API:
```bash
curl -X POST http://localhost:3000/api/v1/shippers/verify \
  -H "Authorization: Bearer YOUR_FIREBASE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "vehicleType": "Motorcycle",
    "vehicleDetails": "Honda CB 2020, Red, ABC-123",
    "licenseNumber": "DL12345",
    "address": "123 Main St, Lagos",
    "emergencyContact": "+234-123-4567",
    "hasInsurance": true
  }'
```

---

## 🎯 What Happens When?

### Shipper Verification Flow:
1. **User submits verification** (mobile app)
   → `POST /api/v1/shippers/verify`
   → Email sent to admin

2. **Admin reviews** (admin dashboard)
   → Opens pending verifications page
   → Clicks "Approve" or "Reject"

3. **Admin approves**
   → `PUT /admin/api/shippers/:id/approve`
   → Email sent to shipper
   → User role updated to include 'shipper'

### Affiliate Shipping Request Flow:
1. **Affiliate creates request** (mobile app)
   → `POST /api/v1/shipping/affiliate-request`
   → Email sent to affiliate confirming creation
   → Email includes tracking link and estimated earnings

---

## 📧 Email Previews

### Admin Notification (New Shipper):
- **From:** ShopsNSports <noreply@shopsnports.com>
- **To:** admin@shopsnports.com
- **Subject:** New Shipper Verification: John Doe
- **Content:** Shipper details + Review button linking to admin dashboard

### Shipper Approval:
- **From:** ShopsNSports <noreply@shopsnports.com>
- **To:** shipper@email.com
- **Subject:** 🎉 Your Shipper Account is Approved!
- **Content:** Congratulations message + "Open Dashboard" button

### Affiliate Request Created:
- **From:** ShopsNSports <noreply@shopsnports.com>
- **To:** affiliate@email.com
- **Subject:** Shipping Request Created - #12345
- **Content:** Request details + estimated earnings + tracking link

---

## 🔧 Testing in Development

The email service has **dev mode** built in. If `SENDGRID_API_KEY` is not set:
- No actual emails are sent
- Email content is logged to console
- API calls still succeed (won't break app)

This lets you develop without needing SendGrid during early testing.

---

## 🚀 Production Checklist

Before going live:

- [ ] Get SendGrid API key and add to .env
- [ ] Verify your sender email in SendGrid
- [ ] Update `SENDGRID_FROM_EMAIL` to your domain
- [ ] Set `ADMIN_EMAIL` to real admin email
- [ ] Test all email flows end-to-end
- [ ] Monitor SendGrid dashboard for delivery stats
- [ ] Set up email analytics/tracking (optional)

---

## 📊 SendGrid Free Tier Limits

- **100 emails/day** = 3,000/month
- Enough for ~50 orders/day with 2 emails per order
- Can upgrade to $15/month for 40,000 emails when needed

---

## ✅ Next Steps

1. **Get your SendGrid API key** (do this now)
2. **Update server/.env** with the key
3. **Restart the server**: `cd server && npm start`
4. **Test the flow**:
   - Submit shipper verification from mobile app
   - Check your admin email
   - Approve from admin dashboard
   - Check shipper receives approval email

Once working, we'll move to **Firebase Hosting for Admin Dashboard**.

---

**Status:** 🟢 Email service code complete, waiting for API key

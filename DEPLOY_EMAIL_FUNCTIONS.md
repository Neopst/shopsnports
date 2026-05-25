# Deploy Updated Functions with Email Enabled

## What Was Fixed

✅ **onCustomerCreated** - Was missing SMTP env vars  
✅ **onShippingRequestCreated** - NOW SENDS confirmation email to customer  
✅ Removed duplicate email function for clean codebase  

## Deploy Now

Open PowerShell and run:

```powershell
cd C:\projects\shopsnports\functions
npm run build
firebase deploy --only functions `
  --set-env SMTP_HOST=smtp.shopsnports.com `
  --set-env SMTP_PORT=587 `
  --set-env SMTP_USER=noreply@shopsnports.com `
  --set-env SMTP_PASS="YOUR_SMTP_PASSWORD_HERE" `
  --set-env SMTP_SECURE=false
```

**Or use the PowerShell script:**

```powershell
PS C:\projects\shopsnports\> .\deploy-functions-with-email.ps1
```

## What Happens After Deployment

### 1. **Welcome Email** (When customer creates account)
- ✅ Sent to customer email
- From: noreply@shopsnports.com
- Subject: Welcome to Shop's & Ports, [Name]! 🎉

### 2. **Shipping Confirmation Email** (When customer submits shipping request)
- ✅ Sent to customer email  
- From: noreply@shopsnports.com
- Subject: Shipping Request Confirmed - Tracking: [TRACKING_NUMBER]
- **INCLUDES:**
  - Tracking number
  - Shipping route details
  - Next steps to approve

## Testing

1. **Test Welcome Email:**
   - Open mobile app
   - Create new account with a test email
   - Check email inbox for welcome message

2. **Test Shipping Confirmation:**
   - Login to mobile app
   - Submit a shipping request
   - Check email for confirmation with tracking number
   - Go to "Track Shipment" → Enter tracking number → Should see request

3. **Check Firebase Logs:**
   - Firebase Console → Functions → Logs
   - Look for: `✅ Confirmation email sent to...` or `✅ Welcome email sent to...`

## SMTP Configuration Already Set

All SMTP credentials are already configured in:
- File: `functions/.env.onCustomerCreated`
- Host: smtp.shopsnports.com
- Port: 587  
- User: noreply@shopsnports.com
- Password: ✅ Set (visible in .env file)

**This deployment just uploads these credentials to Firebase so the functions can use them.**

## Admin Dashboard Should Now Show Requests

After deployment + new shipping request submission:
1. Go to admin dashboard
2. Navigate to "Shipping Requests"
3. You should see the request with:
   - Customer name
   - Tracking number (auto-generated, now included in email)
   - Status: Pending
   - Real-time updates

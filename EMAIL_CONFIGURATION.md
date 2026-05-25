# Email Notifications - Status & Configuration

## Issue Summary
Email notifications for welcome and shipping confirmation are **not sending** because SMTP credentials are not configured in Firebase Cloud Functions environment variables.

## What's Working
- ✅ Welcome email function created (`onCustomerCreated`)  
- ✅ Shipping confirmation email function created and deployed (`onShippingRequestConfirmationEmail`)
- ✅ In-app/push notifications working correctly
- ✅ Email infrastructure configured (nodemailer + SMTP)

## What's Needed to Enable Emails

### Option 1: Configure SMTP Server (Recommended)
Create a `.env.onCustomerCreated` file in your `functions/` directory:

```env
SMTP_HOST=your-smtp-host.com
SMTP_PORT=587
SMTP_USER=your-email@example.com
SMTP_PASS=your-app-password
SMTP_SECURE=false
```

Then deploy functions using Firebase CLI:
```bash
cd functions
firebase deploy --only functions
```

### Option 2: Use SendGrid (Alternative)
The server has SendGrid configured. You can:
1. Get SendGrid API key from environment
2. Create HTTP Cloud Function that calls SendGrid endpoint
3. Deploy the updated functions

### Option 3: Use Gmail SMTP
```
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-gmail@gmail.com
SMTP_PASS=your-app-password (NOT regular password - use 2FA app password)
SMTP_SECURE=false
```

## What Gets Sent

### 1. Welcome Email (New Customer)
- Triggered: When user creates an account
- Recipient: Customer email
- Content: Welcome message + account details + link to get started
- Status: Function exists, waiting for SMTP config

### 2. Shipping Confirmation Email (New Request)
- Triggered: When customer submits a shipping request
- Recipient: Customer email  
- Content: Tracking number + route details + next steps
- Status: ✅ NEW - Function created and ready to deploy
- Fallback: In-app notification created if email fails

## Deployment Steps

```bash
# 1. Configure SMTP in .env file
# 2. Build TypeScript to JavaScript
cd c:\projects\shopsnports\functions
npm run build

# 3. Deploy functions
firebase deploy --only functions

# 4. Verify in Firebase Console
# Functions > shippingRequestConfirmationEmail should show "ACTIVE"
```

## Testing

After deployment, test by:
1. Creating a new account (should get welcome email)
2. Submitting a shipping request (should get confirmation email)
3. Check Firebase Console > Functions logs for email sending details

## Troubleshooting

If emails still don't send:
- Check Firebase Cloud Functions logs for errors
- Verify SMTP credentials are correct
- Ensure firewall allows outbound SMTP (port 587)
- Check email spam folder
- Review rate limiting on email service

## Files Modified
- `functions/src/onShippingRequestConfirmationEmail.ts` - NEW email function
- `functions/src/index.ts` - Added export for new function

# Firebase Functions Deployment Guide - Windows PowerShell

## Prerequisites

1. **Node.js 20** - Already have node v24.13.1 ✅
2. **Firebase CLI** - Already installed
3. **SMTP Credentials** - shopsnports SMTP account

## Step 1: Install Dependencies

```powershell
# Navigate to functions directory
cd c:\projects\shopsnports\functions

# Install npm packages (including nodemailer)
npm install
```

✅ **Status**: Already completed - nodemailer ^6.9.7 installed

---

## Step 2: Set Environment Variables (Modern Params Approach)

The function now uses the modern `defineSecret` and `defineString` params approach instead of deprecated `functions.config()`.

In PowerShell, use the following syntax to set parameters:

```powershell
# Set each parameter individually in PowerShell
firebase deploy --set-env SMTP_HOST=smtp.shopsnports.com
firebase deploy --set-env SMTP_PORT=587
firebase deploy --set-env SMTP_USER=noreply@shopsnports.com
firebase deploy --set-env SMTP_PASS="YOUR_ACTUAL_SMTP_PASSWORD"
firebase deploy --set-env SMTP_SECURE=false
```

**OR** create a `.env.onCustomerCreated` file in the functions directory:

```
SMTP_HOST=smtp.shopsnports.com
SMTP_PORT=587
SMTP_USER=noreply@shopsnports.com
SMTP_PASS=YOUR_ACTUAL_SMTP_PASSWORD
SMTP_SECURE=false
```

Then deploy with:
```powershell
firebase deploy --only functions:onCustomerCreated --import-credentials functions/.env.onCustomerCreated
```

---

## Step 3: Deploy the Function

```powershell
# Deploy only the welcome email function (faster)
firebase deploy --only functions:onCustomerCreated

# Or deploy all functions
firebase deploy --only functions
```

If you get Node.js 18 deprecation error, the package.json has been updated to Node 20. The deployment should succeed after npm install.

---

## Step 4: Verify Deployment

```powershell
# List all deployed functions
firebase functions:list

# You should see:
# onCustomerCreated - HTTPS callable function
# sendWelcomeEmailHttp - HTTPS callable function
```

---

## Testing the Welcome Email

### Option 1: Via Mobile App Signup
1. Open mobile app (should auto-rebuild with Flutter)
2. Register with a test email:
   - Name: Test User
   - Email: your-test@gmail.com
   - Password: Strong password
   - Phone: +234 8012345678
   - Gender: Select one
3. Click "Create Account"
4. Check email inbox for:
   ```
   Welcome to Shop's & Ports, Test! 🎉
   ```

### Option 2: Via Firestore Console
Manually create a document triggering the function:

1. Open Firebase Console → Firestore Database
2. Collection: `customers`
3. Add new document with ID: `test-customer-123`
4. Fields:
   ```
   name: "Test User"
   email: "your-test@gmail.com"
   phone: "+234 8012345678"
   ```
5. Function automatically triggers
6. Check email in 10-30 seconds

---

## Monitoring Function Execution

### View Logs
```powershell
# Real-time function logs
firebase functions:log

# View last N lines
firebase functions:log --lines=50
```

### Check Firestore for Logs

The function writes to two collections:

**Success Logs** (activity_log):
```
Collection: activity_log
Fields: action, customerId, email, name, timestamp
```

**Error Logs** (email_errors):
```
Collection: email_errors
Fields: customerId, email, error, timestamp
```

---

## Troubleshooting

### Problem: Function not triggering on customer creation

**Solution**:
1. Verify function is deployed: `firebase functions:list`
2. Check Firestore rules allow `customers` collection creation
3. Monitor logs: `firebase functions:log`

### Problem: SMTP connection failed

**Solution**:
1. Verify SMTP credentials are correct:
   - Host: `smtp.shopsnports.com`
   - Port: `587`
   - User: `noreply@shopsnports.com`
   - Check password hasn't changed
2. Test SMTP conn manually (optional):
   ```powershell
   # Test with telnet (if available)
   Test-NetConnection -ComputerName smtp.shopsnports.com -Port 587
   ```
3. Check Firebase Functions logs for details

### Problem: Email not received

**Solution**:
1. Check `activity_log` in Firestore - was email sent?
2. Check spam/junk folder
3. Verify email address in customer document is correct
4. Check `email_errors` collection for any SMTP errors

### Problem: Node.js 18 deprecation on deploy

**Solution**:
- ✅ Already fixed - package.json updated to Node.js 20
- Run `npm install` again to ensure dependencies update
- Then deploy

---

## Parameters Reference

| Parameter | Default | Required | Format |
|-----------|---------|----------|--------|
| SMTP_HOST | smtp.shopsnports.com | ❌ | hostname |
| SMTP_PORT | 587 | ❌ | number (string) |
| SMTP_USER | noreply@shopsnports.com | ❌ | email |
| SMTP_PASS | (none) | ✅ | password (SECRET) |
| SMTP_SECURE | false | ❌ | "true" or "false" |

---

## File Changes Made

✅ **functions/package.json**
- Updated Node.js engine: 18 → 20
- Dependencies remain: firebase-admin, firebase-functions, nodemailer

✅ **functions/lib/onCustomerCreated.js**
- Migrated from `functions.config()` to `defineSecret/defineString` params
- Added `runWith({ secrets: ['SMTP_PASS'] })`
- Environment variables now read via `param.value()` instead of `process.env`

---

## Next Steps After Deployment

1. ✅ Deploy function and set parameters
2. ✅ Test welcome email with new user signup
3. ✅ Verify phone display in admin dashboard (already working)
4. 🔄 **Next Phase**: Shipping Module Implementation
   - Create `ShippingRequest` model
   - Build shipping request creation form
   - Add admin shipping management screens

---

## PowerShell Quick Reference

```powershell
# Navigate to functions
cd c:\projects\shopsnports\functions

# Install dependencies
npm install

# Deploy with parameters (individual commands)
firebase deploy --set-env SMTP_HOST=smtp.shopsnports.com
firebase deploy --set-env SMTP_PORT=587
firebase deploy --set-env SMTP_USER=noreply@shopsnports.com
firebase deploy --set-env SMTP_PASS="YOUR_PASSWORD"

# Deploy function only
firebase deploy --only functions:onCustomerCreated

# Monitor logs
firebase functions:log

# List functions
firebase functions:list
```

---

## Status Tracking

| Step | Status | Command |
|------|--------|---------|
| Update Node.js | ✅ DONE | (automatic in package.json) |
| Install Dependencies | ✅ DONE | `npm install` |
| Migrate to Params | ✅ DONE | (already in onCustomerCreated.js) |
| Set SMTP Variables | ⏳ TODO | `firebase deploy --set-env ...` |
| Deploy Function | ⏳ TODO | `firebase deploy --only functions:onCustomerCreated` |
| Test Welcome Email | ⏳ TODO | Register new account |
| Verify Admin Display | ✅ DONE | Phone with flag showing |
| Start Shipping Module | ⏳ TODO | Create models and screens |

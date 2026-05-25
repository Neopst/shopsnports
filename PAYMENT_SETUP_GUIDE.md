# 🎯 PAYMENT SETUP CHECKLIST

**Date:** December 31, 2025  
**Status:** Ready to Configure

---

## ✅ **STRIPE SETUP**

### Registration
- [ ] Go to https://dashboard.stripe.com/register
- [ ] Create account with your email
- [ ] Verify email address
- [ ] Switch to **TEST MODE** (toggle at top)

### Get API Keys
- [ ] Visit https://dashboard.stripe.com/test/apikeys
- [ ] Copy **Publishable key** (starts with `pk_test_`)
- [ ] Copy **Secret key** (starts with `sk_test_`)

### Setup Webhook
- [ ] Visit https://dashboard.stripe.com/test/webhooks
- [ ] Click "Add endpoint"
- [ ] Enter URL: `https://your-domain.com/webhooks/stripe`
- [ ] Select events:
  - [ ] `payment_intent.succeeded`
  - [ ] `payment_intent.payment_failed`
  - [ ] `charge.refunded`
- [ ] Save and copy **Signing secret** (starts with `whsec_`)

### Update Configuration
- [ ] Add to `server/.env`:
  ```
  STRIPE_SECRET_KEY=sk_test_xxxxx
  STRIPE_PUBLISHABLE_KEY=pk_test_xxxxx
  STRIPE_WEBHOOK_SECRET=whsec_xxxxx
  ```
- [ ] Note `pk_test_xxxxx` for mobile app

---

## ✅ **PAYSTACK SETUP**

### Registration
- [ ] Go to https://dashboard.paystack.com/#/signup
- [ ] Create account
- [ ] Verify email and phone
- [ ] Complete business profile (optional for testing)

### Get API Keys
- [ ] Visit https://dashboard.paystack.com/#/settings/developers
- [ ] Copy **Test Public Key** (starts with `pk_test_`)
- [ ] Copy **Test Secret Key** (starts with `sk_test_`)

### Setup Webhook
- [ ] Same page (Settings → API Keys & Webhooks)
- [ ] Scroll to "Webhook URL"
- [ ] Enter: `https://your-domain.com/webhooks/paystack`
- [ ] Click "Save Changes"

### Update Configuration
- [ ] Add to `server/.env`:
  ```
  PAYSTACK_SECRET_KEY=sk_test_xxxxx
  PAYSTACK_PUBLIC_KEY=pk_test_xxxxx
  ```
- [ ] Note `pk_test_xxxxx` for mobile app

---

## ✅ **FLUTTERWAVE SETUP**

### Registration
- [ ] Go to https://dashboard.flutterwave.com/signup
- [ ] Create account
- [ ] Verify email and phone
- [ ] Complete KYC (optional for testing)

### Get API Keys
- [ ] Visit https://dashboard.flutterwave.com/settings/apis
- [ ] Switch to **TEST MODE** (toggle at top)
- [ ] Copy **Public Key** (starts with `FLWPUBK_TEST-`)
- [ ] Copy **Secret Key** (starts with `FLWSECK_TEST-`)
- [ ] Copy **Encryption Key** (starts with `FLWSECK-`)

### Setup Webhook
- [ ] Same page (Settings → API Keys)
- [ ] Scroll to "Webhooks"
- [ ] Enter URL: `https://your-domain.com/webhooks/flutterwave`
- [ ] Copy the **Secret Hash**
- [ ] Click "Save"

### Update Configuration
- [ ] Add to `server/.env`:
  ```
  FLUTTERWAVE_SECRET_KEY=FLWSECK_TEST-xxxxx
  FLUTTERWAVE_PUBLIC_KEY=FLWPUBK_TEST-xxxxx
  FLUTTERWAVE_ENCRYPTION_KEY=FLWSECK-xxxxx
  ```
- [ ] Note `FLWPUBK_TEST-xxxxx` for mobile app

---

## ✅ **CONFIGURATION FILES**

### Server Configuration (`server/.env`)
- [ ] Copy `server/.env.TEMPLATE` to `server/.env`
- [ ] Fill in all Stripe keys
- [ ] Fill in all Paystack keys
- [ ] Fill in all Flutterwave keys
- [ ] Verify PORT is set to 3000

### Mobile App Configuration
- [ ] Note all PUBLIC keys (pk_test_, FLWPUBK_TEST-)
- [ ] Test with command:
  ```bash
  flutter run --dart-define=STRIPE_KEY=pk_test_xxx --dart-define=PAYSTACK_KEY=pk_test_xxx --dart-define=FLUTTERWAVE_KEY=FLWPUBK_TEST-xxx
  ```

---

## ✅ **TESTING**

### Test Cards (Stripe)
- [ ] Success: `4242 4242 4242 4242` (any CVV, any future date)
- [ ] Decline: `4000 0000 0000 0002`

### Test Cards (Paystack)
- [ ] Card: `4084 0840 8408 4081`
- [ ] CVV: `408`
- [ ] PIN: `0000`

### Test Cards (Flutterwave)
- [ ] Card: `5531 8866 5214 2950`
- [ ] CVV: `564`
- [ ] PIN: `3310`
- [ ] OTP: `12345`

### Verification
- [ ] Start server: `cd server && npm start`
- [ ] Test payment flow in mobile app
- [ ] Check webhooks received in provider dashboards
- [ ] Verify transactions appear in admin dashboard

---

## 📋 **QUICK REFERENCE**

### Server Files
```
c:\projects\shopsnports\server\.env          ← Your actual keys (SECRET)
c:\projects\shopsnports\server\.env.TEMPLATE ← Template with instructions
```

### Mobile App Files
```
c:\projects\shopsnports\lib\core\config\app_config.dart ← Reads PUBLIC keys
c:\projects\shopsnports\.env.mobile.TEMPLATE             ← Template for flutter run
```

### Official Documentation
- Stripe: https://stripe.com/docs
- Paystack: https://paystack.com/docs
- Flutterwave: https://developer.flutterwave.com/docs

---

## 🚀 **NEXT STEPS AFTER SETUP**

1. [ ] Update TODO list with testing tasks
2. [ ] Test complete checkout flow
3. [ ] Verify webhook events
4. [ ] Configure production keys (when ready)
5. [ ] Update deployment configs

---

**Need Help?**
- Stripe Support: https://support.stripe.com
- Paystack Support: https://paystack.com/help
- Flutterwave Support: https://support.flutterwave.com

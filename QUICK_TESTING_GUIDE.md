# Quick Testing Guide - Core Systems

## 🏃‍♂️ Quick Start Testing

### 1. Cart System (15 minutes)

```bash
# Launch app
flutter run
```

**Test Steps:**
1. ✓ Navigate to Products screen
2. ✓ Tap "Add to Cart" on 3 different products
3. ✓ Check cart badge shows "3"
4. ✓ Open cart from top-right icon
5. ✓ Increase quantity of first item
6. ✓ Decrease quantity of second item
7. ✓ Remove third item entirely
8. ✓ Verify subtotal updates correctly
9. ✓ Close app completely
10. ✓ Reopen app
11. ✓ Open cart - verify items still there

**Expected Results:**
- Cart operations instant (< 500ms)
- Badge updates immediately
- Cart persists after app restart
- No errors in console

**If Issues:**
- Check `lib/providers/cart_provider.dart`
- Check console for errors
- Verify SharedPreferences working

---

### 2. Affiliate System (20 minutes)

**Part A: Registration (10 min)**
1. ✓ Navigate: Drawer → Affiliate Program
2. ✓ Tap "Join Now" or "Register"
3. ✓ Fill form:
   - Name: Test Affiliate
   - Email: test.affiliate@example.com
   - Phone: +2348012345678
   - Bank: GTBank
   - Account: 0123456789
4. ✓ Submit
5. ✓ Check Firestore: `affiliates` collection has new record
6. ✓ Verify status = 'pending'

**Part B: Admin Approval (10 min)**
1. ✓ Navigate: Drawer → Admin Dashboard (if admin)
2. ✓ Go to Affiliates Admin
3. ✓ Find pending affiliate
4. ✓ Tap menu → Approve
5. ✓ Confirm approval
6. ✓ Check status changed to 'approved'
7. ✓ Verify notification sent (check Firestore notifications)

**Expected Results:**
- Form submits successfully
- Record created in Firestore
- Admin can see and approve
- Status updates correctly

---

### 3. Vendor Dashboard (15 minutes)

**Part A: Registration**
1. ✓ Navigate to Vendor Registration
2. ✓ Fill all fields
3. ✓ Submit
4. ✓ Verify record created

**Part B: Dashboard Access**
1. ✓ Login as approved vendor
2. ✓ Navigate to Vendor Dashboard
3. ✓ Verify chart displays
4. ✓ Check KPIs show numbers
5. ✓ Navigate to Products screen
6. ✓ Add a test product

**Expected Results:**
- Dashboard loads < 2 seconds
- Charts render correctly
- Product management works

---

### 4. Admin Dashboard (15 minutes)

1. ✓ Login as admin user
2. ✓ Navigate: Drawer → Admin Dashboard
3. ✓ Verify notifications load
4. ✓ Check recent orders display
5. ✓ Test filter chips (Pending/Flagged/Recent)
6. ✓ Navigate to Pending Approvals
7. ✓ Approve/reject a request
8. ✓ Check audit log created

**Expected Results:**
- Real-time updates working
- All sections load
- Actions complete successfully

---

### 5. Payment System (20 minutes)

**Setup:**
1. Set environment variables OR configure backend

**Test:**
1. ✓ Add items to cart
2. ✓ Navigate to checkout
3. ✓ Select payment method
4. ✓ Verify logos display
5. ✓ Test Stripe flow (if configured)
6. ✓ Test Paystack flow (if configured)
7. ✓ Verify payment success handling

**Expected Results:**
- Payment logos visible
- Payment screens load
- Transactions process (if keys configured)

---

## 🐛 Common Issues & Fixes

### Cart Not Persisting
**Check:**
- `SharedPreferences` package installed
- `cart_provider.dart` persistence methods
- Console for errors

**Fix:**
```dart
// Ensure _persistCart() is being called
await _persistCart();
```

### Affiliate Registration Fails
**Check:**
- Firestore rules allow writes
- Form validation passing
- Network connectivity

**Fix:**
```
// Check Firestore rules
match /affiliates/{document} {
  allow create: if request.auth != null;
}
```

### Payment Logos Not Showing
**Check:**
- Assets folder has images
- `pubspec.yaml` includes assets
- `flutter_svg` package installed

**Fix:**
```bash
flutter pub get
flutter clean
flutter run
```

### Admin Dashboard Empty
**Check:**
- User has admin role
- Firestore collections exist
- Route guard passing

**Fix:**
```dart
// Verify user.isAdmin = true
// Check admin_notifications provider
```

---

## 📊 Testing Metrics

Track these for each system:

| System | Response Time | Success Rate | Issues Found |
|--------|--------------|--------------|--------------|
| Cart | < 500ms | 100% | 0 |
| Affiliate | < 2s | 100% | 0 |
| Vendor | < 2s | 100% | 0 |
| Admin | < 3s | 100% | 0 |
| Payment | < 5s | 100% | 0 |

**Goal:** All systems green before deployment

---

## ✅ Daily Testing Checklist

**Morning:**
- [ ] Launch app successfully
- [ ] Test 1 core system thoroughly
- [ ] Document issues
- [ ] Fix critical bugs

**Afternoon:**
- [ ] Test 1-2 more systems
- [ ] Verify integrations
- [ ] Update checklist
- [ ] Report progress

**End of Day:**
- [ ] Review all tests
- [ ] Update todo list
- [ ] Plan next day
- [ ] Commit fixes

---

## 🎯 Week Timeline

**Day 1:** Cart + Payment Logos ✅  
**Day 2:** Affiliate + Vendor  
**Day 3:** Admin + Integration  
**Day 4:** Payment Integration  
**Day 5-6:** Model Enhancements  
**Day 7:** Final Testing + Deploy  

---

**Quick Reference Version:** 1.0  
**Last Updated:** December 23, 2025

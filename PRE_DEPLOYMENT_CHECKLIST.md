# Pre-Deployment Testing & Feature Audit Checklist

## Overview
This checklist ensures all core functionalities are thoroughly tested and working before production deployment. We will test each system methodically, one at a time.

---

## 📦 1. CART SYSTEM TESTING

### Cart Operations
- [ ] **Add to Cart**
  - [ ] Add product from product list
  - [ ] Add product from product details screen
  - [ ] Verify cart count badge updates
  - [ ] Verify success message displays
  - [ ] Check persistence after adding

- [ ] **Update Cart**
  - [ ] Increase quantity in cart
  - [ ] Decrease quantity in cart
  - [ ] Verify subtotal updates correctly
  - [ ] Check minimum quantity (1)
  - [ ] Test maximum quantity limits

- [ ] **Remove from Cart**
  - [ ] Remove single item
  - [ ] Clear entire cart
  - [ ] Verify cart badge updates
  - [ ] Check empty cart state

- [ ] **Cart Persistence**
  - [ ] Add items and close app
  - [ ] Reopen app - verify cart restored
  - [ ] Test guest cart (local storage)
  - [ ] Test logged-in cart (Firestore)
  - [ ] Test cart migration after login

- [ ] **Cart Integration**
  - [ ] Navigate from cart to checkout
  - [ ] Apply promo code (if implemented)
  - [ ] Verify delivery fee calculation
  - [ ] Verify tax calculation
  - [ ] Check total calculation accuracy

**Status:** ⏳ Not Started  
**Blockers:** None  
**Notes:** Cart uses Riverpod state management with dual persistence (guest=SharedPreferences, logged-in=Firestore)

---

## 🤝 2. AFFILIATE SYSTEM TESTING

### Registration & Approval Flow
- [ ] **Affiliate Registration**
  - [ ] Open affiliate intro screen
  - [ ] Navigate to registration form
  - [ ] Fill all required fields:
    - [ ] Name
    - [ ] Email
    - [ ] Phone
    - [ ] Company (optional)
    - [ ] Website (optional)
    - [ ] Tax ID
    - [ ] Bank account details
  - [ ] Submit registration
  - [ ] Verify success message
  - [ ] Check Firebase/Firestore record created
  - [ ] Verify status set to 'pending'

- [ ] **Admin Approval Process**
  - [ ] Login as admin
  - [ ] Navigate to Affiliates Admin screen
  - [ ] View pending affiliate registrations
  - [ ] Approve an affiliate
  - [ ] Verify status updated to 'approved'
  - [ ] Check audit log created
  - [ ] Verify notification sent to affiliate

- [ ] **Affiliate Dashboard**
  - [ ] Login as approved affiliate
  - [ ] Access affiliate dashboard
  - [ ] View KPIs (earnings, requests, etc.)
  - [ ] Create shipment request
  - [ ] Share request link
  - [ ] View request status

- [ ] **Affiliate Payouts**
  - [ ] Mark shipment request as completed (admin)
  - [ ] Verify payout record created
  - [ ] Check commission calculation
  - [ ] View payout in affiliate payouts screen
  - [ ] Test payout request submission

**Status:** ⏳ Not Started  
**Blockers:** None  
**Notes:** Affiliate system uses Firestore functions for payout automation on shipment completion

---

## 🏪 3. VENDOR DASHBOARD TESTING

### Vendor Registration & Access
- [ ] **Vendor Registration**
  - [ ] Navigate to vendor registration
  - [ ] Fill all required fields:
    - [ ] Business name
    - [ ] Owner name
    - [ ] Email
    - [ ] Password
    - [ ] Phone
    - [ ] Mobile phone
    - [ ] Address
    - [ ] Tax ID
    - [ ] Bank account details
  - [ ] Submit registration
  - [ ] Verify record created
  - [ ] Check status set to 'pending'

- [ ] **Admin Approval**
  - [ ] Login as admin
  - [ ] Navigate to Vendors Admin screen
  - [ ] Approve vendor registration
  - [ ] Verify status updated
  - [ ] Check audit log

- [ ] **Vendor Dashboard Access**
  - [ ] Login as approved vendor
  - [ ] Access vendor dashboard
  - [ ] View monthly earnings chart
  - [ ] View KPIs:
    - [ ] Total orders
    - [ ] Total earnings
    - [ ] Product count

- [ ] **Product Management**
  - [ ] Navigate to vendor products screen
  - [ ] Add new product
  - [ ] Edit existing product
  - [ ] Delete product
  - [ ] View product list

- [ ] **Order Management**
  - [ ] View vendor orders
  - [ ] Update order status
  - [ ] View order details

**Status:** ⏳ Not Started  
**Blockers:** None  
**Notes:** Vendor dashboard uses route guards to check vendor role and approval status

---

## 👨‍💼 4. IN-APP ADMIN DASHBOARD TESTING

### Mini Admin Dashboard
- [ ] **Access Control**
  - [ ] Login as admin
  - [ ] Access mini admin dashboard
  - [ ] Verify non-admin cannot access
  - [ ] Test admin route guard

- [ ] **Dashboard Features**
  - [ ] View real-time notifications
  - [ ] View recent orders
  - [ ] Filter orders (Pending/Flagged/Recent)
  - [ ] Export orders to CSV
  - [ ] Update order status with optimistic UI

- [ ] **Pending Approvals**
  - [ ] View pending shipment requests
  - [ ] Approve/reject requests
  - [ ] Verify status updates
  - [ ] Check notification sent

- [ ] **Affiliate Management**
  - [ ] View affiliate list
  - [ ] Approve/reject affiliates
  - [ ] Verify audit logging
  - [ ] Test undo functionality

- [ ] **Vendor Management**
  - [ ] View vendor list
  - [ ] Approve/reject vendors
  - [ ] Update vendor status

- [ ] **User Management**
  - [ ] View users list
  - [ ] Update user roles
  - [ ] View user details

**Status:** ⏳ Not Started  
**Blockers:** None  
**Notes:** In-app admin uses Firebase Auth custom claims for role verification

---

## 💳 5. PAYMENT SYSTEM ENHANCEMENTS

### Payment Logos Integration
- [ ] **Add Payment Provider Logos**
  - [ ] Add Stripe logo to payment_methods_screen.dart
  - [ ] Add Paystack logo
  - [ ] Add Flutterwave logo
  - [ ] Ensure SVG/PNG assets exist in assets/images/payments/
  - [ ] Update pubspec.yaml if needed

- [ ] **Add Screen Title**
  - [ ] Add AppBar title to PaymentMethodsScreen
  - [ ] Ensure consistent styling with app theme

**Files to Update:**
- `lib/screens/cart/payment_methods_screen.dart`

---

## 🔐 6. PAYMENT SYSTEM TESTING

### Payment Configuration
- [ ] **Environment Variables Setup**
  - [ ] Verify STRIPE_KEY configured
  - [ ] Verify PAYSTACK_KEY configured
  - [ ] Verify FLUTTERWAVE_KEY configured
  - [ ] Test fallback to backend-fetched keys

- [ ] **Stripe Integration**
  - [ ] Test Stripe initialization
  - [ ] Create payment intent
  - [ ] Test PaymentSheet flow
  - [ ] Verify payment success
  - [ ] Test payment failure handling
  - [ ] Check webhook integration

- [ ] **Paystack Integration**
  - [ ] Initialize Paystack
  - [ ] Test payment flow
  - [ ] Verify transaction
  - [ ] Test vault (save card)
  - [ ] Check webhook integration

- [ ] **Flutterwave Integration**
  - [ ] Initialize Flutterwave
  - [ ] Test payment flow
  - [ ] Verify transaction
  - [ ] Test redirect handling
  - [ ] Check webhook integration

- [ ] **Payment Methods Screen**
  - [ ] Select payment method
  - [ ] View saved cards
  - [ ] Add new card
  - [ ] Remove saved card

**Status:** ⏳ Not Started  
**Blockers:** Need API keys configured  
**Notes:** Payment system uses backend to fetch publishable keys; webhooks log to database

---

## 📊 7. DATA MODEL IMPROVEMENTS

### Current Models Review

#### **AppUser Model** ✅
**Current Fields:**
- id, name, email, phone, address, gender, avatarUrl
- roles, roleStatus, activeRole
- businessName, bankName, accountName, accountNumber, taxId
- affiliateApproved, isAdmin, affiliateId

**Suggested Enhancements:**
- [ ] Add `createdAt` timestamp
- [ ] Add `updatedAt` timestamp
- [ ] Add `lastLoginAt` timestamp
- [ ] Add `emailVerified` boolean
- [ ] Add `phoneVerified` boolean
- [ ] Add `profileCompleteness` percentage
- [ ] Add `preferredLanguage` (for i18n)
- [ ] Add `notificationPreferences` map
- [ ] Add `shippingAddresses` list (multiple addresses)
- [ ] Add `defaultShippingAddress` reference
- [ ] Add `loyaltyPoints` integer
- [ ] Add `referralCode` string (for customer referrals)

#### **Product Model** ✅
**Current Fields:**
- id, name, price, imageUrl, category, vendor, description, createdAt

**Suggested Enhancements:**
- [ ] Add `sku` string (Stock Keeping Unit)
- [ ] Add `stockQuantity` integer
- [ ] Add `lowStockThreshold` integer
- [ ] Add `isInStock` computed property
- [ ] Add `images` list (multiple product images)
- [ ] Add `compareAtPrice` (original price for discounts)
- [ ] Add `discountPercentage` computed property
- [ ] Add `tags` list (for search/filtering)
- [ ] Add `weight` double (for shipping calculations)
- [ ] Add `dimensions` map {length, width, height}
- [ ] Add `status` enum (active, draft, archived)
- [ ] Add `rating` double (average rating)
- [ ] Add `reviewCount` integer
- [ ] Add `featured` boolean
- [ ] Add `variants` list (size, color options)
- [ ] Add `metaData` map (SEO: title, description, keywords)

#### **Order Model** ⚠️
**Current Fields:**
- id, userId, status, total, items, eta, createdAt

**Suggested Enhancements:**
- [ ] Add `orderNumber` string (user-friendly order ID)
- [ ] Add `shippingAddress` Address object
- [ ] Add `billingAddress` Address object
- [ ] Add `shippingMethod` string
- [ ] Add `shippingCost` double
- [ ] Add `tax` double
- [ ] Add `discount` double
- [ ] Add `subtotal` double
- [ ] Add `paymentMethod` string
- [ ] Add `paymentStatus` enum (pending, paid, failed, refunded)
- [ ] Add `paymentId` string (transaction reference)
- [ ] Add `fulfillmentStatus` enum (unfulfilled, partial, fulfilled)
- [ ] Add `trackingNumber` string
- [ ] Add `trackingUrl` string
- [ ] Add `notes` string (customer notes)
- [ ] Add `adminNotes` string (internal notes)
- [ ] Add `cancelledAt` timestamp
- [ ] Add `cancelReason` string
- [ ] Add `refundedAmount` double
- [ ] Add `vendorId` string (for multi-vendor)
- [ ] Add `estimatedDeliveryDate` timestamp
- [ ] Add `actualDeliveryDate` timestamp
- [ ] Add `statusHistory` list (track status changes)

#### **CartItem Model** ⚠️
**Current Fields:**
- productId, qty

**Suggested Enhancements:**
- [ ] Add `variantId` string (for product variants)
- [ ] Add `price` double (snapshot price at add-to-cart)
- [ ] Add `name` string (snapshot product name)
- [ ] Add `imageUrl` string (snapshot product image)
- [ ] Add `addedAt` timestamp
- [ ] Add `notes` string (special instructions)

#### **ShippingRequest Model** ✅
**Current Fields:**
- freightType, airService, seaContainerType, seaLoadType, incoterm
- purpose, hsCode, countryOfOrigin, certificateOfOrigin
- products, containsDangerousGoods, unNumber, etc.
- insuranceRequired, insuranceValue, insuranceType
- requiredDocs, attachments, extraFields

**Suggested Enhancements:**
- [ ] Add `requestNumber` string (user-friendly ID)
- [ ] Add `status` enum (draft, submitted, approved, rejected, completed)
- [ ] Add `submittedAt` timestamp
- [ ] Add `approvedAt` timestamp
- [ ] Add `completedAt` timestamp
- [ ] Add `affiliateId` reference
- [ ] Add `commission` double
- [ ] Add `estimatedCost` double
- [ ] Add `actualCost` double
- [ ] Add `customerInfo` map (name, email, phone)
- [ ] Add `pickupAddress` Address object
- [ ] Add `deliveryAddress` Address object
- [ ] Add `rejectionReason` string

### New Model Suggestions

#### **Address Model** (NEW)
```dart
class Address {
  final String id;
  final String label; // "Home", "Office", etc.
  final String fullName;
  final String phone;
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final bool isDefault;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;
}
```

#### **Review Model** (NEW)
```dart
class Review {
  final String id;
  final String productId;
  final String userId;
  final String userName;
  final double rating; // 1-5
  final String title;
  final String comment;
  final List<String> images; // review photos
  final bool verified; // verified purchase
  final int helpfulCount;
  final String status; // pending, approved, rejected
  final DateTime createdAt;
}
```

#### **Notification Model** (NEW)
```dart
class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type; // order, payment, affiliate, admin
  final Map<String, dynamic> data;
  final bool read;
  final DateTime createdAt;
  final DateTime? readAt;
}
```

#### **Payout Model** (NEW)
```dart
class Payout {
  final String id;
  final String recipientId; // affiliateId or vendorId
  final String recipientType; // affiliate, vendor
  final double amount;
  final String currency;
  final String status; // pending, processing, paid, failed
  final String? requestId; // shipment request ID
  final String? orderId; // for vendor payouts
  final String paymentMethod; // bank_transfer, etc.
  final String? transactionId;
  final DateTime requestedAt;
  final DateTime? processedAt;
  final DateTime? paidAt;
  final String? failureReason;
}
```

#### **Category Model** (NEW)
```dart
class Category {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? imageUrl;
  final String? parentId; // for subcategories
  final int sortOrder;
  final bool active;
  final DateTime createdAt;
}
```

#### **Wishlist Model** (ENHANCE EXISTING)
```dart
class WishlistItem {
  final String productId;
  final DateTime addedAt;
  final double? priceWhenAdded; // track price changes
  final bool notifyOnDiscount;
}
```

**Status:** ⏳ Not Started  
**Blockers:** None  
**Notes:** Model improvements will enhance features and enable better analytics

---

## 🧪 8. COMPREHENSIVE INTEGRATION TESTING

### End-to-End Flows
- [ ] **Customer Journey**
  - [ ] Sign up → Browse → Add to cart → Checkout → Payment → Track order
  - [ ] Search products
  - [ ] Filter by category
  - [ ] Add to wishlist
  - [ ] Leave review

- [ ] **Vendor Journey**
  - [ ] Register → Approval → Login → Add products → Manage orders
  - [ ] View analytics
  - [ ] Request payout

- [ ] **Affiliate Journey**
  - [ ] Register → Approval → Login → Create request → Get paid
  - [ ] Share links
  - [ ] Track commissions

- [ ] **Admin Journey**
  - [ ] Login → Approve vendors → Approve affiliates → Manage orders
  - [ ] View analytics
  - [ ] Process payouts

### Performance Testing
- [ ] App startup time < 3 seconds
- [ ] Dashboard load time < 3 seconds
- [ ] Cart operations < 500ms
- [ ] Image loading optimized
- [ ] Memory leaks checked
- [ ] Network request optimization

### Error Handling
- [ ] Offline mode handling
- [ ] Network timeout handling
- [ ] Payment failure recovery
- [ ] Form validation errors
- [ ] Empty state handling

**Status:** ⏳ Not Started  
**Blockers:** All previous tests must pass  
**Notes:** Use integration_test folder for automated E2E tests

---

## 🚀 9. PRODUCTION DEPLOYMENT PREPARATION

### Pre-Deployment Checks
- [ ] **Security**
  - [ ] All API keys in environment variables
  - [ ] No hardcoded secrets
  - [ ] Firebase security rules reviewed
  - [ ] API endpoints secured
  - [ ] CORS configured properly

- [ ] **Build Configuration**
  - [ ] Release build tested on Android
  - [ ] Release build tested on iOS
  - [ ] ProGuard rules configured
  - [ ] App signing configured
  - [ ] Version numbers updated

- [ ] **Backend Readiness**
  - [ ] Production database configured
  - [ ] Webhook endpoints live
  - [ ] Payment providers configured
  - [ ] Email notifications setup
  - [ ] SMS notifications setup (optional)

- [ ] **Monitoring & Analytics**
  - [ ] Crashlytics configured
  - [ ] Analytics tracking setup
  - [ ] Error logging configured
  - [ ] Performance monitoring enabled

- [ ] **Documentation**
  - [ ] API documentation complete
  - [ ] Deployment runbook created
  - [ ] Admin user guide created
  - [ ] Support documentation prepared

**Status:** ⏳ Not Started  
**Blockers:** All testing must be complete  
**Notes:** Follow PRODUCTION_ROADMAP.md for detailed deployment steps

---

## 📋 TESTING PRIORITY ORDER

### Phase 1: Core Functions (Days 1-2)
1. Cart System Testing
2. Payment System Configuration & Logos
3. Cart-to-Checkout Integration

### Phase 2: User Flows (Days 3-4)
4. Affiliate Registration & Approval Flow
5. Vendor Registration & Dashboard
6. In-App Admin Dashboard

### Phase 3: Integration (Days 5-6)
7. Payment System Testing (All Providers)
8. Data Model Enhancements
9. End-to-End Integration Testing

### Phase 4: Deployment (Day 7)
10. Production Preparation
11. Final Testing
12. Deployment

---

## 🔧 IMMEDIATE ACTION ITEMS

### Today
1. ✅ Create comprehensive testing checklist
2. ⏳ Add payment logos to payment methods screen
3. ⏳ Add title to payment methods screen
4. ⏳ Test cart system thoroughly

### Tomorrow
1. Test affiliate registration flow
2. Test vendor dashboard
3. Test admin dashboard features
4. Configure payment API keys

---

## 📊 SUCCESS CRITERIA

Each system must meet these criteria before deployment:

✅ **Cart System**
- Zero errors in add/update/remove operations
- Cart persists correctly for guests and logged-in users
- Cart count badge accurate
- Subtotal/total calculations correct

✅ **Affiliate System**
- Registration form submits successfully
- Admin can approve/reject
- Dashboard displays correct data
- Payouts calculate correctly

✅ **Vendor Dashboard**
- Vendors can manage products
- Dashboard shows accurate analytics
- Order management works

✅ **Admin Dashboard**
- All approval workflows functional
- Real-time updates working
- Audit logging captures actions
- Notifications sent correctly

✅ **Payment System**
- All 3 providers (Stripe, Paystack, Flutterwave) working
- Payment logos visible
- Success/failure handling correct
- Webhooks processing

✅ **Data Models**
- Critical enhancements implemented
- Models support all features
- No data loss scenarios

---

## 📞 SUPPORT & ESCALATION

**If Blockers Arise:**
1. Document the blocker clearly
2. Check existing documentation
3. Review error logs
4. Test in isolation
5. Report with reproduction steps

**Deployment Approval Required From:**
- All cart tests passing
- At least 2 payment providers working
- Admin dashboard functional
- No critical bugs

---

**Document Version:** 1.0  
**Last Updated:** December 23, 2025  
**Next Review:** After Phase 1 completion

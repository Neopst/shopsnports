# 🚀 ShopsNSports - Production TODO List
**Created:** January 5, 2026  
**Status:** 50% Complete  
**Target:** Production Deployment

---

## 📊 Overall System Completion

### **Progress Breakdown:**
- **Mobile App:** 70% × 50% weight = **35%**
- **Backend:** 40% × 35% weight = **14%**
- **Admin:** 30% × 15% weight = **4.5%**
- **TOTAL:** **~53%** 🟡

---

## 🔴 PHASE 1: Infrastructure & Communication Setup (Week 1)

### 1.1 Email Service Integration ⏳
**Priority:** CRITICAL  
**Time:** 1 day

- [ ] **Sign up for SendGrid/Mailgun**
  - [ ] Create account (SendGrid Free: 100 emails/day or Mailgun Free: 5,000/month)
  - [ ] Verify domain or use sandbox
  - [ ] Get API key
  - [ ] Test email sending

- [ ] **Install email package in server**
  ```bash
  cd server
  npm install nodemailer @sendgrid/mail
  ```

- [ ] **Create email service (`server/src/services/email.js`)**
  - [ ] Configure SendGrid/Mailgun client
  - [ ] Create email templates
  - [ ] Add error handling & retry logic

- [ ] **Implement email notifications**
  - [ ] Shipper verification request → Admin notification
  - [ ] Shipper approval/rejection → Shipper notification
  - [ ] Affiliate shipping request created → Affiliate notification
  - [ ] Shipping request accepted → Customer notification
  - [ ] Order confirmation → Customer email
  - [ ] Payout processed → Vendor/Affiliate email

**Files to create:**
- `server/src/services/email.js`
- `server/src/templates/emails/shipper-verification.html`
- `server/src/templates/emails/shipping-request.html`
- `server/src/templates/emails/order-confirmation.html`

---

### 1.2 Firebase Hosting for Admin Dashboard ⏳
**Priority:** CRITICAL  
**Time:** 0.5 day

- [ ] **Build admin dashboard for production**
  ```bash
  cd server/src/admin
  npm run build
  ```

- [ ] **Initialize Firebase Hosting**
  ```bash
  firebase init hosting
  # Select: server/src/admin/build as public directory
  # Configure as single-page app: Yes
  # Set up automatic builds with GitHub: Optional
  ```

- [ ] **Configure firebase.json**
  ```json
  {
    "hosting": {
      "public": "server/src/admin/build",
      "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
      "rewrites": [
        {
          "source": "**",
          "destination": "/index.html"
        }
      ]
    }
  }
  ```

- [ ] **Deploy admin dashboard**
  ```bash
  firebase deploy --only hosting
  ```

- [ ] **Update backend CORS to allow admin domain**
  - [ ] Add Firebase hosting URL to CORS whitelist
  - [ ] Update admin API authentication

- [ ] **Test deployed admin dashboard**
  - [ ] Login functionality
  - [ ] API connectivity
  - [ ] All pages load correctly

**Result:** Admin dashboard live at `https://shopsnports-admin.web.app`

---

## 🟡 PHASE 2: Backend API Development (Week 1-2)

### 2.1 Database Schema & Migrations ⏳
**Priority:** CRITICAL  
**Time:** 2 days

- [ ] **Create migration system**
  ```bash
  cd server
  npm install node-pg-migrate
  npx node-pg-migrate create initial-schema
  ```

- [ ] **Define database tables**
  - [ ] users
  - [ ] products
  - [ ] categories
  - [ ] orders
  - [ ] order_items
  - [ ] shipping_requests
  - [ ] affiliates
  - [ ] vendors
  - [ ] shippers
  - [ ] payouts
  - [ ] transactions
  - [ ] reviews
  - [ ] cart_items

- [ ] **Run migrations**
  ```bash
  npm run migrate up
  ```

- [ ] **Seed initial data**
  - [ ] Categories
  - [ ] Sample products
  - [ ] Admin user

---

### 2.2 Build REST API Endpoints ⏳
**Priority:** CRITICAL  
**Time:** 5-6 days

#### Products API
- [ ] `GET /api/v1/products` - List products with filters
- [ ] `GET /api/v1/products/:id` - Get product details
- [ ] `POST /api/v1/products` - Create product (vendor)
- [ ] `PUT /api/v1/products/:id` - Update product (vendor)
- [ ] `DELETE /api/v1/products/:id` - Delete product (vendor)
- [ ] `GET /api/v1/products/search` - Search products

#### Categories API
- [ ] `GET /api/v1/categories` - List categories
- [ ] `GET /api/v1/categories/:id` - Get category
- [ ] `GET /api/v1/categories/:id/products` - Category products

#### Orders API
- [ ] `GET /api/v1/orders` - List user orders
- [ ] `GET /api/v1/orders/:id` - Get order details
- [ ] `POST /api/v1/orders` - Create order
- [ ] `PUT /api/v1/orders/:id/status` - Update order status
- [ ] `GET /api/v1/orders/:id/track` - Track order

#### Shipping API
- [ ] `GET /api/v1/shipping` - List shipping requests
- [ ] `GET /api/v1/shipping/:id` - Get shipping request
- [ ] `POST /api/v1/shipping` - Create shipping request
- [ ] `PUT /api/v1/shipping/:id/claim` - Shipper claims request
- [ ] `PUT /api/v1/shipping/:id/complete` - Mark delivered
- [ ] `GET /api/v1/shipping/:id/track` - Track shipment

#### Customers API
- [ ] `GET /api/v1/customers/:id` - Get customer profile
- [ ] `PUT /api/v1/customers/:id` - Update profile
- [ ] `GET /api/v1/customers/:id/orders` - Customer orders
- [ ] `GET /api/v1/customers/:id/addresses` - List addresses
- [ ] `POST /api/v1/customers/:id/addresses` - Add address

#### Vendors API
- [ ] `GET /api/v1/vendors/:id` - Get vendor profile
- [ ] `PUT /api/v1/vendors/:id` - Update vendor
- [ ] `GET /api/v1/vendors/:id/products` - Vendor products
- [ ] `GET /api/v1/vendors/:id/orders` - Vendor orders
- [ ] `GET /api/v1/vendors/:id/analytics` - Vendor dashboard stats

#### Affiliates API
- [ ] `GET /api/v1/affiliates/:id` - Get affiliate profile
- [ ] `POST /api/v1/affiliates` - Register affiliate
- [ ] `GET /api/v1/affiliates/:id/requests` - Shipping requests
- [ ] `GET /api/v1/affiliates/:id/payouts` - Payout history
- [ ] `GET /api/v1/affiliates/:id/analytics` - Affiliate stats

#### Shippers API
- [ ] `POST /api/v1/shippers/verify` - Submit verification
- [ ] `GET /api/v1/shippers/:id/shipments` - Active shipments
- [ ] `GET /api/v1/shippers/:id/earnings` - Earnings summary

#### Cart API
- [ ] `GET /api/v1/cart` - Get user cart
- [ ] `POST /api/v1/cart/items` - Add to cart
- [ ] `PUT /api/v1/cart/items/:id` - Update quantity
- [ ] `DELETE /api/v1/cart/items/:id` - Remove from cart
- [ ] `DELETE /api/v1/cart` - Clear cart

#### Wishlist API
- [ ] `GET /api/v1/wishlist` - Get wishlist
- [ ] `POST /api/v1/wishlist/:productId` - Add to wishlist
- [ ] `DELETE /api/v1/wishlist/:productId` - Remove from wishlist

#### Reviews API
- [ ] `GET /api/v1/products/:id/reviews` - Product reviews
- [ ] `POST /api/v1/reviews` - Create review
- [ ] `PUT /api/v1/reviews/:id` - Update review
- [ ] `DELETE /api/v1/reviews/:id` - Delete review

**Files to create:**
- `server/src/routes/products.js`
- `server/src/routes/categories.js`
- `server/src/routes/orders.js`
- `server/src/routes/shipping.js`
- `server/src/routes/customers.js`
- `server/src/routes/vendors.js`
- `server/src/routes/affiliates.js`
- `server/src/routes/shippers.js`
- `server/src/routes/cart.js`
- `server/src/routes/wishlist.js`
- `server/src/routes/reviews.js`
- `server/src/middleware/auth.js` (Firebase token verification)
- `server/src/middleware/roles.js` (Role-based access control)

---

### 2.3 API Authentication & Authorization ⏳
**Priority:** CRITICAL  
**Time:** 1 day

- [ ] **Implement Firebase ID token verification**
  - [ ] Create auth middleware
  - [ ] Verify tokens on protected routes
  - [ ] Extract user from token

- [ ] **Role-based access control**
  - [ ] Customer role checks
  - [ ] Vendor role checks
  - [ ] Affiliate role checks
  - [ ] Shipper role checks
  - [ ] Admin role checks

- [ ] **Protect all endpoints**
  - [ ] Public: Products, Categories (read-only)
  - [ ] Authenticated: Cart, Orders, Profile
  - [ ] Role-specific: Vendor products, Affiliate requests

---

### 2.4 API Documentation ⏳
**Priority:** HIGH  
**Time:** 1 day

- [ ] **Install Swagger**
  ```bash
  npm install swagger-jsdoc swagger-ui-express
  ```

- [ ] **Document all endpoints**
  - [ ] Add JSDoc comments
  - [ ] Define request/response schemas
  - [ ] Add example requests

- [ ] **Serve API docs at `/api/docs`**

---

## 🟢 PHASE 3: Mobile App Integration (Week 3)

### 3.1 Disable Mock Data ⏳
**Priority:** CRITICAL  
**Time:** 0.5 day

- [ ] **Update service flags**
  - [ ] `lib/services/affiliate_api_service.dart` - Set `_useMockData = false`
  - [ ] `lib/services/content_service.dart` - Set `useMockData = false`
  - [ ] Search for all `useMock` flags and disable
  - [ ] Remove mock data generators

- [ ] **Configure API base URL**
  - [ ] Create `lib/core/config/api_config.dart`
  - [ ] Set production API URL
  - [ ] Environment-based switching (dev/staging/prod)

---

### 3.2 Connect to Real Backend ⏳
**Priority:** CRITICAL  
**Time:** 3 days

- [ ] **Update all API services**
  - [ ] `affiliate_api_service.dart` - Use real endpoints
  - [ ] `vendor_api_service.dart` - Use real endpoints
  - [ ] `content_service.dart` - Use real endpoints
  - [ ] All other services

- [ ] **Add HTTP client configuration**
  - [ ] Firebase ID token injection
  - [ ] Error handling
  - [ ] Retry logic
  - [ ] Timeout configuration

- [ ] **Test all API integrations**
  - [ ] Products loading
  - [ ] Cart operations
  - [ ] Order creation
  - [ ] Shipping requests
  - [ ] User profile updates

---

### 3.3 Complete Payment Processing ⏳
**Priority:** CRITICAL  
**Time:** 2 days

- [ ] **Implement Paystack payment flow**
  - [ ] Initialize payment with backend
  - [ ] Handle payment callback
  - [ ] Verify payment on backend
  - [ ] Update order status

- [ ] **Implement Flutterwave payment flow**
  - [ ] Initialize payment
  - [ ] Handle callback
  - [ ] Verify transaction
  - [ ] Update order

- [ ] **Add payment webhooks**
  - [ ] Backend webhook handlers
  - [ ] Payment verification
  - [ ] Order status updates
  - [ ] Email notifications

- [ ] **Test payment flows**
  - [ ] Paystack test cards
  - [ ] Flutterwave test cards
  - [ ] Failed payment handling
  - [ ] Refund handling

**Files to update:**
- `lib/screens/cart/payment_methods_screen.dart`
- `lib/screens/flutterwave_payment_screen.dart`
- `lib/services/payment_service.dart` (create)
- `server/src/routes/payments.js` (create)

---

### 3.4 Fix Critical TODOs ⏳
**Priority:** HIGH  
**Time:** 2 days

**High Priority TODOs (50+ found):**

- [ ] `lib/screens/flutterwave_payment_screen.dart:36` - Implement actual payment processing
- [ ] `lib/screens/request_shipping_screen.dart` - Fix provider references
- [ ] `lib/screens/vendor/product_form_screen.dart` - Add category selection, tags, dimensions
- [ ] `lib/screens/profile/profile_screen.dart:635` - Implement proper sign out
- [ ] `lib/screens/settings_screen.dart` - Theme switching, 2FA, export data, bug report
- [ ] `lib/screens/wishlist_screen.dart:121` - Implement actual cart add logic
- [ ] `lib/screens/product/product_details_screen.dart:494` - Add to cart functionality
- [ ] `lib/widgets/shipment_form.dart` - Update provider/attachments handling
- [ ] `lib/main.dart:93` - Re-enable production settings
- [ ] `lib/main.dart:145-146` - Implement deep links (affiliate, product)

---

### 3.5 Testing & QA ⏳
**Priority:** HIGH  
**Time:** 2 days

- [ ] **Run all test files**
  ```bash
  flutter test
  ```

- [ ] **Fix broken tests**
  - [ ] Update tests for new API integration
  - [ ] Mock API responses
  - [ ] Test error scenarios

- [ ] **Manual testing checklist**
  - [ ] User registration & login
  - [ ] Product browsing & search
  - [ ] Add to cart & checkout
  - [ ] Payment processing
  - [ ] Order tracking
  - [ ] Vendor product management
  - [ ] Affiliate request creation
  - [ ] Shipper verification & deliveries

---

## 🔵 PHASE 4: Admin Dashboard Completion (Week 4)

### 4.1 Shipper Verification Management ⏳
**Priority:** CRITICAL  
**Time:** 1 day

- [ ] **Create Shippers page (`server/src/admin/pages/Shippers.tsx`)**
  - [ ] List pending verifications
  - [ ] View shipper details
  - [ ] Approve/reject buttons
  - [ ] View submitted documents

- [ ] **Backend endpoints**
  - [ ] `GET /admin/api/shippers/pending` - Pending verifications
  - [ ] `PUT /admin/api/shippers/:id/approve` - Approve shipper
  - [ ] `PUT /admin/api/shippers/:id/reject` - Reject shipper

- [ ] **Email notifications**
  - [ ] Approval email to shipper
  - [ ] Rejection email with reason

---

### 4.2 Product Management ⏳
**Priority:** HIGH  
**Time:** 1 day

- [ ] **Create Products page**
  - [ ] List all products with filters
  - [ ] Search products
  - [ ] Edit product details
  - [ ] Approve/reject vendor products
  - [ ] Bulk actions (delete, feature)

- [ ] **Backend endpoints**
  - [ ] `GET /admin/api/products` - All products
  - [ ] `PUT /admin/api/products/:id` - Update product
  - [ ] `DELETE /admin/api/products/:id` - Delete product

---

### 4.3 Order Management ⏳
**Priority:** HIGH  
**Time:** 1 day

- [ ] **Create Orders page**
  - [ ] List all orders with filters
  - [ ] View order details
  - [ ] Update order status
  - [ ] Refund processing
  - [ ] Export orders (CSV)

- [ ] **Backend endpoints**
  - [ ] `GET /admin/api/orders` - All orders
  - [ ] `PUT /admin/api/orders/:id/status` - Update status
  - [ ] `POST /admin/api/orders/:id/refund` - Process refund

---

### 4.4 Payout Management ⏳
**Priority:** HIGH  
**Time:** 1 day

- [ ] **Create Payouts page**
  - [ ] Pending payout requests
  - [ ] Payout history
  - [ ] Mark as paid
  - [ ] Export payout reports

- [ ] **Backend endpoints**
  - [ ] `GET /admin/api/payouts/pending` - Pending payouts
  - [ ] `PUT /admin/api/payouts/:id/approve` - Approve payout
  - [ ] `PUT /admin/api/payouts/:id/paid` - Mark as paid

---

### 4.5 Analytics Dashboard ⏳
**Priority:** MEDIUM  
**Time:** 1 day

- [ ] **Enhance Dashboard page**
  - [ ] Sales charts (daily, weekly, monthly)
  - [ ] Top products
  - [ ] Top vendors
  - [ ] Revenue breakdown
  - [ ] User growth chart

- [ ] **Backend endpoints**
  - [ ] `GET /admin/api/analytics/sales` - Sales data
  - [ ] `GET /admin/api/analytics/products` - Product stats
  - [ ] `GET /admin/api/analytics/users` - User stats

---

## ⚫ PHASE 5: Production Preparation (Week 5)

### 5.1 Security Audit ⏳
**Priority:** CRITICAL  
**Time:** 2 days

- [ ] **Code security review**
  - [ ] Remove all hardcoded secrets
  - [ ] Verify Firebase rules
  - [ ] Check API authentication
  - [ ] SQL injection prevention
  - [ ] XSS prevention

- [ ] **Firestore security rules**
  - [ ] Lock down production database
  - [ ] Role-based access
  - [ ] Data validation rules

- [ ] **API rate limiting**
  - [ ] Per-user limits
  - [ ] Per-IP limits
  - [ ] Webhook limits

- [ ] **Environment variables**
  - [ ] Move all secrets to .env
  - [ ] Use cloud secrets manager (AWS Secrets Manager / GCP Secret Manager)
  - [ ] Rotate API keys

---

### 5.2 Performance Testing ⏳
**Priority:** HIGH  
**Time:** 1 day

- [ ] **Load testing**
  - [ ] API load tests (Apache JMeter / k6)
  - [ ] Database query optimization
  - [ ] Add database indexes
  - [ ] Enable caching (Redis)

- [ ] **Mobile app performance**
  - [ ] Profile app startup time
  - [ ] Optimize image loading
  - [ ] Lazy loading for lists
  - [ ] Database query optimization

- [ ] **Monitoring setup**
  - [ ] Firebase Performance Monitoring
  - [ ] Crashlytics verification
  - [ ] Backend logging (Winston/Bunyan)
  - [ ] Uptime monitoring (UptimeRobot)

---

### 5.3 App Store Submission ⏳
**Priority:** CRITICAL  
**Time:** 2 days

- [ ] **App Store assets**
  - [ ] App icon (1024×1024)
  - [ ] Screenshots (all device sizes)
  - [ ] App preview video
  - [ ] App description
  - [ ] Keywords
  - [ ] Privacy policy URL
  - [ ] Terms of service URL

- [ ] **Google Play Store**
  - [ ] Create store listing
  - [ ] Upload APK/AAB
  - [ ] Content rating
  - [ ] Privacy policy
  - [ ] Test with internal testers

- [ ] **Apple App Store**
  - [ ] Create App Store Connect listing
  - [ ] Upload IPA
  - [ ] App Review information
  - [ ] Privacy policy
  - [ ] Submit for review

---

### 5.4 Deployment Automation ⏳
**Priority:** HIGH  
**Time:** 1 day

- [ ] **CI/CD pipeline**
  - [ ] GitHub Actions workflow
  - [ ] Automated testing
  - [ ] Build automation
  - [ ] Deployment scripts

- [ ] **Backend deployment**
  - [ ] Deploy to production server (AWS/GCP/Heroku)
  - [ ] Database backup automation
  - [ ] Health check monitoring
  - [ ] Auto-scaling configuration

- [ ] **Firebase deployment**
  - [ ] Firestore production database
  - [ ] Firebase Hosting (admin)
  - [ ] Cloud Functions (if needed)
  - [ ] Firebase Storage

---

## 📋 Quick Start Checklist

### Week 1: Infrastructure
1. ✅ Sign up for SendGrid/Mailgun
2. ✅ Implement email service
3. ✅ Deploy admin to Firebase Hosting
4. ✅ Create database migrations
5. ✅ Build core API endpoints

### Week 2: API Completion
1. ✅ Finish all REST endpoints
2. ✅ Add authentication middleware
3. ✅ Create API documentation
4. ✅ Test all endpoints

### Week 3: Mobile Integration
1. ✅ Disable mock data
2. ✅ Connect to real backend
3. ✅ Complete payment flows
4. ✅ Fix critical TODOs
5. ✅ Test entire app

### Week 4: Admin & Polish
1. ✅ Shipper verification UI
2. ✅ Product/order management
3. ✅ Payout management
4. ✅ Analytics dashboard

### Week 5: Production
1. ✅ Security audit
2. ✅ Performance testing
3. ✅ App store submission
4. ✅ Deploy to production

---

## 🎯 Next Actions (Start Here)

### ACTION 1: Email Service Setup
**Time:** 2 hours  
**Files to create:**
- `server/src/services/email.js`
- `server/src/templates/emails/shipper-verification.html`
- `server/src/templates/emails/shipping-request.html`

### ACTION 2: Firebase Hosting Setup
**Time:** 1 hour  
**Commands:**
```bash
cd server/src/admin
npm run build
cd ../../..
firebase init hosting
firebase deploy --only hosting
```

### ACTION 3: Database Migrations
**Time:** 4 hours  
**Files to create:**
- `server/migrations/001_initial_schema.sql`
- `server/migrations/002_seed_data.sql`

---

## 📊 Progress Tracking

- [ ] Phase 1: Infrastructure (0/2 completed)
- [ ] Phase 2: Backend API (0/4 completed)
- [ ] Phase 3: Mobile Integration (0/5 completed)
- [ ] Phase 4: Admin Dashboard (0/5 completed)
- [ ] Phase 5: Production Prep (0/4 completed)

**Overall: 0/20 major tasks completed**

---

**Target Completion:** February 9, 2026 (5 weeks)  
**Daily Progress Required:** ~3-4 tasks per day  
**Current Status:** Ready to begin Phase 1

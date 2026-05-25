# Mobile App Backend Integration Guide

## AWS ECS API Endpoint
**Base URL:** `http://marketplace-api-alb-1242236330.us-east-1.elb.amazonaws.com`

---

## API Routes by Feature

### 🔐 Authentication (Firebase Auth)
- **Firebase Project ID:** `shopsnports`
- **Auth Method:** Firebase Authentication
- Mobile app uses Firebase SDK for login/signup
- Backend validates Firebase ID tokens

---

### 👤 Customer APIs
**Base Path:** `/api/v1/customers`

- `GET /api/v1/customers` - List all customers (admin)
- `GET /api/v1/customers/:id` - Get customer details
- `POST /api/v1/customers` - Create customer account
- `PUT /api/v1/customers/:id` - Update customer profile
- `DELETE /api/v1/customers/:id` - Delete customer
- `GET /api/v1/customers/:id/orders` - Get customer orders
- `GET /api/v1/customers/:id/reviews` - Get customer reviews

---

### 🏪 Vendor APIs
**Base Path:** `/api/v1/vendors`

- `GET /api/v1/vendors` - List all vendors
- `GET /api/v1/vendors/:id` - Get vendor details
- `POST /api/v1/vendors` - Register as vendor
- `PUT /api/v1/vendors/:id` - Update vendor profile
- `DELETE /api/v1/vendors/:id` - Delete vendor
- `GET /api/v1/vendors/:id/products` - Get vendor products
- `GET /api/v1/vendors/:id/orders` - Get vendor orders
- `GET /api/v1/vendors/:id/analytics` - Vendor analytics
- `PUT /api/v1/vendors/:id/status` - Update vendor status (admin)

---

### 🤝 Affiliate APIs
**Base Path:** `/api/v1/affiliates`

- `GET /api/v1/affiliates` - List all affiliates
- `GET /api/v1/affiliates/:id` - Get affiliate details
- `POST /api/v1/affiliates` - Register as affiliate
- `PUT /api/v1/affiliates/:id` - Update affiliate profile
- `DELETE /api/v1/affiliates/:id` - Delete affiliate
- `GET /api/v1/affiliates/:id/commissions` - Get affiliate commissions
- `GET /api/v1/affiliates/:id/referrals` - Get referral stats
- `POST /api/v1/affiliates/:id/generate-link` - Generate affiliate link

---

### 📦 Product APIs
**Base Path:** `/api/v1/products`

- `GET /api/v1/products` - List all products (with filters)
  - Query params: `?category=&minPrice=&maxPrice=&vendorId=&search=`
- `GET /api/v1/products/:id` - Get product details
- `POST /api/v1/products` - Create product (vendor)
- `PUT /api/v1/products/:id` - Update product (vendor)
- `DELETE /api/v1/products/:id` - Delete product (vendor/admin)
- `GET /api/v1/products/:id/reviews` - Get product reviews
- `POST /api/v1/products/:id/reviews` - Add product review
- `GET /api/v1/products/featured` - Get featured products
- `GET /api/v1/products/trending` - Get trending products

---

### 🏷️ Category APIs
**Base Path:** `/api/v1/categories`

- `GET /api/v1/categories` - List all categories
- `GET /api/v1/categories/:id` - Get category details
- `GET /api/v1/categories/:id/products` - Get products by category

---

### 🛒 Cart & Checkout APIs
**Base Path:** `/api/v1/cart` & `/api/v1/orders`

- `GET /api/v1/cart/:customerId` - Get customer cart
- `POST /api/v1/cart/:customerId/items` - Add item to cart
- `PUT /api/v1/cart/:customerId/items/:itemId` - Update cart item
- `DELETE /api/v1/cart/:customerId/items/:itemId` - Remove cart item
- `DELETE /api/v1/cart/:customerId` - Clear cart
- `POST /api/v1/orders` - Create order (checkout)
- `GET /api/v1/orders/:id` - Get order details
- `GET /api/v1/orders/customer/:customerId` - Get customer orders
- `PUT /api/v1/orders/:id/status` - Update order status

---

### 📧 Shipping/Cargo APIs
**Base Path:** `/api/v1/shipping`

- `GET /api/v1/shipping/zones` - Get shipping zones
- `GET /api/v1/shipping/carriers` - Get shipping carriers
- `POST /api/v1/shipping/calculate` - Calculate shipping cost
  - Body: `{ origin, destination, weight, dimensions }`
- `POST /api/v1/shipping-requests` - Create shipping request
- `GET /api/v1/shipping-requests/:id` - Get shipping request status
- `PUT /api/v1/shipping-requests/:id` - Update shipping request
- `POST /api/v1/shipping-requests/:id/assign-carrier` - Assign carrier

---

### 💰 Payment APIs
**Base Path:** `/api/v1/payments`

- `GET /api/v1/payments/methods` - Get available payment methods
- `POST /api/v1/payments/process` - Process payment
- `GET /api/v1/payments/:id` - Get payment status
- `POST /api/v1/payments/:id/refund` - Request refund

---

### ⭐ Review APIs
**Base Path:** `/api/v1/reviews`

- `GET /api/v1/reviews` - List reviews
- `POST /api/v1/reviews` - Create review
- `PUT /api/v1/reviews/:id` - Update review
- `DELETE /api/v1/reviews/:id` - Delete review
- `PUT /api/v1/reviews/:id/approve` - Approve review (admin)

---

### 💳 Invoice APIs
**Base Path:** `/api/v1/invoices`

- `GET /api/v1/invoices` - List invoices
- `GET /api/v1/invoices/:id` - Get invoice details
- `POST /api/v1/invoices` - Create invoice
- `PUT /api/v1/invoices/:id` - Update invoice
- `GET /api/v1/invoices/:id/pdf` - Download invoice PDF

---

### 💸 Payout APIs (Vendor/Affiliate)
**Base Path:** `/api/v1/payouts`

- `GET /api/v1/payouts` - List payouts
- `GET /api/v1/payouts/:id` - Get payout details
- `POST /api/v1/payouts/request` - Request payout
- `PUT /api/v1/payouts/:id/approve` - Approve payout (admin)

---

### 📊 Analytics APIs
**Base Path:** `/api/v1/analytics`

- `GET /api/v1/analytics/dashboard` - Get dashboard stats
- `GET /api/v1/analytics/sales` - Get sales analytics
- `GET /api/v1/analytics/products` - Get product analytics
- `GET /api/v1/analytics/customers` - Get customer analytics

---

### 📰 News Ticker APIs
**Base Path:** `/api/v1/news-ticker`

- `GET /api/v1/news-ticker/feed` - Get published news feed
- `GET /api/v1/news-ticker/feed/:id` - Get news item
- `POST /api/v1/news-ticker/feed/:id/view` - Increment view count
- `GET /api/v1/news-ticker/feed/trending` - Get trending news

---

### 🔔 Notification APIs (Firebase Cloud Messaging)
**Firebase Server Key:** Configured in backend
- Mobile app uses FCM for push notifications
- Backend sends notifications via Firebase Admin SDK

---

## Firebase Configuration

### Required in Mobile App:
```dart
// lib/core/config/firebase_config.dart
const firebaseConfig = {
  'projectId': 'shopsnports',
  'apiKey': 'YOUR_FIREBASE_API_KEY',
  'messagingSenderId': 'YOUR_SENDER_ID',
  'appId': 'YOUR_APP_ID',
};
```

### Firebase Services Used:
1. **Firebase Authentication** - User login/signup
2. **Cloud Firestore** - Real-time data (optional)
3. **Cloud Messaging (FCM)** - Push notifications
4. **Firebase Analytics** - App analytics
5. **Firebase Storage** - Image uploads

---

## Mobile App API Client Setup

```dart
// lib/core/api/api_config.dart
class ApiConfig {
  static const String baseUrl = 
    'http://marketplace-api-alb-1242236330.us-east-1.elb.amazonaws.com/api/v1';
  
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
```

---

## Authentication Flow

1. **User signs up/logs in** → Firebase Auth
2. **Get Firebase ID Token** → `await user.getIdToken()`
3. **Send token with API requests** → `Authorization: Bearer <token>`
4. **Backend validates token** → Firebase Admin SDK
5. **Backend returns user data** → Mobile app updates state

---

## Testing Checklist

### Customer Flow:
- [ ] Sign up with email/password
- [ ] Login with existing account
- [ ] Browse products by category
- [ ] Search products
- [ ] Add products to cart
- [ ] Update cart quantities
- [ ] Checkout and create order
- [ ] View order history
- [ ] Track shipping status
- [ ] Submit product reviews

### Vendor Flow:
- [ ] Register as vendor
- [ ] Login to vendor account
- [ ] Create new products
- [ ] Update product details
- [ ] View product orders
- [ ] Update order status
- [ ] View sales analytics
- [ ] Request payouts

### Affiliate Flow:
- [ ] Register as affiliate
- [ ] Generate affiliate links
- [ ] View referral stats
- [ ] View commission earnings
- [ ] Request commission payouts

---

## Deployment Targets

### Android:
- Build: `flutter build apk --release` or `flutter build appbundle`
- Deploy: Google Play Store
- Min SDK: 21 (Android 5.0)

### iOS:
- Build: `flutter build ipa --release`
- Deploy: Apple App Store
- Min iOS: 12.0

---

## Environment Variables (Mobile App)

Create `.env` file:
```env
API_BASE_URL=http://marketplace-api-alb-1242236330.us-east-1.elb.amazonaws.com
FIREBASE_PROJECT_ID=shopsnports
FIREBASE_API_KEY=your_api_key_here
APP_NAME=ShopsNSports
```

---

## CORS Configuration (Backend)

Backend must allow mobile app requests:
```javascript
// In marketplace-api
app.use(cors({
  origin: '*', // Or specific mobile app schemes
  credentials: true
}));
```

---

## Next Steps

1. Open mobile app project in VS Code
2. Update `ApiConfig` with ECS endpoint
3. Configure Firebase with `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
4. Test authentication flow
5. Test all API integrations
6. Build production APK/AAB/IPA
7. Submit to app stores

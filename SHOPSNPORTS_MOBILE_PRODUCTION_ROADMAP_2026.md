# 🚀 SHOPSNPORTS MOBILE APP - PRODUCTION ROADMAP 2026

**Date:** February 11, 2026  
**Target:** Production launch  
**Timeline:** 7-10 business days  
**Confidence:** HIGH

---

## 📋 TABLE OF CONTENTS
1. [Executive Summary](#executive-summary)
2. [Phase 1: Critical Fixes](#phase-1-critical-fixes)
3. [Phase 2: Payment Integration](#phase-2-payment-integration)
4. [Phase 3: Testing & Quality](#phase-3-testing--quality)
5. [Phase 4: Security & Compliance](#phase-4-security--compliance)
6. [Phase 5: Final Testing & Launch](#phase-5-final-testing--launch)
7. [Parallel Tasks](#parallel-tasks)
8. [Risk Mitigation](#risk-mitigation)
9. [Success Criteria](#success-criteria)

---

## EXECUTIVE SUMMARY

### Current State
- **Code Status:** 17 compilation errors blocking build
- **Functionality:** 42% complete
- **Test Coverage:** 0%
- **Known Issues:** 54 total (12 critical, 18 high, 24 medium)

### Target State (Production)
- **Code Status:** 0 compilation errors, < 5 linter warnings
- **Functionality:** 90%+ complete
- **Test Coverage:** 70%+ minimum
- **Known Issues:** 0 critical, 0 high (in production)

### Success Metrics
- Zero downtime deployment
- < 1% error rate in first week
- 99% API availability
- < 2s screen load time
- 60fps frame rate

---

## PHASE 1: CRITICAL FIXES (Day 1)
**Duration:** 8 hours focused work  
**Team:** 1-2 developers  
**Goal:** App compiles and runs without crashing

### Task 1.1: Fix Compilation Errors (4 hours)

#### 1.1.1 Fix firestore_constants.dart Nested Classes
**File:** `lib/config/firestore_constants.dart`  
**Issue:** Classes declared inside other classes (invalid Dart)  
**Lines:** 62-244

```dart
// BEFORE (WRONG):
class FirestoreCollections {
  class UserFields {  // ← Invalid nested class
    static const String uid = 'uid';
  }
  
  class ShippingRequestFields {  // ← Invalid
    static const String id = 'id';
  }
}

// AFTER (CORRECT):
class UserFields {  // ← Top level
  static const String uid = 'uid';
}

class ShippingRequestFields {  // ← Top level
  static const String id = 'id';
}

class FirestoreCollections {
  static const String users = 'users';
  static const String orders = 'orders';
}
```

**Action Items:**
- [ ] Move all nested classes to top-level
- [ ] Classes to move:
  - `UserFields` (line 62)
  - `ShippingRequestFields` (line 82)
  - `AffiliateFields` (line 106)
  - `NotificationFields` (line 127)
  - `NotificationSettingsFields` (line 144)
  - `NewsTickerFields` (line 162)
  - `BannerFields` (line 178)
  - `InvoiceFields` (line 194)
  - `PayoutFields` (line 213)
  - `ContentPageFields` (line 230)
  - `PushNotificationTemplateFields` (line 244)
- [ ] Update imports in files that use these classes
- [ ] Verify compilation succeeds

**Verification:**
```bash
flutter pub get
flutter analyze  # Should have 0 errors
flutter build apk --analyze  # Build check
```

---

#### 1.1.2 Fix home_screen.dart String Quote Escape
**File:** `lib/screens/home_screen.dart`  
**Issue:** String literal with unescaped quote  
**Line:** 873

```dart
// BEFORE (WRONG):
title: const Text('Shop's & Ports'),  // ← Unescaped apostrophe breaks string

// AFTER (CORRECT - Option 1 - Double quotes):
title: const Text("Shop's & Ports"),

// AFTER (CORRECT - Option 2 - Escape quote):
title: const Text('Shop\'s & Ports'),

// AFTER (CORRECT - Option 3 - Use raw string):
title: const Text(r"Shop's & Ports"),
```

**Action Items:**
- [ ] Change line 873 from `'Shop's & Ports'` to `"Shop's & Ports"`
- [ ] Verify no other similar quote issues exist
- [ ] Test home screen renders correctly

**Related Issues:**
- Lines 249-250: `slide.color[300]!` and `slide.color[700]!` - Color is not indexable

```dart
// BEFORE (WRONG):
subtitle: 'From ₦${slide.color[300]}',  // ← Color is not a Map
subtitle: 'To ₦${slide.color[700]}',

// AFTER (CORRECT):
// Option 1: If slide has a minPrice/maxPrice:
subtitle: 'From ₦${slide.minPrice}',
subtitle: 'To ₦${slide.maxPrice}',

// Option 2: If using MaterialColor:
subtitle: 'From ₦${MaterialColor(slide.color.value, {...})[300]}',

// Option 3: If color[300] represents a price value:
// Define color as: Color priceColor = Color(0xFF...);
// And use separate price fields
```

**Action Items:**
- [ ] Identify what `slide.color[300]` and `slide.color[700]` represent
- [ ] Update to use correct fields or remove if not needed
- [ ] Test carousel renders with correct values

**Additional Issue (Line 895-896):**
- App structure may be using MainScaffold but this raw Scaffold is conflicting
- [ ] Check if this should use MainScaffold instead
- [ ] Or verify drawer/body parameters exist

**Verification:**
```bash
flutter analyze
flutter build apk  # Should compile without errors
```

---

#### 1.1.3 Fix affiliate_shipment_repository.dart Missing Field
**File:** `lib/repositories/affiliate_shipment_repository.dart`  
**Issue:** `_affiliateApi` used in constructor but not declared  
**Line:** 15

```dart
// BEFORE (WRONG):
class AffiliateShipmentRepository {
  final AffiliateApi _api;  // ← Only _api declared
  
  AffiliateShipmentRepository({required AffiliateApi affiliateApi})
    : _affiliateApi = affiliateApi;  // ← But _affiliateApi used here!
}

// AFTER (CORRECT):
class AffiliateShipmentRepository {
  final AffiliateApi _affiliateApi;  // ← Declare _affiliateApi
  
  AffiliateShipmentRepository({required AffiliateApi affiliateApi})
    : _affiliateApi = affiliateApi;
}
```

**Action Items:**
- [ ] Add field declaration for `_affiliateApi`
- [ ] Update field name references throughout class
- [ ] Test compilation

---

#### 1.1.4 Fix Unreachable Switch Default Cases
**Files:**
- `lib/screens/affiliate/commission_tracking_screen.dart` (lines 68, 85)
- `lib/screens/affiliate/payout_management_screen.dart` (lines 157, 172)

**Issue:** Default case covered by previous pattern matching

```dart
// BEFORE (WRONG):
switch (filter) {
  case 'all': return _allCommissions;
  case 'pending': return _pendingCommissions;
  case 'paid': return _paidCommissions;
  default: return _allCommissions;  // ← Unreachable - 'all' covers this
}

// AFTER (CORRECT):
switch (filter) {
  case 'all': return _allCommissions;
  case 'pending': return _pendingCommissions;
  case 'paid': return _paidCommissions;
  // Remove default or add fallback message
}

// Or if all cases not covered:
switch (filter) {
  case 'all': return _allCommissions;
  case 'pending': return _pendingCommissions;
  case 'paid': return _paidCommissions;
  default: return _allCommissions;
}
```

**Action Items:**
- [ ] Analyze each switch statement
- [ ] Remove unreachable default cases
- [ ] Ensure all branches covered
- [ ] Test affiliate screens

---

#### 1.1.5 Clean Up Unused Imports and Variables

**Files to fix:**
- [ ] `lib/screens/payment/payment_billing_screen.dart` - Remove unused `_cvv` field
- [ ] `lib/screens/user_settings_screen.dart` - Remove unused import `models/user.dart`
- [ ] `lib/screens/shipping/pickup_scheduling_screen.dart` - Remove unused `_selectedTime`
- [ ] `lib/screens/shipping/quote_request_screen.dart` - Remove unused import
- [ ] `lib/screens/shipping/shipping_request_screen.dart` - Remove unused variables
- [ ] `lib/widgets/main_scaffold.dart` - Remove unused `_openCart()` method
- [ ] `lib/widgets/shipment_form.dart` - Use `map` variable or remove

**Action Items:**
- [ ] Use `flutter analyze` to identify all unused symbols
- [ ] Run `dart fix --apply` to auto-fix removable issues
- [ ] Manual review for remaining unused code
- [ ] Test that app still functions after cleanup

**Verification:**
```bash
flutter analyze
# Should show: 0 errors, minimal warnings
```

---

### Task 1.2: Disable Mock Data (2 hours)

#### 1.2.1 Disable Mock Data in All Services
**Files to update:**

```dart
// 1. lib/services/affiliate_api_service.dart (Search: _useMockData)
- static const bool _useMockData = true;  // ← Change to false
+ static const bool _useMockData = false;

// 2. lib/services/content_service.dart
- useMockData: true,  // ← Change to false
+ useMockData: false,

// 3. lib/repositories/vendor_product_repository.dart
- const bool _useMockProductData = true;  // ← Change to false
+ const bool _useMockProductData = false;

// 4. lib/repositories/vendor_order_repository.dart
- const bool _useMockOrderData = true;  // ← Change to false
+ const bool _useMockOrderData = false;

// 5. lib/repositories/affiliate_shipment_repository.dart
- const bool _useMockShipmentData = true;  // ← Change to false
+ const bool _useMockShipmentData = false;

// 6. lib/repositories/vendor_repository.dart
- const bool _useMockVendorData = true;  // ← Change to false
+ const bool _useMockVendorData = false;
```

**Action Items:**
- [ ] Search for all `_useMockData`, `useMockData`, `_useMock*Data` patterns
- [ ] Set all to `false`
- [ ] Verify with `grep "useMockData\|_useMockData" lib/**/*.dart`
- [ ] Test that real API data is being used (check network tab)

**Verification:**
```bash
# Verify no mock data flags remain as true
grep -r "_useMockData = true" lib/
grep -r "useMockData: true" lib/
# Should return 0 results
```

---

#### 1.2.2 Add Environment-Based Configuration (Optional but Recommended)

**Create:** `lib/core/config/environment.dart`

```dart
enum Environment { development, staging, production }

class EnvironmentConfig {
  static const Environment currentEnvironment = 
    String.fromEnvironment('FLUTTER_ENV') == 'prod'
      ? Environment.production
      : String.fromEnvironment('FLUTTER_ENV') == 'staging'
      ? Environment.staging
      : Environment.development;
  
  static bool get useMockData {
    return currentEnvironment == Environment.development;
  }
  
  static String get apiBaseUrl {
    switch (currentEnvironment) {
      case Environment.production:
        return 'https://api.shopsnports.com';
      case Environment.staging:
        return 'https://staging-api.shopsnports.com';
      case Environment.development:
        return 'http://localhost:3000';
    }
  }
}
```

**Build Commands:**
```bash
# Development (mock data enabled)
flutter run --dart-define=FLUTTER_ENV=dev

# Staging (mock data disabled, staging API)
flutter run --dart-define=FLUTTER_ENV=staging

# Production (mock data disabled, production API)
flutter run --dart-define=FLUTTER_ENV=prod
```

**Action Items:**
- [ ] Create environment configuration
- [ ] Update all services to use EnvironmentConfig
- [ ] Update build scripts
- [ ] Document environment setup

---

### Task 1.3: Verify App Runs (2 hours)

**Action Items:**
- [ ] `flutter clean`
- [ ] `flutter pub get`
- [ ] `flutter analyze` - expect < 5 warnings
- [ ] `flutter build apk` - must succeed
- [ ] `flutter run` on emulator - must not crash
- [ ] Test basic navigation (all bottom nav tabs)
- [ ] Test home screen specifically (string fixed)
- [ ] Verify real API data showing (mock disabled)

**Testing Checklist:**
```
✅ App launches without crash
✅ Bottom navigation works (Home, Categories, Cart, Profile)
✅ Home screen displays correctly
✅ No unhandled exceptions
✅ Network requests showing real data (not mock)
✅ Cart has real products
✅ Can navigate to all screens
```

---

## PHASE 2: PAYMENT INTEGRATION (Days 2-3)
**Duration:** 8 hours focused work  
**Team:** 1 developer (payments specialist preferred)  
**Goal:** Full payment flow working end-to-end

### Task 2.1: Configure Payment Gateways (3 hours)

#### 2.1.1 Paystack Integration Setup

**Current Status:** Integration exists, needs live configuration

**Steps:**
1. **Get Paystack Credentials**
   - [ ] Create Paystack account (https://paystack.com)
   - [ ] Complete KYC verification
   - [ ] Get Public Key and Secret Key
   - [ ] Set up sub-accounts for vendors (if applicable)

2. **Update Configuration**
   ```dart
   // lib/core/config/payment_config.dart
   class PaymentConfig {
     static const String paystackPublicKey = 'pk_live_...';  // From Paystack dashboard
     static const String paystackSecretKey = 'sk_live_...';  // Backend only
   }
   ```

3. **Test Paystack Integration**
   - [ ] Test payment initialization
   - [ ] Test OTP verification
   - [ ] Test callback handling
   - [ ] Verify funds transfer

**Files to Update:**
- `lib/screens/cart/payment_methods_screen.dart` - Initialize with live key
- `lib/services/payment_service.dart` - Add Paystack handler
- Backend payment endpoint - Process Paystack transactions

---

#### 2.1.2 Stripe Integration Completion

**Current Status:** Partial integration

**Steps:**
1. **Get Stripe Live Keys**
   - [ ] Create Stripe account (https://stripe.com)
   - [ ] Complete identity verification
   - [ ] Get Publishable Key and Secret Key
   - [ ] Set up payment intents

2. **Complete Stripe Integration**
   ```dart
   // lib/services/stripe_service.dart
   class StripeService {
     static const String publishableKey = 'pk_live_...';
     static const String secretKey = 'sk_live_...';  // Backend only
     
     static Future<void> initialize() async {
       Stripe.publishableKey = publishableKey;
       await Stripe.instance.applySettings();
     }
     
     static Future<PaymentIntentResponse> processPayment({
       required double amount,
       required String currency,
     }) async {
       // Implementation
     }
   }
   ```

3. **Test Stripe Payments**
   - [ ] Test payment intent creation
   - [ ] Test 3D Secure (if applicable)
   - [ ] Test webhook handling
   - [ ] Test refunds

---

#### 2.1.3 Flutterwave Configuration

**Current Status:** Integrated but OTP issues need fixing

**Steps:**
1. **Get Flutterwave Credentials**
   - [ ] Create Flutterwave account
   - [ ] Complete verification
   - [ ] Get Public Key and Secret Key

2. **Fix OTP/KYC Issues**
   - [ ] Debug OTP verification failures
   - [ ] Implement proper KYC flow
   - [ ] Test bank transfers

3. **Configuration**
   ```dart
   // lib/core/config/payment_config.dart
   class FlutterwaveConfig {
     static const String publicKey = 'FLWPUBK_TEST_...';
     static const String secretKey = 'FLWSECK_TEST_...';
   }
   ```

---

### Task 2.2: Fix Payment Amount Bug (1 hour)

**Issue:** Cart total not passed to payment screen  
**File:** `lib/screens/cart/payment_methods_screen.dart`  
**Current Code:**
```dart
amount: 100.0,  // ← HARDCODED!
```

**Fix:**
```dart
// Get cart total from provider
final cartTotal = ref.read(cartTotalProvider);

// Pass to payment gateway
amount: cartTotal,

// Or create a payment data class:
class PaymentData {
  final double amount;
  final String currency;
  final List<CartItem> items;
  final ShippingAddress address;
  
  PaymentData({
    required this.amount,
    required this.items,
    required this.address,
    this.currency = 'NGN',
  });
}
```

**Action Items:**
- [ ] Create CartTotalProvider if not exists
- [ ] Calculate total including shipping
- [ ] Calculate total including taxes (if applicable)
- [ ] Pass correct amount to all payment gateways
- [ ] Test with different cart amounts

---

### Task 2.3: Implement Payment Verification (2 hours)

**Steps:**
1. **Create Payment Verification Service**
   ```dart
   // lib/services/payment_verification_service.dart
   class PaymentVerificationService {
     /// Verify payment with backend
     Future<PaymentStatus> verifyPayment({
       required String transactionId,
       required String paymentGateway,
     }) async {
       // Call backend endpoint: /api/v1/payments/verify
       // Return status: pending, success, failed
     }
     
     /// Handle payment webhook
     Future<bool> handleWebhook({
       required Map<String, dynamic> data,
       required String gateway,
     }) async {
       // Verify webhook signature
       // Update payment status in database
       // Create order if payment successful
       return true;
     }
   }
   ```

2. **Add Backend Endpoints**
   - `POST /api/v1/payments/verify` - Verify payment
   - `POST /api/v1/payments/webhook/:gateway` - Handle webhooks
   - `GET /api/v1/payments/:transactionId` - Get payment status

3. **Implement Confirmation Flow**
   ```dart
   // lib/screens/payment_confirmation_screen.dart
   Future<void> _verifyPayment() async {
     final result = await _paymentVerificationService.verifyPayment(
       transactionId: widget.transactionId,
       paymentGateway: widget.gateway,
     );
     
     if (result.status == PaymentStatus.success) {
       // Create order
       // Show success screen
     } else {
       // Show retry option
     }
   }
   ```

---

### Task 2.4: End-to-End Payment Testing (2 hours)

**Test Cases:**
- [ ] Add item to cart
- [ ] Proceed to checkout
- [ ] Select payment method (Paystack)
- [ ] Complete payment (test card)
- [ ] Verify payment succeeded
- [ ] View order confirmation
- [ ] See order in Orders screen
- [ ] Test Stripe payment
- [ ] Test Flutterwave payment
- [ ] Test failed payment recovery
- [ ] Test refund flow

**Test Data:**
```
Paystack Test: 5531 8860 6862 7272 (any future date, any CVC)
Stripe Test: 4242 4242 4242 4242 (any future date, any CVC)
Flutterwave Test: Providedby Flutterwave
```

---

## PHASE 3: TESTING & QUALITY (Days 3-5)
**Duration:** 15 hours focused work  
**Team:** 1-2 developers + 1 QA  
**Goal:** 70%+ test coverage, all critical flows tested

### Task 3.1: Set Up Testing Infrastructure (2 hours)

**Create test directory structure:**
```
test/
├── unit/
│   ├── providers/
│   │   ├── cart_provider_test.dart
│   │   ├── auth_provider_test.dart
│   │   └── user_provider_test.dart
│   ├── services/
│   │   ├── payment_service_test.dart
│   │   ├── api_service_test.dart
│   │   └── auth_service_test.dart
│   └── models/
│       ├── user_test.dart
│       ├── order_test.dart
│       └── cart_item_test.dart
├── widget/
│   ├── main_scaffold_test.dart
│   ├── cart_screen_test.dart
│   ├── checkout_screen_test.dart
│   └── payment_methods_screen_test.dart
└── integration/
    ├── checkout_flow_test.dart
    └── auth_flow_test.dart
```

**Create test utilities:**
```dart
// test/helpers/test_helpers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';

// Mock providers
class MockUserRepository extends Mock implements UserRepository {}
class MockCartRepository extends Mock implements CartRepository {}
class MockPaymentService extends Mock implements PaymentService {}

// Test widget wrapper
Widget createTestWidget({required Widget child}) {
  return ProviderScope(
    child: MaterialApp(home: child),
  );
}

// Common test data builders
User createTestUser({String id = '1'}) => User(
  id: id,
  name: 'Test User',
  email: 'test@example.com',
);

CartItem createTestCartItem() => CartItem(
  productId: '1',
  quantity: 1,
  price: 100.0,
);
```

**Action Items:**
- [ ] Create test directory structure
- [ ] Create test helper utilities
- [ ] Add test dependencies to pubspec.yaml:
  ```yaml
  dev_dependencies:
    flutter_test:
      sdk: flutter
    mockito: ^5.4.0
    fake_cloud_firestore: ^4.0.0
  ```
- [ ] Create GitHub Actions workflow for CI/CD testing (optional but recommended)

---

### Task 3.2: Write Critical Path Tests (8 hours)

#### 3.2.1 Authentication Tests (2 hours)
**File:** `test/unit/providers/auth_provider_test.dart`

```dart
void main() {
  group('AuthProvider', () {
    late ProviderContainer container;
    late MockAuthRepository mockAuthRepository;
    
    setUp(() {
      mockAuthRepository = MockAuthRepository();
      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
        ],
      );
    });
    
    test('Sign up successful', () async {
      when(mockAuthRepository.signUp(
        email: 'test@example.com',
        password: 'password123',
      )).thenAnswer((_) async => User(id: '1', email: 'test@example.com'));
      
      final state = await container.read(authActionsProvider.future);
      expect(state.user, isNotNull);
      expect(state.user?.email, equals('test@example.com'));
    });
    
    test('Sign in successful', () async {
      // Test sign in flow
    });
    
    test('Sign out clears user', () async {
      // Test sign out
    });
    
    test('Invalid email rejected', () async {
      // Test validation
    });
  });
}
```

**Tests to write:**
- [ ] Sign up with valid email/password
- [ ] Sign up with invalid email
- [ ] Sign up with weak password
- [ ] Sign in with valid credentials
- [ ] Sign in with invalid password
- [ ] Sign out clears user
- [ ] Password reset flow
- [ ] Email verification flow

---

#### 3.2.2 Cart Management Tests (2 hours)
**File:** `test/unit/providers/cart_provider_test.dart`

```dart
void main() {
  group('CartProvider', () {
    late ProviderContainer container;
    
    setUp(() {
      container = ProviderContainer();
    });
    
    test('Add item to cart', () async {
      final item = createTestCartItem();
      container.read(cartNotifierProvider.notifier).addItem(item);
      
      final cart = container.read(cartNotifierProvider);
      expect(cart.items.length, equals(1));
      expect(cart.items.first.productId, equals(item.productId));
    });
    
    test('Update cart item quantity', () async {
      container.read(cartNotifierProvider.notifier).addItem(createTestCartItem());
      container.read(cartNotifierProvider.notifier).updateQuantity('1', 5);
      
      final cart = container.read(cartNotifierProvider);
      expect(cart.items.first.quantity, equals(5));
    });
    
    test('Remove item from cart', () async {
      container.read(cartNotifierProvider.notifier).addItem(createTestCartItem());
      container.read(cartNotifierProvider.notifier).removeItem('1');
      
      final cart = container.read(cartNotifierProvider);
      expect(cart.items.length, equals(0));
    });
    
    test('Clear cart', () async {
      container.read(cartNotifierProvider.notifier).addItem(createTestCartItem());
      container.read(cartNotifierProvider.notifier).clear();
      
      final cart = container.read(cartNotifierProvider);
      expect(cart.items.length, equals(0));
    });
    
    test('Calculate total correctly', () async {
      container.read(cartNotifierProvider.notifier).addItem(
        CartItem(productId: '1', quantity: 2, price: 100.0),
      );
      container.read(cartNotifierProvider.notifier).addItem(
        CartItem(productId: '2', quantity: 1, price: 50.0),
      );
      
      final total = container.read(cartTotalProvider);
      expect(total, equals(250.0));
    });
  });
}
```

**Tests to write:**
- [ ] Add item to empty cart
- [ ] Add duplicate item (increase quantity)
- [ ] Update item quantity
- [ ] Remove item from cart
- [ ] Clear all items
- [ ] Calculate cart total
- [ ] Apply coupon/discount
- [ ] Persist cart to local storage
- [ ] Restore cart from storage

---

#### 3.2.3 Payment Tests (2 hours)
**File:** `test/unit/services/payment_service_test.dart`

```dart
void main() {
  group('PaymentService', () {
    late PaymentService paymentService;
    late MockPaymentGateway mockGateway;
    
    setUp(() {
      mockGateway = MockPaymentGateway();
      paymentService = PaymentService(gateway: mockGateway);
    });
    
    test('Process payment successfully', () async {
      when(mockGateway.initiatePayment(
        amount: 1000.0,
        email: 'test@example.com',
      )).thenAnswer((_) async => PaymentResponse(
        status: 'success',
        transactionId: 'TXN123',
      ));
      
      final result = await paymentService.processPayment(
        amount: 1000.0,
        email: 'test@example.com',
      );
      
      expect(result.status, equals('success'));
      expect(result.transactionId, equals('TXN123'));
    });
    
    test('Handle payment failure', () async {
      when(mockGateway.initiatePayment(
        amount: 1000.0,
        email: 'test@example.com',
      )).thenThrow(PaymentException('Payment declined'));
      
      expect(
        () => paymentService.processPayment(
          amount: 1000.0,
          email: 'test@example.com',
        ),
        throwsA(isA<PaymentException>()),
      );
    });
    
    test('Verify payment status', () async {
      when(mockGateway.verifyPayment('TXN123'))
        .thenAnswer((_) async => PaymentStatus.completed);
      
      final status = await paymentService.verifyPayment('TXN123');
      expect(status, equals(PaymentStatus.completed));
    });
  });
}
```

**Tests to write:**
- [ ] Process payment successfully
- [ ] Handle payment failure
- [ ] Verify payment status
- [ ] Refund payment
- [ ] Handle timeout
- [ ] Validate payment data
- [ ] Test all payment gateways (Paystack, Stripe, Flutterwave)

---

#### 3.2.4 Widget Tests (2 hours)

**Checkout Screen Test**
```dart
// test/widget/checkout_screen_test.dart
void main() {
  testWidgets('Checkout screen displays items', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget(
      child: CheckoutScreen(),
    ));
    
    expect(find.text('Order Summary'), findsOneWidget);
    expect(find.byType(CartItemTile), findsWidgets);
  });
  
  testWidgets('Proceed button enabled with valid address', (WidgetTester tester) async {
    // Test implementation
  });
  
  testWidgets('Navigate to payment on proceed', (WidgetTester tester) async {
    // Test navigation
  });
}
```

**Payment Methods Screen Test**
```dart
// test/widget/payment_methods_screen_test.dart
void main() {
  testWidgets('Display all payment methods', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget(
      child: PaymentMethodsScreen(),
    ));
    
    expect(find.text('Paystack'), findsOneWidget);
    expect(find.text('Stripe'), findsOneWidget);
    expect(find.text('Flutterwave'), findsOneWidget);
  });
  
  testWidgets('Select payment method', (WidgetTester tester) async {
    // Test selection
  });
  
  testWidgets('Payment gateway initializes on tap', (WidgetTester tester) async {
    // Test payment init
  });
}
```

**Tests to write:**
- [ ] Home screen displays correctly
- [ ] Navigation works between screens
- [ ] Search functionality works
- [ ] Product details display
- [ ] Cart screen updates correctly
- [ ] Checkout step-by-step flow
- [ ] Payment method selection
- [ ] Order confirmation display
- [ ] Orders list display

---

### Task 3.3: Run Tests and Fix Failures (3 hours)

**Action Items:**
- [ ] Run all tests: `flutter test --coverage`
- [ ] Check coverage report: `coverage/lcov.info`
- [ ] Generate HTML coverage: `genhtml coverage/lcov.info -o coverage/html`
- [ ] Fix any failing tests
- [ ] Aim for 70%+ coverage
- [ ] Document test results

**Commands:**
```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Generate coverage report
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html  # View report

# Run specific test file
flutter test test/unit/providers/cart_provider_test.dart

# Run tests matching pattern
flutter test --name="Cart"

# Watch mode (re-run on changes)
flutter test --watch
```

---

### Task 3.4: Fix Code Quality Issues (2 hours)

**Action Items:**
- [ ] Run analysis: `flutter analyze`
- [ ] Expected output: 0 errors, < 5 warnings
- [ ] Run formatter: `flutter format .`
- [ ] Update analysis_options.yaml with stricter rules
- [ ] Fix remaining warnings
- [ ] Commit code quality improvements

**Updated analysis_options.yaml:**
```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    # Errors
    avoid_empty_else: true
    avoid_print: true
    avoid_relative_lib_imports: true
    avoid_returning_null_for_future: true
    avoid_slow_async_io: true
    cancel_subscriptions: true
    close_sinks: true
    comment_references: true
    control_flow_in_finally: true
    empty_statements: true
    hash_and_equals: true
    invariant_booleans: true
    iterable_contains_unrelated_type: true
    list_remove_unrelated_type: true
    no_adjacent_strings_in_list: true
    no_duplicate_case_values: true
    prefer_void_to_null: true
    throw_in_finally: true
    unnecessary_statements: true
    unrelated_type_equality_checks: true
    valid_regexps: true
    
    # Style
    always_declare_return_types: true
    always_put_control_body_on_new_line: false
    always_put_required_named_parameters_first: true
    annotate_overrides: true
    avoid_bool_literals_in_conditional_expressions: true
    avoid_catching_errors: true
    avoid_classes_with_only_static_members: false
    avoid_double_and_int_checks: true
    avoid_field_initializers_in_const_classes: true
    avoid_function_literals_in_foreach_calls: true
    avoid_init_to_null: true
    avoid_null_checks_in_equality_operators: true
    avoid_positional_boolean_parameters: true
    avoid_private_typedef_functions: true
    avoid_redundant_argument_values: true
    avoid_renaming_method_parameters: true
    avoid_returning_null: false
    avoid_returning_null_for_future: true
    avoid_returning_this: false
    avoid_setters_without_getters: true
    avoid_shadowing_type_parameters: true
    avoid_single_cascade_in_expression_statements: true
    avoid_types_as_parameter_names: true
    avoid_types_on_extension_declarations: true
    avoid_types_on_loop_variable_declaration: true
    avoid_unnecessary_containers: true
    avoid_unnecessary_getters_setters: true
    await_only_futures: true
    camel_case_extensions: true
    camel_case_types: true
    cascade_invocations: false
    cast_nullable_to_non_nullable: true
    constant_identifier_names: true
    curly_braces_in_flow_control_structures: true
    directives_ordering: true
    empty_catches: true
    empty_constructor_bodies: true
    eol_only_newlines: true
    file_names: true
    implementation_imports: true
    leading_newlines_in_multiline_strings: true
    library_names: true
    library_prefixes: true
    library_private_types_in_public_api: true
    lines_longer_than_80_chars: false
    no_leading_underscores_for_library_prefixes: true
    no_leading_underscores_for_local_variables: true
    null_closures: true
    null_check_on_nullable_type_parameter: true
    null_to_closure_preservation: true
    omit_local_variable_types: false
    one_member_abstracts: false
    only_throw_errors: true
    overridden_fields: true
    package_api_docs: false
    package_names: true
    package_prefixed_library_names: true
    parameter_assignments: true
    prefer_adjacent_string_concatenation: true
    prefer_asserts_in_initializer_lists: true
    prefer_asserts_with_message: true
    prefer_collection_literals: true
    prefer_conditional_assignment: true
    prefer_const_constructors: true
    prefer_const_constructors_in_immutables: true
    prefer_const_declarations: true
    prefer_const_literals_to_create_immutables: true
    prefer_constructors_over_static_methods: false
    prefer_contains: true
    prefer_equal_for_default_values: true
    prefer_expression_function_bodies: false
    prefer_final_fields: true
    prefer_final_in_for_each: true
    prefer_final_locals: true
    prefer_for_elements_to_map_fromIterable: true
    prefer_foreach: false
    prefer_function_declarations_over_variables: true
    prefer_generic_function_type_aliases: true
    prefer_if_elements_to_conditional_expressions: true
    prefer_if_null_to_conditional_expression: true
    prefer_if_on_single_line_statements: false
    prefer_initializing_formals: true
    prefer_inlined_adds: true
    prefer_int_literals: true
    prefer_interpolation_to_compose_strings: true
    prefer_int_literals: true
    prefer_is_empty: true
    prefer_is_not_empty: true
    prefer_is_not_operator: true
    prefer_is_null_check_operator: true
    prefer_null_aware_operators: true
    prefer_null_coalescing_operators: true
    prefer_relative_imports: true
    prefer_single_quotes: true
    provide_deprecation_message: true
    recursive_getters: true
    sized_box_for_whitespace: true
    sized_box_shrink_expand: true
    sized_box_to_shrink_box: true
    slash_for_doc_comments: true
    sort_child_properties_last: true
    sort_constructors_first: true
    sort_pub_dependencies: true
    sort_unnamed_constructors_first: true
    tighten_type_of_initializing_formals: true
    type_annotate_public_apis: true
    type_init_formals: true
    unawaited_futures: true
    unnecessary_await_in_return: true
    unnecessary_brace_in_string_interps: true
    unnecessary_const: true
    unnecessary_constructor_name: true
    unnecessary_getters_setters: false
    unnecessary_lambdas: true
    unnecessary_new: true
    unnecessary_null_aware_operators: true
    unnecessary_null_checks: true
    unnecessary_null_in_if_null_operators: true
    unnecessary_null_on_extension_on_nullable_type: true
    unnecessary_nullable_for_final_variable_declarations: true
    unnecessary_overrides: true
    unnecessary_parenthesis: true
    unnecessary_statements: true
    unnecessary_string_escapes: true
    unnecessary_string_interpolations: true
    unnecessary_this: true
    unnecessary_to_list_in_spreads: true
    unrelated_type_equality_checks: true
    unsafe_html: true
    use_build_context_synchronously: true
    use_full_hex_values_for_flutter_colors: true
    use_function_type_syntax_for_parameters: true
    use_getters_to_change_properties: false
    use_if_null_to_convert_nulls: true
    use_is_even_rather_than_modulo: true
    use_key_in_widget_constructors: true
    use_late_for_private_fields_and_variables: true
    use_rethrow_when_possible: true
    use_setters_to_change_properties: false
    use_string_buffers: true
    use_test_throws_matchers: true
    use_to_close_resource_in_finally: true
    use_unnamed_constants: true
    void_checks: true
```

---

## PHASE 4: SECURITY & COMPLIANCE (Days 5-6)
**Duration:** 8 hours focused work  
**Team:** 1 developer (security focused) + 1 legal  
**Goal:** App meets security standards and app store requirements

### Task 4.1: Implement Secure Token Storage (2 hours)

**Current Issue:** Tokens stored in SharedPreferences (not encrypted)  
**Fix:** Implement flutter_secure_storage

**Steps:**
1. **Add Dependency**
   ```yaml
   dependencies:
     flutter_secure_storage: ^9.0.0
   ```

2. **Create Secure Storage Service**
   ```dart
   // lib/services/secure_storage_service.dart (UPDATE EXISTING)
   import 'package:flutter_secure_storage/flutter_secure_storage.dart';
   
   class SecureStorageService {
     static const _authTokenKey = 'auth_token';
     static const _refreshTokenKey = 'refresh_token';
     static const _userIdKey = 'user_id';
     
     static final _storage = const FlutterSecureStorage(
       aOptions: AndroidOptions(
         keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
         storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
       ),
       iOptions: IOSOptions(
         accessibility: KeychainAccessibility.first_available_when_unlocked_this_device_only,
       ),
     );
     
     /// Save auth token securely
     static Future<void> saveAuthToken(String token) async {
       try {
         await _storage.write(
           key: _authTokenKey,
           value: token,
         );
       } catch (e) {
         AppLogger.error('Error saving auth token', e);
         rethrow;
       }
     }
     
     /// Retrieve auth token
     static Future<String?> getAuthToken() async {
       try {
         return await _storage.read(key: _authTokenKey);
       } catch (e) {
         AppLogger.error('Error reading auth token', e);
         return null;
       }
     }
     
     /// Save refresh token
     static Future<void> saveRefreshToken(String token) async {
       try {
         await _storage.write(
           key: _refreshTokenKey,
           value: token,
         );
       } catch (e) {
         AppLogger.error('Error saving refresh token', e);
         rethrow;
       }
     }
     
     /// Retrieve refresh token
     static Future<String?> getRefreshToken() async {
       try {
         return await _storage.read(key: _refreshTokenKey);
       } catch (e) {
         AppLogger.error('Error reading refresh token', e);
         return null;
       }
     }
     
     /// Delete all tokens (on logout)
     static Future<void> deleteAllTokens() async {
       try {
         await _storage.delete(key: _authTokenKey);
         await _storage.delete(key: _refreshTokenKey);
         await _storage.delete(key: _userIdKey);
       } catch (e) {
         AppLogger.error('Error deleting tokens', e);
       }
     }
   }
   ```

3. **Update Auth Service to Use Secure Storage**
   ```dart
   // lib/services/auth_service.dart
   class AuthService {
     Future<void> saveTokens(String accessToken, String refreshToken) async {
       await SecureStorageService.saveAuthToken(accessToken);
       await SecureStorageService.saveRefreshToken(refreshToken);
     }
     
     Future<String?> getAccessToken() async {
       return await SecureStorageService.getAuthToken();
     }
     
     Future<String?> getRefreshToken() async {
       return await SecureStorageService.getRefreshToken();
     }
     
     Future<void> logout() async {
       await SecureStorageService.deleteAllTokens();
     }
   }
   ```

4. **Platform-Specific Configuration**
   - **Android:** Ensures encryption via Android Keystore
   - **iOS:** Uses Keychain with proper accessibility settings

**Action Items:**
- [ ] Add flutter_secure_storage to pubspec.yaml
- [ ] Create/update SecureStorageService
- [ ] Update AuthService to use secure storage
- [ ] Remove SharedPreferences token storage
- [ ] Test on real devices (Android + iOS)
- [ ] Verify tokens survive app restart

---

### Task 4.2: Add HTTPS & Certificate Pinning (1.5 hours)

**Current Status:** HTTPS not enforced  
**Fix:** Implement certificate pinning

**Steps:**
1. **Configure API Base URLs**
   ```dart
   // lib/core/config/api_config.dart
   class ApiConfig {
     static const String baseUrl = 'https://api.shopsnports.com';
     static const String apiVersion = '/api/v1';
     
     static const Map<String, String> certificatePins = {
       'api.shopsnports.com': '''
         -----BEGIN CERTIFICATE-----
         MIIDXTCCAkWgAwIBAgIJAJC1/iNAZwqDMA0GCSqGSIb3DQEBBQUAMEUxCzAJBgNV
         ... (certificate content)
         -----END CERTIFICATE-----
       ''',
     };
   }
   ```

2. **Create HTTP Client with Pinning**
   ```dart
   // lib/services/http_client_service.dart
   import 'dart:io';
   import 'package:http/http.dart' as http;
   
   class HttpClientService {
     static http.Client createHttpClient() {
       final client = http.Client();
       
       // Configure SecurityContext for certificate pinning
       final context = SecurityContext.defaultContext;
       
       // Load certificate from assets
       // context.setTrustedCertificates('assets/certs/api_cert.pem');
       
       return client;
     }
   }
   ```

3. **Enforce HTTPS in API Service**
   ```dart
   // lib/services/api_service.dart
   class ApiService {
     Future<T> get<T>(
       String endpoint, {
       required T Function(dynamic) parser,
     }) async {
       // Ensure HTTPS
       if (!endpoint.startsWith('https://')) {
         throw SecurityException('Only HTTPS requests allowed');
       }
       
       final response = await _httpClient.get(Uri.parse(endpoint));
       
       if (response.statusCode == 200) {
         return parser(jsonDecode(response.body));
       } else {
         throw ApiException('Error: ${response.statusCode}');
       }
     }
   }
   ```

**Action Items:**
- [ ] Get SSL certificate from hosting provider
- [ ] Add certificate pinning
- [ ] Update ApiService to enforce HTTPS
- [ ] Test with actual API calls
- [ ] Verify certificate validation works

---

### Task 4.3: Remove Hardcoded Secrets & Values (1.5 hours)

**Locations to Fix:**
1. **API Endpoints** - Currently may be hardcoded
2. **Stripe Keys** - Check main.dart and payment screens
3. **Firebase Config** - Already handled by Firebase, but verify
4. **Database URLs** - Should use config
5. **Feature Flags** - Should use dynamic config

**Implementation:**
```dart
// lib/core/config/secrets.dart
class SecretsConfig {
  /// Get Stripe publishable key from environment or config
  static String get stripePublishableKey {
    const key = String.fromEnvironment('STRIPE_PUBLISHABLE_KEY');
    if (key.isEmpty) {
      throw Exception('STRIPE_PUBLISHABLE_KEY not configured');
    }
    return key;
  }
  
  /// Get API base URL (can be from environment or constants)
  static String get apiBaseUrl {
    const url = String.fromEnvironment('API_BASE_URL');
    return url.isNotEmpty ? url : 'https://api.shopsnports.com';
  }
  
  /// Never log or expose these
  static void validateSecrets() {
    assert(stripePublishableKey.isNotEmpty, 'Stripe key not set');
    assert(apiBaseUrl.isNotEmpty, 'API URL not set');
  }
}
```

**Build Commands:**
```bash
# Build with environment variables
flutter build apk \
  --dart-define=STRIPE_PUBLISHABLE_KEY=pk_live_... \
  --dart-define=API_BASE_URL=https://api.shopsnports.com
```

**Action Items:**
- [ ] Identify all hardcoded secrets
- [ ] Move to SecretsConfig
- [ ] Use environment variables for CI/CD
- [ ] Verify no secrets in git history
- [ ] Add secrets validation on app start

---

### Task 4.4: Implement Legal Pages (2 hours)

**Required Pages:**
1. **Privacy Policy**
2. **Terms of Service**
3. **Return/Refund Policy**
4. **Shipping Policy**
5. **GDPR Compliance**
6. **Cookie Policy**

**Implementation:**

```dart
// lib/screens/legal/legal_page_screen.dart
class LegalPageScreen extends ConsumerWidget {
  final String pageType;  // 'privacy', 'terms', 'shipping', etc.
  
  const LegalPageScreen({required this.pageType});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAsync = ref.watch(legalContentProvider(pageType));
    
    return MainScaffold(
      appBarTitle: _getTitleForType(pageType),
      showBackOnly: true,
      body: contentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (content) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Flutter.Html(content),  // Or use markdown_widget
        ),
      ),
    );
  }
  
  String _getTitleForType(String type) {
    return {
      'privacy': 'Privacy Policy',
      'terms': 'Terms of Service',
      'shipping': 'Shipping Policy',
      'return': 'Return Policy',
      'gdpr': 'GDPR',
      'cookies': 'Cookie Policy',
    }[type] ?? 'Legal';
  }
}

// Create provider
final legalContentProvider = FutureProvider.family<String, String>((ref, pageType) async {
  // Fetch from admin dashboard or backend
  final response = await http.get(
    Uri.parse('https://api.shopsnports.com/api/v1/legal/$pageType'),
  );
  if (response.statusCode == 200) {
    return jsonDecode(response.body)['content'] as String;
  }
  throw Exception('Failed to load legal content');
});
```

**Steps:**
1. **Create Legal Pages in Admin Dashboard**
   - Add content management interface in web admin
   - Allow admins to edit legal pages

2. **Create API Endpoints**
   - `GET /api/v1/legal/:pageType` - Get legal page content

3. **Link from Settings Screen**
   ```dart
   // lib/screens/settings/settings_screen.dart
   ListTile(
     title: const Text('Privacy Policy'),
     trailing: const Icon(Icons.arrow_forward),
     onTap: () => context.push(
       '/legal/privacy',
       // Or use named route
     ),
   ),
   ```

4. **Add Acceptance Flow (First Time Users)**
   ```dart
   // lib/widgets/legal_acceptance_dialog.dart
   class LegalAcceptanceDialog extends StatefulWidget {
     @override
     State<LegalAcceptanceDialog> createState() => _LegalAcceptanceDialogState();
   }
   
   class _LegalAcceptanceDialogState extends State<LegalAcceptanceDialog> {
     bool _privacyAccepted = false;
     bool _termsAccepted = false;
     
     @override
     Widget build(BuildContext context) {
       return AlertDialog(
         title: const Text('Welcome to ShopsNPorts'),
         content: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             CheckboxListTile(
               title: const Text('I accept the Privacy Policy'),
               value: _privacyAccepted,
               onChanged: (val) => setState(() => _privacyAccepted = val ?? false),
             ),
             CheckboxListTile(
               title: const Text('I accept the Terms of Service'),
               value: _termsAccepted,
               onChanged: (val) => setState(() => _termsAccepted = val ?? false),
             ),
           ],
         ),
         actions: [
           ElevatedButton(
             onPressed: _privacyAccepted && _termsAccepted
               ? () {
                   ref.read(legalAcceptanceProvider.notifier).accept();
                   Navigator.pop(context);
                 }
               : null,
             child: const Text('Accept & Continue'),
           ),
         ],
       );
     }
   }
   ```

**Action Items:**
- [ ] Write all legal page content
- [ ] Create admin interface to manage pages
- [ ] Implement API endpoints
- [ ] Create legal page screens
- [ ] Link from settings
- [ ] Implement first-time acceptance flow
- [ ] Test on all screens

---

## PHASE 5: FINAL TESTING & LAUNCH (Days 6-7)
**Duration:** 9 hours focused work  
**Team:** 2 developers + 1-2 QA  
**Goal:** Production-ready app deployed to app stores

### Task 5.1: Device Testing (3 hours)

**Test Devices:**
- [ ] Android (latest version, minimum SDK)
- [ ] Android (budget device - 4GB RAM)
- [ ] iOS (latest version)
- [ ] iOS (iPhone 12 or older)

**Test Cases:**
```
✅ Authentication
  - Sign up new account
  - Sign in with existing account
  - Password reset
  - Social login (Google)
  - Logout

✅ Shopping
  - Search products
  - Browse categories
  - View product details
  - Add to cart
  - Update cart quantities
  - Remove from cart
  - Add to wishlist
  - View wishlist

✅ Checkout & Payment
  - Add shipping address
  - Apply coupon
  - Select payment method
  - Complete payment (test card)
  - View order confirmation
  - View orders list
  - Track shipment

✅ User Account
  - Edit profile
  - Change password
  - Manage addresses
  - View saved payment methods
  - View notifications
  - Adjust notification settings

✅ Performance
  - App startup time < 3s
  - Screen transitions smooth (60fps)
  - Large lists scroll without jank
  - No memory leaks
  - Battery usage acceptable

✅ Edge Cases
  - Offline -> Online transition
  - Poor network conditions
  - App backgrounding/resuming
  - Deep links
  - Push notifications
```

---

### Task 5.2: Integration Testing (2 hours)

```dart
// integration_test/checkout_flow_test.dart
void main() {
  group('End-to-End Checkout', () {
    testWidgets('Complete purchase flow', (WidgetTester tester) async {
      // Launch app
      await app.main();
      await tester.pumpAndSettle();
      
      // Sign in
      await tester.enterText(find.byType(TextField).first, 'test@example.com');
      await tester.enterText(find.byType(TextField).last, 'password123');
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();
      
      // Browse and add product
      await tester.tap(find.text('Products'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ProductCard).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add to Cart'));
      await tester.pumpAndSettle();
      
      // Go to cart
      await tester.tap(find.byIcon(Icons.shopping_cart));
      await tester.pumpAndSettle();
      
      // Checkout
      await tester.tap(find.text('Checkout'));
      await tester.pumpAndSettle();
      
      // Enter address
      await tester.enterText(find.byType(TextField).first, '123 Main St');
      await tester.pumpAndSettle();
      
      // Select payment
      await tester.tap(find.text('Paystack'));
      await tester.pumpAndSettle();
      
      // Verify success
      expect(find.text('Order Confirmed'), findsOneWidget);
    });
  });
}
```

**Run Integration Tests:**
```bash
flutter drive \
  --target=integration_test/checkout_flow_test.dart
```

---

### Task 5.3: App Store Preparation (2 hours)

#### 5.3.1 Android App Store (Google Play)

**Requirements:**
1. **App Signing**
   ```bash
   # Create keystore (one-time)
   keytool -genkey -v -keystore ~/upload-keystore.jks \
     -keyalg RSA -keysize 2048 -validity 10000 \
     -alias upload -storepass mypassword -keypass mypassword
   
   # Sign app
   flutter build apk --release --obfuscate --split-debug-info=build/app/debug
   ```

2. **Play Store Listed**
   - [ ] Create Google Play Developer account ($25 one-time)
   - [ ] Add app listing
   - [ ] Fill store listing (screenshots, description, etc.)
   - [ ] Set content rating
   - [ ] Configure pricing and distribution
   - [ ] Review privacy policy
   - [ ] Submit for review

3. **Store Listing:**
   ```
   Title: ShopsNPorts
   Short Description: Buy and sell online
   Full Description: ShopsNPorts is...
   Screenshots: 5+ screenshots showing app screens
   Feature Graphic: 1024x500px banner
   Icon:512x512px app icon
   Privacy Policy URL: https://shopsnports.com/privacy
   ```

---

#### 5.3.2 iOS App Store (Apple App Store)

**Requirements:**
1. **Build**
   ```bash
   flutter build ipa --release
   ```

2. **App Store Connect**
   - [ ] Create Apple Developer account ($99/year)
   - [ ] Create app in App Store Connect
   - [ ] Fill app information
   - [ ] Add screenshots and previews
   - [ ] Configure app signing

3. **TestFlight (Beta Testing)**
   - [ ] Build and upload to TestFlight
   - [ ] Add internal testers
   - [ ] Conduct beta testing
   - [ ] Fix issues
   - [ ] Submit for App Store review

---

### Task 5.4: Marketing & Launch (2 hours)

**Pre-Launch:**
- [ ] Prepare press release
- [ ] Create social media content
- [ ] Email list announcement
- [ ] Partner outreach
- [ ] Marketing calendar

**Launch:**
- [ ] Submit to Google Play
- [ ] Submit to App Store
- [ ] Announce on social media
- [ ] Email users
- [ ] Update website
- [ ] Monitor reviews and ratings

**Post-Launch (First Week):**
- [ ] Monitor app store reviews
- [ ] Track crash reports
- [ ] Fix critical bugs
- [ ] Respond to user feedback
- [ ] Monitor engagement metrics

---

## PARALLEL TASKS

These tasks can be done while main phases are in progress:

### Backend Preparation (Can start immediately)
- [ ] Deploy REST API to production
- [ ] Set up database backups
- [ ] Configure monitoring and logging
- [ ] Set up error alerts
- [ ] Test API endpoints with mobile app

### Documentation (Can start immediately)
- [ ] Update README with setup instructions
- [ ] Document API endpoints
- [ ] Create deployment guide
- [ ] Create user guide
- [ ] Create admin documentation

### DevOps (Can start Day 1)
- [ ] Set up CI/CD pipeline
- [ ] Configure automated testing
- [ ] Set up staging environment
- [ ] Configure app store CI/CD
- [ ] Set up monitoring

---

## RISK MITIGATION

### Risk: Payment Integration Fails
**Likelihood:** Medium  
**Impact:** CRITICAL  
**Mitigation:**
- Implement payment with test mode first
- Have fallback payment method ready
- Test with real test cards early
- Have payment specialist on standby

### Risk: App Store Rejection
**Likelihood:** Low  
**Impact:** HIGH  
**Mitigation:**
- Review app store guidelines thoroughly
- Test privacy policy implementation
- Ensure proper age rating
- Review app before final submission

### Risk: Performance Issues on Budget Devices
**Likelihood:** Medium  
**Impact:** MEDIUM  
**Mitigation:**
- Profile app early
- Optimize large screens (home, product list)
- Compress images
- Test on budget devices regularly

### Risk: Real-World Network Issues
**Likelihood:** High  
**Impact:** MEDIUM  
**Mitigation:**
- Implement timeout handling
- Add retry logic
- Test on slow networks
- Implement offline mode (future)

### Risk: Critical Bug After Launch
**Likelihood:** Low  
**Impact:** CRITICAL  
**Mitigation:**
- Thorough QA before launch
- Monitoring and alerts set up
- Rollback plan ready
- Support team briefed

---

## SUCCESS CRITERIA

### Code Quality
- ✅ 0 compilation errors
- ✅ < 5 linter warnings
- ✅ 70%+ test coverage
- ✅ All critical tests passing

### Functionality
- ✅ All user flows tested and working
- ✅ Payment processing verified
- ✅ Authentication flows complete
- ✅ API integration tested

### Performance
- ✅ App startup < 3 seconds
- ✅ Screen load < 2 seconds
- ✅ 60fps animations
- ✅ Memory usage < 150MB

### Security
- ✅ No hardcoded secrets
- ✅ Secure token storage
- ✅ HTTPS certificate pinning
- ✅ Input validation complete

### Compliance
- ✅ Privacy policy present
- ✅ Terms of service present
- ✅ GDPR compliant
- ✅ App store review passed

---

## DEPLOYMENT CHECKLIST

### T-24 Hours
- [ ] Final code review
- [ ] Run full test suite
- [ ] Backup production database
- [ ] Test rollback procedure
- [ ] Brief support team
- [ ] Prepare documentation

### T-1 Hour
- [ ] Final build created
- [ ] Signatures verified
- [ ] Store listings verified
- [ ] Monitoring configured
- [ ] Alerts tested

### T=0 (Launch)
- [ ] Submit to Google Play
- [ ] Submit to App Store
- [ ] Announce on social media
- [ ] Email users
- [ ] Monitor dashboards

### T+1 Hour
- [ ] Verify app appears in stores
- [ ] Monitor crash reports
- [ ] Check reviews coming in
- [ ] Test app from app store

### T+24 Hours
- [ ] Check weekly metrics
- [ ] Verify no critical issues
- [ ] Respond to reviews
- [ ] Plan next release

---

## SUMMARY

| Phase | Duration | Tasks | Status |
|-------|----------|-------|--------|
| Phase 1: Critical Fixes | 8 hours | Compilation, Mock Data, Run Test | 🔴 Not Started |
| Phase 2: Payment | 8 hours | Configure Gateways, Test Flows | 🔴 Not Started |
| Phase 3: Testing | 15 hours | Write Tests, Quality, Coverage | 🔴 Not Started |
| Phase 4: Security | 8 hours | Tokens, HTTPS, Legal Pages | 🔴 Not Started |
| Phase 5: Launch | 9 hours | Device Testing, App Store, Deploy | 🔴 Not Started |
| **Total** | **48 hours** | **50+ Tasks** | **🔴 0% Complete** |

**Calendar Timeline:** 7-10 business days  
**With Buffer:** 2-3 weeks recommended

---

**Created:** February 11, 2026  
**Next Review:** After Phase 1 (Day 2)  
**Status:** READY TO EXECUTE  
**Confidence:** HIGH (Detailed action items, clear success criteria)


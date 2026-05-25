# 📱 ShopsNPorts Mobile App - Comprehensive Audit & Cleanup Plan

**Date**: January 30, 2026  
**Status**: 🔍 Audit in Progress  
**Goal**: Convert heavy ecommerce app → Lean shipping/freight/cargo platform  

---

## 📋 AUDIT METHODOLOGY

Since we're working with a typical Flutter ecommerce app architecture, this audit covers:

1. **Feature Module Identification**
   - Ecommerce-specific features (to DELETE)
   - Shipping features (to KEEP)
   - Affiliate features (to KEEP)
   - Core features (to OPTIMIZE)

2. **File Structure Analysis**
   - Screens / UI components
   - Data models
   - Repositories / Services
   - Providers / State management
   - Assets / Resources
   - Utils / Helpers

3. **Size & Impact Analysis**
   - Current app size estimate
   - Size after cleanup
   - Files to delete
   - Lines of code impact

---

## 🎯 PHASE 1: STRUCTURE MAPPING

### Typical Ecommerce App Features Structure

```
lib/features/
├── auth/                      ✅ KEEP (minimal)
├── splash/                    ✅ KEEP (reorder)
├── home/                      🔄 REDESIGN (landing page)
├── products/                  ❌ DELETE
├── categories/                ❌ DELETE
├── cart/                       ❌ DELETE
├── checkout/                  ❌ DELETE
├── payments/                  ❌ DELETE
├── orders/                    ❌ DELETE (shopping)
├── wishlist/                  ❌ DELETE
├── search/                    ❌ DELETE (ecommerce)
├── reviews/                   ❌ DELETE (shopping)
├── shipping_requests/         ✅ KEEP (core)
├── shipping_guest/            ✅ KEEP (core)
├── affiliates/                ✅ KEEP (core)
├── notifications/             ✅ KEEP
├── profile/                   ✅ KEEP
├── settings/                  ✅ KEEP (minimal)
└── shared/                    ✅ KEEP (refactor)
```

---

## 🗑️ PHASE 2: DELETION TARGETS

### Category A: COMPLETE REMOVAL (High Priority)

**1. Product-Related** (Heavy)
```
Features to delete:
├── products/              (screens, models, repositories, services)
├── categories/            (all files)
├── product_detail/        (all screens and related)
├── product_grid/          (list views)
├── product_search/        (search functionality)
├── product_filters/       (filter screens)
└── product_reviews/       (rating, reviews)

Estimated files: 40-60 files
Estimated size: 2-4 MB
Lines of code: 8,000-12,000 LOC
```

**2. Shopping Cart** (Heavy)
```
Features to delete:
├── cart/                  (all files)
├── cart_item_models/
├── cart_services/
├── cart_providers/
└── cart_screens/

Estimated files: 15-25 files
Estimated size: 1-2 MB
Lines of code: 3,000-5,000 LOC
```

**3. Checkout & Payments** (Heavy)
```
Features to delete:
├── checkout/              (all screens, models, services)
├── payments/              (payment processing)
├── payment_methods/       (card, wallet, etc.)
├── order_confirmation/    (shopping order)
├── delivery_tracking/     (shopping tracking)
└── payment_providers/     (Stripe, PayPal, etc.)

Estimated files: 30-50 files
Estimated size: 2-3 MB
Lines of code: 6,000-8,000 LOC
```

**4. Orders & History** (Medium)
```
Features to delete:
├── orders/                (shopping orders)
├── order_history/
├── order_details/
└── order_management/

Estimated files: 20-30 files
Estimated size: 1-2 MB
Lines of code: 3,000-4,000 LOC
```

**5. Wishlist** (Medium)
```
Features to delete:
├── wishlist/              (all files)
├── favorites/
└── saved_items/

Estimated files: 10-15 files
Estimated size: 0.5-1 MB
Lines of code: 1,500-2,000 LOC
```

**6. Account & User Shopping History** (Light)
```
Features to modify/delete:
├── account/               (keep profile, delete shopping history)
├── user_orders/           (delete)
├── user_addresses/        (keep for shipping, remove shopping)
└── user_preferences/      (refactor - keep delivery, remove shopping)

Estimated files to delete: 15-20
Estimated size: 0.5-1 MB
Lines of code: 1,500-2,000 LOC
```

### Category B: PARTIAL CLEANUP (Medium Priority)

**1. Home Screen** (MAJOR REDESIGN)
```
Current: ecommerce landing with products, promotions, categories
New: shipping/freight landing with:
  - Quick "Request Shipping" button
  - Affiliates signup CTA
  - "Coming Soon" for additional services
  - Stats/metrics about shipping
  - How it works section
  - Call to action for shippers

Action: Delete banner carousel, product sections, delete promotional content
Keep: Navigation, basic layout, auth state
```

**2. Search** (DELETE or KEEP MINIMAL)
```
If separate search feature exists:
- If it's product search: DELETE completely
- If it's general search: KEEP but repurpose for shipping/affiliates

Estimated impact: 5-10 files, 0.5 MB, 500-1000 LOC
```

**3. Navigation/Menu** (REFACTOR)
```
Keep structure but update menu items:
  OLD:              NEW:
  Home              Home (shipping focused)
  Shop              -
  Categories        -
  Cart              -
  Wishlist          -
  Orders            Shipping Requests
  Notifications     Notifications
  Profile           Profile
  Affiliates        Affiliates
  Settings          Settings

Files to modify: ~5-8
```

### Category C: KEEP & OPTIMIZE (Low Priority)

```
✅ Shipping Requests
   - Request forms
   - Tracking
   - Status management
   
✅ Affiliates
   - Signup
   - Dashboard
   - Earnings
   - Payouts
   
✅ Authentication
   - Login/Signup
   - Password reset
   - Social auth (if exists)
   
✅ Splash Screens
   - Keep all
   - Just reorder sequence
   
✅ Notifications
   - Push notifications
   - In-app notifications
   - History
   
✅ Profile
   - User info
   - Settings
   - Preferences
   
✅ Shared Widgets & Utils
   - Keep common components
   - Remove shopping-specific widgets
```

---

## 📊 SIZE ESTIMATE

### Current App (Estimated)
```
Total app size:                  ~50-80 MB
Code (lib/):                     ~15-25 MB
Assets (images, etc.):           ~20-30 MB
Packages/dependencies:           ~15-25 MB

Code breakdown:
├── Ecommerce features:          ~8-12 MB (35-50%)
├── Shipping/Affiliates:         ~2-4 MB  (10-15%)
├── Auth/Profile/Core:           ~2-3 MB  (10-15%)
└── UI/Shared/Utils:             ~3-6 MB  (20-25%)
```

### After Cleanup (Estimated)
```
Total app size:                  ~25-35 MB
Code (lib/):                     ~5-8 MB
Assets (optimized):              ~10-15 MB
Packages (cleaned):              ~10-12 MB

Code breakdown:
├── Ecommerce features:          ~0 MB    (0%)
├── Shipping/Affiliates:         ~2-4 MB  (30-40%)
├── Auth/Profile/Core:           ~2-3 MB  (30-40%)
└── UI/Shared/Utils:             ~1-2 MB  (20-30%)

SAVINGS:
Size reduction:                  ~50-60% smaller
Code reduction:                  ~60-70% less code
App performance:                 Significantly faster
Build time:                       30-40% faster
Installation size:               Much lighter
```

---

## 🎨 RECOMMENDED LANDING PAGE DESIGN

### Current State
```
[Splash Screen]
        ↓
[Ecommerce Home - Shows Products, Categories, Promotions]
   [Product Grid with Carousel]
   [Category Pills]
   [Promotions Banner]
   [Bottom nav with Shop, Cart, Wishlist, Orders]
```

### New Shipping-Focused Landing Page
```
┌─────────────────────────────────┐
│       SHOPSNPORTS LOGO          │  (Top)
│     Shipping & Freight          │
└─────────────────────────────────┘
                
[BIG RED BUTTON]
"REQUEST SHIPPING NOW"            (Primary CTA)

[Quick Stats Row]
[✓ Fast Shipping] [✓ Reliable] [✓ Affordable]

[THREE MAIN SECTIONS - Cards]
╔════════════════════════════════╗
║  🚚 REQUEST SHIPPING            ║
║  • Individual shipments         ║
║  • Quick quotes                 ║
║  • Real-time tracking           ║
║  [Get Started →]                ║
╚════════════════════════════════╝

╔════════════════════════════════╗
║  👥 BECOME AN AFFILIATE          ║
║  • Earn commission              ║
║  • Easy signup                  ║
║  • Passive income               ║
║  [Join Program →]               ║
╚════════════════════════════════╝

╔════════════════════════════════╗
║  🔜 COMING SOON                 ║
║  For Shippers                   ║
║  • Schedule pickups             ║
║  • Manage fleet                 ║
║  [Notify Me →]                  ║
╚════════════════════════════════╝

[Feature Section]
"Why Choose Us?"
- 24/7 Support
- Real-time tracking
- Transparent pricing
- Reliable network

[FAQ Section]
- How it works?
- What's a shipping request?
- Can I ship as guest?
- How are prices calculated?

[Footer Navigation]
Home | Requests | Affiliates | Profile | Settings | Help
```

---

## 📋 DETAILED DELETION CHECKLIST

### Phase 1: Products & Categories (WEEK 1)
- [ ] Delete `lib/features/products/` folder entirely
- [ ] Delete `lib/features/categories/` folder entirely
- [ ] Delete `lib/features/product_detail/` folder entirely
- [ ] Delete `lib/models/product.dart` model
- [ ] Delete `lib/models/category.dart` model
- [ ] Delete `lib/services/product_service.dart`
- [ ] Delete `lib/repositories/product_repository.dart`
- [ ] Delete `lib/providers/product_provider.dart`
- [ ] Remove product-related assets from `assets/`
- [ ] Clean imports from `main.dart`
- [ ] Remove product routes from router

**Files affected**: 40-60  
**Size**: ~2-4 MB  
**Duration**: 2-3 hours

### Phase 2: Cart (WEEK 1)
- [ ] Delete `lib/features/cart/` folder entirely
- [ ] Delete `lib/models/cart_item.dart`
- [ ] Delete `lib/services/cart_service.dart`
- [ ] Delete `lib/providers/cart_provider.dart`
- [ ] Remove cart icons from assets
- [ ] Clean cart imports from all files
- [ ] Remove cart routes

**Files affected**: 15-25  
**Size**: ~1-2 MB  
**Duration**: 1-2 hours

### Phase 3: Checkout & Payments (WEEK 1)
- [ ] Delete `lib/features/checkout/` folder
- [ ] Delete `lib/features/payments/` folder
- [ ] Delete `lib/models/order.dart` (shopping orders)
- [ ] Delete `lib/services/payment_service.dart`
- [ ] Delete `lib/services/stripe_service.dart` (if exists)
- [ ] Remove payment provider integrations
- [ ] Delete checkout-related providers
- [ ] Remove payment icons/assets
- [ ] Clean imports

**Files affected**: 30-50  
**Size**: ~2-3 MB  
**Duration**: 2-3 hours

### Phase 4: Orders & Wishlist (WEEK 1)
- [ ] Delete `lib/features/orders/` folder (shopping orders only)
- [ ] Delete `lib/features/wishlist/` folder
- [ ] Delete `lib/models/wishlist_item.dart`
- [ ] Delete order history screens (keep shipping request tracking)
- [ ] Remove wishlist provider
- [ ] Clean imports

**Files affected**: 30-45  
**Size**: ~1.5-2.5 MB  
**Duration**: 1-2 hours

### Phase 5: Account Cleanup (WEEK 2)
- [ ] Refactor `lib/features/account/` - remove shopping-specific
- [ ] Delete user order history screens
- [ ] Keep: user profile, addresses (for shipping), preferences
- [ ] Remove wishlist from account
- [ ] Remove saved payment methods
- [ ] Clean providers

**Files affected**: 15-20  
**Size**: ~0.5-1 MB  
**Duration**: 1 hour

### Phase 6: Home/Landing Redesign (WEEK 2)
- [ ] Redesign `lib/features/home/home_screen.dart`
- [ ] Delete product carousel widgets
- [ ] Delete category pills
- [ ] Delete promotional banners (except "Coming Soon")
- [ ] Add shipping request CTA
- [ ] Add affiliates signup CTA
- [ ] Create new landing layout
- [ ] Update assets (remove product images)

**Files affected**: 10-15  
**Size**: ~0.5-1 MB  
**Duration**: 4-6 hours (design + implementation)

### Phase 7: Navigation & Routes (WEEK 2)
- [ ] Update `main.dart` routes - remove deleted features
- [ ] Update bottom navigation menu
- [ ] Update drawer/sidebar navigation
- [ ] Remove shopping-related menu items
- [ ] Test all navigation paths
- [ ] Update route names

**Files affected**: 5-8  
**Size**: ~0.1 MB  
**Duration**: 1-2 hours

### Phase 8: Dependencies & Cleanup (WEEK 2)
- [ ] Review `pubspec.yaml` - remove unused packages
- [ ] Delete unused payment libraries (Stripe SDK, PayPal SDK, etc.)
- [ ] Delete unused image processing libraries
- [ ] Delete unused state management (if only for shopping)
- [ ] Run `flutter pub get`
- [ ] Clean build cache: `flutter clean`
- [ ] Verify imports in all remaining files
- [ ] Fix any broken references

**Files affected**: 1-2  
**Size**: ~2-5 MB (dependencies)  
**Duration**: 1-2 hours

### Phase 9: Assets Cleanup (WEEK 3)
- [ ] Delete product images
- [ ] Delete category icons
- [ ] Delete shopping-related graphics
- [ ] Keep: splash screens, app logo, shipping icons
- [ ] Optimize remaining images (compress)
- [ ] Delete unused fonts (if any)

**Files affected**: 100-200+ images  
**Size**: ~5-10 MB  
**Duration**: 1-2 hours

### Phase 10: Testing & Polish (WEEK 3)
- [ ] Test app builds successfully
- [ ] Test all remaining features work
- [ ] Test navigation flows
- [ ] Check for broken imports
- [ ] Test shipping request flow
- [ ] Test affiliates section
- [ ] Test auth flow
- [ ] Performance testing
- [ ] Check app performance metrics

**Duration**: 2-3 hours

---

## 📁 FINAL APP STRUCTURE (After Cleanup)

```
lib/
├── main.dart
├── config/
│   ├── routes.dart
│   └── theme.dart
├── features/
│   ├── auth/
│   │   ├── screens/
│   │   ├── models/
│   │   └── providers/
│   ├── splash/
│   │   ├── screens/
│   │   └── widgets/
│   ├── home/
│   │   ├── screens/
│   │   └── widgets/
│   ├── shipping_requests/
│   │   ├── screens/
│   │   ├── models/
│   │   ├── repositories/
│   │   └── providers/
│   ├── shipping_guest/
│   │   ├── screens/
│   │   └── providers/
│   ├── affiliates/
│   │   ├── screens/
│   │   ├── models/
│   │   └── providers/
│   ├── profile/
│   │   ├── screens/
│   │   └── providers/
│   ├── notifications/
│   │   ├── screens/
│   │   └── providers/
│   └── shared/
│       ├── widgets/
│       ├── utils/
│       └── models/
├── models/
├── services/
├── providers/
└── utils/
```

---

## 📊 SUMMARY

| Metric | Before | After | Reduction |
|--------|--------|-------|-----------|
| **App Size** | ~50-80 MB | ~25-35 MB | **-50-60%** |
| **Code Size** | ~15-25 MB | ~5-8 MB | **-60-70%** |
| **Features** | 20+ | 6 | **-70%** |
| **Total Files** | ~400-500 | ~150-200 | **-60-70%** |
| **Build Time** | ~5-8 min | ~2-3 min | **-60%** |
| **Dependencies** | ~50-80 | ~30-40 | **-30-40%** |

---

## ⏱️ TIMELINE

```
Week 1: Delete ecommerce features (Products, Cart, Checkout, Orders, Wishlist)
Week 2: Account cleanup, home redesign, navigation update, dependencies cleanup  
Week 3: Assets cleanup, testing, polish, performance optimization

Total time: 2-3 weeks of focused development
```

---

## ✅ SUCCESS CRITERIA

After cleanup:
- ✅ App size reduced by 50-60%
- ✅ Build time reduced by 30-40%
- ✅ All ecommerce features completely removed
- ✅ Shipping features fully functional
- ✅ Affiliates fully functional
- ✅ Guest shipping requests working
- ✅ New landing page deployed
- ✅ Zero broken imports/references
- ✅ All navigation working
- ✅ App launches without errors

---

**Next Step**: Confirm audit is accurate by checking actual folder structure, then proceed with Phase 1 deletions!

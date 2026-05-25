# ShopsNPorts Ecommerce Removal Checklist

**Status:** Complete inventory of ecommerce elements to delete  
**Scope:** Complete transition from ecommerce + shipping → cargo/freight-only  
**Total Items:** 80+ ecommerce elements across 12 categories  
**Estimated Effort:** 6-8 hours of focused deletion and cleanup

---

## 1. FLUTTER APP STATE & PROVIDERS ⚡

### File: `lib/providers/app_state_provider.dart`
Status: **EXISTS - PARTIALLY ECOMMERCE**

**Items to REMOVE:**
- [ ] Remove `WishlistStatus` enum (lines ~XX)
  - `empty`
  - `sale`
  - `lowStock`
- [ ] Remove `wishlistCount` field and related getter
- [ ] Remove `wishlist` map field (productId → inWishlist boolean)
- [ ] Remove `markWishlistLowStock()` method
- [ ] Remove `toggleWishlist(String productId)` method
- [ ] Remove `addToWishlist(String productId)` method
- [ ] Remove `clearWishlist()` method
- [ ] Remove all wishlist-related copyWith() parameters
- [ ] Review: Keep or remove currency conversion? (fxRate, baseCurrency, displayCurrency methods)
  - ⚠️ **DECISION NEEDED:** Are these still needed for shipping cost pricing?

---

### File: `lib/state/app_state.dart`
Status: **EXISTS - LEGACY ECOMMERCE STATE**

**Items to REMOVE:**
- [ ] Remove `cartCount` field
- [ ] Remove `addToCart(dynamic product)` method
- [ ] Remove `removeFromCart(String productId)` method
- [ ] Remove `cartQty(String productId)` method
- [ ] Remove `toggleWishlist(String productId)` method
- [ ] Remove `isWishlisted(String productId)` method
- [ ] Remove `ratings` map field (productId → double)
- [ ] Remove `getRating(String productId)` method
- [ ] Remove `setRating(String productId, double rating)` method
- [ ] Remove currency conversion (fxRate, baseCurrency, displayCurrency)
  - ⚠️ **DECISION NEEDED:** Keep for shipping pricing?

---

## 2. FLUTTER SCREENS 📱

### Screens Already Deleted (Verified via app_router.dart comments)
- ✅ `lib/screens/vendor/vendor_profile_screen.dart`
- ✅ `lib/screens/vendor_dashboard_screen.dart`
- ✅ `lib/screens/vendor/vendor_products_screen.dart`
- ✅ `lib/screens/vendor/product_management_screen.dart`
- ✅ `lib/screens/product_details_screen.dart`
- ✅ `lib/screens/customer/my_reviews_screen.dart`
- ✅ `lib/screens/customer/write_review_screen.dart`
- ✅ `lib/screens/cart_screen.dart`
- ✅ `lib/screens/cart/checkout_screen.dart`
- ✅ `lib/screens/cart/payment_methods_screen.dart`
- ✅ `lib/screens/orders/order_details_screen.dart`
- ✅ `lib/screens/track_order_screen.dart`
- ✅ `lib/screens/product/product_list_screen.dart`
- ✅ `lib/screens/category_products_screen.dart`

### Screens Still Present - AMBIGUOUS (Requires Review & User Decision)

**File: `lib/screens/customer/customer_home_screen.dart`**
- [ ] Review for ecommerce content (product carousel, recommendations, etc.)
- [ ] Keep if it's now shipping-focused (home for cargo shipments)
- [ ] **Decision:** Keep or refactor?

**File: `lib/screens/customer/invoices_screen.dart`**
- [ ] Determine if "invoices" = shipping manifests (KEEP) or ecommerce order receipts (DELETE)
- [ ] **Decision:** Keep as shipping manifest view, or delete?

**File: `lib/screens/customer/invoice_detail_screen.dart`**
- [ ] Paired with invoices_screen - determine purpose
- [ ] **Decision:** Keep or delete?

**File: `lib/screens/payment/payment_billing_screen.dart`**
- [ ] Determine if still needed for shipping cost payment
- [ ] ⚠️ Could be ecommerce checkout-only
- [ ] **Decision:** Keep for shipping payments, or delete as ecommerce-only?

---

### Screens Likely Deleted (Verify)
- [ ] Confirm deletion: `lib/screens/empty_cart_screen.dart`
- [ ] Confirm deletion: `lib/screens/empty_wishlist_screen.dart`
- [ ] Confirm deletion: `lib/screens/wishlist_screen.dart`
- [ ] Confirm deletion: `lib/screens/recommended_screen.dart`
- [ ] Any other `lib/screens/product/*` files

---

## 3. FLUTTER WIDGETS 🎨

### Widgets Already Disabled (Ready for Final Deletion)
- [ ] Delete `lib/widgets/featured_carousel.dart.disabled` (featured products)
- [ ] Delete `lib/widgets/filter_sheet.dart.disabled` (product filters)
- [ ] Delete `lib/widgets/item_slider.dart.disabled` (product slider)

### Widget: `lib/widgets/add_product_dialog.dart`
- [ ] **DECISION NEEDED:** Is this for admin managing shipments or ecommerce products?
  - If for shipping items → **KEEP** and rename to clarify purpose
  - If for products → **DELETE**

### Widgets Likely Already Deleted (Verify Absence)
- [ ] Confirm deletion: `add_to_cart_button.dart`
- [ ] Confirm deletion: `quantity_cart_button.dart`
- [ ] Confirm deletion: `product_card.dart`
- [ ] Confirm deletion: `product_grid.dart`
- [ ] Confirm deletion: `cart_item_tile.dart`
- [ ] Confirm deletion: `wishlist_icon_button.dart`

---

## 4. FLUTTER MODELS & DATA CLASSES 📊

### Models Likely Already Deleted (Verify)
- [ ] Confirm deletion: `lib/models/product.dart`
- [ ] Confirm deletion: `lib/models/review.dart`
- [ ] Confirm deletion: `lib/models/cart.dart`
- [ ] Confirm deletion: `lib/models/wishlist.dart`
- [ ] Confirm deletion: `lib/models/order.dart` (ecommerce variant - NOT shipping_request.dart)
- [ ] Confirm deletion: `lib/models/vendor.dart`

### Models to Keep (Verified Present & Cargo-Related)
✅ `lib/models/user.dart`
✅ `lib/models/address.dart`
✅ `lib/models/affiliate.dart`
✅ `lib/models/app_banner.dart`
✅ `lib/models/app_config.dart`
✅ `lib/models/content_page.dart`
✅ `lib/models/enums.dart`
✅ `lib/models/invoice.dart` (if shipping manifest)
✅ `lib/models/news_ticker.dart`
✅ `lib/models/payout_record.dart`
✅ `lib/models/shipping_request.dart`
✅ `lib/models/user_role.dart`

---

## 5. FLUTTER SERVICES 🔌

### Services Likely Already Deleted (Verify)
- [ ] Confirm deletion: `lib/services/products_api_service.dart`
- [ ] Confirm deletion: `lib/services/categories_api_service.dart`
- [ ] Confirm deletion: `lib/services/orders_api_service.dart` (ecommerce variant)
- [ ] Confirm deletion: `lib/services/vendor_api_service.dart`
- [ ] Confirm deletion: `lib/services/reviews_api_service.dart`
- [ ] Confirm deletion: `lib/services/cart_api_service.dart`

### Services to Keep (Cargo-Related)
✅ `lib/services/shipping_api_service.dart`
✅ `lib/services/affiliate_api_service.dart`
✅ `lib/services/auth_service.dart`
✅ `lib/services/notification_service.dart`
✅ `lib/services/analytics_service.dart`

---

## 6. FLUTTER REPOSITORIES 📚

### Repositories Likely Already Deleted (Verify)
- [ ] Confirm deletion: `lib/repositories/product_repository.dart`
- [ ] Confirm deletion: `lib/repositories/cart_repository.dart`
- [ ] Confirm deletion: `lib/repositories/order_repository.dart` (ecommerce variant)
- [ ] Confirm deletion: `lib/repositories/review_repository.dart`

### Repositories to Keep (Verified Present & Cargo-Related)
✅ `lib/repositories/addresses_repository.dart`
✅ `lib/repositories/affiliate_shipment_repository.dart`
✅ `lib/repositories/user_repository.dart`
✅ `lib/repositories/firebase_user_repository.dart`
✅ `lib/repositories/mock_addresses_repository.dart`
✅ `lib/repositories/mock_user_repository.dart`

---

## 7. FLUTTER UTILITIES & CONSTANTS ⚙️

### File: `lib/utils/user_messages.dart`
Status: **EXISTS - CONTAINS ECOMMERCE MESSAGE CONSTANTS**

**Items to REMOVE (~30 lines):**
- [ ] Remove `addedToCart()` method - "Item added to your cart"
- [ ] Remove `removedFromCart()` method
- [ ] Remove `cartEmpty()` method - "Your cart is empty"
- [ ] Remove `addedToWishlist()` method - "Added to wishlist"
- [ ] Remove `removedFromWishlist()` method - "Removed from wishlist"
- [ ] Remove all payment/checkout error messages (if ecommerce transaction-specific)
  - [ ] `paymentProcessingError()`
  - [ ] `checkoutError()`
  - [ ] `invalidPaymentMethod()`
- [ ] Remove ecommerce-specific order messages:
  - [ ] `orderPlaced()` (if ecommerce-only, NOT shipping)
  - [ ] `orderFailed()`
  - [ ] `orderCancelled()`
- [ ] Review: Keep shipping-related messages (shipmentCreated, delivered, etc.)

### Other Utilities
- [ ] Review `lib/utils/constants.dart` for ecommerce constants
- [ ] Review any other utils files for cart/product/review constants

---

## 8. ROUTER & NAVIGATION 🗺️

### File: `lib/core/routing/app_router.dart`
Status: **PARTIALLY CLEAN - HAS COMMENTS OF DELETED ROUTES**

**Items to REMOVE:**
- [ ] Clean up commented-out imports (10+ ecommerce screen imports currently commented)
- [ ] Remove any remaining route definitions for:
  - [ ] `/product/:id` (product details)
  - [ ] `/products` (product listing)
  - [ ] `/search` (product search)
  - [ ] `/cart` (shopping cart)
  - [ ] `/checkout` (checkout flow)
  - [ ] `/payment-methods` (payment selection)
  - [ ] `/orders` (ecommerce orders)
  - [ ] `/orders/:id` (order details)
  - [ ] `/wishlist`
  - [ ] `/reviews` or `/write-review`

---

## 9. BACKEND - DATABASE SCHEMA 🗄️

### File: `server/init-database.js`

**Tables to REMOVE from DROP and CREATE statements:**

- [ ] **vendors** table
  - Ecommerce seller/merchant accounts
  - Drop from dropTables
  - Remove TABLE CREATE block (~15 lines)
  - Remove FK references in other tables
  
- [ ] **categories** table
  - Product categories
  - Drop from dropTables
  - Remove TABLE CREATE block (~12 lines)
  - Remove FK references
  
- [ ] **products** table
  - Product catalog
  - Drop from dropTables  
  - Remove TABLE CREATE block (~20 lines)
  - Remove indexes (idx_products_vendor, idx_products_category)
  - Remove FK references in cart_items, order_items
  
- [ ] **carts** table
  - Shopping carts
  - Drop from dropTables
  - Remove TABLE CREATE block (~8 lines)
  
- [ ] **cart_items** table
  - Shopping cart line items
  - Drop from dropTables
  - Remove TABLE CREATE block (~12 lines)
  
- [ ] **order_items** table
  - Individual products in ecommerce orders
  - Drop from dropTables
  - Remove TABLE CREATE block (~15 lines)
  - ⚠️ **DECISION:** If orders are being repurposed for shipping, determine if order_items should be kept/refactored

### Ambiguous Database Decisions

**Table: `orders`**
- ⚠️ **DECIDE:** Is this being repurposed for shipping requests, or completely removed?
  - If kept: Refactor schema (remove ecommerce-specific fields like payment_method, payment_reference, shipping_address)
  - If removed: Drop from schema AND update shipping_requests table structure
  - **Current fields to evaluate:**
    - `total_amount` - REMOVE if ecommerce-only
    - `payment_status` - REMOVE if ecommerce-only
    - `payment_method` - REMOVE if ecommerce-only
    - `payment_reference` - REMOVE if ecommerce-only
    - `shipping_address` - May be needed for shipping

**Table: `shipments`**
- ⚠️ Review if currently linked to ecommerce orders (has FK to orders table)
  - If migrating to shipping_requests: Update structure
  - Verify all shipment tracking functionality is preserved

---

## 10. BACKEND - API ROUTES & HANDLERS 🛣️

### File: `server/admin.js`

**Ecommerce Endpoints to REMOVE (~18 routes):**

- [ ] **Product Management:**
  - [ ] `GET /admin/products` (line ~1055) - List all products
  - [ ] `POST /admin/products` (line ~1080) - Create product
  - [ ] `PUT /admin/products/:id` (line ~1085) - Update product
  - [ ] `DELETE /admin/products/:id` (line ~1090) - Delete product
  - [ ] `POST /admin/products/:id/categories/:cid` (line ~1096) - Link product to category
  - [ ] `DELETE /admin/products/:id/categories/:cid` (line ~1101) - Unlink product from category

- [ ] **Product Approvals:**
  - [ ] `GET /admin/products/approvals` (line ~507) - Product approval queue
  - [ ] `POST /admin/products/:id/approve` (line ~523) - Approve product
  - [ ] `POST /admin/products/:id/reject` (line ~536) - Reject product

- [ ] **Category Management:**
  - [ ] `GET /admin/categories` (line ~1025) - List categories
  - [ ] `POST /admin/categories` (line ~1039) - Create category
  - [ ] `PUT /admin/categories/:id` (line ~1044) - Update category
  - [ ] `DELETE /admin/categories/:id` (line ~1049) - Delete category

- [ ] **Vendor Management:**
  - [ ] `GET /admin/vendors` (line ~550) - List vendors
  - [ ] `POST /admin/vendors/:id/approve` (line ~566) - Approve vendor
  - [ ] ~~`GET /admin/vendors/:id`~~ - (may be removed)

- [ ] **Other Ecommerce:**
  - [ ] `GET /admin/orders` (line ~466) - Ecommerce orders list
  - [ ] `GET /admin/orders/:id/track` (line ~487) - Order tracking
  - [ ] `POST /admin/orders/:id/status` (line ~620) - Update order status (ecommerce)

---

### Check Other Backend Files for Ecommerce Routes

**Files to audit for ecommerce API endpoints:**
- [ ] `server/index.js` - Main app file (check for /api/v1/products, /api/v1/cart, /api/v1/orders routes)
- [ ] Look for separate route files:
  - [ ] `server/products-routes.js` or similar
  - [ ] `server/cart-routes.js` or similar
  - [ ] `server/orders-routes.js` (ecommerce variant) or similar
  - [ ] `server/reviews-routes.js` or similar
  - [ ] `server/vendors-routes.js` or similar

---

## 11. FIREBASE/FIRESTORE COLLECTIONS 🔥

### Collections to DELETE

- [ ] **products/** collection
  - Contains all product documents
  - Delete entire collection via Firebase Console or script
  - ~Estimated: 100-500 documents (if seeded)

- [ ] **categories/** collection
  - Product category documents
  - Delete entire collection
  - ~Estimated: 10-50 documents

- [ ] **reviews/** collection
  - Product review documents
  - Delete entire collection
  - ~Estimated: 0-100 documents

- [ ] **carts/** collection
  - User shopping cart documents
  - May also be: **cart_{userId}/** sub-collections
  - Delete entire collection and all user sub-collections
  - ~Estimated: 0-100 documents

- [ ] **wishlist/** collection
  - User favorites
  - May also be: **wishlist_{userId}/** sub-collections
  - Delete entire collection
  - ~Estimated: 0-100 documents

- [ ] **vendors/** collection
  - Ecommerce seller profiles
  - Delete entire collection
  - ~Estimated: 0-50 documents

### Collections to KEEP & VERIFY CARGO-FOCUSED
✅ **users/** - User profiles (keep)
✅ **orders/** - ⚠️ Verify this is shipping orders, not ecommerce (keep but review structure)
✅ **notifications/** - Keep
✅ **announcements/** - Keep
✅ **banners/** - Keep
✅ **news_items/** - Keep
✅ **shipping_requests/** - Keep (core feature)
✅ **shipping_tokens/** - Keep (authorization)
✅ **help_articles/** - Keep
✅ **feature_flags/** - Keep

---

## 12. DOCUMENTATION FILES 📄

### Files to DELETE Entirely

- [ ] `docs/cart_operations_guide.md` (~205 lines)
  - Complete cart and checkout instructions
  - No longer relevant for freight app

### Files to UPDATE (Remove ecommerce sections)

- [ ] `docs/navigation_audit.md`
  - Remove route definitions for: `/cart`, `/product/:id`, `/search`, `/orders`, `/checkout`, `/payment-methods`
  
- [ ] `SHOPSNPORTS_SHIPPING_DOMAIN_AUDIT_2026.md`
  - Already has explicit deletion list - review and execute any missing deletions
  
- [ ] `COMPLETE_SYSTEM_HANDOFF.md`
  - Remove product/cart service architecture descriptions
  - Remove ecommerce workflow diagrams
  
- [ ] `RECENT_CHANGES_SUMMARY.md`
  - Remove cart/checkout flow documentation
  - Remove product feature updates
  
- [ ] `MOBILE_APP_BACKEND_ROUTES.md`
  - Remove product route documentation (~40+ lines)
  - Remove cart route documentation
  - Remove ecommerce order endpoints
  - Remove vendor endpoints
  
- [ ] `MOBILE_APP_DEPLOYMENT_HANDOFF.md`
  - Remove product/cart API examples in code walkthrough
  - Remove ecommerce-specific testing instructions
  
- [ ] `SHOPSNPORTS_MOBILE_PRODUCTION_ROADMAP_2026.md`
  - Remove cart/payment testing tasks
  - Remove "product polish" tasks
  - Remove vendor dashboard tasks

---

## 13. PROJECT CONFIG FILES ⚙️

### File: `pubspec.yaml`
- [ ] Audit dependencies - Remove any ecommerce-specific packages:
  - [ ] Shopping cart packages (if using any)
  - [ ] Product image gallery packages (if ecommerce-specific)
  - [ ] Payment packages for checkout flow (if ecommerce-only)
  - ⚠️ Keep: Stripe, Paystack, Flutterwave (may be needed for shipping cost payment)

### File: `firebase.json`
- [ ] Review Firestore security rules for ecommerce collections
  - [ ] Remove rules for `products/`, `categories/`, `reviews/`, `carts/`, `wishlist/`, `vendors/`
  - [ ] Ensure rules only allow access to cargo-related collections

### File: `firestore.rules`
- [ ] Remove or disable read/write rules for ecommerce collections
- [ ] Example lines to remove:
  ```
  match /products/{document=**} { allow read, write: if true; }
  match /categories/{document=**} { allow read, write: if true; }
  match /carts/{userId}/{document=**} { allow read, write: if request.auth.uid == userId; }
  match /wishlist/{userId}/{document=**} { allow read, write: if request.auth.uid == userId; }
  match /reviews/{document=**} { allow read, write: if true; }
  match /vendors/{document=**} { allow read, write: if true; }
  ```

---

## 14. BUILD & CONFIGURATION FILES 🔨

### Android Configuration
- [ ] Check `android/build.gradle.kts` for ecommerce-specific dependencies
- [ ] Check `android/app/build.gradle.kts` for ecommerce product flavors

### iOS Configuration
- [ ] Check `ios/Podfile` for ecommerce-specific pods

### Web/Other Platforms
- [ ] Check `web/index.html` for ecommerce-specific scripts/meta tags
- [ ] Check platform-specific build configs

---

## 15. TEST FILES 🧪

### Files to DELETE
- [ ] Any unit tests for cart functionality
- [ ] Any widget tests for product screens
- [ ] Any integration tests for checkout flow
- [ ] Search tests: `test/unit/**/search*` files
- [ ] Product tests: `test/unit/**/product*` files
- [ ] Order tests (ecommerce): `test/unit/**/order*` files (if ecommerce-only)
- [ ] Wishlist tests: `test/unit/**/wishlist*` files
- [ ] Cart tests: `test/unit/**/cart*` files

### Test Files to KEEP
✅ Shipping tests
✅ Affiliate tests
✅ Authentication tests
✅ User management tests

---

## 16. SUMMARY & PRIORITIES 🎯

### CRITICAL - Do First
1. **Delete disabled widget files** (3 files, .disabled)
   - Remove: featured_carousel, filter_sheet, item_slider
   
2. **Clean app_state_provider.dart & app_state.dart** (embedded ecommerce logic)
   - Remove 20+ lines of wishlist, cart, and rating logic
   - Verify currency conversion isn't needed for shipping
   
3. **Update init-database.js** (6 ecommerce tables)
   - Remove products, categories, carts, cart_items, vendors, order_items
   - Refactor or remove orders table
   - Remove all related INDEXes and FKs

### HIGH - Do Second
4. **Remove admin.js ecommerce routes** (18+ endpoints)
5. **Delete Firestore collections** (6 collections with potential hundreds of docs)
6. **Clean up user_messages.dart** (~30 lines)
7. **Update 7 documentation files** (remove ecommerce references)

### MEDIUM - Do Third
8. **Review ambiguous items** (4 items requiring user decision)
9. **Verify all deleted files are actually gone**
10. **Check all route files for ecommerce endpoints**

### LOW - Polish
11. **Update pubspec.yaml** (remove unnecessary dependencies)
12. **Update Firestore rules** (remove ecommerce collection permissions)
13. **Update test suite** (remove ecommerce-related tests)

---

## AMBIGUOUS ITEMS - USER DECISION NEEDED ⚠️

**Before starting major deletions, clarify these 4 items:**

1. **ORDERS TABLE & CONCEPT**
   - Currently in schema but unclear if for ecommerce or shipping
   - **Question:** Are shipping requests the new "orders"? Delete orders or refactor?
   - **Impact:** Affects database schema, API routes, and data models

2. **INVOICES_SCREEN.DART**
   - Cannot determine if invoices = shipping manifests or ecommerce receipts
   - **Question:** Keep as shipping manifest view or delete?
   - **Impact:** Small refactor if keeping

3. **PAYMENT_BILLING_SCREEN.DART**
   - Cannot determine if for shipping cost calculation or ecommerce checkout
   - **Question:** Keep for shipping cost payment, or remove as ecommerce-only?
   - **Impact:** May affect shipping cost quote workflow

4. **ADD_PRODUCT_DIALOG.DART**
   - Cannot determine if for admin managing shipment details or ecommerce products
   - **Question:** Is this for shipping items or products? Keep or delete?
   - **Impact:** Clarifies whether to delete or repurpose widget

---

## EXECUTION NOTES

### Recommended Deletion Sequence
1. Delete 3 disabled widgets (.disabled files) - No dependencies
2. Remove embedded ecommerce logic from state providers
3. Update database schema (init-database.js)
4. Remove backend API routes
5. Delete Firestore collections
6. Clean up documentation
7. Update configurations & tests

### Verification Steps After Each Phase
- [ ] Run `flutter analyze` - should have no import errors
- [ ] Run `flutter test test/unit/ --reporter=expanded` - all tests should pass
- [ ] Check backend: `npm test` or manual API tests
- [ ] Firebase Console: Verify collections deleted

### Backup Recommendation
- [ ] **Before starting:** Create git branch `feat/remove-ecommerce`
- [ ] **Make commits at each phase** for easy rollback
- [ ] **Keep this checklist updated** as you progress

---

## VALIDATION CHECKLIST

### Final Verification - Before Production Deploy
- [ ] No imports of deleted files remain in codebase
- [ ] No routes reference ecommerce endpoints
- [ ] Flutter app compiles without errors or warnings
- [ ] All cargo-related tests pass (shipping, affiliate, user)
- [ ] Backend server starts without errors
- [ ] Database initializes without orphaned FK errors
- [ ] Firestore rules don't reference deleted collections
- [ ] App navigates without broken route references
- [ ] No ecommerce-related errors in Firebase Console Crashlytics
- [ ] Documentation files updated and consistent


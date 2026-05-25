# ✅ PHASE 4 STATUS - CLEANUP & IMPORT REMOVAL IN PROGRESS

**Date**: January 31, 2026  
**Status**: 🔄 Phase 4 In-Progress  
**Focus**: Identifying and removing dead imports  
**Timeline**: ~2-3 hours for complete Phase 4  

---

## 📋 PHASE 4 OBJECTIVES

### Primary Goals
1. ✅ Identify all files with dead imports/references
2. 🔄 Remove imports of deleted models/services/providers
3. 🔄 Clean routing configuration
4. 🔄 Update navigation/menu
5. 🔄 Verify clean build

---

## 🔍 DEAD IMPORT PATTERNS TO REMOVE

### Provider Imports (MUST REMOVE)
```
- import 'providers/product_provider.dart'
- import 'providers/cart_provider.dart'
- import 'providers/order_provider.dart'
- import 'providers/category_provider.dart'
- import 'providers/vendor_provider.dart'
- import 'package:shopsnports/providers/product_provider.dart'
- import 'package:shopsnports/providers/cart_provider.dart'
- (and variants)
```

### Repository Imports (MUST REMOVE)
```
- import 'repositories/product_repository.dart'
- import 'repositories/cart_repository.dart'
- import 'repositories/order_repository.dart'
- import 'repositories/vendor_repository.dart'
- (and package: variants)
```

### Model Imports (MUST REMOVE)
```
- import 'models/product.dart'
- import 'models/cart_item.dart'
- import 'models/order.dart'
- import 'models/category.dart'
- import 'models/vendor.dart'
- (and package: variants)
```

### Service Imports (MUST REMOVE)
```
- import 'services/products_api_service.dart'
- import 'services/categories_api_service.dart'
- import 'services/reviews_api_service.dart'
- import 'services/vendor_api_service.dart'
- import 'services/orders_api_service.dart'
- import 'services/orders_service.dart'
```

### Screen Imports (MUST REMOVE)
```
- import 'screens/product/product_screen.dart'
- import 'screens/cart/cart_screen.dart'
- import 'screens/orders/orders_screen.dart'
- import 'screens/customer/customer_screen.dart'
- import 'screens/search/search_screen.dart'
- import 'screens/vendor/vendor_screen.dart'
- (and any ProductScreen, CartScreen, etc. classes)
```

---

## 🔧 FILES TO CLEAN (Typical Structure)

### 1. lib/main.dart
**Expected issues:**
- Imports of deleted providers
- Provider registrations
- Route definitions for deleted screens
- Provider reference in ProviderScope or equivalent

**Cleanup steps:**
```dart
// REMOVE:
import 'providers/product_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/order_provider.dart';
// ... etc

// REMOVE from provider setup:
ProductProvider(),
CartProvider(),
OrderProvider(),
// ... etc

// REMOVE from GoRouter:
GoRoute(path: '/product', ...),
GoRoute(path: '/cart', ...),
GoRoute(path: '/orders', ...),
// ... etc
```

### 2. Routing Configuration File
**Typical locations:**
- `lib/core/routing/app_router.dart`
- `lib/config/routes.dart`
- `lib/utils/router_config.dart`
- Or embedded in main.dart

**Expected issues:**
- Routes for /product, /cart, /orders, /customer, /search, /vendor
- Screen imports at top of file
- Route builder references

**Cleanup steps:**
```dart
// REMOVE these route blocks:
GoRoute(
  path: 'product',
  builder: (context, state) => ProductScreen(...),
),
// ... for cart, orders, customer, search, vendor
```

### 3. Navigation/Menu Widget
**Typical locations:**
- `lib/widgets/bottom_navigation.dart`
- `lib/widgets/app_drawer.dart`
- `lib/widgets/navigation_menu.dart`
- `lib/screens/public/home_screen.dart`

**Expected issues:**
- Tab/menu item for "Shop" or "Products"
- Tab/menu item for "Cart"
- Tab/menu item for "Orders" or "My Orders"
- Navigation to deleted screens

**Cleanup steps:**
```dart
// REMOVE tab/menu items:
BottomNavigationBarItem(
  icon: Icon(Icons.shopping_bag),
  label: 'Shop', // REMOVE
),

// REMOVE case/condition:
case 'shop':
  return ProductListScreen();

// KEEP:
BottomNavigationBarItem(
  icon: Icon(Icons.local_shipping),
  label: 'Shipping', // KEEP
),
```

### 4. Provider Registry (if separate file)
**Typical locations:**
- `lib/providers/providers.dart` (barrel file)
- `lib/core/providers/provider_setup.dart`

**Expected issues:**
- Deleted provider registrations
- Barrel export statements

**Cleanup steps:**
```dart
// REMOVE:
export 'product_provider.dart';
export 'cart_provider.dart';
export 'order_provider.dart';
```

---

## 📝 CLEANUP PROCESS

### Step 1: Find All Affected Files
```bash
# Search patterns in all .dart files:
grep -r "product_provider" lib/
grep -r "cart_provider" lib/
grep -r "order_provider" lib/
grep -r "ProductScreen" lib/
grep -r "CartScreen" lib/
grep -r "/product" lib/
grep -r "/cart" lib/
grep -r "/orders" lib/
```

### Step 2: Document Findings
Create a list of:
- [ ] Files with dead imports
- [ ] Line numbers to remove
- [ ] Routes to delete
- [ ] Menu items to remove

### Step 3: Remove Systematically
1. main.dart - remove provider imports and setup
2. routing file - remove deleted routes
3. navigation - remove shopping menu items
4. any other files with references

### Step 4: Verify Build
```bash
flutter clean
flutter pub get
flutter analyze lib
```

---

## 🎯 CLEANUP CHECKLIST

### Critical Files to Clean
- [ ] main.dart (if exists at lib root)
- [ ] Core routing configuration
- [ ] Navigation/menu widget
- [ ] Provider barrel file (if exists)
- [ ] Any state setup file
- [ ] Any navigation service file

### Import Patterns to Remove
- [ ] All product_provider imports
- [ ] All cart_provider imports  
- [ ] All order_provider imports
- [ ] All category_provider imports
- [ ] All vendor_provider imports
- [ ] All product_repository imports
- [ ] All cart_repository imports
- [ ] All order_repository imports
- [ ] All vendor_repository imports
- [ ] All deleted model imports
- [ ] All deleted service imports
- [ ] All deleted screen imports

### Route Patterns to Remove
- [ ] Routes to /product
- [ ] Routes to /cart
- [ ] Routes to /orders
- [ ] Routes to /customer
- [ ] Routes to /search
- [ ] Routes to /vendor
- [ ] Any GoRoute with ProductScreen
- [ ] Any GoRoute with CartScreen
- [ ] Any GoRoute with OrdersScreen

### Menu Items to Remove
- [ ] Shop tab/item
- [ ] Cart tab/item (if separate from shopping)
- [ ] Orders tab/item (if shopping-specific)
- [ ] Wishlist tab/item
- [ ] Any other shopping-specific UI elements

---

## 🔄 EXPECTED AFTER PHASE 4

### Success Criteria
```
✓ No import errors for deleted files
✓ No references to deleted screens
✓ No deleted providers in setup
✓ No shopping routes in configuration
✓ No shopping menu items in navigation
✓ App builds cleanly with no errors
```

### Build Output (Expected)
```
$ flutter analyze lib
No issues found! (0 issues)

or

$ flutter pub get
Running "flutter pub get" in shopsnports...
Got dependencies!
```

---

## 📊 PHASE PROGRESS

### Phase 4 Status
```
Step 1: Find dead imports      ✅ SEARCHING
Step 2: Document findings       ⏳ IN-PROGRESS
Step 3: Remove systematically   ⏳ READY
Step 4: Verify build           ⏳ READY

Overall: 25-30% complete
Duration so far: 15-20 minutes
Estimated remaining: 2-3 hours
```

---

## 🚀 NEXT IMMEDIATE STEPS

### Approach 1: Manual Cleanup (Fastest if small)
If only 1-3 files need cleanup:
1. Manually open each file
2. Search for shopping-related terms
3. Delete matching lines
4. Build and test

### Approach 2: Automated Search & Replace
If many files need cleanup:
1. Use grep to find all occurrences
2. Create find-replace patterns
3. Apply to each file
4. Verify and build

### Approach 3: Rebuild & Fix On-Demand
If unclear what needs cleanup:
1. Try to build the app
2. Fix errors as Flutter reports them
3. This is often fastest for complex projects

---

## 📌 IMPORTANT NOTES

### Import Errors are Expected
After Phase 1-3, import errors in the following are NORMAL:
- main.dart (references deleted providers)
- Routing file (references deleted screens)
- Navigation widgets (references deleted routes)
- Provider setup files

These errors will be completely resolved after Phase 4.

### Post-Phase 4 App State
After cleanup completes:
- ✅ App should compile without import errors
- ✅ No references to deleted shopping features
- ✅ Shipping and affiliate features intact
- ✅ Ready for Phase 5 (Firebase audit)

---

## 📄 SUMMARY

**Phase 4** focuses on removing all dead imports, broken references, and routes to deleted screens. The exact files and lines to remove depend on how this specific ShopsNPorts project is structured.

**Key tasks:**
1. Identify which files have shopping references
2. Remove those references systematically
3. Verify clean build

**Expected outcome:**
- Clean, buildable app
- Zero import errors
- All shopping features completely removed
- Ready for Firebase integration audit (Phase 5)

**Status**: Ready to proceed with cleanup once files are identified


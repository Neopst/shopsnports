# Phase 4 Cleanup Script - Remove Dead Imports and References

## Objective
Clean all dead imports, references, and broken code paths from ShopsNPorts after deleting ecommerce features.

## Files to Search and Clean

### 1. Main Application Files
- [ ] lib/main.dart
  - Remove imports: product_provider, cart_provider, order_provider, category_provider, vendor_provider
  - Remove imports: ProductScreen, CartScreen, OrdersScreen, CustomerScreen, SearchScreen, VendorScreen
  - Remove provider registrations for deleted providers
  - Remove routes to deleted screens

### 2. Routing/Navigation Files
- [ ] lib/core/routing/ (if exists)
  - Remove routes for /product, /cart, /orders, /customer, /search, /vendor
- [ ] lib/services/navigation_service.dart (if exists)
  - Remove navigation to deleted screens

### 3. Bottom Navigation/Menu Files
- [ ] lib/widgets/ - Look for navigation menu widgets
  - Remove shopping menu items (Shop, Cart, Orders, Wishlist)
  - Keep: Home, Shipping, Affiliates, Profile, Settings

### 4. State Management
- [ ] lib/providers/ - All files
  - Remove imports of deleted providers
  - Remove provider references

### 5. Services
- [ ] lib/services/api_service.dart
  - Remove hardcoded API endpoints
  - Remove references to deleted services
  - Keep only Cloud Functions

## Search Patterns to Find Dead Code

```
Search for in ALL .dart files:
  - "product_provider"
  - "cart_provider"
  - "order_provider"
  - "category_provider"
  - "vendor_provider"
  - "ProductScreen"
  - "CartScreen"
  - "OrdersScreen"
  - "CustomerScreen"
  - "SearchScreen"
  - "VendorScreen"
  - "/product"
  - "/cart"
  - "/orders"
  - "/customer"
  - "/search"
  - "/vendor"
```

## Expected Files With Changes

Based on typical Flutter app structure, these files likely need cleanup:

1. **lib/main.dart** - Provider setup, route configuration
2. **Core routing file** - GoRouter or navigation setup
3. **Navigation/menu widgets** - Bottom nav bar, drawer, etc.
4. **Any state setup file** - ProviderContainer or StateNotifier setup

## Manual Steps if Automated Search Doesn't Find Files

1. Open `lib/main.dart`
2. Search for `product` or `cart` - remove any matching lines
3. Look for route definitions - remove shopping routes
4. Look for provider registrations - remove deleted ones
5. Check bottom navigation setup - remove shopping menu items

## Verification After Cleanup

After removing all dead imports:
```bash
cd c:\projects\shopsnports
flutter clean
flutter pub get
flutter analyze lib
```

All errors should be resolved except possibly:
- Unused import warnings (can be cleaned later)
- Unused variable warnings

Expected result: 0 import errors, clean compilation ready


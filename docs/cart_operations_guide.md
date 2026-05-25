# Cart Operations Guide

## Overview
The cart system is fully integrated with Riverpod for state management and supports both guest (SharedPreferences) and authenticated user (Firestore) carts.

## Cart Provider

### Location
- `lib/providers/cart_provider.dart`

### Features
- ✅ Add items to cart
- ✅ Update item quantities
- ✅ Remove items from cart
- ✅ Clear entire cart
- ✅ Calculate subtotal
- ✅ Guest cart persistence (SharedPreferences)
- ✅ User cart persistence (Firestore)
- ✅ Automatic migration from guest to user cart on login
- ✅ Loading states
- ✅ Error handling

## Usage

### 1. Basic Cart Operations

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopsnports/providers/cart_provider.dart';

// In a ConsumerWidget or ConsumerStatefulWidget:

// Add item to cart
final cartNotifier = ref.read(cartProvider.notifier);
cartNotifier.add('product_id', qty: 2);

// Update quantity
cartNotifier.updateQty('product_id', 3);

// Remove item
cartNotifier.remove('product_id');

// Clear cart
cartNotifier.clear();

// Get subtotal
final subtotal = cartNotifier.subtotal();
```

### 2. Watch Cart State

```dart
// Listen to cart changes
final cartState = ref.watch(cartProvider);

// Access cart items
final items = cartState.items;

// Check loading state
if (cartState.isLoading) {
  return CircularProgressIndicator();
}

// Handle errors
if (cartState.error != null) {
  return Text('Error: ${cartState.error}');
}
```

### 3. Using the Add to Cart Widgets

#### Simple Button
```dart
import 'package:shopsnports/widgets/add_to_cart_button.dart';

AddToCartButton(
  productId: product.id,
  productName: product.name,
  inStock: product.stock > 0,
)
```

#### Icon Button Variant
```dart
AddToCartButton(
  productId: product.id,
  productName: product.name,
  inStock: product.stock > 0,
  isIconButton: true,
)
```

#### With Quantity Selector
```dart
QuantityCartButton(
  productId: product.id,
  productName: product.name,
  inStock: product.stock > 0,
  maxQuantity: product.stock,
)
```

### 4. Cart Screen Integration

The `CartScreen` (`lib/screens/cart_screen.dart`) is fully integrated with the cart provider:

- Displays cart items with product details from catalog
- Supports swipe-to-delete with undo
- Bulk selection and removal
- Quantity increment/decrement
- Promo code application (SAVE10 for 10% off)
- Price breakdown (subtotal, tax, delivery fee)
- Empty state with "Start Shopping" CTA
- Loading and error states

## Data Flow

1. **Guest User Flow:**
   ```
   Add to Cart → CartNotifier.add() → Update state → Save to SharedPreferences
   ```

2. **Logged-in User Flow:**
   ```
   Add to Cart → CartNotifier.add() → Update state → Save to Firestore
   ```

3. **Login Migration Flow:**
   ```
   User logs in → CartNotifier.migrateGuestCartToUser() → 
   Transfer items to Firestore → Clear SharedPreferences
   ```

## Cart Item Model

```dart
class CartItem {
  final String productId;
  int qty;
  
  CartItem({required this.productId, this.qty = 1});
}
```

## Cart State Model

```dart
class CartState {
  final List<CartItem> items;
  final bool isLoading;
  final String? error;
}
```

## Cart Screen View Model

The cart screen uses a view model to combine cart items with product details:

```dart
class CartItemViewModel {
  final String productId;
  final String productName;
  final String description;
  final double price;
  final int quantity;
  final String vendorName;
  final String imagePath;
  final int stock;
  
  double get total => price * quantity;
}
```

## Integration Examples

### Wishlist → Cart
```dart
// In wishlist_screen.dart
void _addToCart(Map<String, dynamic> item) {
  final cartNotifier = ref.read(cartProvider.notifier);
  cartNotifier.add(item['id'] as String, qty: 1);
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('${item['name']} added to cart')),
  );
}
```

### Product Details → Cart
```dart
// In any product screen
ElevatedButton.icon(
  onPressed: () {
    ref.read(cartProvider.notifier).add(product.id, qty: selectedQty);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} added to cart'),
        action: SnackBarAction(
          label: 'View Cart',
          onPressed: () => Navigator.of(context).pushNamed('/cart'),
        ),
      ),
    );
  },
  icon: Icon(Icons.add_shopping_cart),
  label: Text('Add to Cart'),
)
```

## Testing

### Mock Cart Data
The product catalog provider (`lib/providers/product_catalog_provider.dart`) contains demo products that can be added to cart:
- Product 1: $49.99
- Product 2: $79.99

### Promo Codes
- `SAVE10` - 10% discount on subtotal

## Next Steps

Completed in this task:
- ✅ Cart screen integrated with cart provider
- ✅ Add/update/remove operations working
- ✅ Wishlist → Cart integration
- ✅ Reusable AddToCartButton widgets
- ✅ Cart persistence (guest & user)

Remaining (next tasks):
- [ ] Cart persistence enhancements (Task #5)
- [ ] Checkout screen (Task #6)
- [ ] Payment methods (Task #7)

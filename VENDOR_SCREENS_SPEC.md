# 📦 VENDOR SCREENS SPECIFICATION

## Based on Web Admin Dashboard Structure

---

## 🛍️ 1. PRODUCT MANAGEMENT SCREEN

### Purpose
Allow vendors to view, add, edit, and delete their products.

### Features (Admin Dashboard Aligned)

#### Top Section
- **Total Products Count**: Display total active products
- **Add Product Button**: FAB or top-right action button
- **Search Bar**: Filter products by name/SKU

#### Product List View
Each product card/row shows:
- **Product Image** (thumbnail)
- **Product Name**
- **SKU** / Product ID
- **Price** (formatted currency)
- **Stock Quantity**
- **Category**
- **Status Badge** (active, draft, out_of_stock)
- **Actions**: Edit | Delete | View

#### Product Details (When Tapped)
- Full product information
- Image gallery (multiple images)
- Description
- Price & stock
- Category & tags
- Status toggle
- Edit button

#### Add/Edit Product Form
Fields:
- Product name (required)
- Description (required)
- Category (dropdown)
- Price (number input)
- Stock quantity (number input)
- SKU (auto-generated or manual)
- Images (upload up to 5)
- Product tags (chips)
- Status (active/draft toggle)

### Mock Test Data (12 Products)

```json
[
  {
    "id": "PROD-001",
    "name": "Professional Soccer Ball",
    "sku": "SOC-001-BLK",
    "price": 2999,
    "stock": 45,
    "category": "Soccer Equipment",
    "status": "active",
    "imageUrl": "https://picsum.photos/200/200?random=1",
    "description": "FIFA approved professional soccer ball"
  },
  {
    "id": "PROD-002",
    "name": "Basketball Hoop Set",
    "sku": "BAS-002-SLV",
    "price": 12999,
    "stock": 12,
    "category": "Basketball Equipment",
    "status": "active",
    "imageUrl": "https://picsum.photos/200/200?random=2",
    "description": "Adjustable height basketball hoop"
  },
  {
    "id": "PROD-003",
    "name": "Tennis Racket Pro",
    "sku": "TEN-003-BLU",
    "price": 8999,
    "stock": 0,
    "category": "Tennis Equipment",
    "status": "out_of_stock",
    "imageUrl": "https://picsum.photos/200/200?random=3",
    "description": "Carbon fiber tennis racket"
  }
]
```

---

## 📦 2. ORDERS MANAGEMENT SCREEN

### Purpose
Allow vendors to view and manage orders for their products.

### Features (Admin Dashboard Aligned)

#### Top Section
- **Total Orders Count**: Display total orders
- **Filter Tabs**: All | Pending | Processing | Shipped | Delivered | Cancelled
- **Search Bar**: Filter by order ID or customer name
- **Date Range Filter**: Last 7 days, Last 30 days, Custom

#### Orders List View
Each order card/row shows:
- **Order ID** (e.g., ORD-2025-001)
- **Customer Name**
- **Order Date**
- **Total Amount** (formatted currency)
- **Status Badge** (pending, processing, shipped, delivered, cancelled)
- **Items Count** (e.g., "3 items")
- **Actions**: View Details | Update Status

#### Order Details (When Tapped)
- Order ID & Date
- Customer Information (name, email, phone, address)
- Product List (name, quantity, price per item, subtotal)
- Order Summary:
  - Subtotal
  - Shipping fee
  - Tax
  - Total
- Payment Status (paid, pending, failed)
- Shipping Status (pending, shipped, delivered)
- Status Update Actions:
  - Mark as Processing
  - Mark as Shipped (with tracking number)
  - Mark as Delivered
  - Cancel Order (with reason)

#### Status Update Dialog
- Current status display
- New status selector (dropdown)
- Notes/Tracking number (optional text field)
- Confirm/Cancel buttons

### Mock Test Data (24 Orders)

```json
[
  {
    "id": "ORD-2025-001",
    "customerId": "CUST-123",
    "customerName": "John Doe",
    "customerEmail": "john@example.com",
    "orderDate": "2025-12-28T10:30:00Z",
    "status": "pending",
    "paymentStatus": "paid",
    "items": [
      {
        "productId": "PROD-001",
        "productName": "Professional Soccer Ball",
        "quantity": 2,
        "price": 2999
      }
    ],
    "subtotal": 5998,
    "shippingFee": 500,
    "tax": 480,
    "total": 6978
  },
  {
    "id": "ORD-2025-002",
    "customerId": "CUST-124",
    "customerName": "Jane Smith",
    "customerEmail": "jane@example.com",
    "orderDate": "2025-12-27T14:15:00Z",
    "status": "shipped",
    "paymentStatus": "paid",
    "trackingNumber": "TRACK-12345",
    "items": [
      {
        "productId": "PROD-002",
        "productName": "Basketball Hoop Set",
        "quantity": 1,
        "price": 12999
      }
    ],
    "subtotal": 12999,
    "shippingFee": 1500,
    "tax": 1160,
    "total": 15659
  }
]
```

---

## 🎯 IMPLEMENTATION SUGGESTION

### Phase 1: Product Management (Priority: HIGH)
**Estimated Time:** 2-3 days

**Files to Create:**
1. `lib/screens/vendor/product_list_screen.dart`
   - List view of all vendor products
   - Search and filter functionality
   - Navigate to add/edit product

2. `lib/screens/vendor/product_form_screen.dart`
   - Add new product form
   - Edit existing product form
   - Image upload (Firebase Storage)
   - Form validation

3. `lib/screens/vendor/product_details_screen.dart`
   - Read-only product view
   - Edit button navigates to form
   - Delete confirmation dialog

4. `lib/repositories/vendor_product_repository.dart`
   - CRUD operations for products
   - Mock data for testing
   - Firestore integration ready

5. `lib/providers/vendor_product_providers.dart`
   - Product list stream provider
   - Product CRUD action provider
   - Search/filter state provider

**Mock Data Repository:**
```dart
class VendorProductRepository {
  static const bool _useMockData = true;
  
  Stream<List<Product>> getVendorProducts(String vendorId) {
    if (_useMockData) {
      return Stream.value(_getMockProducts());
    }
    // Real Firestore query
    return _db.collection('products')
      .where('vendorId', isEqualTo: vendorId)
      .snapshots()
      .map((s) => s.docs.map((d) => Product.fromFirestore(d)).toList());
  }
  
  static List<Product> _getMockProducts() {
    return [
      Product(
        id: 'PROD-001',
        name: 'Professional Soccer Ball',
        sku: 'SOC-001-BLK',
        price: 2999,
        stock: 45,
        category: 'Soccer Equipment',
        status: ProductStatus.active,
      ),
      // ... 11 more products
    ];
  }
}
```

---

### Phase 2: Order Management (Priority: HIGH)
**Estimated Time:** 2-3 days

**Files to Create:**
1. `lib/screens/vendor/orders_list_screen.dart`
   - List view of all vendor orders
   - Filter by status tabs
   - Search by order ID/customer
   - Navigate to order details

2. `lib/screens/vendor/order_details_screen.dart`
   - Complete order information
   - Customer details
   - Items list with prices
   - Update status button

3. `lib/screens/vendor/order_status_update_dialog.dart`
   - Status selector dropdown
   - Tracking number input (for shipped status)
   - Notes field
   - Confirmation

4. `lib/repositories/vendor_order_repository.dart`
   - Fetch vendor orders from Firestore
   - Update order status
   - Mock data for testing

5. `lib/providers/vendor_order_providers.dart`
   - Orders list stream provider
   - Status filter state provider
   - Order update action provider

**Mock Data Repository:**
```dart
class VendorOrderRepository {
  static const bool _useMockData = true;
  
  Stream<List<Order>> getVendorOrders(String vendorId, {OrderStatus? filter}) {
    if (_useMockData) {
      var orders = _getMockOrders();
      if (filter != null) {
        orders = orders.where((o) => o.status == filter).toList();
      }
      return Stream.value(orders);
    }
    // Real Firestore query
  }
  
  static List<Order> _getMockOrders() {
    return List.generate(24, (i) => Order(
      id: 'ORD-2025-${(i + 1).toString().padLeft(3, '0')}',
      customerName: 'Customer ${i + 1}',
      total: (5000 + (i * 500)),
      status: OrderStatus.values[i % OrderStatus.values.length],
      date: DateTime.now().subtract(Duration(days: i)),
    ));
  }
}
```

---

## 📱 UI/UX PATTERNS (Material Design 3)

### Product List
```dart
ListView.builder(
  itemCount: products.length,
  itemBuilder: (context, index) {
    final product = products[index];
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            product.imageUrl,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
          ),
        ),
        title: Text(product.name),
        subtitle: Text('${product.sku} • Stock: ${product.stock}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('\$${(product.price / 100).toStringAsFixed(2)}',
              style: TextStyle(fontWeight: FontWeight.bold)),
            _StatusBadge(status: product.status),
          ],
        ),
        onTap: () => Navigator.push(context, 
          MaterialPageRoute(builder: (_) => ProductDetailsScreen(product))),
      ),
    );
  },
);
```

### Order List
```dart
ListView.builder(
  itemCount: orders.length,
  itemBuilder: (context, index) {
    final order = orders[index];
    return Card(
      child: ListTile(
        title: Row(
          children: [
            Text(order.id, style: TextStyle(fontWeight: FontWeight.bold)),
            Spacer(),
            _OrderStatusBadge(status: order.status),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(order.customerName),
            Text(_formatDate(order.date), 
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        trailing: Text('\$${(order.total / 100).toStringAsFixed(2)}',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => OrderDetailsScreen(order))),
      ),
    );
  },
);
```

---

## ✅ ACCEPTANCE CRITERIA

### Product Management
- [ ] Display 12 mock products initially
- [ ] Search filters products by name
- [ ] Add product form validates all required fields
- [ ] Image upload works with Firebase Storage
- [ ] Edit product updates data
- [ ] Delete product shows confirmation dialog
- [ ] Stock status updates automatically (out_of_stock when qty = 0)
- [ ] Price displays in dollar format ($29.99)

### Order Management
- [ ] Display 24 mock orders initially
- [ ] Filter tabs work (All, Pending, Shipped, etc.)
- [ ] Search filters by order ID or customer name
- [ ] Order details show complete information
- [ ] Status update dialog appears when clicking "Update Status"
- [ ] Tracking number field appears only for "Shipped" status
- [ ] Order total calculated correctly (subtotal + shipping + tax)
- [ ] Date formats are user-friendly (Dec 28, 2025)

---

## 🚀 MY RECOMMENDATION

**Start with Product Management first** because:
1. Simpler scope - CRUD operations
2. No complex state transitions (unlike order status)
3. Vendors need to add products before receiving orders
4. Image upload is good practice for later features

**Then build Order Management** using lessons learned from products.

**Would you like me to:**
1. Build the Product Management screen first with full mock data?
2. Build the Order Management screen first?
3. Build both basic versions simultaneously?
4. Create just the navigation stubs for now and polish vendor dashboard more?

Let me know your preference and I'll implement it!

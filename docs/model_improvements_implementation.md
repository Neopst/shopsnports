# Data Model Improvements Implementation Guide

## Overview
This document provides step-by-step implementation for enhanced data models with priority-based rollout.

---

## 🎯 Priority Levels

**P0 (Critical):** Required for basic functionality  
**P1 (High):** Significantly improves features  
**P2 (Medium):** Nice to have, enhances UX  
**P3 (Low):** Future enhancements

---

## 1. AppUser Model Enhancements

### Current Implementation
```dart
class AppUser {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? address;
  final String? gender;
  final String? avatarUrl;
  final List<String>? roles;
  final Map<String, String>? roleStatus;
  final String? activeRole;
  final String? businessName;
  final String? bankName;
  final String? accountName;
  final String? accountNumber;
  final String? taxId;
  final bool affiliateApproved;
  final bool isAdmin;
  final String? affiliateId;
}
```

### Priority 1 Enhancements (Implement First)
```dart
class AppUser {
  // Existing fields...
  
  // P1 Additions
  final DateTime? createdAt;                    // User registration date
  final DateTime? updatedAt;                    // Last profile update
  final DateTime? lastLoginAt;                  // Last login timestamp
  final bool emailVerified;                     // Email verification status
  final bool phoneVerified;                     // Phone verification status
  final List<Address>? shippingAddresses;       // Multiple shipping addresses
  final String? defaultShippingAddressId;       // Default address reference
  
  AppUser({
    // Existing parameters...
    this.createdAt,
    this.updatedAt,
    this.lastLoginAt,
    this.emailVerified = false,
    this.phoneVerified = false,
    this.shippingAddresses,
    this.defaultShippingAddressId,
  });
  
  // Update factory
  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      // ... existing fields
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
      emailVerified: data['emailVerified'] ?? false,
      phoneVerified: data['phoneVerified'] ?? false,
      shippingAddresses: (data['shippingAddresses'] as List?)
          ?.map((e) => Address.fromJson(e))
          .toList(),
      defaultShippingAddressId: data['defaultShippingAddressId'],
    );
  }
}
```

### Priority 2 Enhancements (Implement Next)
```dart
class AppUser {
  // P1 fields...
  
  // P2 Additions
  final int profileCompleteness;                // 0-100 percentage
  final String preferredLanguage;               // 'en', 'fr', etc.
  final Map<String, bool> notificationPreferences; // Email, push, SMS
  final int loyaltyPoints;                      // Rewards points
  final String? referralCode;                   // Customer referral code
  
  // Computed property
  int calculateProfileCompleteness() {
    int score = 0;
    if (name.isNotEmpty) score += 15;
    if (email.isNotEmpty && emailVerified) score += 15;
    if (phone != null && phoneVerified) score += 15;
    if (address != null) score += 10;
    if (avatarUrl != null) score += 10;
    if (gender != null) score += 5;
    if (shippingAddresses != null && shippingAddresses!.isNotEmpty) score += 15;
    if (businessName != null) score += 15; // For vendors
    return score;
  }
}
```

**Implementation Steps:**
1. Update `lib/models/user.dart`
2. Update Firestore security rules
3. Create migration script for existing users
4. Update registration forms
5. Update profile edit screens
6. Add email/phone verification flows

---

## 2. Product Model Enhancements

### Priority 1 Enhancements
```dart
class Product {
  // Existing fields...
  
  // P1 Additions
  final String sku;                             // Stock Keeping Unit
  final int stockQuantity;                      // Current inventory
  final int lowStockThreshold;                  // Alert threshold
  final List<String> images;                    // Multiple images
  final double? compareAtPrice;                 // Original price for discount
  final List<String> tags;                      // Searchable tags
  final String status;                          // active, draft, archived
  
  Product({
    // Existing parameters...
    required this.sku,
    this.stockQuantity = 0,
    this.lowStockThreshold = 5,
    this.images = const [],
    this.compareAtPrice,
    this.tags = const [],
    this.status = 'active',
  });
  
  // Computed properties
  bool get isInStock => stockQuantity > 0;
  bool get isLowStock => stockQuantity <= lowStockThreshold && stockQuantity > 0;
  double? get discountPercentage {
    if (compareAtPrice == null || compareAtPrice! <= price) return null;
    return ((compareAtPrice! - price) / compareAtPrice!) * 100;
  }
  
  // Legacy support
  String get imageUrl => images.isNotEmpty ? images.first : '';
  String get image => imageUrl; // Existing code compatibility
}
```

### Priority 2 Enhancements
```dart
class Product {
  // P1 fields...
  
  // P2 Additions
  final double? weight;                         // In kg for shipping
  final Map<String, double>? dimensions;        // {length, width, height} in cm
  final double rating;                          // Average rating 0-5
  final int reviewCount;                        // Number of reviews
  final bool featured;                          // Featured product flag
  final List<ProductVariant>? variants;         // Size/color options
  final Map<String, String>? metaData;          // SEO: title, description
  
  // Factory with variants
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      // Existing fields...
      weight: (json['weight'] as num?)?.toDouble(),
      dimensions: json['dimensions'] != null
          ? Map<String, double>.from(json['dimensions'])
          : null,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['reviewCount'] ?? 0,
      featured: json['featured'] ?? false,
      variants: (json['variants'] as List?)
          ?.map((e) => ProductVariant.fromJson(e))
          .toList(),
      metaData: json['metaData'] != null
          ? Map<String, String>.from(json['metaData'])
          : null,
    );
  }
}

class ProductVariant {
  final String id;
  final String name;                            // "Small", "Red", etc.
  final String type;                            // "size", "color"
  final double? priceAdjustment;                // +/- from base price
  final int stockQuantity;
  final String? sku;
  
  ProductVariant({
    required this.id,
    required this.name,
    required this.type,
    this.priceAdjustment,
    this.stockQuantity = 0,
    this.sku,
  });
  
  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      priceAdjustment: (json['priceAdjustment'] as num?)?.toDouble(),
      stockQuantity: json['stockQuantity'] ?? 0,
      sku: json['sku'],
    );
  }
}
```

**Implementation Steps:**
1. Update `lib/models/product.dart`
2. Update product card widgets
3. Update product details screen
4. Add inventory management in vendor dashboard
5. Implement variant selector UI
6. Update search/filter logic

---

## 3. Order Model Enhancements

### Priority 0 (Critical - Implement Immediately)
```dart
class Order {
  // Existing fields...
  
  // P0 Critical Additions
  final String orderNumber;                     // User-friendly order ID
  final Address shippingAddress;                // Delivery address
  final Address billingAddress;                 // Billing address
  final double shippingCost;                    // Shipping fee
  final double tax;                             // Tax amount
  final double subtotal;                        // Items subtotal
  final String paymentMethod;                   // stripe, paystack, etc.
  final String paymentStatus;                   // pending, paid, failed
  final String? paymentId;                      // Transaction reference
  
  Order({
    // Existing parameters...
    required this.orderNumber,
    required this.shippingAddress,
    required this.billingAddress,
    required this.shippingCost,
    required this.tax,
    required this.subtotal,
    required this.paymentMethod,
    this.paymentStatus = 'pending',
    this.paymentId,
  });
  
  factory Order.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Order(
      id: doc.id,
      userId: data['userId'] ?? '',
      status: data['status'] ?? 'processing',
      total: (data['total'] as num?)?.toDouble() ?? 0.0,
      items: (data['items'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e))
          .toList() ?? [],
      orderNumber: data['orderNumber'] ?? doc.id.substring(0, 8).toUpperCase(),
      shippingAddress: Address.fromJson(data['shippingAddress']),
      billingAddress: Address.fromJson(data['billingAddress'] ?? data['shippingAddress']),
      shippingCost: (data['shippingCost'] as num?)?.toDouble() ?? 0.0,
      tax: (data['tax'] as num?)?.toDouble() ?? 0.0,
      subtotal: (data['subtotal'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: data['paymentMethod'] ?? 'unknown',
      paymentStatus: data['paymentStatus'] ?? 'pending',
      paymentId: data['paymentId'],
      eta: data['eta'],
      createdAt: data['createdAt'] as Timestamp?,
    );
  }
}
```

### Priority 1 Enhancements
```dart
class Order {
  // P0 fields...
  
  // P1 Additions
  final String? trackingNumber;                 // Shipping tracking number
  final String? trackingUrl;                    // Tracking link
  final String? notes;                          // Customer notes
  final String? adminNotes;                     // Internal notes
  final DateTime? estimatedDeliveryDate;        // Estimated delivery
  final DateTime? actualDeliveryDate;           // Actual delivery
  final List<OrderStatusChange> statusHistory;  // Status change log
  final String fulfillmentStatus;               // unfulfilled, partial, fulfilled
  
  // Helper to add status change
  void addStatusChange(String newStatus, String changedBy) {
    statusHistory.add(OrderStatusChange(
      status: newStatus,
      changedBy: changedBy,
      changedAt: DateTime.now(),
    ));
  }
}

class OrderStatusChange {
  final String status;
  final String changedBy;                       // userId or "system"
  final DateTime changedAt;
  final String? note;
  
  OrderStatusChange({
    required this.status,
    required this.changedBy,
    required this.changedAt,
    this.note,
  });
}
```

**Implementation Steps:**
1. Update `lib/models/order.dart`
2. Create Address model (see below)
3. Update checkout screen to capture addresses
4. Update order creation logic
5. Add order tracking screen
6. Implement status history UI

---

## 4. CartItem Model Enhancements

### Current Implementation
```dart
class CartItem {
  final String productId;
  int qty;
  
  CartItem({required this.productId, this.qty = 1});
}
```

### Priority 1 Enhancement
```dart
class CartItem {
  final String productId;
  final String? variantId;                      // For product variants
  int qty;
  final double price;                           // Snapshot at add-to-cart
  final String name;                            // Product name snapshot
  final String imageUrl;                        // Product image snapshot
  final DateTime addedAt;                       // When added to cart
  final String? notes;                          // Special instructions
  
  CartItem({
    required this.productId,
    this.variantId,
    this.qty = 1,
    required this.price,
    required this.name,
    required this.imageUrl,
    DateTime? addedAt,
    this.notes,
  }) : addedAt = addedAt ?? DateTime.now();
  
  // Calculate item subtotal
  double get subtotal => price * qty;
  
  // JSON serialization for persistence
  Map<String, dynamic> toJson() => {
    'productId': productId,
    'variantId': variantId,
    'qty': qty,
    'price': price,
    'name': name,
    'imageUrl': imageUrl,
    'addedAt': addedAt.toIso8601String(),
    'notes': notes,
  };
  
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      productId: json['productId'],
      variantId: json['variantId'],
      qty: json['qty'] ?? 1,
      price: (json['price'] as num).toDouble(),
      name: json['name'],
      imageUrl: json['imageUrl'],
      addedAt: DateTime.parse(json['addedAt']),
      notes: json['notes'],
    );
  }
}
```

**Why This Matters:**
- Price snapshot prevents price changes affecting cart
- Name/image snapshot ensures cart items display even if product deleted
- Variant support enables size/color selection
- Notes enable customer customization

**Implementation Steps:**
1. Update `lib/models/cart_item.dart`
2. Update cart provider to pass product data when adding
3. Update cart UI to show snapshots
4. Migrate existing cart items
5. Update checkout to use snapshots

---

## 5. New Models Implementation

### Address Model (Priority 0 - Critical)

**File:** `lib/models/address.dart`

```dart
class Address {
  final String id;
  final String label;                           // "Home", "Office", "Other"
  final String fullName;
  final String phone;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final bool isDefault;
  final double? latitude;                       // For map integration
  final double? longitude;
  final DateTime createdAt;
  
  Address({
    required this.id,
    required this.label,
    required this.fullName,
    required this.phone,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.postalCode,
    this.country = 'Nigeria',
    this.isDefault = false,
    this.latitude,
    this.longitude,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
  
  // Display format
  String get fullAddress {
    final parts = [
      addressLine1,
      if (addressLine2 != null && addressLine2!.isNotEmpty) addressLine2,
      city,
      state,
      postalCode,
      country,
    ];
    return parts.join(', ');
  }
  
  String get shortAddress => '$addressLine1, $city';
  
  // JSON serialization
  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'fullName': fullName,
    'phone': phone,
    'addressLine1': addressLine1,
    'addressLine2': addressLine2,
    'city': city,
    'state': state,
    'postalCode': postalCode,
    'country': country,
    'isDefault': isDefault,
    'latitude': latitude,
    'longitude': longitude,
    'createdAt': createdAt.toIso8601String(),
  };
  
  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] ?? '',
      label: json['label'] ?? 'Address',
      fullName: json['fullName'] ?? '',
      phone: json['phone'] ?? '',
      addressLine1: json['addressLine1'] ?? '',
      addressLine2: json['addressLine2'],
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      postalCode: json['postalCode'] ?? '',
      country: json['country'] ?? 'Nigeria',
      isDefault: json['isDefault'] ?? false,
      latitude: json['latitude'],
      longitude: json['longitude'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
  
  Address copyWith({
    String? id,
    String? label,
    String? fullName,
    String? phone,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    bool? isDefault,
    double? latitude,
    double? longitude,
  }) {
    return Address(
      id: id ?? this.id,
      label: label ?? this.label,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      isDefault: isDefault ?? this.isDefault,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt,
    );
  }
}
```

**Usage:**
1. User profile: Multiple shipping addresses
2. Checkout: Select shipping/billing address
3. Orders: Store delivery address
4. Vendor: Business address

---

### Review Model (Priority 2)

**File:** `lib/models/review.dart`

```dart
class Review {
  final String id;
  final String productId;
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final double rating;                          // 1-5
  final String title;
  final String comment;
  final List<String> images;                    // Review photos
  final bool verifiedPurchase;                  // Verified buyer
  final int helpfulCount;                       // Helpful votes
  final String status;                          // pending, approved, rejected
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  Review({
    required this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    required this.rating,
    required this.title,
    required this.comment,
    this.images = const [],
    this.verifiedPurchase = false,
    this.helpfulCount = 0,
    this.status = 'pending',
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();
  
  // JSON serialization
  Map<String, dynamic> toJson() => {
    'id': id,
    'productId': productId,
    'userId': userId,
    'userName': userName,
    'userAvatarUrl': userAvatarUrl,
    'rating': rating,
    'title': title,
    'comment': comment,
    'images': images,
    'verifiedPurchase': verifiedPurchase,
    'helpfulCount': helpfulCount,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };
  
  factory Review.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Review(
      id: doc.id,
      productId: data['productId'],
      userId: data['userId'],
      userName: data['userName'],
      userAvatarUrl: data['userAvatarUrl'],
      rating: (data['rating'] as num).toDouble(),
      title: data['title'],
      comment: data['comment'],
      images: List<String>.from(data['images'] ?? []),
      verifiedPurchase: data['verifiedPurchase'] ?? false,
      helpfulCount: data['helpfulCount'] ?? 0,
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
```

---

## 📅 Implementation Roadmap

### Week 1: Critical Models
- [ ] Day 1-2: Implement Address model
- [ ] Day 2-3: Update Order model with P0 fields
- [ ] Day 3-4: Update CartItem model with snapshots
- [ ] Day 4-5: Test and migrate existing data

### Week 2: High Priority
- [ ] Day 1-2: Update AppUser model (P1)
- [ ] Day 2-3: Update Product model (P1)
- [ ] Day 3-4: Implement Review model
- [ ] Day 4-5: Update UI components

### Week 3: Medium Priority
- [ ] Day 1-2: Add Product variants
- [ ] Day 2-3: Add Order tracking
- [ ] Day 3-4: Add Notification model
- [ ] Day 4-5: Testing and optimization

---

## 🧪 Testing Strategy

For each model enhancement:
1. Write unit tests for model serialization
2. Test database migrations
3. Update integration tests
4. Verify backwards compatibility
5. Test UI components

---

## 🚀 Deployment Strategy

1. **Backwards Compatible:** Ensure old data still works
2. **Gradual Rollout:** Deploy P0 → P1 → P2
3. **Data Migration:** Script to update existing records
4. **Monitoring:** Track errors during migration
5. **Rollback Plan:** Keep old model versions for 1 release

---

**Document Version:** 1.0  
**Last Updated:** December 23, 2025  
**Status:** Ready for Implementation

# ShopsNSports REST API Documentation

Base URL: `http://localhost:3000/api/v1`

## Authentication
All endpoints require Firebase ID Token in Authorization header:
```
Authorization: Bearer <firebase-id-token>
```

---

## Products API (8 endpoints)

### `GET /products`
Get all products with filtering
- Query params: `status`, `category_id`, `vendor_id`, `search`, `show_all` (admin)
- Returns: List of products

### `GET /products/search`
Search products by name/description
- Query params: `q` (search term), `category_id`, `min_price`, `max_price`

### `GET /products/:id`
Get single product by ID

### `POST /products`
Create new product (defaults to `pending_approval` status)

### `PUT /products/:id`
Update product details

### `PUT /products/:id/approve`
Approve pending product (admin only)
- Body: `{ approved_by: "admin-id" }`

### `PUT /products/:id/reject`
Reject pending product (admin only)
- Body: `{ rejection_reason: "reason", rejected_by: "admin-id" }`

### `DELETE /products/:id`
Delete product

---

## Categories API (5 endpoints)

### `GET /categories`
Get all categories
- Query params: `status`, `parent_id`

### `GET /categories/:id`
Get single category

### `POST /categories`
Create new category

### `PUT /categories/:id`
Update category

### `DELETE /categories/:id`
Delete category (checks for products/subcategories)

---

## Orders API (5 endpoints)

### `GET /orders`
Get all orders
- Query params: `status`, `customer_id`, `vendor_id`, `date_from`, `date_to`, `search`

### `GET /orders/:id`
Get single order with items

### `POST /orders`
Create new order
- Body: `{ customer_id, vendor_id, items[], shipping_address, payment_method }`

### `PATCH /orders/:id/status`
Update order status
- Body: `{ status: "pending|processing|shipped|delivered|cancelled|refunded", notes }`

### `DELETE /orders/:id`
Delete order (admin only)

---

## Reviews API (12 endpoints)

### `GET /reviews`
Get all reviews
- Query params: `status`, `rating`, `product_id`, `customer_id`, `vendor_id`, `search`

### `GET /reviews/stats`
Get review statistics (total, pending, average rating, etc.)

### `GET /reviews/:id`
Get single review

### `POST /reviews`
Create new review (defaults to `pending` status)

### `PUT /reviews/:id/approve`
Approve review (admin)

### `PUT /reviews/:id/reject`
Reject review (admin)

### `POST /reviews/bulk/approve`
Bulk approve reviews
- Body: `{ ids: ["id1", "id2"], approved_by: "admin-id" }`

### `POST /reviews/bulk/reject`
Bulk reject reviews

### `POST /reviews/bulk/delete`
Bulk delete reviews

### `PUT /reviews/:id/helpful`
Increment helpful count

### `DELETE /reviews/:id`
Delete review

---

## Users API (7 endpoints)

### `GET /users`
Get all users
- Query params: `role` (customer|vendor|affiliate|admin), `status`, `is_verified`, `search`

### `GET /users/:id`
Get single user (password excluded)

### `POST /users`
Create new user
- Body: `{ email, password, name, phone, role, business_name?, ... }`

### `PUT /users/:id`
Update user profile

### `PATCH /users/:id/status`
Update user status
- Body: `{ status: "active|suspended|banned|deleted" }`

### `DELETE /users/:id`
Delete user

### `GET /users/:id/orders`
Get user's order history

---

## Cart API (5 endpoints)

### `GET /cart/:userId`
Get user's cart with all items

### `POST /cart/:userId/items`
Add item to cart
- Body: `{ product_id, quantity, variant_id? }`

### `PUT /cart/:userId/items/:itemId`
Update item quantity
- Body: `{ quantity }`

### `DELETE /cart/:userId/items/:itemId`
Remove item from cart

### `DELETE /cart/:userId`
Clear entire cart

---

## Shipping API (6 endpoints)

### `GET /shipping`
Get all shipping profiles
- Query params: `vendor_id`, `is_active`

### `GET /shipping/:id`
Get single shipping profile

### `POST /shipping`
Create new shipping profile
- Body: `{ name, carrier, service_type, base_rate, delivery_time_min, delivery_time_max, ... }`

### `PUT /shipping/:id`
Update shipping profile

### `DELETE /shipping/:id`
Delete shipping profile

### `POST /shipping/calculate`
Calculate shipping cost
- Body: `{ shipping_profile_id, weight, item_count, subtotal, destination }`
- Returns: Calculated shipping cost and delivery estimates

---

## Response Format

### Success Response
```json
{
  "success": true,
  "data": { ... },
  "message": "Optional success message",
  "count": 10  // For list endpoints
}
```

### Error Response
```json
{
  "success": false,
  "error": "Error message",
  "message": "Detailed error description"
}
```

---

## Status Codes

- `200` - Success
- `201` - Created
- `400` - Bad Request (validation error)
- `401` - Unauthorized (missing/invalid token)
- `404` - Not Found
- `409` - Conflict (duplicate, constraint violation)
- `500` - Internal Server Error

---

## Total Endpoints: 48

- Products: 8
- Categories: 5
- Orders: 5
- Reviews: 12
- Users: 7
- Cart: 5
- Shipping: 6

All endpoints perfectly mirror the admin dashboard repository interfaces for seamless integration.

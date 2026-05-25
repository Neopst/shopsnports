# Home Screen API Integration Guide

## Overview
The mobile app home screen now connects directly to the **web admin backend** (`server/admin.js`) to fetch all dynamic content. This ensures **consistent data flow** and **easy management** through the admin dashboard.

---

## Architecture

```
┌─────────────────────────┐
│  Mobile App (Flutter)   │
│  lib/screens/           │
│  - home_screen.dart     │
│  - category_*.dart      │
└───────────┬─────────────┘
            │
            │ HTTP GET
            │
            v
┌─────────────────────────┐
│  Admin API Service      │
│  lib/services/          │
│  - admin_api_service.dart
└───────────┬─────────────┘
            │
            │ REST API
            │
            v
┌─────────────────────────┐
│  Backend Server         │
│  server/admin.js        │
│  Node.js + Express      │
└───────────┬─────────────┘
            │
            │
            v
┌─────────────────────────┐
│  Database / Firestore   │
│  - Products             │
│  - Categories           │
│  - Slides (Banners)     │
│  - News Ticker          │
└─────────────────────────┘
```

---

## API Endpoints Used

### 1. **Home Slider Banners**
**Endpoint**: `GET /admin/slides`

**Response**:
```json
{
  "slides": [
    {
      "id": 1,
      "image_url": "https://cdn.example.com/banner1.jpg",
      "title": "Summer Sale",
      "active": true,
      "ordering": 1
    }
  ]
}
```

**Mobile Usage**: `lib/screens/home_screen.dart`
- Fetches banner images for `BannerSlider` widget
- Filters for active slides only
- Fallback to default asset if API fails

---

### 2. **Products Catalog**
**Endpoint**: `GET /admin/products`

**Optional Query**: `?category_id=123`

**Response**:
```json
{
  "products": [
    {
      "id": 501,
      "name": "Nike Air Max",
      "price": 12999,
      "image_url": "https://cdn.example.com/product.jpg",
      "sku": "NKE-AM-001",
      "category_id": 2,
      "status": "active"
    }
  ]
}
```

**Mobile Usage**: `lib/screens/home_screen.dart`
- Displays "Popular right now" (first 6 products)
- Displays "New arrivals" (next 6 products)
- Shows product cards with image, name, price, SKU

---

### 3. **Categories**
**Endpoint**: `GET /admin/categories`

**Response**:
```json
{
  "categories": [
    {
      "id": 1,
      "name": "Footwear",
      "slug": "footwear",
      "description": "Athletic and casual shoes",
      "image_url": "https://cdn.example.com/category.jpg",
      "product_count": 203,
      "status": "active",
      "created_at": "2025-01-01T00:00:00Z"
    }
  ]
}
```

**Mobile Usage**: `lib/widgets/category_scroller.dart`
- Horizontal scrollable category chips
- Uses Riverpod provider: `categoriesProvider`
- Shows category name and product count

---

### 4. **News Ticker** *(Firestore-backed)*
**Endpoint**: `GET /admin/news-ticker`

**Response**:
```json
{
  "items": [
    {
      "id": "abc123",
      "text": "🔥 Flash Sale: 30% off sneakers!",
      "link": null,
      "priority": 10,
      "isActive": true,
      "createdAt": "2025-12-31T10:00:00Z",
      "expiresAt": null
    }
  ]
}
```

**Mobile Usage**: `lib/services/news_ticker_service.dart`
- Already integrated via Firestore listener
- No code changes needed (existing implementation)
- Admin dashboard manages via Firestore

---

## File Structure

### **New Files Created**
```
lib/
├── services/
│   └── admin_api_service.dart        # API client for admin backend
├── providers/
│   └── category_provider.dart        # Riverpod provider for categories
└── core/
    └── config/
        └── admin_api_config.dart     # API base URL configuration
```

### **Updated Files**
```
lib/
├── screens/
│   └── home_screen.dart              # Now uses API data
└── widgets/
    └── category_scroller.dart        # Now uses categoriesProvider
```

---

## Configuration

### **Development Mode (Default)**
Base URL: `http://localhost:3000/admin`

No configuration needed. Just run the backend server:
```bash
cd server
npm start
```

### **Production Mode**
Set the backend URL via `--dart-define`:

```bash
flutter run --dart-define=ADMIN_API_URL=https://api.yourapp.com/admin
```

Or build for release:
```bash
flutter build apk --dart-define=ADMIN_API_URL=https://api.yourapp.com/admin
```

Configuration file: `lib/core/config/admin_api_config.dart`

---

## Error Handling

### **Loading States**
- **First load**: Shows `CircularProgressIndicator`
- **Refresh**: Pull-to-refresh gesture reloads data
- **Empty data**: Shows fallback assets/messages

### **Error States**
- **Network error**: Shows error message with "Retry" button
- **Server error**: Displays error details (in dev mode)
- **Timeout**: 30-second timeout (configurable)

### **Fallback Strategy**
```dart
// If API fails, home screen uses:
_bannerImages = ['assets/images/1.jpg']; // Default banner
```

---

## Admin Dashboard Workflow

### **Adding New Products**
1. Open web admin: `http://localhost:3000/admin`
2. Navigate to **Products** section
3. Click **Add Product**
4. Fill in: Name, Price, Image URL, SKU, Category
5. Click **Save**
6. Mobile app automatically shows new product on refresh

### **Managing Banners**
1. Web admin → **Slides** section
2. Add/Edit slide with image URL
3. Set `active: true` and ordering number
4. Mobile app home screen updates banner slider

### **Managing Categories**
1. Web admin → **Categories** section
2. Add/Edit category with name, slug, image
3. Mobile app category scroller updates automatically

### **News Ticker**
1. Web admin → **News Ticker** section
2. Add news item with text, priority, expiry
3. Mobile app ticker updates in real-time (Firestore)

---

## Testing Checklist

### **Before Testing**
- [ ] Backend server running: `cd server && npm start`
- [ ] Mobile app connected to same network (for `localhost`)
- [ ] Database seeded with sample data

### **Test Scenarios**
- [ ] **Home screen loads**: Banners, products, categories visible
- [ ] **Pull-to-refresh**: Data reloads successfully
- [ ] **Error state**: Stop server → See error message with Retry
- [ ] **Empty state**: Clear database → See empty state messages
- [ ] **Category filter**: Tap category → See filtered products
- [ ] **Product tap**: Tap product card → Navigate to detail
- [ ] **News ticker**: See ticker scrolling at top (MainScaffold)

### **Admin Sync Test**
1. Add product in admin dashboard
2. Refresh mobile app home screen
3. New product appears in "Popular" or "New arrivals"
4. ✅ Data synced successfully

---

## Troubleshooting

### **"Failed to load data" Error**

**Possible Causes:**
1. Backend server not running
2. Wrong API URL (localhost vs. real IP)
3. Network/firewall blocking connection
4. CORS issues (web build only)

**Solutions:**
```bash
# Check backend is running
curl http://localhost:3000/admin/products

# On emulator, use 10.0.2.2 instead of localhost
flutter run --dart-define=ADMIN_API_URL=http://10.0.2.2:3000/admin

# On physical device, use computer's IP
flutter run --dart-define=ADMIN_API_URL=http://192.168.1.100:3000/admin
```

### **Empty Products/Categories**

**Check database has data:**
```bash
# If using Firestore - check Firebase console
# If using PostgreSQL:
psql -d shopsnports -c "SELECT COUNT(*) FROM products;"
```

**Seed sample data:**
```bash
cd server
npm run seed  # If seed script exists
```

### **Images Not Loading**

**Issues:**
- Image URLs must be absolute (https://...)
- Local paths won't work (assets/ only works for bundled assets)
- CORS headers required for external images

**Fix:**
- Use CDN URLs (Cloudinary, Firebase Storage)
- Or use base64 encoded images (small icons only)

---

## Performance Optimization

### **Caching Strategy**
```dart
// TODO: Add to admin_api_service.dart
final _productsCache = <String, List<Map<String, dynamic>>>{};
final _cacheExpiry = <String, DateTime>{};

Future<List<Map<String, dynamic>>> getProducts({int? categoryId}) async {
  final cacheKey = 'products_${categoryId ?? 'all'}';
  
  // Check cache
  if (_cacheExpiry[cacheKey]?.isAfter(DateTime.now()) ?? false) {
    return _productsCache[cacheKey]!;
  }
  
  // Fetch from API
  final products = await _fetchProducts(categoryId);
  
  // Update cache (5 minute expiry)
  _productsCache[cacheKey] = products;
  _cacheExpiry[cacheKey] = DateTime.now().add(Duration(minutes: 5));
  
  return products;
}
```

### **Lazy Loading**
- Currently loads first 12 products only
- Implement pagination for large catalogs
- Use `ListView.builder` with scroll listener

### **Image Optimization**
- Backend should serve optimized thumbnails
- Mobile requests: `?size=thumbnail` query param
- Use `cached_network_image` package for image caching

---

## Next Steps

1. ✅ **Home screen** - Connected to admin API
2. ✅ **Categories** - Using provider with API data
3. ✅ **News ticker** - Already using Firestore (admin-managed)
4. ⏳ **Product detail** - Implement detail screen with API
5. ⏳ **Search** - Connect search bar to API endpoint
6. ⏳ **Cart** - Sync cart with backend orders API
7. ⏳ **Vendor dashboard** - Verify functionality
8. ⏳ **Affiliate dashboard** - Verify functionality

---

## Related Documentation

- **Backend API**: See `server/admin.js` for all endpoints
- **Payment Setup**: See `PAYMENT_SETUP_GUIDE.md`
- **Deployment**: See `MOBILE_APP_DEPLOYMENT_HANDOFF.md`
- **Testing**: See `QUICK_TESTING_GUIDE.md`

---

## Support

**Admin Backend Endpoints Reference:**
- Products: `GET /admin/products`
- Categories: `GET /admin/categories`
- Slides: `GET /admin/slides`
- News Ticker: `GET /admin/news-ticker`
- Orders: `GET /admin/orders`
- Vendors: `GET /admin/vendors`
- Metrics: `GET /admin/metrics`

**Full API Documentation**: Run backend server and visit:
```
http://localhost:3000/api-docs
```

---

**Last Updated**: December 31, 2025  
**Status**: ✅ Home Screen Integration Complete

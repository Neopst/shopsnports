# Mock Data Configuration Guide

## 🎯 Overview

The mobile app now has **MOCK DATA FALLBACK** to work even when the backend server is offline. This lets you:
- ✅ See the app working immediately without running the backend
- ✅ Test the UI and navigation
- ✅ Verify data flows from "admin dashboard structure"
- ✅ When you go live, just disable mock data and it uses real backend

---

## 🔄 How It Works

```
1. App tries to connect to backend (localhost:3000)
   ↓
2. If backend is OFFLINE → Uses mock data automatically
   ↓
3. Console shows: "🔄 Using mock products data (backend not available)"
   ↓
4. App displays mock products/categories/banners
   ↓
5. When backend comes ONLINE → Automatically uses real data
```

---

## 📂 Mock Data Structure

All mock data in: **`lib/services/admin_api_service.dart`**

### Mock Products (12 items)
```dart
- Nike Air Max 2024 ($129.99)
- Adidas Ultraboost ($159.99)
- Under Armour T-Shirt ($29.99)
- Fitness Tracker Pro ($99.99)
- Yoga Mat Premium ($49.99)
- Resistance Bands Set ($34.99)
- Basketball Shoes Elite ($179.99)
- Sports Water Bottle ($19.99)
- Running Shorts ($39.99)
- Gym Bag XL ($59.99)
- Compression Socks ($24.99)
- Dumbbells 10kg Set ($89.99)
```

### Mock Categories (4 items)
```dart
- Sports Equipment (156 products)
- Footwear (203 products)
- Clothing (342 products)
- Fitness Accessories (98 products)
```

### Mock Banners (3 slides)
```dart
- Summer Sale (assets/images/1.jpg)
- New Arrivals (assets/images/2.jpg)
- Featured Brands (assets/images/3.jpg)
```

---

## ⚙️ Configuration

### **Current Setup (Mock Enabled)**
File: `lib/services/admin_api_service.dart`

```dart
AdminApiService({
  String? baseUrl,
  this.useMockData = true,  // ← Mock data ENABLED
})
```

### **Disable Mock Data (Production)**
When you go live and have real backend:

```dart
AdminApiService({
  String? baseUrl,
  this.useMockData = false,  // ← Mock data DISABLED
})
```

Or update the singleton at the bottom:

```dart
final adminApiService = AdminApiService(useMockData: false);
```

---

## 🧪 Testing Scenarios

### **Scenario 1: Backend Offline (Current)**
```bash
# Backend NOT running
flutter run
```

**Result:**
- ✅ App loads successfully
- ✅ Shows 12 mock products
- ✅ Shows 4 mock categories
- ✅ Shows 3 mock banners
- ✅ Console: "🔄 Using mock data..."

### **Scenario 2: Backend Online**
```bash
# Terminal 1: Start backend
cd server
npm start

# Terminal 2: Run app
flutter run
```

**Result:**
- ✅ App connects to backend
- ✅ Shows REAL products from database
- ✅ Shows REAL categories from database
- ✅ Shows REAL banners from database
- ✅ No mock data messages

### **Scenario 3: Backend Goes Offline Mid-Use**
```bash
# Stop backend while app is running
# Pull to refresh in app
```

**Result:**
- ✅ Automatically switches to mock data
- ✅ App continues working
- ✅ Console: "🔄 Using mock data..."

---

## 🗑️ Deleting Mock Data (Production)

When you're ready to go live:

### **Option 1: Delete Mock Methods**
Open `lib/services/admin_api_service.dart` and delete:

```dart
// ============================================================================
// MOCK DATA - Matches Web Admin Dashboard Structure
// ============================================================================
// Delete this section when backend is ready for production

List<Map<String, dynamic>> _getMockProducts() { ... }
List<Map<String, dynamic>> _getMockCategories() { ... }
List<Map<String, dynamic>> _getMockSlides() { ... }
```

### **Option 2: Disable Mock Flag**
Change constructor:

```dart
AdminApiService({
  String? baseUrl,
  this.useMockData = false,  // Changed from true
})
```

---

## 🔍 Console Messages

### **Using Mock Data:**
```
🔄 Using mock products data (backend not available)
🔄 Using mock categories data (backend not available)
🔄 Using mock slides data (backend not available)
```

### **Using Real Data:**
```
(No special messages - just normal API calls)
```

### **Connection Error:**
```
Failed to load data from server. Pull to refresh.

Error: Connection timeout
```

---

## 📊 Data Flow Diagram

```
┌─────────────────────┐
│   Mobile App        │
│   Requests Data     │
└──────────┬──────────┘
           │
           v
┌─────────────────────┐
│  AdminApiService    │
│  Try Backend First  │
└──────────┬──────────┘
           │
     ┌─────┴─────┐
     │           │
     v           v
Backend      Backend
Online       Offline
     │           │
     v           v
  Real        Mock
  Data        Data
     │           │
     └─────┬─────┘
           │
           v
   ┌───────────────┐
   │  Home Screen  │
   │  Displays     │
   └───────────────┘
```

---

## 🚀 Benefits

### **Development:**
- ✅ Work on UI without backend running
- ✅ Fast iteration on mobile app
- ✅ No database setup needed initially
- ✅ Offline development possible

### **Testing:**
- ✅ Test error handling (turn off backend)
- ✅ Test loading states
- ✅ Test offline mode
- ✅ Verify data structure matches admin

### **Production:**
- ✅ Easy switch to real data (one flag)
- ✅ Mock data as documentation
- ✅ Clear separation of concerns
- ✅ Gradual migration possible

---

## 📝 Customizing Mock Data

### **Add More Products:**

```dart
List<Map<String, dynamic>> _getMockProducts() {
  return [
    // ... existing products ...
    {
      'id': 13,
      'name': 'Your Product Name',
      'price': 4999,  // Price in cents
      'image_url': 'assets/images/your_image.jpg',
      'sku': 'YOUR-SKU-013',
      'category_id': 1,
      'status': 'active',
      'description': 'Your description',
    },
  ];
}
```

### **Add More Categories:**

```dart
List<Map<String, dynamic>> _getMockCategories() {
  return [
    // ... existing categories ...
    {
      'id': 5,
      'name': 'Your Category',
      'slug': 'your-category',
      'description': 'Your description',
      'image_url': 'assets/images/your_category.jpg',
      'product_count': 50,
      'status': 'active',
      'created_at': DateTime.now().toIso8601String(),
    },
  ];
}
```

---

## ⚠️ Important Notes

1. **Price Format**: Prices are in CENTS (e.g., 12999 = $129.99)
2. **Image URLs**: Using local assets (`assets/images/`) for demo
3. **Category IDs**: Match products to categories by `category_id`
4. **Status**: Always `'active'` for visible items
5. **Console Logs**: Use `print()` statements to debug data flow

---

## 🔧 Troubleshooting

### **"Failed to load categories" even with mock data**

**Check:**
1. Is `useMockData = true` in AdminApiService?
2. Are the mock methods defined?
3. Check console for error messages

**Fix:**
```dart
// lib/services/admin_api_service.dart
AdminApiService({
  String? baseUrl,
  this.useMockData = true,  // ← Make sure this is true
})
```

### **"News ticker is gone"**

**Reason:** News ticker uses Firestore directly (not admin API)

**Fix:** Check Firebase initialization in `main.dart`:
```dart
await Firebase.initializeApp();
```

### **Mock data not updating**

**Solution:**
```bash
# Hot restart (not just hot reload)
flutter run

# Or in terminal while app is running:
r  # Hot reload
R  # Hot restart
```

---

## 📚 Related Files

- `lib/services/admin_api_service.dart` - API service with mock data
- `lib/screens/home_screen.dart` - Uses API service
- `lib/widgets/category_scroller.dart` - Uses category provider
- `lib/providers/category_provider.dart` - Wraps API service
- `server/admin.js` - Real backend API endpoints

---

## 🎯 Next Steps

1. ✅ **Now:** App works with mock data (no backend needed)
2. ⏳ **Later:** Run backend server for real data testing
3. ⏳ **Pre-launch:** Disable mock data (`useMockData = false`)
4. ⏳ **Production:** Delete mock methods completely

---

**Last Updated:** December 31, 2025  
**Status:** ✅ Mock Data Active - App works offline!

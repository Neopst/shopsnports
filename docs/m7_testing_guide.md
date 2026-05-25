# M7 Testing Guide - Loading States & News Ticker

## Quick Testing Checklist

### 1. News Ticker Visibility ✅
Test that the news ticker appears on these screens:

- [ ] **Home Screen** - Navigate to home
- [ ] **Product List** - Navigate to /products
- [ ] **Product Details** - Tap any product
- [ ] **Search Screen** - Navigate to search
- [ ] **Cart Screen** - Navigate to cart
- [ ] **Orders List** - Navigate to orders
- [ ] **Profile Screen** - Navigate to profile
- [ ] **Checkout Screen** - Start checkout process

**Expected:** News ticker scrolling at the top of each screen

---

### 2. Loading Skeleton Screens ✅

#### Product List Screen
1. Navigate to Products
2. **Expected:** See shimmer loading skeleton (2-column grid)
3. After 2 seconds: Actual products appear
4. Pull down to refresh
5. **Expected:** Brief loading indicator at top

#### Orders List Screen
1. Navigate to Orders
2. **Expected:** See order card skeletons
3. After 2 seconds: Actual orders appear
4. Pull down to refresh
5. **Expected:** Refresh indicator

#### Search Screen
1. Navigate to Search
2. Type search query and press enter
3. **Expected:** See list item skeletons during search
4. After 1 second: Search results appear
5. Clear search
6. **Expected:** Empty state with search icon

---

### 3. Loading States

#### Initial Loading
```
Screen opens → Skeleton appears → Data loads → Content shows
```

#### Pull-to-Refresh
```
Pull down → Progress indicator → Data reloads → Content updates
```

#### Error State (Simulated)
To test error handling:
1. Turn off WiFi/data
2. Navigate to Product List
3. **Expected:** Error icon + message + "Try Again" button
4. Tap "Try Again"
5. Turn on WiFi/data
6. **Expected:** Loading skeleton → Content loads

---

### 4. Shimmer Animation Quality

Check that shimmer effect:
- [ ] Smooth animation (no jank)
- [ ] Proper color gradient (light grey to white)
- [ ] Matches content layout (cards, lists, grids)
- [ ] Consistent across all screens

---

### 5. User Experience Flow

#### Happy Path
1. Open app
2. See news ticker immediately
3. Products load with skeleton
4. Smooth transition to actual content
5. Pull-to-refresh works smoothly
6. Navigate between screens - ticker visible everywhere

#### Error Path
1. Disable internet
2. Open product list
3. See error message (not technical error)
4. Tap "Try Again"
5. Enable internet
6. Content loads successfully

---

### 6. Performance Checks

- [ ] App launches without crashes
- [ ] Skeleton screens render immediately (< 100ms)
- [ ] No lag during shimmer animation
- [ ] Smooth scrolling with skeletons
- [ ] Memory usage stays stable
- [ ] No flickering during state transitions

---

## Known Issues to Ignore (Pre-existing)

These errors existed before M7 and will be fixed in M8:
- `analysis_options.yaml` - Deprecated lint rules
- `secure_storage_service.dart` - Package conflicts
- `main.dart` - Duplicate imports
- `phone_login_screen.dart` - AppRoutes undefined
- Some widget errors in other screens

---

## Testing Commands

### Run Unit Tests
```powershell
flutter test test/unit/ --reporter=expanded
```

### Run Widget Tests
```powershell
flutter test test/ --reporter=expanded
```

### Check for Errors
```powershell
flutter analyze
```

### Hot Reload
```powershell
# In running app, press 'r' in terminal
r
```

### Hot Restart
```powershell
# In running app, press 'R' in terminal
R
```

---

## Visual Checklist

### Before Loading (Skeleton)
```
┌─────────────────────────┐
│  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  │  ← Shimmer effect
│  ▓▓▓▓▓▓  ▓▓▓▓▓▓       │
│  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  │
└─────────────────────────┘
```

### After Loading (Content)
```
┌─────────────────────────┐
│  Product Image          │  ← Actual content
│  Product Title          │
│  $29.99                 │
└─────────────────────────┘
```

---

## Expected Behavior Summary

| Screen | News Ticker | Loading Skeleton | Pull-to-Refresh | Error Handling |
|--------|-------------|------------------|-----------------|----------------|
| Home | ✅ | ✅ | ✅ | ✅ |
| Products | ✅ | ✅ Grid | ✅ | ✅ |
| Search | ✅ | ✅ List | ❌ | ✅ |
| Orders | ✅ | ✅ Cards | ✅ | ✅ |
| Cart | ✅ | ❌ | ❌ | ✅ |
| Profile | ✅ | ❌ | ❌ | ✅ |
| Checkout | ✅ | ❌ | ❌ | ✅ |

---

## Reporting Issues

If you find bugs during testing, note:
1. Screen/feature affected
2. Steps to reproduce
3. Expected behavior
4. Actual behavior
5. Screenshots/video if possible

---

**Ready to Test!** 🚀

Start with the news ticker visibility check, then move through each loading state screen.

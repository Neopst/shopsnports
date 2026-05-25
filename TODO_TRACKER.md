# ShopsNPorts - Guest & Customer End-to-End + Banner Fixes

## Project Status: In Progress
**Last Updated:** 2026-04-16

---

## Phase 1: Banner Slider Performance Fixes

### Issues Identified
- [ ] Images load slowly, next slide appears before image loads
- [ ] Possible memory issue with image caching
- [ ] No progressive image loading
- [ ] Firebase Storage URL resolution adds latency

### Tasks
1. [ ] Add image caching with `cached_network_image` package
2. [ ] Preload banner images before showing carousel
3. [ ] Add shimmer/skeleton loading with better UX
4. [ ] Optimize Firebase Storage URL resolution (cache download URLs)
5. [ ] Reduce carousel auto-play interval if needed
6. [ ] Add lazy loading for off-screen images

---

## Phase 2: Guest User Flow Verification

### Features
- [ ] Home screen with banners displays correctly
- [ ] News ticker loads and scrolls smoothly
- [ ] Tracking bar is visible and functional
- [ ] Guest can browse public content (FAQ, legal pages)
- [ ] Guest shipping request form works

### Tasks
1. [ ] Test guest user flow in emulator
2. [ ] Verify all public Firestore data loads
3. [ ] Check navigation for guest-specific screens
4. [ ] Test tracking functionality with sample tracking number

---

## Phase 3: Registered Customer (User) Flow Verification

### Features
- [ ] Complete authentication flow (email/phone/Google)
- [ ] User profile creation and management
- [ ] Active shipments dashboard
- [ ] Create shipping request with all fields
- [ ] Shipment history with status updates
- [ ] Invoice viewing

### Tasks
1. [ ] Test user registration flow
2. [ ] Test login/logout functionality
3. [ ] Verify user data saves to Firestore correctly
4. [ ] Test shipment creation end-to-end
5. [ ] Verify shipment status updates reflect in user view
6. [ ] Test admin approval workflow for shipments

---

## Phase 4: Admin Dashboard Integration

### Features
- [ ] Admin can view all customer shipping requests
- [ ] Admin can update shipment status
- [ ] Admin can manage banners
- [ ] Admin can manage customers

### Tasks
1. [ ] Verify admin can see all shipments
2. [ ] Test status update workflow (User creates → Admin sees → Admin updates)
3. [ ] Test banner CRUD operations
4. [ ] Verify customer list and details

---

## Phase 5: APK Build & Testing Preparation

### Tasks
1. [ ] Update `firebase_options.dart` with production keys
2. [ ] Configure release signing (keystore)
3. [ ] Update `AndroidManifest.xml` for production
4. [ ] Build debug APK for testing
5. [ ] Test on physical Android device
6. [ ] Verify both guest and customer flows work

---

## Known Issues (Technical Debt)

### Banner Slider Issues
- [ ] `_resolveImageUrl` called on every build
- [ ] No image compression on upload
- [ ] Carousel auto-play doesn't wait for image load

### Authentication Issues
- [ ] Role service hardcoded for admin
- [ ] Email verification not enforced

### Data Model Issues
- [ ] Banner field naming inconsistency (`imageUrl` vs `image_url`)

---

## Progress Log

### 2026-04-16
- Initial todo tracker created
- Completed project exploration
- Identified key issues with banner loading
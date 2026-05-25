# Testing Guide - AWS ECS Integration

**Date:** December 22, 2025  
**Status:** Ready for Testing

---

## ✅ Completed Configuration

### 1. API Configuration Updated
- ✅ Created [`lib/utils/api_config.dart`](lib/utils/api_config.dart) with AWS ECS endpoints
- ✅ Updated [`lib/utils/server_host.dart`](lib/utils/server_host.dart) to point to production
- ✅ Updated [`lib/services/affiliate_api.dart`](lib/services/affiliate_api.dart) to use AWS backend
- ✅ Created [`lib/services/api_service.dart`](lib/services/api_service.dart) for centralized API calls

### 2. Backend Configuration
- ✅ AWS ECS API: `http://marketplace-api-alb-1242236330.us-east-1.elb.amazonaws.com`
- ✅ Firebase Project: `shopsnports`
- ✅ Firebase config files present:
  - `android/app/google-services.json`
  - `ios/Runner/GoogleService-Info.plist`

---

## 🧪 Testing Checklist

### Phase 1: Authentication (CRITICAL - Test First)
```bash
# Run the app
flutter run
```

**Test Steps:**
1. [ ] Launch app on Android emulator or device
2. [ ] Try to sign up with a new email/password
3. [ ] Verify Firebase authentication succeeds
4. [ ] Check that user is logged in
5. [ ] Try logout and login again
6. [ ] Test Google Sign-In (if implemented)

**Expected Result:** User should be able to create account and login successfully.

---

### Phase 2: Customer Features

#### Browse Products
1. [ ] Open home screen
2. [ ] Verify products load from backend
3. [ ] Test category filtering
4. [ ] Test search functionality
5. [ ] View product details

#### Shopping Cart
1. [ ] Add product to cart
2. [ ] Update quantity in cart
3. [ ] Remove item from cart
4. [ ] Verify cart persists after app restart

#### Checkout
1. [ ] Proceed to checkout
2. [ ] Select shipping address
3. [ ] Select payment method
4. [ ] Create order
5. [ ] Verify order appears in order history

---

### Phase 3: Vendor Features

1. [ ] Register as vendor
2. [ ] Login to vendor account
3. [ ] Create a new product with:
   - Name, description, price
   - Upload product images
   - Select category
4. [ ] View vendor dashboard
5. [ ] Check product listings
6. [ ] View incoming orders (if any)
7. [ ] Update order status

---

### Phase 4: Affiliate Features

1. [ ] Register as affiliate
2. [ ] Login to affiliate account
3. [ ] Generate affiliate link for shipping
4. [ ] View affiliate dashboard
5. [ ] Check commission stats
6. [ ] View referral history

---

## 🐛 Troubleshooting

### If you get connection errors:

1. **Check backend is running:**
   ```bash
   curl http://marketplace-api-alb-1242236330.us-east-1.elb.amazonaws.com/health
   ```

2. **Check Firebase authentication:**
   - Verify Firebase console shows the user was created
   - Check Firebase Auth rules allow sign-up

3. **Enable debug logging:**
   Add to your main.dart:
   ```dart
   import 'package:http/http.dart' as http;
   
   void main() {
     debugPrint('API Base URL: ${ApiConfig.baseUrl}');
     runApp(MyApp());
   }
   ```

4. **Check network connectivity:**
   - Emulator must have internet access
   - Try pinging the AWS endpoint from terminal

---

## 🔧 Switch Between Development and Production

### Use Local Server (Development):
Edit [`lib/utils/server_host.dart`](lib/utils/server_host.dart):
```dart
const bool kUseLocalServer = true;  // Change to true
```

### Use AWS ECS (Production):
```dart
const bool kUseLocalServer = false;  // Keep as false
```

---

## 📱 Build Instructions

### Android APK (for testing):
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle (for Play Store):
```bash
flutter build appbundle --release
```
Output: `build/app/outputs/bundle/release/app-release.aab`

### iOS (requires Mac):
```bash
flutter build ios --release
# Then open in Xcode to archive and export
```

---

## 🚀 Next Steps After Testing

1. **If tests pass:**
   - Create Play Store developer account
   - Create App Store developer account
   - Prepare app store assets (screenshots, descriptions)
   - Submit for review

2. **If tests fail:**
   - Document specific errors
   - Check backend logs in AWS CloudWatch
   - Verify API endpoints match documentation
   - Test individual API endpoints with Postman

---

## 📊 Monitoring

### Check Backend Logs:
```bash
aws logs tail /ecs/marketplace-api --follow --region us-east-1
```

### Check ECS Service Status:
```bash
aws ecs describe-services \
  --cluster marketplace-api-cluster \
  --services marketplace-api-task-service-siq7bzxe \
  --region us-east-1
```

---

## 📞 Support

If you encounter issues:
1. Check [`MOBILE_APP_BACKEND_ROUTES.md`](MOBILE_APP_BACKEND_ROUTES.md) for API documentation
2. Review [`MOBILE_APP_DEPLOYMENT_HANDOFF.md`](MOBILE_APP_DEPLOYMENT_HANDOFF.md) for deployment details
3. Test API endpoints directly using curl or Postman
4. Check Firebase console for authentication issues

---

**Good luck with testing! 🎉**

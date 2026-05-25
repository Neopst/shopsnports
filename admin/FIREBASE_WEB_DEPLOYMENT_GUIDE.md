# Firebase Web Deployment Guide
## Flutter Admin Dashboard - Firebase Hosting Only

---

## Project Configuration

**Location:** `c:\projects\admin`
**Framework:** Flutter/Dart
**Deployment:** Firebase Hosting (Web)
**Firebase Project:** shopsnports
**Admin UID:** V7szNk8qaSZJx6ZSJX2hQs5PLwQ2

---

## Active Feature Modules (17)

The admin dashboard now contains these modules:

### Core Features
1. **auth** - Authentication & User Profile
2. **dashboard** - Overview Screen
3. **super_admin_profile** - Super Admin Management
4. **settings** - Settings Dashboard
5. **admin_profile** - Admin Profile Management

### Shipping & Freight (Core Business)
6. **shipping** - Shipment Requests Management
7. **orders** - Orders Dashboard (Read-Only View)

### Customer & Affiliate Management
8. **customers** - Customer Management
9. **affiliates** - Affiliate Marketing Program
10. **payouts** - Affiliate Payouts & Commissions

### Financial
11. **invoices** - Invoice Management

### Communication
12. **notifications** - System Notifications
13. **push_notifications** - Push Notification Management
14. **news_ticker** - News Ticker

### Analytics & Content
15. **analytics** - Analytics Dashboard
16. **content** - Content Management
17. **no_access** - Access Denied Screen

---

## Removed Modules

These e-commerce modules were removed as they don't align with shipping/freight business:
- ❌ products
- ❌ vendors
- ❌ reviews
- ❌ marketplace

---

## Deployment Scripts

### 1. Full Deployment (Clean Build)

```powershell
.\deploy-firebase-web.ps1
```

**Steps:**
1. Cleans previous builds
2. Gets dependencies
3. Builds Flutter web (release mode)
4. Deploys to Firebase Hosting

**Use when:** First deployment or after major changes

### 2. Quick Redeploy

```powershell
.\redeploy-firebase-web.ps1
```

**Steps:**
1. Builds Flutter web (release mode)
2. Deploys to Firebase Hosting

**Use when:** Quick updates, no dependency changes

---

## Manual Deployment Steps

### Step 1: Clean Build
```powershell
cd c:\projects\admin
flutter clean
flutter pub get
```

### Step 2: Build for Web
```powershell
flutter build web --release --web-renderer html
```

**Output:** `build/web/` directory

### Step 3: Deploy to Firebase
```powershell
firebase deploy --only hosting
```

---

## Firebase Hosting Configuration

**File:** `firebase.json`

```json
{
  "hosting": {
    "public": "build/web",
    "ignore": [
      ".firebase",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ]
  }
}
```

**Key Settings:**
- `public: "build/web"` - Deploys Flutter web build output
- `rewrites` - SPA routing (all routes go to index.html)

---

## Testing Before Deployment

### 1. Local Development Server
```powershell
flutter run -d chrome --web-port=8080
```

**Access:** http://localhost:8080

### 2. Local Production Build
```powershell
flutter build web --release --web-renderer html
firebase serve --only hosting
```

**Access:** http://localhost:5000

---

## Post-Deployment Checklist

After deploying, verify these features work:

- [ ] Admin can login with UID: V7szNk8qaSZJx6ZSJX2hQs5PLwQ2
- [ ] Dashboard overview loads
- [ ] Shipping requests module works
- [ ] Orders module displays data
- [ ] Customers module accessible
- [ ] Affiliates management works
- [ ] Payouts processing functional
- [ ] Invoices CRUD operations
- [ ] Push notifications sending
- [ ] News ticker updates
- [ ] Analytics dashboard displays
- [ ] Super Admin can create new admins
- [ ] Settings configuration works

---

## Firestore Rules

The admin dashboard requires these Firestore permissions:

```javascript
// Admins collection - verify admin status
match /admins/{adminId} {
  allow read: if request.auth != null && request.auth.uid == adminId;
}

// Shipments collection - full CRUD for admins
match /shipments/{shipmentId} {
  allow read, write: if isAdmin();
}

// Customers collection - read for admins
match /customers/{customerId} {
  allow read: if isAdmin();
}

// Affiliates collection - admin management
match /affiliates/{affiliateId} {
  allow read, write: if isAdmin();
}

// Helper function
function isAdmin() {
  return request.auth != null && 
         exists(/databases/$(database)/documents/admins/$(request.auth.uid)) &&
         get(/databases/$(database)/documents/admins/$(request.auth.uid)).data.status == 'active';
}
```

---

## Admin Customer Types

The system supports three customer types:

1. **Registered Customers** (🟢)
   - Mobile app users with accounts
   - Can upload profile photos
   - Avatar: Photo URL or initials

2. **Affiliate Customers** (🔵)
   - Marketing partners
   - Earn commissions on referrals
   - Track with affiliateCode

3. **Guest Customers** (⚪)
   - One-time orders
   - No account required
   - Avatar: Initials only

---

## Shipping Services

**Air Freight:**
- Air General
- Air Express
- Air Perishable

**Sea Freight:**
- Sea FCL (Full Container Load)
- Sea LCL (Less than Container Load)
- Sea Bulk
- Sea RoRo (Roll-on/Roll-off)

**Special Services:**
- Specialised Cargo
- Hazardous Materials
- Fragile Items
- Document Shipping

**Note:** No land shipping options (removed from system)

---

## Environment Variables

**File:** `env.json` (not committed to git)

Required variables:
- Firebase configuration (from firebase.json)
- Admin UID for super admin access
- API keys for third-party services

---

## Troubleshooting

### Build Fails

```powershell
flutter clean
flutter pub get
flutter pub upgrade --major-versions
flutter build web --release --web-renderer html
```

### Deployment Fails

Check Firebase CLI authentication:
```powershell
firebase login
firebase projects:list
firebase use shopsnports
```

### App Won't Load

1. Check Firebase Hosting URL
2. Verify Firestore rules deployed
3. Check browser console for errors
4. Verify Firebase config in web/index.html

### Routes Not Working

1. Check firebase.json rewrites configuration
2. Verify go_router setup in lib/core/routing/app_router.dart
3. Check sidebar_navigation.dart routes

---

## Monitoring & Logs

### Firebase Hosting Logs
```powershell
firebase hosting:channel:list
```

### Flutter Web Console
- Open browser DevTools (F12)
- Check Console tab for errors
- Check Network tab for API calls

### Firestore Usage
- Firebase Console → Firestore → Usage tab
- Monitor reads/writes/deletes
- Check for quota limits

---

## Rollback Procedure

### Revert to Previous Deployment
```powershell
firebase hosting:clone SOURCE_SITE_ID:SOURCE_CHANNEL_ID TARGET_SITE_ID:live
```

### Restore from Backup
1. Git checkout previous commit
2. Run `flutter build web --release`
3. Deploy with `firebase deploy --only hosting`

---

## Backup Strategy

### Code Backup
- Git repository with version control
- Regular commits to remote
- Tagged releases for production

### Database Backup
- Firestore automatic daily backups (Firebase Console)
- Export collections before major updates
- Keep backup of firestore.rules and firestore.indexes.json

---

## Next Steps

1. ✅ Remove e-commerce modules (products, vendors, reviews, marketplace)
2. ✅ Remove ECS deployment dependencies
3. ✅ Clean up import references
4. ✅ Fix compilation errors
5. ⏳ Test local build with `flutter run -d chrome`
6. ⏳ Deploy to Firebase Hosting with `.\deploy-firebase-web.ps1`
7. ⏳ Verify all 17 modules work in production
8. ⏳ Update Firestore rules if needed
9. ⏳ Monitor performance and usage
10. ⏳ Implement shipping module enhancements (avatars, pagination, customer types)

---

## Support & Resources

**Flutter Documentation:** https://docs.flutter.dev/deployment/web
**Firebase Hosting Docs:** https://firebase.google.com/docs/hosting
**Go Router Package:** https://pub.dev/packages/go_router
**Riverpod State Management:** https://riverpod.dev

---

**Last Updated:** $(Get-Date -Format "yyyy-MM-dd HH:mm")
**Project Status:** Ready for Firebase Hosting deployment
**Deployment Method:** Firebase Hosting (Web) - ECS fully removed

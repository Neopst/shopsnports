# Flutter Admin Dashboard - Quick Start Guide

**Project Location:** `c:\projects\admin`

---

## Quick Commands

### Development
```powershell
# Start local dev server
flutter run -d chrome --web-port=8080

# Access at: http://localhost:8080
```

### Testing
```powershell
# Analyze code
flutter analyze

# Run tests
flutter test

# Format code
dart format .
```

### Deployment
```powershell
# Full deployment (clean build)
.\deploy-firebase-web.ps1

# Quick redeploy (faster)
.\redeploy-firebase-web.ps1

# Manual build only
flutter build web --release --web-renderer html
```

---

## Project Structure

```
c:\projects\admin\
├── lib\
│   ├── core\              # Core utilities, routing, API clients
│   ├── features\          # 17 feature modules
│   └── main.dart          # Entry point
├── web\                   # Web-specific files
├── build\web\             # Build output (git ignored)
├── firebase.json          # Firebase config
├── firestore.rules        # Database rules
└── pubspec.yaml           # Dependencies
```

---

## Active Modules (17)

1. **auth** - Login/Logout/Profile
2. **dashboard** - Overview screen with metrics
3. **super_admin_profile** - Create/manage admins
4. **admin_profile** - Edit admin profile
5. **settings** - App settings
6. **shipping** - Air & sea freight shipments
7. **orders** - Read-only orders view
8. **customers** - Customer management
9. **affiliates** - Affiliate program
10. **payouts** - Commission payouts
11. **invoices** - Invoice CRUD
12. **notifications** - System notifications
13. **push_notifications** - Send push notifications
14. **news_ticker** - News ticker management
15. **analytics** - Analytics dashboard
16. **content** - Content management
17. **no_access** - Access denied screen

---

## Admin Access

**Super Admin UID:** `V7szNk8qaSZJx6ZSJX2hQs5PLwQ2`
**Firebase Project:** shopsnports

Login at: `https://YOUR-FIREBASE-PROJECT.web.app/`

---

## Customer Types

| Type | Badge | Description |
|------|-------|-------------|
| Registered | 🟢 | Mobile app users with accounts |
| Affiliate | 🔵 | Marketing partners earning commissions |
| Guest | ⚪ | One-time orders, no account |

---

## Shipping Services

### Air Freight
- Air General
- Air Express
- Air Perishable

### Sea Freight
- Sea FCL (Full Container Load)
- Sea LCL (Less than Container Load)
- Sea Bulk
- Sea RoRo

### Special
- Specialised Cargo
- Hazardous Materials
- Fragile Items
- Documents

---

## Common Tasks

### Add New Feature Module
1. Create folder: `lib/features/your_module/`
2. Add to routing: `lib/core/routing/app_router.dart`
3. Add to sidebar: `lib/features/dashboard/presentation/widgets/sidebar_navigation.dart`
4. Update dependencies: `flutter pub get`

### Update Dependencies
```powershell
flutter pub upgrade --major-versions
```

### Clear Build Cache
```powershell
flutter clean
flutter pub get
```

---

## Troubleshooting

### App won't compile
```powershell
flutter clean
flutter pub get
flutter pub upgrade
```

### Deployment fails
```powershell
firebase login
firebase use shopsnports
firebase deploy --only hosting
```

### Routes not working
Check `lib/core/routing/app_router.dart` and `sidebar_navigation.dart`

---

## Documentation

- **FIREBASE_WEB_DEPLOYMENT_GUIDE.md** - Full deployment guide
- **CLEANUP_SUMMARY.md** - Recent changes & cleanup
- **README.md** - Project overview

---

## Support

**Flutter Docs:** https://docs.flutter.dev
**Firebase Docs:** https://firebase.google.com/docs
**Riverpod:** https://riverpod.dev
**Go Router:** https://pub.dev/packages/go_router

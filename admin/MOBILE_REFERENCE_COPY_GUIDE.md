# Mobile App - Reference Copy Guide

## What to Copy from Web App

### 1. Data Models (MUST COPY)
```
admin/lib/features/super_admin/data/models/
├── admin_user.dart                 ← Admin profile structure
├── admin_permissions.dart          ← Permission model
├── admin_activity_log.dart         ← Activity log structure
└── admin_permissions.dart
```

**Why**: Mobile uses exact same data structures

---

### 2. Integration Guide (MUST READ)
```
admin/MOBILE_APP_BACKEND_INTEGRATION_GUIDE.md
```

**Contains**:
- Firebase setup code
- Firestore queries
- Cloud Function calls
- Quick start examples
- Common issues & solutions

---

### 3. Seeder Pattern (REFERENCE)
```
admin/lib/features/super_admin/data/repositories/super_admin_seeder.dart
```

**Use**: As template for your mobile auth flow

---

### 4. Screenshot Reference (OPTIONAL)
Test the web app first, then replicate UI in mobile:

**Screens to Reference**:
- Dashboard with stats
- Admin list
- Admin profile
- Activity logs
- Create admin dialog

---

## Folder Structure Recommendation

```
mobile/
├── lib/
│   ├── features/
│   │   ├── auth/
│   │   │   ├── screens/
│   │   │   │   └── login_screen.dart
│   │   │   └── providers/
│   │   │       └── auth_providers.dart
│   │   └── super_admin/
│   │       ├── models/
│   │       │   ├── admin_user.dart (✅ COPY from web)
│   │       │   ├── admin_permissions.dart (✅ COPY from web)
│   │       │   └── admin_activity_log.dart (✅ COPY from web)
│   │       ├── screens/
│   │       │   ├── dashboard_screen.dart
│   │       │   ├── admin_list_screen.dart
│   │       │   ├── admin_profile_screen.dart
│   │       │   └── activity_logs_screen.dart
│   │       └── providers/
│   │           └── admin_providers.dart
│   └── main.dart
├── pubspec.yaml
├── android/
├── ios/
└── README.md
```

---

## Data Models to Copy

### 1. admin_user.dart
```dart
enum AdminRole { super_admin, admin }
enum AdminStatus { active, disabled }

class AdminUser {
  final String id;
  final String email;
  final String displayName;
  final AdminRole role;
  final AdminStatus status;
  final AdminPermissions permissions;
  // ... more fields
}
```

### 2. admin_permissions.dart
```dart
class AdminModule {
  final String id;
  final String displayName;
  final String description;
  // ...
}

class AdminPermissions {
  final Map<String, bool> permissions;
  // ...
}
```

### 3. admin_activity_log.dart
```dart
class AdminActivityLog {
  final String id;
  final String adminId;
  final String adminEmail;
  final String action;
  final DateTime timestamp;
  final bool success;
  // ...
}
```

---

## Quick Implementation Path

### Week 1
- [ ] Copy models from web app
- [ ] Set up Firebase + auth
- [ ] Implement login with seeder
- [ ] Build dashboard screen

### Week 2
- [ ] Build admin list screen
- [ ] Build admin profile screen
- [ ] Build activity logs screen
- [ ] Implement create admin feature

### Week 3
- [ ] Testing & refinement
- [ ] Performance optimization
- [ ] Polish UI for mobile
- [ ] Deploy to test devices

---

## Commands to Remember

### Copy Models
```bash
# From admin (web app root)
cp -r lib/features/super_admin/data/models /path/to/mobile/lib/features/super_admin/data/
```

### Read Integration Guide
```bash
cat admin/MOBILE_APP_BACKEND_INTEGRATION_GUIDE.md
```

### Copy Reference Files
```bash
cp admin/lib/features/super_admin/data/repositories/super_admin_seeder.dart mobile/docs/
cp admin/MOBILE_APP_BACKEND_INTEGRATION_GUIDE.md mobile/docs/
```

---

## Firebase Project Configuration

Mobile app connects to **same Firebase project** as web app:

```json
{
  "google_services.json" (Android) or
  "GoogleService-Info.plist" (iOS)
  ↓
  Same Firebase Project
  ↓
  Same Firestore Database
  ↓
  Same Collections: users, activity_logs
}
```

**No separate backend needed** - reuse everything!

---

## Authentication Flow

**Mobile**:
```
Login Screen
    ↓
Firebase Auth.signIn(email, password)
    ↓
Seed Super Admin Profile (if new user)
    ↓
Read User from Firestore
    ↓
Dashboard
```

**Exact same flow** as web app

---

## Firestore Collections Used

### users/{uid}
```json
{
  "id": "firebase_uid",
  "email": "admin@example.com",
  "displayName": "Admin Name",
  "role": "super_admin",
  "status": "active",
  "permissions": {...},
  "createdAt": timestamp,
  "lastLogin": timestamp
}
```

### activity_logs/{logId}
```json
{
  "adminId": "uid",
  "adminEmail": "admin@example.com",
  "action": "created_admin",
  "timestamp": timestamp,
  "success": true
}
```

---

## Getting Started Checklist

- [ ] Copy `MOBILE_APP_BACKEND_INTEGRATION_GUIDE.md` to mobile folder
- [ ] Copy models from `lib/features/super_admin/data/models/` 
- [ ] Copy `super_admin_seeder.dart` pattern to mobile auth
- [ ] Set up Firebase in mobile project
- [ ] Implement login screen
- [ ] Test login + profile seeding
- [ ] Verify Firestore data populates
- [ ] Start building admin screens

---

## References

**Saved in admin/ root**:
- ✅ `MOBILE_APP_BACKEND_INTEGRATION_GUIDE.md` - Complete integration guide
- ✅ `SUPER_ADMIN_AUDIT_AND_RECOMMENDATIONS.md` - Full audit details
- ✅ `SUPER_ADMIN_GO_AHEAD_FOR_MOBILE.md` - Executive summary
- ✅ `SEEDER_INTEGRATION_COMPLETE.md` - Seeder setup info

**Copy these to mobile/docs/ for reference**

---

**Status**: ✅ Web app ready - Mobile app can start anytime!

# Mobile App Integration Guide

## What Mobile App Needs to Know

The mobile app will connect to the exact same Firebase/Firestore backend. Here's what's available:

---

## 🔐 Authentication

**Provider**: Firebase Authentication  
**Methods**: Email/Password (already set up)

```
Endpoint: Firebase Auth
- Sign up new admin
- Sign in with email/password
- Get current user UID
- Sign out
```

---

## 📊 Data Collections Available

### 1. **Users Collection** (`users/{uid}`)
**Used for**: Admin profiles, permissions, status

```json
{
  "id": "user_uid",
  "email": "admin@example.com",
  "displayName": "Admin Name",
  "role": "super_admin",  // or "admin"
  "status": "active",     // or "disabled"
  "permissions": {
    "permissions": {
      "module_1": true,
      "module_2": false,
      ...
    }
  },
  "createdAt": Timestamp,
  "lastLogin": Timestamp,
  "requirePasswordChange": false
}
```

**Mobile Can**:
- ✅ Read current user profile
- ✅ List all admins (if super admin)
- ✅ Stream real-time admin updates
- ✅ Check user permissions

---

### 2. **Activity Logs Collection** (`activity_logs/{logId}`)
**Used for**: Tracking admin actions

```json
{
  "adminId": "uid",
  "adminEmail": "admin@example.com",
  "action": "created_admin",
  "itemId": "target_admin_id",
  "itemName": "New Admin Name",
  "timestamp": Timestamp,
  "success": true,
  "details": {
    "targetAdminId": "...",
    ...
  }
}
```

**Actions Tracked**:
- `created_admin`
- `updated_admin`
- `deleted_admin`
- `updated_permissions`
- `suspended_admin`
- `activated_admin`
- `updated_profile`

**Mobile Can**:
- ✅ Stream activity logs
- ✅ Filter by admin
- ✅ Filter by action
- ✅ View activity details

---

## 🔧 Cloud Functions Available

### 1. **createAdmin** (Callable)
```dart
// Parameters
{
  "email": "newadmin@example.com",
  "displayName": "New Admin",
  "role": "admin",  // or "super_admin"
  "permissions": {
    "module_1": true,
    "module_2": false,
  }
}

// Returns
{
  "success": true,
  "userId": "new_user_uid",
  "tempPassword": "generated_password",
  "message": "Admin created successfully"
}
```

### 2. **updateAdminPermissions** (Callable)
```dart
{
  "adminId": "target_admin_uid",
  "permissions": {
    "module_1": true,
    "module_2": true,
  }
}

// Returns
{
  "success": true,
  "message": "Permissions updated"
}
```

### 3. **deleteAdmin** (Callable)
```dart
{
  "adminId": "target_admin_uid"
}

// Returns
{
  "success": true,
  "message": "Admin deleted permanently"
}
```

---

## 🔒 Firestore Security Rules

Mobile app is protected by these rules:

```
✅ Users can read their own profile
✅ Admins can read all admin profiles
✅ Super admins can create/update/delete admins
✅ Activity logs are protected by admin role
✅ Authenticated users only
```

---

## 📋 Mobile Implementation Checklist

### Phase 1: Auth Integration
- [ ] Set up Firebase Auth in mobile app
- [ ] Create login/signup screens
- [ ] Store auth token
- [ ] Implement logout

### Phase 2: Admin Data Access
- [ ] Stream users collection
- [ ] Stream activity logs collection
- [ ] Implement admin list screen
- [ ] Implement admin detail screen
- [ ] Implement profile screen

### Phase 3: Admin Management (If Super Admin)
- [ ] Implement create admin screen
- [ ] Call createAdmin Cloud Function
- [ ] Implement edit permissions screen
- [ ] Call updateAdminPermissions Cloud Function
- [ ] Implement delete admin functionality

### Phase 4: Optional Enhancements
- [ ] Caching of admin data
- [ ] Offline support
- [ ] Push notifications for new admins
- [ ] Export logs to CSV

---

## 🚀 Quick Start for Mobile Team

### 1. Install Flutter Packages
```yaml
dependencies:
  firebase_core: ^latest
  firebase_auth: ^latest
  cloud_firestore: ^latest
  firebase_storage: ^latest  # Optional
```

### 2. Initialize Firebase
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}
```

### 3. Authenticate User
```dart
final FirebaseAuth _auth = FirebaseAuth.instance;

Future<void> signIn(String email, String password) async {
  try {
    UserCredential result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    User? user = result.user;
    // user.uid is the admin ID
  } catch (e) {
    print('Error: $e');
  }
}
```

### 4. Read Admin Profile
```dart
final FirebaseFirestore _firestore = FirebaseFirestore.instance;

Stream<Map<String, dynamic>> getAdminProfile(String uid) {
  return _firestore
    .collection('users')
    .doc(uid)
    .snapshots()
    .map((doc) => doc.data() ?? {});
}
```

### 5. Stream Activity Logs
```dart
Stream<List<Map<String, dynamic>>> getActivityLogs() {
  return _firestore
    .collection('activity_logs')
    .orderBy('timestamp', descending: true)
    .limit(100)
    .snapshots()
    .map((snapshot) {
      return snapshot.docs
        .map((doc) => doc.data())
        .toList();
    });
}
```

### 6. Call Cloud Function
```dart
final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable(
  'createAdmin',
);

final result = await callable.call({
  'email': 'newadmin@example.com',
  'displayName': 'New Admin',
  'role': 'admin',
  'permissions': {
    'module_1': true,
  },
});

print('New admin ID: ${result.data['userId']}');
```

---

## 📱 UI Components to Build

### Screens
1. **Login Screen**
   - Email/password input
   - Error handling
   - Loading state

2. **Dashboard**
   - Welcome message
   - Quick stats (if super admin)
   - Recent activities

3. **Admin Profile**
   - Display user info
   - Show permissions (modules)
   - Display role and status

4. **Activity Feed**
   - List of admin actions
   - Filter options
   - Timestamps
   - Action details

5. **Create Admin** (If Super Admin Only)
   - Email input
   - Display name
   - Role selector
   - Permission checkboxes

---

## 🔄 Data Flow

```
┌──────────────────┐
│   Mobile App     │
└────────┬─────────┘
         │
    [Firebase Auth]
         │
    User Logs In
         │
┌────────▼──────────────────┐
│   Cloud Firestore         │
├───────────────────────────┤
│ • users/uid → Profile     │
│ • activity_logs → Logs    │
└────────┬──────────────────┘
         │
   [Cloud Functions]
         │
  Create/Update/Delete
    Admin Operations
         │
    ✅ Update Firestore
```

---

## ✅ What's Ready for Mobile

- ✅ Firebase project configured
- ✅ Firestore collections created
- ✅ Security rules in place
- ✅ Cloud Functions deployed
- ✅ Admin model defined
- ✅ Authentication ready
- ✅ Activity logging ready

---

## ⏰ Estimated Mobile Dev Timeline

| Phase | Tasks | Duration |
|-------|-------|----------|
| 1 | Auth setup + login screen | 2-3 days |
| 2 | Profile & dashboard screens | 3-4 days |
| 3 | Admin list & activity feed | 3-4 days |
| 4 | Admin management features | 2-3 days |
| 5 | Testing & refinement | 2-3 days |
| **Total** | | **2-3 weeks** |

---

## 🆘 Common Issues & Solutions

### Issue: "Permission denied" errors
**Solution**: Check user role in Firestore rules, ensure user is super admin for certain operations

### Issue: Data not updating in real-time
**Solution**: Ensure StreamBuilder/StreamProvider is properly watching Firestore stream

### Issue: Cloud Function not found
**Solution**: Deploy functions, check region matches, ensure function name is correct

### Issue: Auth token expired
**Solution**: Firebase Auth handles this automatically, but handle 'unauthenticated' errors

---

## 📞 Support

If mobile team needs:
- Firestore schema details → See this document
- Cloud Function signatures → Check functions/index.js
- Firestore rules → Check firestore.rules
- Data model definitions → Check admin_user.dart, admin_permissions.dart
- Example implementations → Check web app screens

---

**Status**: ✅ Backend ready for mobile integration
**Last Updated**: January 30, 2026

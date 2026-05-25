# Firebase Cloud Functions - Deployment & Integration Guide

**Status**: ✅ Functions Created & Deployed (01/31/2026)
**Location**: `c:\projects\admin\functions\seedNotifications.js`
**Deployment Command**: `firebase deploy --only functions`

---

## 📋 Deployed Functions Overview

### 1. **seedNotificationCollections()** - HTTP Endpoint
**Purpose**: One-time seeding of all notification-related Firestore collections

**Endpoint**: `https://<region>-<project>.cloudfunctions.net/seedNotificationCollections`

**What It Seeds**:
- ✅ **push_notifications** (7 templates)
  - `shipping_update`: Shipment status changes
  - `shipping_delivered`: Delivery confirmation
  - `affiliate_earnings`: Commission notifications
  - `affiliate_payout`: Payout notifications
  - `affiliate_approved`: Affiliate approval
  - `system_alert`: System announcements
  - `promo_offer`: Promotional content

- ✅ **news_ticker** (3 items)
  - Welcome message
  - Worldwide shipping announcement
  - Affiliate program notice

- ✅ **banners** (3 items)
  - Shipper Dashboard promo
  - Affiliate Program banner
  - Fast Shipping banner

- ✅ **content_pages** (3 pages)
  - `how-it-works`: Feature explanation
  - `about`: Company info
  - `faq`: Common questions

- ✅ **notification_settings** (auto-generated per user)
  - Default preferences for all existing users
  - Created automatically on user signup

**Response Example**:
```json
{
  "success": true,
  "message": "Notification collections seeded successfully",
  "summary": {
    "push_notifications": 7,
    "news_ticker": 3,
    "banners": 3,
    "content_pages": 3,
    "notification_settings": 45
  }
}
```

**How to Call**:
```bash
# From Firebase Console -> Functions
# Or via curl:
curl -X POST https://<region>-<project>.cloudfunctions.net/seedNotificationCollections
```

---

### 2. **createNotificationSettingsOnUserCreate()** - Auth Trigger
**Purpose**: Auto-creates notification preferences when new user signs up

**Trigger**: `onCreate` - Firebase Authentication user creation

**Automatically Sets**:
```javascript
{
  userId: user.uid,
  pushEnabled: true,
  emailEnabled: true,
  inAppEnabled: true,
  types: {
    shipping: true,
    affiliate: true,
    system: true,
    promotional: false
  },
  frequency: "immediate",
  quietHours: { enabled: false, start: "22:00", end: "08:00" },
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

**No Manual Setup Required**: Runs automatically on signup

---

### 3. **sendNotification()** - Callable Cloud Function
**Purpose**: Mobile app creates new notifications in Firestore

**Called From**: Mobile app via `FirebaseFunctions.instance.httpsCallable('sendNotification')`

**Parameters**:
```javascript
{
  userId: "user123",           // Target user
  title: "Shipment Updated",   // Notification title
  message: "Your order...",    // Notification message
  type: "shipping",            // shipping|affiliate|system
  actionUrl: "/shipping/123"   // Optional action link
}
```

**Firestore Document Created**:
```javascript
{
  userId: "user123",
  title: "Shipment Updated",
  message: "Your order...",
  type: "shipping",
  status: "unread",
  actionUrl: "/shipping/123",
  timestamp: Timestamp,
  readAt: null,
  createdAt: Timestamp
}
```

**Return**:
```json
{
  "success": true,
  "notificationId": "doc123"
}
```

---

### 4. **updateNotificationStatus()** - Callable Cloud Function
**Purpose**: Mark notifications as read/archived

**Called From**: Mobile app via `FirebaseFunctions.instance.httpsCallable('updateNotificationStatus')`

**Parameters**:
```javascript
{
  notificationId: "doc123",
  status: "read"  // read|archived|deleted
}
```

**Updates Firestore Document**:
```javascript
{
  status: "read",
  readAt: Timestamp,  // Only if status = "read"
  updatedAt: Timestamp
}
```

**Return**:
```json
{
  "success": true,
  "message": "Notification marked as read"
}
```

---

## 🔐 Security Rules (Updated)

All collections are protected by Firestore security rules in `firestore.rules`:

### notifications
```
- Users can read their own notifications
- Admins can read all notifications
- Authenticated users can create
- Users can update notification status
```

### push_notifications
```
- Users can read templates
- Admins can write/update templates
- Super admins can delete templates
```

### notification_settings
```
- Users can read/update their own settings
- Admins can read all settings
- Authenticated users can create
```

### news_ticker, banners, content_pages
```
- Everyone can read
- Admins can write/update
- Super admins can delete
```

---

## 📱 Mobile App Integration

### In Flutter:

```dart
// Import Firebase Functions
import 'package:cloud_functions/cloud_functions.dart';

// 1. Send Notification
Future<void> sendNotification({
  required String userId,
  required String title,
  required String message,
  String type = 'system',
  String? actionUrl,
}) async {
  try {
    final result = await FirebaseFunctions.instance
        .httpsCallable('sendNotification')
        .call({
          'userId': userId,
          'title': title,
          'message': message,
          'type': type,
          'actionUrl': actionUrl,
        });
    
    print('Notification sent: ${result.data['notificationId']}');
  } catch (e) {
    print('Error sending notification: $e');
  }
}

// 2. Mark Notification as Read
Future<void> markNotificationAsRead(String notificationId) async {
  try {
    await FirebaseFunctions.instance
        .httpsCallable('updateNotificationStatus')
        .call({
          'notificationId': notificationId,
          'status': 'read',
        });
    
    print('Notification marked as read');
  } catch (e) {
    print('Error updating notification: $e');
  }
}

// 3. Listen to User Notifications (Real-time)
Stream<List<Map<String, dynamic>>> getUserNotifications(String userId) {
  return FirebaseFirestore.instance
      .collection('notifications')
      .where('userId', isEqualTo: userId)
      .orderBy('timestamp', descending: true)
      .limit(50)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => {...doc.data(), 'id': doc.id})
          .toList());
}

// 4. Get Notification Settings
Future<Map<String, dynamic>> getNotificationSettings(String userId) async {
  final doc = await FirebaseFirestore.instance
      .collection('notification_settings')
      .doc(userId)
      .get();
  
  return doc.data() ?? {};
}

// 5. Update Notification Settings
Future<void> updateNotificationSettings(
  String userId,
  Map<String, dynamic> settings,
) async {
  await FirebaseFirestore.instance
      .collection('notification_settings')
      .doc(userId)
      .update(settings);
}
```

---

## 🚀 Deployment Checklist

- [x] Cloud Functions written (`seedNotifications.js`)
- [x] Security rules updated (`firestore.rules`)
- [x] Functions deployed to Firebase
- [ ] Seed function called to populate collections
- [ ] Mobile app pubspec.yaml updated with cloud_functions
- [ ] Mobile app notification service implemented
- [ ] Test notification sending via mobile app
- [ ] Test notification reading/marking status
- [ ] Verify real-time updates in UI
- [ ] Performance monitoring enabled
- [ ] Error handling tested

---

## 📊 Data Structure Reference

### notifications
```
/notifications/{notificationId}
  - userId: string
  - title: string
  - message: string
  - type: enum(shipping|affiliate|system|promotional)
  - status: enum(unread|read|archived)
  - actionUrl: string (optional)
  - timestamp: Timestamp
  - readAt: Timestamp (null until read)
  - createdAt: Timestamp
```

### push_notifications
```
/push_notifications/{templateId}
  - name: string (identifier: shipping_update, etc.)
  - title: string
  - message: string (with {placeholders})
  - type: enum(shipping|affiliate|system|promotional)
  - enabled: boolean
  - description: string
  - createdAt: Timestamp
  - updatedAt: Timestamp
```

### notification_settings
```
/notification_settings/{userId}
  - userId: string
  - pushEnabled: boolean
  - emailEnabled: boolean
  - inAppEnabled: boolean
  - types: object
    * shipping: boolean
    * affiliate: boolean
    * system: boolean
    * promotional: boolean
  - frequency: enum(immediate|daily|weekly)
  - quietHours: object
    * enabled: boolean
    * start: time (24h format)
    * end: time (24h format)
  - createdAt: Timestamp
  - updatedAt: Timestamp
```

### news_ticker
```
/news_ticker/{id}
  - title: string
  - content: string
  - priority: number
  - status: enum(published|draft)
  - imageUrl: string (optional)
  - publishedAt: Timestamp
  - createdAt: Timestamp
  - createdBy: string (admin ID)
```

### banners
```
/banners/{id}
  - title: string
  - imageUrl: string
  - link: string (navigation path)
  - status: enum(active|inactive)
  - displayOrder: number
  - startDate: Timestamp
  - endDate: Timestamp
  - createdAt: Timestamp
```

### content_pages
```
/content_pages/{slug}
  - slug: string (how-it-works, about, faq)
  - title: string
  - content: string (HTML)
  - published: boolean
  - createdAt: Timestamp
  - updatedAt: Timestamp
```

---

## 🐛 Troubleshooting

### Function Not Found
- Verify deployment completed: `firebase deploy --list`
- Check Firebase console -> Cloud Functions
- Ensure correct region

### Permission Denied Error
- Check firestore.rules are deployed: `firebase deploy --only firestore:rules`
- Verify user authentication before calling functions
- Check that authenticated user has permission to write to collection

### Collections Empty
- Call `seedNotificationCollections()` endpoint manually
- Check Firebase console -> Cloud Functions -> seedNotificationCollections
- Verify function execution in Firebase console logs

### Real-time Updates Not Working
- Check user has read permission in firestore.rules
- Verify Firestore listener correctly subscribed
- Check network connection and Firebase initialization

---

## 📞 Next Steps

1. **Call seed function** (if not auto-triggered):
   ```bash
   curl -X POST https://<region>-<project>.cloudfunctions.net/seedNotificationCollections
   ```

2. **Update mobile app**:
   - Add cloud_functions to pubspec.yaml
   - Implement notification service
   - Add notification UI screens

3. **Test end-to-end**:
   - Send test notification via function
   - Verify appears in Firestore
   - Confirm real-time update in app
   - Test mark as read functionality

4. **Monitor performance**:
   - Check Cloud Functions logs
   - Monitor Firestore read/write volume
   - Track latency metrics

---

**Created**: 01/31/2026  
**Architecture**: 100% Firebase-native, zero hardcoding  
**Status**: ✅ Ready for mobile app integration

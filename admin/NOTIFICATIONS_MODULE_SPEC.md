## NOTIFICATIONS MODULE SPECIFICATION
## Admin Dashboard - Flutter

### ARCHITECTURE OVERVIEW
- **Database**: ECS (Elasticsearch Cloud / ElasticSearch)
- **Auth**: Firebase Authentication
- **State**: Riverpod (providers, notifiers)
- **Real-time**: Firebase Cloud Messaging (FCM) + Firestore listeners for realtime updates

---

## DATA MODELS

### 1. Notification
```dart
class Notification {
  String id;                    // unique identifier
  String userId;               // recipient (Firebase UID)
  NotificationType type;       // order_status, payment, review, system, message
  NotificationCategory category; // sales, orders, reviews, users, system
  String title;                // "Order Shipped"
  String message;              // full content
  String? actionUrl;           // route to navigate (e.g., /dashboard/orders/123)
  bool isRead;                 // read/unread
  DateTime createdAt;
  DateTime? readAt;
  Map<String, dynamic>? metadata; // contextual data (orderId, customerId, etc.)
  NotificationPriority priority; // low, normal, high, critical
}

enum NotificationType {
  orderStatus,      // order placed, shipped, delivered
  payment,          // payment received, failed, refunded
  review,           // new review submitted
  userActivity,     // new user signup, customer action
  inventory,        // stock low, restock needed
  system,           // maintenance, alerts
  message           // admin messages, announcements
}

enum NotificationCategory {
  sales,            // revenue, orders, payments
  orders,           // order lifecycle
  reviews,          // customer reviews
  users,            // user/vendor activity
  inventory,        // stock management
  system            // system alerts, maintenance
}

enum NotificationPriority {
  low,
  normal,
  high,
  critical          // requires immediate attention
}
```

---

## CORE FEATURES

### A. NOTIFICATION LIST SCREEN (`NotificationsScreen`)
**Components:**
- **AppBar Badge** — shows unread count (red badge on dashboard shell + AppBar icon)
- **Category Filters** — tabs/dropdown (All, Sales, Orders, Reviews, Users, System)
- **Status Filters** — Read/Unread toggle
- **Priority Indicator** — visual badge (color-coded: critical=red, high=orange, normal=gray)
- **Search/Date Range** — search by title, filter by date
- **Notification List** (with grouped timestamps):
  - Today, Yesterday, This Week, Older
  - Row shows: icon, title, truncated message, time, priority, read status
  - Click row → navigate to related resource (order, review, user, etc.)
  - Swipe/hover → Mark as read, Archive, Delete actions
- **Bulk Actions** — select multiple → Mark as Read/Unread, Archive, Delete

**UI Pattern:** Similar to Reviews/Invoices list with checkboxes, filters, card layout

---

### B. NOTIFICATION DETAIL/EXPANSION MODAL
**Triggered by:**
- Clicking a notification row
- Notification badge click in AppBar

**Content:**
- Full message + metadata
- Action button (e.g., "View Order", "View Review", "View User")
- Mark as read/unread toggle
- Archive/Delete option
- Related context (e.g., order details, review snippet, user profile snippet)

---

### C. APPBAR NOTIFICATION ICON
**Placement:** Dashboard shell AppBar (top-right, next to profile menu)

**Features:**
- **Badge with Count** — unread notification count (hide if 0)
- **Click → Dropdown Popover**:
  - Shows last 5–10 unread notifications (scrollable)
  - "View All" link → opens full NotificationsScreen
  - Each item shows title, timestamp, type icon
  - Quick-read snippet
  - Click item → navigate to detail or related resource
  - "Mark All as Read" button at bottom
- **Real-time Updates** — badge count refreshes when new notifications arrive (FCM + Firestore listener)

---

### D. NOTIFICATION SETTINGS/PREFERENCES SCREEN
**Accessible from:** Dashboard settings or notification screen menu

**Toggles per Category:**
- Sales notifications (On/Off)
- Order notifications (On/Off)
- Review notifications (On/Off)
- User activity notifications (On/Off)
- Inventory alerts (On/Off)
- System messages (On/Off)

**Preferences:**
- Email notifications (On/Off per category)
- Push notifications (On/Off, Firebase Cloud Messaging)
- Sound alert (On/Off)
- Quiet hours (e.g., 10 PM – 7 AM, do not disturb)

---

### E. NOTIFICATION ARCHIVE & CLEANUP
**Archive Feature:**
- Swipe or action button → Archive (soft delete, moves to archive list)
- Archive Screen — view past/archived notifications
- Restore from archive

**Auto-Cleanup:**
- Archived notifications deleted after 30 days (configurable)
- Read notifications auto-archived after 7 days (optional user preference)

---

### F. REAL-TIME NOTIFICATIONS
**Push Notifications (FCM):**
- Server sends FCM token when user logs in
- Backend triggers notifications via Firebase Cloud Messaging
- App listens for incoming messages in foreground/background
- Update badge count and local Firestore cache instantly

**Firestore Listener:**
- Listen to `notifications/{userId}` collection
- Auto-update provider when new notification arrives
- Trigger UI refresh (badge count, list update)

---

### G. NOTIFICATION TYPES & USE CASES

#### 1. **Sales Notifications**
- "New order received - $500"
- "Payment received for Order #1234"
- "Refund processed - $200"
- "Daily revenue: $5,000"

#### 2. **Order Notifications**
- "Order #1234 confirmed"
- "Order #1234 shipped - tracking #XYZ"
- "Order #1234 delivered"
- "Order #1234 cancelled by customer"

#### 3. **Review Notifications**
- "New 5-star review: 'Amazing product!'"
- "Review flagged as inappropriate"
- "Vendor response needed on 1 review"

#### 4. **User/Vendor Notifications**
- "New vendor signup - John's Store"
- "New customer registered - Jane Doe"
- "Vendor account suspended (reason: policy violation)"
- "New vendor request to join marketplace"

#### 5. **Inventory Notifications**
- "Stock low: Product X (5 units remaining)"
- "Stock out: Product Y needs restock"
- "Restock received: 100 units of Product Z"

#### 6. **System Notifications**
- "Scheduled maintenance: Nov 25, 10 PM – 11 PM"
- "System backup completed successfully"
- "Security alert: Unusual login from new device"

---

## DATA FLOW & COMMUNICATION

### Creating Notifications (Backend → Client)
1. **Event Trigger** (backend/cloud function):
   - Order placed → create order_status notification
   - Payment received → create payment notification
   - New review → create review notification
   
2. **Save to Firestore**:
   - Store in `notifications/{userId}` collection with metadata
   - Sync to ECS for full-text search & analytics

3. **Send FCM Message**:
   - Push notification to user's device
   - Include title, message, actionUrl, priority

4. **Client Receives**:
   - App listens via Firestore listener
   - Provider updates with new notification
   - Badge count updates
   - User sees toast/banner if foreground

### Marking as Read (Client → Backend)
1. User clicks notification or "Mark as Read" button
2. Client calls `updateNotification(id, {isRead: true, readAt: now})`
3. Backend updates Firestore + ECS
4. Firestore listener triggers, badge count decrements
5. UI updates instantly

### Deleting/Archiving (Client → Backend)
1. User swipes or clicks delete/archive
2. Client calls `archiveNotification(id)` or `deleteNotification(id)`
3. Backend marks as archived/deleted in Firestore + ECS
4. Listener removes from list, badge updates
5. UI updates

---

## REPOSITORY INTERFACE

```dart
abstract class NotificationRepository {
  // Fetch
  Future<List<Notification>> getNotifications({
    int limit = 50,
    int page = 0,
    NotificationCategory? category,
    bool? isRead,
    NotificationPriority? priority,
    DateTime? startDate,
    DateTime? endDate,
  });
  
  // Stream for real-time updates
  Stream<List<Notification>> getNotificationsStream();
  
  // Single notification
  Future<Notification?> getNotificationById(String id);
  
  // Update
  Future<void> updateNotification(String id, Notification notification);
  Future<void> markAsRead(String id);
  Future<void> markAsUnread(String id);
  Future<void> markAllAsRead();
  
  // Delete/Archive
  Future<void> archiveNotification(String id);
  Future<void> deleteNotification(String id);
  Future<void> bulkArchive(List<String> ids);
  
  // Count
  Future<int> getUnreadCount();
  Stream<int> getUnreadCountStream();
  
  // Preferences
  Future<NotificationPreferences> getPreferences();
  Future<void> updatePreferences(NotificationPreferences prefs);
}

class NotificationPreferences {
  bool salesEnabled = true;
  bool ordersEnabled = true;
  bool reviewsEnabled = true;
  bool usersEnabled = true;
  bool inventoryEnabled = true;
  bool systemEnabled = true;
  bool emailNotifications = false;
  bool pushNotifications = true;
  bool soundAlert = true;
  TimeOfDay? quietHoursStart;  // null = disabled
  TimeOfDay? quietHoursEnd;
}
```

---

## RIVERPOD PROVIDERS

```dart
// Repository provider
final notificationRepositoryProvider = Provider<NotificationRepository>(...);

// List provider with filters
final notificationsProvider = FutureProvider.family<List<Notification>, Map>(...);

// Real-time stream
final notificationsStreamProvider = StreamProvider<List<Notification>>(...);

// Unread count (real-time)
final unreadCountProvider = StreamProvider<int>(...);

// Current notification (for detail view)
final selectedNotificationProvider = StateProvider<Notification?>(...);

// Preferences
final notificationPreferencesProvider = FutureProvider<NotificationPreferences>(...);

// Filter state
final notificationCategoryFilterProvider = StateProvider<NotificationCategory?>((_) => null);
final notificationReadFilterProvider = StateProvider<bool?>((_) => null);
final notificationPriorityFilterProvider = StateProvider<NotificationPriority?>((_) => null);
```

---

## FILE STRUCTURE

```
lib/features/notifications/
├── data/
│   ├── models/
│   │   ├── notification_model.dart
│   │   ├── notification_type.dart
│   │   ├── notification_category.dart
│   │   ├── notification_priority.dart
│   │   └── notification_preferences.dart
│   ├── repositories/
│   │   ├── notification_repository.dart
│   │   └── notification_repository_mock.dart
│   └── datasources/
│       ├── firestore_notification_datasource.dart
│       └── elasticsearch_notification_datasource.dart
├── presentation/
│   ├── providers/
│   │   └── notification_providers.dart
│   ├── screens/
│   │   ├── notifications_screen.dart
│   │   ├── notification_detail_modal.dart
│   │   └── notification_preferences_screen.dart
│   ├── widgets/
│   │   ├── notification_list_item.dart
│   │   ├── notification_badge.dart
│   │   ├── notification_appbar_dropdown.dart
│   │   ├── notification_status_badge.dart
│   │   └── notification_filter_bar.dart
│   └── notifiers/
│       └── notification_filter_notifier.dart
├── services/
│   └── fcm_notification_service.dart
└── utils/
    └── notification_helpers.dart
```

---

## KEY SCREENS & WIDGETS

1. **NotificationsScreen** — main list with filters, search, bulk actions
2. **NotificationDetailModal** — full message + context + actions
3. **NotificationAppBarDropdown** — AppBar popover with recent 5-10 notifications + "Mark All Read"
4. **NotificationPreferencesScreen** — user settings for notification types & delivery
5. **NotificationBadge** — red count badge (dashboard shell + AppBar)
6. **NotificationListItem** — row widget with title, message, time, priority icon

---

## INTEGRATION POINTS

1. **Dashboard Shell** — AppBar notification icon + badge (real-time unread count)
2. **Sidebar** — navigation link to NotificationsScreen
3. **Related Screens** — clicking notification navigates to:
   - Order notification → OrdersScreen or order detail
   - Review notification → ReviewsScreen or review detail
   - User notification → UsersScreen or vendor detail
   - Inventory notification → ProductsScreen

4. **Firebase Cloud Messaging**:
   - Send FCM tokens to backend on login
   - Receive push notifications in app & update badge
   - Handle notification taps (deep link to resource)

---

## SUMMARY TABLE

| Feature | Priority | Mock | Firestore | ECS | Notes |
|---------|----------|------|-----------|-----|-------|
| Notification List | High | ✓ | ✓ | ✓ | Full-text search via ECS |
| AppBar Badge & Dropdown | High | ✓ | ✓ | — | Real-time via Firestore listener |
| Mark Read/Unread | High | ✓ | ✓ | ✓ | Bulk + single actions |
| Category Filters | High | ✓ | ✓ | ✓ | 6 categories + All |
| Priority Indicators | Medium | ✓ | ✓ | ✓ | Color-coded badges |
| Archive/Cleanup | Medium | ✓ | ✓ | ✓ | Auto-delete after 30 days |
| Push Notifications (FCM) | Medium | — | ✓ | — | Real-time delivery |
| Notification Settings | Medium | ✓ | ✓ | — | Per-category toggles |
| Detail/Expansion | Medium | ✓ | ✓ | — | Click notification → detail |
| Search & Date Range | Low | ✓ | ✓ | ✓ | ECS for fast search |


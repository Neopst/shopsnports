# Push Notifications Module

## Overview
Complete push notifications management system for the ShopNSports Admin Dashboard.

## Features
- ✅ **Send Notifications**: Send targeted push notifications to customers, vendors, affiliates, or shippers
- ✅ **Template Library**: Quick templates for common notification types
- ✅ **Notification History**: Track all sent notifications with delivery statistics
- ✅ **Target Audiences**: Choose specific user groups (customers, vendors, affiliates, shippers)
- ✅ **Preview System**: Review notifications before sending
- ✅ **Delivery Stats**: View sent, delivered, failed, and opened counts

## Screens

### 1. Send Notification Screen
**Route**: `/dashboard/push-notifications`

**Features**:
- Target audience selector (ChoiceChips for customer/vendor/affiliate/shipper)
- Template dropdown (filtered by selected audience)
- Custom message composer (title + body fields)
- Send confirmation dialog
- Success feedback with device count

**Usage**:
1. Select target audience
2. (Optional) Choose a template or compose custom message
3. Click "Send Notification"
4. Confirm in dialog
5. View success message with sent count

### 2. Notification History Screen
**Route**: `/dashboard/push-notifications/history`

**Features**:
- Filter by category (All, Customers, Vendors, Affiliates, Shippers)
- Scrollable data table showing:
  - Date sent
  - Title (with body tooltip)
  - Category chip
  - Status chip (color-coded: green=sent, red=failed, orange=scheduled)
  - Sent count
  - Delivered count
  - Failed count (red if > 0)
  - Opened count
  - Delivery rate %
  - Open rate %
- Refresh button
- Empty state message

## Navigation
The module is accessible via the sidebar menu under "Push Notifications" (icon: `notifications_active`), positioned between "Notifications" and "News Ticker".

## Data Models

### NotificationTemplate
```dart
{
  id: int,
  name: String,
  title: String,
  body: String,
  category: String,  // customer | vendor | affiliate | shipper
  type: String,
  isActive: bool,
  imageUrl: String?,
  actionUrl: String?,
  createdAt: DateTime,
  updatedAt: DateTime
}
```

### PushNotification (Request)
```dart
{
  title: String,
  body: String,
  category: String,
  targetUserType: String,
  templateId: int?,
  userIds: List<int>?,
  scheduledAt: DateTime?,
  imageUrl: String?,
  actionUrl: String?,
  customData: Map<String, dynamic>?
}
```

### NotificationHistory
```dart
{
  id: int,
  templateId: int?,
  title: String,
  body: String,
  category: String,
  targetUserType: String,
  status: String,
  scheduledAt: DateTime?,
  sentAt: DateTime?,
  sentCount: int,
  deliveredCount: int,
  failedCount: int,
  openedCount: int,
  createdAt: DateTime,
  
  // Computed properties:
  deliveryRate: double,  // (delivered / sent) * 100
  openRate: double       // (opened / delivered) * 100
}
```

## API Client

**Provider**: `pushNotificationApiClientProvider`

### Methods:
```dart
// Get all templates (optionally filtered by category)
Future<List<NotificationTemplate>> getTemplates({String? category})

// Send a push notification
Future<Map<String, dynamic>> sendNotification(PushNotification notification)

// Get notification history (optionally filtered by category)
Future<List<NotificationHistory>> getHistory({String? category})

// Get statistics
Future<Map<String, dynamic>> getStats()
```

## API Endpoints
- `GET /api/v1/push-notifications/templates` - Get templates
- `GET /api/v1/push-notifications/templates?category=customer` - Get filtered templates
- `POST /api/v1/push-notifications/send` - Send notification
- `GET /api/v1/push-notifications/history` - Get history
- `GET /api/v1/push-notifications/history?category=vendor` - Get filtered history
- `GET /api/v1/push-notifications/stats` - Get statistics

## Database Tables

### notification_templates
14 pre-populated templates:
- 4 Customer templates (Order Shipped, Flash Sale, Order Delivered, New Arrival)
- 4 Vendor templates (New Order, Low Stock, Payout Processed, Product Approved)
- 3 Affiliate templates (Commission Earned, New Marketing Material, Payout Ready)
- 3 Shipper templates (New Pickup, Delivery Reminder, Route Updated)

### notification_history
Tracks all sent notifications with delivery statistics.

### notification_logs
Individual delivery attempts per device.

### fcm_tokens
Device tokens for Firebase Cloud Messaging.

## Error Handling
- Template loading errors → Red SnackBar
- Send errors → Error dialog with selectable error text
- History loading errors → Red SnackBar
- Network timeouts → 30 seconds (configured in AdminApiClient)

## State Management
Uses **Riverpod** (`ConsumerStatefulWidget`) for:
- API client injection via `pushNotificationApiClientProvider`
- Reading admin API client for Dio instance sharing

## Dependencies
```dart
- flutter_riverpod: ^2.x.x
- dio: ^5.x.x
- intl: ^0.x.x  // For date formatting
- go_router: ^x.x.x  // For navigation
```

## Testing
Test the module end-to-end:
1. Navigate to "Push Notifications" in sidebar
2. Select target audience (e.g., Customers)
3. Choose template from dropdown (should auto-fill title/body)
4. Click "Send Notification"
5. Confirm in dialog
6. Verify success message shows device count
7. Click "History" button in AppBar
8. Verify sent notification appears in table
9. Check delivery stats are displayed

## Future Enhancements
- [ ] Scheduled notifications (date/time picker)
- [ ] User selection (specific user IDs instead of all)
- [ ] Image upload for rich notifications
- [ ] Custom action URLs
- [ ] Template CRUD (create, edit, delete templates)
- [ ] Advanced filtering (date range, status)
- [ ] Export history to CSV
- [ ] Real-time delivery tracking
- [ ] A/B testing support
- [ ] Analytics dashboard

## Notes
- Currently sends to ALL users in selected category (no user filtering yet)
- Auth middleware bypassed in development (needs proper implementation)
- CORS enabled for localhost:3000 ↔ localhost:62529 communication
- API base URL configured in `ApiConfig.ecsBaseUrl` (currently localhost:3000)

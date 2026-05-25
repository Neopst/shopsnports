# Notification & Messaging System Implementation Guide

## 📋 Table of Contents
1. [Overview](#overview)
2. [Current State](#current-state)
3. [System Architecture](#system-architecture)
4. [Implementation Roadmap](#implementation-roadmap)
5. [Data Models](#data-models)
6. [FCM Push Notifications](#fcm-push-notifications)
7. [In-App Messaging System](#in-app-messaging-system)
8. [Testing Guide](#testing-guide)

---

## Overview

This document outlines the complete notification and messaging system for ShopSnPorts, covering:
- **Push Notifications** (Firebase Cloud Messaging - FCM)
- **In-App Notifications** (real-time updates via Firestore)
- **Direct Messaging** (customer-vendor, customer-support, affiliate-admin)
- **User-Specific Notifications** (vendors, customers, affiliates)

---

## Current State

### ✅ Already Implemented

#### 1. Firebase Cloud Messaging (FCM)
**Status:** Fully integrated and ready for production

**Files:**
- `lib/services/notification_service.dart` (162 lines)
- `lib/main.dart` (NotificationService initialization)
- `lib/providers/admin_notifications_provider.dart`

**Features:**
- ✅ FCM plugin installed (`firebase_messaging: ^15.1.4`)
- ✅ Permission request on iOS/Android
- ✅ Foreground message handling
- ✅ Topic subscriptions (admins, affiliates, users)
- ✅ Topic-based messaging for role-specific notifications
- ✅ Background message handling

**Topic Subscription Logic:**
```dart
// Admin topic (when user has admin role)
NotificationService.instance.subscribeToAdminsTopic();

// Affiliate topic (per affiliate ID)
NotificationService.instance.subscribeToAffiliateTopic(affiliateId);

// User-specific topic (per user ID)
NotificationService.instance.subscribeToUserTopic(userId);
```

#### 2. Admin Notifications
**Status:** Fully implemented with real-time Firestore streams

**Files:**
- `lib/providers/admin_notifications_provider.dart`
- `lib/screens/admin/mini_admin_dashboard.dart`

**Features:**
- ✅ Real-time notifications via Firestore snapshots
- ✅ Admin dashboard displays latest 10 notifications
- ✅ Performance tested (< 2s update time)

**Collection:** `admin_notifications`
```firestore
{
  type: string,           // 'user_registration', 'shipment_request', etc.
  message: string,        // Display message
  createdAt: timestamp,
  meta: object           // Additional data
}
```

#### 3. Cloud Functions Notifications
**Status:** Partially implemented

**Files:**
- `functions/src/onShipmentRequestCreated.ts`
- `functions/src/onShipmentRequestUpdated.ts`

**Features:**
- ✅ Notifications created on shipment request events
- ✅ FCM topic messaging to admins and affiliates
- ✅ Firestore `notifications` collection writes

**Example:**
```typescript
// Create notification document
await admin.firestore().collection('notifications').add({
  title: 'New shipment request',
  body: `Request ${requestId} from affiliate ${affiliateId}`,
  userId: affiliateId,
  createdAt: admin.firestore.FieldValue.serverTimestamp(),
  meta: { requestId }
});

// Send FCM to topic
await admin.messaging().sendToTopic('admins', {
  notification: {
    title: 'New shipment request',
    body: `Request ${requestId}`
  },
  data: { requestId, type: 'shipment_request' }
});
```

#### 4. Per-User Notifications
**Status:** Basic implementation exists

**Example:**
```dart
// lib/screens/admin/shipper_verification_admin.dart
await db.collection('users').doc(userId).collection('notifications').add({
  'type': 'shipper_verification',
  'status': 'approved',
  'message': 'Your shipper verification was approved',
  'createdAt': FieldValue.serverTimestamp(),
  'meta': {'verificationId': verificationId}
});
```

---

### ❌ Not Yet Implemented

#### 1. User-Facing Notifications Screen
**Status:** Placeholder only

**File:** `lib/screens/notifications_screen.dart` (16 lines - placeholder)

**Current Code:**
```dart
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: 0,
      onNavTap: (_) {},
      appBar: null,
      appBarTitle: 'Notifications',
      showNewsTicker: false,
      body: const Center(child: Text('No notifications yet')),
    );
  }
}
```

**Needed:**
- Real-time notification stream
- Mark as read functionality
- Notification actions (tap to navigate)
- Badge count updates
- Filter by type (orders, messages, system)

#### 2. In-App Messaging System
**Status:** Not implemented

**Needed:**
- Chat/conversation UI
- Message persistence in Firestore
- Real-time message updates
- File attachment support
- Read receipts
- Typing indicators

#### 3. Notification Data Model
**Status:** No unified model

**Needed:**
- `Notification` model class
- Consistent schema across collections
- Type-safe notification handling

---

## System Architecture

### 1. Multi-Channel Notification System

```
┌─────────────────────────────────────────────────────────────┐
│                    NOTIFICATION SOURCES                      │
├─────────────────────────────────────────────────────────────┤
│  Orders  │  Shipments  │  Messages  │  System  │  Marketing │
└─────────┬─────────────┴────────────┴──────────┴─────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────────┐
│              NOTIFICATION PROCESSING ENGINE                  │
│  (Cloud Functions + Firestore Triggers)                     │
├─────────────────────────────────────────────────────────────┤
│  • Create Notification Document                             │
│  • Determine Recipients (role-based, user-specific)         │
│  • Write to Firestore Collections                           │
│  • Send FCM Push Notifications                              │
└─────────┬───────────────────────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────────┐
│                   NOTIFICATION STORAGE                       │
├─────────────────────────────────────────────────────────────┤
│  Global: /notifications                                     │
│  User-Specific: /users/{userId}/notifications               │
│  Admin-Specific: /admin_notifications                       │
│  Conversations: /conversations/{conversationId}/messages    │
└─────────┬───────────────────────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────────┐
│                  CLIENT APPLICATIONS                         │
├─────────────────────────────────────────────────────────────┤
│  • FCM Foreground/Background Handlers                       │
│  • Real-time Firestore Listeners                            │
│  • In-App Notification UI                                   │
│  • Badge Count Updates                                      │
│  • Deep Link Navigation                                     │
└─────────────────────────────────────────────────────────────┘
```

### 2. User Role-Specific Notification Routing

| Notification Type | Customer | Vendor | Affiliate | Admin |
|-------------------|----------|--------|-----------|-------|
| **Order Created** | ✅ | ✅ (if vendor) | ❌ | ✅ |
| **Order Shipped** | ✅ | ✅ (if vendor) | ❌ | ✅ |
| **Order Delivered** | ✅ | ✅ (if vendor) | ❌ | ✅ |
| **Payment Received** | ✅ | ✅ (vendor payout) | ✅ (affiliate payout) | ✅ |
| **Shipment Request** | ✅ (customer) | ❌ | ✅ (affiliate) | ✅ |
| **Message Received** | ✅ | ✅ | ✅ | ✅ |
| **Product Low Stock** | ❌ | ✅ | ❌ | ✅ |
| **Review Posted** | ❌ | ✅ (if vendor) | ❌ | ✅ |
| **Account Approved** | ✅ | ✅ | ✅ | ❌ |
| **Affiliate Approved** | ❌ | ❌ | ✅ | ❌ |
| **Vendor Approved** | ❌ | ✅ | ❌ | ❌ |

---

## Implementation Roadmap

### Phase 1: Enhanced Notification System (Week 1)

#### Priority: P0 (Critical - Production Blocker)

**1.1 Create Notification Model**
```dart
// lib/models/notification.dart
class AppNotification {
  final String id;
  final String userId;              // Recipient
  final String type;                // 'order', 'message', 'shipment', 'system'
  final String title;
  final String body;
  final bool read;
  final DateTime createdAt;
  final Map<String, dynamic>? data; // Additional payload
  final String? actionUrl;          // Deep link
  final String? imageUrl;           // Optional image
  
  // Factory from Firestore
  factory AppNotification.fromFirestore(DocumentSnapshot doc) { ... }
  
  // To Firestore
  Map<String, dynamic> toFirestore() { ... }
}
```

**1.2 Implement Notifications Screen**
```dart
// lib/screens/notifications_screen.dart
class NotificationsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(userNotificationsProvider);
    
    return notificationsAsync.when(
      data: (notifications) => ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return NotificationTile(
            notification: notification,
            onTap: () => _handleNotificationTap(notification),
            onDismiss: () => _markAsRead(notification.id),
          );
        },
      ),
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => ErrorWidget(error),
    );
  }
}
```

**1.3 Create User Notifications Provider**
```dart
// lib/providers/user_notifications_provider.dart
final userNotificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final db = ref.watch(firestoreProvider);
  final user = ref.watch(currentUserProvider);
  
  if (user == null) return Stream.value([]);
  
  return db
    .collection('users')
    .doc(user.id)
    .collection('notifications')
    .orderBy('createdAt', descending: true)
    .limit(50)
    .snapshots()
    .map((snap) => snap.docs
        .map((doc) => AppNotification.fromFirestore(doc))
        .toList());
});

final unreadNotificationCountProvider = StreamProvider<int>((ref) {
  final db = ref.watch(firestoreProvider);
  final user = ref.watch(currentUserProvider);
  
  if (user == null) return Stream.value(0);
  
  return db
    .collection('users')
    .doc(user.id)
    .collection('notifications')
    .where('read', isEqualTo: false)
    .snapshots()
    .map((snap) => snap.size);
});
```

**1.4 Update Badge Count in UI**
```dart
// lib/widgets/main_scaffold.dart
// Replace hardcoded appState.notificationCount with:
final unreadCount = ref.watch(unreadNotificationCountProvider);
unreadCount.when(
  data: (count) => _buildBadgeIcon(Icons.notifications_none, count, Colors.blue),
  loading: () => Icon(Icons.notifications_none),
  error: (_, __) => Icon(Icons.notifications_none),
)
```

**1.5 Implement Mark as Read**
```dart
// lib/services/notification_service.dart
Future<void> markAsRead(String userId, String notificationId) async {
  await _db
    .collection('users')
    .doc(userId)
    .collection('notifications')
    .doc(notificationId)
    .update({'read': true, 'readAt': FieldValue.serverTimestamp()});
}

Future<void> markAllAsRead(String userId) async {
  final batch = _db.batch();
  final snapshot = await _db
    .collection('users')
    .doc(userId)
    .collection('notifications')
    .where('read', isEqualTo: false)
    .get();
  
  for (var doc in snapshot.docs) {
    batch.update(doc.reference, {'read': true, 'readAt': FieldValue.serverTimestamp()});
  }
  
  await batch.commit();
}
```

---

### Phase 2: In-App Messaging System (Week 2)

#### Priority: P1 (High - Customer Support & Vendor Communication)

**2.1 Create Message Data Models**
```dart
// lib/models/conversation.dart
class Conversation {
  final String id;
  final List<String> participantIds;    // [customerId, vendorId] or [customerId, adminId]
  final String? subject;
  final String lastMessage;
  final DateTime lastMessageAt;
  final Map<String, int> unreadCounts;  // userId -> unread count
  final String type;                    // 'customer_vendor', 'customer_support', 'affiliate_admin'
  final bool archived;
  
  factory Conversation.fromFirestore(DocumentSnapshot doc) { ... }
  Map<String, dynamic> toFirestore() { ... }
}

// lib/models/message.dart
class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String? senderRole;             // 'customer', 'vendor', 'affiliate', 'admin'
  final String text;
  final DateTime createdAt;
  final bool read;
  final List<String>? attachments;      // URLs to images/files
  final String? type;                   // 'text', 'image', 'order_link', 'system'
  
  factory Message.fromFirestore(DocumentSnapshot doc) { ... }
  Map<String, dynamic> toFirestore() { ... }
}
```

**2.2 Firestore Collections Structure**
```
/conversations/{conversationId}
  - id: string
  - participantIds: array
  - subject: string
  - lastMessage: string
  - lastMessageAt: timestamp
  - unreadCounts: map
  - type: string
  - archived: boolean
  
  /messages/{messageId}
    - id: string
    - conversationId: string
    - senderId: string
    - senderName: string
    - senderRole: string
    - text: string
    - createdAt: timestamp
    - read: boolean
    - attachments: array
    - type: string
```

**2.3 Messaging Providers**
```dart
// lib/providers/messaging_providers.dart

// User's conversations
final userConversationsProvider = StreamProvider<List<Conversation>>((ref) {
  final db = ref.watch(firestoreProvider);
  final user = ref.watch(currentUserProvider);
  
  if (user == null) return Stream.value([]);
  
  return db
    .collection('conversations')
    .where('participantIds', arrayContains: user.id)
    .orderBy('lastMessageAt', descending: true)
    .snapshots()
    .map((snap) => snap.docs
        .map((doc) => Conversation.fromFirestore(doc))
        .toList());
});

// Messages in a conversation
final conversationMessagesProvider = StreamProvider.family<List<Message>, String>(
  (ref, conversationId) {
    final db = ref.watch(firestoreProvider);
    
    return db
      .collection('conversations')
      .doc(conversationId)
      .collection('messages')
      .orderBy('createdAt', descending: false)
      .limit(100)
      .snapshots()
      .map((snap) => snap.docs
          .map((doc) => Message.fromFirestore(doc))
          .toList());
  },
);

// Total unread message count
final totalUnreadMessagesProvider = StreamProvider<int>((ref) {
  final conversationsAsync = ref.watch(userConversationsProvider);
  final user = ref.watch(currentUserProvider);
  
  return conversationsAsync.when(
    data: (conversations) {
      int total = 0;
      for (var conv in conversations) {
        total += conv.unreadCounts[user?.id] ?? 0;
      }
      return Stream.value(total);
    },
    loading: () => Stream.value(0),
    error: (_, __) => Stream.value(0),
  );
});
```

**2.4 Messaging Service**
```dart
// lib/services/messaging_service.dart
class MessagingService {
  final FirebaseFirestore _db;
  
  MessagingService(this._db);
  
  // Create or get conversation
  Future<String> getOrCreateConversation({
    required String userId1,
    required String userId2,
    required String type,
    String? subject,
  }) async {
    // Check if conversation exists
    final existing = await _db
      .collection('conversations')
      .where('participantIds', arrayContains: userId1)
      .get();
    
    for (var doc in existing.docs) {
      final participantIds = List<String>.from(doc['participantIds']);
      if (participantIds.contains(userId2)) {
        return doc.id;
      }
    }
    
    // Create new conversation
    final docRef = await _db.collection('conversations').add({
      'participantIds': [userId1, userId2],
      'subject': subject,
      'lastMessage': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'unreadCounts': {userId1: 0, userId2: 0},
      'type': type,
      'archived': false,
    });
    
    return docRef.id;
  }
  
  // Send message
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String senderRole,
    required String text,
    List<String>? attachments,
  }) async {
    final batch = _db.batch();
    
    // Add message
    final messageRef = _db
      .collection('conversations')
      .doc(conversationId)
      .collection('messages')
      .doc();
    
    batch.set(messageRef, {
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
      'attachments': attachments ?? [],
      'type': attachments != null && attachments.isNotEmpty ? 'image' : 'text',
    });
    
    // Update conversation
    final convRef = _db.collection('conversations').doc(conversationId);
    final convSnap = await convRef.get();
    final participantIds = List<String>.from(convSnap['participantIds']);
    final unreadCounts = Map<String, dynamic>.from(convSnap['unreadCounts']);
    
    // Increment unread count for all participants except sender
    for (var participantId in participantIds) {
      if (participantId != senderId) {
        unreadCounts[participantId] = (unreadCounts[participantId] ?? 0) + 1;
      }
    }
    
    batch.update(convRef, {
      'lastMessage': text,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'unreadCounts': unreadCounts,
    });
    
    await batch.commit();
    
    // Send FCM to other participants
    for (var participantId in participantIds) {
      if (participantId != senderId) {
        await _sendMessageNotification(
          userId: participantId,
          title: 'New message from $senderName',
          body: text,
          conversationId: conversationId,
        );
      }
    }
  }
  
  // Mark messages as read
  Future<void> markConversationAsRead(String conversationId, String userId) async {
    final batch = _db.batch();
    
    // Update unread count in conversation
    final convRef = _db.collection('conversations').doc(conversationId);
    batch.update(convRef, {
      'unreadCounts.$userId': 0,
    });
    
    // Mark all messages as read
    final messages = await _db
      .collection('conversations')
      .doc(conversationId)
      .collection('messages')
      .where('read', isEqualTo: false)
      .where('senderId', isNotEqualTo: userId)
      .get();
    
    for (var doc in messages.docs) {
      batch.update(doc.reference, {'read': true});
    }
    
    await batch.commit();
  }
  
  Future<void> _sendMessageNotification({
    required String userId,
    required String title,
    required String body,
    required String conversationId,
  }) async {
    // Send FCM
    await NotificationService.instance.sendToUser(
      userId: userId,
      title: title,
      body: body,
      data: {
        'type': 'message',
        'conversationId': conversationId,
      },
    );
    
    // Create in-app notification
    await _db.collection('users').doc(userId).collection('notifications').add({
      'type': 'message',
      'title': title,
      'body': body,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
      'data': {'conversationId': conversationId},
      'actionUrl': '/messages/$conversationId',
    });
  }
}
```

**2.5 Messaging UI Components**

**Conversations List Screen:**
```dart
// lib/screens/messages/conversations_screen.dart
class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(userConversationsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          // Unread badge
          Consumer(builder: (context, ref, _) {
            final unreadAsync = ref.watch(totalUnreadMessagesProvider);
            return unreadAsync.when(
              data: (count) => count > 0
                ? Badge(label: Text('$count'), child: Icon(Icons.message))
                : Icon(Icons.message),
              loading: () => Icon(Icons.message),
              error: (_, __) => Icon(Icons.message),
            );
          }),
        ],
      ),
      body: conversationsAsync.when(
        data: (conversations) {
          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No conversations yet'),
                ],
              ),
            );
          }
          
          return ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              return ConversationTile(
                conversation: conversation,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(conversationId: conversation.id),
                  ),
                ),
              );
            },
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => _showNewMessageDialog(context),
      ),
    );
  }
}

class ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;
  
  const ConversationTile({
    required this.conversation,
    required this.onTap,
    super.key,
  });
  
  @override
  Widget build(BuildContext context) {
    final user = /* get current user from provider */;
    final unreadCount = conversation.unreadCounts[user?.id] ?? 0;
    
    return ListTile(
      leading: CircleAvatar(
        child: Icon(Icons.person),
      ),
      title: Text(
        conversation.subject ?? 'Conversation',
        style: TextStyle(
          fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        conversation.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatTime(conversation.lastMessageAt),
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          if (unreadCount > 0)
            Container(
              margin: EdgeInsets.only(top: 4),
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$unreadCount',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
        ],
      ),
      onTap: onTap,
    );
  }
  
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    
    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
```

**Chat Screen:**
```dart
// lib/screens/messages/chat_screen.dart
class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  
  const ChatScreen({required this.conversationId, super.key});
  
  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    // Mark as read when opening
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markAsRead();
    });
  }
  
  Future<void> _markAsRead() async {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      final service = ref.read(messagingServiceProvider);
      await service.markConversationAsRead(widget.conversationId, user.id);
    }
  }
  
  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    
    final service = ref.read(messagingServiceProvider);
    await service.sendMessage(
      conversationId: widget.conversationId,
      senderId: user.id,
      senderName: user.name,
      senderRole: user.activeRole ?? 'customer',
      text: text,
    );
    
    _textController.clear();
    
    // Scroll to bottom
    _scrollController.animateTo(
      0,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(
      conversationMessagesProvider(widget.conversationId),
    );
    final user = ref.watch(currentUserProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(child: Text('No messages yet'));
                }
                
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[messages.length - 1 - index];
                    final isMe = message.senderId == user?.id;
                    
                    return MessageBubble(
                      message: message,
                      isMe: isMe,
                    );
                  },
                );
              },
              loading: () => Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }
  
  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.attach_file),
            onPressed: () {
              // TODO: Implement file attachment
            },
          ),
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.send),
            color: Theme.of(context).primaryColor,
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  
  const MessageBubble({
    required this.message,
    required this.isMe,
    super.key,
  });
  
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(
                message.senderName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: isMe ? Colors.white70 : Colors.black54,
                ),
              ),
            SizedBox(height: 4),
            Text(
              message.text,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
              ),
            ),
            SizedBox(height: 4),
            Text(
              _formatTime(message.createdAt),
              style: TextStyle(
                fontSize: 10,
                color: isMe ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (messageDate == today) {
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.month}/${dateTime.day} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}
```

---

### Phase 3: Vendor/Affiliate/Admin Specific Features (Week 3)

#### Priority: P2 (Medium - Enhanced Experience)

**3.1 Vendor Notifications**
- Order received
- Low stock alerts
- Payment received
- Review posted
- Customer message

**3.2 Affiliate Notifications**
- Shipment request approved/rejected
- Payout processed
- New customer referral
- Commission earned
- Admin message

**3.3 Customer Notifications**
- Order confirmed
- Order shipped
- Order delivered
- Message from vendor
- Review reminder

**3.4 Bulk Notification Sending**
```dart
// lib/services/bulk_notification_service.dart
class BulkNotificationService {
  static Future<void> notifyAllVendors({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    // Send to 'vendors' topic
    await admin.messaging().sendToTopic('vendors', {
      notification: { title, body },
      data: data ?? {},
    });
  }
  
  static Future<void> notifyAllCustomers({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    await admin.messaging().sendToTopic('customers', {
      notification: { title, body },
      data: data ?? {},
    });
  }
}
```

---

## Data Models

### Notification Model (Complete)
```dart
// lib/models/notification.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String body;
  final bool read;
  final DateTime createdAt;
  final DateTime? readAt;
  final Map<String, dynamic>? data;
  final String? actionUrl;
  final String? imageUrl;
  
  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.read = false,
    required this.createdAt,
    this.readAt,
    this.data,
    this.actionUrl,
    this.imageUrl,
  });
  
  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: data['type'] ?? 'system',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      read: data['read'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      readAt: data['readAt'] != null 
        ? (data['readAt'] as Timestamp).toDate() 
        : null,
      data: data['data'] as Map<String, dynamic>?,
      actionUrl: data['actionUrl'] as String?,
      imageUrl: data['imageUrl'] as String?,
    );
  }
  
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type,
      'title': title,
      'body': body,
      'read': read,
      'createdAt': Timestamp.fromDate(createdAt),
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'data': data,
      'actionUrl': actionUrl,
      'imageUrl': imageUrl,
    };
  }
  
  AppNotification copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? body,
    bool? read,
    DateTime? createdAt,
    DateTime? readAt,
    Map<String, dynamic>? data,
    String? actionUrl,
    String? imageUrl,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      data: data ?? this.data,
      actionUrl: actionUrl ?? this.actionUrl,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
```

### Conversation Model (Complete)
```dart
// lib/models/conversation.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Conversation {
  final String id;
  final List<String> participantIds;
  final String? subject;
  final String lastMessage;
  final DateTime lastMessageAt;
  final Map<String, int> unreadCounts;
  final String type;
  final bool archived;
  final DateTime createdAt;
  
  Conversation({
    required this.id,
    required this.participantIds,
    this.subject,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCounts,
    required this.type,
    this.archived = false,
    required this.createdAt,
  });
  
  factory Conversation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Conversation(
      id: doc.id,
      participantIds: List<String>.from(data['participantIds'] ?? []),
      subject: data['subject'] as String?,
      lastMessage: data['lastMessage'] ?? '',
      lastMessageAt: (data['lastMessageAt'] as Timestamp).toDate(),
      unreadCounts: Map<String, int>.from(data['unreadCounts'] ?? {}),
      type: data['type'] ?? 'customer_vendor',
      archived: data['archived'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
  
  Map<String, dynamic> toFirestore() {
    return {
      'participantIds': participantIds,
      'subject': subject,
      'lastMessage': lastMessage,
      'lastMessageAt': Timestamp.fromDate(lastMessageAt),
      'unreadCounts': unreadCounts,
      'type': type,
      'archived': archived,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
```

### Message Model (Complete)
```dart
// lib/models/message.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String? senderRole;
  final String text;
  final DateTime createdAt;
  final bool read;
  final List<String>? attachments;
  final String? type;
  
  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    this.senderRole,
    required this.text,
    required this.createdAt,
    this.read = false,
    this.attachments,
    this.type,
  });
  
  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      conversationId: data['conversationId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? 'Unknown',
      senderRole: data['senderRole'] as String?,
      text: data['text'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      read: data['read'] ?? false,
      attachments: data['attachments'] != null 
        ? List<String>.from(data['attachments']) 
        : null,
      type: data['type'] as String?,
    );
  }
  
  Map<String, dynamic> toFirestore() {
    return {
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
      'read': read,
      'attachments': attachments,
      'type': type,
    };
  }
}
```

---

## FCM Push Notifications

### Current Setup (Already Working)

**1. Initialization**
```dart
// lib/main.dart (already exists)
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Initialize notification service
  NotificationService.instance.init();
  
  runApp(MyApp());
}
```

**2. Topic Subscriptions**
```dart
// lib/main.dart (already exists in user listener)
ref.listen<AppUser?>(currentUserProvider, (prev, next) {
  if (next != null && next.roles.containsKey('admin')) {
    NotificationService.instance.subscribeToAdminsTopic();
  } else {
    NotificationService.instance.unsubscribeFromAdminsTopic();
  }
  
  if (next?.affiliateId != null) {
    NotificationService.instance.subscribeToAffiliateTopic(next!.affiliateId!);
  }
  
  if (next?.id != null) {
    NotificationService.instance.subscribeToUserTopic(next!.id);
  }
});
```

### Backend FCM Integration (Cloud Functions)

**Send notification via Cloud Functions:**
```typescript
// functions/src/utils/notifications.ts
import * as admin from 'firebase-admin';

export async function sendNotificationToUser(
  userId: string,
  title: string,
  body: string,
  data?: Record<string, string>
) {
  // Send to user-specific topic
  await admin.messaging().sendToTopic(`user-${userId}`, {
    notification: { title, body },
    data: data || {},
  });
  
  // Also create in-app notification
  await admin.firestore()
    .collection('users')
    .doc(userId)
    .collection('notifications')
    .add({
      type: data?.type || 'system',
      title,
      body,
      read: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      data,
    });
}

export async function sendNotificationToTopic(
  topic: string,
  title: string,
  body: string,
  data?: Record<string, string>
) {
  await admin.messaging().sendToTopic(topic, {
    notification: { title, body },
    data: data || {},
  });
}
```

---

## Testing Guide

### Phase 1: Notification System Testing (Day 1-2)

**Test 1: Notification Creation**
```dart
testWidgets('Create notification for user', (tester) async {
  final db = FakeFirebaseFirestore();
  
  await db.collection('users').doc('user1').collection('notifications').add({
    'type': 'order',
    'title': 'Order Confirmed',
    'body': 'Your order #123 has been confirmed',
    'read': false,
    'createdAt': FieldValue.serverTimestamp(),
  });
  
  final snapshot = await db
    .collection('users')
    .doc('user1')
    .collection('notifications')
    .get();
  
  expect(snapshot.docs.length, 1);
  expect(snapshot.docs.first['title'], 'Order Confirmed');
});
```

**Test 2: Unread Count**
```dart
testWidgets('Unread notification count', (tester) async {
  final container = ProviderContainer(overrides: [
    firestoreProvider.overrideWithValue(fakeFirestore),
  ]);
  
  // Add 3 unread notifications
  for (int i = 0; i < 3; i++) {
    await fakeFirestore
      .collection('users')
      .doc('user1')
      .collection('notifications')
      .add({'read': false, 'createdAt': FieldValue.serverTimestamp()});
  }
  
  final count = await container.read(unreadNotificationCountProvider.future);
  expect(count, 3);
});
```

**Test 3: Mark as Read**
```dart
test('Mark notification as read', () async {
  final service = NotificationService(fakeFirestore);
  
  final docRef = await fakeFirestore
    .collection('users')
    .doc('user1')
    .collection('notifications')
    .add({'read': false});
  
  await service.markAsRead('user1', docRef.id);
  
  final doc = await docRef.get();
  expect(doc['read'], true);
  expect(doc['readAt'], isNotNull);
});
```

### Phase 2: Messaging System Testing (Day 3-4)

**Test 1: Create Conversation**
```dart
test('Create conversation between two users', () async {
  final service = MessagingService(fakeFirestore);
  
  final conversationId = await service.getOrCreateConversation(
    userId1: 'customer1',
    userId2: 'vendor1',
    type: 'customer_vendor',
    subject: 'Product Inquiry',
  );
  
  final doc = await fakeFirestore.collection('conversations').doc(conversationId).get();
  expect(doc.exists, true);
  expect(doc['participantIds'], contains('customer1'));
  expect(doc['participantIds'], contains('vendor1'));
});
```

**Test 2: Send Message**
```dart
test('Send message in conversation', () async {
  final service = MessagingService(fakeFirestore);
  
  final conversationId = await service.getOrCreateConversation(
    userId1: 'customer1',
    userId2: 'vendor1',
    type: 'customer_vendor',
  );
  
  await service.sendMessage(
    conversationId: conversationId,
    senderId: 'customer1',
    senderName: 'Customer A',
    senderRole: 'customer',
    text: 'Hello, I have a question',
  );
  
  final messages = await fakeFirestore
    .collection('conversations')
    .doc(conversationId)
    .collection('messages')
    .get();
  
  expect(messages.docs.length, 1);
  expect(messages.docs.first['text'], 'Hello, I have a question');
});
```

**Test 3: Unread Message Count**
```dart
test('Unread message count increments correctly', () async {
  final service = MessagingService(fakeFirestore);
  
  final conversationId = await service.getOrCreateConversation(
    userId1: 'customer1',
    userId2: 'vendor1',
    type: 'customer_vendor',
  );
  
  // Send 2 messages from customer
  for (int i = 0; i < 2; i++) {
    await service.sendMessage(
      conversationId: conversationId,
      senderId: 'customer1',
      senderName: 'Customer',
      senderRole: 'customer',
      text: 'Message $i',
    );
  }
  
  final doc = await fakeFirestore.collection('conversations').doc(conversationId).get();
  expect(doc['unreadCounts']['vendor1'], 2);
  expect(doc['unreadCounts']['customer1'], 0);
});
```

### Manual Testing Checklist

**Notifications (15 minutes)**
- [ ] Launch app and verify FCM permission request
- [ ] Navigate to Notifications screen
- [ ] Verify empty state shows correctly
- [ ] Create test notification via Firestore console
- [ ] Verify notification appears in list
- [ ] Tap notification and verify navigation
- [ ] Mark as read and verify badge count updates
- [ ] Send FCM push notification and verify foreground alert
- [ ] Close app and verify background notification appears
- [ ] Tap background notification and verify deep link works

**Messaging (20 minutes)**
- [ ] Navigate to Messages screen
- [ ] Verify empty state shows correctly
- [ ] Create new conversation with vendor
- [ ] Send 3 messages
- [ ] Verify messages appear in real-time
- [ ] Close and reopen conversation
- [ ] Verify unread count shows correctly
- [ ] Open conversation and verify unread count clears
- [ ] Test file attachment (if implemented)
- [ ] Verify message timestamps format correctly
- [ ] Test with multiple conversations

---

## Production Deployment Checklist

### Backend Configuration
- [ ] Deploy Cloud Functions with FCM credentials
- [ ] Set up FCM server key in Firebase Console
- [ ] Configure Firestore security rules for notifications and conversations
- [ ] Test FCM token refresh handling
- [ ] Set up background notification handler for iOS

### Frontend Configuration
- [ ] Update iOS Info.plist with notification permissions
- [ ] Update Android AndroidManifest.xml with FCM receiver
- [ ] Test on real devices (iOS and Android)
- [ ] Verify deep linking works from notifications
- [ ] Test notification badges on app icon

### Performance
- [ ] Limit notification queries (max 50-100 per page)
- [ ] Implement pagination for old notifications
- [ ] Set up Firestore indexes for notification queries
- [ ] Optimize real-time listeners (unsubscribe when not needed)
- [ ] Test with 100+ notifications

### Security
- [ ] Verify users can only read their own notifications
- [ ] Prevent notification injection attacks
- [ ] Validate conversation participants before sending messages
- [ ] Sanitize message content before display
- [ ] Rate limit notification creation

---

## Summary

**Current State:**
- ✅ FCM fully integrated
- ✅ Admin notifications working
- ✅ Topic-based messaging ready
- ✅ Cloud Functions create notifications
- ❌ User notifications screen incomplete
- ❌ In-app messaging not implemented

**Estimated Implementation Time:**
- Week 1 (P0): Enhanced notification system (20 hours)
- Week 2 (P1): In-app messaging system (30 hours)
- Week 3 (P2): Role-specific features (15 hours)

**Total:** ~65 hours over 3 weeks

**Priority Order:**
1. **P0 (Week 1):** Notification model, notifications screen, unread counts, mark as read
2. **P1 (Week 2):** Messaging models, chat UI, conversations list, real-time messaging
3. **P2 (Week 3):** Vendor/affiliate/customer specific notifications, bulk sending

**Next Immediate Steps:**
1. Create `AppNotification` model
2. Implement `NotificationsScreen` with real data
3. Add `unreadNotificationCountProvider`
4. Test notification creation and marking as read
5. Deploy and test with real FCM push notifications

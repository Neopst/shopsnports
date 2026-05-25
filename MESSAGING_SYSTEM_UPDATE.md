# Messaging System Update - Admin-Centric Communication

## 📋 Updated Requirements

### Communication Flow
**UPDATED RULE:** All communication goes through admin only. No direct vendor-customer messaging.

```
Customer  ──────────┐
                    │
Vendor    ──────────┼─────> Admin (Central Hub)
                    │
Affiliate ──────────┘
```

### Who Communicates With Whom

| User Type | Can Message |
|-----------|------------|
| **Customer** | ✅ Admin only (via Help/Support) |
| **Vendor** | ✅ Admin only |
| **Affiliate** | ✅ Admin only |
| **Admin** | ✅ All users (customers, vendors, affiliates) |

❌ **NOT ALLOWED:**
- Customer ↔ Vendor direct messaging
- Customer ↔ Affiliate direct messaging
- Vendor ↔ Affiliate direct messaging

---

## ✅ Current State

### 1. Help Center Screen (Exists)
**File:** `lib/screens/help_center_screen.dart` (230 lines)

**Current Features:**
- ✅ Static contact information page
- ✅ Phone number click-to-call
- ✅ WhatsApp integration
- ✅ Email form (opens mailto)
- ✅ FAQ link
- ✅ Accessible from drawer Help button

**What's Missing:**
- ❌ Live chat functionality
- ❌ Real-time messaging with admin
- ❌ Conversation history
- ❌ Message notifications
- ❌ Admin response system

### 2. Drawer Help Button (Exists)
**File:** `lib/widgets/main_scaffold.dart` (line 581-585)

**Current Code:**
```dart
TextButton.icon(
  key: const Key('drawer_bottom_help'),
  onPressed: () => Navigator.of(context).pushNamed('/help'),
  icon: const Icon(Icons.help_outline, size: 18),
  label: const Text('Help'),
)
```

**Status:** ✅ Functional - navigates to Help Center screen

### 3. Notification System
**Status:** ✅ Partially implemented (see `docs/notification_and_messaging_system.md`)

- ✅ FCM push notifications working
- ✅ Admin notifications working
- ✅ Topic-based messaging ready
- ❌ User-facing notification screen incomplete
- ❌ In-app messaging not implemented

---

## 🎯 Updated Implementation Plan

### Phase 1: Admin-Customer Support Chat (Priority P0)
**Estimated Time:** 2-3 days

#### 1.1 Update Help Center Screen with Live Chat
Transform the static Help Center into a functional support chat interface.

**New Features:**
- Live chat button (starts conversation with admin)
- Recent conversations list
- Quick help topics
- Emergency contact (existing phone/WhatsApp)

**UI Layout:**
```
┌─────────────────────────────────────┐
│ Help Center                          │
├─────────────────────────────────────┤
│ 💬 Start Live Chat with Support     │ ← Primary CTA
├─────────────────────────────────────┤
│ Recent Conversations                 │
│  • Order #123 Issue (2h ago)        │
│  • Product Question (1d ago)        │
├─────────────────────────────────────┤
│ Quick Help                           │
│  📦 Track Order                     │
│  💳 Payment Issues                  │
│  🔄 Returns & Refunds               │
│  ❓ FAQs                            │
├─────────────────────────────────────┤
│ Other Contact Options                │
│  📞 Call Center                     │
│  📧 Email                           │
│  💚 WhatsApp                        │
└─────────────────────────────────────┘
```

#### 1.2 Simplified Data Model (Admin-Centric)

**Conversation Model:**
```dart
class SupportConversation {
  final String id;
  final String userId;              // Customer, Vendor, or Affiliate ID
  final String userRole;            // 'customer', 'vendor', 'affiliate'
  final String subject;
  final String status;              // 'open', 'pending', 'closed'
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCountUser;        // Unread for user
  final int unreadCountAdmin;       // Unread for admin
  final DateTime createdAt;
  final String? orderId;            // Optional order reference
  final String? assignedAdminId;    // Which admin is handling
}
```

**Message Model:**
```dart
class SupportMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderRole;          // 'customer', 'vendor', 'affiliate', 'admin'
  final String text;
  final DateTime createdAt;
  final bool readByUser;
  final bool readByAdmin;
  final List<String>? attachments;
}
```

**Firestore Structure:**
```
/support_conversations/{conversationId}
  - id: string
  - userId: string
  - userRole: string
  - subject: string
  - status: string
  - lastMessage: string
  - lastMessageAt: timestamp
  - unreadCountUser: number
  - unreadCountAdmin: number
  - createdAt: timestamp
  - orderId: string (optional)
  - assignedAdminId: string (optional)
  
  /messages/{messageId}
    - id: string
    - conversationId: string
    - senderId: string
    - senderRole: string
    - text: string
    - createdAt: timestamp
    - readByUser: boolean
    - readByAdmin: boolean
    - attachments: array
```

#### 1.3 Support Chat Service

**File:** `lib/services/support_chat_service.dart`

```dart
class SupportChatService {
  final FirebaseFirestore _db;
  
  SupportChatService(this._db);
  
  // Start a new conversation with admin
  Future<String> startConversation({
    required String userId,
    required String userRole,
    required String subject,
    String? orderId,
  }) async {
    final docRef = await _db.collection('support_conversations').add({
      'userId': userId,
      'userRole': userRole,
      'subject': subject,
      'status': 'open',
      'lastMessage': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'unreadCountUser': 0,
      'unreadCountAdmin': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'orderId': orderId,
    });
    
    // Notify admins
    await _notifyAdmins(
      'New support request',
      'From ${userRole}: $subject',
      {'conversationId': docRef.id},
    );
    
    return docRef.id;
  }
  
  // Send message to admin
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderRole,
    required String text,
    List<String>? attachments,
  }) async {
    final batch = _db.batch();
    
    // Add message
    final messageRef = _db
      .collection('support_conversations')
      .doc(conversationId)
      .collection('messages')
      .doc();
    
    batch.set(messageRef, {
      'conversationId': conversationId,
      'senderId': senderId,
      'senderRole': senderRole,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
      'readByUser': senderRole != 'admin',
      'readByAdmin': senderRole == 'admin',
      'attachments': attachments ?? [],
    });
    
    // Update conversation
    final convRef = _db.collection('support_conversations').doc(conversationId);
    
    if (senderRole == 'admin') {
      // Admin sent message - increment user unread
      batch.update(convRef, {
        'lastMessage': text,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'unreadCountUser': FieldValue.increment(1),
      });
    } else {
      // User sent message - increment admin unread
      batch.update(convRef, {
        'lastMessage': text,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'unreadCountAdmin': FieldValue.increment(1),
      });
    }
    
    await batch.commit();
    
    // Send notification
    if (senderRole == 'admin') {
      await _notifyUser(conversationId, text);
    } else {
      await _notifyAdmins('New message', text, {'conversationId': conversationId});
    }
  }
  
  // Get user's conversations
  Stream<List<SupportConversation>> getUserConversations(String userId) {
    return _db
      .collection('support_conversations')
      .where('userId', isEqualTo: userId)
      .orderBy('lastMessageAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs
          .map((doc) => SupportConversation.fromFirestore(doc))
          .toList());
  }
  
  // Get all conversations for admin
  Stream<List<SupportConversation>> getAllConversations({
    String? status,
    String? userRole,
  }) {
    Query query = _db.collection('support_conversations');
    
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    if (userRole != null) {
      query = query.where('userRole', isEqualTo: userRole);
    }
    
    return query
      .orderBy('lastMessageAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs
          .map((doc) => SupportConversation.fromFirestore(doc))
          .toList());
  }
  
  // Mark conversation as read
  Future<void> markAsRead(String conversationId, bool isAdmin) async {
    if (isAdmin) {
      await _db.collection('support_conversations').doc(conversationId).update({
        'unreadCountAdmin': 0,
      });
    } else {
      await _db.collection('support_conversations').doc(conversationId).update({
        'unreadCountUser': 0,
      });
    }
    
    // Mark messages as read
    final messages = await _db
      .collection('support_conversations')
      .doc(conversationId)
      .collection('messages')
      .where(isAdmin ? 'readByAdmin' : 'readByUser', isEqualTo: false)
      .get();
    
    final batch = _db.batch();
    for (var doc in messages.docs) {
      batch.update(doc.reference, {
        isAdmin ? 'readByAdmin' : 'readByUser': true,
      });
    }
    await batch.commit();
  }
  
  // Close conversation
  Future<void> closeConversation(String conversationId) async {
    await _db.collection('support_conversations').doc(conversationId).update({
      'status': 'closed',
    });
  }
  
  Future<void> _notifyAdmins(String title, String body, Map<String, dynamic> data) async {
    // Send to admins topic
    await NotificationService.instance.sendToTopic(
      topic: 'admins',
      title: title,
      body: body,
      data: data,
    );
    
    // Create admin notification
    await _db.collection('admin_notifications').add({
      'type': 'support_message',
      'title': title,
      'message': body,
      'createdAt': FieldValue.serverTimestamp(),
      'meta': data,
    });
  }
  
  Future<void> _notifyUser(String conversationId, String messageText) async {
    final conv = await _db
      .collection('support_conversations')
      .doc(conversationId)
      .get();
    final userId = conv['userId'];
    
    await NotificationService.instance.sendToUser(
      userId: userId,
      title: 'Support Response',
      body: messageText,
      data: {
        'type': 'support_message',
        'conversationId': conversationId,
      },
    );
    
    // Create user notification
    await _db.collection('users').doc(userId).collection('notifications').add({
      'type': 'support_message',
      'title': 'Support Response',
      'body': messageText,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
      'data': {'conversationId': conversationId},
      'actionUrl': '/support/chat/$conversationId',
    });
  }
}
```

#### 1.4 Enhanced Help Center Screen

**File:** `lib/screens/help_center_screen.dart`

Add live chat functionality:
```dart
class HelpCenterScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final conversationsAsync = ref.watch(userSupportConversationsProvider);
    
    return MainScaffold(
      currentIndex: 4,
      onNavTap: (_) {},
      topWidget: const NewsTicker(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Text('Help Center', style: Theme.of(context).textTheme.headlineMedium),
          SizedBox(height: 8),
          Text('How can we help you today?'),
          SizedBox(height: 24),
          
          // Live Chat Button (Primary CTA)
          ElevatedButton.icon(
            icon: Icon(Icons.chat_bubble),
            label: Text('Start Live Chat with Support'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.all(16),
              minimumSize: Size(double.infinity, 56),
            ),
            onPressed: () => _startNewChat(context, ref, user),
          ),
          
          SizedBox(height: 24),
          
          // Recent Conversations
          conversationsAsync.when(
            data: (conversations) {
              if (conversations.isEmpty) {
                return SizedBox.shrink();
              }
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Recent Conversations', 
                    style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  ...conversations.take(3).map((conv) => 
                    ConversationTile(
                      conversation: conv,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SupportChatScreen(
                            conversationId: conv.id,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                ],
              );
            },
            loading: () => SizedBox.shrink(),
            error: (_, __) => SizedBox.shrink(),
          ),
          
          // Quick Help Topics
          Text('Quick Help', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          _buildQuickHelpTile(
            context,
            icon: Icons.local_shipping,
            title: 'Track Order',
            onTap: () => Navigator.pushNamed(context, '/orders'),
          ),
          _buildQuickHelpTile(
            context,
            icon: Icons.payment,
            title: 'Payment Issues',
            onTap: () => _startTopicChat(context, ref, user, 'Payment Issue'),
          ),
          _buildQuickHelpTile(
            context,
            icon: Icons.refresh,
            title: 'Returns & Refunds',
            onTap: () => _startTopicChat(context, ref, user, 'Return Request'),
          ),
          _buildQuickHelpTile(
            context,
            icon: Icons.help_outline,
            title: 'FAQs',
            onTap: () => _launch(context, Uri.parse(faqUrl)),
          ),
          
          SizedBox(height: 24),
          
          // Other Contact Options (existing)
          Text('Other Contact Options', 
            style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          ContactTile(
            icon: Icons.phone,
            title: 'Call Center',
            subtitle: phoneNumber,
            onTap: () => _launch(context, Uri.parse('tel:$phoneNumber')),
          ),
          ContactTile(
            leadingImage: 'assets/designs/WhatsApp_Image_...',
            title: 'WhatsApp',
            subtitle: 'Chat with us',
            onTap: () => _launch(context, 
              Uri.parse('https://wa.me/$whatsappNumber')),
          ),
          ContactTile(
            icon: Icons.email,
            title: 'Email',
            subtitle: supportEmail,
            onTap: () => _launch(context, 
              Uri.parse('mailto:$supportEmail')),
          ),
        ],
      ),
    );
  }
  
  Future<void> _startNewChat(
    BuildContext context, 
    WidgetRef ref, 
    AppUser? user,
  ) async {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please sign in to start a chat')),
      );
      return;
    }
    
    // Show subject dialog
    final subject = await _showSubjectDialog(context);
    if (subject == null) return;
    
    final service = ref.read(supportChatServiceProvider);
    final conversationId = await service.startConversation(
      userId: user.id,
      userRole: user.activeRole ?? 'customer',
      subject: subject,
    );
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SupportChatScreen(conversationId: conversationId),
      ),
    );
  }
  
  Future<void> _startTopicChat(
    BuildContext context,
    WidgetRef ref,
    AppUser? user,
    String topic,
  ) async {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please sign in to start a chat')),
      );
      return;
    }
    
    final service = ref.read(supportChatServiceProvider);
    final conversationId = await service.startConversation(
      userId: user.id,
      userRole: user.activeRole ?? 'customer',
      subject: topic,
    );
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SupportChatScreen(conversationId: conversationId),
      ),
    );
  }
}
```

#### 1.5 Support Chat Screen

**File:** `lib/screens/support_chat_screen.dart`

Full chat interface for talking with admin.

---

### Phase 2: Admin Support Dashboard (Priority P1)
**Estimated Time:** 2-3 days

#### Admin Support Inbox Screen
- View all open support conversations
- Filter by user role (customer, vendor, affiliate)
- Filter by status (open, pending, closed)
- Assign conversations to specific admins
- Quick reply templates
- Mark as resolved
- Conversation history

---

### Phase 3: Vendor & Affiliate Messaging (Priority P1)
**Estimated Time:** 1-2 days

#### Vendor Admin Chat
- Same interface as customer support
- Vendor can reach admin for:
  - Product approval questions
  - Payout inquiries
  - Account issues
  - Policy questions

#### Affiliate Admin Chat
- Same interface as customer support
- Affiliate can reach admin for:
  - Shipment request questions
  - Payout inquiries
  - Approval status
  - Commission questions

---

## 📊 Updated Todo List

1. ✅ Add payment logos to payment methods screen
2. ✅ Add title to payment methods screen
3. ⏳ Test cart system (add/update/remove/persist)
4. 🔲 Test affiliate registration and approval flow
5. 🔲 Test vendor dashboard and product management
6. 🔲 Test in-app admin dashboard features
7. 🔲 Test payment system integration (all providers)
8. 🔲 **Implement admin-customer messaging (help/support)** ← NEW
9. 🔲 **Implement admin-vendor messaging** ← NEW
10. 🔲 **Implement admin-affiliate messaging** ← NEW
11. 🔲 **Make live chat/help feature in drawer functional** ← NEW
12. 🔲 Test notification system (all user roles)
13. 🔲 Enhance data models with suggested features
14. 🔲 Final testing and production deployment

---

## 🎯 Implementation Priority

### This Week (Days 1-3): Critical Messaging Foundation
1. **Day 1:** Create data models and service (SupportConversation, SupportMessage, SupportChatService)
2. **Day 2:** Enhance Help Center screen with live chat
3. **Day 3:** Implement Support Chat Screen (customer view)

### Next Week (Days 4-6): Admin & Testing
4. **Day 4:** Admin support inbox screen
5. **Day 5:** Vendor and affiliate chat integration
6. **Day 6:** Testing and notifications integration

---

## 📁 Files to Create/Update

### New Files:
1. `lib/models/support_conversation.dart` - Data model
2. `lib/models/support_message.dart` - Data model
3. `lib/services/support_chat_service.dart` - Business logic
4. `lib/providers/support_chat_providers.dart` - Riverpod providers
5. `lib/screens/support_chat_screen.dart` - Chat UI
6. `lib/screens/admin/support_inbox_screen.dart` - Admin view
7. `lib/widgets/support_chat_bubble.dart` - Message bubble widget

### Files to Update:
1. `lib/screens/help_center_screen.dart` - Add live chat
2. `lib/widgets/main_scaffold.dart` - Update help button (already works)
3. `lib/services/notification_service.dart` - Add sendToUser method
4. `docs/notification_and_messaging_system.md` - Update architecture

---

## 🔒 Security Considerations

### Firestore Security Rules
```javascript
// Support conversations - users can only read their own
match /support_conversations/{conversationId} {
  allow read: if request.auth != null && 
    (resource.data.userId == request.auth.uid || 
     request.auth.token.admin == true);
  allow create: if request.auth != null;
  allow update: if request.auth != null && 
    (resource.data.userId == request.auth.uid || 
     request.auth.token.admin == true);
  
  // Messages subcollection
  match /messages/{messageId} {
    allow read: if request.auth != null && 
      (get(/databases/$(database)/documents/support_conversations/$(conversationId)).data.userId == request.auth.uid ||
       request.auth.token.admin == true);
    allow create: if request.auth != null;
  }
}
```

---

## ✅ Ready to Begin

The todo list has been updated. We're ready to start implementing the admin-centric messaging system, beginning with the customer support chat functionality.

**Next Step:** Shall we start with creating the data models and service layer?

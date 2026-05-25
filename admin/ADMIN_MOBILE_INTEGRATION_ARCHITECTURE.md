# Admin Dashboard ↔ Mobile App Architecture

**Architecture Pattern**: Single Firestore Database = Single Source of Truth  
**Status**: Admin Dashboard Ready ✅ | Mobile App Ready to Integrate

---

## The Big Picture

```
┌─────────────────────────────────────────────────────────────┐
│                    FIRESTORE DATABASE                        │
│                   (Single Source of Truth)                   │
│                                                              │
│  ├─ news_ticker (5 items)          ✅ Auto-seeded          │
│  ├─ content_pages (5 items)        ✅ Auto-seeded          │
│  ├─ faqs (7 items)                 ✅ Auto-seeded          │
│  ├─ banners (4 items)              ✅ Auto-seeded          │
│  ├─ email_templates (7 items)      ✅ Auto-seeded          │
│  ├─ invoices (3 items)             ✅ Auto-seeded          │
│  ├─ customers (3 items)            ✅ Auto-seeded          │
│  ├─ shipping_requests (10 items)   ✅ Auto-seeded          │
│  ├─ notifications (5 items)        ✅ Auto-seeded          │
│  ├─ affiliates (as needed)         ✅ Auto-seeded          │
│  ├─ payouts (transaction records)  ✅ Auto-seeded          │
│  ├─ commission_settings            ✅ Auto-seeded          │
│  ├─ tax_settings                   ✅ Auto-seeded          │
│  ├─ business_settings              ✅ Auto-seeded          │
│  └─ ... (and more)                 ✅ Auto-seeded          │
└─────────────────────────────────────────────────────────────┘
                           ↑
                           │ (Same Firebase Project)
                           │
        ┌──────────────────┴──────────────────┐
        │                                     │
    ┌────────────┐                   ┌──────────────┐
    │   ADMIN    │                   │   MOBILE     │
    │ DASHBOARD  │                   │    APP       │
    │  (Flutter  │                   │   (Flutter   │
    │   Web)     │                   │   Native)    │
    └────────────┘                   └──────────────┘
         │                                 │
         │ Queries/Updates                 │ Queries/Reads
         │                                 │
         └──────────────────┬──────────────┘
                            │
                    Real-time Sync
                    (StreamProvider)
```

---

## How It Works

### 1️⃣ **Admin Creates Content** (News Ticker)

**Admin Dashboard Action**:
```dart
// admin_dashboard/lib/features/news_ticker/screens/news_ticker_screen.dart
Future<void> _createNewsItem() async {
  final newsItem = NewsTicker(
    id: 'news_123',
    title: 'New Feature: Flash Sales',
    content: 'Now offering flash sales every Friday!',
    status: NewsTickerStatus.published,
    publishedAt: DateTime.now(),
  );
  
  await _repository.createNewsItem(newsItem);  // → Firestore
}
```

**Behind the Scenes**:
```dart
// admin_dashboard/lib/features/news_ticker/data/repositories/news_ticker_repository_firestore.dart
Future<void> createNewsItem(NewsTicker newsItem) async {
  await _firestore
      .collection('news_ticker')  // Collection in Firestore
      .doc(newsItem.id)
      .set(newsItem.toMap());  // Stores to Firestore
}
```

### 2️⃣ **Firestore Triggers Sync**

Firestore document created:
```json
{
  "id": "news_123",
  "title": "New Feature: Flash Sales",
  "content": "Now offering flash sales every Friday!",
  "status": "published",
  "publishedAt": "2026-01-30T10:30:00Z",
  "createdAt": "2026-01-30T10:30:00Z",
  "updatedAt": "2026-01-30T10:30:00Z",
  "viewCount": 0
}
```

### 3️⃣ **Mobile App Sees It Instantly** (Real-time)

**Mobile App Screen** (NewsWidget):
```dart
// mobile_app/lib/features/news_ticker/screens/news_ticker_screen.dart
class NewsTickerWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Subscribe to real-time updates
    final newsStream = ref.watch(publishedNewsStreamProvider);
    
    return newsStream.when(
      data: (newsList) {
        // newsList automatically updates when admin creates news
        return ListView.builder(
          itemCount: newsList.length,
          itemBuilder: (context, index) {
            return NewsCard(news: newsList[index]);
          },
        );
      },
      loading: () => LoadingWidget(),
      error: (err, st) => ErrorWidget(),
    );
  }
}
```

**Behind the Scenes** (Mobile):
```dart
// mobile_app/lib/features/news_ticker/repositories/news_ticker_repository.dart
Stream<List<NewsTicker>> streamPublishedNews() {
  return _firestore
      .collection('news_ticker')  // Same collection
      .where('status', isEqualTo: 'published')
      .snapshots()  // Listens for real-time changes
      .map((snapshot) => snapshot.docs
          .map((doc) => NewsTicker.fromFirestore(doc))
          .toList());
}
```

**Result**: Mobile app shows the new news item **within milliseconds** ✅

---

## Complete Data Flow Example

### Scenario: Admin Creates Invoice, Mobile App Tracks Status

**Step 1: Admin Creates Invoice**
```dart
// Admin Dashboard
final invoice = Invoice(
  id: 'INV-2026-001',
  invoiceNumber: 'INV-2026-001',
  customerName: 'John Smith',
  totalAmount: 50000,
  status: InvoiceStatus.pending,
);

await invoiceRepository.createInvoice(invoice);
```

**Firestore Updates** (automatically):
```
invoices/INV-2026-001
{
  "id": "INV-2026-001",
  "invoiceNumber": "INV-2026-001",
  "customerName": "John Smith",
  "totalAmount": 50000,
  "status": "pending",
  "createdAt": "2026-01-30T10:30:00Z"
}
```

**Step 2: Mobile App Displays Invoice** (Real-time):
```dart
// Mobile App
final invoiceStream = ref.watch(invoiceByIdProvider('INV-2026-001'));

invoiceStream.when(
  data: (invoice) {
    // Automatically updates when admin updates status
    return InvoiceCard(invoice: invoice);
  },
);
```

**Step 3: Admin Updates Invoice Status**
```dart
// Admin Dashboard
await invoiceRepository.updateInvoiceStatus(
  'INV-2026-001',
  InvoiceStatus.paid,
);
```

**Firestore Updates** (automatically):
```
invoices/INV-2026-001
{
  "id": "INV-2026-001",
  ...
  "status": "paid",  // ← Changed
  "paidAt": "2026-01-30T11:00:00Z",  // ← Added
  "updatedAt": "2026-01-30T11:00:00Z"
}
```

**Step 4: Mobile App Updates Instantly** ✅
```
Mobile shows: Invoice status changed from "pending" to "paid"
              Paid at: 2026-01-30 11:00 AM
```

---

## Smart Seeding Explained

### First App Launch (Admin Dashboard)

```
App Starts
    ↓
Initialize Firebase
    ↓
Check if news_ticker collection has any docs
    ↓
   NO docs found → Seed 5 sample news items
    ↓
Done. Sample data in Firestore
```

### Mobile App Launches (Same Firebase Project)

```
Mobile App Starts
    ↓
Initialize Firebase (same project)
    ↓
Query Firestore: SELECT * FROM news_ticker WHERE status = 'published'
    ↓
Result: 5 news items (from admin dashboard seeding)
    ↓
Display news items
```

### Second Time Admin Launches

```
Admin App Starts
    ↓
Initialize Firebase
    ↓
Check if news_ticker collection has any docs
    ↓
   YES docs exist → Skip seeding
    ↓
App runs normally, all data preserved
```

**Result**: Data seeds once, never overwrites. Both apps see same data ✅

---

## Module-by-Module Integration

### News Ticker Module

**Admin Dashboard**:
- ✅ Create news item
- ✅ Edit news item
- ✅ Delete news item
- ✅ Publish/Archive
- ✅ Set expiration date

**Mobile App Will**:
- ✅ Display published news items
- ✅ Show news detail page
- ✅ Track view count
- ✅ Real-time updates

### Content Pages Module

**Admin Dashboard**:
- ✅ Create page (About Us, Terms, etc.)
- ✅ Edit content with HTML
- ✅ Publish/Draft status
- ✅ SEO metadata

**Mobile App Will**:
- ✅ Display published pages
- ✅ Deep linking by slug (e.g., /about-us)
- ✅ Render HTML content
- ✅ Real-time updates

### FAQs Module

**Admin Dashboard**:
- ✅ Create FAQ
- ✅ Categorize (Account, Payment, Shipping, etc.)
- ✅ Set display order
- ✅ Publish/Hide

**Mobile App Will**:
- ✅ Display all FAQs
- ✅ Filter by category
- ✅ Search FAQs
- ✅ Track views

### Banners Module

**Admin Dashboard**:
- ✅ Create banner
- ✅ Set position (top, sidebar, footer)
- ✅ Set display dates
- ✅ Add action URL
- ✅ Track impressions/clicks

**Mobile App Will**:
- ✅ Display active banners
- ✅ Record impressions
- ✅ Record clicks
- ✅ Navigate on tap

### Invoices Module

**Admin Dashboard**:
- ✅ Create invoice
- ✅ Send to customer (email)
- ✅ Update payment status
- ✅ View payment history

**Mobile App Will**:
- ✅ Display customer invoices (if logged in)
- ✅ View invoice details
- ✅ Track payment status
- ✅ Download invoice PDF

### And More...

Same pattern for:
- Affiliates ↔ Mobile Affiliate Dashboard
- Payouts ↔ Mobile Payout Tracking
- Shipping ↔ Mobile Shipment Tracking
- Notifications ↔ Mobile Notification Feed
- Customers ↔ Mobile Customer Profile

---

## Firestore Security Rules

To allow mobile app to read (but not write) published content:

```javascript
// firebase.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // News - readable if published
    match /news_ticker/{document=**} {
      allow read: if resource.data.status == 'published';
      allow write: if isAdmin();
    }
    
    // Pages - readable if published
    match /content_pages/{document=**} {
      allow read: if resource.data.status == 'published';
      allow write: if isAdmin();
    }
    
    // FAQs - readable if published
    match /faqs/{document=**} {
      allow read: if resource.data.isPublished == true;
      allow write: if isAdmin();
    }
    
    // Banners - readable if active
    match /banners/{document=**} {
      allow read: if resource.data.isActive == true;
      allow write: if isAdmin();
    }
    
    // Invoices - readable if your own
    match /invoices/{document=**} {
      allow read: if request.auth.uid == resource.data.customerId;
      allow write: if isAdmin();
    }
    
    function isAdmin() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
```

---

## Implementation Checklist

### When Mobile App is Ready

- [ ] Copy mobile app to `c:\projects\admin\mobile`
- [ ] Configure Firebase in mobile app (same project)
- [ ] Create models directory: `mobile/lib/features/[module]/models/`
- [ ] Create repositories: `mobile/lib/features/[module]/repositories/`
- [ ] Create providers: `mobile/lib/features/[module]/providers/`
- [ ] Create screens: `mobile/lib/features/[module]/screens/`
- [ ] Test: Create news in admin → appears in mobile ✅
- [ ] Test: Update news in admin → mobile refreshes ✅
- [ ] Test: Delete news in admin → mobile updates ✅
- [ ] Verify: No hardcoded strings in mobile app ✅
- [ ] Verify: All data from Firestore ✅
- [ ] Deploy Cloud Functions: `firebase deploy --only functions`
- [ ] Test: Email sending works ✅
- [ ] Test: Push notifications work ✅
- [ ] Launch to production ✅

---

## Key Principles

### 1. Single Source of Truth
- One Firestore database
- Admin writes
- Mobile reads
- No duplication

### 2. Real-time Sync
- Mobile subscribes to Firestore streams
- Updates appear within milliseconds
- No polling needed

### 3. No Hardcoding
- Admin: All data in Firestore
- Mobile: All data from Firestore
- Configuration in Firestore

### 4. Smart Seeding
- Sample data seeds once
- Checks if collection exists first
- Never overwrites existing data

### 5. Same Architecture
- Admin and Mobile use same:
  - Models (NewsTicker, Invoice, etc.)
  - Repositories (Firestore queries)
  - Riverpod providers
  - Data validation

---

## Example: Creating News Item End-to-End

### Admin Dashboard Creates News

```dart
// Step 1: Admin types title and content
final newsItem = NewsTicker(
  id: 'news_124',
  title: 'Flash Sale Today!',
  content: 'Everything 50% off for 24 hours',
  imageUrl: 'https://example.com/flash-sale.jpg',
  priority: 5,
  status: NewsTickerStatus.published,
  publishedAt: DateTime.now(),
);

// Step 2: Admin clicks "Create News"
await ref.read(newsTickerRepositoryProvider)
    .createNewsItem(newsItem);
```

### Behind the Scenes (Admin)

```dart
// Repository saves to Firestore
Future<void> createNewsItem(NewsTicker news) async {
  await _firestore
      .collection('news_ticker')  // Firestore collection
      .doc(news.id)
      .set(news.toMap());  // JSON stored in cloud
}
```

### Firestore Document Created

```json
news_ticker/news_124 {
  "id": "news_124",
  "title": "Flash Sale Today!",
  "content": "Everything 50% off for 24 hours",
  "imageUrl": "https://example.com/flash-sale.jpg",
  "priority": 5,
  "status": "published",
  "publishedAt": Timestamp,
  "createdAt": Timestamp,
  "updatedAt": Timestamp,
  "viewCount": 0
}
```

### Mobile App Receives Update (Real-time)

```dart
// Mobile subscribes to published news
final newsStream = ref.watch(publishedNewsStreamProvider);

// StreamProvider listens to Firestore
Stream<List<NewsTicker>> streamPublishedNews() {
  return _firestore
      .collection('news_ticker')  // Same collection
      .where('status', isEqualTo: 'published')
      .snapshots()  // Real-time listener
      .map((snapshot) => [
        for (final doc in snapshot.docs)
          NewsTicker.fromFirestore(doc)
      ]);
}
```

### Mobile App Displays News

```dart
// Widget receives updated data
@override
Widget build(BuildContext context, WidgetRef ref) {
  final newsAsync = ref.watch(publishedNewsStreamProvider);
  
  return newsAsync.when(
    data: (newsList) {
      // newsList now includes: "Flash Sale Today!"
      return ListView.builder(
        itemCount: newsList.length,
        itemBuilder: (context, index) {
          final news = newsList[index];
          return NewsCard(
            title: news.title,  // "Flash Sale Today!"
            content: news.content,  // "Everything 50% off..."
            image: news.imageUrl,
          );
        },
      );
    },
  );
}
```

### User Sees News (Within 1-2 seconds) ✅

Mobile screen:
```
📱 MOBILE APP
═══════════════════════════════════════════
  News Ticker

  Flash Sale Today!
  Everything 50% off for 24 hours
  [IMAGE]

  Earlier News...
═══════════════════════════════════════════
```

---

## Summary

✅ **Admin Dashboard**: Creates content in Firestore  
✅ **Firestore**: Stores data once, serves both apps  
✅ **Mobile App**: Reads from Firestore, displays to users  
✅ **Real-time**: Updates propagate within milliseconds  
✅ **No Hardcoding**: Everything configurable in Firestore  
✅ **Smart Seeding**: Sample data loads once on first run  

**When you bring the mobile app, this architecture just works!** 🚀

---

**Status**: ✅ ARCHITECTURE READY | Admin: ✅ READY | Mobile: 🔄 READY TO INTEGRATE

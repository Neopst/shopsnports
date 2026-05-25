# Mobile App Integration Guide - News Ticker & Content Modules

**Purpose**: Step-by-step guide to integrate the mobile app with the admin dashboard Firestore data

---

## Pre-Integration Checklist

### **What's Ready in Admin Dashboard**
- ✅ Firestore database with sample data
- ✅ News Ticker collection (`news_ticker`) - 5 sample items
- ✅ Content Pages collection (`content_pages`) - 5 sample items
- ✅ FAQs collection (`faqs`) - 7 sample items
- ✅ Banners collection (`banners`) - 4 sample items
- ✅ Email Templates collection (`email_templates`) - 7 sample items
- ✅ Analytics tracking (view count, clicks, impressions)
- ✅ Real-time stream support

### **Data Size**
- **Total Collections**: 6
- **Total Sample Documents**: 28
- **Storage Size**: < 1 MB (all demo data)
- **Ready for Scale**: Yes (Firestore auto-scales)

---

## Step 1: Set Up Mobile App Project

### **1.1 Create New Flutter Project** (if not already created)
```bash
flutter create shopsnports_mobile
cd shopsnports_mobile
```

### **1.2 Add Firebase Dependencies**
```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^2.24.0
  cloud_firestore: ^4.13.0
  firebase_messaging: ^14.6.0  # For notifications
  riverpod: ^2.4.0  # Same state management as admin
  go_router: ^12.0.0  # For navigation
  intl: ^0.19.0  # Date formatting
```

### **1.3 Install Dependencies**
```bash
flutter pub get
```

---

## Step 2: Firebase Project Configuration

### **2.1 Use Same Firebase Project**

```dart
// main.dart
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize with same Firebase project as admin dashboard
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}
```

### **2.2 Download google-services.json (Android)**
1. Go to Firebase Console
2. Project Settings → Download google-services.json
3. Place in `android/app/`

### **2.3 Set Up google-services.json (iOS)**
1. Download GoogleService-Info.plist from Firebase Console
2. Add to Xcode project

### **2.4 Update Firestore Security Rules**

```javascript
// In Firebase Console: Firestore Rules

rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow public read for published content
    match /news_ticker/{document=**} {
      allow read: if resource.data.status == 'published';
      allow write: if request.auth.uid != null && hasAdminRole();
    }
    
    match /content_pages/{document=**} {
      allow read: if resource.data.status == 'published';
      allow write: if request.auth.uid != null && hasAdminRole();
    }
    
    match /faqs/{document=**} {
      allow read: if resource.data.isPublished == true;
      allow write: if request.auth.uid != null && hasAdminRole();
    }
    
    match /banners/{document=**} {
      allow read: if resource.data.isActive == true;
      allow write: if request.auth.uid != null && hasAdminRole();
    }
    
    match /email_templates/{document=**} {
      allow write: if request.auth.uid != null && hasAdminRole();
    }
    
    // Helper function for admin role
    function hasAdminRole() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
```

---

## Step 3: Create Models (Mirror Admin Dashboard Models)

### **3.1 News Ticker Model**

```dart
// lib/features/news_ticker/models/news_ticker.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum NewsTickerStatus { draft, published, scheduled, archived, expired }

class NewsTicker {
  final String id;
  final String title;
  final String content;
  final String? imageUrl;
  final int priority;
  final NewsTickerStatus status;
  final DateTime publishedAt;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final int viewCount;

  NewsTicker({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.priority,
    required this.status,
    required this.publishedAt,
    this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.viewCount = 0,
  });

  bool get isPublished => status == NewsTickerStatus.published && !isExpired;
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  factory NewsTicker.fromJson(Map<String, dynamic> json) {
    return NewsTicker(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      imageUrl: json['imageUrl'] as String?,
      priority: json['priority'] as int? ?? 3,
      status: NewsTickerStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => NewsTickerStatus.draft,
      ),
      publishedAt: (json['publishedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (json['expiresAt'] as Timestamp?)?.toDate(),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: json['createdBy'] as String? ?? 'system',
      viewCount: json['viewCount'] as int? ?? 0,
    );
  }

  factory NewsTicker.fromFirestore(DocumentSnapshot doc) {
    return NewsTicker.fromJson({...doc.data() as Map, 'id': doc.id});
  }
}
```

### **3.2 ContentPage, FAQ, Banner Models**

```dart
// Similar structure to News Ticker
// Follow same pattern for:
// - lib/features/content/models/content_page.dart
// - lib/features/content/models/faq.dart
// - lib/features/content/models/banner.dart
```

---

## Step 4: Create Repositories

### **4.1 News Ticker Repository**

```dart
// lib/features/news_ticker/repositories/news_ticker_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/news_ticker.dart';

class NewsTickerRepository {
  final FirebaseFirestore _firestore;

  NewsTickerRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // Get published news items
  Future<List<NewsTicker>> getPublishedNewsItems({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('news_ticker')
          .where('status', isEqualTo: 'published')
          .orderBy('publishedAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => NewsTicker.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch news: $e');
    }
  }

  // Stream for real-time updates
  Stream<List<NewsTicker>> streamPublishedNews() {
    return _firestore
        .collection('news_ticker')
        .where('status', isEqualTo: 'published')
        .orderBy('publishedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => NewsTicker.fromFirestore(doc))
              .toList(),
        );
  }

  // Get single news item
  Future<NewsTicker?> getNewsById(String id) async {
    try {
      final doc = await _firestore.collection('news_ticker').doc(id).get();
      if (!doc.exists) return null;
      return NewsTicker.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to fetch news detail: $e');
    }
  }

  // Track view
  Future<void> trackNewsView(String id) async {
    try {
      await _firestore
          .collection('news_ticker')
          .doc(id)
          .update({
            'viewCount': FieldValue.increment(1),
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      print('Failed to track view: $e');
    }
  }
}
```

### **4.2 Content Repository** (Similar pattern)

```dart
// lib/features/content/repositories/content_repository.dart
// Implement methods for:
// - getPublishedPages()
// - getPageBySlug(slug)
// - getFAQsByCategory(category)
// - getActiveBanners()
// - recordBannerImpression(id)
// - recordBannerClick(id)
```

---

## Step 5: Create Riverpod Providers

### **5.1 News Ticker Provider**

```dart
// lib/features/news_ticker/providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'repositories/news_ticker_repository.dart';
import 'models/news_ticker.dart';

final newsRepositoryProvider = Provider((ref) {
  return NewsTickerRepository();
});

// Real-time stream of published news
final publishedNewsStreamProvider =
    StreamProvider<List<NewsTicker>>((ref) {
  final repository = ref.watch(newsRepositoryProvider);
  return repository.streamPublishedNews();
});

// Single news item by ID
final newsByIdProvider =
    FutureProvider.family<NewsTicker?, String>((ref, id) async {
  final repository = ref.watch(newsRepositoryProvider);
  return repository.getNewsById(id);
});
```

---

## Step 6: Create UI Screens

### **6.1 News Ticker Widget** (Home Screen)

```dart
// lib/features/news_ticker/screens/news_ticker_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';

class NewsTickerWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsStream = ref.watch(publishedNewsStreamProvider);

    return newsStream.when(
      data: (newsList) {
        if (newsList.isEmpty) {
          return const SizedBox.shrink();
        }

        return ListView.builder(
          itemCount: newsList.length,
          itemBuilder: (context, index) {
            final news = newsList[index];
            return NewsTickerCard(news: news);
          },
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
    );
  }
}

class NewsTickerCard extends ConsumerWidget {
  final NewsTicker news;

  const NewsTickerCard({required this.news});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        leading: news.imageUrl != null
            ? Image.network(news.imageUrl!, width: 80, fit: BoxFit.cover)
            : null,
        title: Text(news.title),
        subtitle: Text(news.content),
        trailing: Text('Priority: ${news.priority}'),
        onTap: () {
          // Track view when tapped
          ref.read(newsRepositoryProvider).trackNewsView(news.id);
          // Navigate to detail screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewsDetailScreen(newsId: news.id),
            ),
          );
        },
      ),
    );
  }
}
```

### **6.2 FAQs Screen**

```dart
// lib/features/content/screens/faqs_screen.dart

class FAQsScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<FAQsScreen> createState() => _FAQsScreenState();
}

class _FAQsScreenState extends ConsumerState<FAQsScreen> {
  String? selectedCategory;

  @override
  Widget build(BuildContext context) {
    final faqStream = ref.watch(
      faqsByCategory(selectedCategory ?? 'all'),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('FAQs')),
      body: Column(
        children: [
          // Category filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                'account', 'payment', 'shipping', 'returns', 'affiliate'
              ]
                  .map((category) => Padding(
                        padding: const EdgeInsets.all(8),
                        child: ChoiceChip(
                          label: Text(category),
                          selected: selectedCategory == category,
                          onSelected: (selected) {
                            setState(() {
                              selectedCategory = selected ? category : null;
                            });
                          },
                        ),
                      ))
                  .toList(),
            ),
          ),
          // FAQ list
          Expanded(
            child: faqStream.when(
              data: (faqs) => ListView.builder(
                itemCount: faqs.length,
                itemBuilder: (context, index) {
                  final faq = faqs[index];
                  return ExpansionTile(
                    title: Text(faq.question),
                    children: [Text(faq.answer)],
                  );
                },
              ),
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => Text('Error: $error'),
            ),
          ),
        ],
      ),
    );
  }
}
```

### **6.3 Info Pages Screen** (About, Terms, etc.)

```dart
// lib/features/content/screens/info_page_screen.dart

class InfoPageScreen extends ConsumerWidget {
  final String slug;

  const InfoPageScreen({required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageAsync = ref.watch(pageBySlugProvider(slug));

    return pageAsync.when(
      data: (page) {
        if (page == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Page Not Found')),
            body: const Center(child: Text('Page not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(title: Text(page.title)),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Html(data: page.content), // Use flutter_html package
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Error: $error')),
      ),
    );
  }
}
```

---

## Step 7: Add to Home Screen

```dart
// lib/screens/home_screen.dart

class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('ShopsNPorts')),
      body: ListView(
        children: [
          // News Ticker Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Latest News',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          SizedBox(
            height: 200,
            child: NewsTickerWidget(),
          ),
          
          // Banners Section
          BannersCarousel(),
          
          // Other sections...
        ],
      ),
    );
  }
}
```

---

## Step 8: Test Data Matching

### **Verification Steps**

1. **Run Mobile App**
   ```bash
   flutter run
   ```

2. **Check News Ticker** (Should show 5 news items)
   ```
   ✅ "Welcome to ShopsNPorts Admin Dashboard"
   ✅ "New Feature: Real-time Analytics"
   ✅ "System Maintenance Scheduled"
   ✅ "Affiliate Commission Rate Increase"
   ✅ "New Payment Gateway Integrated"
   ```

3. **Check FAQs** (Should show 7 FAQs with categories)
   ```
   ✅ Account (2 items)
   ✅ Payment (1 item)
   ✅ Shipping (2 items)
   ✅ Returns (1 item)
   ✅ Affiliate (1 item)
   ```

4. **Check Info Pages** (Should show About, Terms, etc.)
   ```
   ✅ /about-us
   ✅ /terms-and-conditions
   ✅ /privacy-policy
   ✅ /shipping-policy
   ✅ /return-refund-policy
   ```

5. **Check Banners** (Should show 4 active banners)
   ```
   ✅ "Welcome to ShopsNPorts" (hero)
   ✅ "Flash Sale - 50% Off" (promo)
   ✅ "Affiliate Program" (sidebar)
   ✅ "Free Shipping Over N10000" (secondary)
   ```

### **Real-time Test**

1. In Admin Dashboard: Create new news item
2. In Mobile App: Should appear instantly (if streaming)
3. Admin deletes news item
4. Mobile App: News automatically disappears

---

## Step 9: Handle Offline Caching

### **Enable Firestore Offline Persistence**

```dart
// In main.dart after Firebase init
await FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: true,
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);
```

**Result**: Content loads instantly from cache, then syncs when online

---

## Step 10: Deploy & Monitor

### **Before Production**

- ✅ Test all features work offline
- ✅ Verify real-time updates
- ✅ Check data matching with admin dashboard
- ✅ Test on Android & iOS
- ✅ Verify Firestore rules allow read access
- ✅ Monitor Firestore costs

### **Production Monitoring**

```dart
// Log Firestore access
FirebaseFirestore.instance.collection('news_ticker')
    .where('status', isEqualTo: 'published')
    .snapshots()
    .listen(
      (snapshot) => print('News updated: ${snapshot.docs.length} items'),
      onError: (error) => print('Error: $error'),
    );
```

---

## Summary: Expected Results

### **After Integration**

✅ Mobile app shows 5 sample news items  
✅ Mobile app shows 7 FAQs with categories  
✅ Mobile app shows 5 info pages (About, Terms, etc.)  
✅ Mobile app shows 4 promotional banners  
✅ Real-time updates when admin creates/edits content  
✅ Analytics tracking (views, clicks, impressions)  
✅ Offline access with caching  
✅ **Zero hardcoded content in mobile app code**

### **Admin Dashboard Controls Everything**

- Create/edit news → Appears in mobile instantly
- Add FAQ → Mobile users see it immediately
- Create banner → Analytics start tracking clicks
- Modify email template → New emails use updated template
- Enable/disable content → Mobile app respects status

---

**This is a clean, scalable content management architecture that grows with your platform!**

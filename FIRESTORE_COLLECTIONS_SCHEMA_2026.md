# Firestore Collections Schema - ShopsNPorts Shipping Platform
**Date:** February 11, 2026  
**Status:** 📋 READY FOR REVIEW & APPROVAL  
**Phase:** 2 - Firebase Integration  

---

## Executive Summary

This document defines the **complete Firestore database schema** for the ShopsNPorts shipping/cargo platform. All collections listed below are required to be created in Firebase Console before mobile app data binding begins.

**Key Principles:**
- ✅ Mobile app fetches all content from Firestore (zero hardcoded values)
- ✅ Web admin dashboard manages all content
- ✅ Real-time updates flow instantly to mobile app
- ✅ Collections support Deep Blue (#003366) & Deep Yellow (#FFB81C) theme from config

---

## Part 1: Public Content Collections (Read by Mobile App)

### 1️⃣ Collection: `banners`
**Purpose:** Carousel slides and promotional content for home screen  
**Access:** Public read (mobile app), Admin write (web dashboard)

```json
banners/
├── banner_001/
│   ├── id: "banner_001"
│   ├── title: "Fast & Reliable Shipping"
│   ├── subtitle: "Shipping your cargo with care"
│   ├── imageUrl: "https://storage.googleapis.com/.../banner1.jpg"
│   ├── position: "HOME_CAROUSEL"  // HOME_TOP, HOME_CAROUSEL, HOME_BOTTOM
│   ├── displayOrder: 1
│   ├── isActive: true
│   ├── startDate: Timestamp(2026-02-11)
│   ├── endDate: Timestamp(2026-12-31)
│   ├── impressions: 0  // Track views
│   ├── clicks: 0  // Track interactions
│   ├── createdAt: Timestamp(2026-02-11)
│   ├── updatedAt: Timestamp(2026-02-11)
│   ├── createdBy: "admin1"
│   └── updatedBy: "admin1"
├── banner_002/
│   └── (same structure)
├── banner_003/
│   └── (same structure)
└── banner_004/
    └── (same structure)
```

**Sample Data (4 banners for initial seed):**
```
1. "Fast & Reliable Shipping" → trending feature
2. "Competitive Rates Guaranteed" → price advantage
3. "Real-Time Tracking" → tech advantage
4. "Become an Affiliate Agent" → partnership
```

**Mobile App Usage:**
```dart
// Stream from Firestore
final bannerProvider = StreamProvider<List<Banner>>((ref) async* {
  yield* FirebaseFirestore.instance
    .collection('banners')
    .where('isActive', isEqualTo: true)
    .where('position', isEqualTo: 'HOME_CAROUSEL')
    .snapshots()
    .map((snapshot) => snapshot.docs
        .map((doc) => Banner.fromFirestore(doc))
        .toList());
});
```

---

### 2️⃣ Collection: `news_ticker`
**Purpose:** Announcements, updates, news items for mobile app feed  
**Access:** Public read (published items only), Admin write (web dashboard)

```json
news_ticker/
├── news_001/
│   ├── id: "news_001"
│   ├── title: "Welcome to ShopsNPorts Shipping"
│   ├── content: "We're excited to launch the cargo shipping platform..."
│   ├── priority: 10  // Higher = display first
│   ├── status: "published"  // draft, published, archived
│   ├── imageUrl: "https://storage.googleapis.com/.../news1.jpg"
│   ├── publishedAt: Timestamp(2026-02-11)
│   ├── expiresAt: Timestamp(2026-03-11)  // Auto-hide after this
│   ├── createdAt: Timestamp(2026-02-11)
│   ├── createdBy: "admin1"
│   └── updatedAt: Timestamp(2026-02-11)
├── news_002/
│   ├── title: "Express Air Shipping Now Available"
│   ├── status: "published"
│   └── (same fields)
├── news_003/
│   ├── title: "Join Our Affiliate Program"
│   ├── status: "published"
│   └── (same fields)
├── news_004/
│   ├── title: "New Security Features Released"
│   ├── status: "published"
│   └── (same fields)
└── news_005/
    ├── title: "Customer Support Improvements"
    ├── status: "published"
    └── (same fields)
```

**Mobile App Usage:**
```dart
// Stream published news only
final newsProvider = StreamProvider<List<NewsTicker>>((ref) async* {
  yield* FirebaseFirestore.instance
    .collection('news_ticker')
    .where('status', isEqualTo: 'published')
    .where('expiresAt', isGreaterThan: Timestamp.now())
    .orderBy('priority', descending: true)
    .orderBy('publishedAt', descending: true)
    .snapshots()
    .map((snapshot) => snapshot.docs
        .map((doc) => NewsTicker.fromFirestore(doc))
        .toList());
});
```

---

### 3️⃣ Collection: `content_pages`
**Purpose:** Static pages - Terms, Privacy, FAQs, Help documentation  
**Access:** Public read (published pages), Admin write (web dashboard)  
**Existing:** Already implemented in web admin dashboard ✅

```json
content_pages/
├── terms_of_service/
│   ├── id: "terms_of_service"
│   ├── slug: "terms-of-service"
│   ├── title: "Terms of Service"
│   ├── description: "ShopsNPorts shipping platform terms and conditions"
│   ├── content: "<h1>Terms of Service</h1><p>...</p>"  // HTML or Markdown
│   ├── contentType: "HTML"  // TEXT, HTML, MARKDOWN
│   ├── tags: ["legal", "terms"]
│   ├── status: "published"  // draft, published, archived
│   ├── publishedAt: Timestamp(2026-02-11)
│   ├── publishedBy: "admin1"
│   ├── createdAt: Timestamp(2026-02-11)
│   ├── createdBy: "admin1"
│   ├── updatedAt: Timestamp(2026-02-11)
│   ├── updatedBy: "admin1"
│   ├── viewCount: 0
│   └── seoKeywords: "shipping, cargo, freight, terms"
├── privacy_policy/
│   ├── slug: "privacy-policy"
│   ├── tags: ["legal", "privacy"]
│   └── (same fields)
├── how_it_works/
│   ├── slug: "how-it-works"
│   ├── tags: ["help", "guide"]
│   └── (same fields)
├── FAQ/
│   ├── slug: "frequently-asked-questions"
│   ├── tags: ["help", "faq"]
│   └── (same fields)
└── shipping_guide/
    ├── slug: "shipping-guide"
    ├── tags: ["help", "shipping"]
    └── (same fields)
```

**Sample Content to Seed:**
1. **Terms of Service** - Full legal terms (2000+ words)
2. **Privacy Policy** - GDPR/data protection (2000+ words)
3. **How It Works** - Step-by-step shipping guide
4. **FAQ** - Frequently asked questions
5. **Shipping Guide** - Best practices for shipping cargo

**Mobile App Usage:**
```dart
// Fetch specific legal page
final legalPageProvider = FutureProvider.family<ContentPage?, String>(
  (ref, slug) async {
    final doc = await FirebaseFirestore.instance
      .collection('content_pages')
      .where('slug', isEqualTo: slug)
      .where('status', isEqualTo: 'published')
      .limit(1)
      .get();
    
    return doc.docs.isEmpty 
      ? null 
      : ContentPage.fromFirestore(doc.docs.first);
  }
);
```

---

### 4️⃣ Collection: `config` (Singleton Document)
**Purpose:** Application-wide configuration, theme colors, contact info  
**Access:** Public read, Admin write (web dashboard)  
**Important:** This is a SINGLE document at `config/contacts`, not multiple documents

```json
config/
└── contacts/  // SINGLETON DOCUMENT
    ├── supportPhone: "+234 XXX XXX XXXX"
    ├── supportWhatsapp: "+234 XXX XXX XXXX"
    ├── supportEmail: "support@shopsnports.com"
    ├── techSupportEmail: "tech@shopsnports.com"
    ├── faqUrl: "https://shopsnports.com/faq"
    ├── theme: {
    │   ├── primaryColor: "#003366"     // Deep Blue
    │   ├── accentColor: "#FFB81C"      // Deep Yellow
    │   ├── successColor: "#27AE60"     // Green
    │   ├── warningColor: "#E67E22"     // Orange
    │   └── errorColor: "#E74C3C"       // Red
    ├── features: {
    │   ├── analyticsEnabled: true
    │   ├── affiliateProgramActive: true
    │   └── maintenanceMode: false
    ├── appVersion: "1.0.0"
    ├── minRequiredVersion: "1.0.0"
    ├── updatedAt: Timestamp(2026-02-11)
    └── updatedBy: "admin1"
```

**Mobile App Usage:**
```dart
// Fetch config once and cache
final configProvider = FutureProvider<AppConfig>((ref) async {
  final doc = await FirebaseFirestore.instance
    .collection('config')
    .doc('contacts')
    .get();
  
  return AppConfig.fromFirestore(doc);
});

// Use in help_center_screen.dart
final config = await ref.read(configProvider.future);
launch('tel:${config.supportPhone}');
launch('https://wa.me/${config.supportWhatsapp}');
```

---

## Part 2: Shipping Platform Collections (Core Features)

### 5️⃣ Collection: `shippingRequests`
**Purpose:** Customer shipping requests, quotes, order history  
**Access:** User read (own requests), Admin write  
**Status:** Already partially implemented ✅

```json
shippingRequests/
├── req_001/
│   ├── id: "req_001"
│   ├── userId: "user_001"  // Shipper/Customer ID
│   ├── affiliateId: "aff_001"  // Referral (optional)
│   ├── shippingType: "AIR"  // AIR, SEA, LAND
│   ├── originAddress: {
│   │   ├── city: "Lagos"
│   │   ├── state: "Lagos"
│   │   ├── country: "Nigeria"
│   │   └── coordinates: {lat: 6.5244, lng: 3.3792}
│   ├── destinationAddress: {
│   │   └── (same structure)
│   ├── cargoDetails: {
│   │   ├── description: "Electronics shipment"
│   │   ├── weight: 25.5  // kg
│   │   ├── dimensions: {
│   │   │   ├── width: 50
│   │   │   ├── height: 40
│   │   │   └── depth: 30  // cm
│   │   ├── itemValue: 500000  // in currency
│   │   ├── hsCode: "8471.30"  // Harmonized tariff
│   │   └── cargoType: "ELECTRONICS"
│   ├── shippingOptions: {
│   │   ├── requiresInsurance: true
│   │   ├── requiresPickup: true
│   │   ├── requiresDelivery: true
│   │   └── expressDelivery: false
│   ├── estimatedCost: 150000
│   ├── actualCost: null  // Set when quote accepted
│   ├── status: "PENDING"  // PENDING, QUOTED, ACCEPTED, IN_TRANSIT, DELIVERED, CANCELLED
│   ├── trackingNumber: null  // Generated when in transit
│   ├── quotes: [
│   │   {
│   │   │   ├── quoteId: "q_001"
│   │   │   ├── affiliateId: "aff_001"
│   │   │   ├── price: 150000
│   │   │   ├── estimatedDays: 3
│   │   │   ├── status: "PENDING"  // PENDING, ACCEPTED, REJECTED
│   │   │   └── createdAt: Timestamp(2026-02-11)
│   │   └── (more quotes)
│   ├── paymentStatus: "PENDING"  // PENDING, COMPLETED, FAILED
│   ├── createdAt: Timestamp(2026-02-11)
│   ├── updatedAt: Timestamp(2026-02-11)
│   └── deliveryDate: null
└── (more requests)
```

---

### 6️⃣ Collection: `users`
**Purpose:** User profiles (customers, shippers, affiliates)  
**Access:** User read (own), Admin read all  
**Status:** Already implemented ✅

```json
users/
├── user_001/
│   ├── id: "user_001"  // Firebase Auth UID
│   ├── email: "customer@example.com"
│   ├── displayName: "John Shipper"
│   ├── phoneNumber: "+234XXXXXXXXXX"
│   ├── profileImageUrl: "https://..."
│   ├── userType: "CUSTOMER"  // CUSTOMER, SHIPPER, AFFILIATE
│   ├── status: "ACTIVE"  // ACTIVE, SUSPENDED
│   ├── role: "user"  // user, admin, super_admin
│   ├── businessName: "JohnShips Logistics"  // For affiliates
│   ├── kycStatus: "VERIFIED"  // For affiliates
│   ├── affiliateStatus: "APPROVED"  // For affiliates
│   ├── affiliateCode: "JS2026001"  // Unique referral code
│   ├── commissionRate: 10  // Percentage for affiliates
│   ├── createdAt: Timestamp(2026-02-11)
│   ├── updatedAt: Timestamp(2026-02-11)
│   └── lastLoginAt: Timestamp(2026-02-11)
└── (more users)
```

---

### 7️⃣ Collection: `invoices`
**Purpose:** Shipping invoices and payment history  
**Access:** User read (own), Admin read all

```json
invoices/
├── inv_001/
│   ├── id: "inv_001"
│   ├── userId: "user_001"
│   ├── shippingRequestId: "req_001"
│   ├── invoiceNumber: "INV-2026-0001"
│   ├── amount: 150000
│   ├── currency: "NGN"
│   ├── status: "PAID"  // PENDING, PAID, OVERDUE, CANCELLED
│   ├── issueDate: Timestamp(2026-02-11)
│   ├── dueDate: Timestamp(2026-02-21)
│   ├── paidDate: Timestamp(2026-02-15)
│   ├── createdAt: Timestamp(2026-02-11)
│   └── updatedAt: Timestamp(2026-02-11)
└── (more invoices)
```

---

### 8️⃣ Collection: `affiliates`
**Purpose:** Affiliate/agent profile and commission tracking  
**Access:** Affiliate read (own), Admin read all

```json
affiliates/
├── aff_001/
│   ├── id: "aff_001"
│   ├── userId: "user_001"
│   ├── businessName: "FastShip Agents"
│   ├── bankName: "First Bank Nigeria"
│   ├── bankAccountNumber: "1234567890"
│   ├── bankAccountName: "FastShip Agents Ltd"
│   ├── commissionRate: 10  // Percentage
│   ├── totalEarnings: 250000  // Total commission earned
│   ├── totalReferrals: 15  // Shipments referred
│   ├── status: "APPROVED"  // PENDING, APPROVED, SUSPENDED
│   ├── affiliateCode: "FS2026001"
│   ├── createdAt: Timestamp(2026-02-11)
│   ├── updatedAt: Timestamp(2026-02-11)
│   └── approvedAt: Timestamp(2026-02-11)
└── (more affiliates)
```

---

### 9️⃣ Collection: `notifications`
**Purpose:** In-app notifications and alerts  
**Access:** User read (own), Admin write

```json
notifications/
├── notif_001/
│   ├── id: "notif_001"
│   ├── userId: "user_001"
│   ├── title: "Shipment Dispatched"
│   ├── message: "Your cargo #req_001 has been dispatched"
│   ├── type: "SHIPPING"  // SHIPPING, AFFILIATE, SYSTEM, PROMOTIONAL
│   ├── status: "UNREAD"  // UNREAD, READ, ARCHIVED
│   ├── actionUrl: "/shipping/track/req_001"  // Deep link
│   ├── timestamp: Timestamp(2026-02-11)
│   ├── readAt: null
│   └── createdAt: Timestamp(2026-02-11)
└── (more notifications)
```

---

## Part 3: Supporting Collections

### 🔟 Collection: `payouts`
**Purpose:** Affiliate commission payouts  
**Access:** Affiliate read (own), Admin read all

```json
payouts/
├── payout_001/
│   ├── id: "payout_001"
│   ├── affiliateId: "aff_001"
│   ├── amount: 50000
│   ├── currency: "NGN"
│   ├── status: "COMPLETED"  // PENDING, PROCESSING, COMPLETED, FAILED
│   ├── paymentMethod: "BANK_TRANSFER"
│   ├── transactionId: "TXN123456"
│   ├── createdAt: Timestamp(2026-02-11)
│   ├── completedAt: Timestamp(2026-02-12)
│   └── notes: "Monthly payout for February"
└── (more payouts)
```

---

## Part 4: Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper function to check user role
    function hasRole(role) {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == role;
    }

    // BANNERS - Public read, Admin write
    match /banners/{document=**} {
      allow read: if true;
      allow write: if request.auth != null && hasRole('admin');
    }

    // NEWS TICKER - Public read (published only), Admin write
    match /news_ticker/{document=**} {
      allow read: if resource.data.status == 'published';
      allow write: if request.auth != null && hasRole('admin');
    }

    // CONTENT PAGES - Public read (published), Admin write
    match /content_pages/{document=**} {
      allow read: if resource.data.status == 'published';
      allow write: if request.auth != null && hasRole('admin');
    }

    // CONFIG - Public read, Admin write
    match /config/{document=**} {
      allow read: if true;
      allow write: if request.auth != null && hasRole('admin');
    }

    // SHIPPING REQUESTS - User read own, Admin can read all
    match /shippingRequests/{document=**} {
      allow read: if request.auth.uid == resource.data.userId || hasRole('admin');
      allow create: if request.auth != null;
      allow update: if request.auth.uid == resource.data.userId || hasRole('admin');
    }

    // USERS - User read own, Admin read all
    match /users/{userId} {
      allow read: if request.auth.uid == userId || hasRole('admin');
      allow update: if request.auth.uid == userId;
    }

    // INVOICES - User read own, Admin read all
    match /invoices/{document=**} {
      allow read: if request.auth.uid == resource.data.userId || hasRole('admin');
      allow write: if hasRole('admin');
    }

    // AFFILIATES - User read own, Admin read all
    match /affiliates/{document=**} {
      allow read: if request.auth.uid == resource.data.userId || hasRole('admin');
      allow update: if request.auth.uid == resource.data.userId;
    }

    // NOTIFICATIONS - User read own, Admin write
    match /notifications/{document=**} {
      allow read: if request.auth.uid == resource.data.userId;
      allow write: if hasRole('admin');
    }

    // PAYOUTS - User read own, Admin write
    match /payouts/{document=**} {
      allow read: if request.auth.uid == resource.data.userId || hasRole('admin');
      allow write: if hasRole('admin');
    }
  }
}
```

---

## Part 5: Implementation Checklist

### Create Collections in Firebase:
- [ ] `banners` - Product: Carousel
- [ ] `news_ticker` - Announcements
- [ ] `content_pages` - Legal/Help (already exists in web admin)
- [ ] `config` - Configuration (singleton doc: contacts)
- [ ] `shippingRequests` - Core feature (partially exists)
- [ ] `users` - User profiles (exists)
- [ ] `invoices` - Payment history (exists)
- [ ] `affiliates` - Agent profiles (exists)
- [ ] `notifications` - Alerts (exists)
- [ ] `payouts` - Commission tracking (exists)

### Seed Initial Data:
- [ ] 4 banners in `banners` collection
- [ ] 5 news items in `news_ticker` collection
- [ ] 5 legal pages in `content_pages` collection
- [ ] 1 config document in `config/contacts`

### Apply Firestore Security Rules:
- [ ] Copy security rules above into Firestore Console
- [ ] Enable public read for banners, news, legal, config
- [ ] Enable admin write for content management

---

## Part 6: Color Scheme Reference

Used throughout all screens and theme:

```dart
// Deep Blue & Yellow Theme
const Color primaryColor = Color(0xFF003366);      // Deep Blue
const Color accentColor = Color(0xFFFFB81C);       // Deep Yellow
const Color successColor = Color(0xFF27AE60);      // Green
const Color warningColor = Color(0xFFE67E22);      // Orange
const Color errorColor = Color(0xFFE74C3C);        // Red

// Neutrals
const Color darkGrey = Color(0xFF2C3E50);
const Color lightGrey = Color(0xFFECF0F1);
const Color white = Color(0xFFFFFFFF);
const Color black = Color(0xFF000000);
```

---

## Part 7: Next Steps After Approval

Once you **review & approve** this schema:

1. ✅ I'll create all collections in Firebase Console
2. ✅ Seed initial data (banners, news, legal, config)
3. ✅ Build home screen skeleton with Deep Blue/Yellow colors
4. ✅ Wire screens to Firestore data streams
5. ✅ Final polish and refinement

---

## 🎯 Ready for Review?

Please review this schema and let me know:
1. **Any changes to collection structure?**
2. **Additional fields needed?**
3. **Sample data looks good?**
4. **Color scheme approved? (Deep Blue #003366 + Yellow #FFB81C)**

Once approved, we'll move to **creating collections + home screen skeleton** 🚀


# 🔍 FIRESTORE COLLECTIONS AUDIT REPORT

**Date**: January 31, 2026  
**Project**: ShopsNPorts Mobile App  
**Status**: ⚠️ MISSING COLLECTIONS IDENTIFIED  

---

## 📊 FIRESTORE COLLECTIONS - CURRENT STATE

### Collections Defined in Firestore Rules

Based on the admin project's `firestore.rules`, the following collections are configured:

```
✅ DEFINED & CONFIGURED:
├── news_ticker/              (Published news/ticker items)
├── users/                    (User profiles)
├── admin_profiles/           (Admin-specific profiles)
├── settings/                 (User settings)
├── configuration/            (App configuration)
├── activity_logs/            (Activity audit trail)
├── audit_trail/              (Super admin audit)
├── customers/                (Customer data)
├── invoices/                 (Invoices)
├── shippingRequests/         (Primary shipping data)
├── shipments/                (Legacy - backward compatibility)
├── affiliates/               (Affiliate program)
├── payouts/                  (Affiliate payouts)
├── commission_settings/      (Commission configuration)
├── tax_settings/             (Tax configuration)
├── analytics_events/         (Analytics tracking)
├── content_pages/            (CMS content)
├── faqs/                     (FAQ content)
├── banners/                  (Content banners)
└── email_templates/          (Email templates)
```

---

## ⚠️ MISSING COLLECTIONS - CRITICAL

Based on your report, the following collections are **MISSING** from Firestore but required for the app:

### 1. **news_ticker** - ⚠️ DEFINED BUT POSSIBLY EMPTY
```
Collection:     news_ticker
Purpose:        News ticker items, announcements, updates
Status:         ✅ Defined in rules BUT
                ⚠️ Possibly not populated with data
                
Required fields:
  - title (string)
  - content (string)
  - priority (1-10)
  - status (draft, scheduled, published, archived)
  - imageUrl (optional)
  - publishedAt (timestamp)
  - createdBy (user ID)
  - createdAt (timestamp)

Action: Create sample news ticker documents
```

### 2. **banners** - ⚠️ DEFINED BUT POSSIBLY EMPTY
```
Collection:     banners
Purpose:        Content banners, promotions, featured sections
Status:         ✅ Defined in rules BUT
                ⚠️ Possibly not populated with data
                
Required fields:
  - title (string)
  - imageUrl (string)
  - link (string)
  - status (active, inactive)
  - displayOrder (number)
  - startDate (timestamp)
  - endDate (timestamp)

Action: Create sample banner documents
```

### 3. **content_pages** - ⚠️ DEFINED BUT POSSIBLY EMPTY
```
Collection:     content_pages
Purpose:        Static content pages (About, How it Works, etc.)
Status:         ✅ Defined in rules BUT
                ⚠️ Possibly not populated with data
                
Required fields:
  - slug (string - unique identifier)
  - title (string)
  - content (string/HTML)
  - published (boolean)
  - updatedAt (timestamp)

Action: Create sample content page documents
```

### 4. **notifications** - ❌ COMPLETELY MISSING
```
Collection:     notifications (NOT DEFINED IN RULES)
Purpose:        Push notifications, in-app notifications, notification history
Status:         ❌ NOT DEFINED
                ❌ NOT IN FIRESTORE RULES
                
Required fields:
  - userId (string - recipient)
  - title (string)
  - message (string)
  - type (string - shipping, affiliate, system)
  - status (read, unread)
  - timestamp (created date)
  - actionUrl (string - where to navigate)

Action: CREATE THIS COLLECTION AND ADD TO FIRESTORE RULES
```

### 5. **push_notifications** - ❌ COMPLETELY MISSING
```
Collection:     push_notifications (NOT DEFINED IN RULES)
Purpose:        Templates and configuration for push notifications
Status:         ❌ NOT DEFINED
                ❌ NOT IN FIRESTORE RULES
                
Required fields:
  - name (string - notification template name)
  - title (string - template)
  - message (string - template with {placeholders})
  - type (string - shipping_update, affiliate_earnings, etc.)
  - enabled (boolean)
  - createdAt (timestamp)

Action: CREATE THIS COLLECTION AND ADD TO FIRESTORE RULES
```

### 6. **notifications_module** or **notification_settings** - ❌ MISSING
```
Collection:     notification_settings (NOT DEFINED)
Purpose:        User's notification preferences and configuration
Status:         ❌ NOT DEFINED
                ❌ NOT IN FIRESTORE RULES
                
Required fields:
  - userId (string)
  - pushEnabled (boolean)
  - emailEnabled (boolean)
  - inAppEnabled (boolean)
  - types (object - shipping, affiliate, system, etc. - all boolean)
  - frequency (daily, immediate, weekly)
  - quietHours (object - start, end)

Action: CREATE THIS COLLECTION AND ADD TO FIRESTORE RULES
```

---

## 📋 COMPLETE FIRESTORE STRUCTURE - RECOMMENDED

### Collections by Category

#### **Authentication & Users**
```
users/                       ✅ DEFINED
  └── userId/
      ├── email
      ├── displayName
      ├── photoUrl
      ├── role (user, admin, super_admin)
      ├── permissions (array)
      ├── accountStatus
      └── createdAt

admin_profiles/              ✅ DEFINED
  └── adminId/
      ├── title
      ├── department
      ├── bio
      ├── phone
      ├── avatar
      └── adminId
```

#### **Shipping Features** ✅ CORE
```
shippingRequests/            ✅ DEFINED
  └── requestId/
      ├── origin
      ├── destination
      ├── weight
      ├── dimensions
      ├── userId
      ├── status
      ├── estimatedCost
      ├── createdAt
      └── tracking

shipments/                   ✅ DEFINED (legacy)
  └── shipmentId/
      ├── shippingRequestId
      ├── driverId
      ├── status
      └── updatedAt
```

#### **Affiliate Program** ✅ CORE
```
affiliates/                  ✅ DEFINED
  └── affiliateId/
      ├── userId
      ├── status (pending, approved, suspended)
      ├── bankDetails
      ├── taxInfo
      ├── totalEarnings
      ├── createdAt
      └── approvedAt

payouts/                     ✅ DEFINED
  └── payoutId/
      ├── affiliateId
      ├── amount
      ├── status (pending, paid, failed)
      ├── transactionId
      ├── createdAt
      └── completedAt

commission_settings/         ✅ DEFINED
  └── settingId/
      ├── affiliateId
      ├── commissionRate
      ├── currency
      └── updatedAt

tax_settings/                ✅ DEFINED
  └── settingId/
      ├── affiliateId
      ├── taxId
      ├── taxRate
      └── updatedAt
```

#### **Notifications** ⚠️ PARTIALLY MISSING
```
notifications/               ❌ MISSING
  └── notificationId/
      ├── userId (recipient)
      ├── title
      ├── message
      ├── type (shipping_update, affiliate_earnings, system)
      ├── status (read, unread)
      ├── timestamp
      └── actionUrl

push_notifications/          ❌ MISSING
  └── templateId/
      ├── name
      ├── title (template)
      ├── message (template with {userId}, {amount}, etc.)
      ├── type
      ├── enabled
      └── createdAt

notification_settings/       ❌ MISSING
  └── userId/
      ├── pushEnabled
      ├── emailEnabled
      ├── inAppEnabled
      ├── types (object)
      ├── frequency
      └── quietHours
```

#### **Content & Configuration** ✅ PARTIAL
```
news_ticker/                 ✅ DEFINED (may be empty)
  └── tickerId/
      ├── title
      ├── content
      ├── priority
      ├── status
      ├── imageUrl
      ├── publishedAt
      └── createdBy

banners/                     ✅ DEFINED (may be empty)
  └── bannerId/
      ├── title
      ├── imageUrl
      ├── link
      ├── status
      ├── displayOrder
      └── endDate

content_pages/               ✅ DEFINED (may be empty)
  └── pageId/
      ├── slug
      ├── title
      ├── content
      ├── published
      └── updatedAt

faqs/                        ✅ DEFINED
  └── faqId/
      ├── question
      ├── answer
      ├── category
      └── order

email_templates/             ✅ DEFINED
  └── templateId/
      ├── name
      ├── subject
      ├── body (HTML)
      └── createdAt
```

#### **Settings & Admin**
```
settings/                    ✅ DEFINED
  └── userId/
      ├── preferences
      ├── notifications
      ├── privacy
      └── updatedAt

configuration/               ✅ DEFINED
  └── configId/
      ├── key
      ├── value
      ├── type
      └── access (public, authenticated, admin)

activity_logs/               ✅ DEFINED
  └── logId/
      ├── userId
      ├── action
      ├── details
      ├── timestamp
      └── ipAddress

audit_trail/                 ✅ DEFINED
  └── auditId/
      ├── action
      ├── performedBy
      ├── timestamp
      └── changes
```

---

## 🔧 ACTION ITEMS - IMMEDIATE

### Priority 1: Create Missing Notification Collections

**Task 1: Create Firestore Rules for Missing Collections**
```
Collections to add to firestore.rules:

1. notifications/{notificationId}
   - Allow users to read their own notifications
   - Allow admins to create notifications
   
2. push_notifications/{templateId}
   - Allow admins to create/update templates
   - Allow users to read templates
   
3. notification_settings/{userId}
   - Allow users to read/update their own settings
   - Allow admins to read all settings
```

**Task 2: Create Sample Data**
```
notifications/
  - Sample: User receives shipping update
  - Sample: User receives affiliate earnings notification

push_notifications/
  - Template: Shipping Update
  - Template: Affiliate Earnings
  - Template: System Alert

notification_settings/
  - Sample: User preferences (push enabled, quiet hours)
```

### Priority 2: Populate Empty Collections

**News Ticker:**
```
Add at least 3-5 news ticker items:
  - "Welcome to ShopsNPorts"
  - "Shipping Available in 50+ Countries"
  - "Join Our Affiliate Program"
  - "Real-time Tracking Now Available"
```

**Banners:**
```
Add at least 2-3 banners:
  - "Coming Soon: Shipper Dashboard"
  - "Affiliate Program - Earn Commission"
  - "Fast Shipping Worldwide"
```

**Content Pages:**
```
Add required pages:
  - How It Works (slug: how-it-works)
  - About Us (slug: about)
  - FAQ (slug: faq)
  - Contact (slug: contact)
```

### Priority 3: Update pubspec.yaml (if needed)

Verify the mobile app has:
```yaml
firebase_messaging: ^16.0.2     ✅ For push notifications
cloud_firestore: ^6.0.2          ✅ For Firestore access
```

---

## 📝 FIRESTORE RULES UPDATE NEEDED

Add the following to `firestore.rules`:

```firestore
// =========================================================================
// Notifications Collection - IN-APP NOTIFICATIONS
// =========================================================================

match /notifications/{notificationId} {
  // Users can read their own notifications
  allow read: if isAuthenticated() &&
                 resource.data.userId == request.auth.uid;

  // Admins can read all notifications
  allow read: if isAdmin();

  // Only Cloud Functions can create (auto-triggered)
  allow create: if false;

  // Users can mark as read
  allow update: if isAuthenticated() &&
                   request.auth.uid == resource.data.userId &&
                   request.resource.data.diff(resource.data).affectedKeys()
                     .hasOnly(['status']);

  // Only admins can delete
  allow delete: if isAdmin();
}

// =========================================================================
// Push Notifications - TEMPLATES AND CONFIG
// =========================================================================

match /push_notifications/{templateId} {
  // Authenticated users can read templates
  allow read: if isAuthenticated();

  // Admins can create/update templates
  allow write: if isAdmin();

  // Super admin can delete
  allow delete: if isSuperAdmin();
}

// =========================================================================
// Notification Settings - USER PREFERENCES
// =========================================================================

match /notification_settings/{userId} {
  // Users can read their own settings
  allow read: if isAuthenticated() &&
                 request.auth.uid == userId;

  // Users can update their own settings
  allow update: if isAuthenticated() &&
                   request.auth.uid == userId;

  // Admins can read all settings
  allow read: if isAdmin();

  // Create during first signup
  allow create: if isAuthenticated() &&
                   request.auth.uid == userId;

  // Super admin can delete
  allow delete: if isSuperAdmin();
}
```

---

## 📊 SUMMARY

### Collections Status

| Collection | Status | In Rules | Has Data | Action |
|-----------|--------|----------|----------|--------|
| news_ticker | ⚠️ Partial | ✅ Yes | ❓ Unknown | Populate with data |
| banners | ⚠️ Partial | ✅ Yes | ❓ Unknown | Populate with data |
| content_pages | ⚠️ Partial | ✅ Yes | ❓ Unknown | Populate with data |
| notifications | ❌ Missing | ❌ No | ❌ No | **Create + Add Rules** |
| push_notifications | ❌ Missing | ❌ No | ❌ No | **Create + Add Rules** |
| notification_settings | ❌ Missing | ❌ No | ❌ No | **Create + Add Rules** |

### Next Steps

1. ✅ **Verify** which collections have data in Firebase Console
2. 🔧 **Update** firestore.rules with missing collections
3. 📝 **Create** sample documents for empty collections
4. 🔄 **Deploy** updated rules to Firebase
5. ✅ **Verify** mobile app can read all collections

---

**Status**: ⚠️ AUDIT COMPLETE - ACTION ITEMS IDENTIFIED  
**Next**: Update Firestore Rules + Populate Collections


# 🚀 Firebase Manual Seeding Guide - ShopsNPorts

**Date:** February 12, 2026  
**Status:** Ready to seed while Node.js is being set up  
**Collections to Seed:** 4 (banners, news_ticker, content_pages, config)  
**Total Documents:** 13

---

## ⚠️ IMPORTANT SETUP STEPS

1. **Go to:** https://console.firebase.google.com
2. **Select Project:** shopsnports
3. **Navigate:** Build → Firestore Database
4. **View:** Data tab (top of Firestore)

---

## 📋 Collection 1: `banners`

**Total Documents:** 4  
**Purpose:** Carousel promotional content for home screen  
**Tags:** `isActive=true`, `position='HOME_CAROUSEL'`

### Banner 1: Fast & Reliable Shipping

**Document ID:** `banner_001`

**Fields to Add:**

| Field | Type | Value |
|-------|------|-------|
| `id` | String | `banner_001` |
| `title` | String | `Fast & Reliable Shipping` |
| `subtitle` | String | `Shipping your cargo with care` |
| `imageUrl` | String | `https://via.placeholder.com/800x300?text=Fast+Shipping` |
| `position` | String | `HOME_CAROUSEL` |
| `displayOrder` | Number | `1` |
| `isActive` | Boolean | `true` |
| `impressions` | Number | `0` |
| `clicks` | Number | `0` |
| `createdAt` | Timestamp | **Today's date** |
| `createdBy` | String | `admin` |

**Steps to Add in Firebase Console:**
1. Click **"Add document"** in `banners` collection
2. Set Document ID to: `banner_001`
3. Click **"Auto-generated ID"** toggle if needed, then clear it and type `banner_001`
4. Add each field from table above
5. Click **Save**

---

### Banner 2: Affordable Rates

**Document ID:** `banner_002`

| Field | Type | Value |
|-------|------|-------|
| `id` | String | `banner_002` |
| `title` | String | `Affordable Rates` |
| `subtitle` | String | `Competitive pricing for all shipment sizes` |
| `imageUrl` | String | `https://via.placeholder.com/800x300?text=Affordable+Rates` |
| `position` | String | `HOME_CAROUSEL` |
| `displayOrder` | Number | `2` |
| `isActive` | Boolean | `true` |
| `impressions` | Number | `0` |
| `clicks` | Number | `0` |
| `createdAt` | Timestamp | **Today's date** |
| `createdBy` | String | `admin` |

---

### Banner 3: Real-Time Tracking

**Document ID:** `banner_003`

| Field | Type | Value |
|-------|------|-------|
| `id` | String | `banner_003` |
| `title` | String | `Real-Time Tracking` |
| `subtitle` | String | `Know where your cargo is, always` |
| `imageUrl` | String | `https://via.placeholder.com/800x300?text=Real+Time+Tracking` |
| `position` | String | `HOME_CAROUSEL` |
| `displayOrder` | Number | `3` |
| `isActive` | Boolean | `true` |
| `impressions` | Number | `0` |
| `clicks` | Number | `0` |
| `createdAt` | Timestamp | **Today's date** |
| `createdBy` | String | `admin` |

---

### Banner 4: Featured Promo

**Document ID:** `banner_004`

| Field | Type | Value |
|-------|------|-------|
| `id` | String | `banner_004` |
| `title` | String | `New Year Special` |
| `subtitle` | String | `Get 10% off on your first shipment` |
| `imageUrl` | String | `https://via.placeholder.com/800x300?text=New+Year+Special` |
| `position` | String | `HOME_CAROUSEL` |
| `displayOrder` | Number | `4` |
| `isActive` | Boolean | `true` |
| `impressions` | Number | `0` |
| `clicks` | Number | `0` |
| `isFeatured` | Boolean | `true` |
| `createdAt` | Timestamp | **Today's date** |
| `createdBy` | String | `admin` |

---

## 📰 Collection 2: `news_ticker`

**Total Documents:** 5  
**Purpose:** Real-time announcements for home screen  
**Status:** All `published`

### News 1: Welcome Announcement

**Document ID:** `news_001`

| Field | Type | Value |
|-------|------|-------|
| `id` | String | `news_001` |
| `title` | String | `Welcome to ShopsNPorts 2026!` |
| `content` | String | `We're excited to launch our redesigned shipping platform with real-time tracking and better rates. Download the latest version now!` |
| `priority` | Number | `5` |
| `status` | String | `published` |
| `imageUrl` | String | `https://via.placeholder.com/400x200?text=Welcome+2026` |
| `publishedAt` | Timestamp | **Today's date** |
| `publishedBy` | String | `admin` |
| `expiresAt` | Timestamp | **30 days from today** |
| `createdAt` | Timestamp | **Today's date** |
| `createdBy` | String | `admin` |

---

### News 2: Feature Update

**Document ID:** `news_002`

| Field | Type | Value |
|-------|------|-------|
| `id` | String | `news_002` |
| `title` | String | `New Affiliate Program Launched` |
| `content` | String | `Join our affiliate program and earn commissions on every referral. Start earning today with competitive rates!` |
| `priority` | Number | `4` |
| `status` | String | `published` |
| `imageUrl` | String | `https://via.placeholder.com/400x200?text=Affiliate+Program` |
| `publishedAt` | Timestamp | **Today's date** |
| `publishedBy` | String | `admin` |
| `expiresAt` | Timestamp | **30 days from today** |
| `createdAt` | Timestamp | **Today's date** |
| `createdBy` | String | `admin` |

---

### News 3: Maintenance Notice

**Document ID:** `news_003`

| Field | Type | Value |
|-------|------|-------|
| `id` | String | `news_003` |
| `title` | String | `App Performance Improvements` |
| `content` | String | `Our engineering team has optimized the app for faster loading and smoother performance. Users will notice 40% faster shipment searches!` |
| `priority` | Number | `3` |
| `status` | String | `published` |
| `publishedAt` | Timestamp | **Today's date** |
| `publishedBy` | String | `admin` |
| `expiresAt` | Timestamp | **30 days from today** |
| `createdAt` | Timestamp | **Today's date** |
| `createdBy` | String | `admin` |

---

### News 4: Partnership

**Document ID:** `news_004`

| Field | Type | Value |
|-------|------|-------|
| `id` | String | `news_004` |
| `title` | String | `Partnering with Major Logistics Providers` |
| `content` | String | `ShopsNPorts now partners with 50+ verified shipping providers across Nigeria. More choices, better rates, guaranteed delivery!` |
| `priority` | Number | `4` |
| `status` | String | `published` |
| `publishedAt` | Timestamp | **Today's date** |
| `publishedBy` | String | `admin` |
| `expiresAt` | Timestamp | **30 days from today** |
| `createdAt` | Timestamp | **Today's date** |
| `createdBy` | String | `admin` |

---

### News 5: Security Update

**Document ID:** `news_005`

| Field | Type | Value |
|-------|------|-------|
| `id` | String | `news_005` |
| `title` | String | `Enhanced Security Features Active` |
| `content` | String | `Your data is protected by military-grade encryption. Two-factor authentication now available in account settings.` |
| `priority` | Number | `5` |
| `status` | String | `published` |
| `publishedAt` | Timestamp | **Today's date** |
| `publishedBy` | String | `admin` |
| `expiresAt` | Timestamp | **30 days from today** |
| `createdAt` | Timestamp | **Today's date** |
| `createdBy` | String | `admin` |

---

## 📄 Collection 3: `content_pages`

**Total Documents:** 3  
**Purpose:** Legal docs, FAQ, help pages  
**Status:** All `published`

### Page 1: Terms of Service

**Document ID:** `terms_of_service`

**Copy the entire Terms of Service content from below:**

```
Add this document with these fields:

Field: id | Type: String | Value: terms_of_service
Field: slug | Type: String | Value: terms-of-service
Field: title | Type: String | Value: Terms of Service
Field: description | Type: String | Value: ShopsNPorts shipping platform terms and conditions

Field: content | Type: String | Value: [[COPY FULL CONTENT BELOW]]
```

**FULL TERMS OF SERVICE CONTENT (Copy & Paste into `content` field):**

```html
<h1>Terms of Service</h1>

<h2>1. Introduction & Agreement</h2>
<p>Welcome to ShopsNSports ("we," "our," or "us"). These Terms of Service ("Terms") govern your access to and use of our mobile application, website, and related services (collectively, the "Platform"). By creating an account or using our Platform, you agree to be bound by these Terms. If you do not agree, please discontinue use immediately.</p>

<h2>2. Account Registration</h2>
<p>To access certain features, you must create an account. You agree to:
• Provide accurate, current, and complete information
• Maintain and promptly update your account information
• Maintain the security of your password and account
• Accept all responsibility for activities under your account
• Notify us immediately of any unauthorized use

We reserve the right to suspend or terminate accounts that violate these Terms or engage in fraudulent activity.</p>

<h2>3. User Roles and Responsibilities</h2>
<p>Our Platform supports multiple user types:

<strong>Customers:</strong>
• Browse and purchase products
• Track orders and shipments
• Leave reviews and ratings
• Communicate with vendors and shippers

<strong>Vendors:</strong>
• List products for sale
• Manage inventory and pricing
• Fulfill orders promptly
• Provide accurate product descriptions
• Maintain quality standards

<strong>Shippers:</strong>
• Accept and fulfill delivery requests
• Deliver items safely and on time
• Maintain verified status and documentation
• Provide tracking updates

<strong>Affiliates:</strong>
• Promote products using provided links
• Adhere to ethical marketing practices
• Disclose affiliate relationships
• Track and receive commissions</p>

<h2>4. Payment Terms</h2>
<p><strong>Payment Processing:</strong>
• We use third-party payment processors (Paystack, Flutterwave, and Stripe)
• All prices are in Nigerian Naira (NGN) unless otherwise stated
• Payment is required at checkout before order processing
• Platform commission: 10% on all transactions

<strong>Refunds:</strong>
• Refund requests must be made within 14 days of purchase
• Products must be in original condition
• Refunds are processed within 5-10 business days
• Shipping costs are non-refundable unless item is defective

<strong>Vendor Payouts:</strong>
• Vendors receive payouts bi-weekly
• Minimum payout threshold: ₦5,000
• Platform fees are deducted before payout</p>

<h2>5. Shipping and Delivery</h2>
<p><strong>Shipping:</strong>
• Delivery times are estimates, not guarantees
• Customers are responsible for providing accurate delivery addresses
• Risk of loss transfers upon delivery confirmation
• Shippers must complete deliveries within agreed timeframes

<strong>Tracking:</strong>
• Real-time tracking available for all shipments
• Status updates provided via in-app notifications
• Customers can contact shippers directly through the Platform</p>

<h2>6. Dispute Resolution</h2>
<p><strong>Informal Resolution:</strong>
• Contact us first at support@shopsnports.com to resolve disputes informally
• We will attempt to resolve within 30 days

<strong>Governing Law:</strong>
• These Terms are governed by the laws of Nigeria
• Disputes shall be resolved in Nigerian courts

<strong>Arbitration:</strong>
• If informal resolution fails, disputes may be submitted to binding arbitration
• Arbitration conducted in Lagos, Nigeria
• Each party bears own costs unless otherwise awarded</p>

<h2>7. Contact Information</h2>
<p>For questions about these Terms, contact us at:
<br/>Email: support@shopsnports.com
<br/>Website: www.shopsnports.com
<br/>Address: Lagos, Nigeria
<br/>Business Hours: Monday - Friday, 9:00 AM - 5:00 PM WAT</p>

<p><strong>© 2026 ShopsNSports. All rights reserved.</strong></p>
```

**Continue adding the remaining fields:**

| Field | Type | Value |
|-------|------|-------|
| `contentType` | String | `HTML` |
| `tags` | Array | [`legal`, `terms`] |
| `status` | String | `published` |
| `publishedAt` | Timestamp | **Today's date** |
| `publishedBy` | String | `admin` |
| `createdAt` | Timestamp | **Today's date** |
| `createdBy` | String | `admin` |
| `updatedAt` | Timestamp | **Today's date** |
| `updatedBy` | String | `admin` |
| `viewCount` | Number | `0` |
| `seoKeywords` | String | `shipping, cargo, terms, conditions` |

---

### Page 2: Privacy Policy

**Document ID:** `privacy_policy`

**FULL PRIVACY POLICY CONTENT (Copy & Paste):**

```html
<h1>Privacy Policy</h1>

<h2>1. Introduction</h2>
<p>ShopsNSports ("we," "our," or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application and website (collectively, the "Platform"). By using our Platform, you consent to the data practices described in this policy.</p>

<h2>2. Information We Collect</h2>
<p><strong>Personal Information:</strong>
• Name, email address, phone number
• Shipping and billing addresses
• Payment information (processed by third-party providers)
• Government-issued ID (for vendor/shipper verification)
• Profile photos and bio
• Account credentials (username, password)

<strong>Transaction Data:</strong>
• Purchase history and order details
• Shopping cart contents
• Product reviews and ratings
• Affiliate tracking and commission data
• Shipment tracking information

<strong>Automatically Collected Information:</strong>
• Device information (model, OS version, unique identifiers)
• IP address and location data
• Browser type and version
• Usage data (pages viewed, time spent, click paths)
• Cookies and similar tracking technologies

<strong>User-Generated Content:</strong>
• Product listings (vendors)
• Reviews and ratings
• Messages and communications
• Support tickets and feedback</p>

<h2>3. How We Use Your Information</h2>
<p><strong>Service Delivery:</strong>
• Process transactions and orders
• Facilitate communication between users
• Coordinate shipping and delivery
• Provide customer support
• Track affiliate commissions

<strong>Platform Improvement:</strong>
• Analyze usage patterns and trends
• Personalize user experience
• Develop new features
• Conduct research and analytics
• Monitor and improve performance

<strong>Security and Fraud Prevention:</strong>
• Verify user identity
• Detect and prevent fraud
• Enforce our Terms of Service
• Protect against unauthorized access

<strong>Marketing and Communications:</strong>
• Send order confirmations and updates
• Provide promotional offers (with consent)
• Send newsletters and announcements
• Notify about new features or products
• Respond to inquiries

<strong>Legal Compliance:</strong>
• Comply with legal obligations
• Respond to legal requests
• Protect our rights and property
• Resolve disputes</p>

<h2>4. Information Sharing and Disclosure</h2>
<p><strong>Other Platform Users:</strong>
• Vendors see customer shipping information for order fulfillment
• Shippers see delivery addresses and contact information
• Public profiles display username and bio
• Reviews are publicly visible

<strong>Service Providers:</strong>
• Payment processors (Paystack, Flutterwave, Stripe)
• Cloud hosting providers (Firebase, Google Cloud)
• Analytics services (Firebase Analytics, Crashlytics)
• Email and notification services
• Customer support tools

<strong>Legal Requirements:</strong>
• To comply with laws and regulations
• In response to legal process (subpoenas, court orders)
• To protect our rights and safety
• To prevent fraud or abuse</p>

<h2>5. Data Security</h2>
<p><strong>Technical Safeguards:</strong>
• Encryption in transit (TLS/SSL)
• Encryption at rest for sensitive data
• Secure authentication (Firebase Auth)
• Regular security audits
• Intrusion detection systems

<strong>Payment Security:</strong>
• PCI-DSS compliant payment processors
• We do not store credit card numbers
• Tokenization of payment information

Despite our efforts, no security measures are 100% secure. You are responsible for maintaining the security of your account credentials.</p>

<h2>6. Your Rights and Choices</h2>
<p><strong>Access and Portability:</strong>
• Request a copy of your personal data
• Export your data in machine-readable format

<strong>Correction and Update:</strong>
• Update account information through settings
• Correct inaccurate data

<strong>Deletion:</strong>
• Request account deletion
• Some data may be retained for legal compliance

<strong>Opt-Out:</strong>
• Marketing emails: Unsubscribe link in emails
• Push notifications: Disable in device settings
• Cookies: Browser settings
• Analytics: Opt-out through device settings

To exercise these rights, contact us at privacy@shopsnports.com</p>

<h2>7. GDPR Compliance (European Users)</h2>
<p><strong>Legal Basis for Processing:</strong>
• Contract performance (service delivery)
• Consent (marketing, analytics)
• Legitimate interests (fraud prevention, improvement)
• Legal obligations (tax, regulatory compliance)

<strong>Additional Rights:</strong>
• Right to object to processing
• Right to restrict processing
• Right to withdraw consent
• Right to lodge complaint with supervisory authority

Data Protection Officer: dpo@shopsnports.com</p>

<h2>8. CCPA Compliance (California Users)</h2>
<p><strong>California residents have the right to:</strong>
• Know what personal information is collected
• Delete personal information
• Opt-out of sale of personal information (we don't sell data)
• Not be discriminated against for exercising rights

Contact privacy@shopsnports.com to exercise rights.</p>

<h2>9. Contact Us</h2>
<p>For questions about this Privacy Policy, contact us at:
<br/>Email: privacy@shopsnports.com
<br/>Tech Support: tech@shopsnports.com
<br/>Address: Lagos, Nigeria
<br/>Business Hours: Monday - Friday, 9:00 AM - 5:00 PM WAT</p>

<p><strong>© 2026 ShopsNSports. All rights reserved.</strong></p>
```

**Remaining fields:**

| Field | Type | Value |
|-------|------|-------|
| `id` | String | `privacy_policy` |
| `slug` | String | `privacy-policy` |
| `title` | String | `Privacy Policy` |
| `description` | String | `How we collect, use, and protect your data` |
| `contentType` | String | `HTML` |
| `tags` | Array | [`legal`, `privacy`] |
| `status` | String | `published` |
| `publishedAt` | Timestamp | **Today's date** |
| `publishedBy` | String | `admin` |
| `createdAt` | Timestamp | **Today's date** |
| `createdBy` | String | `admin` |
| `updatedAt` | Timestamp | **Today's date** |
| `updatedBy` | String | `admin` |
| `viewCount` | Number | `0` |
| `seoKeywords` | String | `privacy, data protection, GDPR, CCPA` |

---

### Page 3: FAQ

**Document ID:** `faq_main`

| Field | Type | Value |
|-------|------|-------|
| `id` | String | `faq_main` |
| `slug` | String | `faq` |
| `title` | String | `Frequently Asked Questions` |
| `description` | String | `Common questions about ShopsNPorts services` |
| `content` | String | **[Copy below]** |
| `contentType` | String | `HTML` |
| `tags` | Array | [`help`, `faq`] |
| `status` | String | `published` |
| `publishedAt` | Timestamp | **Today's date** |
| `publishedBy` | String | `admin` |
| `createdAt` | Timestamp | **Today's date** |
| `createdBy` | String | `admin` |
| `updatedAt` | Timestamp | **Today's date** |
| `updatedBy` | String | `admin` |
| `viewCount` | Number | `0` |
| `seoKeywords` | String | `faq, help, questions, shipping` |

**FULL FAQ CONTENT (Copy & Paste):**

```html
<h1>Frequently Asked Questions</h1>

<h2>Getting Started</h2>

<h3>How do I create an account?</h3>
<p>Download the ShopsNPorts app, click "Sign Up," and follow the on-screen instructions. You'll need an email address and phone number. Verification takes about 2 minutes.</p>

<h3>What types of users can register?</h3>
<p>ShopsNPorts supports four user types: Customers (book shipments), Vendors (list products), Shippers (offer delivery services), and Affiliates (promote and earn commissions). Choose your role during registration.</p>

<h3>Is there a registration fee?</h3>
<p>No! Registration is completely free for all user types. We only take a 10% commission on completed transactions.</p>

<h2>Shipping & Delivery</h2>

<h3>How long does shipping take?</h3>
<p>Delivery times depend on your origin and destination. Most Lagos-to-Lagos shipments arrive within 24-48 hours. Long-distance shipments (5-7 days) and air cargo (rapid overnight options) are also available.</p>

<h3>How do I track my shipment?</h3>
<p>After booking, you'll receive a tracking number. Log into your account and go to "Active Shipments" to see real-time updates. You can also contact your shipper directly through the app.</p>

<h3>What if my shipment is damaged?</h3>
<p>All shipments include insurance coverage up to the declared value. Report damage within 48 hours of delivery with photos. Our support team will file a claim and process compensation within 7 business days.</p>

<h3>Can I cancel my shipment?</h3>
<p>Yes, but cancellation fees apply depending on the shipment status. If your shipper hasn't started the delivery, you can cancel for free. In-transit cancellations cost 20% of the booking fee.</p>

<h2>Payments & Refunds</h2>

<h3>What payment methods are accepted?</h3>
<p>We accept all major debit/credit cards via Paystack, Flutterwave, and Stripe. We also support bank transfers for large shipments. Payment is processed securely and instantly.</p>

<h3>How do refunds work?</h3>
<p>Refund requests are accepted within 14 days of the transaction. Most refunds process within 5-10 business days. Shipping costs are non-refundable unless the item was lost, damaged, or incorrectly delivered by our shipper.</p>

<h3>Is my payment information secure?</h3>
<p>Yes. We use PCI-DSS compliant payment processors and never store credit card numbers directly. All transactions are encrypted with military-grade security.</p>

<h2>Account & Security</h2>

<h3>How do I reset my password?</h3>
<p>Click "Forgot Password" on the login screen, enter your email, and follow the reset link sent to your inbox. You'll have 1 hour to create a new password.</p>

<h3>Is two-factor authentication available?</h3>
<p>Yes! Enable 2FA in Settings → Security. You'll need to verify a code from an authenticator app in addition to your password when logging in from new devices.</p>

<h3>What if I think my account was hacked?</h3>
<p>Contact support@shopsnports.com immediately. Our security team will lock your account, review recent activity, and help you restore access. Change your password as soon as possible.</p>

<h3>Why was my account suspended?</h3>
<p>Accounts may be suspended for Terms of Service violations, fraudulent activity, or suspicious behavior. Contact support@shopsnports.com to appeal or get more information.</p>

<h2>Affiliate Program</h2>

<h3>How does the affiliate program work?</h3>
<p>Join the affiliate program, receive a unique referral link, and share it. You earn 5-10% commission on every shipment booked through your link. Earnings are paid bi-weekly.</p>

<h3>When do I get paid?</h3>
<p>Affiliate payments are processed every two weeks. Minimum payout threshold is ₦5,000. You'll receive payment via bank transfer within 3 business days of payout processing.</p>

<h3>Can I track my affiliate earnings?</h3>
<p>Yes. Log into your Affiliate Dashboard in the app to see real-time earnings, clicks, conversions, and pending payouts.</p>

<h2>Vendor & Shipper Questions</h2>

<h3>How do I become a verified shipper?</h3>
<p>Complete your shipper profile, submit required documentation (ID, vehicle registration), and pass our verification process. Verification typically takes 2-3 business days.</p>

<h3>What fees do shippers pay?</h3>
<p>ShopsNPorts takes a 10% commission on delivery earnings. There are no monthly fees or subscription costs. You only pay when you complete a delivery.</p>

<h3>How do I contact customers?</h3>
<p>After accepting a delivery, you can message the customer through the app. In-app messaging keeps both parties safe and provides proof of communication.</p>

<h2>Technical Issues</h2>

<h3>The app is crashing. What should I do?</h3>
<p>Try these steps: 1) Restart your phone, 2) Update the app to the latest version, 3) Clear the app cache (Settings → Apps → ShopsNPorts → Storage → Clear Cache), 4) Contact tech@shopsnports.com if the issue persists.</p>

<h3>Why is the app running slowly?</h3>
<p>Check your phone's available storage and RAM. Disable background apps, clear cache regularly, and ensure you have a stable internet connection. Contact tech support if problems continue.</p>

<h3>Where can I get technical support?</h3>
<p>Email tech@shopsnports.com or call +234 (0) 123 456 7890. Our technical team typically responds within 2 hours during business hours (Monday-Friday, 9 AM-5 PM WAT).</p>

<h2>General</h2>

<h3>What documents do I need for shipper verification?</h3>
<p>You'll need: Valid government ID (National ID, Passport, Driver's License), phone number, email address, and proof of address. For vehicle-based shipping, you'll also need vehicle registration and insurance documents.</p>

<h3>How do I report a problem or file a complaint?</h3>
<p>Use the in-app Support section to file a complaint. Describe your issue, attach photos if applicable, and our support team will investigate within 24 hours.</p>

<h3>When was ShopsNPorts founded?</h3>
<p>ShopsNPorts is an emerging logistics platform launched in 2025, bringing modern, technology-driven shipping solutions to Nigeria.</p>

<h3>Does ShopsNPorts operate everywhere in Nigeria?</h3>
<p>We currently operate in major Nigerian cities (Lagos, Abuja, Ibadan, Kano, Enugu, Rivers, Oyo). We're expanding to secondary cities quarterly.</p>

<p><strong>Didn't find your answer? Contact support@shopsnports.com</strong></p>
```

---

## ⚙️ Collection 4: `config` (Singleton)

**Total Documents:** 1  
**Purpose:** Global app configuration  
**Note:** This is a singleton collection, not a collection of documents

### Config Document: `contacts`

**Document ID:** `contacts`

| Field | Type | Value |
|-------|------|-------|
| `supportPhone` | String | `+234 (0) 123 456 7890` |
| `supportWhatsapp` | String | `+234 (0) 123 456 7890` |
| `supportEmail` | String | `support@shopsnports.com` |
| `techSupportEmail` | String | `tech@shopsnports.com` |
| `dpoEmail` | String | `dpo@shopsnports.com` |
| `privacyEmail` | String | `privacy@shopsnports.com` |
| `faqUrl` | String | `https://shopsnports.com/faq` |
| `appVersion` | String | `1.0.0` |
| `minRequiredVersion` | String | `1.0.0` |
| `maintenanceMode` | Boolean | `false` |
| `theme.primaryColor` | String | `#003366` |
| `theme.accentColor` | String | `#FFB81C` |
| `theme.successColor` | String | `#27AE60` |
| `theme.warningColor` | String | `#E67E22` |
| `theme.errorColor` | String | `#E74C3C` |
| `features.analyticsEnabled` | Boolean | `true` |
| `features.affiliateProgramActive` | Boolean | `true` |
| `features.maintenanceMode` | Boolean | `false` |
| `updatedAt` | Timestamp | **Today's date** |
| `updatedBy` | String | `system` |

**Steps for Firebase Console:**

1. Go to **Firestore Database** → **Data** tab
2. **Create collection** (if it doesn't exist): `config`
3. **Add document** with ID: `contacts`
4. **Add fields** from table above
5. For nested fields like `theme.primaryColor`, use the **Map** type:
   - Create a Map field called `theme`
   - Inside it, add: `primaryColor`, `accentColor`, `successColor`, `warningColor`, `errorColor`
6. Similarly for `features` (create Map, add `analyticsEnabled`, `affiliateProgramActive`, `maintenanceMode`)
7. Click **Save**

---

## ✅ Seeding Checklist

After adding all documents, verify:

- [ ] **Banners Collection** - 4 documents added
  - [ ] banner_001 (Fast & Reliable Shipping)
  - [ ] banner_002 (Affordable Rates)
  - [ ] banner_003 (Real-Time Tracking)
  - [ ] banner_004 (New Year Special)

- [ ] **News Ticker Collection** - 5 documents added
  - [ ] news_001 (Welcome)
  - [ ] news_002 (Affiliate Program)
  - [ ] news_003 (Performance Improvements)
  - [ ] news_004 (Partnership)
  - [ ] news_005 (Security Update)

- [ ] **Content Pages Collection** - 3 documents added
  - [ ] terms_of_service
  - [ ] privacy_policy
  - [ ] faq_main

- [ ] **Config Collection** - 1 document added
  - [ ] contacts (with all theme fields)

---

## 🎯 Next Steps After Seeding

1. **Verify in Firebase Console:**
   - Navigate to each collection and confirm documents are visible
   - Check that timestamps are correct
   - Verify all arrays (tags, theme colors) are properly set

2. **Restart Flutter App:**
   ```bash
   flutter run
   ```

3. **Home Screen Should Show:**
   - ✅ Real banners from Firebase (4 items in carousel)
   - ✅ Real news items (ticker showing announcements)
   - ✅ Loading spinners → actual data (no more mock data)

4. **Test Navigation:**
   - Settings → Privacy Policy (should display real content from Firestore)
   - Settings → Terms of Service (should display real content from Firestore)

---

## 💡 Pro Tips

- **Add documents one by one** - This helps identify any field type errors
- **Timestamps:** Use Firebase Console's "Timestamp" field type (don't type dates as strings)
- **Arrays:** For `tags` array, click "+" to add each item: `legal`, `terms`, etc.
- **Maps:** For `theme` and `features`, right-click and select "Add field" from the dropdown menu
- **Images:** Using placeholder images for now is fine. Later, upload real images to Firebase Storage and use those URLs

---

## 🚀 Once Complete

Fire up the flutter app with `flutter run` and send me a message:
```
✅ Seeding complete! The home screen should now display real Firestore data.
```

You'll see the banners update live in your app within seconds of adding them to Firestore!

---

**Need Help?** File any issues in the Firebase console directly, or I can provide additional guidance once you complete seeding.

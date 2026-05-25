# Production Architecture Recommendation
## ShopsNSports - Full System Integration Plan

**Generated:** January 13, 2026  
**Status:** Production-Ready Architecture Design

---

## 🏗️ Recommended Architecture: **Hybrid Stack**

### Overview
Keep your current hybrid approach - it's the best architecture for your use case and costs.

```
┌─────────────────────────────────────────────────────────────────┐
│                        CLIENT LAYER                              │
├─────────────────────────────────────────────────────────────────┤
│  Mobile App (Flutter)          Admin Dashboard (Flutter Web)    │
│  - iOS/Android                 - Web Browser                     │
│  - Customer/Vendor/Shipper     - Admin Management                │
└─────────────────────────────────────────────────────────────────┘
                              ↓ ↓ ↓
┌─────────────────────────────────────────────────────────────────┐
│                    AUTHENTICATION LAYER                          │
├─────────────────────────────────────────────────────────────────┤
│                     Firebase Authentication                      │
│  - Google Sign-In  - Phone Auth  - Email/Password               │
│  - Custom Claims for Roles (admin, vendor, shipper, customer)   │
└─────────────────────────────────────────────────────────────────┘
                              ↓ ↓ ↓
┌─────────────────────────────────────────────────────────────────┐
│                      BACKEND LAYER                               │
├─────────────────────────────────────────────────────────────────┤
│                    Node.js/Express API Server                    │
│  - REST API endpoints (19 route modules)                         │
│  - Firebase Admin SDK (token verification)                       │
│  - Session management (Redis/Memory)                             │
│  - Business logic & validation                                   │
│  - Payment webhooks (Stripe, Paystack, Flutterwave)             │
└─────────────────────────────────────────────────────────────────┘
                              ↓ ↓ ↓
┌──────────────────────────┬──────────────────────────────────────┐
│    DATABASE LAYER        │                                      │
├──────────────────────────┴──────────────────────────────────────┤
│                                                                  │
│  Firebase Firestore              PostgreSQL Database            │
│  ==================              ====================            │
│  REAL-TIME DATA:                 TRANSACTIONAL DATA:            │
│  ✓ User profiles                 ✓ Products & categories        │
│  ✓ Notifications                 ✓ Orders & order items         │
│  ✓ Messages/Chat                 ✓ Payouts & commissions        │
│  ✓ News ticker                   ✓ Shipping profiles            │
│  ✓ Affiliate records             ✓ Analytics & reports          │
│  ✓ Cart (logged-in users)        ✓ Inventory tracking           │
│  ✓ Live updates/streams          ✓ Financial records            │
│                                                                  │
│  WHY: Real-time updates,         WHY: Complex queries,          │
│       mobile-first,                    ACID transactions,       │
│       Firebase Auth sync               lower cost for bulk data │
└──────────────────────────────────────────────────────────────────┘
```

---

## 📋 Platform Responsibilities Breakdown

### 1️⃣ **FRONTEND** (Client Applications)

#### Platform: **Flutter**

**Mobile App:**
- **Location:** `c:\projects\shopsnports\lib\`
- **Target Platforms:** iOS, Android
- **Users:** Customers, Vendors, Shippers, Affiliates
- **Key Features:**
  - Product browsing & purchase
  - Vendor dashboard (sales, inventory)
  - Shipper management (deliveries, earnings)
  - Affiliate tracking (referrals, commissions)
  - Real-time notifications
  - In-app messaging

**Admin Dashboard:**
- **Location:** `c:\projects\shopsnports\admin_dashboard\`
- **Target Platform:** Web (Chrome, Edge, Safari)
- **Users:** System Administrators
- **Key Features:**
  - User management (approve vendors/shippers)
  - Content management (news ticker)
  - Order oversight
  - System configuration
  - Analytics & reporting
  - Review moderation

**State Management:** Riverpod  
**HTTP Client:** http package + dio (for complex requests)

---

### 2️⃣ **BACKEND** (API Server)

#### Platform: **Node.js v18+ with Express.js**

- **Location:** `c:\projects\shopsnports\server\`
- **Port:** 3000 (configurable via PORT env var)
- **Deployment:** Can run anywhere (Heroku, Railway, DigitalOcean, AWS EC2, Azure App Service)

**Responsibilities:**
1. **API Endpoints** (19 route modules):
   - `/api/auth` - Authentication & token management
   - `/api/users` - User CRUD operations
   - `/api/vendors` - Vendor management
   - `/api/products` - Product management
   - `/api/orders` - Order processing
   - `/api/shipping` - Shipper profiles & management
   - `/api/shipping-tokens` - Token generation/validation
   - `/api/affiliates` - Affiliate program management
   - `/api/payouts` - Commission & payment processing
   - `/api/admin` - Administrative operations
   - `/webhooks/*` - Payment provider webhooks

2. **Security:**
   - Firebase token verification (verifyFirebaseIdToken middleware)
   - Role-based access control (requireAdmin, requireVendor, etc.)
   - CSRF protection
   - Rate limiting
   - Session management (Redis in production)

3. **Business Logic:**
   - Order fulfillment workflows
   - Commission calculations
   - Payout automation
   - Email notifications (via Resend)
   - Payment processing (Stripe, Paystack, Flutterwave)

4. **Integrations:**
   - Firebase Admin SDK (Firestore writes, custom claims)
   - PostgreSQL connection (via node-pg)
   - Email service (Resend)
   - Payment gateways

**Dependencies:**
```json
{
  "express": "^4.18.2",
  "firebase-admin": "^13.5.0",
  "pg": "^8.11.0",
  "resend": "^6.6.0",
  "stripe": "^12.0.0",
  "express-session": "^1.17.3",
  "connect-redis": "^7.1.0"
}
```

---

### 3️⃣ **AUTHENTICATION** (Identity Management)

#### Platform: **Firebase Authentication**

- **Provider:** Google Cloud Platform (Firebase)
- **Integration:** firebase-admin SDK (backend) + firebase_auth (Flutter)

**Supported Methods:**
- ✅ Email/Password
- ✅ Google Sign-In
- ✅ Phone Authentication (SMS OTP)
- 🔄 Apple Sign-In (optional, for iOS)

**User Roles** (via Custom Claims):
```javascript
// Set in backend via Firebase Admin SDK
await admin.auth().setCustomUserClaims(uid, {
  role: 'admin' | 'vendor' | 'shipper' | 'customer' | 'affiliate'
});
```

**Token Flow:**
```
1. User signs in via Flutter app
2. Firebase Auth returns ID token
3. App sends token with every API request (Authorization: Bearer <token>)
4. Backend verifies token with Firebase Admin SDK
5. Backend checks custom claims for authorization
6. Backend proceeds with request
```

**Security:**
- Tokens expire after 1 hour (auto-refresh in Flutter)
- Custom claims cached by Firebase
- Firestore security rules enforce read/write permissions
- Backend middleware double-checks authorization

---

### 4️⃣ **DATABASE** (Data Storage)

#### Two-Database Hybrid Approach

---

#### **Database A: Firebase Firestore** (NoSQL Cloud Database)

**Platform:** Google Cloud Platform  
**Type:** Document-based NoSQL  
**Access:** Direct from Flutter + Backend writes

**Data Stored:**
| Collection | Purpose | Accessed By |
|------------|---------|-------------|
| `users` | User profiles, preferences | Mobile + Backend |
| `notifications` | Real-time in-app notifications | Mobile (live streams) |
| `conversations` | Chat/messaging threads | Mobile + Admin |
| `messages` | Individual chat messages | Mobile + Admin |
| `news_ticker` | Homepage news items | Mobile + Admin |
| `affiliates` | Affiliate requests & profiles | Mobile + Backend |
| `carts` | User shopping carts (logged-in) | Mobile only |
| `reviews` | Product reviews (optional) | Mobile + Admin |

**Why Firestore for This Data:**
1. **Real-time updates** - Firestore streams push changes instantly to Flutter
2. **Offline support** - Mobile app caches data automatically
3. **Firebase Auth integration** - Security rules use Auth UID directly
4. **Scalability** - Auto-scales with no server management
5. **Mobile-first** - Optimized for mobile SDKs

**Firestore Security Rules:**
```javascript
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own profile
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    
    // Notifications readable by recipient
    match /notifications/{notifId} {
      allow read: if request.auth.uid == resource.data.userId;
    }
    
    // News ticker readable by all
    match /news_ticker/{itemId} {
      allow read: if true;
      allow write: if request.auth.token.role == 'admin';
    }
    
    // Admin-only collections
    match /affiliates/{docId} {
      allow read: if request.auth.token.role in ['admin', 'affiliate'];
      allow write: if request.auth.token.role == 'admin';
    }
  }
}
```

**Cost Optimization:**
- Read/write operations charged per document
- Use `.limit()` to reduce reads
- Cache aggressively in Flutter
- Use Firestore only for small, frequently-accessed data

---

#### **Database B: PostgreSQL** (Relational Database)

**Platform:** Self-hosted (AWS RDS, DigitalOcean, Railway, Heroku Postgres)  
**Type:** SQL relational database  
**Access:** Backend only (never direct from mobile)

**Data Stored:**
| Table | Purpose | Why PostgreSQL |
|-------|---------|----------------|
| `products` | Product catalog | Complex joins, inventory tracking |
| `categories` | Product categories | Hierarchical queries |
| `orders` | Customer orders | ACID transactions, financial accuracy |
| `order_items` | Order line items | Relational integrity |
| `shipping_profiles` | Shipper details | Complex filtering, status updates |
| `payouts` | Commission payments | Financial records, auditing |
| `payout_items` | Itemized commissions | Multi-table joins |
| `admins` | Admin users | Secure user management |

**Why PostgreSQL for This Data:**
1. **ACID transactions** - Orders must be atomic (all-or-nothing)
2. **Complex queries** - Joins, aggregations, reporting
3. **Cost-effective** - Bulk data cheaper than Firestore
4. **Data integrity** - Foreign keys, constraints
5. **Financial compliance** - Audit trails, immutable records
6. **Analytics** - SQL aggregations for dashboards

**Current Migration Files:**
- ✅ `1670000000000-create-admins.js` - Admin users table
- ✅ `20251010000001-create-core-tables.js` - Core schema
- ✅ `20251010000002-expand-users-table.js` - Extended user fields
- ✅ `20260106000001-create-production-schema.js` - Products, orders, payouts

**Connection Setup:**
- Location: `server/db-pg.js`
- Features: Vault secrets, SSL/TLS, connection pooling, dynamic credentials
- Status: ✅ Production-ready (just needs migrations run)

**Sample Query Pattern:**
```javascript
// Backend API endpoint
router.get('/api/orders/:id', async (req, res) => {
  const result = await db.query(`
    SELECT o.*, oi.product_id, oi.quantity, oi.price
    FROM orders o
    LEFT JOIN order_items oi ON o.id = oi.order_id
    WHERE o.id = $1
  `, [req.params.id]);
  
  res.json(result.rows);
});
```

---

## 🎯 Integration Points & Data Flow

### Example: User Places Order

```
1. MOBILE APP (Flutter)
   ↓ User taps "Place Order"
   ↓ Calls POST /api/orders with cart items
   ↓ Includes Firebase Auth token in header

2. BACKEND (Node.js)
   ↓ Verifies Firebase token
   ↓ Starts PostgreSQL transaction
   ↓   - INSERT into orders table
   ↓   - INSERT into order_items table
   ↓   - UPDATE products (reduce stock)
   ↓ Commits transaction
   ↓ Writes notification to Firestore
   ↓ Sends email via Resend
   ↓ Returns order ID to app

3. FIRESTORE (Real-time)
   ↓ Notification appears instantly in app
   ↓ Stream updates notification badge

4. POSTGRESQL (Persistent)
   ✓ Order stored permanently
   ✓ Financial record created
   ✓ Inventory updated atomically
```

---

## ✅ Production-Ready Checklist

### Firebase Setup
- [x] Firebase project created
- [x] Firebase Auth enabled (Email, Google, Phone)
- [x] Firestore database created
- [ ] **Deploy Firestore security rules** (`firebase deploy --only firestore:rules`)
- [ ] **Deploy Firestore indexes** (`firebase deploy --only firestore:indexes`)
- [ ] Set up Firebase Admin SDK credentials in backend
- [x] Custom claims system implemented

### PostgreSQL Setup
- [x] Migration tool installed (node-pg-migrate)
- [x] Migration files created (4 files)
- [x] Database connection code ready (db-pg.js)
- [ ] **RUN MIGRATIONS** ⚠️ CRITICAL - `npm run migrate`
- [ ] Set environment variables:
  - `DATABASE_URL` or individual `DB_*` vars
  - `DB_SSL=true` (for production)
  - Vault credentials (if using Vault)
- [ ] Set up database backups
- [ ] Configure connection pooling (already in code)

### Backend Server Setup
- [x] Express server configured
- [x] 19 API route modules mounted
- [x] Firebase Admin SDK integrated
- [x] PostgreSQL connection ready
- [ ] **Set RESEND_API_KEY** ⚠️ CRITICAL - Email won't work without this
- [ ] Set SESSION_SECRET (for production)
- [ ] Configure Redis for sessions (production)
- [ ] Set up payment gateway webhooks
- [ ] Deploy to hosting (Heroku/Railway/DigitalOcean)
- [ ] Set up SSL/TLS certificate
- [ ] Configure CORS for mobile app

### Mobile App Setup
- [x] Flutter app structure complete
- [x] Firebase integration (auth, Firestore)
- [x] API service layer implemented
- [ ] **Disable mock data** ⚠️ CRITICAL - Set `_useMockData = false`
- [ ] Test on real devices (iOS, Android)
- [ ] Build release APK/IPA
- [ ] Submit to app stores

### Admin Dashboard Setup
- [x] Flutter web app structure
- [x] Admin routes implemented
- [ ] Build for production (`flutter build web`)
- [ ] Deploy to hosting (Firebase Hosting, Netlify, Vercel)
- [ ] Add admin users to Firebase Auth
- [ ] Set custom claims for admin users

---

## 💰 Cost Estimation (Monthly)

### Firebase (Spark Plan - FREE tier available)
- **Firestore:**
  - 50K reads/day FREE
  - 20K writes/day FREE
  - 1GB storage FREE
  - **Estimated:** $0-25/month for small-medium traffic

- **Firebase Auth:**
  - SMS auth: $0.06/verification (after free tier)
  - Email/Google: FREE
  - **Estimated:** $0-50/month (depends on SMS usage)

### PostgreSQL Database
- **DigitalOcean Managed PostgreSQL:** $15/month (1GB RAM)
- **Railway:** $5/month (500MB RAM)
- **Heroku Postgres:** $9/month (Basic tier)
- **Self-hosted:** $5-10/month (VPS)
- **Recommended:** Railway or DigitalOcean

### Backend Hosting
- **Railway:** $5/month (starter)
- **Heroku:** $7/month (Eco Dyno)
- **DigitalOcean App Platform:** $5/month
- **Render:** FREE tier available
- **Recommended:** Railway ($5/month)

### Email (Resend)
- **Free tier:** 100 emails/day
- **Paid:** $20/month for 50K emails
- **Estimated:** $0-20/month

### **Total Monthly Cost: $25-110/month**
- Minimal: $25 (Railway backend + DB, Firebase free tier)
- Comfortable: $60 (DigitalOcean DB + Railway + Resend)
- Heavy traffic: $110 (all paid tiers)

---

## 🚀 Immediate Action Plan (Next 24 Hours)

### Step 1: Run PostgreSQL Migrations (5 minutes)
```bash
cd c:\projects\shopsnports\server

# Set database connection (choose one):
# Option A: Full connection string
$env:DATABASE_URL="postgresql://user:password@localhost:5432/shopsnports"

# Option B: Individual vars
$env:DB_HOST="localhost"
$env:DB_PORT="5432"
$env:DB_NAME="shopsnports"
$env:DB_USER="your_user"
$env:DB_PASSWORD="your_password"

# Run migrations
npm run migrate
```

**Verify tables created:**
```bash
psql -d shopsnports -c "\dt"
```

Expected output:
```
 Schema |       Name       | Type  |  Owner
--------+------------------+-------+---------
 public | admins           | table | postgres
 public | categories       | table | postgres
 public | orders           | table | postgres
 public | order_items      | table | postgres
 public | payouts          | table | postgres
 public | products         | table | postgres
 public | shipping_profiles| table | postgres
```

---

### Step 2: Get Resend API Key (10 minutes)
```bash
# 1. Sign up at https://resend.com
# 2. Create API key
# 3. Add to .env file

echo "RESEND_API_KEY=re_your_key_here" >> .env
```

---

### Step 3: Disable Mock Data (2 minutes)
Edit `lib/services/affiliate_api_service.dart`:
```dart
// Line 21: Change from true to false
static const bool _useMockData = false;
```

---

### Step 4: Test Backend API (5 minutes)
```bash
# Start server
cd c:\projects\shopsnports\server
npm start

# Test endpoint (in another terminal)
curl http://localhost:3000/api/health
```

Expected response:
```json
{
  "status": "ok",
  "database": "connected",
  "firebase": "connected"
}
```

---

### Step 5: Deploy Firestore Rules (2 minutes)
```bash
cd c:\projects\shopsnports
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
```

---

## 🔐 Environment Variables Checklist

### Backend (.env file)
```bash
# Required
PORT=3000
NODE_ENV=production

# Firebase Admin
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxx@your-project.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"

# PostgreSQL
DATABASE_URL=postgresql://user:pass@host:5432/shopsnports
# OR
DB_HOST=localhost
DB_PORT=5432
DB_NAME=shopsnports
DB_USER=postgres
DB_PASSWORD=your_password
DB_SSL=false  # true in production

# Email
RESEND_API_KEY=re_your_key_here

# Sessions
SESSION_SECRET=your-long-random-secret-here
REDIS_URL=redis://localhost:6379  # Production only

# Payments
STRIPE_SECRET_KEY=sk_test_...
PAYSTACK_SECRET_KEY=sk_test_...
FLUTTERWAVE_SECRET_KEY=FLWSECK_TEST-...
```

### Mobile App (No .env needed)
All config in `lib/config/app_config.dart` and Firebase console.

---

## 📊 System Health Monitoring

### Key Metrics to Track

**Backend:**
- API response times (should be < 200ms)
- Error rates (should be < 1%)
- Database connection pool usage
- Active sessions

**Firebase:**
- Firestore read/write counts
- Auth success/failure rates
- Storage usage
- Function execution times

**PostgreSQL:**
- Query performance (slow query log)
- Connection count
- Database size
- Backup completion

---

## 🎓 Why This Architecture Works

### ✅ Advantages of Hybrid Approach

1. **Best of Both Worlds**
   - Firestore: Real-time, offline-first, mobile-optimized
   - PostgreSQL: Transactional, relational, cost-effective

2. **Cost-Effective**
   - Firestore only for small, frequently-accessed data
   - PostgreSQL for bulk historical data (cheaper)

3. **Scalability**
   - Firestore auto-scales without server management
   - PostgreSQL scales vertically (upgrade RAM/CPU as needed)

4. **Developer Experience**
   - Firebase: Quick prototyping, real-time features
   - PostgreSQL: Familiar SQL, powerful queries

5. **Reliability**
   - If one database is down, core features still work
   - Firestore has 99.999% uptime SLA
   - PostgreSQL with managed hosting is highly reliable

### ⚠️ Considerations

1. **Data Sync Complexity**
   - Some data lives in both (e.g., user profiles)
   - Backend is source of truth for writes
   - Use backend to ensure consistency

2. **Learning Curve**
   - Team needs to know both NoSQL and SQL
   - Clear documentation on where data lives

3. **Deployment Complexity**
   - Two databases to manage
   - Separate backup strategies
   - More environment variables

**Verdict:** Complexity is worth it for the cost savings and performance benefits.

---

## 🔄 Alternative: Full Firebase Stack

If you absolutely want to avoid PostgreSQL:

### Pros:
- Single ecosystem (simpler mental model)
- No server management for database
- Real-time by default
- Automatic backups

### Cons:
- **Much more expensive** at scale (pay per read/write)
- Complex queries require Cloud Functions
- No SQL for reporting (need BigQuery export)
- **2-3 weeks of rewrite work** (67+ db.query() calls to replace)

**Cost Comparison:**
- Hybrid: $25-60/month
- Full Firebase: $100-500+/month (same traffic)

**Recommendation:** Stick with hybrid unless you have unlimited budget.

---

## 📝 Final Recommendation

### ✅ **Keep the Hybrid Architecture**

**Why:**
1. ✅ Already 95% implemented
2. ✅ Just need to run migrations (5 minutes)
3. ✅ Cost-effective ($25-60/month vs $100-500+)
4. ✅ Best performance for transactional data
5. ✅ Production-ready database connection code exists

**Immediate Actions:**
1. Run `npm run migrate` ⚠️ CRITICAL
2. Get Resend API key
3. Disable mock data
4. Test full flow (order placement)
5. Deploy Firestore rules
6. Build APK for team testing

**Timeline to Production:**
- Day 1: Database setup (migrations + testing)
- Day 2: Email configuration + mock data removal
- Day 3: Admin endpoint security fixes
- Day 4: End-to-end testing
- Day 5: APK build + team testing
- Day 6-7: Bug fixes + refinements
- **Day 8: Production deployment** 🚀

---

## 📞 Support & Resources

**PostgreSQL Migrations:**
- [node-pg-migrate docs](https://salsita.github.io/node-pg-migrate/)

**Firebase:**
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)
- [Firebase Admin SDK](https://firebase.google.com/docs/admin/setup)

**Express.js:**
- [Express Best Practices](https://expressjs.com/en/advanced/best-practice-security.html)

**Flutter:**
- [Riverpod Documentation](https://riverpod.dev/)
- [Firebase Flutter Setup](https://firebase.flutter.dev/)

---

**Status:** Ready to proceed with PostgreSQL setup ✅

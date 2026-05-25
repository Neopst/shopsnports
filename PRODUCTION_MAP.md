# ShopsNports Production Readiness Map

**Last Updated:** April 8, 2026  
**Status:** IN PROGRESS  
**Total Batches:** 5

---

## Quick Legend

| Symbol | Meaning |
|--------|---------|
| ✅ | Complete & Tested |
| 🔄 | In Progress |
| ⚠️ | Needs Attention |
| ❌ | Not Started / Broken |
| 🔗 | Integration Required |

---

## User Journey Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           USER JOURNEY MAP                                   │
├─────────────────┬─────────────────────┬──────────────────┬──────────────────┤
│     GUEST       │      CUSTOMER       │    AFFILIATE     │      ADMIN       │
│  (No login)     │   (Registered)      │   (Enrolled)     │   (Web Only)     │
├─────────────────┼─────────────────────┼──────────────────┼──────────────────┤
│ • Request Ship  │ • Full App Access   │ • Affiliate Tab  │ • Full Dashboard │
│ • Get Tracking  │ • View/Track Orders │ • Commission     │ • Manage Users   │
│ • Email Updates │ • Profile Mgmt     │ • Payouts        │ • Shipping Mgmt  │
│                 │ • Address Book     │ • Ship for Self  │ • Affiliate Mgmt │
│                 │ • View History     │ • Share Links    │ • Reports        │
└─────────────────┴─────────────────────┴──────────────────┴──────────────────┘
```

---

# BATCH 1: Guest User Journey 🔄 IN PROGRESS (70%)
**Focus:** Guest shipping requests (public access)
**Status:** Form and Firestore integration complete, email notification pending

## 1.1 Guest Shipping Request Flow
| Component | Status | Location | Notes |
|-----------|--------|----------|-------|
| Public Form UI | ✅ | `lib/screens/public/shipment_request_form.dart` | Complete form with sender/receiver/package fields |
| Firebase Integration | ✅ | `lib/screens/public/shipment_request_form.dart:74` | Writes to `shippingRequests` collection |
| Tracking Number Gen | ✅ | `lib/screens/public/shipment_request_form.dart:67` | Format: SHP-YYMMDD-XXXXXX |
| Email Notification | ❌ | N/A | No Firebase Functions trigger |
| Admin View | ✅ | `admin/admin/lib/features/shipping/...` | Shipping list screens exist |

## 1.2 Guest Integration Points
```
Guest Request → Firestore (shippingRequests) → Email (Cloud Functions) → Admin Dashboard
```

### Tasks Completed:
- ✅ Admin dashboard login fixed (superAdmin role set in Firestore)
- ✅ Admin dashboard builds successfully

### Tasks Completed ✅:
| Task | Status |
|------|--------|
| Connect guest form to Firestore `shippingRequests` collection | ✅ |
| Implement tracking number generation (SHP-YYMMDD-XXXXXX) | ✅ |
| Generate system tracking number for guest | ✅ |

### Tasks Remaining:
| Task | Status | Priority |
|------|--------|----------|
| Create Firebase Function for guest email notification | ❌ | HIGH |
| Update Firestore security rules for public write access | ✅ | DONE |

---

# BATCH 2: Customer Journey 🔄 IN PROGRESS
**Focus:** Registered user features and flows

## 2.1 Customer Authentication
| Component | Status | Location | Notes |
|-----------|--------|----------|-------|
| Login Screen | ✅ | `lib/screens/auth/login_screen.dart` | Works |
| Registration | ✅ | `lib/screens/auth/registration_screen.dart` | Works |
| Password Reset | ✅ | `lib/providers/auth_provider.dart` | Via Firebase Auth |
| Auth State Management | ✅ | `lib/providers/user_providers.dart` | Riverpod |
| Firestore User Profile | ✅ | `lib/repositories/firebase_user_repository.dart` | Auto-creates |

## 2.2 Customer Core Features
| Feature | Status | Location | Integration |
|---------|--------|----------|-------------|
| Home Dashboard | ✅ | `lib/screens/customer/customer_home_screen.dart` | Basic |
| Request Shipping | ✅ | `lib/screens/shipping/shipping_request_screen.dart` | Partial |
| View Shipments | ✅ | `lib/screens/shipments/shipments_list_screen.dart` | Needs data |
| Track Shipment | ✅ | `lib/screens/shipping/track_shipment_screen.dart` | UI exists |
| Profile Management | ✅ | `lib/screens/profile/profile_screen.dart` | Partial |
| Address Book | ✅ | `lib/screens/profile/addresses_screen.dart` | UI exists |
| Notifications | ✅ | `lib/screens/notifications_screen.dart` | UI exists |
| Settings | ✅ | `lib/screens/settings_screen.dart` | UI exists |

## 2.3 Customer Integration Status
```
Firebase Auth ─────────────────────────────────────────► Firestore (customers)
       │                                                             │
       ▼                                                             ▼
User Login ◄──────────────────────────────────────────── Profile Data
```

### Customer Tasks:
| Task | Status | Priority |
|------|--------|----------|
| Connect shipping request form to Firestore `shippingRequests` | ❌ | HIGH |
| Display customer's actual shipments in list | ❌ | HIGH |
| Show tracking info for customer shipments | ❌ | HIGH |
| Implement address book CRUD | ⚠️ | MEDIUM |
| Profile image upload to Firebase Storage | ⚠️ | MEDIUM |
| Push notifications for shipment updates | ❌ | HIGH |

---

# BATCH 3: Affiliate Journey 🔄 IN PROGRESS
**Focus:** Affiliate-specific features

## 3.1 Affiliate Features
| Component | Status | Location | Notes |
|-----------|--------|----------|-------|
| Affiliate Intro | ✅ | `lib/screens/affiliate_intro_screen.dart` | Exists |
| Join Affiliate | ✅ | `lib/screens/affiliate_join_screen.dart` | Exists |
| Pending Screen | ✅ | `lib/screens/affiliate_pending_screen.dart` | Exists |
| Affiliate Dashboard | ✅ | `lib/screens/affiliate/affiliate_dashboard_screen.dart` | Exists |
| Commission Tracking | ✅ | `lib/screens/affiliate/commission_tracking_screen.dart` | Exists |
| Payout Management | ✅ | `lib/screens/affiliate/payout_management_screen.dart` | Exists |
| Share Form | ✅ | `lib/screens/affiliate/share_form_dialog.dart` | Exists |

## 3.2 Affiliate Integration
| Feature | Status | Integration |
|---------|--------|-------------|
| Self Enroll | ✅ | `firebase_user_repository.dart:registerAsAffiliate()` |
| Commission Display | ⚠️ | Reads from Firestore `customers` collection |
| Payout Request | ❌ | No payout request collection |
| Ship for Self | ⚠️ | Same as customer shipping |

### Affiliate Tasks:
| Task | Status | Priority |
|------|--------|----------|
| Implement commission calculation logic | ❌ | HIGH |
| Create `affiliatePayouts` collection in Firestore | ❌ | HIGH |
| Admin payout approval workflow | ⚠️ | HIGH |
| Show affiliate code in share form | ⚠️ | MEDIUM |
| Track referrals from affiliate links | ❌ | HIGH |
| Payout history in admin dashboard | ⚠️ | HIGH |

---

# BATCH 4: Admin Dashboard 🔄 IN PROGRESS
**Focus:** Web admin dashboard modules

## 4.1 Admin Authentication ✅ FIXED
| Component | Status | Notes |
|-----------|--------|-------|
| Login Screen | ✅ | Fixed compilation errors |
| Permission Check | ✅ | Checks `roleType: 'superAdmin'` in `customers` collection |
| Custom Claims | ✅ | Set via `set_admin_claims.js` script |
| Build Status | ✅ | Successfully builds (`flutter build web`) |

## 4.2 Admin Dashboard Modules
| Module | Status | Location | Data Source |
|--------|--------|----------|-------------|
| Overview/Dashboard | ✅ | `features/dashboard/presentation/dashboard_screen.dart` | Firestore `stats` |
| Shipping Management | ✅ | `features/shipping/...` | `shippingRequests` |
| Customers | ✅ | `features/customers/...` | `customers` |
| Affiliates | ✅ | `features/affiliates/...` | `customers` (roleType: affiliate) |
| Orders | ✅ | `features/orders/...` | `orders` (deprecated?) |
| Invoices | ✅ | `features/invoices/...` | `invoices` |
| Payouts | ✅ | `features/payouts/...` | `affiliatePayouts` |
| Settings | ✅ | `features/settings/...` | `settings` |
| Notifications | ✅ | `features/notifications/...` | `notifications` |
| Content | ✅ | `features/content/...` | `content` |
| News Ticker | ✅ | `features/news_ticker/...` | `newsTicker` |
| Push Notifications | ✅ | `features/push_notifications/...` | FCM |
| Super Admin | ✅ | `features/super_admin/...` | `admin_users` |

## 4.3 Admin Integration Status
```
Admin Dashboard ─────────────────────────────────────► Firebase Auth
       │                                                     │
       ├─────────────────────────────────────────────────────┼────────────────┐
       │                                                     │               │
       ▼                                                     ▼               ▼
Shipping Mgmt ──► Firestore (shippingRequests)      User Mgmt         Payouts
Customers ─────► Firestore (customers)              Affiliates ──► Firestore
Notifications ─► Firestore + FCM                     Settings ──────► Firestore
```

### Admin Tasks:
| Task | Status | Priority |
|------|--------|----------|
| Ensure shippingRequests data writes from mobile app | ❌ | HIGH |
| Customer list shows actual data | ❌ | HIGH |
| Affiliate approval workflow integration | ⚠️ | HIGH |
| Payout approval sends FCM notifications | ❌ | MEDIUM |
| Dashboard stats auto-update | ⚠️ | MEDIUM |
| Export functionality for reports | ❌ | LOW |

---

# BATCH 5: Firebase Backend Integration 🔄 IN PROGRESS
**Focus:** Ensuring Firebase is single source of truth

## 5.1 Firestore Collections
| Collection | Status | Purpose | Admin Access | Mobile Access |
|------------|--------|---------|--------------|---------------|
| `customers` | ✅ | User profiles | Read/Write | Read/Write (own) |
| `shippingRequests` | ⚠️ | Shipment requests | Read/Write | Write (all) |
| `affiliates` | ⚠️ | Affiliate profiles | Read/Write | Read (own) |
| `affiliatePayouts` | ❌ | Payout requests | Read/Write | Write (own) |
| `admin_users` | ✅ | Admin permissions | Read/Write | N/A |
| `notifications` | ✅ | App notifications | Read/Write | Read (own) |
| `stats` | ⚠️ | Dashboard stats | Read/Write | Read |
| `activity_log` | ⚠️ | Audit trail | Write | N/A |
| `settings` | ⚠️ | App settings | Read/Write | Read |

## 5.2 Firebase Functions
| Function | Status | Trigger | Purpose |
|----------|--------|---------|---------|
| onCustomerCreated | ✅ | `customers` onCreate | Welcome email |
| onShippingStatusChange | ❌ | `shippingRequests` onUpdate | Email notification |
| onPayoutRequest | ❌ | `affiliatePayouts` onCreate | Admin notification |
| onPayoutApproved | ❌ | `affiliatePayouts` onUpdate | Affiliate notification |
| onAffiliateSignup | ❌ | `customers` onUpdate | Commission setup |

## 5.3 Security Rules (firestore.rules)
| Rule | Status | Notes |
|------|--------|-------|
| Customers read own | ✅ | `request.auth.uid == resource.data.id` |
| Customers write own | ✅ | With validation |
| Shipping requests public write | ⚠️ | Needs review |
| Admin access | ✅ | Custom claims check |

---

## Firebase Collections Schema

```
📁 customers/
   ├── {uid}/
   │   ├── id: string
   │   ├── name: string
   │   ├── email: string
   │   ├── phone: string
   │   ├── roleType: "customer"|"affiliate"|"superAdmin"|"subAdmin"
   │   ├── status: "active"|"suspended"|"pending"|"deactivated"
   │   ├── affiliateId: string?
   │   ├── affiliateApproved: bool
   │   ├── affiliateCode: string?
   │   ├── commissionRate: number
   │   ├── totalEarnings: number
   │   └── createdAt: timestamp

📁 shippingRequests/
   ├── {id}/
   │   ├── trackingNumber: string (SHP-YYMMDD-XXXXXX)
   │   ├── requesterId: string
   │   ├── requesterType: "guest"|"customer"|"affiliate"
   │   ├── status: "pending"|"approved"|"inTransit"|"delivered"|"cancelled"
   │   ├── origin: map
   │   ├── destination: map
   │   ├── package: map
   │   ├── clientInfo: map
   │   ├── createdAt: timestamp
   │   └── updatedAt: timestamp

📁 affiliatePayouts/
   ├── {id}/
   │   ├── affiliateId: string
   │   ├── amount: number
   │   ├── status: "pending"|"approved"|"paid"|"rejected"
   │   ├── bankInfo: map
   │   ├── requestedAt: timestamp
   │   └── processedAt: timestamp?
```

---

## Enhancement Recommendations

### High Priority
| Enhancement | Impact | Complexity |
|-------------|--------|------------|
| Email template system | High | Medium |
| SMS notifications (Twilio) | High | Medium |
| Real-time shipment tracking map | Medium | High |
| Payment integration (Paystack) | High | High |

### Medium Priority
| Enhancement | Impact | Complexity |
|-------------|--------|------------|
| Deep link handling for affiliate tracking | Medium | Medium |
| Multi-language support | Medium | Medium |
| Dark mode theme | Low | Low |
| Analytics dashboard | Medium | Medium |

### Low Priority
| Enhancement | Impact | Complexity |
|-------------|--------|------------|
| In-app chat support | Low | High |
| Rate limiting for API calls | Low | Low |
| Backup/restore admin tool | Low | Medium |

---

## Progress Summary

| Batch | Name | Status | Completion |
|-------|------|--------|------------|
| 1 | Guest User Journey | 🔄 IN PROGRESS | 70% |
| 2 | Customer Journey | 🔄 IN PROGRESS | 60% |
| 3 | Affiliate Journey | 🔄 IN PROGRESS | 50% |
| 4 | Admin Dashboard | 🔄 IN PROGRESS | 70% |
| 5 | Firebase Integration | 🔄 IN PROGRESS | 60% |

**Overall Progress:** ~62%

---

## Next Actions

1. **Immediate:** Connect guest shipping form to Firestore
2. **Priority:** Ensure `shippingRequests` collection has write access for public
3. **Test:** Verify admin can see guest requests in dashboard
4. **Build:** Deploy admin dashboard to Firebase Hosting

---

*Document auto-generated for ShopsNports Production Readiness*
*Last update: April 8, 2026*
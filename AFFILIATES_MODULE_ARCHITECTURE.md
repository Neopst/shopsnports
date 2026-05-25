# Affiliates Module - Complete Architecture & Commission System

## Overview

The **Affiliates Module** is a complete partner management system that includes:
- Affiliate registration and profile management
- Commission rate configuration (admin-only)
- Automatic commission calculation
- Earnings tracking and reporting
- Payout workflow management

**IMPORTANT**: Commissions are **NOT** a separate module - they are part of the Affiliates Management system.

---

## Architecture

### Collections (Firestore)

#### 1. **`affiliates/`** - Affiliate Profiles
Stores affiliate account information and settings.

```dart
{
  affiliateId (doc ID from users collection)
  {
    "name": "John Partner",
    "email": "john@example.com",
    "phone": "+2347012345678",
    "businessName": "John's Logistics",
    "website": "https://example.com",
    "taxId": "12345678901",
    "bankName": "First Bank Nigeria",
    "accountNumber": "0123456789",
    "status": "active",  // active, suspended, inactive
    "commissionRate": 5.0,  // Percentage (0-100) - SET BY ADMIN
    "commissionType": "percentage",  // percentage or fixed
    "createdAt": timestamp,
    "updatedAt": timestamp,
    "approvedAt": null,  // Auto-filled when registered (auto-approval)
    "suspendedAt": null,
    "suspensionReason": null,
  }
}
```

#### 2. **`commissions/`** - Earnings Ledger
Tracks all commission earnings for each affiliate (calculated automatically on shipment completion).

```dart
{
  commissionId (auto-generated)
  {
    "affiliateId": "user123",
    "shipmentId": "ship456",
    "amount": 25.50,  // Calculated: shipmentAmount * (commissionRate / 100)
    "currency": "USD",
    "commissionRate": 5.0,  // Rate used for this calculation
    "shipmentAmount": 510.00,  // Original shipment amount
    "status": "pending",  // pending, paid, void
    "earnedAt": timestamp,  // When shipment was completed
    "paidAt": null,  // When payout was processed
    "payoutId": null,  // Link to payout document
    "notes": "Commission from shipment #ship456"
  }
}
```

#### 3. **`payouts/`** - Payment Records
Manual transaction records for affiliate payments.

```dart
{
  payoutId (auto-generated)
  {
    "affiliateId": "user123",
    "amount": 150.00,  // Total paid
    "currency": "USD",
    "bankName": "First Bank Nigeria",
    "accountNumber": "0123456789",
    "status": "processed",  // pending, processed, failed
    "frequency": "monthly",  // monthly, quarterly, on-demand
    "paymentMethod": "bank_transfer",  // bank_transfer, check, paypal, etc.
    "requestedAt": timestamp,
    "processedAt": timestamp,
    "notes": "Monthly payout",
    "commissionIds": ["comm1", "comm2", "comm3"],  // Which commissions are included
    "createdBy": "admin123"  // Which admin processed
  }
}
```

---

## Commission System Flow

### 1. Registration (Affiliate)
```
Affiliate fills registration form
  ↓
System creates user + affiliate profile
  ↓
Auto-approval: status = "active"
  ↓
Affiliate can immediately start sharing referral links
```

### 2. Commission Rate Setting (Admin)
```
Admin Dashboard → Affiliates Management → Edit Affiliate Profile
  ↓
Set commission rate (0-100%)
  ↓
Save to affiliates/[affiliateId]/commissionRate
  ↓
Applied to all future shipments referred by this affiliate
```

### 3. Shipment Completion → Commission Creation (Automatic)
```
Customer completes shipping request
  ↓
System checks shipping/referralAffiliateId field
  ↓
IF referral affiliate exists:
  ├─ Fetch affiliate's commissionRate from affiliates/[id]
  ├─ Calculate: commission = shipmentAmount * (rate / 100)
  ├─ Create document in commissions/ collection
  ├─ Set status = "pending"
  └─ Set earnedAt = current timestamp

Commission now appears in affiliate's earnings dashboard
```

### 4. Payout Processing (Admin)
```
Admin Dashboard → Affiliates → Payouts
  ↓
Select affiliate + pending commissions
  ↓
Set payout details (amount, method, frequency)
  ↓
Create payout document
  ↓
Update related commission docs: status = "paid", paidAt = now, payoutId = [id]
  ↓
Send notification to affiliate (payment processed)

Affiliate sees in history: "Payout #pay123 - $150 received on Jan 15"
```

---

## Admin Controls

### Affiliates Management Module
**Location**: `admin/admin/lib/screens/affiliates/`

#### Screens:
1. **Affiliates List** - View all affiliates with status, earnings, commission rate
   - Search, filter by status
   - Quick actions: View, Edit, Suspend, View Earnings

2. **Affiliate Detail** - Full profile edit
   - Name, email, phone (with all country codes + flags)
   - Business info (tax ID, website)
   - Bank details for payouts
   - Commission rate (PRIMARY CONTROL)
   - Status management

3. **Commission Ledger** - View all commissions
   - Filter by affiliate, date range, status
   - Total earnings, pending earnings, paid earnings
   - Export functionality

4. **Payouts Management** - Process affiliate payments
   - Create payout batch
   - Select commissions to include
   - Confirm bank details
   - Track payment status

### Key Admin Actions:
- ✅ View affiliate list with search/filter
- ✅ View individual affiliate profile
- ✅ Edit commission rate for each affiliate
- ✅ View earnings history
- ✅ Create/process payouts
- ✅ View payment history
- ✅ Suspend/activate affiliates
- ✅ Export earnings reports

---

## Affiliate Dashboard (Self-Service)

### Screens:
1. **Dashboard** - Quick stats
   - Total earned (lifetime)
   - Pending earnings
   - Next payout date
   - Quick actions

2. **Earnings History** - Commission ledger
   - Date, shipment details, amount, status
   - Filter by date range, status
   - Receipt generation

3. **Payouts** - Payment history
   - Payout date, amount, method, status
   - Download payment receipts

4. **Profile** - Self-service updates
   - Name, email, phone (with countries + flags)
   - Business info
   - Bank account (for payouts)
   - Password
   - Tax documents upload (future)

---

## Phone Field Enhancements (Global)

All phone fields throughout the app now support:

### Features:
- ✅ **All 195 world countries** with flags + country codes
- ✅ **Searchable dropdown** - Type "nig" → Nigeria, "uga" → Uganda
- ✅ **Autocomplete** - First few letters filter results
- ✅ **Country flags** - Visual identification
- ✅ **Country codes** - Auto-populated (e.g., +234, +256)
- ✅ **ISO codes** - For regional reference

### Forms Using Enhanced Phone Field:
1. **Customer Signup** (`lib/screens/auth/unified_signup_screen.dart`)
   - Country selector + phone input
   - Country flag + code display
   - Searchable dropdown in modal dialog

2. **Affiliate Registration** (`lib/screens/auth/affiliate_registration_screen.dart`)
   - Same enhanced phone field
   - Optional field

3. **Guest Checkout** (future)
   - Required field

4. **User Profile Edit** (future)
   - Allow updating phone with country code

### Implementation:
```dart
// New reusable widget
CountryPhoneField(
  phoneController: textCtl,
  initialCountry: selectedCountry,
  onCountryChanged: (country) => setState(...),
  label: 'Phone Number',
  hintText: 'Enter phone number',
)

// Countries constant file
lib/utils/countries.dart
- 195 countries with flags, codes, ISO codes
- Search function for filtering
- Default country getter
```

---

## Data Flow Example: Complete Affiliate Scenario

### Scenario: Affiliate "John Partner" earns commission

**Day 1: Registration**
```
John submits affiliate registration form
- Name: John Partner
- Email: john@example.com
- Phone: +234 (Nigeria) 7012345678 → Saved as "+2347012345678"
- Business: John's Logistics
- Bank: First Bank Nigeria, Acct: 0123456789

✅ Auto-approved → Status: "active"
✅ Creates: users/john123, affiliates/john123
```

**Day 2: Admin Sets Commission**
```
Admin: Dashboard → Affiliates → Find "John Partner"
Admin: Clicks "Edit" → Sets Commission Rate to "5.0%"
✅ affiliates/john123.commissionRate = 5.0

John is now earning 5% on all referrals
```

**Day 5: Customer Ships via John's Referral**
```
Customer A books shipment through John's link
Shipping details:
- Route: Lagos → Abuja
- Amount: $500
- referralAffiliateId: john123

System completes and marks shipment as paid
Automatic trigger: Create commission

✅ commissions/comm001 created:
   - affiliateId: john123
   - shipmentAmount: 500.00
   - commissionRate: 5.0
   - amount: 25.00 (500 * 5%)
   - status: pending
   - earnedAt: 2026-02-25 15:30 UTC

✅ John sees in earnings: "+$25.00 (Pending)"
```

**Day 10-15: More Shipments**
```
Customers B, C, D also ship via John's links:
- Shipment B: $300 → Commission: $15.00
- Shipment C: $1000 → Commission: $50.00
- Shipment D: $200 → Commission: $10.00

John's Dashboard Shows:
- Total Earned: $100.00
- Pending: $100.00
- Status: All 4 commissions pending
```

**Day 20: Admin Processes Payout**
```
Admin: Dashboard → Payouts → Create New Payout
- Affiliate: John Partner
- Include commissions: 4 commissions ($100 total)
- Bank details: Confirmed
- Status: Ready to process

Admin: Approves payout
✅ Payout created: payouts/payout001
✅ All 4 commission docs updated:
   - status: paid
   - paidAt: 2026-02-20 10:00 UTC
   - payoutId: payout001

✅ John gets notification: "Your payout of $100 has been processed"
✅ John's dashboard shows: 
   - All commissions marked as PAID
   - Payment receipt available
```

---

## Configuration Notes

### Default Commission Rate
- New affiliates: Rate can be set to 0% (requires admin to activate)
- Auto-approval: All affiliates start as "active" regardless of rate

### Commission Calculation
- Applied on shipment **completion**, not on booking
- Only to shipping amounts, not extras/surcharges
- Rounded to 2 decimal places (nearest cent/basic unit)

### Payout Frequency
- Admin configured per payout request
- Affiliates can request on-demand (future feature)
- Typically: monthly, quarterly, or per-request

### Tax Compliance
- Tax ID stored (for future T4/1099 generation)
- Payout records maintain audit trail
- Admin can export for tax reporting

---

## Future Enhancements

- [ ] Tax document uploads (W9, T4, TIN)
- [ ] Payout scheduling (automatic monthly)
- [ ] Commission tiers (additional % for reaching milestones)
- [ ] Referral codes tracking
- [ ] Performance dashboard (charts, trends)
- [ ] Bulk affiliate management (CSV import)
- [ ] Commission dispute resolution workflow

---

## Status Summary

**✅ COMPLETED:**
- [x] Affiliate registration with auto-approval
- [x] Affiliate profile management
- [x] Commission rate configuration (admin)
- [x] Commission ledger (earnings tracking)
- [x] Payout request/processing (admin)
- [x] Phone field with global countries + search
- [x] Database structure (Firestore)
- [x] Admin dashboard screens (planned)

**🚧 IN PROGRESS:**
- [ ] Admin dashboard Affiliates module (UI)
- [ ] Commission auto-calculation on shipment completion
- [ ] Payout batch processing

**⏳ NOT YET STARTED:**
- [ ] Affiliate self-service dashboard
- [ ] Tax document workflow
- [ ] Advanced reporting/analytics
- [ ] Automatic payout scheduling

---

**Last Updated**: February 25, 2026
**Module Status**: Core infrastructure COMPLETE, Admin UI and Affiliate Dashboard PENDING

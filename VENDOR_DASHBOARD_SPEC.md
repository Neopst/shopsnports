# 📦 VENDOR DASHBOARD SPECIFICATION

## Web Admin Dashboard - Vendor Section Structure

### Overview
The vendor dashboard provides business owners with comprehensive analytics and management tools for their online store.

---

## 📊 DASHBOARD SECTIONS

### 1. **Stats Overview (Top Cards)**
- **Total Products**: Count of active products
- **Total Orders**: Count of all orders
- **Total Earnings**: Cumulative revenue
- **Pending Payout**: Amount awaiting withdrawal
- **Average Rating**: Customer satisfaction score
- **Review Count**: Total customer reviews

### 2. **Monthly Earnings Chart**
- **Type**: Bar chart / Line chart
- **Data**: Last 6 months earnings
- **Format**: Currency with month labels
- **Purpose**: Track revenue trends

### 3. **Quick Actions**
- Add New Product
- View All Orders
- Manage Products
- View Analytics
- Request Payout

### 4. **Recent Orders Table**
- Order ID
- Customer Name
- Amount
- Status (pending, processing, shipped, delivered)
- Date
- Actions (view, update status)

### 5. **Vendor Profile Info**
- Business Name
- Owner Name
- Email
- Phone
- Status Badge (pending, approved, suspended)
- Tier Badge (starter, pro, enterprise)
- Commission Rate

---

## 📱 MOBILE APP - SIMPLIFIED VENDOR DASHBOARD

### Features to Display
1. **Stats Cards (4 main metrics)**:
   - Orders Count
   - Products Count
   - Total Earnings (formatted as currency)
   - Pending Payout

2. **Monthly Earnings Mini Chart**:
   - Last 6 months
   - Simple bar visualization
   - No external chart library

3. **Quick Actions Menu**:
   - Manage Products (navigate to product list)
   - View Orders (navigate to orders list)
   - Request Payout (navigate to payout screen)

4. **Vendor Status Indicator**:
   - Approval status
   - Tier level
   - Commission rate

---

## 🧪 TEST DATA (Matching Admin Dashboard)

### Mock Vendor Profile
```json
{
  "id": "vendor_test_001",
  "userId": "onKwFWGTpaRBViQ28DY9gXzjWzK2",
  "businessName": "Sports Equipment Plus",
  "ownerName": "Test User",
  "email": "tester@shopsnports.com",
  "phone": "+1234567890",
  "status": "approved",
  "tier": "pro",
  "commissionRate": 15.0,
  "totalProducts": 12,
  "totalOrders": 24,
  "totalEarnings": 331000,
  "pendingPayout": 52500,
  "rating": 4.7,
  "reviewCount": 18
}
```

### Monthly Earnings (Last 6 Months)
```json
[
  {"month": "Jul", "amount": 45000},
  {"month": "Aug", "amount": 52000},
  {"month": "Sep", "amount": 48000},
  {"month": "Oct", "amount": 61000},
  {"month": "Nov", "amount": 58000},
  {"month": "Dec", "amount": 67000}
]
```

### Recent Orders Sample
```json
[
  {
    "id": "ORD-2025-001",
    "customerName": "John Doe",
    "amount": 12500,
    "status": "pending",
    "date": "2025-12-28"
  },
  {
    "id": "ORD-2025-002",
    "customerName": "Jane Smith",
    "amount": 8900,
    "status": "shipped",
    "date": "2025-12-27"
  }
]
```

---

## 🎯 MOBILE APP IMPLEMENTATION GOALS

1. **Match Admin Dashboard Data**: Use same test data
2. **Simplified UI**: Focus on essential metrics
3. **Responsive Cards**: Material Design 3 cards
4. **Currency Formatting**: Display cents as dollars ($331.00)
5. **Loading States**: Show spinners while fetching data
6. **Error Handling**: Show error message with retry button
7. **Pull to Refresh**: Refresh all dashboard data

---

## ✅ ACCEPTANCE CRITERIA

- [ ] Stats cards show correct values from mock data
- [ ] Monthly chart displays 6 months of data
- [ ] Earnings displayed in dollar format ($450.00, not 45000 cents)
- [ ] Loading states work properly
- [ ] Error states show retry option
- [ ] Navigation to products/orders works
- [ ] Vendor status badge displays correctly
- [ ] Data matches admin dashboard test vendor

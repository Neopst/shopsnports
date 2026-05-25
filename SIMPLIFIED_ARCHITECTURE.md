# 🏗️ SHOPSNPORTS - SIMPLIFIED ARCHITECTURE
**Three Entities. Firebase as Single Source of Truth.**

---

## 📱 **ARCHITECTURE OVERVIEW**

```
┌─────────────────────────┐
│   MOBILE APP (Flutter)  │
│   - Customers          │
│   - Affiliates         │
│   - Shippers           │
└────────────┬────────────┘
             │
             ├─ Reads/Writes
             │
┌────────────▼────────────────────────┐
│  FIREBASE/FIRESTORE (Source of Truth)│
│  - Collections:                      │
│    • users                          │
│    • shipping_requests              │
│    • notifications                  │
│    • shipments                      │
│    • banners                        │
│    • news_items                     │
└────────────┬────────────────────────┘
             │
             ├─ Reads/Writes
             │
┌────────────▼──────────────────┐
│  WEB ADMIN DASHBOARD          │
│  - View requests              │
│  - Manage shipments           │
│  - Send notifications         │
│  - View analytics             │
└───────────────────────────────┘
```

---

## 🚀 **USER JOURNEY (Mobile App)**

### **1. Customer/Guest - Create Shipping Request**
```
Customer opens mobile app
        ↓
Navigates to "Request Shipping"
        ↓
Fills form (6 sections):
  • Freight type
  • Shipment details
  • Sender info
  • Receiver info
  • Documentation
  • Other info
        ↓
SUBMIT FORM
        ↓
Data written directly to Firestore:
  POST: /shipping_requests/{requestId}
        ↓
Firebase triggers notification:
  → Admin gets notification (Firestore Messaging)
  → Affiliate gets notification (if tagged)
        ↓
Success screen displays:
  "Your request was successfully sent.
   An agent will contact you. Thank you!"
        ↓
Request appears in admin dashboard in real-time
```

### **2. Shipper - View & Accept Shipment**
```
Shipper opens mobile app
        ↓
Views available shipments
  (Real-time from Firestore)
        ↓
Clicks "Accept Shipment"
        ↓
Updates Firestore:
  PATCH: /shipping_requests/{requestId}
  Set: status = "assigned"
  Set: shipperId = {shipper_id}
        ↓
Firebase triggers notification:
  → Admin gets notification
  → Customer gets notification
        ↓
Shipper can now:
  • Update tracking status
  • Upload documents
  • Add delivery notes
```

### **3. Affiliate - View Commissions**
```
Affiliate opens mobile app
        ↓
Views dashboard:
  • Referred requests count
  • Commission earned
  • Status of each request
        ↓
All data read from Firestore
  (Real-time updates)
        ↓
Can share unique referral token
  (Links to pre-filled request form)
        ↓
When customer uses token:
  Firestore auto-tags affiliate_id
  Affiliate gets notified
```

---

## 👨‍💼 **ADMIN JOURNEY (Web Dashboard)**

### **1. View Incoming Requests**
```
Admin logs into web dashboard
        ↓
Real-time Firestore listener:
  Collection: shipping_requests
  Filter: status = "new"
        ↓
Dashboard displays:
  • Request list (newest first)
  • Customer details
  • Shipment details
  • Attached documents
        ↓
Click on any request → Full details
```

### **2. Assign to Shipper**
```
Admin views pending request
        ↓
Clicks "Assign Shipper"
        ↓
Selects shipper from list
        ↓
Updates Firestore:
  PATCH: /shipping_requests/{requestId}
  Set: shipperId = {selected_shipper_id}
  Set: status = "assigned"
        ↓
Firebase triggers notification:
  → Shipper gets mobile notification
  → Customer gets email notification
        ↓
Dashboard updates in real-time
```

### **3. Track Shipment**
```
Admin dashboard shows:
  • Real-time shipment status
  • Shipper location (if enabled)
  • Delivery proof
  • Customer communications
        ↓
Can update status:
  "in_transit" → "delivered" → "completed"
        ↓
Each status change triggers notifications
  to customer & shipper
```

### **4. View Analytics**
```
Admin dashboard shows:
  • Total requests this month
  • Avg delivery time
  • Top shippers
  • Customer satisfaction
        ↓
All data aggregated from Firestore
  (Real-time stats)
```

---

## 🔄 **DATA FLOW SUMMARY**

### **Write Operations**
```
Mobile App → Firestore → Triggers Cloud Functions
                      ↓
                Cloud Functions send notifications
                      ↓
                Web Dashboard sees real-time updates
```

### **Read Operations**
```
Web Admin Dashboard ← Real-time Firestore listener
Mobile App ← Real-time Firestore listener

(Both see same data simultaneously)
```

### **Notifications Flow**
```
User action in Mobile App
        ↓
Writes to Firestore
        ↓
Cloud Function triggered
        ↓
FCM notification sent:
  • Admin: "New shipping request from John Doe"
  • Affiliate: "Request from your referral"
  • Shipper: "New shipment assigned to you"
  • Customer: "Your request was received"
```

---

## 📋 **FIRESTORE COLLECTIONS** (Single Source of Truth)

```
users/
  {userId}/
    - name
    - email
    - phone
    - role (customer, affiliate, shipper, admin)
    - createdAt

shipping_requests/
  {requestId}/
    - customerId
    - affiliateId (optional)
    - shipperId (assigned later)
    - freight_type (airport-airport, door-door)
    - shipment_details { }
    - sender_details { }
    - receiver_details { }
    - documents[] (URLs to files)
    - other_information
    - status (new, assigned, in_transit, delivered, completed)
    - createdAt
    - updatedAt

notifications/
  {notificationId}/
    - userId
    - type (request_created, shipment_assigned, delivery_proof, etc)
    - title
    - message
    - data { requestId, shipperId, etc }
    - read (boolean)
    - createdAt

shipments/
  {shipmentId}/
    - requestId (reference)
    - status
    - tracking_updates[]
    - delivery_proof (photo/signature)
    - estimatedDelivery
    - actualDelivery

banners/
  {bannerId}/
    - title
    - subtitle
    - image_url
    - active (boolean)
    - position (order)
    - createdAt

news_items/
  {newsId}/
    - title
    - content
    - published (boolean)
    - createdAt
```

---

## ✅ **WHAT THIS ELIMINATES**

❌ **PostgreSQL** - Not needed
❌ **REST API** - Not needed
❌ **Database migrations** - Not needed
❌ **API authentication** - Firebase handles it
❌ **Manual notifications** - Cloud Functions handle it
❌ **Data synchronization** - Firestore is real-time

---

## 🎯 **BENEFITS OF THIS ARCHITECTURE**

✅ **Simple** - 3 entities, 1 source of truth
✅ **Real-time** - All changes instant across all devices
✅ **Scalable** - Firestore auto-scales
✅ **Secure** - Firestore security rules control access
✅ **Cost-effective** - Pay-as-you-go pricing
✅ **Fast to build** - No backend needed
✅ **Easy to maintain** - Fewer moving parts
✅ **Mobile-first** - Built for real-time apps

---

## 🚀 **QUICK START CHECKLIST**

- [ ] Create Firestore collections (above schema)
- [ ] Set up Cloud Function for notifications
- [ ] Create simplified shipping request form (6 sections)
- [ ] Build web dashboard (view + assign + track)
- [ ] Update mobile app (write to Firestore)
- [ ] Set up Firestore Security Rules
- [ ] Configure Firebase Cloud Messaging (FCM)
- [ ] Deploy and test end-to-end

---

**Result:** A clean, modern, Firebase-native shipping platform. No complexity. Pure functionality. 🎉

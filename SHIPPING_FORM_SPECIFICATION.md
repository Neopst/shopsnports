# SHIPPING FORM FIELD SPECIFICATION & IMPLEMENTATION PLAN
**Date:** February 27, 2026

---

## 1. FIELD SPECIFICATION (21 Fields Total)

### ✅ COMPLETE FIELD LIST - Spec Compliance

| # | Section | Field Name | Type | Required | Mobile Model | Admin Model | Notes |
|---|---------|-----------|------|----------|---|---|---|
| 1 | Freight Type | freightType | enum | ✅ | ✅ | ✅ | 'airport_to_airport' or 'door_to_door' |
| 2 | Shipment | itemDescription | text | ✅ | ✅ | ✅ | What's being shipped |
| 3 | Shipment | hsCode | text | ❌ | ✅ | ✅ | Harmonized System Code (optional) |
| 4 | Shipment | departingLocation | text | ✅ | ✅ | ✅ | From location |
| 5 | Shipment | departureDate | date | ❌ | ✅ | ✅ | Optional departure date |
| 6 | Shipment | destinationLocation | text | ✅ | ✅ | ✅ | To location |
| 7 | Shipment | arrivalDate | date | ❌ | ✅ | ✅ | Optional arrival date |
| 8 | Shipment | shipmentWeight | double | ✅ | ✅ | ✅ | In kilograms |
| 9 | Shipment | shipmentLength | double | ✅ | ✅ | ✅ | In centimeters |
| 10 | Shipment | shipmentWidth | double | ✅ | ✅ | ✅ | In centimeters |
| 11 | Shipment | shipmentHeight | double | ✅ | ✅ | ✅ | In centimeters |
| 12 | Shipment | shipmentPackaging | text | ✅ | ✅ | ✅ | Brief packaging description |
| 13 | Sender | senderName | text | ✅ | ✅ | ✅ | Full name |
| 14 | Sender | senderAddress | text | ✅ | ✅ | ✅ | Complete address |
| 15 | Sender | senderPhone | text | ✅ | ✅ | ✅ | Contact phone |
| 16 | Sender | senderEmail | text | ✅ | ✅ | ✅ | Contact email |
| 17 | Receiver | receiverName | text | ✅ | ✅ | ✅ | Full name |
| 18 | Receiver | receiverAddress | text | ✅ | ✅ | ✅ | Complete address |
| 19 | Receiver | receiverPhone | text | ✅ | ✅ | ✅ | Contact phone |
| 20 | Receiver | receiverEmail | text | ✅ | ✅ | ✅ | Contact email |
| 21 | Attachments | attachments | file[] | ❌ | ✅ | ✅ | Multiple files (invoices, docs, etc) |
| 22 | Other | otherInformation | text | ❌ | ✅ | ✅ | Additional notes/special requirements |

**System Fields (automatically set):**
- id (doc ID)
- requesterId (user's ID)
- affiliateId (if applicable)
- status (pending, approved, in_transit, delivered, cancelled)
- createdAt (timestamp)
- updatedAt (timestamp)
- trackingNumber (set by admin)
- assignedAdminId (assigned by admin)
- estimatedCost (calculated or quoted)
- actualCost (final cost)

---

## 2. FIRESTORE COLLECTION SCHEMA

### Collection: `shippingRequests`

```
shippingRequests/
├── {requestId}
│   ├── requesterId: string (user ID)
│   ├── affiliateId: string (optional)
│   ├── status: string (pending|approved|in_transit|delivered|cancelled)
│   ├── createdAt: timestamp
│   ├── updatedAt: timestamp
│   │
│   ├── freightType: string (airport_to_airport|door_to_door)
│   │
│   ├── itemDescription: string
│   ├── hsCode: string (optional)
│   ├── departingLocation: string
│   ├── departureDate: timestamp (optional)
│   ├── destinationLocation: string
│   ├── arrivalDate: timestamp (optional)
│   ├── shipmentWeight: number (kg)
│   ├── shipmentLength: number (cm)
│   ├── shipmentWidth: number (cm)
│   ├── shipmentHeight: number (cm)
│   ├── shipmentPackaging: string
│   │
│   ├── senderName: string
│   ├── senderAddress: string
│   ├── senderPhone: string
│   ├── senderEmail: string
│   │
│   ├── receiverName: string
│   ├── receiverAddress: string
│   ├── receiverPhone: string
│   ├── receiverEmail: string
│   │
│   ├── attachments: array
│   │   └── {
│   │       ├── id: string (UUID)
│   │       ├── fileName: string
│   │       ├── fileUrl: string (Cloud Storage URL)
│   │       ├── fileType: string (invoice|proforma|packing_list|other)
│   │       ├── fileSizeBytes: number
│   │       └── uploadedAt: timestamp
│   │   }
│   │
│   ├── otherInformation: string (optional)
│   ├── trackingNumber: string (optional)
│   ├── assignedAdminId: string (optional)
│   ├── rejectionReason: string (optional)
│   ├── estimatedCost: number
│   └── actualCost: number
```

---

## 3. MODELS CREATED ✅

### Mobile Model: `lib/models/shipping_request_simplified.dart`
- ✅ 21 fields + system fields
- ✅ ShippingRequestSimplified class
- ✅ ShippingDocument class for attachments
- ✅ toFirestore() method
- ✅ fromFirestore() factory

### Admin Model: `admin/admin/lib/features/shipping/domain/shipping_request_simplified_model.dart`
- ✅ 21 fields + system fields
- ✅ ShippingRequestSimplified class
- ✅ ShippingDocumentModel class
- ✅ Status display methods
- ✅ fromFirestore() factory

---

## 4. REMAINING WORK - Implementation Checklist

### Phase 1: Form UI (Mobile App)
- [ ] Create simplified shipping form screen (`lib/screens/shipping/shipping_request_form.dart`)
- [ ] Implement 6 sections in expandable cards:
  - [ ] Freight Type (dropdown: Airport-to-Airport / Door-to-Door)
  - [ ] Shipment Details (11 fields)
  - [ ] Sender Details (4 fields)
  - [ ] Receiver Details (4 fields)
  - [ ] File Attachments (multi-file picker)
  - [ ] Other Information (text area)
- [ ] Add validation for required fields (marked with *)
- [ ] Add file upload to Cloud Storage
- [ ] Submit to Firestore `shippingRequests` collection

### Phase 2: Repository Layer (Mobile)
- [ ] Create `lib/repositories/shipping_request_repository.dart`
- [ ] Implement:
  - [ ] `createShippingRequest()` - save to Firestore
  - [ ] `uploadAttachments()` - upload files to Cloud Storage
  - [ ] `getShippingRequests()` - fetch user's requests
  - [ ] `updateShippingRequest()` - update existing request

### Phase 3: Admin Dashboard - List View
- [ ] Update `admin/admin/lib/features/shipping/presentation/shipping_request_management_screen.dart`
- [ ] Display fields in order:
  - [ ] Request ID
  - [ ] Sender Name
  - [ ] Receiver Name
  - [ ] Tracking Status
  - [ ] Freight Type
  - [ ] Route (From → To)
  - [ ] Weight
  - [ ] Date Created
  - [ ] Cost
  - [ ] Actions (View, Assign, Download Docs)

### Phase 4: Admin Dashboard - Detail View
- [ ] Create detail screen showing all 21 fields
- [ ] Layout by section:
  - [ ] **Freight Type** section
  - [ ] **Shipment Details** section
  - [ ] **Sender Details** section
  - [ ] **Receiver Details** section
  - [ ] **Attachments** section with download buttons
  - [ ] **Other Information** section
- [ ] Include admin actions:
  - [ ] Assign tracking number
  - [ ] Update status
  - [ ] Download attachments
  - [ ] View/print details

### Phase 5: File Management
- [ ] Setup Firebase Cloud Storage folder: `shipping-documents/`
- [ ] Implement file picker for multiple files
- [ ] File upload with progress indicator
- [ ] Allowed file types: PDF, PNG, JPG, DOCX, XLS, etc.
- [ ] Max file size: 10MB per file, 50MB per request
- [ ] Create download functionality for admin

### Phase 6: Firestore Rules
- [ ] Create rules for `shippingRequests` collection:
  ```
  allow create: if request.auth.uid == resource.data.requesterId
  allow read: if request.auth.uid == resource.data.requesterId || request.auth.uid == resource.data.assignedAdminId
  allow update: if request.auth.uid == resource.data.assignedAdminId  // Only admin can update
  ```

---

## 5. FORM FIELD ORDER (Exact Sequence)

**User sees fields in this exact order:**

```
1. FREIGHT TYPE
   └─ Dropdown: "Airport to Airport" / "Door to Door"

2. SHIPMENT DETAILS
   └─ Item Description (text, required)
   └─ HS Code (text, optional)
   └─ From/Departing Location (text, required)
   └─ Departure Date (date picker, optional)
   └─ To/Destination Location (text, required)
   └─ Arrival Date (date picker, optional)
   └─ Shipment Weight (number, kg, required)
   └─ Shipment Dimensions (3 numbers: L×W×H in cm, required)
   └─ Shipment Packaging (text, required)

3. SENDER DETAILS
   └─ Name (text, required)
   └─ Address (text area, required)
   └─ Phone Number (text, required)
   └─ Email (text, required)

4. RECEIVER DETAILS
   └─ Name (text, required)
   └─ Address (text area, required)
   └─ Phone Number (text, required)
   └─ Email (text, required)

5. ATTACH RELEVANT DOCUMENTATION
   └─ File picker (accept PDF, images, documents, max 10MB each)
   └─ Show list of selected files with delete option

6. OTHER INFORMATION
   └─ Text area for special requirements, notes, etc.

[SEND REQUEST BUTTON]
```

---

## 6. FIRESTORE -> ADMIN DISPLAY MAPPING

**Admin dashboard displays these fields in this exact visual order:**

```
SHIPPING REQUEST DETAIL VIEW

┌─ Freight Type: Airport to Airport
├─ Status: Pending (with status badge)
├─ Request ID: {id}
├─ Requested: Feb 27, 2026 at 14:30
│
├─ SHIPMENT DETAILS
│  ├─ Item: Electronics equipment
│  ├─ HS Code: 8471.30
│  ├─ From: Lagos, Nigeria
│  ├─ Depart: Feb 28, 2026
│  ├─ To: London, United Kingdom
│  ├─ Arrive: Mar 02, 2026
│  ├─ Weight: 150 kg
│  ├─ Dimensions: 200×150×100 cm
│  └─ Packaging: Wooden crate
│
├─ SENDER DETAILS
│  ├─ Name: John Smith
│  ├─ Address: Lagos, Nigeria
│  ├─ Phone: +234 8012345678
│  └─ Email: john@example.com
│
├─ RECEIVER DETAILS
│  ├─ Name: Jane Doe
│  ├─ Address: London, United Kingdom
│  ├─ Phone: +44 7700963456
│  └─ Email: jane@example.com
│
├─ ATTACHMENTS (2 files)
│  ├─ invoice.pdf (1.2 MB) [Download] [Preview]
│  └─ packing_list.pdf (0.8 MB) [Download] [Preview]
│
├─ ADDITIONAL INFO
│  └─ Handle with care - fragile items
│
└─ ADMIN ACTIONS
   ├─ [Assign Tracking Number]
   ├─ [Update Status] → [Approve] [Assign] [In Transit] [Delivered]
   └─ [View All Attachments]
```

---

## 7. IMPLEMENTATION PRIORITY

**HIGH PRIORITY (Do First):**
1. ✅ Create mobile model - DONE
2. ✅ Create admin model - DONE
3. Create mobile form UI (Phases 1-2)
4. Create admin list view (Phase 3)

**MEDIUM PRIORITY (Do Next):**
5. Create admin detail view (Phase 4)
6. Implement file upload (Phase 5)

**LOWER PRIORITY:**
7. Firestore rules (Phase 6)
8. Testing & refinement

---

## 8. DATABASE INDEXES NEEDED

```firestore.indexes.json
{
  "indexes": [
    {
      "collectionGroup": "shippingRequests",
      "fields": [
        {"fieldPath": "requesterId", "order": "ASCENDING"},
        {"fieldPath": "createdAt", "order": "DESCENDING"}
      ]
    },
    {
      "collectionGroup": "shippingRequests",
      "fields": [
        {"fieldPath": "status", "order": "ASCENDING"},
        {"fieldPath": "createdAt", "order": "DESCENDING"}
      ]
    },
    {
      "collectionGroup": "shippingRequests",
      "fields": [
        {"fieldPath": "assignedAdminId", "order": "ASCENDING"},
        {"fieldPath": "status", "order": "ASCENDING"}
      ]
    }
  ]
}
```

---

## ✅ SUMMARY

**Status: Field Specification Complete**

| Component | Status |
|-----------|--------|
| Field spec defined | ✅ COMPLETE (21 fields) |
| Firestore schema | ✅ COMPLETE |
| Mobile model | ✅ COMPLETE |
| Admin model | ✅ COMPLETE |
| Mobile form | ⏳ TODO |
| Admin list/detail | ⏳ TODO |
| File upload | ⏳ TODO |
| Testing | ⏳ TODO |

**Next Step:** Create simplified mobile shipping form using the model spec above.

All 21 fields are now properly defined and synchronized across mobile model, admin model, and Firestore schema!

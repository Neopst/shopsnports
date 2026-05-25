# Manual Firebase Firestore Setup - shippingRequests Collection

## Collection Name
```
shippingRequests
```

---

## Sample Document (Copy-Paste Ready)

Use this data when creating your sample document in Firebase Console.

### Paste this as JSON:

```json
{
  "id": "SHP-20260302-SAMPLE",
  "requesterId": "user_sample_001",
  "affiliateId": "",
  "clientName": "Sample Client Inc",
  "clientEmail": "client@example.com",
  "clientPhone": "+1-234-567-8900",
  "type": "air",
  "status": "pending",
  "priority": "standard",
  "origin": "New York, USA",
  "destination": "Lagos, Nigeria",
  "description": "Sample shipment for testing",
  "weight": 100.5,
  "length": 80,
  "width": 60,
  "height": 50,
  "estimatedCost": 2500,
  "actualCost": 0,
  "affiliateCommission": 0,
  "requiresInsurance": true,
  "requiresCustomsClearance": true,
  "trackingNumber": "SHP-20260302-ABC12",
  "createdAt": "2026-03-02",
  "updatedAt": "2026-03-02"
}
```

---

## Step-by-Step Firebase Console Instructions

### Step 1: Open Firebase Console

1. Go to: **https://console.firebase.google.com**
2. Select **shopsnports** project
3. Click **Firestore Database** (left sidebar)

### Step 2: Create Collection

1. Click **+ Start Collection** (or **Create Collection**)
2. **Collection ID**: `shippingRequests`
3. Click **Next**

### Step 3: Add Sample Document

1. **Document ID**: Click **Auto ID** (generates automatic ID)
2. In the **Add the first document** screen:

#### Method A: Field-by-Field (Easier)

| Field Name | Type | Value |
|---|---|---|
| id | String | `SHP-20260302-SAMPLE` |
| requesterId | String | `user_sample_001` |
| affiliateId | String | `` (empty) |
| clientName | String | `Sample Client Inc` |
| clientEmail | String | `client@example.com` |
| clientPhone | String | `+1-234-567-8900` |
| type | String | `air` |
| status | String | `pending` |
| priority | String | `standard` |
| origin | String | `New York, USA` |
| destination | String | `Lagos, Nigeria` |
| description | String | `Sample shipment for testing` |
| weight | Number | `100.5` |
| length | Number | `80` |
| width | Number | `60` |
| height | Number | `50` |
| estimatedCost | Number | `2500` |
| actualCost | Number | `0` |
| affiliateCommission | Number | `0` |
| requiresInsurance | Boolean | `true` |
| requiresCustomsClearance | Boolean | `true` |
| trackingNumber | String | `SHP-20260302-ABC12` |
| createdAt | String | `2026-03-02` |
| updatedAt | String | `2026-03-02` |

**Steps for Field-by-Field:**
1. Click **Add field**
2. Enter field name from table above
3. Select type from dropdown
4. Enter value
5. Repeat for all 24 fields
6. Click **Save**

#### Method B: JSON Import (Faster - If Firebase Supports)

1. Look for **"Import Document"** or similar option
2. Paste the JSON from above
3. Click **Import** or **Save**

### Step 4: Verify Collection Created

After saving, you should see:
- Collection: `shippingRequests`
- Document ID: (auto-generated, e.g., `abc123xyz`)
- 24 fields visible in document

---

## All Field Names & Types Reference

| # | Field Name | Type | Required | Notes |
|---|---|---|---|---|
| 1 | id | String | ✅ | Document identifier |
| 2 | requesterId | String | ✅ | Firebase UID |
| 3 | affiliateId | String | ❌ | Can be empty |
| 4 | clientName | String | ✅ | Customer name |
| 5 | clientEmail | String | ✅ | Valid email |
| 6 | clientPhone | String | ✅ | Phone number |
| 7 | type | String | ✅ | air / sea / land |
| 8 | status | String | ✅ | pending / approved / inTransit / delivered / rejected / cancelled |
| 9 | priority | String | ✅ | economy / standard / express / urgent |
| 10 | origin | String | ✅ | Starting location |
| 11 | destination | String | ✅ | Ending location |
| 12 | description | String | ✅ | Shipment details |
| 13 | weight | Number | ✅ | Kilograms |
| 14 | length | Number | ✅ | Centimeters |
| 15 | width | Number | ✅ | Centimeters |
| 16 | height | Number | ✅ | Centimeters |
| 17 | estimatedCost | Number | ✅ | USD |
| 18 | actualCost | Number | ✅ | USD (0 until delivered) |
| 19 | affiliateCommission | Number | ✅ | USD (0 if no affiliate) |
| 20 | requiresInsurance | Boolean | ✅ | true / false |
| 21 | requiresCustomsClearance | Boolean | ✅ | true / false |
| 22 | trackingNumber | String | ❌ | Auto-generated format: SHP-YYYYMMDD-XXXXX |
| 23 | createdAt | String/Timestamp | ✅ | Date created |
| 24 | updatedAt | String/Timestamp | ✅ | Last modified |

---

## After Manual Creation

### Test with Mobile App

1. Run mobile app:
   ```
   flutter run
   ```

2. Create account

3. Go to **Shipping** tab

4. Submit a shipping request

5. Check Firebase Console → **shippingRequests** should have new document

### Test Admin Dashboard

1. Run admin:
   ```
   cd admin/admin
   flutter run -d chrome
   ```

2. Go to **Shipping** section

3. Should display your submitted requests in real-time

---

## Troubleshooting

### "Collection not appearing"
- Refresh Firebase Console (F5)
- Check you're in correct project (shopsnports)
- Check Firestore tab is selected

### "Can't add new shipping requests from app"
- Verify **createdAt** and **updatedAt** are Timestamp type (not String)
- Check security rules allow write access

### "Fields not in dropdown"
- Custom field names are allowed - type them manually
- Don't worry about exact capitalization matching

---

## That's It!

You now have the `shippingRequests` collection ready for:
- ✅ Mobile app submissions
- ✅ Admin dashboard viewing
- ✅ Real-time syncing
- ✅ Live tracking

No scripts needed!

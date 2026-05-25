# Manual Document Setup in Firestore

## Option 1: Use Firebase Console (Easiest for Testing)

1. **Open Firestore Console:**
   - https://console.firebase.google.com
   - Select project: shopsnports
   - Go to Firestore Database

2. **Find Shipping Request:**
   - Collection: `shippingRequests`
   - Document ID: `TWCblOXDO0hMdRxAyB02` (Ahmed Hassan)

3. **Add Documents Field:**
   ```
   Field: documents
   Type: array
   ```

4. **Add Document Object (as array item):**
   Click + to add array item, select "map" type, then add these fields:
   
   ```
   id: "doc_001" (string)
   name: "invoice.pdf" (string)
   url: "https://www.africau.edu/images/default/sample.pdf" (string)
   storagePath: "shipping_requests/documents/invoice.pdf" (string)
   type: "invoice" (string)
   status: "verified" (string)
   sizeInBytes: 13264 (number)
   mimeType: "application/pdf" (string)
   uploadedAt: (click "Set to current time") (timestamp)
   uploadedBy: "admin_001" (string)
   ```

5. **Add More Documents:**
   Click + again to add another map with different details:
   - Change `id` to "doc_002"
   - Change `name` to "packing_list.pdf"
   - Change `type` to "packingList"
   - etc.

## Option 2: Upload to Firebase Storage (Production Method)

1. **Go to Firebase Console > Storage**
2. Create folder: `shipping_requests/documents/`
3. Upload your PDF file
4. Click the file → Get download URL
5. Use that URL in the document object above

## Option 3: Use Asset PDF (Quick Test)

If you have a PDF file you want to use:

1. **Add to assets folder:**
   ```
   assets/documents/sample.pdf
   ```

2. **Update pubspec.yaml:**
   ```yaml
   flutter:
     assets:
       - assets/documents/
   ```

3. **In Firestore, use asset path as URL:**
   ```
   url: "assets/documents/sample.pdf"
   ```

4. **BUT NOTE:** Asset URLs won't work for download/email features. They're only for display within the app.

## Recommended Testing Approach

**Use these public PDF URLs** (they work and support download):

1. **Sample PDF 1:**
   ```
   https://www.africau.edu/images/default/sample.pdf
   ```

2. **Sample PDF 2:**
   ```
   https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf
   ```

3. **Sample Image:**
   ```
   https://via.placeholder.com/800x1000/4A90E2/ffffff?text=Sample+Document
   ```

## Troubleshooting

### Documents Not Showing
1. Check Firestore Console - verify `documents` field exists
2. Check it's an **array** type, not string
3. Check each array item is a **map** (object), not string
4. Hot reload dashboard after adding

### Filter Errors
1. Wait for Firestore indexes to build (1-3 minutes)
2. Check: https://console.firebase.google.com/project/shopsnports/firestore/indexes
3. Status should be "Enabled" (not "Building")

### Download Not Working
1. Verify `url` field has a valid HTTP/HTTPS URL
2. Test the URL in browser first
3. Check browser console for errors

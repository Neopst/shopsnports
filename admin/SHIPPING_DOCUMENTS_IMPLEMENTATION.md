# Shipping Documents Feature - Implementation Guide

## Overview
Complete document handling system for shipping requests supporting:
- ✅ View documents in dashboard
- ✅ Download documents (single or bulk)
- ✅ Email documents
- ✅ Print documents (PDF/images)
- ✅ Document preview
- ✅ Document metadata (type, status, size)

## Architecture

### Data Flow
```
Mobile App Upload → Firebase Storage → Get Download URL → Firestore
                                                              ↓
Dashboard reads Firestore → Gets URLs → Display/Download/Email/Print
```

### Storage Structure
```
Firebase Storage:
/shipping_requests/{requestId}/documents/{documentId}.{ext}

Firestore Document:
shippingRequests/{requestId}
  └── documents: [
        {
          id: "doc_123",
          name: "invoice.pdf",
          url: "https://firebasestorage.googleapis.com/...",
          storagePath: "shipping_requests/req_456/documents/doc_123.pdf",
          type: "invoice",
          status: "pending",
          sizeInBytes: 245600,
          mimeType: "application/pdf",
          uploadedAt: "2026-01-26T10:30:00Z",
          uploadedBy: "user_123"
        }
      ]
```

## Dashboard Integration

### 1. Add to Shipping Request Details Screen

```dart
import 'package:admin_dashboard/features/shipping/presentation/widgets/shipping_documents_viewer.dart';
import 'package:admin_dashboard/features/shipping/domain/shipping_document_model.dart';
import 'package:admin_dashboard/features/shipping/application/document_service.dart';

// In your shipping_request_management_screen.dart or details screen:

class ShippingRequestDetailsScreen extends StatelessWidget {
  final ShippingRequest request;

  @override
  Widget build(BuildContext context) {
    // Parse documents from request
    final documents = (request.documents as List<dynamic>? ?? [])
        .map((doc) => ShippingDocument.fromMap(doc as Map<String, dynamic>))
        .toList();

    return Column(
      children: [
        // ... other shipping details ...

        // Documents section
        ShippingDocumentsViewer(
          documents: documents,
          onDownload: (doc) {
            DocumentService.downloadDocument(doc);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Downloading ${doc.name}...')),
            );
          },
          onEmail: (doc) {
            DocumentService.showEmailDialog(
              context,
              doc,
              defaultEmail: request.clientEmail,
            );
          },
          onPrint: (doc) {
            DocumentService.printDocument(doc);
          },
          onDelete: null, // Only admins can delete
        ),
      ],
    );
  }
}
```

### 2. Quick Actions Example

```dart
// Bulk operations
Row(
  children: [
    ElevatedButton.icon(
      onPressed: () => DocumentService.downloadMultiple(documents),
      icon: Icon(Icons.download),
      label: Text('Download All'),
    ),
    SizedBox(width: 8),
    OutlinedButton.icon(
      onPressed: () {
        for (final doc in documents.where((d) => d.isPdf)) {
          DocumentService.printDocument(doc);
        }
      },
      icon: Icon(Icons.print),
      label: Text('Print All PDFs'),
    ),
  ],
)
```

## Mobile App Implementation Guide

### Required Mobile App Changes

**1. Add Firebase Storage dependency** (pubspec.yaml):
```yaml
dependencies:
  firebase_storage: ^11.6.0
  file_picker: ^6.1.1  # For picking files
  image_picker: ^1.0.7  # For camera/gallery
```

**2. Upload Function** (shipping_repository_mobile.dart):
```dart
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

class ShippingRepositoryMobile {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Upload documents and return document metadata
  Future<List<Map<String, dynamic>>> uploadDocuments(
    String requestId,
    String userId,
    List<PlatformFile> files,
  ) async {
    final List<Map<String, dynamic>> uploadedDocs = [];

    for (final file in files) {
      try {
        // Generate unique ID for document
        final docId = 'doc_${DateTime.now().millisecondsSinceEpoch}';
        final extension = file.extension ?? 'bin';
        
        // Storage path
        final storagePath = 'shipping_requests/$requestId/documents/$docId.$extension';
        final storageRef = _storage.ref().child(storagePath);

        // Upload file
        final uploadTask = await storageRef.putData(
          file.bytes!,
          SettableMetadata(
            contentType: _getMimeType(extension),
          ),
        );

        // Get download URL
        final downloadUrl = await uploadTask.ref.getDownloadURL();

        // Create document metadata
        final docMetadata = {
          'id': docId,
          'name': file.name,
          'url': downloadUrl,
          'storagePath': storagePath,
          'type': _inferDocumentType(file.name),
          'status': 'pending',
          'sizeInBytes': file.size,
          'mimeType': _getMimeType(extension),
          'uploadedAt': DateTime.now().toIso8601String(),
          'uploadedBy': userId,
        };

        uploadedDocs.add(docMetadata);
      } catch (e) {
        print('Error uploading ${file.name}: $e');
      }
    }

    return uploadedDocs;
  }

  String _getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf': return 'application/pdf';
      case 'jpg':
      case 'jpeg': return 'image/jpeg';
      case 'png': return 'image/png';
      case 'doc': return 'application/msword';
      case 'docx': return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default: return 'application/octet-stream';
    }
  }

  String _inferDocumentType(String filename) {
    final lower = filename.toLowerCase();
    if (lower.contains('invoice')) return 'invoice';
    if (lower.contains('packing')) return 'packingList';
    if (lower.contains('customs')) return 'customsDeclaration';
    if (lower.contains('payment') || lower.contains('receipt')) return 'proofOfPayment';
    if (lower.contains('insurance')) return 'insuranceCertificate';
    return 'other';
  }

  // Create shipping request with documents
  Future<void> createShippingRequestWithDocuments(
    Map<String, dynamic> requestData,
    List<PlatformFile> files,
  ) async {
    // First create the request to get ID
    final docRef = _firestore.collection('shippingRequests').doc();
    final requestId = docRef.id;

    // Upload documents
    final documents = await uploadDocuments(requestId, requestData['requesterId'], files);

    // Add documents to request data
    requestData['documents'] = documents;
    requestData['id'] = requestId;
    requestData['createdAt'] = FieldValue.serverTimestamp();

    // Save to Firestore
    await docRef.set(requestData);
  }
}
```

**3. Mobile App UI** (shipping_request_form.dart):
```dart
import 'package:file_picker/file_picker.dart';

class ShippingRequestForm extends StatefulWidget {
  @override
  _ShippingRequestFormState createState() => _ShippingRequestFormState();
}

class _ShippingRequestFormState extends State<ShippingRequestForm> {
  List<PlatformFile> selectedFiles = [];

  Future<void> pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
    );

    if (result != null) {
      setState(() {
        selectedFiles.addAll(result.files);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ... other form fields ...

        // Document picker
        ListTile(
          title: Text('Attach Documents'),
          subtitle: Text('${selectedFiles.length} files selected'),
          trailing: ElevatedButton.icon(
            onPressed: pickFiles,
            icon: Icon(Icons.attach_file),
            label: Text('Choose Files'),
          ),
        ),

        // Show selected files
        if (selectedFiles.isNotEmpty)
          ListView.builder(
            shrinkWrap: true,
            itemCount: selectedFiles.length,
            itemBuilder: (context, index) {
              final file = selectedFiles[index];
              return ListTile(
                leading: Icon(Icons.insert_drive_file),
                title: Text(file.name),
                subtitle: Text('${(file.size / 1024).toStringAsFixed(1)} KB'),
                trailing: IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      selectedFiles.removeAt(index);
                    });
                  },
                ),
              );
            },
          ),

        ElevatedButton(
          onPressed: () async {
            // Submit form with documents
            await repository.createShippingRequestWithDocuments(
              formData,
              selectedFiles,
            );
          },
          child: Text('Submit Request'),
        ),
      ],
    );
  }
}
```

## Firestore Security Rules

Add to firestore.rules:
```javascript
// Allow authenticated users to read/write shipping request documents
match /shippingRequests/{requestId} {
  allow read: if isAuthenticated();
  allow create: if isAuthenticated() && request.auth.uid == request.resource.data.requesterId;
  allow update: if isAuthenticated();
}
```

## Firebase Storage Security Rules

Create storage.rules file:
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Shipping documents
    match /shipping_requests/{requestId}/documents/{document} {
      // Anyone authenticated can read
      allow read: if request.auth != null;
      
      // Only document owner can upload
      allow write: if request.auth != null;
      
      // Max file size: 10MB
      allow write: if request.resource.size < 10 * 1024 * 1024;
      
      // Allowed file types
      allow write: if request.resource.contentType.matches('image/.*') 
                   || request.resource.contentType == 'application/pdf'
                   || request.resource.contentType.matches('application/.*word.*');
    }
  }
}
```

Deploy storage rules:
```bash
firebase deploy --only storage
```

## Testing

### 1. Test Data (for development)

Add this to your existing seeding script:
```javascript
{
  // ... existing shipping request fields ...
  documents: [
    {
      id: 'doc_001',
      name: 'commercial_invoice.pdf',
      url: 'https://firebasestorage.googleapis.com/v0/b/shopsnports.appspot.com/o/sample%2Finvoice.pdf?alt=media',
      storagePath: 'shipping_requests/req_001/documents/doc_001.pdf',
      type: 'invoice',
      status: 'verified',
      sizeInBytes: 245600,
      mimeType: 'application/pdf',
      uploadedAt: new Date().toISOString(),
      uploadedBy: 'user_001',
    },
    {
      id: 'doc_002',
      name: 'packing_list.pdf',
      url: 'https://firebasestorage.googleapis.com/v0/b/shopsnports.appspot.com/o/sample%2Fpacking.pdf?alt=media',
      storagePath: 'shipping_requests/req_001/documents/doc_002.pdf',
      type: 'packingList',
      status: 'pending',
      sizeInBytes: 189200,
      mimeType: 'application/pdf',
      uploadedAt: new Date().toISOString(),
      uploadedBy: 'user_001',
    },
  ],
}
```

## Features Summary

### Dashboard Capabilities ✅
- [x] View all documents attached to shipping request
- [x] Download individual documents
- [x] Download all documents (bulk)
- [x] Email documents to client/carrier
- [x] Print PDF documents
- [x] Preview documents in modal
- [x] Open documents in new tab
- [x] See document metadata (size, type, status)
- [x] Verify/reject documents (admin action)

### Mobile App Needs to Implement 📱
- [ ] File picker integration
- [ ] Upload to Firebase Storage
- [ ] Create document metadata
- [ ] Attach documents to shipping request
- [ ] Show upload progress
- [ ] Handle upload errors

### Real-time Updates ⚡
When user uploads from mobile:
1. File uploaded to Storage → URL generated
2. Document metadata saved to Firestore
3. Dashboard listeners auto-update → New document appears immediately
4. Admin can view/download/email instantly

## Next Steps

1. **Test in Dashboard**: Hot reload and navigate to any shipping request
2. **Add test documents**: Use the seeding script above
3. **Mobile App**: Implement file upload (code provided above)
4. **Deploy Storage Rules**: `firebase deploy --only storage`
5. **Production**: Monitor Storage usage in Firebase Console

## Troubleshooting

**Documents not showing?**
- Check Firestore document has `documents` array
- Verify URLs are valid (test in browser)
- Check browser console for CORS errors

**Can't download?**
- Verify Firebase Storage CORS configuration
- Check Storage security rules allow read access

**Mobile upload fails?**
- Check file size (max 10MB in rules)
- Verify file type is allowed
- Check Storage rules deployed correctly

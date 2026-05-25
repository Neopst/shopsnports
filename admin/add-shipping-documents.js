// Script to add sample documents to shipping requests in Firestore
const admin = require('firebase-admin');
const fs = require('fs');

// Initialize Firebase Admin
const serviceAccount = JSON.parse(
  fs.readFileSync('./shopsnports-firebase-adminsdk-fbsvc-b0880f6249.json', 'utf8')
);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Sample documents - using fast, reliable CDN URLs
const sampleDocuments = {
  pdf1: {
    id: 'doc_' + Date.now() + '_1',
    name: 'invoice.pdf',
    url: 'https://pdfobject.com/pdf/sample.pdf',
    storagePath: 'shipping_requests/sample/documents/invoice.pdf',
    type: 'invoice',
    status: 'verified',
    sizeInBytes: 13264,
    mimeType: 'application/pdf',
    uploadedAt: new Date().toISOString(),
    uploadedBy: 'admin_001'
  },
  pdf2: {
    id: 'doc_' + Date.now() + '_2',
    name: 'packing_list.pdf',
    url: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
    storagePath: 'shipping_requests/sample/documents/packing.pdf',
    type: 'packingList',
    status: 'pending',
    sizeInBytes: 184320,
    mimeType: 'application/pdf',
    uploadedAt: new Date().toISOString(),
    uploadedBy: 'admin_001'
  },
  image1: {
    id: 'doc_' + Date.now() + '_3',
    name: 'customs_declaration.jpg',
    url: 'https://picsum.photos/800/1000',
    storagePath: 'shipping_requests/sample/documents/customs.jpg',
    type: 'customsDeclaration',
    status: 'verified',
    sizeInBytes: 245600,
    mimeType: 'image/jpeg',
    uploadedAt: new Date().toISOString(),
    uploadedBy: 'admin_001'
  },
  image2: {
    id: 'doc_' + Date.now() + '_4',
    name: 'proof_of_payment.png',
    url: 'https://picsum.photos/600/800',
    storagePath: 'shipping_requests/sample/documents/payment.png',
    type: 'proofOfPayment',
    status: 'verified',
    sizeInBytes: 156800,
    mimeType: 'image/png',
    uploadedAt: new Date().toISOString(),
    uploadedBy: 'admin_001'
  },
  pdf3: {
    id: 'doc_' + Date.now() + '_5',
    name: 'insurance_certificate.pdf',
    url: 'https://www.clickdimensions.com/links/TestPDFfile.pdf',
    storagePath: 'shipping_requests/sample/documents/insurance.pdf',
    type: 'insuranceCertificate',
    status: 'pending',
    sizeInBytes: 98400,
    mimeType: 'application/pdf',
    uploadedAt: new Date().toISOString(),
    uploadedBy: 'admin_001'
  }
};

(async () => {
  try {
    console.log('🔍 Finding shipping requests...\n');
    
    // Get first 5 shipping requests ordered by creation date
    const snapshot = await db.collection('shippingRequests')
      .orderBy('createdAt', 'desc')
      .limit(5)
      .get();

    if (snapshot.empty) {
      console.log('❌ No shipping requests found');
      process.exit(1);
    }

    console.log(`✅ Found ${snapshot.size} shipping requests\n`);

    let count = 0;
    for (const doc of snapshot.docs) {
      const data = doc.data();
      
      // Create different document combinations for each request
      let documents = [];
      if (count === 0) {
        // First request: 2 PDFs
        documents = [sampleDocuments.pdf1, sampleDocuments.pdf2];
      } else if (count === 1) {
        // Second request: 1 PDF + 1 image
        documents = [sampleDocuments.pdf1, sampleDocuments.image1];
      } else if (count === 2) {
        // Third request: 2 images
        documents = [sampleDocuments.image1, sampleDocuments.image2];
      } else if (count === 3) {
        // Fourth request: All 5 documents
        documents = Object.values(sampleDocuments);
      } else {
        // Fifth request: 1 PDF + 2 images
        documents = [sampleDocuments.pdf3, sampleDocuments.image1, sampleDocuments.image2];
      }

      await doc.ref.update({ 
        documents: documents 
      });

      count++;
      const pdfCount = documents.filter(d => d.mimeType.includes('pdf')).length;
      const imageCount = documents.filter(d => d.mimeType.includes('image')).length;
      
      console.log(`✅ ${count}/5: ${data.clientName || 'Unknown'}`);
      console.log(`   📎 Added ${documents.length} documents (${pdfCount} PDFs, ${imageCount} images)`);
      console.log(`   🆔 Request ID: ${doc.id}\n`);
    }

    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('✅ SUCCESS! Added documents to 5 shipping requests');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    console.log('🔄 Hot reload your dashboard to see the documents');
    console.log('📋 Click on any of the 5 requests above to view documents\n');
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error.message);
    console.error(error.stack);
    process.exit(1);
  }
})();

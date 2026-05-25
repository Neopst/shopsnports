const admin = require('firebase-admin');
const serviceAccount = require('./shopsnports-firebase-adminsdk-fbsvc-b0880f6249.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function analyzeInvoicesModule() {
  console.log('📋 INVOICES MODULE ANALYSIS');
  console.log('='.repeat(70));
  
  try {
    // Check invoices collection
    const invoicesSnapshot = await db.collection('invoices').get();
    console.log(`\n💼 INVOICES COLLECTION: ${invoicesSnapshot.size} documents\n`);
    
    if (invoicesSnapshot.size === 0) {
      console.log('❌ No invoices found in Firestore');
      console.log('   → Invoices module likely using mock/seed data\n');
    } else {
      const invoicesByStatus = {};
      let totalRevenue = 0;
      let pendingAmount = 0;
      
      invoicesSnapshot.forEach(doc => {
        const data = doc.data();
        const status = data.status || 'unknown';
        invoicesByStatus[status] = (invoicesByStatus[status] || 0) + 1;
        
        if (status === 'paid') totalRevenue += (data.total || 0);
        if (status === 'pending') pendingAmount += (data.total || 0);
        
        if (invoicesByStatus[status] === 1) {
          console.log(`Sample ${status} invoice:`);
          console.log(`  Number: ${data.invoiceNumber}`);
          console.log(`  Customer: ${data.customerName} (${data.customerId})`);
          console.log(`  Total: $${data.total || 0}`);
          console.log(`  Line Items: ${data.lineItems?.length || 0}`);
          console.log();
        }
      });
      
      console.log('By Status:');
      Object.entries(invoicesByStatus).forEach(([status, count]) => {
        console.log(`  ${status}: ${count}`);
      });
      
      console.log(`\nTotal Revenue (paid): $${totalRevenue.toFixed(2)}`);
      console.log(`Pending Amount: $${pendingAmount.toFixed(2)}`);
    }
    
    // Check customers collection (invoices should link to customers)
    const customersSnapshot = await db.collection('customers').get();
    console.log(`\n👥 CUSTOMERS COLLECTION: ${customersSnapshot.size} documents`);
    
    // Check shipping requests (invoices might link to shipments)
    const shippingSnapshot = await db.collection('shipping_requests').get();
    console.log(`📦 SHIPPING REQUESTS: ${shippingSnapshot.size} documents`);
    
    console.log('\n' + '='.repeat(70));
    console.log('🔍 EXPECTED INVOICE WORKFLOW:\n');
    console.log('1. Customer places order / requests shipping');
    console.log('2. Admin generates invoice for the service');
    console.log('3. Invoice created with:');
    console.log('   - Customer details (from customers collection)');
    console.log('   - Line items (shipping fees, insurance, etc.)');
    console.log('   - Tax calculation');
    console.log('   - Due date');
    console.log('4. Customer pays invoice');
    console.log('5. Admin marks invoice as paid');
    console.log('6. Invoice archived for records\n');
    
    console.log('='.repeat(70));
    console.log('📊 RELATIONSHIP MAPPING:\n');
    console.log('Invoice → Customer (via customerId)');
    console.log('Invoice → Shipping Request (optional, via shipmentId)');
    console.log('Invoice → Line Items (embedded in invoice doc)');
    console.log('\n' + '='.repeat(70));
    
    process.exit(0);
    
  } catch (error) {
    console.error('\n❌ Error:', error.message);
    console.error(error);
    process.exit(1);
  }
}

analyzeInvoicesModule();

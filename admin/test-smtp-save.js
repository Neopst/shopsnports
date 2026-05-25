const admin = require('firebase-admin');
const path = require('path');

console.log('Starting SMTP credentials save...');

try {
  // Load service account
  const serviceAccountPath = path.join(__dirname, 'shopsnports-firebase-adminsdk-fbsvc-b0880f6249.json');
  console.log('Loading credentials from:', serviceAccountPath);
  
  const serviceAccount = require(serviceAccountPath);
  console.log('✅ Credentials loaded for project:', serviceAccount.project_id);

  // Initialize Firebase
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
  console.log('✅ Firebase initialized');

  const db = admin.firestore();

  // Save SMTP config
  const smtpConfig = {
    smtpHost: 'mail.shopsnports.com',
    smtpPort: 465,
    smtpSecure: true,
    smtpNoreplyEmail: 'noreply@shopsnports.com',
    smtpNoreplyPassword: 'ljqJ[rwdeDa(GbWS',
    smtpInvoiceEmail: 'invoices@shopsnports.com',
    smtpInvoicePassword: '6YW?caelWI2]+}A[',
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedBy: 'system-setup'
  };

  // Determine if update or create
  db.collection('settings').doc('api_settings').get()
    .then(doc => {
      if (doc.exists) {
        return db.collection('settings').doc('api_settings').update(smtpConfig);
      } else {
        return db.collection('settings').doc('api_settings').set({
          id: 'api_settings',
          ...smtpConfig,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          createdBy: 'system-setup',
          version: 1
        });
      }
    })
    .then(() => {
      console.log('\n✅ SMTP Configuration Saved Successfully!\n');
      console.log('📧 Configuration:');
      console.log('  Host:', smtpConfig.smtpHost);
      console.log('  Port:', smtpConfig.smtpPort);
      console.log('  Secure (SSL):', smtpConfig.smtpSecure);
      console.log('  System Email:', smtpConfig.smtpNoreplyEmail);
      console.log('  Invoice Email:', smtpConfig.smtpInvoiceEmail);
      console.log('\n🎉 Ready for Cloud Functions deployment!\n');
      admin.app().delete();
      process.exit(0);
    })
    .catch(error => {
      console.error('❌ Error:', error.message);
      admin.app().delete();
      process.exit(1);
    });

} catch (error) {
  console.error('❌ Fatal error:', error.message);
  process.exit(1);
}

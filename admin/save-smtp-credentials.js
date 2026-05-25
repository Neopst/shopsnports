const admin = require('firebase-admin');
const serviceAccount = require('./shopsnports-firebase-adminsdk-fbsvc-b0880f6249.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function saveSMTPCredentials() {
  try {
    console.log('🔐 Saving SMTP credentials to Firestore...\n');

    const smtpConfig = {
      smtpHost: 'mail.shopsnports.com',
      smtpPort: 465,
      smtpSecure: true, // SSL/TLS
      smtpNoreplyEmail: 'noreply@shopsnports.com',
      smtpNoreplyPassword: 'ljqJ[rwdeDa(GbWS', // TODO: Encrypt in production
      smtpInvoiceEmail: 'invoices@shopsnports.com',
      smtpInvoicePassword: '6YW?caelWI2]+}A[', // TODO: Encrypt in production
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedBy: 'system-setup'
    };

    // Check if api_settings document exists
    const settingsRef = db.collection('settings').doc('api_settings');
    const settingsDoc = await settingsRef.get();

    if (settingsDoc.exists) {
      // Update existing document
      await settingsRef.update(smtpConfig);
      console.log('✅ Updated existing api_settings with SMTP configuration');
    } else {
      // Create new document
      await settingsRef.set({
        id: 'api_settings',
        ...smtpConfig,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        createdBy: 'system-setup',
        version: 1,
        webhookSecrets: {}
      });
      console.log('✅ Created new api_settings with SMTP configuration');
    }

    // Display saved configuration
    console.log('\n📧 SMTP Configuration Saved:');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log(`Host: ${smtpConfig.smtpHost}`);
    console.log(`Port: ${smtpConfig.smtpPort}`);
    console.log(`Secure: ${smtpConfig.smtpSecure}`);
    console.log(`\nSystem Email: ${smtpConfig.smtpNoreplyEmail}`);
    console.log(`Invoice Email: ${smtpConfig.smtpInvoiceEmail}`);
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    console.log('🎉 SMTP credentials saved successfully!');
    console.log('\n⚠️  SECURITY NOTE:');
    console.log('Passwords are currently stored in plain text.');
    console.log('Consider implementing encryption before production deployment.\n');

    await admin.app().delete();
    process.exit(0);
  } catch (error) {
    console.error('❌ Error saving SMTP credentials:', error.message);
    await admin.app().delete();
    process.exit(1);
  }
}

saveSMTPCredentials().catch(err => {
  console.error('Fatal error:', err);
  process.exit(1);
});

/**
 * Local email service test
 * Tests the email sending functionality without deployment
 */
const nodemailer = require('nodemailer');

async function testEmailSending() {
  console.log('🧪 Testing Email Service Locally...\n');

  try {
    // SMTP Configuration
    const smtpConfig = {
      host: 'mail.shopsnports.com',
      port: 465,
      secure: true,
      user: 'invoices@shopsnports.com',
      password: '6YW?caelWI2]+}A[',
    };

    console.log('Creating transporter with SMTP config:');
    console.log(`  Host: ${smtpConfig.host}`);
    console.log(`  Port: ${smtpConfig.port}`);
    console.log(`  Secure: ${smtpConfig.secure}`);
    console.log(`  User: ${smtpConfig.user}\n`);

    // Create transporter
    const transporter = nodemailer.createTransport(smtpConfig);

    // Verify connection
    console.log('Verifying SMTP connection...');
    await transporter.verify();
    console.log('✅ SMTP Connection verified!\n');

    // Test email data
    const testEmail = {
      from: '"ShopsNSports Billing" <invoices@shopsnports.com>',
      to: 'dipoenvile1@gmail.com', // Replace with test email
      subject: 'Test Invoice - ShopsNSports',
      text: 'This is a test invoice email from ShopsNSports.',
      html: `
        <div style="font-family: Arial, sans-serif; padding: 20px;">
          <h1>Test Invoice Email</h1>
          <p>Dear Customer,</p>
          <p>This is a test email to verify that the email system is working correctly.</p>
          <p><strong>Invoice Number:</strong> INV-TEST-001</p>
          <p><strong>Amount:</strong> ₦1,000.00</p>
          <p><strong>Status:</strong> This is a test email</p>
          <p>Best regards,<br>ShopsNSports Billing Team</p>
        </div>
      `
    };

    // Send test email
    console.log('Sending test email to dipoenvile1@gmail.com...');
    const info = await transporter.sendMail(testEmail);
    console.log('\n✅ Email sent successfully!');
    console.log('  Message ID:', info.messageId);
    console.log('  Response:', info.response);

    console.log('\n🎉 EMAIL SERVICE TEST PASSED!\n');
    console.log('Cloud Functions are ready to deploy.');
    console.log('Email sending via SMTP is working correctly.\n');

    process.exit(0);

  } catch (error) {
    console.error('\n❌ Email Test Failed:');
    console.error('  Error:', error.message);
    
    if (error.code === 'EAUTH') {
      console.error('\n  ⚠️  Authentication failed - check email credentials');
    } else if (error.code === 'ECONNECTION') {
      console.error('\n  ⚠️  Connection failed - check SMTP server address and port');
    }
    
    console.error('\n📧 SMTP Server: mail.shopsnports.com:465');
    console.error('📧 Invoice Email: invoices@shopsnports.com');
    
    process.exit(1);
  }
}

testEmailSending();

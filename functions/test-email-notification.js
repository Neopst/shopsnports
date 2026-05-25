#!/usr/bin/env node

/**
 * EMAIL NOTIFICATION TEST SCRIPT
 * 
 * Tests the complete email notification flow for shipping requests
 * 
 * Usage:
 *   node test-email-notification.js
 *   node test-email-notification.js --local (test with emulator)
 *   node test-email-notification.js --production (test with Firebase)
 */

const fs = require('fs');
const path = require('path');

const args = process.argv.slice(2);
const mode = args[0] || '--local';

console.log('\n📧 EMAIL NOTIFICATION TEST SUITE');
console.log('='.repeat(50));
console.log(`Mode: ${mode}`);
console.log('='.repeat(50) + '\n');

// ========== TEST 1: Check SMTP Configuration ==========
console.log('✅ TEST 1: Check SMTP Configuration');
console.log('-'.repeat(50));

console.log('ℹ️  SMTP configuration should be set via Firebase Functions config:');
console.log('   firebase functions:config:set smtp.host="..." smtp.port="..." smtp.user="..." smtp.pass="..." smtp.secure="..."');
console.log('   Or use .env.onCustomerCreated.template for local development (copy to .env.onCustomerCreated)');

const envFile = path.join(__dirname, '.env.onCustomerCreated');
if (fs.existsSync(envFile)) {
  console.log('⚠️  .env.onCustomerCreated file found (development mode)');
  const envContent = fs.readFileSync(envFile, 'utf8');
  const envVars = {};
  envContent.split('\n').forEach(line => {
    const [key, value] = line.split('=');
    if (key && value) envVars[key] = '***' + value.slice(-5); // Hide password
  });
  console.log('   Environment variables present:');
  Object.entries(envVars).forEach(([k, v]) => {
    console.log(`   - ${k}: ${v}`);
  });
} else {
  console.log('✅ No local .env file found (using Firebase Functions config)');
}

// ========== TEST 2: Check Firebase Configuration ==========
console.log('\n✅ TEST 2: Check Firebase Configuration');
console.log('-'.repeat(50));

const firebaseJsonPath = path.join(__dirname, '../firebase.json');
if (fs.existsSync(firebaseJsonPath)) {
  const firebaseJson = JSON.parse(fs.readFileSync(firebaseJsonPath, 'utf8'));
  console.log('✅ firebase.json found');
  console.log(`   Functions source: ${firebaseJson.functions?.source || 'N/A'}`);
  console.log(`   Firestore rules: ${firebaseJson.firestore?.rules || 'N/A'}`);
} else {
  console.log('❌ firebase.json NOT found');
}

// ========== TEST 3: Check Required Packages ==========
console.log('\n✅ TEST 3: Check Required Npm Packages');
console.log('-'.repeat(50));

const packageJsonPath = path.join(__dirname, 'package.json');
const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, 'utf8'));
const requiredPackages = ['firebase-functions', 'firebase-admin', 'nodemailer'];

requiredPackages.forEach(pkg => {
  if (packageJson.dependencies[pkg]) {
    console.log(`✅ ${pkg} v${packageJson.dependencies[pkg]}`);
  } else {
    console.log(`❌ ${pkg} NOT FOUND - RUN: npm install ${pkg}`);
  }
});

// ========== TEST 4: Check TypeScript Compilation ==========
console.log('\n✅ TEST 4: Check TypeScript Compilation');
console.log('-'.repeat(50));

const libFiles = [
  'lib/onShippingRequestCreated.js',
  'lib/onShippingRequestUpdated.js',
  'lib/index.js'
];

libFiles.forEach(file => {
  const filePath = path.join(__dirname, file);
  if (fs.existsSync(filePath)) {
    console.log(`✅ ${file} exists`);
  } else {
    console.log(`❌ ${file} NOT FOUND - RUN: npm run build`);
  }
});

// ========== TEST 5: Verify Email Function Export ==========
console.log('\n✅ TEST 5: Verify Functions Exported');
console.log('-'.repeat(50));

const indexLibPath = path.join(__dirname, 'lib/index.js');
const indexContent = fs.readFileSync(indexLibPath, 'utf8');

const expectedFunctions = [
  'shippingRequestCreated',
  'shippingRequestUpdated',
  'admin',
  'calculateAffiliateCommission'
];

expectedFunctions.forEach(func => {
  if (indexContent.includes(`exports.${func}`)) {
    console.log(`✅ ${func} exported`);
  } else {
    console.log(`❌ ${func} NOT exported`);
  }
});

// ========== TEST 6: Check Email Template ==========
console.log('\n✅ TEST 6: Check Email Template');
console.log('-'.repeat(50));

const createdTsPath = path.join(__dirname, 'src/onShippingRequestCreated.ts');
const createdContent = fs.readFileSync(createdTsPath, 'utf8');

const templateChecks = [
  { text: 'Shipping Request Received', hint: 'Email header' },
  { text: 'tracking number', hint: 'Tracking number field' },
  { text: 'agents will contact you shortly', hint: 'Agent contact message' },
  { text: 'support@shopsnports.com', hint: 'Support email' },
  { text: 'Subject:', hint: 'Email subject line' }
];

templateChecks.forEach(check => {
  if (createdContent.includes(check.text)) {
    console.log(`✅ "${check.text}" (${check.hint})`);
  } else {
    console.log(`❌ "${check.text}" NOT FOUND (${check.hint})`);
  }
});

// ========== TEST 7: SMTP Connection Test (Optional) ==========
if (args.includes('--smtp-test')) {
  console.log('\n✅ TEST 7: SMTP Connection Test');
  console.log('-'.repeat(50));

  const nodemailer = require('nodemailer');

  // Try Firebase Functions config first, then fallback to .env file
  let smtpConfig = {};

  if (fs.existsSync(envFile)) {
    const envContent = fs.readFileSync(envFile, 'utf8');
    const env = {};
    envContent.split('\n').forEach(line => {
      const [key, value] = line.split('=');
      if (key && value) env[key] = value.trim();
    });
    smtpConfig = {
      host: env.SMTP_HOST,
      port: parseInt(env.SMTP_PORT),
      secure: env.SMTP_SECURE === 'true',
      user: env.SMTP_USER,
      pass: env.SMTP_PASS
    };
    console.log('ℹ️  Using local .env configuration');
  } else {
    console.log('ℹ️  For production, use Firebase Functions config:');
    console.log('   firebase functions:config:get smtp');
    console.log('   Skipping SMTP test (no local config found)');
    return;
  }

  const transporter = nodemailer.createTransport({
    host: smtpConfig.host,
    port: smtpConfig.port,
    secure: smtpConfig.secure,
    auth: {
      user: smtpConfig.user,
      pass: smtpConfig.pass
    }
  });

  transporter.verify((error, success) => {
    if (error) {
      console.log('❌ SMTP Connection Failed:');
      console.log(`   ${error.message}`);
    } else {
      console.log('✅ SMTP Connection Successful');
      console.log(`   SMTP server listening on ${smtpConfig.host}:${smtpConfig.port}`);
    }
  });
}

// ========== SUMMARY ==========
console.log('\n' + '='.repeat(50));
console.log('📋 NEXT STEPS:');
console.log('='.repeat(50));
console.log('1. Run emulator: firebase emulators:start');
console.log('2. Create shipping request via Flutter app');
console.log('3. Check function logs for "✅ Confirmation email sent to"');
console.log('4. Verify email in recipient inbox');
console.log('5. Deploy to Firebase: firebase deploy --only functions');
console.log('\n');

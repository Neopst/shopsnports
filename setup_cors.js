#!/usr/bin/env node

/**
 * Script to apply CORS configuration to Firebase Storage bucket
 * Usage: node setup_cors.js
 */

const { Storage } = require('@google-cloud/storage');
const fs = require('fs');
const path = require('path');

async function setupCors() {
  try {
    console.log('🔧 Setting up CORS for Firebase Storage...\n');

    // Initialize Google Cloud Storage with service account
    const serviceAccount = require('./shopsnports-firebase-adminsdk-fbsvc-0ebfd2e668.json');
    
    const storage = new Storage({
      projectId: serviceAccount.project_id,
      keyFilename: path.join(__dirname, 'shopsnports-firebase-adminsdk-fbsvc-0ebfd2e668.json'),
    });

    // support both the explicit Firebase Storage bucket and the
    // default appspot.com bucket just in case builds still target the
    // legacy bucket.  This avoids CORS errors when the client accidentally
    // uses the wrong one.
    const bucketNames = [
      'shopsnports.firebasestorage.app',
      'shopsnports.appspot.com',
    ];

    // Read CORS configuration
    const corsConfigPath = path.join(__dirname, 'cors.json');
    if (!fs.existsSync(corsConfigPath)) {
      throw new Error(`CORS configuration file not found: ${corsConfigPath}`);
    }
    const corsConfig = JSON.parse(fs.readFileSync(corsConfigPath, 'utf8'));

    console.log('📋 CORS Configuration:');
    console.log(JSON.stringify(corsConfig, null, 2));

    for (const bucketName of bucketNames) {
      console.log(`\nApplying CORS to bucket: ${bucketName}`);
      const bucket = storage.bucket(bucketName);
      await bucket.setCorsConfiguration(corsConfig);
      console.log('✅ Applied to ' + bucketName);
    }

    console.log('\n✅ CORS configuration applied successfully to all buckets!');
    console.log('📝 Allowed origins:');
    corsConfig.forEach((config, index) => {
      console.log(`   ${index + 1}. ${config.origin.join(', ')}`);
    });
    console.log('\n✅ You can now upload from localhost during development!');

  } catch (error) {
    console.error('❌ Error setting up CORS:', error.message);
    process.exit(1);
  }
}

setupCors();

#!/usr/bin/env node

/**
 * Initialize shippingRequests collection in Firestore
 * 
 * This script creates the shippingRequests collection with proper document structure
 * Run with: node scripts/init_shipping_requests_collection.js
 */

const admin = require('firebase-admin');
const path = require('path');

// Initialize Firebase Admin SDK
const serviceAccountPath = path.join(__dirname, '../functions/serviceAccountKey.json');

try {
  admin.initializeApp({
    credential: admin.credential.cert(require(serviceAccountPath)),
  });
  console.log('✅ Firebase initialized');
} catch (error) {
  console.error('❌ Error initializing Firebase:', error.message);
  process.exit(1);
}

const db = admin.firestore();

/**
 * Create shippingRequests collection with proper structure
 */
async function initializeCollection() {
  try {
    console.log('\n🚀 Initializing shippingRequests collection...\n');

    const collectionRef = db.collection('shippingRequests');
    
    // Check if collection already exists
    const existingDocs = await collectionRef.limit(1).get();
    if (!existingDocs.empty) {
      console.log('⚠️  Collection already has documents. Skipping initialization.');
      console.log('   Documents in collection:', existingDocs.size);
      await admin.app().delete();
      return;
    }

    // Create a sample document to establish collection structure
    const sampleDoc = {
      // Identifiers
      id: collectionRef.doc().id,
      requesterId: 'sample_user_001',
      affiliateId: null,

      // Client Information
      clientName: 'Sample Client',
      clientEmail: 'sample@example.com',
      clientPhone: '+1-234-567-8900',

      // Shipment Type & Status
      type: 'air', // 'air' | 'sea' | 'land'
      status: 'pending', // 'pending' | 'approved' | 'inTransit' | 'delivered' | 'rejected' | 'cancelled'
      priority: 'standard', // 'economy' | 'standard' | 'express' | 'urgent'

      // Route Details
      origin: 'New York, USA',
      destination: 'Lagos, Nigeria',
      description: 'Sample shipment for testing',

      // Dimensions & Weight
      weight: 100.0, // kg
      length: 80.0, // cm
      width: 60.0, // cm
      height: 50.0, // cm

      // Costs
      estimatedCost: 2500.00, // USD
      actualCost: 0.00, // USD (0 until delivered)

      // Delivery Estimates
      estimatedDelivery: admin.firestore.Timestamp.fromDate(
        new Date(Date.now() + 14 * 24 * 60 * 60 * 1000) // 14 days from now
      ),
      actualDelivery: null,

      // Insurance & Customs
      requiresInsurance: true,
      requiresCustomsClearance: true,

      // Affiliate
      affiliateCommission: 0.00, // USD

      // Tracking
      trackingNumber: null, // Auto-generated on submission: SHP-YYYYMMDD-XXXXX

      // Metadata (server-side timestamps)
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    // Add the sample document
    const docRef = await collectionRef.add(sampleDoc);
    console.log('✅ Sample document created');
    console.log('   Document ID:', docRef.id);
    console.log('   Collection: shippingRequests');

    // Delete the sample document to leave collection empty for real data
    console.log('\n🧹 Cleaning up sample document...');
    await docRef.delete();
    console.log('✅ Sample document deleted');

    console.log('\n📋 Collection Structure Reference:');
    console.log('─────────────────────────────────────────');
    console.log(JSON.stringify(sampleDoc, null, 2)
      .replace(/"createdAt".*\n/, '"createdAt": Timestamp (auto-generated),\n')
      .replace(/"updatedAt".*\n/, '"updatedAt": Timestamp (auto-generated),\n'));

    console.log('\n✅ shippingRequests collection ready!\n');
    console.log('📝 Field Guidelines:');
    console.log('   • id: Auto-generated document ID');
    console.log('   • requesterId: Firebase UID of requester');
    console.log('   • affiliateId: Optional - for affiliate partners');
    console.log('   • type: air | sea | land');
    console.log('   • status: pending | approved | inTransit | delivered | rejected | cancelled');
    console.log('   • priority: economy | standard | express | urgent');
    console.log('   • trackingNumber: Auto-generated format SHP-YYYYMMDD-XXXXX');
    console.log('   • createdAt / updatedAt: Server timestamps\n');

  } catch (error) {
    console.error('❌ Error initializing collection:', error.message);
    process.exit(1);
  } finally {
    await admin.app().delete();
  }
}

// Run initialization
initializeCollection();

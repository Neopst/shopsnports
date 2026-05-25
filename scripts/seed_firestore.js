#!/usr/bin/env node
/**
 * Firestore Collections Seeding Script
 * 
 * Usage:
 * 1. Install Firebase CLI: npm install -g firebase-tools
 * 2. Initialize Firebase: firebase init
 * 3. Run this script: node scripts/seed_firestore.js
 * 
 * Or run directly with:
 * firebase shell < scripts/seed_firestore.js
 */

const admin = require('firebase-admin');
const path = require('path');

// Initialize Firebase Admin SDK
// Make sure you have set GOOGLE_APPLICATION_CREDENTIALS environment variable
// or have credentials file saved
if (!admin.apps.length) {
  admin.initializeApp({
    projectId: 'shopsnports',
  });
}

const db = admin.firestore();

// Seed data collections
async function seedFirestore() {
  try {
    console.log('🌱 Starting Firestore seeding...\n');

    // ============================================
    // 1. Seed BANNERS collection
    // ============================================
    console.log('📦 Seeding banners collection...');
    const bannersCollection = db.collection('banners');

    const banners = [
      {
        id: 'banner_001',
        title: 'Fast & Reliable Shipping',
        subtitle: 'Shipping your cargo with care',
        imageUrl: 'https://via.placeholder.com/800x300?text=Fast+Shipping',
        position: 'HOME_CAROUSEL',
        displayOrder: 1,
        isActive: true,
        startDate: admin.firestore.Timestamp.now(),
        endDate: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000),
        impressions: 0,
        clicks: 0,
        createdAt: admin.firestore.Timestamp.now(),
        updatedAt: admin.firestore.Timestamp.now(),
        createdBy: 'system',
        updatedBy: 'system',
      },
      {
        id: 'banner_002',
        title: 'Competitive Rates Guaranteed',
        subtitle: 'Best prices in the market',
        imageUrl: 'https://via.placeholder.com/800x300?text=Competitive+Rates',
        position: 'HOME_CAROUSEL',
        displayOrder: 2,
        isActive: true,
        startDate: admin.firestore.Timestamp.now(),
        endDate: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000),
        impressions: 0,
        clicks: 0,
        createdAt: admin.firestore.Timestamp.now(),
        updatedAt: admin.firestore.Timestamp.now(),
        createdBy: 'system',
        updatedBy: 'system',
      },
      {
        id: 'banner_003',
        title: 'Real-Time Tracking',
        subtitle: 'Know where your cargo is at all times',
        imageUrl: 'https://via.placeholder.com/800x300?text=Real-Time+Tracking',
        position: 'HOME_CAROUSEL',
        displayOrder: 3,
        isActive: true,
        startDate: admin.firestore.Timestamp.now(),
        endDate: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000),
        impressions: 0,
        clicks: 0,
        createdAt: admin.firestore.Timestamp.now(),
        updatedAt: admin.firestore.Timestamp.now(),
        createdBy: 'system',
        updatedBy: 'system',
      },
      {
        id: 'banner_004',
        title: 'Become an Affiliate Agent',
        subtitle: 'Earn commissions with our referral program',
        imageUrl: 'https://via.placeholder.com/800x300?text=Affiliate+Program',
        position: 'HOME_CAROUSEL',
        displayOrder: 4,
        isActive: true,
        startDate: admin.firestore.Timestamp.now(),
        endDate: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000),
        impressions: 0,
        clicks: 0,
        createdAt: admin.firestore.Timestamp.now(),
        updatedAt: admin.firestore.Timestamp.now(),
        createdBy: 'system',
        updatedBy: 'system',
      },
    ];

    for (const banner of banners) {
      await bannersCollection.doc(banner.id).set(banner);
      console.log(`  ✅ Created banner: ${banner.title}`);
    }

    // ============================================
    // 2. Seed NEWS_TICKER collection
    // ============================================
    console.log('\n📰 Seeding news_ticker collection...');
    const newsCollection = db.collection('news_ticker');

    const newsItems = [
      {
        id: 'news_001',
        title: 'Welcome to ShopsNPorts Shipping',
        content:
          'We are excited to launch the cargo and freight shipping platform. ShopsNPorts is your trusted partner for all shipping needs.',
        priority: 10,
        status: 'published',
        imageUrl: 'https://via.placeholder.com/400x300?text=Welcome',
        publishedAt: admin.firestore.Timestamp.now(),
        expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
        createdAt: admin.firestore.Timestamp.now(),
        createdBy: 'admin',
        updatedAt: admin.firestore.Timestamp.now(),
      },
      {
        id: 'news_002',
        title: 'Express Air Shipping Now Available',
        content:
          'Fast track your shipments with our new express air shipping service. Same-day and next-day delivery available to major cities.',
        priority: 9,
        status: 'published',
        imageUrl: 'https://via.placeholder.com/400x300?text=Air+Shipping',
        publishedAt: admin.firestore.Timestamp.now(),
        expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
        createdAt: admin.firestore.Timestamp.now(),
        createdBy: 'admin',
        updatedAt: admin.firestore.Timestamp.now(),
      },
      {
        id: 'news_003',
        title: 'Join Our Affiliate Program',
        content:
          'Become a ShopsNPorts affiliate agent and earn generous commissions. Sign up today and start earning from shipping referrals.',
        priority: 8,
        status: 'published',
        imageUrl: 'https://via.placeholder.com/400x300?text=Affiliate',
        publishedAt: admin.firestore.Timestamp.now(),
        expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
        createdAt: admin.firestore.Timestamp.now(),
        createdBy: 'admin',
        updatedAt: admin.firestore.Timestamp.now(),
      },
      {
        id: 'news_004',
        title: 'New Security Features Released',
        content:
          'We have upgraded our security infrastructure with end-to-end encryption and advanced fraud detection for safer transactions.',
        priority: 7,
        status: 'published',
        imageUrl: 'https://via.placeholder.com/400x300?text=Security',
        publishedAt: admin.firestore.Timestamp.now(),
        expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
        createdAt: admin.firestore.Timestamp.now(),
        createdBy: 'admin',
        updatedAt: admin.firestore.Timestamp.now(),
      },
      {
        id: 'news_005',
        title: 'Customer Support Improvements',
        content:
          'Our customer support team is now available 24/7 via WhatsApp, email, and phone to assist with your shipping needs.',
        priority: 6,
        status: 'published',
        imageUrl: 'https://via.placeholder.com/400x300?text=Support',
        publishedAt: admin.firestore.Timestamp.now(),
        expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
        createdAt: admin.firestore.Timestamp.now(),
        createdBy: 'admin',
        updatedAt: admin.firestore.Timestamp.now(),
      },
    ];

    for (const news of newsItems) {
      await newsCollection.doc(news.id).set(news);
      console.log(`  ✅ Created news: ${news.title}`);
    }

    // ============================================
    // 3. Seed CONTENT_PAGES collection
    // ============================================
    console.log('\n📄 Seeding content_pages collection...');
    const contentCollection = db.collection('content_pages');

    const contentPages = [
      {
        id: 'terms_of_service',
        slug: 'terms-of-service',
        title: 'Terms of Service',
        description: 'ShopsNPorts shipping platform terms and conditions',
        content: `
<h1>Terms of Service</h1>
<p>Welcome to ShopsNPorts Shipping Platform. These terms and conditions govern your use of our services.</p>
<h2>1. Acceptance of Terms</h2>
<p>By using ShopsNPorts, you agree to comply with our terms and conditions.</p>
<h2>2. Services</h2>
<p>ShopsNPorts provides air, sea, and land shipping services for cargo and freight.</p>
<h2>3. Liability</h2>
<p>ShopsNPorts is not liable for loss or damage beyond insurance coverage.</p>
<h2>4. Dispute Resolution</h2>
<p>All disputes shall be resolved through arbitration in accordance with applicable laws.</p>
        `,
        contentType: 'HTML',
        tags: ['legal', 'terms'],
        status: 'published',
        publishedAt: admin.firestore.Timestamp.now(),
        publishedBy: 'admin',
        createdAt: admin.firestore.Timestamp.now(),
        createdBy: 'admin',
        updatedAt: admin.firestore.Timestamp.now(),
        updatedBy: 'admin',
        viewCount: 0,
        seoKeywords: 'shipping, cargo, terms, conditions',
      },
      {
        id: 'privacy_policy',
        slug: 'privacy-policy',
        title: 'Privacy Policy',
        description: 'How we collect, use, and protect your data',
        content: `
<h1>Privacy Policy</h1>
<p>ShopsNPorts is committed to protecting your privacy.</p>
<h2>1. Data Collection</h2>
<p>We collect information necessary to provide shipping services.</p>
<h2>2. Data Usage</h2>
<p>Your data is used only for service provision and improvement.</p>
<h2>3. Data Protection</h2>
<p>We use industry-standard encryption to protect your personal information.</p>
<h2>4. GDPR Compliance</h2>
<p>ShopsNPorts complies with GDPR and international data protection regulations.</p>
        `,
        contentType: 'HTML',
        tags: ['legal', 'privacy'],
        status: 'published',
        publishedAt: admin.firestore.Timestamp.now(),
        publishedBy: 'admin',
        createdAt: admin.firestore.Timestamp.now(),
        createdBy: 'admin',
        updatedAt: admin.firestore.Timestamp.now(),
        updatedBy: 'admin',
        viewCount: 0,
        seoKeywords: 'privacy, data protection, GDPR',
      },
      {
        id: 'how_it_works',
        slug: 'how-it-works',
        title: 'How It Works',
        description: 'Step-by-step guide to shipping with ShopsNPorts',
        content: `
<h1>How It Works</h1>
<h2>Step 1: Create Shipment Request</h2>
<p>Enter your cargo details and origin/destination addresses.</p>
<h2>Step 2: Receive Quotes</h2>
<p>Get competitive quotes from shipping agents and affiliates.</p>
<h2>Step 3: Accept Quote</h2>
<p>Choose the best quote and complete the booking.</p>
<h2>Step 4: Track Shipment</h2>
<p>Monitor your cargo in real-time as it moves through the shipping network.</p>
<h2>Step 5: Delivery</h2>
<p>Receive your cargo at the destination with full insurance coverage.</p>
        `,
        contentType: 'HTML',
        tags: ['help', 'guide'],
        status: 'published',
        publishedAt: admin.firestore.Timestamp.now(),
        publishedBy: 'admin',
        createdAt: admin.firestore.Timestamp.now(),
        createdBy: 'admin',
        updatedAt: admin.firestore.Timestamp.now(),
        updatedBy: 'admin',
        viewCount: 0,
        seoKeywords: 'how to ship, shipping guide',
      },
    ];

    for (const page of contentPages) {
      await contentCollection.doc(page.id).set(page);
      console.log(`  ✅ Created page: ${page.title}`);
    }

    // ============================================
    // 4. Seed CONFIG collection (singleton)
    // ============================================
    console.log('\n⚙️ Seeding config collection...');
    const configData = {
      supportPhone: '+234 (0) 123 456 7890',
      supportWhatsapp: '+234 (0) 123 456 7890',
      supportEmail: 'support@shopsnports.com',
      techSupportEmail: 'tech@shopsnports.com',
      faqUrl: 'https://shopsnports.com/faq',
      theme: {
        primaryColor: '#003366',
        accentColor: '#FFB81C',
        successColor: '#27AE60',
        warningColor: '#E67E22',
        errorColor: '#E74C3C',
      },
      features: {
        analyticsEnabled: true,
        affiliateProgramActive: true,
        maintenanceMode: false,
      },
      appVersion: '1.0.0',
      minRequiredVersion: '1.0.0',
      updatedAt: admin.firestore.Timestamp.now(),
      updatedBy: 'system',
    };

    await db.collection('config').doc('contacts').set(configData);
    console.log('  ✅ Created config: contacts');

    console.log('\n✨ Firestore seeding completed successfully!');
    console.log('\n📊 Summary:');
    console.log('  • 4 banners');
    console.log('  • 5 news items');
    console.log('  • 3 content pages');
    console.log('  • 1 config document');
    console.log('\n🚀 Ready for mobile app binding!');
  } catch (error) {
    console.error('❌ Error seeding Firestore:', error);
    process.exit(1);
  }
}

// Run seeding
seedFirestore().then(() => {
  console.log('\nGoodbye! 👋');
  process.exit(0);
});

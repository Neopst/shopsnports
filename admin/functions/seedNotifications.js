// Cloud Functions - Seed notification collections
// Deploy with: firebase deploy --only functions

const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize Firebase
admin.initializeApp();
const db = admin.firestore();

/**
 * Seed Notification Collections
 * Run once to populate notifications, push_notifications, and notification_settings
 */
exports.seedNotificationCollections = functions.https.onRequest(async (req, res) => {
  try {
    console.log('Starting notification collections seeding...');

    // =========================================================================
    // 1. Seed push_notifications (Templates)
    // =========================================================================
    
    const pushNotificationTemplates = [
      {
        name: 'shipping_update',
        title: 'Shipping Update',
        message: 'Your shipment {requestId} has been {status}. Track it now!',
        type: 'shipping',
        enabled: true,
        description: 'Sent when shipping request status changes',
        createdAt: admin.firestore.Timestamp.now(),
        updatedAt: admin.firestore.Timestamp.now()
      },
      {
        name: 'shipping_delivered',
        title: 'Shipment Delivered',
        message: 'Your shipment has been successfully delivered to {destination}!',
        type: 'shipping',
        enabled: true,
        description: 'Sent when shipment is delivered',
        createdAt: admin.firestore.Timestamp.now(),
        updatedAt: admin.firestore.Timestamp.now()
      },
      {
        name: 'affiliate_earnings',
        title: 'New Affiliate Earnings',
        message: 'You earned {amount} from affiliate commission. Check your dashboard!',
        type: 'affiliate',
        enabled: true,
        description: 'Sent when affiliate earns commission',
        createdAt: admin.firestore.Timestamp.now(),
        updatedAt: admin.firestore.Timestamp.now()
      },
      {
        name: 'affiliate_payout',
        title: 'Payout Processed',
        message: 'Your payout of {amount} has been processed. Check your bank account.',
        type: 'affiliate',
        enabled: true,
        description: 'Sent when affiliate payout is completed',
        createdAt: admin.firestore.Timestamp.now(),
        updatedAt: admin.firestore.Timestamp.now()
      },
      {
        name: 'affiliate_approved',
        title: 'Affiliate Application Approved',
        message: 'Congratulations! Your affiliate application has been approved.',
        type: 'affiliate',
        enabled: true,
        description: 'Sent when affiliate application is approved',
        createdAt: admin.firestore.Timestamp.now(),
        updatedAt: admin.firestore.Timestamp.now()
      },
      {
        name: 'system_alert',
        title: 'Important Update',
        message: '{message}',
        type: 'system',
        enabled: true,
        description: 'System notifications and updates',
        createdAt: admin.firestore.Timestamp.now(),
        updatedAt: admin.firestore.Timestamp.now()
      },
      {
        name: 'promo_offer',
        title: '{title}',
        message: '{message}',
        type: 'promotional',
        enabled: false,
        description: 'Promotional offers (disabled by default)',
        createdAt: admin.firestore.Timestamp.now(),
        updatedAt: admin.firestore.Timestamp.now()
      }
    ];

    // Seed push notifications templates
    for (const template of pushNotificationTemplates) {
      const docId = template.name;
      await db.collection('push_notifications').doc(docId).set(template);
      console.log(`✓ Created push_notifications/${docId}`);
    }

    // =========================================================================
    // 2. Seed sample news_ticker items
    // =========================================================================
    
    const newsTickerItems = [
      {
        title: 'Welcome to ShopsNPorts',
        content: 'Fast, reliable, and affordable shipping solutions for everyone. Start shipping today!',
        priority: 10,
        status: 'published',
        imageUrl: 'assets/images/news/welcome.png',
        publishedAt: admin.firestore.Timestamp.now(),
        createdAt: admin.firestore.Timestamp.now(),
        createdBy: 'system'
      },
      {
        title: 'Shipping Available Worldwide',
        content: 'We now ship to over 50+ countries. Your shipments are in safe hands.',
        priority: 8,
        status: 'published',
        imageUrl: 'assets/images/news/worldwide.png',
        publishedAt: admin.firestore.Timestamp.now(),
        createdAt: admin.firestore.Timestamp.now(),
        createdBy: 'system'
      },
      {
        title: 'Join Our Affiliate Program',
        content: 'Earn commission by referring shippers and businesses. Become an affiliate today!',
        priority: 9,
        status: 'published',
        imageUrl: 'assets/images/news/affiliate.png',
        publishedAt: admin.firestore.Timestamp.now(),
        createdAt: admin.firestore.Timestamp.now(),
        createdBy: 'system'
      }
    ];

    // Seed news ticker (only if empty)
    const newsCheck = await db.collection('news_ticker').limit(1).get();
    if (newsCheck.empty) {
      for (const item of newsTickerItems) {
        const docRef = await db.collection('news_ticker').add(item);
        console.log(`✓ Created news_ticker/${docRef.id}`);
      }
    } else {
      console.log('✓ news_ticker already populated, skipping');
    }

    // =========================================================================
    // 3. Seed sample banners
    // =========================================================================
    
    const bannerItems = [
      {
        title: 'Coming Soon: Shipper Dashboard',
        imageUrl: 'assets/images/banners/shipper-dashboard.png',
        link: '/shipper',
        status: 'active',
        displayOrder: 1,
        startDate: admin.firestore.Timestamp.now(),
        endDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
        createdAt: admin.firestore.Timestamp.now()
      },
      {
        title: 'Affiliate Program - Earn Commission',
        imageUrl: 'assets/images/banners/affiliate-program.png',
        link: '/affiliate',
        status: 'active',
        displayOrder: 2,
        startDate: admin.firestore.Timestamp.now(),
        endDate: new Date(Date.now() + 60 * 24 * 60 * 60 * 1000),
        createdAt: admin.firestore.Timestamp.now()
      },
      {
        title: 'Fast Shipping Worldwide',
        imageUrl: 'assets/images/banners/fast-shipping.png',
        link: '/shipping',
        status: 'active',
        displayOrder: 3,
        startDate: admin.firestore.Timestamp.now(),
        endDate: new Date(Date.now() + 45 * 24 * 60 * 60 * 1000),
        createdAt: admin.firestore.Timestamp.now()
      }
    ];

    // Seed banners (only if empty)
    const bannerCheck = await db.collection('banners').limit(1).get();
    if (bannerCheck.empty) {
      for (const banner of bannerItems) {
        const docRef = await db.collection('banners').add(banner);
        console.log(`✓ Created banners/${docRef.id}`);
      }
    } else {
      console.log('✓ banners already populated, skipping');
    }

    // =========================================================================
    // 4. Seed sample content_pages
    // =========================================================================
    
    const contentPages = [
      {
        slug: 'how-it-works',
        title: 'How It Works',
        content: `
          <h1>How ShopsNPorts Works</h1>
          <p>Shipping has never been easier. Here are the simple steps:</p>
          <ol>
            <li><strong>Create Request:</strong> Enter your shipment details</li>
            <li><strong>Get Quote:</strong> Receive instant shipping quotes</li>
            <li><strong>Confirm:</strong> Approve the shipment</li>
            <li><strong>Track:</strong> Monitor your shipment in real-time</li>
          </ol>
        `,
        published: true,
        createdAt: admin.firestore.Timestamp.now(),
        updatedAt: admin.firestore.Timestamp.now()
      },
      {
        slug: 'about',
        title: 'About ShopsNPorts',
        content: `
          <h1>About Us</h1>
          <p>ShopsNPorts is a leading shipping and logistics platform connecting shippers with carriers.</p>
          <p>Our mission is to make shipping fast, affordable, and reliable for everyone.</p>
        `,
        published: true,
        createdAt: admin.firestore.Timestamp.now(),
        updatedAt: admin.firestore.Timestamp.now()
      },
      {
        slug: 'faq',
        title: 'Frequently Asked Questions',
        content: `
          <h1>FAQ</h1>
          <h3>What areas do you ship to?</h3>
          <p>We ship to 50+ countries worldwide.</p>
          <h3>How are prices calculated?</h3>
          <p>Prices are based on weight, distance, and shipping type.</p>
        `,
        published: true,
        createdAt: admin.firestore.Timestamp.now(),
        updatedAt: admin.firestore.Timestamp.now()
      }
    ];

    // Seed content pages (only if empty)
    const contentCheck = await db.collection('content_pages').limit(1).get();
    if (contentCheck.empty) {
      for (const page of contentPages) {
        await db.collection('content_pages').doc(page.slug).set(page);
        console.log(`✓ Created content_pages/${page.slug}`);
      }
    } else {
      console.log('✓ content_pages already populated, skipping');
    }

    // =========================================================================
    // 5. Create default notification_settings for existing users
    // =========================================================================
    
    // Get all users
    const usersSnapshot = await db.collection('users').get();
    let settingsCreated = 0;

    for (const userDoc of usersSnapshot.docs) {
      const userId = userDoc.id;
      const settingsRef = db.collection('notification_settings').doc(userId);
      const settingsSnapshot = await settingsRef.get();

      if (!settingsSnapshot.exists) {
        // Create default settings
        const defaultSettings = {
          userId: userId,
          pushEnabled: true,
          emailEnabled: true,
          inAppEnabled: true,
          types: {
            shipping: true,
            affiliate: true,
            system: true,
            promotional: false
          },
          frequency: 'immediate',
          quietHours: {
            enabled: false,
            start: '22:00',
            end: '08:00'
          },
          createdAt: admin.firestore.Timestamp.now(),
          updatedAt: admin.firestore.Timestamp.now()
        };

        await settingsRef.set(defaultSettings);
        settingsCreated++;
      }
    }
    console.log(`✓ Created notification_settings for ${settingsCreated} users`);

    // =========================================================================
    // Success Response
    // =========================================================================
    
    return res.json({
      success: true,
      message: 'Notification collections seeded successfully',
      summary: {
        push_notifications: pushNotificationTemplates.length,
        news_ticker: newsCheck.empty ? newsTickerItems.length : 0,
        banners: bannerCheck.empty ? bannerItems.length : 0,
        content_pages: contentCheck.empty ? contentPages.length : 0,
        notification_settings: settingsCreated
      }
    });
  } catch (error) {
    console.error('Error seeding collections:', error);
    return res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * Create notification_settings when new user signs up
 */
exports.createNotificationSettingsOnUserCreate = functions.auth.user().onCreate(async (user) => {
  try {
    const defaultSettings = {
      userId: user.uid,
      pushEnabled: true,
      emailEnabled: true,
      inAppEnabled: true,
      types: {
        shipping: true,
        affiliate: true,
        system: true,
        promotional: false
      },
      frequency: 'immediate',
      quietHours: {
        enabled: false,
        start: '22:00',
        end: '08:00'
      },
      createdAt: admin.firestore.Timestamp.now(),
      updatedAt: admin.firestore.Timestamp.now()
    };

    await db.collection('notification_settings').doc(user.uid).set(defaultSettings);
    console.log(`✓ Created notification_settings for user ${user.uid}`);
  } catch (error) {
    console.error('Error creating notification settings:', error);
  }
});

/**
 * Send notification via Cloud Function
 * Called from mobile app
 */
exports.sendNotification = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  try {
    const { userId, title, message, type, actionUrl } = data;

    // Create notification in Firestore
    const notification = {
      userId: userId,
      title: title,
      message: message,
      type: type || 'system',
      status: 'unread',
      actionUrl: actionUrl || null,
      timestamp: admin.firestore.Timestamp.now(),
      readAt: null,
      createdAt: admin.firestore.Timestamp.now()
    };

    const docRef = await db.collection('notifications').add(notification);
    
    console.log(`✓ Created notification ${docRef.id} for user ${userId}`);

    return {
      success: true,
      notificationId: docRef.id
    };
  } catch (error) {
    console.error('Error sending notification:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Update notification status (mark as read)
 */
exports.updateNotificationStatus = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  try {
    const { notificationId, status } = data;
    const userId = context.auth.uid;

    // Verify notification belongs to user
    const notificationRef = db.collection('notifications').doc(notificationId);
    const notificationDoc = await notificationRef.get();

    if (!notificationDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Notification not found');
    }

    if (notificationDoc.data().userId !== userId) {
      throw new functions.https.HttpsError('permission-denied', 'Unauthorized');
    }

    // Update status
    await notificationRef.update({
      status: status,
      readAt: status === 'read' ? admin.firestore.Timestamp.now() : null,
      updatedAt: admin.firestore.Timestamp.now()
    });

    return {
      success: true,
      message: `Notification marked as ${status}`
    };
  } catch (error) {
    console.error('Error updating notification:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

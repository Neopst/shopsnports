import '../../features/invoices/data/repositories/invoice_repository_firestore.dart';
import '../../features/payouts/data/repositories/payout_repository_firestore.dart';
import '../../features/notifications/data/repositories/notification_repository_firestore.dart';
import '../../features/push_notifications/data/repositories/push_notification_repository_firestore.dart';
import '../../features/content/data/repositories/content_repository_firestore.dart';
import '../../features/settings/data/repositories/settings_repository_firestore.dart';
import '../../features/news_ticker/data/repositories/news_ticker_repository_firestore.dart';
// import '../../features/super_admin_profile/data/repositories/super_admin_repository_firestore.dart'; // Disabled

/// Master Firestore Seeder - Seeds all collections with sample data
/// This is the SINGLE SOURCE OF TRUTH for all dashboard data
class FirestoreSeeder {
  static Future<void> seedAllCollections() async {
    print('\n🌱🌱🌱 MASTER FIRESTORE SEEDING STARTED 🌱🌱🌱\n');
    print('📍 Target: Firestore Database (shopsnports)');
    print('🎯 Goal: Seed ALL collections with comprehensive mock data\n');

    final startTime = DateTime.now();
    int successCount = 0;
    int failureCount = 0;

    // Core Business Data
    // DISABLED: Customers are created via mobile app signup through Firebase Auth
    // await _seedModule('Customers', () async {
    //   await CustomerRepositoryFirestore().seedSampleData();
    //   successCount++;
    // }, () => failureCount++);

    await _seedModule('Invoices', () async {
      await InvoiceRepositoryFirestore().seedSampleData();
      successCount++;
    }, () => failureCount++);

    // Affiliates are now seeded via seed-affiliates.js script
    // await _seedModule('Affiliates', () async {
    //   successCount++;
    // }, () => failureCount++);

    await _seedModule('Payouts', () async {
      await PayoutRepositoryFirestore().seedSampleData();
      successCount++;
    }, () => failureCount++);

    // Communication Modules
    await _seedModule('Notifications', () async {
      await NotificationRepositoryFirestore().seedSampleData();
      successCount++;
    }, () => failureCount++);

    await _seedModule('Push Notifications', () async {
      await PushNotificationRepositoryFirestore().seedSampleData();
      successCount++;
    }, () => failureCount++);

    // Content Management
    await _seedModule(
      'Content (Pages, FAQs, Banners, Email Templates)',
      () async {
        await ContentRepositoryFirestore().seedSampleData();
        successCount++;
      },
      () => failureCount++,
    );

    // Configuration
    await _seedModule('Settings (Business Settings)', () async {
      await SettingsRepositoryFirestore().seedSampleData();
      successCount++;
    }, () => failureCount++);

    // News & Updates
    await _seedModule('News Ticker', () async {
      await NewsTickerRepositoryFirestore().seedSampleData();
      successCount++;
    }, () => failureCount++);

    // Admin Management
    // TODO: Re-enable when Super Admin Firestore implementation is complete
    // await _seedModule('Super Admin & Admins', () async {
    //   await SuperAdminRepositoryFirestore().seedSampleData();
    //   successCount++;
    // }, () => failureCount++);

    // Shipping - Mock data seeding removed (using live Firestore data only)
    // await _seedModule('Shipments', () async {
    //   await ShippingRepositoryFirestore().seedSampleData();
    //   successCount++;
    // }, () => failureCount++);

    final duration = DateTime.now().difference(startTime);

    print('\n═════════════════════════════════════════════');
    print('✅✅✅ FIRESTORE SEEDING COMPLETE ✅✅✅');
    print('═════════════════════════════════════════════');
    print('📊 Success: $successCount modules');
    print('❌ Failed: $failureCount modules');
    print('⏱️  Duration: ${duration.inSeconds}s');
    print(
      '🔥 Database: console.firebase.google.com/project/shopsnports/firestore',
    );
    print('═════════════════════════════════════════════\n');
  }

  static Future<void> _seedModule(
    String name,
    Future<void> Function() seedFunction,
    void Function() onError,
  ) async {
    try {
      print('📦 Seeding $name...');
      await seedFunction();
      print('   ✅ $name seeded successfully');
    } catch (e, stackTrace) {
      print('   ❌ $name failed: $e');
      if (e.toString().contains('already exists')) {
        print('   ℹ️  Data already exists, skipping...');
      } else {
        print(
          '   Stack: ${stackTrace.toString().split('\n').take(3).join('\n')}',
        );
        onError();
      }
    }
  }
}

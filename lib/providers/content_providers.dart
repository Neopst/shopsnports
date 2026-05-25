import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopsnports/models/app_banner.dart';
import 'package:shopsnports/models/news_ticker.dart';
import 'package:shopsnports/models/content_page.dart';
import 'package:shopsnports/models/app_config.dart';

final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// Stream provider for active banners from Firestore
/// Watches for real-time updates to HOME_CAROUSEL banners
final activeBannersProvider = StreamProvider<List<AppBanner>>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);

  return firestore.collection('banners').snapshots().map((snapshot) {
    final List<AppBanner> banners = [];

    for (var doc in snapshot.docs) {
      try {
        final banner = AppBanner.fromFirestore(doc);
        if (!banner.isActive) {
          continue;
        }
        banners.add(banner);
      } catch (e) {
        // Skip malformed documents
      }
    }

    return banners;
  });
});

/// Stream provider for published news items from Firestore
/// Automatically filters expired news (expiresAt > now)
final publishedNewsProvider = StreamProvider<List<NewsTicker>>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);

  return firestore.collection('news_ticker').snapshots().map((snapshot) {
    final now = Timestamp.fromDate(DateTime.now());
    final List<NewsTicker> newsItems = [];

    for (var doc in snapshot.docs) {
      try {
        final item = NewsTicker.fromFirestore(doc);
        if (item.status != 'published') {
          continue;
        }
        if (item.expiresAt.compareTo(now) < 0) {
          continue;
        }
        if (item.publishedAt.compareTo(now) > 0) {
          continue;
        }
        newsItems.add(item);
      } catch (e) {
        // Skip malformed documents
      }
    }

    return newsItems;
  });
});

/// Future provider for app configuration
/// Reads singleton config/contacts document
final appConfigProvider = FutureProvider<AppConfig>((ref) async {
  final firestore = ref.watch(firebaseFirestoreProvider);

  try {
    final doc = await firestore.collection('config').doc('contacts').get();

    if (doc.exists) {
      return AppConfig.fromFirestore(doc);
    }
  } catch (e) {
    // Log error in production - use proper logging in production
  }

  return AppConfig(
    supportPhone: '+234 XXX XXX XXXX',
    supportWhatsapp: '+234 XXX XXX XXXX',
    supportEmail: 'support@shopsnports.com',
    techSupportEmail: 'tech@shopsnports.com',
    faqUrl: 'https://shopsnports.com/faq',
    theme: ThemeConfig(
      primaryColor: '#003366',
      accentColor: '#FFB81C',
      successColor: '#27AE60',
      warningColor: '#E67E22',
      errorColor: '#E74C3C',
    ),
    features: FeaturesConfig(
      analyticsEnabled: true,
      affiliateProgramActive: true,
      maintenanceMode: false,
    ),
    appVersion: '1.0.0',
    minRequiredVersion: '1.0.0',
    updatedAt: Timestamp.now(),
    updatedBy: 'system',
  );
});

/// Future provider to fetch a single content page by slug
/// Used for legal pages, FAQ, help documentation
final contentPageProvider =
    FutureProvider.family<ContentPage?, String>((ref, slug) async {
  final firestore = ref.watch(firebaseFirestoreProvider);

  try {
    final query = await firestore
        .collection('content_pages')
        .where('slug', isEqualTo: slug)
        .where('status', isEqualTo: 'published')
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return ContentPage.fromFirestore(query.docs.first);
    }
    return null;
  } catch (e) {
    return null;
  }
});

/// Future provider to fetch multiple content pages by tag
/// Used to get all FAQs, all legal docs, etc.
final contentPagesByTagProvider =
    FutureProvider.family<List<ContentPage>, String>((ref, tag) async {
  final firestore = ref.watch(firebaseFirestoreProvider);

  try {
    final query = await firestore
        .collection('content_pages')
        .where('tags', arrayContains: tag)
        .where('status', isEqualTo: 'published')
        .get();

    return query.docs.map((doc) => ContentPage.fromFirestore(doc)).toList();
  } catch (e) {
    return [];
  }
});

/// Stream provider for getting all banners (not filtered)
/// Useful for admin dashboard and banner management
final allBannersProvider = StreamProvider<List<AppBanner>>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);

  return firestore
      .collection('banners')
      .orderBy('displayOrder', descending: false)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) => AppBanner.fromFirestore(doc)).toList();
  });
});

/// Stream provider for getting all news (not filtered)
/// Useful for admin dashboard and news management
final allNewsProvider = StreamProvider<List<NewsTicker>>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);

  return firestore
      .collection('news_ticker')
      .orderBy('publishedAt', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) => NewsTicker.fromFirestore(doc)).toList();
  });
});
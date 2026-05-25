import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:admin_dashboard/features/content/data/models/index.dart';
import 'package:admin_dashboard/features/content/data/repositories/content_repository.dart';
import 'package:admin_dashboard/features/content/data/repositories/content_repository_firestore.dart';
// import 'package:admin_dashboard/features/content/data/repositories/content_repository_api.dart';

/// Content repository provider - uses Firestore for all content (banners, pages, FAQs, templates)
final contentRepositoryProvider = Provider<IContentRepository>((ref) {
  return ContentRepositoryFirestore(); // Firestore - syncs to mobile app
  // return ContentRepositoryApi(); // OLD: PostgreSQL API (removed)
});

/// Firestore instance for real-time streams
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// Get all content pages (real-time)
final contentPagesProvider = StreamProvider<List<ContentPage>>((ref) async* {
  final firestore = ref.watch(firestoreProvider);
  final snapshot = firestore
      .collection('content_pages')
      .orderBy('createdAt', descending: true)
      .snapshots();

  await for (final querySnapshot in snapshot) {
    final pages = querySnapshot.docs
        .map((doc) => ContentPage.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
    yield pages;
  }
});

/// Get published pages only (real-time)
final publishedPagesProvider = StreamProvider<List<ContentPage>>((ref) async* {
  final firestore = ref.watch(firestoreProvider);
  final snapshot = firestore
      .collection('content_pages')
      .where('status', isEqualTo: 'published')
      .orderBy('publishedAt', descending: true)
      .snapshots();

  await for (final querySnapshot in snapshot) {
    final pages = querySnapshot.docs
        .map((doc) => ContentPage.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
    yield pages;
  }
});

/// Get single page by ID (real-time)
final contentPageProvider = StreamProvider.family<ContentPage?, String>((ref, pageId) async* {
  final firestore = ref.watch(firestoreProvider);
  final snapshot = firestore.collection('content_pages').doc(pageId).snapshots();

  await for (final docSnapshot in snapshot) {
    if (docSnapshot.exists) {
      yield ContentPage.fromMap(docSnapshot.data() as Map<String, dynamic>, docSnapshot.id);
    } else {
      yield null;
    }
  }
});

/// Get page by slug (real-time)
final contentPageBySlugProvider = StreamProvider.family<ContentPage?, String>((ref, slug) async* {
  final firestore = ref.watch(firestoreProvider);
  final snapshot = firestore
      .collection('content_pages')
      .where('slug', isEqualTo: slug)
      .limit(1)
      .snapshots();

  await for (final querySnapshot in snapshot) {
    if (querySnapshot.docs.isNotEmpty) {
      yield ContentPage.fromMap(
        querySnapshot.docs.first.data() as Map<String, dynamic>,
        querySnapshot.docs.first.id,
      );
    } else {
      yield null;
    }
  }
});

/// Get all banners (real-time)
final bannersProvider = StreamProvider<List<Banner>>((ref) async* {
  final firestore = ref.watch(firestoreProvider);
  final snapshot = firestore
      .collection('banners')
      .orderBy('displayOrder')
      .snapshots();

  await for (final querySnapshot in snapshot) {
    final banners = querySnapshot.docs
        .map((doc) => Banner.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
    yield banners;
  }
});

/// Get active banners only (real-time)
final activeBannersProvider = StreamProvider<List<Banner>>((ref) async* {
  final firestore = ref.watch(firestoreProvider);
  final now = DateTime.now();
  final snapshot = firestore
      .collection('banners')
      .where('active', isEqualTo: true)
      .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(now))
      .where('endDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
      .orderBy('startDate')
      .orderBy('endDate')
      .orderBy('displayOrder')
      .snapshots();

  await for (final querySnapshot in snapshot) {
    final banners = querySnapshot.docs
        .map((doc) => Banner.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
    yield banners;
  }
});

/// Get banners by placement (real-time)
final bannersByPlacementProvider =
    StreamProvider.family<List<Banner>, BannerPlacement>((ref, placement) async* {
      final firestore = ref.watch(firestoreProvider);
      final snapshot = firestore
          .collection('banners')
          .where('placement', isEqualTo: placement.name)
          .orderBy('displayOrder')
          .snapshots();

      await for (final querySnapshot in snapshot) {
        final banners = querySnapshot.docs
            .map((doc) => Banner.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();
        yield banners;
      }
    });

/// Get all FAQs (real-time)
final faqsProvider = StreamProvider<List<FAQ>>((ref) async* {
  final firestore = ref.watch(firestoreProvider);
  final snapshot = firestore
      .collection('faqs')
      .orderBy('displayOrder')
      .snapshots();

  await for (final querySnapshot in snapshot) {
    final faqs = querySnapshot.docs
        .map((doc) => FAQ.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
    yield faqs;
  }
});

/// Get FAQs by category (real-time)
final faqsByCategoryProvider = StreamProvider.family<List<FAQ>, String>((ref, category) async* {
  final firestore = ref.watch(firestoreProvider);
  final snapshot = firestore
      .collection('faqs')
      .where('category', isEqualTo: category)
      .where('isActive', isEqualTo: true)
      .orderBy('displayOrder')
      .snapshots();

  await for (final querySnapshot in snapshot) {
    final faqs = querySnapshot.docs
        .map((doc) => FAQ.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
    yield faqs;
  }
});

/// Get FAQ categories (real-time)
final faqCategoriesProvider = StreamProvider<List<String>>((ref) async* {
  final firestore = ref.watch(firestoreProvider);
  final snapshot = firestore.collection('faqs').snapshots();

  await for (final querySnapshot in snapshot) {
    final categories = querySnapshot.docs
        .map((doc) => (doc.data() as Map<String, dynamic>)['category'] as String?)
        .where((cat) => cat != null)
        .cast<String>()
        .toSet()
        .toList();
    categories.sort();
    yield categories;
  }
});

/// Get all email templates (real-time)
final emailTemplatesProvider = StreamProvider<List<EmailTemplate>>((ref) async* {
  final firestore = ref.watch(firestoreProvider);
  final snapshot = firestore
      .collection('email_templates')
      .orderBy('name')
      .snapshots();

  await for (final querySnapshot in snapshot) {
    final templates = querySnapshot.docs
        .map((doc) => EmailTemplate.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
    yield templates;
  }
});

/// Get email template by type (real-time)
final emailTemplateByTypeProvider =
    StreamProvider.family<EmailTemplate?, EmailTemplateType>((ref, type) async* {
      final firestore = ref.watch(firestoreProvider);
      final snapshot = firestore
          .collection('email_templates')
          .where('type', isEqualTo: type.name)
          .limit(1)
          .snapshots();

      await for (final querySnapshot in snapshot) {
        if (querySnapshot.docs.isNotEmpty) {
          yield EmailTemplate.fromMap(
            querySnapshot.docs.first.data() as Map<String, dynamic>,
            querySnapshot.docs.first.id,
          );
        } else {
          yield null;
        }
      }
    });

/// Get email template by ID (real-time)
final emailTemplateProvider = StreamProvider.family<EmailTemplate?, String>((ref, templateId) async* {
  final firestore = ref.watch(firestoreProvider);
  final snapshot = firestore.collection('email_templates').doc(templateId).snapshots();

  await for (final docSnapshot in snapshot) {
    if (docSnapshot.exists) {
      yield EmailTemplate.fromMap(docSnapshot.data() as Map<String, dynamic>, docSnapshot.id);
    } else {
      yield null;
    }
  }
});

/// Search pages (still uses FutureProvider for search functionality)
final searchPagesProvider = FutureProvider.family<List<ContentPage>, String>((
  ref,
  query,
) async {
  final repository = ref.watch(contentRepositoryProvider);
  if (query.isEmpty) {
    return [];
  }
  return repository.searchPages(query);
});

/// Search FAQs (still uses FutureProvider for search functionality)
final searchFAQsProvider = FutureProvider.family<List<FAQ>, String>((
  ref,
  query,
) async {
  final repository = ref.watch(contentRepositoryProvider);
  if (query.isEmpty) {
    return [];
  }
  return repository.searchFAQs(query);
});

/// Content analytics (still uses FutureProvider)
final contentAnalyticsProvider =
    FutureProvider.family<Map<String, int>, String>((ref, pageId) async {
      final repository = ref.watch(contentRepositoryProvider);
      return repository.getContentAnalytics(pageId);
    });

/// Banner analytics (still uses FutureProvider)
final bannerAnalyticsProvider = FutureProvider.family<Map<String, int>, String>(
  (ref, bannerId) async {
    final repository = ref.watch(contentRepositoryProvider);
    return repository.getBannerAnalytics(bannerId);
  },
);

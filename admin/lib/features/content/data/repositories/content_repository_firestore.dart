import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:admin_dashboard/features/content/data/models/index.dart';
import 'package:admin_dashboard/features/content/data/repositories/content_repository.dart';
import 'package:admin_dashboard/features/super_admin/data/models/admin_permissions.dart';
import 'package:admin_dashboard/features/content/services/content_audit_service.dart';

/// Firestore implementation of IContentRepository
class ContentRepositoryFirestore implements IContentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ContentAuditService _auditService = ContentAuditService();

  /// Check if user is authenticated
  Future<User> _getAuthenticatedUser() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Unauthorized: No authenticated user found');
    }
    return user;
  }

  /// Check if user has content management permission
  Future<void> _checkContentPermission(User user) async {
    try {
      final adminDoc = await _firestore.collection('admin_users').doc(user.uid).get();
      if (!adminDoc.exists) {
        throw Exception('Access denied: Admin account not found');
      }

      final data = adminDoc.data() as Map<String, dynamic>;
      final role = data['role'] as String?;

      // Super admins have full access
      if (role == 'super_admin') {
        return;
      }

      // Check for content_management permission
      final permissions = data['permissions'] as Map<String, dynamic>?;
      if (permissions == null) {
        throw Exception('Access denied: No permissions configured');
      }

      final hasContentAccess = permissions['content_management'] as bool? ?? false;
      if (!hasContentAccess) {
        throw Exception('Access denied: Content management permission required');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Access denied: Failed to verify permissions');
    }
  }

  /// Get current user info for audit trail
  Map<String, String> _getUserInfo(User user) {
    return {
      'userId': user.uid,
      'userEmail': user.email ?? 'unknown',
    };
  }

  // Collection references
  CollectionReference get _bannersCollection =>
      _firestore.collection('banners');
  CollectionReference get _pagesCollection =>
      _firestore.collection('content_pages');
  CollectionReference get _faqsCollection => _firestore.collection('faqs');
  CollectionReference get _templatesCollection =>
      _firestore.collection('email_templates');

  // ========== BANNER OPERATIONS ==========

  @override
  Future<List<Banner>> getBanners({int limit = 50}) async {
    final snapshot = await _bannersCollection
        .orderBy('displayOrder')
        .limit(limit)
        .get();
    return snapshot.docs
        .map(
          (doc) => Banner.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        )
        .toList();
  }

  @override
  Future<List<Banner>> getActiveBanners() async {
    final now = DateTime.now();
    final snapshot = await _bannersCollection
        .where('active', isEqualTo: true)
        .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(now))
        .where('endDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .orderBy('startDate')
        .orderBy('endDate')
        .orderBy('displayOrder')
        .get();
    return snapshot.docs
        .map(
          (doc) => Banner.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        )
        .toList();
  }

  @override
  Future<List<Banner>> getBannersByPlacement(BannerPlacement placement) async {
    final snapshot = await _bannersCollection
        .where('placement', isEqualTo: placement.name)
        .orderBy('displayOrder')
        .get();
    return snapshot.docs
        .map(
          (doc) => Banner.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        )
        .toList();
  }

  @override
  Future<String> createBanner(Banner banner) async {
    final user = await _getAuthenticatedUser();
    await _checkContentPermission(user);
    final doc = await _bannersCollection.add(banner.toMap());

    // Log audit event
    await _auditService.logEvent(
      action: AuditAction.create,
      entityType: AuditEntityType.banner,
      entityId: doc.id,
      entityName: banner.title,
      changes: {
        'title': banner.title,
        'placement': banner.placement.name,
        'active': banner.active,
      },
    );

    return doc.id;
  }

  @override
  Future<void> updateBanner(String id, Banner banner) async {
    final user = await _getAuthenticatedUser();
    await _checkContentPermission(user);

    // Get previous state for change tracking
    final previousDoc = await _bannersCollection.doc(id).get();
    final previousData = previousDoc.exists ? previousDoc.data() as Map<String, dynamic> : null;

    await _bannersCollection.doc(id).update(banner.toMap());

    // Log audit event
    await _auditService.logEvent(
      action: AuditAction.update,
      entityType: AuditEntityType.banner,
      entityId: id,
      entityName: banner.title,
      changes: {
        'previous': previousData,
        'current': banner.toMap(),
      },
    );
  }

  @override
  Future<void> deleteBanner(String id) async {
    final user = await _getAuthenticatedUser();
    await _checkContentPermission(user);

    // Get banner details before deletion
    final doc = await _bannersCollection.doc(id).get();
    final banner = doc.exists
        ? Banner.fromMap(doc.data() as Map<String, dynamic>, id)
        : null;

    await _bannersCollection.doc(id).delete();

    // Log audit event
    if (banner != null) {
      await _auditService.logEvent(
        action: AuditAction.delete,
        entityType: AuditEntityType.banner,
        entityId: id,
        entityName: banner.title,
        changes: {
          'deleted': banner.toMap(),
        },
      );
    }
  }

  @override
  Future<void> recordBannerImpression(String id) async {
    await _bannersCollection.doc(id).update({
      'impressions': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> recordBannerClick(String id) async {
    await _bannersCollection.doc(id).update({
      'clicks': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ========== CONTENT PAGE OPERATIONS ==========

  @override
  Future<List<ContentPage>> getPages({int limit = 20, int offset = 0}) async {
    Query query = _pagesCollection
        .orderBy('createdAt', descending: true)
        .limit(limit);
    if (offset > 0) {
      final offsetSnapshot = await _pagesCollection
          .orderBy('createdAt', descending: true)
          .limit(offset)
          .get();
      if (offsetSnapshot.docs.isNotEmpty) {
        query = query.startAfterDocument(offsetSnapshot.docs.last);
      }
    }
    final snapshot = await query.get();
    return snapshot.docs
        .map(
          (doc) =>
              ContentPage.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        )
        .toList();
  }

  @override
  Future<List<ContentPage>> getPublishedPages({
    int limit = 20,
    int offset = 0,
  }) async {
    Query query = _pagesCollection
        .where('status', isEqualTo: ContentStatus.published.name)
        .orderBy('publishedAt', descending: true)
        .limit(limit);
    if (offset > 0) {
      final offsetSnapshot = await _pagesCollection
          .where('status', isEqualTo: ContentStatus.published.name)
          .orderBy('publishedAt', descending: true)
          .limit(offset)
          .get();
      if (offsetSnapshot.docs.isNotEmpty) {
        query = query.startAfterDocument(offsetSnapshot.docs.last);
      }
    }
    final snapshot = await query.get();
    return snapshot.docs
        .map(
          (doc) =>
              ContentPage.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        )
        .toList();
  }

  @override
  Future<ContentPage?> getPageBySlug(String slug) async {
    final snapshot = await _pagesCollection
        .where('slug', isEqualTo: slug)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return ContentPage.fromMap(
      snapshot.docs.first.data() as Map<String, dynamic>,
      snapshot.docs.first.id,
    );
  }

  @override
  Future<ContentPage?> getPageById(String id) async {
    final doc = await _pagesCollection.doc(id).get();
    if (!doc.exists) return null;
    return ContentPage.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  @override
  Future<String> createPage(ContentPage page) async {
    final user = await _getAuthenticatedUser();
    await _checkContentPermission(user);
    final doc = await _pagesCollection.add(page.toMap());

    // Log audit event
    await _auditService.logEvent(
      action: AuditAction.create,
      entityType: AuditEntityType.content_page,
      entityId: doc.id,
      entityName: page.title,
      changes: {
        'title': page.title,
        'slug': page.slug,
        'status': page.status.name,
      },
    );

    return doc.id;
  }

  @override
  Future<void> updatePage(String id, ContentPage page) async {
    final user = await _getAuthenticatedUser();
    await _checkContentPermission(user);

    // Get previous state for change tracking
    final previousDoc = await _pagesCollection.doc(id).get();
    final previousData = previousDoc.exists ? previousDoc.data() as Map<String, dynamic> : null;

    await _pagesCollection.doc(id).update(page.toMap());

    // Log audit event
    await _auditService.logEvent(
      action: AuditAction.update,
      entityType: AuditEntityType.content_page,
      entityId: id,
      entityName: page.title,
      changes: {
        'previous': previousData,
        'current': page.toMap(),
      },
    );
  }

  @override
  Future<void> deletePage(String id) async {
    final user = await _getAuthenticatedUser();
    await _checkContentPermission(user);

    // Get page details before deletion
    final doc = await _pagesCollection.doc(id).get();
    final page = doc.exists
        ? ContentPage.fromMap(doc.data() as Map<String, dynamic>, id)
        : null;

    await _pagesCollection.doc(id).delete();

    // Log audit event
    if (page != null) {
      await _auditService.logEvent(
        action: AuditAction.delete,
        entityType: AuditEntityType.content_page,
        entityId: id,
        entityName: page.title,
        changes: {
          'deleted': page.toMap(),
        },
      );
    }
  }

  @override
  Future<void> publishPage(String id) async {
    final user = await _getAuthenticatedUser();
    await _checkContentPermission(user);

    // Get page details
    final doc = await _pagesCollection.doc(id).get();
    final page = doc.exists
        ? ContentPage.fromMap(doc.data() as Map<String, dynamic>, id)
        : null;

    await _pagesCollection.doc(id).update({
      'status': ContentStatus.published.name,
      'publishedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Log audit event
    if (page != null) {
      await _auditService.logEvent(
        action: AuditAction.publish,
        entityType: AuditEntityType.content_page,
        entityId: id,
        entityName: page.title,
        changes: {
          'previousStatus': page.status.name,
          'newStatus': ContentStatus.published.name,
        },
      );
    }
  }

  @override
  Future<void> unpublishPage(String id) async {
    final user = await _getAuthenticatedUser();
    await _checkContentPermission(user);

    // Get page details
    final doc = await _pagesCollection.doc(id).get();
    final page = doc.exists
        ? ContentPage.fromMap(doc.data() as Map<String, dynamic>, id)
        : null;

    await _pagesCollection.doc(id).update({
      'status': ContentStatus.draft.name,
      'publishedAt': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Log audit event
    if (page != null) {
      await _auditService.logEvent(
        action: AuditAction.unpublish,
        entityType: AuditEntityType.content_page,
        entityId: id,
        entityName: page.title,
        changes: {
          'previousStatus': page.status.name,
          'newStatus': ContentStatus.draft.name,
        },
      );
    }
  }

  @override
  Future<void> incrementPageView(String id) async {
    await _pagesCollection.doc(id).update({
      'viewCount': FieldValue.increment(1),
    });
  }

  // ========== FAQ OPERATIONS ==========

  @override
  Future<List<FAQ>> getFAQs({int limit = 100}) async {
    final snapshot = await _faqsCollection
        .orderBy('displayOrder')
        .limit(limit)
        .get();
    return snapshot.docs
        .map((doc) => FAQ.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  @override
  Future<List<FAQ>> getFAQsByCategory(String category) async {
    final snapshot = await _faqsCollection
        .where('category', isEqualTo: category)
        .where('isActive', isEqualTo: true)
        .orderBy('displayOrder')
        .get();
    return snapshot.docs
        .map((doc) => FAQ.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  @override
  Future<List<String>> getFAQCategories() async {
    final snapshot = await _faqsCollection.get();
    final categories = snapshot.docs
        .map(
          (doc) => (doc.data() as Map<String, dynamic>)['category'] as String?,
        )
        .where((cat) => cat != null)
        .cast<String>()
        .toSet()
        .toList();
    categories.sort();
    return categories;
  }

  @override
  Future<String> createFAQ(FAQ faq) async {
    final user = await _getAuthenticatedUser();
    await _checkContentPermission(user);
    final doc = await _faqsCollection.add(faq.toMap());

    // Log audit event
    await _auditService.logEvent(
      action: AuditAction.create,
      entityType: AuditEntityType.faq,
      entityId: doc.id,
      entityName: faq.question,
      changes: {
        'question': faq.question,
        'category': faq.category,
        'isActive': faq.isActive,
      },
    );

    return doc.id;
  }

  @override
  Future<void> updateFAQ(String id, FAQ faq) async {
    final user = await _getAuthenticatedUser();
    await _checkContentPermission(user);

    // Get previous state for change tracking
    final previousDoc = await _faqsCollection.doc(id).get();
    final previousData = previousDoc.exists ? previousDoc.data() as Map<String, dynamic> : null;

    await _faqsCollection.doc(id).update(faq.toMap());

    // Log audit event
    await _auditService.logEvent(
      action: AuditAction.update,
      entityType: AuditEntityType.faq,
      entityId: id,
      entityName: faq.question,
      changes: {
        'previous': previousData,
        'current': faq.toMap(),
      },
    );
  }

  @override
  Future<void> deleteFAQ(String id) async {
    final user = await _getAuthenticatedUser();
    await _checkContentPermission(user);

    // Get FAQ details before deletion
    final doc = await _faqsCollection.doc(id).get();
    final faq = doc.exists
        ? FAQ.fromMap(doc.data() as Map<String, dynamic>, id)
        : null;

    await _faqsCollection.doc(id).delete();

    // Log audit event
    if (faq != null) {
      await _auditService.logEvent(
        action: AuditAction.delete,
        entityType: AuditEntityType.faq,
        entityId: id,
        entityName: faq.question,
        changes: {
          'deleted': faq.toMap(),
        },
      );
    }
  }

  @override
  Future<void> incrementFAQView(String id) async {
    await _faqsCollection.doc(id).update({
      'viewCount': FieldValue.increment(1),
    });
  }

  // ========== EMAIL TEMPLATE OPERATIONS ==========

  @override
  Future<List<EmailTemplate>> getEmailTemplates() async {
    final snapshot = await _templatesCollection.orderBy('name').get();
    return snapshot.docs
        .map(
          (doc) =>
              EmailTemplate.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        )
        .toList();
  }

  @override
  Future<EmailTemplate?> getEmailTemplate(EmailTemplateType type) async {
    final snapshot = await _templatesCollection
        .where('type', isEqualTo: type.name)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return EmailTemplate.fromMap(
      snapshot.docs.first.data() as Map<String, dynamic>,
      snapshot.docs.first.id,
    );
  }

  @override
  Future<EmailTemplate?> getEmailTemplateById(String id) async {
    final doc = await _templatesCollection.doc(id).get();
    if (!doc.exists) return null;
    return EmailTemplate.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  @override
  Future<String> createEmailTemplate(EmailTemplate template) async {
    final user = await _getAuthenticatedUser();
    await _checkContentPermission(user);
    final doc = await _templatesCollection.add(template.toMap());

    // Log audit event
    await _auditService.logEvent(
      action: AuditAction.create,
      entityType: AuditEntityType.email_template,
      entityId: doc.id,
      entityName: template.name,
      changes: {
        'name': template.name,
        'type': template.type.name,
        'isActive': template.isActive,
      },
    );

    return doc.id;
  }

  @override
  Future<void> updateEmailTemplate(String id, EmailTemplate template) async {
    final user = await _getAuthenticatedUser();
    await _checkContentPermission(user);

    // Get previous state for change tracking
    final previousDoc = await _templatesCollection.doc(id).get();
    final previousData = previousDoc.exists ? previousDoc.data() as Map<String, dynamic> : null;

    await _templatesCollection.doc(id).update(template.toMap());

    // Log audit event
    await _auditService.logEvent(
      action: AuditAction.update,
      entityType: AuditEntityType.email_template,
      entityId: id,
      entityName: template.name,
      changes: {
        'previous': previousData,
        'current': template.toMap(),
      },
    );
  }

  @override
  Future<void> deleteEmailTemplate(String id) async {
    final user = await _getAuthenticatedUser();
    await _checkContentPermission(user);

    // Get template details before deletion
    final doc = await _templatesCollection.doc(id).get();
    final template = doc.exists
        ? EmailTemplate.fromMap(doc.data() as Map<String, dynamic>, id)
        : null;

    await _templatesCollection.doc(id).delete();

    // Log audit event
    if (template != null) {
      await _auditService.logEvent(
        action: AuditAction.delete,
        entityType: AuditEntityType.email_template,
        entityId: id,
        entityName: template.name,
        changes: {
          'deleted': template.toMap(),
        },
      );
    }
  }

  // ========== SEARCH OPERATIONS ==========

  @override
  Future<List<ContentPage>> searchPages(String query) async {
    // Firestore doesn't support full-text search natively
    // This is a basic implementation - consider using Algolia or similar for production
    final lowerQuery = query.toLowerCase();
    final snapshot = await _pagesCollection.get();
    return snapshot.docs
        .map(
          (doc) =>
              ContentPage.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        )
        .where(
          (page) =>
              page.title.toLowerCase().contains(lowerQuery) ||
              page.description.toLowerCase().contains(lowerQuery) ||
              page.content.toLowerCase().contains(lowerQuery),
        )
        .toList();
  }

  @override
  Future<List<FAQ>> searchFAQs(String query) async {
    final lowerQuery = query.toLowerCase();
    final snapshot = await _faqsCollection
        .where('isActive', isEqualTo: true)
        .get();
    return snapshot.docs
        .map((doc) => FAQ.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .where(
          (faq) =>
              faq.question.toLowerCase().contains(lowerQuery) ||
              faq.answer.toLowerCase().contains(lowerQuery) ||
              faq.keywords.any((kw) => kw.toLowerCase().contains(lowerQuery)),
        )
        .toList();
  }

  // ========== BATCH OPERATIONS ==========

  @override
  Future<void> bulkPublishPages(List<String> pageIds) async {
    final user = await _getAuthenticatedUser();
    await _checkContentPermission(user);
    final batch = _firestore.batch();
    for (final id in pageIds) {
      batch.update(_pagesCollection.doc(id), {
        'status': ContentStatus.published.name,
        'publishedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();

    // Log audit event
    await _auditService.logEvent(
      action: AuditAction.bulk_publish,
      entityType: AuditEntityType.content_page,
      entityId: 'bulk',
      entityName: '${pageIds.length} pages',
      changes: {
        'pageIds': pageIds,
        'count': pageIds.length,
      },
    );
  }

  @override
  Future<void> bulkUnpublishPages(List<String> pageIds) async {
    final user = await _getAuthenticatedUser();
    await _checkContentPermission(user);
    final batch = _firestore.batch();
    for (final id in pageIds) {
      batch.update(_pagesCollection.doc(id), {
        'status': ContentStatus.draft.name,
        'publishedAt': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();

    // Log audit event
    await _auditService.logEvent(
      action: AuditAction.bulk_unpublish,
      entityType: AuditEntityType.content_page,
      entityId: 'bulk',
      entityName: '${pageIds.length} pages',
      changes: {
        'pageIds': pageIds,
        'count': pageIds.length,
      },
    );
  }

  @override
  Future<void> bulkDeletePages(List<String> pageIds) async {
    final user = await _getAuthenticatedUser();
    await _checkContentPermission(user);
    final batch = _firestore.batch();
    for (final id in pageIds) {
      batch.delete(_pagesCollection.doc(id));
    }
    await batch.commit();

    // Log audit event
    await _auditService.logEvent(
      action: AuditAction.bulk_delete,
      entityType: AuditEntityType.content_page,
      entityId: 'bulk',
      entityName: '${pageIds.length} pages',
      changes: {
        'pageIds': pageIds,
        'count': pageIds.length,
      },
    );
  }

  @override
  Future<void> bulkDeleteFAQs(List<String> faqIds) async {
    final user = await _getAuthenticatedUser();
    await _checkContentPermission(user);
    final batch = _firestore.batch();
    for (final id in faqIds) {
      batch.delete(_faqsCollection.doc(id));
    }
    await batch.commit();

    // Log audit event
    await _auditService.logEvent(
      action: AuditAction.bulk_delete,
      entityType: AuditEntityType.faq,
      entityId: 'bulk',
      entityName: '${faqIds.length} FAQs',
      changes: {
        'faqIds': faqIds,
        'count': faqIds.length,
      },
    );
  }

  // ========== ANALYTICS ==========

  @override
  Future<Map<String, int>> getContentAnalytics(String pageId) async {
    final doc = await _pagesCollection.doc(pageId).get();
    if (!doc.exists) return {};
    final page = ContentPage.fromMap(
      doc.data() as Map<String, dynamic>,
      doc.id,
    );
    return {'views': page.viewCount};
  }

  @override
  Future<Map<String, int>> getBannerAnalytics(String bannerId) async {
    final doc = await _bannersCollection.doc(bannerId).get();
    if (!doc.exists) return {};
    final banner = Banner.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    return {'impressions': banner.impressions, 'clicks': banner.clicks};
  }

  // ==================== SEEDING ====================

  /// Seed sample content data
  Future<void> seedSampleData() async {
    try {
      final now = DateTime.now();

      // Check if already seeded
      final existing = await _pagesCollection.limit(1).get();
      if (existing.docs.isNotEmpty) {
        print('Content already seeded');
        return;
      }

      // Seed Content Pages
      final pages = [
        {
          'title': 'About Us',
          'slug': 'about-us',
          'content':
              'Welcome to ShopsNPorts - your trusted online marketplace for quality products and services across Nigeria.',
          'isPublished': true,
          'viewCount': 1523,
          'createdAt': Timestamp.fromDate(
            now.subtract(const Duration(days: 30)),
          ),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'Terms and Conditions',
          'slug': 'terms-and-conditions',
          'content':
              'By using ShopsNPorts, you agree to our terms of service...',
          'isPublished': true,
          'viewCount': 892,
          'createdAt': Timestamp.fromDate(
            now.subtract(const Duration(days: 25)),
          ),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'Privacy Policy',
          'slug': 'privacy-policy',
          'content':
              'Your privacy is important to us. We collect and process your data securely...',
          'isPublished': true,
          'viewCount': 756,
          'createdAt': Timestamp.fromDate(
            now.subtract(const Duration(days: 25)),
          ),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'Shipping Policy',
          'slug': 'shipping-policy',
          'content':
              'We deliver nationwide across Nigeria within 2-5 business days...',
          'isPublished': true,
          'viewCount': 1234,
          'createdAt': Timestamp.fromDate(
            now.subtract(const Duration(days: 20)),
          ),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'Return & Refund Policy',
          'slug': 'return-refund-policy',
          'content':
              'We offer 7-day returns on eligible products. Contact support for assistance...',
          'isPublished': true,
          'viewCount': 678,
          'createdAt': Timestamp.fromDate(
            now.subtract(const Duration(days: 15)),
          ),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      ];

      for (int i = 0; i < pages.length; i++) {
        await _pagesCollection.doc('PAGE-${i + 1}').set(pages[i]);
      }

      // Seed FAQs
      final faqs = [
        {
          'question': 'How do I create an account?',
          'answer':
              'Click on Sign Up, fill in your details, and verify your email address.',
          'category': 'account',
          'displayOrder': 1,
          'isPublished': true,
          'createdAt': Timestamp.fromDate(
            now.subtract(const Duration(days: 20)),
          ),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'question': 'What payment methods do you accept?',
          'answer':
              'We accept bank transfers, card payments, and mobile money (USSD).',
          'category': 'payment',
          'displayOrder': 2,
          'isPublished': true,
          'createdAt': Timestamp.fromDate(
            now.subtract(const Duration(days: 18)),
          ),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'question': 'How long does shipping take?',
          'answer':
              'Delivery takes 2-5 business days depending on your location.',
          'category': 'shipping',
          'displayOrder': 3,
          'isPublished': true,
          'createdAt': Timestamp.fromDate(
            now.subtract(const Duration(days: 18)),
          ),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'question': 'Can I track my order?',
          'answer':
              'Yes! You will receive a tracking number via email once your order ships.',
          'category': 'shipping',
          'displayOrder': 4,
          'isPublished': true,
          'createdAt': Timestamp.fromDate(
            now.subtract(const Duration(days: 16)),
          ),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'question': 'What is your return policy?',
          'answer':
              'We offer 7-day returns on eligible items in original condition.',
          'category': 'returns',
          'displayOrder': 5,
          'isPublished': true,
          'createdAt': Timestamp.fromDate(
            now.subtract(const Duration(days: 15)),
          ),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'question': 'How do I become an affiliate?',
          'answer':
              'Apply through our Affiliate Program page and wait for approval.',
          'category': 'affiliate',
          'displayOrder': 6,
          'isPublished': true,
          'createdAt': Timestamp.fromDate(
            now.subtract(const Duration(days: 12)),
          ),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'question': 'How do I reset my password?',
          'answer':
              'Click on Forgot Password on the login page and follow the email instructions.',
          'category': 'account',
          'displayOrder': 7,
          'isPublished': true,
          'createdAt': Timestamp.fromDate(
            now.subtract(const Duration(days: 10)),
          ),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      ];

      for (int i = 0; i < faqs.length; i++) {
        await _faqsCollection.doc('FAQ-${i + 1}').set(faqs[i]);
      }

      // Seed Banners
      final banners = [
        {
          'title': 'Welcome to ShopsNPorts',
          'imageUrl':
              'https://via.placeholder.com/1200x400/4CAF50/FFFFFF?text=Welcome+Banner',
          'linkUrl': '/welcome',
          'placement': 'home',
          'active': true,
          'displayOrder': 1,
          'startDate': Timestamp.fromDate(
            now.subtract(const Duration(days: 30)),
          ),
          'endDate': Timestamp.fromDate(now.add(const Duration(days: 60))),
          'impressions': 15230,
          'clicks': 892,
          'createdAt': Timestamp.fromDate(
            now.subtract(const Duration(days: 30)),
          ),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'Flash Sale - 50% Off',
          'imageUrl':
              'https://via.placeholder.com/1200x400/FF5722/FFFFFF?text=Flash+Sale',
          'linkUrl': '/sale',
          'placement': 'home',
          'active': true,
          'displayOrder': 2,
          'startDate': Timestamp.fromDate(
            now.subtract(const Duration(days: 5)),
          ),
          'endDate': Timestamp.fromDate(now.add(const Duration(days: 2))),
          'impressions': 8920,
          'clicks': 1456,
          'createdAt': Timestamp.fromDate(
            now.subtract(const Duration(days: 5)),
          ),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'Affiliate Program',
          'imageUrl':
              'https://via.placeholder.com/800x300/2196F3/FFFFFF?text=Join+Affiliate+Program',
          'linkUrl': '/affiliate',
          'placement': 'sidebar',
          'active': true,
          'displayOrder': 3,
          'startDate': Timestamp.fromDate(
            now.subtract(const Duration(days: 20)),
          ),
          'endDate': Timestamp.fromDate(now.add(const Duration(days: 40))),
          'impressions': 5670,
          'clicks': 234,
          'createdAt': Timestamp.fromDate(
            now.subtract(const Duration(days: 20)),
          ),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'title': 'Free Shipping',
          'imageUrl':
              'https://via.placeholder.com/1200x200/9C27B0/FFFFFF?text=Free+Shipping+Over+N10000',
          'linkUrl': '/shipping',
          'placement': 'home',
          'active': true,
          'displayOrder': 4,
          'startDate': Timestamp.fromDate(
            now.subtract(const Duration(days: 15)),
          ),
          'endDate': Timestamp.fromDate(now.add(const Duration(days: 45))),
          'impressions': 6780,
          'clicks': 456,
          'createdAt': Timestamp.fromDate(
            now.subtract(const Duration(days: 15)),
          ),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      ];

      for (int i = 0; i < banners.length; i++) {
        await _bannersCollection.doc('BANNER-${i + 1}').set(banners[i]);
      }

      // Seed Email Templates
      final templates = [
        {
          'name': 'Welcome Email',
          'subject': 'Welcome to ShopsNPorts!',
          'body':
              'Hi {{name}},\n\nThank you for joining ShopsNPorts! We\'re excited to have you.\n\nBest regards,\nShopsNPorts Team',
          'category': 'user',
          'isActive': true,
          'createdAt': Timestamp.fromDate(
            now.subtract(const Duration(days: 30)),
          ),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Order Confirmation',
          'subject': 'Order Confirmed - {{orderNumber}}',
          'body':
              'Hi {{customerName}},\n\nYour order {{orderNumber}} has been confirmed!\n\nTotal: {{total}}\n\nThank you for shopping with us!',
          'category': 'order',
          'isActive': true,
          'createdAt': Timestamp.fromDate(
            now.subtract(const Duration(days: 28)),
          ),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Shipping Notification',
          'subject': 'Your Order Has Shipped!',
          'body':
              'Hi {{customerName}},\n\nGreat news! Your order {{orderNumber}} has shipped.\n\nTracking: {{trackingNumber}}\n\nEstimated delivery: {{deliveryDate}}',
          'category': 'shipping',
          'isActive': true,
          'createdAt': Timestamp.fromDate(
            now.subtract(const Duration(days: 28)),
          ),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Invoice',
          'subject': 'Invoice {{invoiceNumber}} - ShopsNPorts',
          'body':
              'Hi {{customerName}},\n\nPlease find your invoice attached.\n\nInvoice: {{invoiceNumber}}\nAmount: {{amount}}\nDue Date: {{dueDate}}',
          'category': 'billing',
          'isActive': true,
          'createdAt': Timestamp.fromDate(
            now.subtract(const Duration(days: 25)),
          ),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Password Reset',
          'subject': 'Reset Your Password',
          'body':
              'Hi {{name}},\n\nClick the link below to reset your password:\n{{resetLink}}\n\nThis link expires in 1 hour.',
          'category': 'security',
          'isActive': true,
          'createdAt': Timestamp.fromDate(
            now.subtract(const Duration(days: 30)),
          ),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Payout Notification',
          'subject': 'Payout Processed - ₦{{amount}}',
          'body':
              'Hi {{affiliateName}},\n\nYour payout of ₦{{amount}} has been processed!\n\nPayout ID: {{payoutId}}\nDate: {{date}}',
          'category': 'payout',
          'isActive': true,
          'createdAt': Timestamp.fromDate(
            now.subtract(const Duration(days: 20)),
          ),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Affiliate Welcome',
          'subject': 'Welcome to ShopsNPorts Affiliate Program!',
          'body':
              'Hi {{affiliateName}},\n\nCongratulations! Your affiliate application has been approved.\n\nYour referral code: {{referralCode}}\n\nStart earning today!',
          'category': 'affiliate',
          'isActive': true,
          'createdAt': Timestamp.fromDate(
            now.subtract(const Duration(days: 22)),
          ),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      ];

      for (int i = 0; i < templates.length; i++) {
        await _templatesCollection.doc('TEMPLATE-${i + 1}').set(templates[i]);
      }

      print(
        '✅ Seeded ${pages.length} pages, ${faqs.length} FAQs, ${banners.length} banners, ${templates.length} email templates',
      );
    } catch (e) {
      print('Error seeding content: $e');
      rethrow;
    }
  }
}

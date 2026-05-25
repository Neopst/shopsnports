import 'package:admin_dashboard/features/content/data/models/index.dart';

/// Abstract interface for content repository operations
abstract class IContentRepository {
  // ContentPage operations
  Future<List<ContentPage>> getPages({int limit = 20, int offset = 0});
  Future<List<ContentPage>> getPublishedPages({int limit = 20, int offset = 0});
  Future<ContentPage?> getPageBySlug(String slug);
  Future<ContentPage?> getPageById(String id);
  Future<String> createPage(ContentPage page);
  Future<void> updatePage(String id, ContentPage page);
  Future<void> deletePage(String id);
  Future<void> publishPage(String id);
  Future<void> unpublishPage(String id);
  Future<void> incrementPageView(String id);

  // Banner operations
  Future<List<Banner>> getBanners({int limit = 50});
  Future<List<Banner>> getActiveBanners();
  Future<List<Banner>> getBannersByPlacement(BannerPlacement placement);
  Future<String> createBanner(Banner banner);
  Future<void> updateBanner(String id, Banner banner);
  Future<void> deleteBanner(String id);
  Future<void> recordBannerImpression(String id);
  Future<void> recordBannerClick(String id);

  // FAQ operations
  Future<List<FAQ>> getFAQs({int limit = 100});
  Future<List<FAQ>> getFAQsByCategory(String category);
  Future<List<String>> getFAQCategories();
  Future<String> createFAQ(FAQ faq);
  Future<void> updateFAQ(String id, FAQ faq);
  Future<void> deleteFAQ(String id);
  Future<void> incrementFAQView(String id);

  // Email Template operations
  Future<List<EmailTemplate>> getEmailTemplates();
  Future<EmailTemplate?> getEmailTemplate(EmailTemplateType type);
  Future<EmailTemplate?> getEmailTemplateById(String id);
  Future<String> createEmailTemplate(EmailTemplate template);
  Future<void> updateEmailTemplate(String id, EmailTemplate template);
  Future<void> deleteEmailTemplate(String id);

  // Search operations
  Future<List<ContentPage>> searchPages(String query);
  Future<List<FAQ>> searchFAQs(String query);

  // Batch operations
  Future<void> bulkPublishPages(List<String> pageIds);
  Future<void> bulkUnpublishPages(List<String> pageIds);
  Future<void> bulkDeletePages(List<String> pageIds);
  Future<void> bulkDeleteFAQs(List<String> faqIds);

  // Analytics
  Future<Map<String, int>> getContentAnalytics(String pageId);
  Future<Map<String, int>> getBannerAnalytics(String bannerId);
}

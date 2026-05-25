import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:admin_dashboard/features/content/presentation/providers/content_providers.dart';
import 'package:admin_dashboard/features/content/data/models/index.dart';
import 'package:admin_dashboard/features/content/data/models/banner.dart'
    as content_banner;
import '../widgets/banner_form_dialog.dart';
import '../../../../services/banner_storage_service.dart';
import '../widgets/content_page_form_dialog.dart';
import '../widgets/email_template_form_dialog.dart';
import '../widgets/email_template_preview_dialog.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ContentDashboardScreen extends ConsumerWidget {
  const ContentDashboardScreen({super.key});

  static void _addBanner(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<content_banner.Banner>(
      context: context,
      builder: (context) => const BannerFormDialog(),
    );
    if (result != null && context.mounted) {
      // persist to Firestore via repository
      final repository = ref.read(contentRepositoryProvider);
      try {
        await repository.createBanner(result);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Banner "${result.title}" created')),
        );
        // refresh the banner lists so UI updates immediately
        ref.refresh(bannersProvider);
        ref.refresh(activeBannersProvider);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create banner: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  static void _addContentPage(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<ContentPage>(
      context: context,
      builder: (context) => const ContentPageFormDialog(),
    );
    if (result != null && context.mounted) {
      try {
        final repository = ref.read(contentRepositoryProvider);
        await repository.createPage(result);
        ref.refresh(contentPagesProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Page "${result.title}" created'), backgroundColor: Colors.green),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create page: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  static void _addEmailTemplate(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<EmailTemplate>(
      context: context,
      builder: (context) => const EmailTemplateFormDialog(),
    );
    if (result != null && context.mounted) {
      try {
        final repository = ref.read(contentRepositoryProvider);
        await repository.createEmailTemplate(result);
        ref.refresh(emailTemplatesProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Template "${result.name}" created'), backgroundColor: Colors.green),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create template: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentPagesAsync = ref.watch(contentPagesProvider);
    final bannersAsync = ref.watch(bannersProvider);
    final faqsAsync = ref.watch(faqsProvider);
    final emailTemplatesAsync = ref.watch(emailTemplatesProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        padding: EdgeInsets.all(
          MediaQuery.of(context).size.width < 600 ? 16 : 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            // Statistics Grid - Responsive
            LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = 4;
                if (constraints.maxWidth < 600) {
                  crossAxisCount = 1;
                } else if (constraints.maxWidth < 900) {
                  crossAxisCount = 2;
                } else if (constraints.maxWidth < 1200) {
                  crossAxisCount = 3;
                }
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: constraints.maxWidth < 600 ? 3 : 1.5,
                  children: [
                    _StatCard(
                      title: 'Total Pages',
                      value: contentPagesAsync.maybeWhen(
                        data: (pages) => pages.length.toString(),
                        orElse: () => '0',
                      ),
                      icon: Icons.description,
                      color: Colors.blue,
                    ),
                    _StatCard(
                      title: 'Published Pages',
                      value: contentPagesAsync.maybeWhen(
                        data: (pages) =>
                            pages.where((p) => p.isPublished).length.toString(),
                        orElse: () => '0',
                      ),
                      icon: Icons.check_circle,
                      color: Colors.green,
                    ),
                    _StatCard(
                      title: 'Active Banners',
                      value: bannersAsync.maybeWhen(
                        data: (banners) =>
                            banners.where((b) => b.active).length.toString(),
                        orElse: () => '0',
                      ),
                      icon: Icons.image,
                      color: Colors.orange,
                    ),
                    _StatCard(
                      title: 'FAQs',
                      value: faqsAsync.maybeWhen(
                        data: (faqs) => faqs.length.toString(),
                        orElse: () => '0',
                      ),
                      icon: Icons.help,
                      color: Colors.purple,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),
            // Content Pages Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const _SectionTitle(title: 'Content Pages'),
                ElevatedButton.icon(
                  onPressed: () => _addContentPage(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Page'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            contentPagesAsync.when(
              data: (pages) => _PagesTable(pages: pages),
              loading: () => const _LoadingCard(),
              error: (e, st) => _ErrorCard(error: e.toString()),
            ),
            const SizedBox(height: 32),
            // Banners Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const _SectionTitle(title: 'Banners'),
                ElevatedButton.icon(
                  onPressed: () => _addBanner(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Banner'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            bannersAsync.when(
              data: (banners) => _BannersTable(banners: banners),
              loading: () => const _LoadingCard(),
              error: (e, st) => _ErrorCard(error: e.toString()),
            ),
            const SizedBox(height: 32),
            // Email Templates Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const _SectionTitle(title: 'Email Templates'),
                ElevatedButton.icon(
                  onPressed: () => _addEmailTemplate(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Template'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            emailTemplatesAsync.when(
              data: (templates) => _EmailTemplatesTable(templates: templates),
              loading: () => const _LoadingCard(),
              error: (e, st) => _ErrorCard(error: e.toString()),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
          border: Border(top: BorderSide(color: color, width: 4)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }
}

class _PagesTable extends ConsumerWidget {
  final List<ContentPage> pages;

  const _PagesTable({required this.pages});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (pages.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No content pages found'),
        ),
      );
    }

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Title')),
            DataColumn(label: Text('Slug')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Created')),
            DataColumn(label: Text('Actions')),
          ],
          rows: pages.map((page) {
            return DataRow(
              cells: [
                DataCell(Text(page.title)),
                DataCell(Text(page.slug)),
                DataCell(
                  Chip(
                    label: Text(page.isPublished ? 'Published' : 'Draft'),
                    backgroundColor: page.isPublished
                        ? Colors.green.shade100
                        : Colors.orange.shade100,
                    labelStyle: TextStyle(
                      color: page.isPublished
                          ? Colors.green[700]
                          : Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                DataCell(Text(page.createdAt.toString().split(' ')[0])),
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: () async {
                          final result = await showDialog<ContentPage>(
                            context: context,
                            builder: (context) =>
                                ContentPageFormDialog(page: page),
                          );
                          if (result != null && context.mounted) {
                            try {
                              final repository = ref.read(contentRepositoryProvider);
                              await repository.updatePage(page.id, result);
                              ref.refresh(contentPagesProvider);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Page "${result.title}" updated'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to update page: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 18),
                        color: Colors.red,
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Page'),
                              content: Text(
                                'Delete "${page.title}"? This cannot be undone.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true && context.mounted) {
                            try {
                              final repository = ref.read(contentRepositoryProvider);
                              await repository.deletePage(page.id);
                              ref.refresh(contentPagesProvider);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Page "${page.title}" deleted'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to delete page: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _BannersTable extends ConsumerWidget {
  final List<content_banner.Banner> banners;

  const _BannersTable({required this.banners});

  /// Resolve image URL (handle storage paths vs full URLs)
  Future<String> _resolveImageUrl(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) return '';
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }
    // It's a storage path, get download URL
    try {
      final ref = FirebaseStorage.instance.ref().child(imageUrl);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Failed to resolve image URL: $e');
      return '';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (banners.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No banners found'),
        ),
      );
    }

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Title')),
            DataColumn(label: Text('Placement')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Image')),
            DataColumn(label: Text('Actions')),
          ],
          rows: banners.map((banner) {
            return DataRow(
              cells: [
                DataCell(Text(banner.title)),
                DataCell(Text(banner.placement.toString().split('.').last)),
                DataCell(
                  GestureDetector(
                    onTap: () async {
                      // Quick toggle active/inactive
                      final updated = banner.copyWith(
                        active: !banner.active,
                      );
                      try {
                        await ref.read(contentRepositoryProvider).updateBanner(
                              banner.id,
                              updated,
                            );
                        ref.refresh(bannersProvider);
                        ref.refresh(activeBannersProvider);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Banner "${banner.title}" ${updated.active ? 'activated' : 'deactivated'}',
                            ),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Toggle failed: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    child: Chip(
                      label: Text(banner.active ? 'Active' : 'Inactive'),
                      backgroundColor: banner.active
                          ? Colors.green.shade100
                          : Colors.grey.shade200,
                      labelStyle: TextStyle(
                        color: banner.active ? Colors.green[700] : Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                      deleteIcon: Icon(
                        banner.active ? Icons.visibility : Icons.visibility_off,
                        size: 16,
                      ),
                      onDeleted: banner.active
                          ? () {}
                          : null, // Visual indicator that it's clickable
                    ),
                  ),
                ),
                DataCell(
                  (banner.imageUrl?.isNotEmpty ?? false)
                      ? FutureBuilder<String>(
                          future: _resolveImageUrl(banner.imageUrl),
                          builder: (context, snapshot) {
                            final url = snapshot.data ?? '';
                            if (url.isEmpty) {
                              return const Icon(Icons.broken_image, size: 24);
                            }
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.network(
                                url,
                                width: 50,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.image_not_supported, size: 24),
                              ),
                            );
                          },
                        )
                      : const Text('No image'),
                ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: () async {
                          final result =
                              await showDialog<content_banner.Banner>(
                                context: context,
                                builder: (context) =>
                                    BannerFormDialog(banner: banner),
                              );
                          if (result != null && context.mounted) {
                            final repository = ref.read(
                              contentRepositoryProvider,
                            );
                            try {
                              await repository.updateBanner(banner.id, result);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Banner "${result.title}" updated',
                                  ),
                                ),
                              );
                              ref.refresh(bannersProvider);
                              ref.refresh(activeBannersProvider);
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Update failed: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 18),
                        color: Colors.red,
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Banner'),
                              content: Text(
                                'Delete "${banner.title}"? This cannot be undone.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true && context.mounted) {
                            final repository = ref.read(
                              contentRepositoryProvider,
                            );
                            try {
                              // remove storage file first if present
                              if (banner.imageUrl != null &&
                                  banner.imageUrl!.isNotEmpty) {
                                await BannerStorageService.deleteBannerImage(
                                  banner.imageUrl!,
                                );
                              }
                              await repository.deleteBanner(banner.id);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Banner "${banner.title}" deleted',
                                  ),
                                ),
                              );
                              ref.refresh(bannersProvider);
                              ref.refresh(activeBannersProvider);
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Delete failed: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _EmailTemplatesTable extends ConsumerWidget {
  final List<EmailTemplate> templates;

  const _EmailTemplatesTable({required this.templates});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (templates.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No email templates found'),
        ),
      );
    }

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Template Type')),
            DataColumn(label: Text('Subject')),
            DataColumn(label: Text('Created')),
            DataColumn(label: Text('Actions')),
          ],
          rows: templates.map((template) {
            return DataRow(
              cells: [
                DataCell(Text(template.type.toString().split('.').last)),
                DataCell(Text(template.subject)),
                DataCell(Text(template.createdAt.toString().split(' ')[0])),
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.preview, size: 18),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) =>
                                EmailTemplatePreviewDialog(template: template),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: () async {
                          final result = await showDialog<EmailTemplate>(
                            context: context,
                            builder: (context) =>
                                EmailTemplateFormDialog(template: template),
                          );
                          if (result != null && context.mounted) {
                            try {
                              final repository = ref.read(contentRepositoryProvider);
                              await repository.updateEmailTemplate(template.id, result);
                              ref.refresh(emailTemplatesProvider);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Template "${result.name}" updated'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to update template: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 18),
                        color: Colors.red,
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Template'),
                              content: Text(
                                'Delete "${template.name}"? This cannot be undone.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true && context.mounted) {
                            try {
                              final repository = ref.read(contentRepositoryProvider);
                              await repository.deleteEmailTemplate(template.id);
                              ref.refresh(emailTemplatesProvider);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Template "${template.name}" deleted'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to delete template: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: SizedBox(
          height: 50,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String error;

  const _ErrorCard({required this.error});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text('Error: $error', style: const TextStyle(color: Colors.red)),
      ),
    );
  }
}

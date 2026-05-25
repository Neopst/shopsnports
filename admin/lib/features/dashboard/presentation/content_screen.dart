// lib/features/dashboard/presentation/content_screen.dart
// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../content/presentation/providers/content_providers.dart';

class ContentScreen extends ConsumerWidget {
  const ContentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use real content data from providers
    final pagesAsync = ref.watch(contentPagesProvider);
    final bannersAsync = ref.watch(bannersProvider);
    final faqsAsync = ref.watch(faqsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 24),

          // Content Pages Section
          _buildSectionTitle('Content Pages'),
          const SizedBox(height: 12),
          pagesAsync.when(
            data: (pages) => _buildPagesList(pages.length),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => _buildErrorCard('Failed to load pages'),
          ),
          const SizedBox(height: 24),

          // Banners Section
          _buildSectionTitle('Active Banners'),
          const SizedBox(height: 12),
          bannersAsync.when(
            data: (banners) => _buildBannersList(banners.length),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => _buildErrorCard('Failed to load banners'),
          ),
          const SizedBox(height: 24),

          // FAQs Section
          _buildSectionTitle('FAQs'),
          const SizedBox(height: 12),
          faqsAsync.when(
            data: (faqs) => _buildFaqsList(faqs.length),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => _buildErrorCard('Failed to load FAQs'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Content Management',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Manage your website content',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.grey[700],
      ),
    );
  }

  Widget _buildPagesList(int count) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.description, color: Colors.blue),
        title: Text('$count Pages'),
        subtitle: const Text('Content pages available'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  Widget _buildBannersList(int count) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.image, color: Colors.green),
        title: Text('$count Banners'),
        subtitle: const Text('Active banner images'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  Widget _buildFaqsList(int count) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.help, color: Colors.orange),
        title: Text('$count FAQs'),
        subtitle: const Text('Frequently asked questions'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error, color: Colors.red[400]),
            const SizedBox(width: 12),
            Text(message, style: TextStyle(color: Colors.red[400])),
          ],
        ),
      ),
    );
  }
}
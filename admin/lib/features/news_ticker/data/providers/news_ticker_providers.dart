import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/riverpod.dart';
import '../models/news_ticker.dart';
import '../repositories/news_ticker_repository_firestore.dart';

final newsTickerRepositoryProvider = Provider((ref) {
  return NewsTickerRepositoryFirestore();
});

// All news items
final allNewsItemsProvider = FutureProvider((ref) async {
  final repository = ref.watch(newsTickerRepositoryProvider);
  return repository.getAllNewsItems();
});

// Published news items only
final activeNewsItemsProvider = FutureProvider((ref) async {
  final repository = ref.watch(newsTickerRepositoryProvider);
  return repository.getPublishedNewsItems();
});

// Filter class for news ticker list
class NewsTickerFilter {
  final bool? isActive;
  final String? searchQuery;

  NewsTickerFilter({this.isActive, this.searchQuery});

  NewsTickerFilter copyWith({
    bool? Function()? isActive,
    String? Function()? searchQuery,
  }) {
    return NewsTickerFilter(
      isActive: isActive != null ? isActive() : this.isActive,
      searchQuery: searchQuery != null ? searchQuery() : this.searchQuery,
    );
  }
}

// Filtered news items based on internal state
// Note: Filter state is managed in the screen widget itself
final filteredNewsItemsProvider = FutureProvider<List<NewsTicker>>((ref) async {
  // Just return all items - screen handles filtering
  final repository = ref.watch(newsTickerRepositoryProvider);
  return repository.getAllNewsItems();
});

// Single news item by ID
final newsItemByIdProvider = FutureProvider.family<NewsTicker?, String>((
  ref,
  id,
) async {
  final repository = ref.watch(newsTickerRepositoryProvider);
  return repository.getNewsItemById(id);
});

// Create news item
final createNewsItemProvider = FutureProvider.family<NewsTicker, NewsTicker>((
  ref,
  newsTicker,
) async {
  final repository = ref.watch(newsTickerRepositoryProvider);
  final created = await repository.createNewsItem(newsTicker);

  // Invalidate cache
  ref.invalidate(allNewsItemsProvider);
  ref.invalidate(activeNewsItemsProvider);
  ref.invalidate(filteredNewsItemsProvider);

  return created;
});

// Update news item
final updateNewsItemProvider = FutureProvider.family<NewsTicker, NewsTicker>((
  ref,
  newsTicker,
) async {
  final repository = ref.watch(newsTickerRepositoryProvider);
  final updated = await repository.updateNewsItem(newsTicker);

  // Invalidate cache
  ref.invalidate(allNewsItemsProvider);
  ref.invalidate(activeNewsItemsProvider);
  ref.invalidate(filteredNewsItemsProvider);
  ref.invalidate(newsItemByIdProvider(newsTicker.id));

  return updated;
});

// Delete news item
final deleteNewsItemProvider = FutureProvider.family<void, String>((
  ref,
  id,
) async {
  final repository = ref.watch(newsTickerRepositoryProvider);
  await repository.deleteNewsItem(id);

  // Invalidate cache
  ref.invalidate(allNewsItemsProvider);
  ref.invalidate(activeNewsItemsProvider);
  ref.invalidate(filteredNewsItemsProvider);
  ref.invalidate(newsItemByIdProvider(id));
});

// Archive news item
final archiveNewsItemProvider = FutureProvider.family<NewsTicker, String>((
  ref,
  id,
) async {
  final repository = ref.watch(newsTickerRepositoryProvider);
  final archived = await repository.archiveNewsItem(id);

  // Invalidate cache
  ref.invalidate(allNewsItemsProvider);
  ref.invalidate(activeNewsItemsProvider);
  ref.invalidate(filteredNewsItemsProvider);
  ref.invalidate(newsItemByIdProvider(id));

  return archived;
});

// Publish news item
final publishNewsItemProvider = FutureProvider.family<NewsTicker, String>((
  ref,
  id,
) async {
  final repository = ref.watch(newsTickerRepositoryProvider);
  final published = await repository.publishNewsItem(id);

  // Invalidate cache
  ref.invalidate(allNewsItemsProvider);
  ref.invalidate(activeNewsItemsProvider);
  ref.invalidate(filteredNewsItemsProvider);
  ref.invalidate(newsItemByIdProvider(id));

  return published;
});

// Dashboard stats for news ticker
final newsTickerStatsProvider = FutureProvider((ref) async {
  final repository = ref.watch(newsTickerRepositoryProvider);
  final allItems = await repository.getAllNewsItems();

  final active = allItems
      .where((item) => item.isActive)
      .length;
  final inactive = allItems
      .where((item) => !item.isActive)
      .length;

  return {
    'total': allItems.length,
    'active': active,
    'inactive': inactive,
    'totalViews': allItems.fold<int>(0, (sum, item) => sum + item.viewCount),
  };
});

// ============================================
// FIRESTORE REAL-TIME STREAM PROVIDERS
// ============================================

// Firestore repository provider
final newsTickerRepositoryFirestoreProvider = Provider((ref) {
  return NewsTickerRepositoryFirestore();
});

// Stream all news items for real-time updates
final streamAllNewsItemsProvider = StreamProvider<List<NewsTicker>>((ref) {
  final repository = ref.watch(newsTickerRepositoryProvider);
  return repository.streamNewsItems();
});

// Stream published news items for real-time updates
final streamPublishedNewsItemsProvider = StreamProvider<List<NewsTicker>>((ref) {
  final repository = ref.watch(newsTickerRepositoryProvider);
  return repository.streamPublishedNewsItems();
});

// Firestore: Get all news items (one-time fetch)
final allNewsItemsFirestoreProvider = FutureProvider<List<NewsTicker>>((
  ref,
) async {
  final repository = ref.watch(newsTickerRepositoryFirestoreProvider);
  return repository.getAllNewsItems();
});

// Firestore: Get published news items (one-time fetch)
final publishedNewsItemsFirestoreProvider = FutureProvider<List<NewsTicker>>((
  ref,
) async {
  final repository = ref.watch(newsTickerRepositoryFirestoreProvider);
  return repository.getPublishedNewsItems();
});

// Firestore: Get single news item by ID
final newsItemByIdFirestoreProvider =
    FutureProvider.family<NewsTicker?, String>((ref, id) async {
      final repository = ref.watch(newsTickerRepositoryFirestoreProvider);
      return repository.getNewsItemById(id);
    });

// Firestore: Create news item
final createNewsItemFirestoreProvider =
    FutureProvider.family<NewsTicker, NewsTicker>((ref, newsTicker) async {
      final repository = ref.watch(newsTickerRepositoryFirestoreProvider);
      final created = await repository.createNewsItem(newsTicker);

      // Invalidate cache
      ref.invalidate(allNewsItemsFirestoreProvider);
      ref.invalidate(publishedNewsItemsFirestoreProvider);

      return created;
    });

// Firestore: Update news item
final updateNewsItemFirestoreProvider =
    FutureProvider.family<NewsTicker, NewsTicker>((ref, newsTicker) async {
      final repository = ref.watch(newsTickerRepositoryFirestoreProvider);
      final updated = await repository.updateNewsItem(newsTicker);

      // Invalidate cache
      ref.invalidate(allNewsItemsFirestoreProvider);
      ref.invalidate(publishedNewsItemsFirestoreProvider);
      ref.invalidate(newsItemByIdFirestoreProvider(newsTicker.id));

      return updated;
    });

// Firestore: Delete news item
final deleteNewsItemFirestoreProvider = FutureProvider.family<void, String>((
  ref,
  id,
) async {
  final repository = ref.watch(newsTickerRepositoryFirestoreProvider);
  await repository.deleteNewsItem(id);

  // Invalidate cache
  ref.invalidate(allNewsItemsFirestoreProvider);
  ref.invalidate(publishedNewsItemsFirestoreProvider);
  ref.invalidate(newsItemByIdFirestoreProvider(id));
});

// Firestore: Archive news item
final archiveNewsItemFirestoreProvider =
    FutureProvider.family<NewsTicker, String>((ref, id) async {
      final repository = ref.watch(newsTickerRepositoryFirestoreProvider);
      final archived = await repository.archiveNewsItem(id);

      // Invalidate cache
      ref.invalidate(allNewsItemsFirestoreProvider);
      ref.invalidate(publishedNewsItemsFirestoreProvider);
      ref.invalidate(newsItemByIdFirestoreProvider(id));

      return archived;
    });

// Firestore: Publish news item
final publishNewsItemFirestoreProvider =
    FutureProvider.family<NewsTicker, String>((ref, id) async {
      final repository = ref.watch(newsTickerRepositoryFirestoreProvider);
      final published = await repository.publishNewsItem(id);

      // Invalidate cache
      ref.invalidate(allNewsItemsFirestoreProvider);
      ref.invalidate(publishedNewsItemsFirestoreProvider);
      ref.invalidate(newsItemByIdFirestoreProvider(id));

      return published;
    });

// Firestore: Schedule news item
final scheduleNewsItemFirestoreProvider =
    FutureProvider.family<NewsTicker, ({String id, DateTime publishAt})>((
      ref,
      params,
    ) async {
      final repository = ref.watch(newsTickerRepositoryFirestoreProvider);
      final scheduled = await repository.scheduleNewsItem(
        text: params.id,
        scheduledFor: params.publishAt,
        priority: 1,
        createdBy: 'system',
      );

      // Invalidate cache
      ref.invalidate(allNewsItemsFirestoreProvider);
      ref.invalidate(publishedNewsItemsFirestoreProvider);
      ref.invalidate(newsItemByIdFirestoreProvider(params.id));

      return scheduled;
    });

// Firestore: Dashboard stats
final newsTickerStatsFirestoreProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final repository = ref.watch(newsTickerRepositoryFirestoreProvider);
  return repository.getNewsStatistics();
});

// Mock stats provider for development
final newsTickerStatsMockProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final repository = ref.watch(newsTickerRepositoryProvider);
  final allItems = await repository.getAllNewsItems();

  final active = allItems
      .where((item) => item.isActive)
      .length;
  final inactive = allItems
      .where((item) => !item.isActive)
      .length;
  final expired = allItems
      .where((item) => item.isExpired)
      .length;
  final totalViews = allItems.fold<int>(0, (sum, item) => sum + item.viewCount);

  return {
    'total': allItems.length,
    'active': active,
    'inactive': inactive,
    'expired': expired,
    'totalViews': totalViews,
  };
});

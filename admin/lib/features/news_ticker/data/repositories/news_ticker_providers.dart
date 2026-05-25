import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'news_ticker_repository_firestore.dart';
import '../models/news_ticker.dart';

/// News Ticker repository provider - uses Firestore
final newsTickerRepositoryProvider = Provider<NewsTickerRepositoryFirestore>((ref) {
  return NewsTickerRepositoryFirestore();
});

/// Get all news items stream (real-time)
final newsTickerStreamProvider = StreamProvider<List<NewsTicker>>((ref) {
  final repository = ref.watch(newsTickerRepositoryProvider);
  return repository.streamNewsItems();
});

/// Get active news items stream (real-time)
final activeNewsStreamProvider = StreamProvider<List<NewsTicker>>((ref) {
  final repository = ref.watch(newsTickerRepositoryProvider);
  return repository.streamActiveNewsItems();
});

/// Get all news items (one-time fetch)
final allNewsProvider = FutureProvider<List<NewsTicker>>((ref) async {
  final repository = ref.watch(newsTickerRepositoryProvider);
  return repository.getAllNewsItems();
});

/// Get active news items (one-time fetch)
final activeNewsProvider = FutureProvider<List<NewsTicker>>((ref) async {
  final repository = ref.watch(newsTickerRepositoryProvider);
  return repository.getActiveNewsItems();
});

/// Get single news item by ID
final newsItemProvider = FutureProvider.family<NewsTicker?, String>((ref, id) async {
  final repository = ref.watch(newsTickerRepositoryProvider);
  return repository.getNewsItemById(id);
});

/// Search news items
final searchNewsProvider = FutureProvider.family<List<NewsTicker>, String>((ref, query) async {
  final repository = ref.watch(newsTickerRepositoryProvider);
  return repository.searchNewsItems(query);
});

/// Get news statistics
final newsStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(newsTickerRepositoryProvider);
  return repository.getNewsStatistics();
});

/// Filter news by active status
final newsByActiveProvider = FutureProvider.family<List<NewsTicker>, bool>((ref, isActive) async {
  final repository = ref.watch(newsTickerRepositoryProvider);
  return repository.getAllNewsItems(filterByActive: isActive);
});
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopsnports/services/news_ticker_service.dart';

/// Provider for news ticker items from Firestore
final newsTickerStreamProvider = StreamProvider<List<NewsTickerItem>>((ref) {
  return NewsTickerService().watchActiveNewsItems();
});

class NewsTicker extends ConsumerStatefulWidget {
  /// Optional list of news items. If omitted, fetches from Firestore.
  final List<String>? newsItems;

  /// Primary constructor accepts an optional list of news strings.
  const NewsTicker({super.key, this.newsItems});

  /// Convenience constructor that accepts a single raw string where items are
  /// separated by '*' (asterisk). Leading/trailing whitespace is trimmed and
  /// empty entries are ignored.
  factory NewsTicker.fromRaw(String raw, {Key? key}) {
    final parts =
        raw.split('*').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    return NewsTicker(key: key, newsItems: parts);
  }

  @override
  ConsumerState<NewsTicker> createState() => _NewsTickerState();
}

class _NewsTickerState extends ConsumerState<NewsTicker>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  AnimationController? _controller;
  Animation<double>? _animation;
  int _startAttempts = 0;

  // pixels per second
  static const double _defaultSpeed = 50.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final items = _getItems();
      if (items.isNotEmpty) {
        _startAutoScroll();
      }
    });
  }

  List<String> _getItems() {
    if (widget.newsItems != null) {
      return widget.newsItems!;
    }

    // Get items from Firestore stream
    final asyncValue = ref.read(newsTickerStreamProvider);
    return asyncValue.when(
      data: (items) => items.map((item) => item.text).toList(),
      loading: () => [],
      error: (_, __) => [],
    );
  }

  @override
  void didUpdateWidget(covariant NewsTicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.newsItems != widget.newsItems) {
      _stopAutoScroll();
      final items = _getItems();
      if (items.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoScroll());
      }
    }
  }

  void _startAutoScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    // If layout hasn't produced a scroll extent yet, retry a few times with a short delay.
    if (maxScroll <= 0) {
      if (_startAttempts < 10) {
        _startAttempts += 1;
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) _startAutoScroll();
        });
      }
      return;
    }

    // target scroll: half of the duplicated content (original list width)
    // For infinite loop, scroll to the end and seamlessly restart from beginning
    final target = maxScroll;

    final double durationSeconds = (target / _defaultSpeed);
    final int durationMs = (durationSeconds * 1000).round().clamp(1000, 600000);
    final duration = Duration(milliseconds: durationMs);

    _controller?.dispose();
    _controller = AnimationController(vsync: this, duration: duration);
    _animation = Tween<double>(begin: 0, end: target).animate(
      CurvedAnimation(parent: _controller!, curve: Curves.linear),
    )..addListener(() {
        if (_scrollController.hasClients && _animation != null) {
          _scrollController.jumpTo(_animation!.value);
        }
      });

    // When the animation completes (we reached the end of the duplicated content),
    // jump back to 0 and restart. Because we duplicated the items list, this
    // produces a seamless infinite continuous loop.
    _controller!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
        // restart from the beginning for infinite loop
        _controller?.forward(from: 0);
      }
    });

    _controller!.forward();
  }

  void _stopAutoScroll() {
    _controller?.stop();
    _controller?.dispose();
    _controller = null;
    _animation = null;
  }

  @override
  void dispose() {
    _stopAutoScroll();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get items from props or Firestore
    List<String> items = widget.newsItems ?? [];

    if (items.isEmpty) {
      // Get from Firestore stream
      final asyncValue = ref.watch(newsTickerStreamProvider);
      items = asyncValue.when(
        data: (firestoreItems) =>
            firestoreItems.map((item) => item.text).toList(),
        loading: () => ['Loading news...'],
        error: (_, __) => [],
      );
    }

    if (items.isEmpty) return const SizedBox.shrink();

    // Duplicate the list so it loops seamlessly
    final loopedItems = <String>[...items, ...items];

    return Container(
      color: Colors.orange.shade100,
      height: 36,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: 8),
          const Icon(Icons.campaign, color: Colors.orange, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: loopedItems.length,
              itemBuilder: (context, index) {
                final text = loopedItems[index];
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 20.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: Text(
                            text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14, height: 1.0),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // separator bullet between items
                        const Text('•', style: TextStyle(color: Colors.orange)),
                        const SizedBox(width: 12),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

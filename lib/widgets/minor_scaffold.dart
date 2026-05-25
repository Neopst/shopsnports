import 'package:flutter/material.dart';
import 'package:shopsnports/widgets/news_ticker.dart';
import 'package:shopsnports/widgets/main_scaffold.dart';

/// Compatibility wrapper: MinorScaffoldContent used to provide a small,
/// content-only header + optional news ticker when rendered inside a larger
/// scaffold. To consolidate scaffold logic we now forward this API to
/// `MainScaffold` while preserving the original constructor. This keeps
/// existing screen code working while centralizing scaffold behavior.
class MinorScaffoldContent extends StatelessWidget {
  final String title;
  final List<String>? newsItems;
  final Widget child;

  const MinorScaffoldContent({
    super.key,
    required this.title,
    required this.child,
    this.newsItems,
  });

  @override
  Widget build(BuildContext context) {
    final topWidget =
        (newsItems == null || newsItems!.isEmpty) ? null : const NewsTicker();

    // Build a compact app bar that matches the original MinorScaffold header
    final PreferredSizeWidget compactAppBar = PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: SafeArea(
        bottom: false,
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          height: kToolbarHeight,
          child: Row(
            children: [
              Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.black87),
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Forward to MainScaffold. Use safe defaults for currentIndex and
    // onNavTap so screens that were previously content-only can still be
    // previewed during development. Screens that require specific
    // navigation behavior should be updated to use MainScaffold directly.
    return MainScaffold(
      currentIndex: 0,
      onNavTap: (_) {},
      appBar: compactAppBar,
      topWidget: topWidget,
      body: child,
    );
  }
}

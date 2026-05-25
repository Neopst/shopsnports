import 'package:flutter/material.dart';

/// Centralized loading state management widget
///
/// Provides consistent loading UI across the app with various states:
/// - Initial loading
/// - Refreshing
/// - Loading more
/// - Error state
/// - Empty state

class LoadingStateWidget extends StatelessWidget {
  final bool isLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final String? error;
  final bool isEmpty;
  final Widget child;
  final Widget? loadingWidget;
  final Widget? emptyWidget;
  final Widget? errorWidget;
  final VoidCallback? onRetry;
  final String emptyMessage;
  final String errorMessage;

  const LoadingStateWidget({
    super.key,
    required this.isLoading,
    required this.child,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.error,
    this.isEmpty = false,
    this.loadingWidget,
    this.emptyWidget,
    this.errorWidget,
    this.onRetry,
    this.emptyMessage = 'No items found',
    this.errorMessage = 'Something went wrong',
  });

  @override
  Widget build(BuildContext context) {
    // Show error state
    if (error != null && !isRefreshing) {
      return errorWidget ??
          _buildErrorState(context, error!, onRetry, errorMessage);
    }

    // Show empty state
    if (isEmpty && !isLoading && !isRefreshing) {
      return emptyWidget ?? _buildEmptyState(context, emptyMessage);
    }

    // Show initial loading
    if (isLoading && !isRefreshing) {
      return loadingWidget ?? _buildLoadingState(context);
    }

    // Show content with optional refresh/load more indicators
    return Stack(
      children: [
        child,
        if (isRefreshing)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              backgroundColor: Colors.grey[200],
            ),
          ),
        if (isLoadingMore)
          const Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Loading more...'),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  static Widget _buildLoadingState(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading...'),
        ],
      ),
    );
  }

  static Widget _buildEmptyState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildErrorState(
    BuildContext context,
    String error,
    VoidCallback? onRetry,
    String errorMessage,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Loading overlay for modal operations
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black54,
            child: Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      if (message != null) ...[
                        const SizedBox(height: 16),
                        Text(message!),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Inline loading indicator
class InlineLoadingIndicator extends StatelessWidget {
  final String? message;

  const InlineLoadingIndicator({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          if (message != null) ...[
            const SizedBox(width: 12),
            Text(message!),
          ],
        ],
      ),
    );
  }
}

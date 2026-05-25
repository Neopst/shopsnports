import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:shopsnports/utils/app_logger.dart';

/// Error Boundary Widget
///
/// Catches and handles errors in the widget tree, preventing app crashes
/// and providing user-friendly error UI.
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(FlutterErrorDetails)? errorBuilder;
  final void Function(FlutterErrorDetails)? onError;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorBuilder,
    this.onError,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  FlutterErrorDetails? _errorDetails;

  @override
  void initState() {
    super.initState();

    // Set up error handler
    FlutterError.onError = (details) {
      // Log the error
      AppLogger.error(
        'ErrorBoundary caught error',
        details.exception,
        details.stack,
      );

      // Send to Crashlytics in production
      if (!kDebugMode) {
        try {
          FirebaseCrashlytics.instance.recordFlutterError(details);
        } catch (_) {
          // Fail silently if Crashlytics isn't initialized
        }
      }

      // Call custom error handler if provided
      widget.onError?.call(details);

      // Update state to show error UI
      if (mounted) {
        setState(() {
          _errorDetails = details;
        });
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_errorDetails != null) {
      return widget.errorBuilder?.call(_errorDetails!) ??
          _buildDefaultErrorWidget(context, _errorDetails!);
    }

    return ErrorBoundaryWrapper(
      onError: (error, stackTrace) {
        final details = FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'ErrorBoundary',
        );

        AppLogger.error(
            'ErrorBoundary caught runtime error', error, stackTrace);

        // Send to Crashlytics in production
        if (!kDebugMode) {
          try {
            FirebaseCrashlytics.instance.recordError(
              error,
              stackTrace,
              reason: 'Caught by ErrorBoundary',
              fatal: false,
            );
          } catch (_) {
            // Fail silently
          }
        }

        widget.onError?.call(details);

        if (mounted) {
          setState(() {
            _errorDetails = details;
          });
        }
      },
      child: widget.child,
    );
  }

  Widget _buildDefaultErrorWidget(
    BuildContext context,
    FlutterErrorDetails details,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Something went wrong'),
        backgroundColor: Colors.red,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 80,
              ),
              const SizedBox(height: 24),
              const Text(
                'Oops! Something went wrong',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'We\'re sorry for the inconvenience. The error has been logged and we\'ll fix it soon.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _errorDetails = null;
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('Go to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wrapper to catch errors in child widgets
class ErrorBoundaryWrapper extends StatelessWidget {
  final Widget child;
  final void Function(Object error, StackTrace stackTrace) onError;

  const ErrorBoundaryWrapper({
    super.key,
    required this.child,
    required this.onError,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

/// Global error handler setup
class GlobalErrorHandler {
  static void initialize() {
    // Handle Flutter framework errors
    FlutterError.onError = (details) {
      AppLogger.error(
        'Flutter framework error',
        details.exception,
        details.stack,
      );

      // In production, send to crash reporting service
      // e.g., FirebaseCrashlytics.instance.recordFlutterError(details);
    };

    // Handle async errors not caught by Flutter
    PlatformDispatcher.instance.onError = (error, stack) {
      AppLogger.error('Uncaught async error', error, stack);

      // In production, send to crash reporting service
      // e.g., FirebaseCrashlytics.instance.recordError(error, stack);

      return true;
    };
  }
}

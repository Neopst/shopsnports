import 'dart:async';
import 'package:flutter/material.dart';

/// App error types
enum AppErrorType {
  network,
  authentication,
  permission,
  validation,
  server,
  database,
  unknown,
}

/// App exception class
class AppException implements Exception {
  final String message;
  final String? code;
  final AppErrorType type;
  final dynamic originalError;

  const AppException({
    required this.message,
    this.code,
    this.type = AppErrorType.unknown,
    this.originalError,
  });

  @override
  String toString() => message;
}

/// Error handler service
class ErrorHandler {
  /// Handle error and return user-friendly message
  static String getMessage(dynamic error) {
    if (error is AppException) {
      return _getAppExceptionMessage(error);
    }

    if (error is FirebaseException) {
      return _getFirebaseMessage(error);
    }

    if (error is FormatException) {
      return 'Invalid data format. Please check your input.';
    }

    if (error is TimeoutException) {
      return 'Request timed out. Please check your connection and try again.';
    }

    // Default messages based on error string
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('network') || errorStr.contains('socket')) {
      return 'Network error. Please check your internet connection.';
    }

    if (errorStr.contains('permission') || errorStr.contains('denied')) {
      return 'You don\'t have permission to perform this action.';
    }

    if (errorStr.contains('not found')) {
      return 'The requested resource was not found.';
    }

    if (errorStr.contains('auth') || errorStr.contains('login')) {
      return 'Authentication failed. Please check your credentials.';
    }

    return 'An error occurred. Please try again.';
  }

  static String _getAppExceptionMessage(AppException error) {
    switch (error.type) {
      case AppErrorType.network:
        return 'Network error. Please check your internet connection.';
      case AppErrorType.authentication:
        return 'Authentication failed. Please log in again.';
      case AppErrorType.permission:
        return 'You don\'t have permission to perform this action.';
      case AppErrorType.validation:
        return error.message;
      case AppErrorType.server:
        return 'Server error. Please try again later.';
      case AppErrorType.database:
        return 'Database error. Please try again.';
      case AppErrorType.unknown:
        return error.message;
    }
  }

  static String _getFirebaseMessage(FirebaseException error) {
    final code = error.code;

    switch (code) {
      // Auth errors
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Contact support.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';

      // Firestore errors
      case 'not-found':
        return 'The requested document was not found.';
      case 'permission-denied':
        return 'You don\'t have permission for this action.';
      case 'already-exists':
        return 'This record already exists.';
      case 'cancelled':
        return 'Operation was cancelled.';
      case 'deadline-exceeded':
        return 'Request timed out. Please try again.';
      case 'resource-exceeded':
        return 'Rate limit exceeded. Please wait and try again.';
      case 'aborted':
        return 'Operation was aborted. Please try again.';
      case 'internal':
        return 'Internal error. Please try again later.';

      default:
        return 'An error occurred. Please try again.';
    }
  }

  /// Show error snackbar
  static void showSnackbar(BuildContext context, dynamic error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(getMessage(error))),
          ],
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Show success snackbar
  static void showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show warning snackbar
  static void showWarningSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange[700],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Show info snackbar
  static void showInfoSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.blue[700],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

/// Helper extension for easier error handling
extension ErrorExtension on dynamic {
  String get friendlyMessage => ErrorHandler.getMessage(this);
}

// For FirebaseException type
class FirebaseException implements Exception {
  final String code;
  final String? message;
  final dynamic original;

  const FirebaseException({
    required this.code,
    this.message,
    this.original,
  });

  @override
  String toString() => message ?? code;
}
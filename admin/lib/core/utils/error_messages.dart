// lib/core/utils/error_messages.dart
/// Standardized error messages for the app

class ErrorMessages {
  // Network errors
  static const String networkError = 'Unable to connect to the server. Please check your internet connection.';
  static const String serverError = 'Server error. Please try again later.';
  static const String timeoutError = 'Request timed out. Please try again.';

  // Authentication errors
  static const String authError = 'Authentication failed. Please log in again.';
  static const String sessionExpired = 'Your session has expired. Please log in again.';
  static const String unauthorized = 'You do not have permission to perform this action.';
  static const String invalidCredentials = 'Invalid email or password.';

  // Data errors
  static const String loadDataError = 'Failed to load data. Please try again.';
  static const String saveDataError = 'Failed to save data. Please try again.';
  static const String deleteDataError = 'Failed to delete data. Please try again.';
  static const String notFound = 'The requested item was not found.';

  // Validation errors
  static const String validationError = 'Please check your input and try again.';
  static const String requiredField = 'This field is required.';
  static const String invalidEmail = 'Please enter a valid email address.';
  static const String weakPassword = 'Password must be at least 8 characters with uppercase, lowercase, and numbers.';

  // Permission errors
  static const String permissionDenied = 'You do not have permission to perform this action.';
  static const String adminRequired = 'This action requires administrator privileges.';

  // General errors
  static const String unknownError = 'An unexpected error occurred. Please try again.';
  static const String tryAgainLater = 'Please try again later.';

  /// Get user-friendly error message from any error type
  static String getMessage(dynamic error) {
    if (error == null) return unknownError;

    final errorString = error.toString().toLowerCase();

    // Network errors
    if (errorString.contains('socket') ||
        errorString.contains('network') ||
        errorString.contains('connection')) {
      return networkError;
    }

    // Timeout errors
    if (errorString.contains('timeout') || errorString.contains('timed out')) {
      return timeoutError;
    }

    // Server errors
    if (errorString.contains('500') || errorString.contains('server error')) {
      return serverError;
    }

    // Not found
    if (errorString.contains('not found') || errorString.contains('404')) {
      return notFound;
    }

    // Auth errors
    if (errorString.contains('auth') || errorString.contains('permission')) {
      if (errorString.contains('session') || errorString.contains('expired')) {
        return sessionExpired;
      }
      if (errorString.contains('unauthorized') || errorString.contains('login')) {
        return authError;
      }
      return unauthorized;
    }

    // Firestore errors
    if (errorString.contains('firestore') || errorString.contains('database')) {
      return loadDataError;
    }

    return unknownError;
  }
}
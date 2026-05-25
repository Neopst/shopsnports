/// User-friendly error messages and success notifications
///
/// This utility provides consistent, actionable messages throughout the app
library;

class UserMessages {
  static String paymentFailed(String? rawError) {
    if (rawError == null) return 'Payment failed. Please try again.';

    final error = rawError.toLowerCase();

    if (error.contains('cancel') || error.contains('abort')) {
      return 'Payment cancelled.';
    }
    if (error.contains('insufficient') || error.contains('declined')) {
      return 'Payment declined. Please check your payment method or try another card.';
    }
    if (error.contains('network') || error.contains('connection')) {
      return 'Connection lost. Please check your internet and try again.';
    }
    if (error.contains('timeout')) {
      return 'Payment timed out. Please check your connection and try again.';
    }
    if (error.contains('card') && error.contains('invalid')) {
      return 'Invalid card details. Please check and try again.';
    }
    if (error.contains('expired')) {
      return 'Your card has expired. Please use a different payment method.';
    }
    if (error.contains('3d secure') || error.contains('authentication')) {
      return 'Payment authentication required. Please complete verification.';
    }

    return 'Payment failed: $rawError';
  }

  // Authentication Messages
  static String loginRequired() {
    return 'Please sign in to continue';
  }

  static String loginSuccess() {
    return 'Welcome back!';
  }

  static String loginFailed(String? rawError) {
    if (rawError == null) return 'Sign in failed. Please try again.';

    final error = rawError.toLowerCase();

    if (error.contains('invalid') || error.contains('wrong')) {
      return 'Invalid credentials. Please check and try again.';
    }
    if (error.contains('network') || error.contains('connection')) {
      return 'Connection error. Please check your internet.';
    }
    if (error.contains('too many')) {
      return 'Too many attempts. Please try again later.';
    }

    return 'Sign in failed: $rawError';
  }

  static String logoutSuccess() {
    return 'Signed out successfully';
  }

  // Form Validation Messages
  static String fieldRequired(String fieldName) {
    return '$fieldName is required';
  }

  static String invalidEmail() {
    return 'Please enter a valid email address';
  }

  static String invalidPhone() {
    return 'Please enter a valid phone number';
  }

  static String passwordTooShort([int minLength = 6]) {
    return 'Password must be at least $minLength characters';
  }

  static String passwordsDoNotMatch() {
    return 'Passwords do not match';
  }

  // Network/API Messages
  static String networkError() {
    return 'Connection error. Please check your internet and try again.';
  }

  static String serverError() {
    return 'Server error. Please try again later.';
  }

  static String timeoutError() {
    return 'Request timed out. Please try again.';
  }

  static String notFound(String item) {
    return '$item not found';
  }

  static String unauthorized() {
    return 'Session expired. Please sign in again.';
  }

  // Shipping Messages
  static String trackingInfo() {
    return 'Tracking information has been sent to your email';
  }

  // Generic Messages
  static String saveSuccess(String item) {
    return '$item saved successfully';
  }

  static String saveFailed(String item) {
    return 'Failed to save $item. Please try again.';
  }

  static String deleteSuccess(String item) {
    return '$item deleted successfully';
  }

  static String deleteFailed(String item) {
    return 'Failed to delete $item. Please try again.';
  }

  static String updateSuccess(String item) {
    return '$item updated successfully';
  }

  static String updateFailed(String item) {
    return 'Failed to update $item. Please try again.';
  }

  static String genericError() {
    return 'Something went wrong. Please try again.';
  }

  static String tryAgainLater() {
    return 'Something went wrong. Please try again later.';
  }
}

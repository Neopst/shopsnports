/// Base exception class for the app
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'AppException: $message (code: $code)';
}

/// Exception thrown when a Firestore operation fails
class FirestoreException extends AppException {
  const FirestoreException(super.message, {super.code, super.originalError});
}

/// Exception thrown when a user is not authenticated
class UnauthorizedException extends AppException {
  const UnauthorizedException([String message = 'User not authenticated'])
      : super(message, code: 'UNAUTHORIZED');
}

/// Exception thrown when an affiliate profile is not found
class AffiliateNotFoundException extends AppException {
  const AffiliateNotFoundException()
      : super('Affiliate profile not found', code: 'AFFILIATE_NOT_FOUND');
}

/// Exception thrown when a resource is not found
class NotFoundException extends AppException {
  const NotFoundException([String message = 'Resource not found'])
      : super(message, code: 'NOT_FOUND');
}

/// Exception thrown when a network operation times out
class NetworkTimeoutException extends AppException {
  const NetworkTimeoutException(
      [String message = 'Network request timed out'])
      : super(message, code: 'NETWORK_TIMEOUT');
}

/// Exception thrown when storage operations fail
class StorageException extends AppException {
  const StorageException(super.message, {super.code, super.originalError});
}

/// Exception thrown when validation fails
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  const ValidationException(super.message, {this.fieldErrors, super.code});
}

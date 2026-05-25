import 'app_exceptions.dart';

/// A Result type for handling success/failure states without exceptions
/// being silently swallowed.
sealed class Result<T> {
  const Result();

  /// Returns true if this is a success result
  bool get isSuccess => this is Success<T>;

  /// Returns true if this is a failure result
  bool get isFailure => this is Failure<T>;

  /// Map success value to another value
  Result<R> map<R>(R Function(T value) mapper) {
    return switch (this) {
      Success(value: final v) => Success(mapper(v)),
      Failure(message: final m, exception: final e) =>
        Failure(message: m, exception: e),
    };
  }

  /// Fold result to a single value
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(String message, AppException? exception) onFailure,
  }) {
    return switch (this) {
      Success(value: final v) => onSuccess(v),
      Failure(message: final m, exception: final e) => onFailure(m, e),
    };
  }
}

/// Success variant of Result
class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);
}

/// Failure variant of Result
class Failure<T> extends Result<T> {
  final String message;
  final AppException? exception;

  const Failure({required this.message, this.exception});
}

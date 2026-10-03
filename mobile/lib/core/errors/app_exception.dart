import 'app_failure.dart';

/// Base class for all data and infrastructure layer exceptions.
abstract class AppException implements Exception {
  final String message;
  final String? details;

  const AppException(this.message, [this.details]);

  Failure toFailure();

  @override
  String toString() => '$runtimeType: $message (${details ?? ''})';
}

class NetworkException extends AppException {
  const NetworkException([
    super.message = 'Network connection unavailable',
    super.details,
  ]);

  @override
  Failure toFailure() => NetworkFailure(technicalDetails: details ?? message);
}

class TimeoutException extends AppException {
  const TimeoutException([
    super.message = 'Network request timed out',
    super.details,
  ]);

  @override
  Failure toFailure() => TimeoutFailure(technicalDetails: details ?? message);
}

class ServerException extends AppException {
  final int? statusCode;
  const ServerException([
    super.message = 'Internal server error',
    this.statusCode,
    super.details,
  ]);

  @override
  Failure toFailure() => ServerFailure(statusCode: statusCode, technicalDetails: details ?? message);
}

class UnauthorizedException extends AppException {
  const UnauthorizedException([
    super.message = 'Unauthorized access',
    super.details,
  ]);

  @override
  Failure toFailure() => UnauthorizedFailure(technicalDetails: details ?? message);
}

class NotFoundException extends AppException {
  const NotFoundException([
    super.message = 'Resource not found',
    super.details,
  ]);

  @override
  Failure toFailure() => NotFoundFailure(technicalDetails: details ?? message);
}

class ValidationException extends AppException {
  const ValidationException(
    super.message, [
    super.details,
  ]);

  @override
  Failure toFailure() => ValidationFailure(userMessage: message, technicalDetails: details);
}

class StorageException extends AppException {
  const StorageException([
    super.message = 'Storage read/write error',
    super.details,
  ]);

  @override
  Failure toFailure() => StorageFailure(technicalDetails: details ?? message);
}

/// Base class for all domain and architectural failures in LINGUA AI.
/// Errors presented to the user must use plain, non-stigmatizing language
/// and never expose internal stack traces or technical jargon.
abstract class Failure {
  final String userMessage;
  final String? technicalDetails;

  const Failure({
    required this.userMessage,
    this.technicalDetails,
  });

  @override
  String toString() => 'Failure(userMessage: $userMessage, technicalDetails: $technicalDetails)';
}

/// Network connectivity issues (e.g. no internet, DNS lookup failed)
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.userMessage = 'We could not connect to the network. Please check your internet connection and try again.',
    super.technicalDetails,
  });
}

/// Request timeout failure
class TimeoutFailure extends Failure {
  const TimeoutFailure({
    super.userMessage = 'The request took too long to complete. Please try again in a moment.',
    super.technicalDetails,
  });
}

/// Backend server error (5xx)
class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure({
    super.userMessage = 'Our services are experiencing a temporary issue. Please try again shortly.',
    this.statusCode,
    super.technicalDetails,
  });
}

/// Client validation or invalid input failure (400, 422)
class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.userMessage,
    super.technicalDetails,
  });
}

/// Authentication or authorization failure (401, 403)
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({
    super.userMessage = 'Your session has expired or you do not have permission for this action. Please sign in.',
    super.technicalDetails,
  });
}

/// Resource not found failure (404)
class NotFoundFailure extends Failure {
  const NotFoundFailure({
    super.userMessage = 'The requested learning resource or activity was not found.',
    super.technicalDetails,
  });
}

/// Local storage failure (e.g. failed to read/write device preferences)
class StorageFailure extends Failure {
  const StorageFailure({
    super.userMessage = 'Could not save your preferences to the device. Please verify device storage permissions.',
    super.technicalDetails,
  });
}

/// Unexpected or unhandled failure
class UnknownFailure extends Failure {
  const UnknownFailure({
    super.userMessage = 'Something unexpected happened. Please try again.',
    super.technicalDetails,
  });
}

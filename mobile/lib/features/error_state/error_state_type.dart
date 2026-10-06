import 'package:flutter/material.dart';
import '../../core/errors/app_exception.dart';
import '../../core/errors/app_failure.dart';

/// Categories of error states supported by the LINGUA AI error state system.
enum ErrorStateType {
  noInternet,
  serverError,
  notFound,
  generic,
}

/// Metadata and helper extensions for [ErrorStateType].
extension ErrorStateTypeX on ErrorStateType {
  /// Default user-facing headline for this error type.
  String get defaultTitle {
    switch (this) {
      case ErrorStateType.notFound:
        return "Looks like you're lost";
      case ErrorStateType.noInternet:
        return 'No internet connection';
      case ErrorStateType.serverError:
        return 'Something went wrong on our side';
      case ErrorStateType.generic:
        return 'Oops, something broke';
    }
  }

  /// Default user-facing explanation line for this error type.
  String get defaultMessage {
    switch (this) {
      case ErrorStateType.notFound:
        return 'The page you are looking for is not available.';
      case ErrorStateType.noInternet:
        return 'Check your Wi-Fi or mobile data and try again.';
      case ErrorStateType.serverError:
        return 'Please try again in a moment.';
      case ErrorStateType.generic:
        return 'Please try again.';
    }
  }

  /// Header code or badge label displayed at the top of the error screen.
  String get defaultBadge {
    switch (this) {
      case ErrorStateType.notFound:
        return '404';
      case ErrorStateType.noInternet:
        return 'OFFLINE';
      case ErrorStateType.serverError:
        return '500';
      case ErrorStateType.generic:
        return 'ERROR';
    }
  }

  /// Icon representing this error type for badges and screen readers.
  IconData get icon {
    switch (this) {
      case ErrorStateType.notFound:
        return Icons.explore_off_rounded;
      case ErrorStateType.noInternet:
        return Icons.wifi_off_rounded;
      case ErrorStateType.serverError:
        return Icons.cloud_off_rounded;
      case ErrorStateType.generic:
        return Icons.error_outline_rounded;
    }
  }

  /// Resolves an [ErrorStateType] from an architectural [Failure], [AppException], or generic error.
  static ErrorStateType fromError(Object? error) {
    if (error is NetworkFailure ||
        error is NetworkException) {
      return ErrorStateType.noInternet;
    }
    if (error is ServerFailure ||
        error is ServerException ||
        error is TimeoutFailure ||
        error is TimeoutException) {
      return ErrorStateType.serverError;
    }
    if (error is NotFoundFailure ||
        error is NotFoundException) {
      return ErrorStateType.notFound;
    }

    final str = error?.toString().toLowerCase() ?? '';
    if (str.contains('socket') ||
        str.contains('network') ||
        str.contains('connection') ||
        str.contains('offline')) {
      return ErrorStateType.noInternet;
    }
    if (str.contains('timeout') ||
        str.contains('server') ||
        str.contains('500') ||
        str.contains('502') ||
        str.contains('503')) {
      return ErrorStateType.serverError;
    }
    if (str.contains('not found') || str.contains('404')) {
      return ErrorStateType.notFound;
    }

    return ErrorStateType.generic;
  }
}

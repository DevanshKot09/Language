import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_ai/core/errors/app_exception.dart';
import 'package:lingua_ai/core/errors/app_failure.dart';

void main() {
  group('Error Mapping & Plain Language Failure Tests', () {
    test('NetworkException maps to NetworkFailure without exposing internal stack trace', () {
      const exception = NetworkException('SocketException: OS Error 111', 'Failed lookup');
      final failure = exception.toFailure();

      expect(failure, isA<NetworkFailure>());
      // Plain language message must NOT expose raw technical strings
      expect(failure.userMessage, isNot(contains('SocketException')));
      expect(failure.userMessage, contains('internet connection'));
      // Technical details preserved internally for debugging
      expect(failure.technicalDetails, contains('Failed lookup'));
    });

    test('TimeoutException maps to TimeoutFailure with user-friendly message', () {
      const exception = TimeoutException('Client request timed out');
      final failure = exception.toFailure();

      expect(failure, isA<TimeoutFailure>());
      expect(failure.userMessage, contains('took too long'));
    });

    test('ServerException maps to ServerFailure with HTTP status code', () {
      const exception = ServerException('Internal Error', 503, 'Service unavailable');
      final failure = exception.toFailure();

      expect(failure, isA<ServerFailure>());
      final serverFailure = failure as ServerFailure;
      expect(serverFailure.statusCode, 503);
      expect(serverFailure.userMessage, contains('temporary issue'));
    });

    test('UnauthorizedException maps to UnauthorizedFailure', () {
      const exception = UnauthorizedException();
      final failure = exception.toFailure();

      expect(failure, isA<UnauthorizedFailure>());
      expect(failure.userMessage, contains('sign in'));
    });
  });
}

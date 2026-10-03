import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lingua_ai/core/network/api_client.dart';
import 'package:lingua_ai/core/network/health_repository.dart';
import 'package:lingua_ai/core/errors/app_exception.dart';

void main() {
  group('ApiClient & HealthRepository Tests', () {
    test('HealthRepository successfully parses healthy backend response', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/health' || request.url.path == '/api/v1/health') {
          return http.Response(
            jsonEncode({
              'status': 'healthy',
              'service': 'LINGUA AI Backend Service',
              'boundary': 'Screening & Practice Support • Non-Diagnostic',
              'version': '1.0.0',
              'environment': 'testing',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(client: mockClient, baseUrl: 'http://localhost:8000');
      final healthRepo = HealthRepository(apiClient);

      final status = await healthRepo.checkHealth();
      expect(status.isHealthy, isTrue);
      expect(status.service, 'LINGUA AI Backend Service');
      expect(status.version, '1.0.0');
      expect(status.boundary, contains('Non-Diagnostic'));
    });

    test('ApiClient maps 500 error to ServerException', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'detail': 'Internal error'}),
          500,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(client: mockClient, baseUrl: 'http://localhost:8000');

      expect(
        () async => await apiClient.get('/api/v1/error'),
        throwsA(isA<ServerException>()),
      );
    });

    test('ApiClient maps 404 error to NotFoundException', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'detail': 'Not found'}),
          404,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(client: mockClient, baseUrl: 'http://localhost:8000');

      expect(
        () async => await apiClient.get('/api/v1/missing'),
        throwsA(isA<NotFoundException>()),
      );
    });
  });
}

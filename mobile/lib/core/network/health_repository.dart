import '../errors/app_exception.dart';
import '../errors/app_failure.dart';
import 'api_client.dart';
import 'api_endpoints.dart';

/// Health status response model
class HealthStatus {
  final String status;
  final String service;
  final String boundary;
  final String version;

  const HealthStatus({
    required this.status,
    required this.service,
    required this.boundary,
    required this.version,
  });

  bool get isHealthy => status == 'healthy';

  factory HealthStatus.fromJson(Map<String, dynamic> json) {
    return HealthStatus(
      status: json['status'] as String? ?? 'unknown',
      service: json['service'] as String? ?? 'unknown',
      boundary: json['boundary'] as String? ?? '',
      version: json['version'] as String? ?? '1.0.0',
    );
  }
}

/// Abstract contract for checking backend service health
abstract class IHealthRepository {
  Future<HealthStatus> checkHealth();
}

/// Implementation using [IApiClient]
class HealthRepository implements IHealthRepository {
  final IApiClient _apiClient;

  HealthRepository(this._apiClient);

  @override
  Future<HealthStatus> checkHealth() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.health);
      if (response is Map<String, dynamic>) {
        return HealthStatus.fromJson(response);
      }
      throw const ServerException('Malformed health check response');
    } on AppException catch (e) {
      throw e.toFailure();
    } catch (e) {
      throw UnknownFailure(technicalDetails: e.toString());
    }
  }
}

import 'package:lingua_ai/core/network/api_client.dart';

class MockApiClient implements IApiClient {
  dynamic mockResponse;
  String? _authToken;

  @override
  String? get authToken => _authToken;

  @override
  void setAuthToken(String? token) {
    _authToken = token;
  }

  @override
  Future<dynamic> get(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
  }) async {
    return mockResponse;
  }

  @override
  Future<dynamic> post(
    String path, {
    Map<String, String>? headers,
    dynamic body,
  }) async {
    return mockResponse;
  }

  @override
  Future<dynamic> put(
    String path, {
    Map<String, String>? headers,
    dynamic body,
  }) async {
    return mockResponse;
  }

  @override
  Future<dynamic> patch(
    String path, {
    Map<String, String>? headers,
    dynamic body,
  }) async {
    return mockResponse;
  }

  @override
  Future<dynamic> delete(
    String path, {
    Map<String, String>? headers,
    dynamic body,
  }) async {
    return mockResponse;
  }
}

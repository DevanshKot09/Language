import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/environment.dart';
import '../errors/app_exception.dart';

typedef TokenProvider = Future<String?> Function();

/// Abstract API client contract for network operations.
abstract class IApiClient {
  void setAuthToken(String? token);
  String? get authToken;

  Future<dynamic> get(String path, {Map<String, String>? headers, Map<String, dynamic>? queryParameters});
  Future<dynamic> post(String path, {Map<String, String>? headers, dynamic body});
  Future<dynamic> put(String path, {Map<String, String>? headers, dynamic body});
  Future<dynamic> patch(String path, {Map<String, String>? headers, dynamic body});
  Future<dynamic> delete(String path, {Map<String, String>? headers, dynamic body});
}

/// Standard production HTTP client implementation for LINGUA AI.
/// Automatically obtains Firebase ID Token from the current authenticated user
/// before dispatching requests to FastAPI.
class ApiClient implements IApiClient {
  final http.Client _client;
  final String _baseUrl;
  final Duration _timeout;
  final TokenProvider? _tokenProvider;
  String? _authToken;

  ApiClient({
    http.Client? client,
    String? baseUrl,
    this._timeout = const Duration(seconds: 30),
    this._tokenProvider,
    this._authToken,
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? Environment.apiBaseUrl;

  @override
  void setAuthToken(String? token) {
    _authToken = token;
  }

  @override
  String? get authToken => _authToken;

  Uri _buildUri(String path, [Map<String, dynamic>? queryParameters]) {
    final cleanBase = _baseUrl.endsWith('/') ? _baseUrl.substring(0, _baseUrl.length - 1) : _baseUrl;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final fullUrl = '$cleanBase$cleanPath';
    return Uri.parse(fullUrl).replace(queryParameters: queryParameters);
  }

  Future<Map<String, String>> _buildHeaders([Map<String, String>? additionalHeaders]) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    String? token = _authToken;
    if (token == null && _tokenProvider != null) {
      try {
        token = await _tokenProvider();
      } catch (_) {
        token = null;
      }
    }

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }
    return headers;
  }

  @override
  Future<dynamic> get(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
  }) async {
    final uri = _buildUri(path, queryParameters);
    try {
      final resolvedHeaders = await _buildHeaders(headers);
      final response = await _client.get(uri, headers: resolvedHeaders).timeout(_timeout);
      return _handleResponse(response);
    } on TimeoutException {
      throw const NetworkException('Request timed out. Please check your connection and try again.');
    } on SocketException catch (e) {
      throw NetworkException('Network connection failed', e.message);
    } on http.ClientException catch (e) {
      throw NetworkException('HTTP client error', e.message);
    }
  }

  @override
  Future<dynamic> post(
    String path, {
    Map<String, String>? headers,
    dynamic body,
  }) async {
    final uri = _buildUri(path);
    try {
      final resolvedHeaders = await _buildHeaders(headers);
      final encodedBody = body != null ? jsonEncode(body) : null;
      final response = await _client
          .post(uri, headers: resolvedHeaders, body: encodedBody)
          .timeout(_timeout);
      return _handleResponse(response);
    } on TimeoutException {
      throw const NetworkException('Request timed out. Please check your connection and try again.');
    } on SocketException catch (e) {
      throw NetworkException('Network connection failed', e.message);
    } on http.ClientException catch (e) {
      throw NetworkException('HTTP client error', e.message);
    }
  }

  @override
  Future<dynamic> put(
    String path, {
    Map<String, String>? headers,
    dynamic body,
  }) async {
    final uri = _buildUri(path);
    try {
      final resolvedHeaders = await _buildHeaders(headers);
      final encodedBody = body != null ? jsonEncode(body) : null;
      final response = await _client
          .put(uri, headers: resolvedHeaders, body: encodedBody)
          .timeout(_timeout);
      return _handleResponse(response);
    } on TimeoutException {
      throw const NetworkException('Request timed out. Please check your connection and try again.');
    } on SocketException catch (e) {
      throw NetworkException('Network connection failed', e.message);
    } on http.ClientException catch (e) {
      throw NetworkException('HTTP client error', e.message);
    }
  }

  @override
  Future<dynamic> delete(
    String path, {
    Map<String, String>? headers,
    dynamic body,
  }) async {
    final uri = _buildUri(path);
    try {
      final resolvedHeaders = await _buildHeaders(headers);
      final encodedBody = body != null ? jsonEncode(body) : null;
      final response = await _client
          .delete(uri, headers: resolvedHeaders, body: encodedBody)
          .timeout(_timeout);
      return _handleResponse(response);
    } on TimeoutException {
      throw const NetworkException('Request timed out. Please check your connection and try again.');
    } on SocketException catch (e) {
      throw NetworkException('Network connection failed', e.message);
    } on http.ClientException catch (e) {
      throw NetworkException('HTTP client error', e.message);
    }
  }

  @override
  Future<dynamic> patch(
    String path, {
    Map<String, String>? headers,
    dynamic body,
  }) async {
    final uri = _buildUri(path);
    try {
      final resolvedHeaders = await _buildHeaders(headers);
      final encodedBody = body != null ? jsonEncode(body) : null;
      final response = await _client
          .patch(uri, headers: resolvedHeaders, body: encodedBody)
          .timeout(_timeout);
      return _handleResponse(response);
    } on TimeoutException {
      throw const NetworkException('Request timed out. Please check your connection and try again.');
    } on SocketException catch (e) {
      throw NetworkException('Network connection failed', e.message);
    } on http.ClientException catch (e) {
      throw NetworkException('HTTP client error', e.message);
    }
  }

  dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    final bodyString = response.body;

    dynamic decodedJson;
    if (bodyString.isNotEmpty) {
      try {
        decodedJson = jsonDecode(bodyString);
      } catch (_) {
        decodedJson = bodyString;
      }
    }

    if (statusCode >= 200 && statusCode < 300) {
      return decodedJson;
    } else if (statusCode == 400 || statusCode == 422) {
      final msg = decodedJson is Map && decodedJson['detail'] != null
          ? decodedJson['detail'].toString()
          : 'Invalid request data';
      throw ValidationException(msg, bodyString);
    } else if (statusCode == 401 || statusCode == 403) {
      throw UnauthorizedException('Unauthorized access', bodyString);
    } else if (statusCode == 404) {
      throw NotFoundException('Resource not found', bodyString);
    } else if (statusCode >= 500) {
      throw ServerException('Server error occurred', statusCode, bodyString);
    } else {
      throw ServerException('Unexpected HTTP error: $statusCode', statusCode, bodyString);
    }
  }
}

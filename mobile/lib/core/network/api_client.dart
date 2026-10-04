import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
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
  String _baseUrl;
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

  Uri _getAlternateUri(Uri uri) {
    if (!kIsWeb && Platform.isAndroid) {
      if (uri.host == '10.0.2.2') {
        return uri.replace(host: '127.0.0.1');
      } else if (uri.host == '127.0.0.1') {
        return uri.replace(host: '10.0.2.2');
      }
    }
    return uri;
  }

  Future<http.Response> _executeWithFallback(
    Future<http.Response> Function(Uri uri) requestFn,
    Uri uri,
  ) async {
    try {
      return await requestFn(uri).timeout(_timeout);
    } on SocketException {
      final alt = _getAlternateUri(uri);
      if (alt != uri) {
        try {
          final res = await requestFn(alt).timeout(_timeout);
          _baseUrl = '${alt.scheme}://${alt.host}:${alt.port}';
          return res;
        } catch (_) {}
      }
      rethrow;
    } on http.ClientException {
      final alt = _getAlternateUri(uri);
      if (alt != uri) {
        try {
          final res = await requestFn(alt).timeout(_timeout);
          _baseUrl = '${alt.scheme}://${alt.host}:${alt.port}';
          return res;
        } catch (_) {}
      }
      rethrow;
    }
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
      final response = await _executeWithFallback(
        (u) => _client.get(u, headers: resolvedHeaders),
        uri,
      );
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
      final response = await _executeWithFallback(
        (u) => _client.post(u, headers: resolvedHeaders, body: encodedBody),
        uri,
      );
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
      final response = await _executeWithFallback(
        (u) => _client.put(u, headers: resolvedHeaders, body: encodedBody),
        uri,
      );
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
      final response = await _executeWithFallback(
        (u) => _client.delete(u, headers: resolvedHeaders, body: encodedBody),
        uri,
      );
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
      final response = await _executeWithFallback(
        (u) => _client.patch(u, headers: resolvedHeaders, body: encodedBody),
        uri,
      );
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

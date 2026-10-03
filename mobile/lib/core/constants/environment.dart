/// Environment configuration for LINGUA AI.
/// Configurable via compile-time variables: --dart-define=API_BASE_URL=...
class Environment {
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  static const String _configuredApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://bee-neural-internal-warnings.trycloudflare.com',
  );

  static String get apiBaseUrl {
    if (_configuredApiBaseUrl.isNotEmpty) {
      return _configuredApiBaseUrl;
    }
    return 'https://bee-neural-internal-warnings.trycloudflare.com';
  }

  static const bool isDebug = bool.fromEnvironment(
    'DEBUG',
    defaultValue: true,
  );

  static bool get isProduction => environment == 'production';
  static bool get isDevelopment => environment == 'development';
  static bool get isTesting => environment == 'testing';
}

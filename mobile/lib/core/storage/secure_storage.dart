import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Contract for storing non-authentication sensitive device secrets or keys.
///
/// NOTE on Phase 3A Architecture:
/// Custom JWT access tokens and custom refresh tokens are NO LONGER stored here.
/// Firebase Authentication SDK natively handles token lifecycle, hardware keystore
/// persistence, auto-refresh, and secure session management.
/// This interface is preserved strictly for non-auth secure device preferences.
abstract class ISecureStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
  Future<void> deleteAll();
}

/// Secure credential storage using platform-native hardware keystore/keychain.
class SecureStorage implements ISecureStorage {
  final FlutterSecureStorage _storage;

  SecureStorage([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  @override
  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  @override
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (_) {}
  }

  @override
  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
    } catch (_) {}
  }
}

/// In-memory secure storage for isolated unit tests without native platform channels.
class InMemorySecureStorage implements ISecureStorage {
  final Map<String, String> _data = {};

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> write(String key, String value) async {
    _data[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _data.remove(key);
  }

  @override
  Future<void> deleteAll() async {
    _data.clear();
  }
}

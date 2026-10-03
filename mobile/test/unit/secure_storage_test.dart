import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_ai/core/storage/secure_storage.dart';

void main() {
  group('ISecureStorage Isolation Tests', () {
    test('InMemorySecureStorage handles non-auth device keys securely', () async {
      final storage = InMemorySecureStorage();

      // Initially null
      expect(await storage.read('non_auth_secret'), isNull);

      // Store key-value
      await storage.write('non_auth_secret', 'secret_value_123');
      expect(await storage.read('non_auth_secret'), 'secret_value_123');

      // Delete key
      await storage.delete('non_auth_secret');
      expect(await storage.read('non_auth_secret'), isNull);

      // Delete all
      await storage.write('key1', 'val1');
      await storage.write('key2', 'val2');
      await storage.deleteAll();
      expect(await storage.read('key1'), isNull);
      expect(await storage.read('key2'), isNull);
    });
  });
}

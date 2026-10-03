import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/secure_storage.dart';
import '../../features/authentication/data/auth_repository.dart';
import '../../features/authentication/data/profile_repository.dart';
import 'network_provider.dart';

final secureStorageProvider = Provider<ISecureStorage>((ref) {
  return SecureStorage();
});

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRepository(apiClient);
});

final profileRepositoryProvider = Provider<IProfileRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProfileRepository(apiClient);
});

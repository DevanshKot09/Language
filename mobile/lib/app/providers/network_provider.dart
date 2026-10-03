import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/network/health_repository.dart';

/// Provider for the application's API Client with automatic Firebase ID Token attachment
final apiClientProvider = Provider<IApiClient>((ref) {
  return ApiClient(
    tokenProvider: () async {
      try {
        return await FirebaseAuth.instance.currentUser?.getIdToken();
      } catch (_) {
        return null;
      }
    },
  );
});

/// Provider for backend Health Repository
final healthRepositoryProvider = Provider<IHealthRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return HealthRepository(client);
});

/// FutureProvider to check backend health status
final backendHealthProvider = FutureProvider<HealthStatus>((ref) async {
  final repo = ref.watch(healthRepositoryProvider);
  return await repo.checkHealth();
});

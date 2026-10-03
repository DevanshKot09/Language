import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/age_profile.dart';
import 'storage_provider.dart';

/// Notifier managing active age band and age-adaptive configuration.
class AgeProfileNotifier extends Notifier<AgeProfileConfig> {
  @override
  AgeProfileConfig build() {
    // Start with default and load persisted preference asynchronously
    _loadFromStorage();
    return AgeProfileConfig.teen();
  }

  Future<void> _loadFromStorage() async {
    try {
      final storage = ref.read(preferencesStorageProvider);
      final band = await storage.getAgeBand();
      state = AgeProfileConfig.forBand(band);
    } catch (_) {
      // Retain default
    }
  }

  Future<void> setAgeBand(AgeBand band) async {
    state = AgeProfileConfig.forBand(band);
    final storage = ref.read(preferencesStorageProvider);
    await storage.setAgeBand(band);
  }
}

/// Global Riverpod provider for active age profile configuration
final ageProfileProvider = NotifierProvider<AgeProfileNotifier, AgeProfileConfig>(
  AgeProfileNotifier.new,
);

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/preferences_storage.dart';

/// Provider for local device preferences storage
final preferencesStorageProvider = Provider<IPreferencesStorage>((ref) {
  return SharedPreferencesStorage();
});

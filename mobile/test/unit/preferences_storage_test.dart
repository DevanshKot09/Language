import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lingua_ai/core/storage/preferences_storage.dart';
import 'package:lingua_ai/shared/models/age_profile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PreferencesStorage Local Storage Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Saves and retrieves age band preference cleanly', () async {
      final storage = SharedPreferencesStorage();
      
      // Default initial value
      expect(await storage.getAgeBand(), AgeBand.teen);

      // Set to Child
      await storage.setAgeBand(AgeBand.child);
      expect(await storage.getAgeBand(), AgeBand.child);

      // Set to Adult
      await storage.setAgeBand(AgeBand.adult);
      expect(await storage.getAgeBand(), AgeBand.adult);
    });

    test('Saves and retrieves accessibility font preferences', () async {
      final storage = SharedPreferencesStorage();

      expect(await storage.getUseDyslexicFont(), isFalse);
      await storage.setUseDyslexicFont(true);
      expect(await storage.getUseDyslexicFont(), isTrue);

      expect(await storage.getFontScale(), 1.0);
      await storage.setFontScale(1.25);
      expect(await storage.getFontScale(), 1.25);
    });

    test('Onboarding status flag persistence', () async {
      final storage = SharedPreferencesStorage();

      expect(await storage.isOnboardingCompleted(), isFalse);
      await storage.setOnboardingCompleted(true);
      expect(await storage.isOnboardingCompleted(), isTrue);
    });
  });
}

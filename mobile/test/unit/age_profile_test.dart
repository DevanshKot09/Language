import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_ai/shared/models/age_profile.dart';

void main() {
  group('AgeProfileConfig Unit Tests', () {
    test('Child configuration applies large touch target and gentle rewards', () {
      final childConfig = AgeProfileConfig.child();
      expect(childConfig.ageBand, AgeBand.child);
      expect(childConfig.displayName, 'Child Learner');
      expect(childConfig.ageRangeLabel, 'Ages 5–11');
      expect(childConfig.minTouchTarget, 56.0);
      expect(childConfig.autoPlayAudioInstructions, isTrue);
      expect(childConfig.gentleRewardsOnly, isTrue);
      expect(childConfig.showStreaks, isFalse);
    });

    test('Teen configuration provides modern non-childish defaults and streaks', () {
      final teenConfig = AgeProfileConfig.teen();
      expect(teenConfig.ageBand, AgeBand.teen);
      expect(teenConfig.displayName, 'Teen Learner');
      expect(teenConfig.ageRangeLabel, 'Ages 12–17');
      expect(teenConfig.minTouchTarget, 48.0);
      expect(teenConfig.autoPlayAudioInstructions, isFalse);
      expect(teenConfig.gentleRewardsOnly, isFalse);
      expect(teenConfig.showStreaks, isTrue);
    });

    test('Adult configuration provides dignified styling and no gamification streaks', () {
      final adultConfig = AgeProfileConfig.adult();
      expect(adultConfig.ageBand, AgeBand.adult);
      expect(adultConfig.displayName, 'Adult Learner');
      expect(adultConfig.ageRangeLabel, 'Ages 18+');
      expect(adultConfig.minTouchTarget, 44.0);
      expect(adultConfig.autoPlayAudioInstructions, isFalse);
      expect(adultConfig.showStreaks, isFalse);
    });

    test('forBand correctly instantiates matching configuration', () {
      expect(AgeProfileConfig.forBand(AgeBand.child).ageBand, AgeBand.child);
      expect(AgeProfileConfig.forBand(AgeBand.teen).ageBand, AgeBand.teen);
      expect(AgeProfileConfig.forBand(AgeBand.adult).ageBand, AgeBand.adult);
    });
  });
}

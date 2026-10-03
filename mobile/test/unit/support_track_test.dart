import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_ai/shared/models/skill_track.dart';

void main() {
  group('SupportTrack Domain Model Tests', () {
    test('Ensures DLD and Dyslexia remain distinct support tracks', () {
      const dld = SupportTrack.dldSpokenLanguage;
      const dyslexia = SupportTrack.dyslexiaLiteracy;
      const both = SupportTrack.multimodalBoth;

      // Verify domain focus separation
      expect(dld.title.toLowerCase(), contains('spoken language'));
      expect(dld.title.toLowerCase(), contains('dld'));
      expect(dyslexia.title.toLowerCase(), contains('literacy & reading'));
      expect(dyslexia.title.toLowerCase(), contains('dyslexia'));
      expect(both.title.toLowerCase(), contains('dual-track'));

      // Verify distinct labels
      expect(dld.shortLabel, 'DLD Spoken Track');
      expect(dyslexia.shortLabel, 'Dyslexia Reading Track');
      expect(both.shortLabel, 'Connected Track');
    });

    test('SupportTrack provides distinct styling colors', () {
      expect(SupportTrack.dldSpokenLanguage.primaryColor, isNot(equals(SupportTrack.dyslexiaLiteracy.primaryColor)));
      expect(SupportTrack.dldSpokenLanguage.backgroundColor, isNot(equals(SupportTrack.dyslexiaLiteracy.backgroundColor)));
    });
  });
}

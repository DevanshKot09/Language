import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_ai/shared/models/age_profile.dart';
import 'package:lingua_ai/shared/models/auth_user.dart';
import 'package:lingua_ai/shared/models/skill_track.dart';
import 'package:lingua_ai/shared/models/user_profile.dart';
import 'package:lingua_ai/shared/models/user_role.dart';

void main() {
  group('Authentication & Profile Domain Models Tests', () {
    test('AuthUser correctly parses from JSON', () {
      final json = {
        'id': 'usr-1234',
        'email': 'learner@lingua.ai',
        'role': 'learner',
        'status': 'active',
        'created_at': '2026-09-30T10:00:00Z',
      };

      final user = AuthUser.fromJson(json);
      expect(user.id, 'usr-1234');
      expect(user.email, 'learner@lingua.ai');
      expect(user.role, UserRole.learner);
      expect(user.status, 'active');
    });

    test('UserProfile correctly parses non-diagnostic support track and age band', () {
      final json = {
        'id': 'prof-5678',
        'user_id': 'usr-1234',
        'display_name': 'Alex L.',
        'age_band': 'child',
        'support_focus': 'dld_track',
        'guardian_consent_status': 'pending',
      };

      final profile = UserProfile.fromJson(json);
      expect(profile.displayName, 'Alex L.');
      expect(profile.ageBand, AgeBand.child);
      expect(profile.supportFocus, SupportTrack.dldSpokenLanguage);
      expect(profile.guardianConsentStatus, 'pending');
    });

    test('SupportTrack apiId maps bidirectionally', () {
      expect(SupportTrack.dldSpokenLanguage.apiId, 'dld_track');
      expect(SupportTrack.dyslexiaLiteracy.apiId, 'dyslexia_track');
      expect(SupportTrack.multimodalBoth.apiId, 'both_track');

      expect(SupportTrackExtension.fromApiId('dld_track'), SupportTrack.dldSpokenLanguage);
      expect(SupportTrackExtension.fromApiId('dyslexia_track'), SupportTrack.dyslexiaLiteracy);
      expect(SupportTrackExtension.fromApiId('both_track'), SupportTrack.multimodalBoth);
    });
  });
}

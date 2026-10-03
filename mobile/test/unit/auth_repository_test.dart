import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lingua_ai/core/network/api_client.dart';
import 'package:lingua_ai/features/authentication/data/auth_repository.dart';
import 'package:lingua_ai/shared/models/age_profile.dart';
import 'package:lingua_ai/shared/models/skill_track.dart';
import 'package:lingua_ai/shared/models/user_role.dart';

void main() {
  group('AuthRepository Unit Tests', () {
    test('syncWithBackend successfully returns AuthSession from FastAPI + Supabase', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v1/auth/sync') {
          return http.Response(
            jsonEncode({
              'user': {
                'id': 'u1',
                'email': 'alex@lingua.ai',
                'role': 'learner',
                'status': 'active',
                'created_at': '2026-09-30T10:00:00Z',
              },
              'profile': {
                'id': 'p1',
                'user_id': 'u1',
                'display_name': 'Alex',
                'age_band': 'teen',
                'support_focus': 'dld_track',
                'guardian_consent_status': 'not_required',
              },
              'accessibility': {
                'font_scale': 1.0,
                'use_dyslexic_font': false,
                'high_contrast': false,
                'reduced_motion': false,
                'tts_auto_play': false,
                'speech_rate': 1.0,
              },
              'onboarding': {
                'is_completed': true,
                'current_step': 'completed',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(client: mockClient, baseUrl: 'http://localhost:8000');
      // For unit test isolation without Firebase native plugin channels,
      // we test the API repository layer
      final authRepo = AuthRepository(apiClient);

      final session = await authRepo.syncWithBackend(
        role: UserRole.learner,
        ageBand: AgeBand.teen,
        supportFocus: SupportTrack.dldSpokenLanguage,
        displayName: 'Alex',
      );

      expect(session.user.email, 'alex@lingua.ai');
      expect(session.profile.displayName, 'Alex');
      expect(session.profile.supportFocus, SupportTrack.dldSpokenLanguage);
      expect(session.onboarding.isCompleted, isTrue);
    });

    test('getApplicationSession calls /me and returns valid AuthSession', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v1/auth/me') {
          return http.Response(
            jsonEncode({
              'user': {
                'id': 'u2',
                'email': 'taylor@lingua.ai',
                'role': 'learner',
                'status': 'active',
                'created_at': '2026-09-30T10:00:00Z',
              },
              'profile': {
                'id': 'p2',
                'user_id': 'u2',
                'display_name': 'Taylor',
                'age_band': 'adult',
                'support_focus': 'both_track',
                'guardian_consent_status': 'not_required',
              },
              'accessibility': {
                'font_scale': 1.1,
                'use_dyslexic_font': true,
                'high_contrast': false,
                'reduced_motion': true,
                'tts_auto_play': true,
                'speech_rate': 0.9,
              },
              'onboarding': {
                'is_completed': false,
                'current_step': 'role_selection',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(client: mockClient, baseUrl: 'http://localhost:8000');
      final authRepo = AuthRepository(apiClient);

      final session = await authRepo.getApplicationSession();

      expect(session.user.id, 'u2');
      expect(session.profile.ageBand, AgeBand.adult);
      expect(session.profile.supportFocus, SupportTrack.multimodalBoth);
      expect(session.onboarding.isCompleted, isFalse);
    });
  });
}

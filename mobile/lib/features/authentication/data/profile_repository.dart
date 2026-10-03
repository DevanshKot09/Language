import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../shared/models/age_profile.dart';
import '../../../../shared/models/onboarding_status.dart';
import '../../../../shared/models/skill_track.dart';
import '../../../../shared/models/user_profile.dart';
import '../../../../shared/models/user_role.dart';

abstract class IProfileRepository {
  Future<UserProfile> getProfile();

  Future<UserProfile> updateProfile({
    String? displayName,
    AgeBand? ageBand,
    SupportTrack? supportFocus,
    String? guardianConsentStatus,
  });

  Future<OnboardingStatus> updateOnboarding({
    bool? isCompleted,
    String? currentStep,
    UserRole? role,
    AgeBand? ageBand,
    SupportTrack? supportFocus,
  });

  Future<void> updateAccessibility({
    double? fontScale,
    bool? useDyslexicFont,
    bool? highContrast,
    bool? reducedMotion,
    bool? ttsAutoPlay,
    double? speechRate,
  });
}

class ProfileRepository implements IProfileRepository {
  final IApiClient _apiClient;

  ProfileRepository(this._apiClient);

  @override
  Future<UserProfile> getProfile() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.profile);
      return UserProfile.fromJson(response as Map<String, dynamic>);
    } on AppException catch (e) {
      throw e.toFailure();
    } catch (e) {
      throw UnknownFailure(technicalDetails: e.toString());
    }
  }

  @override
  Future<UserProfile> updateProfile({
    String? displayName,
    AgeBand? ageBand,
    SupportTrack? supportFocus,
    String? guardianConsentStatus,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (displayName != null) body['display_name'] = displayName;
      if (ageBand != null) body['age_band'] = ageBand.name;
      if (supportFocus != null) body['support_focus'] = supportFocus.apiId;
      if (guardianConsentStatus != null) body['guardian_consent_status'] = guardianConsentStatus;

      final response = await _apiClient.put(ApiEndpoints.profile, body: body);
      return UserProfile.fromJson(response as Map<String, dynamic>);
    } on AppException catch (e) {
      throw e.toFailure();
    } catch (e) {
      throw UnknownFailure(technicalDetails: e.toString());
    }
  }

  @override
  Future<OnboardingStatus> updateOnboarding({
    bool? isCompleted,
    String? currentStep,
    UserRole? role,
    AgeBand? ageBand,
    SupportTrack? supportFocus,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (isCompleted != null) body['is_completed'] = isCompleted;
      if (currentStep != null) body['current_step'] = currentStep;
      if (role != null) body['role'] = role.name;
      if (ageBand != null) body['age_band'] = ageBand.name;
      if (supportFocus != null) body['support_focus'] = supportFocus.apiId;

      final response = await _apiClient.put(ApiEndpoints.profileOnboarding, body: body);
      return OnboardingStatus.fromJson(response as Map<String, dynamic>);
    } on AppException catch (e) {
      throw e.toFailure();
    } catch (e) {
      throw UnknownFailure(technicalDetails: e.toString());
    }
  }

  @override
  Future<void> updateAccessibility({
    double? fontScale,
    bool? useDyslexicFont,
    bool? highContrast,
    bool? reducedMotion,
    bool? ttsAutoPlay,
    double? speechRate,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (fontScale != null) body['font_scale'] = fontScale;
      if (useDyslexicFont != null) body['use_dyslexic_font'] = useDyslexicFont;
      if (highContrast != null) body['high_contrast'] = highContrast;
      if (reducedMotion != null) body['reduced_motion'] = reducedMotion;
      if (ttsAutoPlay != null) body['tts_auto_play'] = ttsAutoPlay;
      if (speechRate != null) body['speech_rate'] = speechRate;

      await _apiClient.put(ApiEndpoints.profileAccessibility, body: body);
    } on AppException catch (e) {
      throw e.toFailure();
    } catch (e) {
      throw UnknownFailure(technicalDetails: e.toString());
    }
  }
}

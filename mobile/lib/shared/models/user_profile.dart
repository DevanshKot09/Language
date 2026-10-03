import 'age_profile.dart';
import 'skill_track.dart';

/// Represents the user's learning profile.
/// Strictly non-diagnostic: age band and support track are learning settings,
/// never clinical diagnoses.
class UserProfile {
  final String id;
  final String userId;
  final String displayName;
  final AgeBand ageBand;
  final SupportTrack supportFocus;
  final String guardianConsentStatus; // 'not_required', 'pending', 'verified'
  final String baselineStatus; // 'not_started', 'in_progress', 'completed'
  final String preferredLearningMode;
  final String? primaryLearningGoal;
  final DateTime? updatedAt;

  const UserProfile({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.ageBand,
    required this.supportFocus,
    this.guardianConsentStatus = 'not_required',
    this.baselineStatus = 'not_started',
    this.preferredLearningMode = 'interactive',
    this.primaryLearningGoal,
    this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    // Parse age band safely
    final ageStr = json['age_band'] as String? ?? 'teen';
    AgeBand parsedBand = AgeBand.teen;
    for (final b in AgeBand.values) {
      if (b.name == ageStr.toLowerCase()) {
        parsedBand = b;
        break;
      }
    }

    // Parse support track safely
    final trackStr = json['support_focus'] as String? ?? 'dld_track';
    final parsedTrack = SupportTrackExtension.fromApiId(trackStr);

    return UserProfile(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? 'Learner',
      ageBand: parsedBand,
      supportFocus: parsedTrack,
      guardianConsentStatus: json['guardian_consent_status'] as String? ?? 'not_required',
      baselineStatus: json['baseline_status'] as String? ?? 'not_started',
      preferredLearningMode: json['preferred_learning_mode'] as String? ?? 'interactive',
      primaryLearningGoal: json['primary_learning_goal'] as String?,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'display_name': displayName,
        'age_band': ageBand.name,
        'support_focus': supportFocus.apiId,
        'guardian_consent_status': guardianConsentStatus,
        'baseline_status': baselineStatus,
        'preferred_learning_mode': preferredLearningMode,
        'primary_learning_goal': primaryLearningGoal,
        'updated_at': updatedAt?.toIso8601String(),
      };

  UserProfile copyWith({
    String? id,
    String? userId,
    String? displayName,
    AgeBand? ageBand,
    SupportTrack? supportFocus,
    String? guardianConsentStatus,
    String? baselineStatus,
    String? preferredLearningMode,
    String? primaryLearningGoal,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      ageBand: ageBand ?? this.ageBand,
      supportFocus: supportFocus ?? this.supportFocus,
      guardianConsentStatus: guardianConsentStatus ?? this.guardianConsentStatus,
      baselineStatus: baselineStatus ?? this.baselineStatus,
      preferredLearningMode: preferredLearningMode ?? this.preferredLearningMode,
      primaryLearningGoal: primaryLearningGoal ?? this.primaryLearningGoal,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

}

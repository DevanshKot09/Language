/// Tracks the onboarding progress of the user.
class OnboardingStatus {
  final bool isCompleted;
  final String currentStep;
  final DateTime? completedAt;

  const OnboardingStatus({
    this.isCompleted = false,
    this.currentStep = 'role',
    this.completedAt,
  });

  factory OnboardingStatus.fromJson(Map<String, dynamic> json) {
    return OnboardingStatus(
      isCompleted: json['is_completed'] as bool? ?? false,
      currentStep: json['current_step'] as String? ?? 'role',
      completedAt: json['completed_at'] != null ? DateTime.tryParse(json['completed_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'is_completed': isCompleted,
        'current_step': currentStep,
        'completed_at': completedAt?.toIso8601String(),
      };
}

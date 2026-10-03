/// The primary user roles supported across LINGUA AI.
/// Each role receives an adapted navigation architecture and strict authorization boundaries.
enum UserRole {
  learner,
  parent,
  teacher,
  specialist,
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.learner:
        return 'Learner';
      case UserRole.parent:
        return 'Parent / Caregiver';
      case UserRole.teacher:
        return 'Educator / Teacher';
      case UserRole.specialist:
        return 'Specialist (SLP / Reading Professional)';
    }
  }

  String get description {
    switch (this) {
      case UserRole.learner:
        return 'Practice speaking, listening, reading, and language skills with personalized guidance.';
      case UserRole.parent:
        return 'Guide home practice, view child progress, and coordinate with educators.';
      case UserRole.teacher:
        return 'Assign skill practice to students, review class trends, and track accommodations.';
      case UserRole.specialist:
        return 'Manage clinical caseload, define practice targets, and review structured progress summaries.';
    }
  }

  bool get requiresAdultConsentVerification {
    return this == UserRole.parent || this == UserRole.teacher || this == UserRole.specialist;
  }

  static UserRole fromName(String name) {
    for (final role in UserRole.values) {
      if (role.name == name.toLowerCase()) return role;
    }
    return UserRole.learner;
  }
}

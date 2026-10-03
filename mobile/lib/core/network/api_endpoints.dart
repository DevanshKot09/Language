/// API Endpoints for LINGUA AI services.
class ApiEndpoints {
  static const String health = '/health';
  static const String apiV1Health = '/api/v1/health';

  // Phase 3A Firebase Auth & Profile Endpoints
  static const String authSync = '/api/v1/auth/sync';
  static const String logout = '/api/v1/auth/logout';
  static const String me = '/api/v1/auth/me';

  static const String profile = '/api/v1/profile/';
  static const String profileOnboarding = '/api/v1/profile/onboarding';
  static const String profileAccessibility = '/api/v1/profile/accessibility';

  // Phase 4 Skills, Baseline, and Learner Endpoints
  static const String skills = '/api/v1/skills';
  static const String baselineSessions = '/api/v1/baseline/sessions';
  static const String learnerSnapshot = '/api/v1/learner/skill-snapshot';
  static const String learnerGoals = '/api/v1/learner/goals';

  // Phase 5 Learning Engine Endpoints
  static const String lessons = '/api/v1/lessons';
  static const String practice = '/api/v1/practice';
  static const String learningPath = '/api/v1/learning-path';
  static String lessonDetail(String lessonId) => '/api/v1/lessons/$lessonId';
  static String lessonStart(String lessonId) => '/api/v1/lessons/$lessonId/start';
  static String lessonState(String lessonId) => '/api/v1/lessons/$lessonId/state';
  static String lessonComplete(String lessonId) => '/api/v1/lessons/$lessonId/complete';
  static String exerciseAttempt(String exerciseId) => '/api/v1/exercises/$exerciseId/attempt';

  // Phase 10 Progress, Goals & Achievements Endpoints
  static const String progress = '/api/v1/progress';
  static const String progressSkills = '/api/v1/progress/skills';
  static const String progressTimeline = '/api/v1/progress/timeline';
  static const String goals = '/api/v1/goals';
  static String goalDetail(String goalId) => '/api/v1/goals/$goalId';
  static const String achievements = '/api/v1/achievements';
  static const String recommendations = '/api/v1/recommendations';

  // Phase 11 Collaboration, Professional Workspaces & Reports
  static const String relationships = '/api/v1/relationships';
  static const String relationshipInvitations = '/api/v1/relationships/invitations';
  static const String relationshipAudit = '/api/v1/relationships/audit';
  static const String parentChildren = '/api/v1/parent/children';
  static String parentChildProgress(String childId) => '/api/v1/parent/children/$childId/progress';
  static String parentChildHomePractice(String childId) => '/api/v1/parent/children/$childId/home-practice';
  static const String teacherStudents = '/api/v1/teacher/students';
  static String teacherStudentProgress(String studentId) => '/api/v1/teacher/students/$studentId/progress';
  static const String teacherAssignments = '/api/v1/teacher/assignments';
  static const String teacherClassroomTrends = '/api/v1/teacher/classroom-trends';
  static const String specialistCaseload = '/api/v1/specialist/caseload';
  static String specialistLearnerDetail(String learnerId) => '/api/v1/specialist/learners/$learnerId';
  static String specialistLearnerGoals(String learnerId) => '/api/v1/specialist/learners/$learnerId/goals';
  static String specialistLearnerAiRecs(String learnerId) => '/api/v1/specialist/learners/$learnerId/ai-recommendations';
  static String specialistReviewAiRec(String recId) => '/api/v1/specialist/ai-recommendations/$recId';
  static const String reports = '/api/v1/reports';
  static String reportDetail(String reportId) => '/api/v1/reports/$reportId';
  static String reportPdf(String reportId) => '/api/v1/reports/$reportId/pdf';
  static const String specialists = '/api/v1/specialists';
  static const String parentAppointSpecialist = '/api/v1/parent/appoint-specialist';
}


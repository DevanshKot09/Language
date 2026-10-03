import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_ai/features/collaboration/domain/models/collaboration_models.dart';
import 'package:lingua_ai/features/collaboration/data/collaboration_repository.dart';
import '../helpers/mock_api_client.dart';

void main() {
  group('Phase 11 Collaboration Domain Models Tests', () {
    test('RelationshipItem fromJson parses correctly and reports isActive / isPending', () {
      final json = {
        'id': 'rel-1',
        'source_user_id': 'u-parent',
        'target_user_id': 'u-child',
        'target_learner_name': 'Leo',
        'relationship_type': 'parent',
        'status': 'active',
        'permission_scope': ['view_progress', 'view_goals'],
        'consent_status': 'verified',
        'organization': 'Family Circle',
        'created_at': '2026-09-01T10:00:00Z',
      };

      final rel = RelationshipItem.fromJson(json);
      expect(rel.id, equals('rel-1'));
      expect(rel.targetLearnerName, equals('Leo'));
      expect(rel.relationshipType, equals('parent'));
      expect(rel.status, equals('active'));
      expect(rel.isActive, isTrue);
      expect(rel.isPending, isFalse);
      expect(rel.permissionScope, contains('view_progress'));
      expect(rel.organization, equals('Family Circle'));
    });

    test('InvitationItem parses pending token and role', () {
      final json = {
        'id': 'inv-1',
        'inviter_id': 'u-teacher',
        'invitee_email': 'specialist@school.edu',
        'relationship_type': 'specialist',
        'status': 'pending',
        'invitation_token': 'secure-token-12345',
        'expires_at': '2026-10-15T00:00:00Z',
        'created_at': '2026-10-01T00:00:00Z',
      };

      final inv = InvitationItem.fromJson(json);
      expect(inv.id, equals('inv-1'));
      expect(inv.inviteeEmail, equals('specialist@school.edu'));
      expect(inv.relationshipType, equals('specialist'));
      expect(inv.invitationToken, equals('secure-token-12345'));
      expect(inv.isPending, isTrue);
    });

    test('AssignmentItem parses status, completion, and lesson title', () {
      final json = {
        'id': 'asg-1',
        'teacher_id': 't-1',
        'student_id': 's-1',
        'lesson_id': 'lesson-vocab-1',
        'title': 'Active Sentence Building Practice',
        'instructions': 'Practice the sentence builders 3 times.',
        'status': 'assigned',
        'due_at': '2026-10-10T12:00:00Z',
        'created_at': '2026-10-01T12:00:00Z',
        'lesson_title': 'Active Sentence Building',
      };

      final asg = AssignmentItem.fromJson(json);
      expect(asg.id, equals('asg-1'));
      expect(asg.lessonTitle, equals('Active Sentence Building'));
      expect(asg.isPending, isTrue);
      expect(asg.isCompleted, isFalse);
    });

    test('ReportItem parses non-diagnostic attributes', () {
      final json = {
        'id': 'rep-1',
        'learner_id': 'l-1',
        'created_by': 's-1',
        'report_type': 'specialist_summary',
        'title': 'Specialist Educational Support Dossier',
        'status': 'ready',
        'created_at': '2026-10-01T12:00:00Z',
      };

      final rep = ReportItem.fromJson(json);
      expect(rep.id, equals('rep-1'));
      expect(rep.reportType, equals('specialist_summary'));
      expect(rep.title, equals('Specialist Educational Support Dossier'));
      expect(rep.isReady, isTrue);
    });

    test('ParentChildItem parses guardian consent state', () {
      final json = {
        'learner_id': 'c-1',
        'display_name': 'Maya',
        'age_band': 'child',
        'support_focus': 'dld_track',
        'guardian_consent_status': 'verified',
        'relationship_id': 'r-1',
      };

      final child = ParentChildItem.fromJson(json);
      expect(child.learnerId, equals('c-1'));
      expect(child.displayName, equals('Maya'));
      expect(child.guardianConsentStatus, equals('verified'));
    });

    test('TeacherStudentItem parses student roster item', () {
      final json = {
        'student_id': 'st-1',
        'display_name': 'Alex',
        'age_band': 'teen',
        'support_focus': 'dyslexia_track',
        'relationship_id': 'rel-t-1',
        'assignments_total': 3,
        'assignments_completed': 2,
      };

      final student = TeacherStudentItem.fromJson(json);
      expect(student.studentId, equals('st-1'));
      expect(student.displayName, equals('Alex'));
      expect(student.supportFocus, equals('dyslexia_track'));
      expect(student.assignmentsTotal, equals(3));
      expect(student.assignmentsCompleted, equals(2));
    });

    test('SpecialistCaseloadItem preserves non-diagnostic caseload data', () {
      final json = {
        'learner_id': 'ln-1',
        'display_name': 'Sam',
        'age_band': 'adult',
        'support_focus': 'dld_track',
        'relationship_id': 'rel-sp-1',
        'baseline_status': 'completed',
        'pending_ai_recommendations': 2,
        'organization': 'Speech Horizons',
      };

      final item = SpecialistCaseloadItem.fromJson(json);
      expect(item.learnerId, equals('ln-1'));
      expect(item.organization, equals('Speech Horizons'));
      expect(item.pendingAiRecommendations, equals(2));
      expect(item.baselineStatus, equals('completed'));
    });
  });

  group('CollaborationRepository Unit Tests with MockApiClient', () {
    late MockApiClient mockClient;
    late CollaborationRepository repository;

    setUp(() {
      mockClient = MockApiClient();
      repository = CollaborationRepository(mockClient);
    });

    test('getRelationships calls endpoint and returns items', () async {
      mockClient.mockResponse = [
        {
          'id': 'rel-1',
          'source_user_id': 'p-1',
          'target_user_id': 'c-1',
          'target_learner_name': 'Leo',
          'relationship_type': 'parent',
          'status': 'active',
          'permission_scope': ['view_progress'],
          'created_at': '2026-10-01T00:00:00Z',
        }
      ];

      final results = await repository.getRelationships();
      expect(results.length, equals(1));
      expect(results.first.targetLearnerName, equals('Leo'));
    });

    test('createInvitation posts body and returns InvitationItem', () async {
      mockClient.mockResponse = {
        'id': 'inv-1',
        'inviter_id': 'p-1',
        'invitee_email': 'teacher@school.org',
        'relationship_type': 'teacher',
        'status': 'pending',
        'invitation_token': 'token-999',
        'created_at': '2026-10-01T00:00:00Z',
      };

      final result = await repository.createInvitation(
        inviteeEmail: 'teacher@school.org',
        relationshipType: 'teacher',
      );

      expect(result.inviteeEmail, equals('teacher@school.org'));
      expect(result.invitationToken, equals('token-999'));
    });

    test('acceptInvitation posts token and returns active relationship', () async {
      mockClient.mockResponse = {
        'id': 'rel-accepted',
        'source_user_id': 'inviter',
        'target_user_id': 'learner',
        'target_learner_name': 'Learner A',
        'relationship_type': 'specialist',
        'status': 'active',
        'permission_scope': ['view_skill_history'],
        'created_at': '2026-10-01T00:00:00Z',
      };

      final rel = await repository.acceptInvitation('token-999');
      expect(rel.status, equals('active'));
    });

    test('revokeRelationship deletes relationship successfully', () async {
      mockClient.mockResponse = {'message': 'Relationship revoked.'};
      await repository.revokeRelationship('rel-to-revoke');
    });

    test('getParentChildren returns authorized child list', () async {
      mockClient.mockResponse = [
        {
          'learner_id': 'child-101',
          'display_name': 'Child A',
          'age_band': 'child',
          'support_focus': 'dld_track',
          'guardian_consent_status': 'verified',
          'relationship_id': 'rel-p-1',
        }
      ];

      final children = await repository.getParentChildren();
      expect(children.length, equals(1));
      expect(children.first.displayName, equals('Child A'));
    });

    test('getTeacherStudents returns roster', () async {
      mockClient.mockResponse = [
        {
          'student_id': 'student-1',
          'display_name': 'Student 1',
          'age_band': 'child',
          'support_focus': 'dyslexia_track',
          'relationship_id': 'rel-t-1',
          'assignments_total': 1,
          'assignments_completed': 1,
        }
      ];

      final students = await repository.getTeacherStudents();
      expect(students.length, equals(1));
      expect(students.first.displayName, equals('Student 1'));
    });

    test('createTeacherAssignment returns AssignmentItem', () async {
      mockClient.mockResponse = {
        'id': 'asg-new',
        'teacher_id': 't-1',
        'student_id': 'student-1',
        'lesson_id': 'lesson-1',
        'title': 'Daily Phonics',
        'status': 'assigned',
        'created_at': '2026-10-01T00:00:00Z',
      };

      final asg = await repository.createAssignment(
        studentId: 'student-1',
        lessonId: 'lesson-1',
        title: 'Daily Phonics',
      );

      expect(asg.id, equals('asg-new'));
      expect(asg.title, equals('Daily Phonics'));
    });

    test('getSpecialistCaseload returns caseload items', () async {
      mockClient.mockResponse = [
        {
          'learner_id': 'l-caseload-1',
          'display_name': 'Learner Caseload 1',
          'age_band': 'teen',
          'support_focus': 'dld_track',
          'relationship_id': 'rel-sp-1',
          'baseline_status': 'completed',
          'pending_ai_recommendations': 2,
        }
      ];

      final caseload = await repository.getSpecialistCaseload();
      expect(caseload.length, equals(1));
      expect(caseload.first.displayName, equals('Learner Caseload 1'));
    });

    test('createReport returns ReportItem', () async {
      mockClient.mockResponse = {
        'id': 'rep-new',
        'learner_id': 'l-1',
        'created_by': 'prof-1',
        'report_type': 'specialist_summary',
        'title': 'Learning Progress Summary',
        'status': 'ready',
        'created_at': '2026-10-01T00:00:00Z',
      };

      final report = await repository.createReport(
        learnerId: 'l-1',
        reportType: 'specialist_summary',
        title: 'Learning Progress Summary',
      );

      expect(report.id, equals('rep-new'));
      expect(report.status, equals('ready'));
    });
  });
}

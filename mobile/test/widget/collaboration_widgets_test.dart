import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingua_ai/features/collaboration/domain/models/collaboration_models.dart';
import 'package:lingua_ai/features/collaboration/presentation/widgets/relationship_badge.dart';
import 'package:lingua_ai/features/collaboration/presentation/widgets/learner_card_tile.dart';
import 'package:lingua_ai/features/collaboration/presentation/widgets/assignment_card.dart';
import 'package:lingua_ai/features/collaboration/presentation/widgets/report_card.dart';
import 'package:lingua_ai/features/collaboration/presentation/widgets/ai_review_card.dart';
import 'package:lingua_ai/features/collaboration/presentation/screens/parent_dashboard_screen.dart';
import 'package:lingua_ai/features/collaboration/presentation/screens/teacher_dashboard_screen.dart';
import 'package:lingua_ai/features/collaboration/presentation/screens/specialist_dashboard_screen.dart';
import 'package:lingua_ai/features/collaboration/presentation/screens/relationships_screen.dart';
import 'package:lingua_ai/features/collaboration/presentation/screens/invite_collaborator_screen.dart';
import 'package:lingua_ai/features/collaboration/application/collaboration_providers.dart';

void main() {
  group('Phase 11 Collaboration Presentation Widget Tests', () {
    testWidgets('RelationshipBadge renders active and pending labels with distinct colors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                RelationshipBadge(status: 'active'),
                RelationshipBadge(status: 'pending'),
                RelationshipBadge(status: 'revoked'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Connected'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Revoked'), findsOneWidget);
    });

    testWidgets('LearnerCardTile renders learner name, track, and consent status', (tester) async {
      const child = ParentChildItem(
        relationshipId: 'rel-1',
        learnerId: 'c-1',
        displayName: 'Leo',
        ageBand: 'child',
        supportFocus: 'dld_track',
        guardianConsentStatus: 'verified',
        status: 'active',
        permissionScope: ['view_progress'],
      );

      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LearnerCardTile(
              displayName: child.displayName,
              ageBand: child.ageBand,
              supportFocus: child.supportFocus,
              status: child.status,
              subtitle: 'Consent Verified',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Leo'), findsOneWidget);
      expect(find.text('CHILD'), findsOneWidget);
      expect(find.text('Spoken Language (DLD)'), findsOneWidget);
      expect(find.text('Consent Verified'), findsOneWidget);

      await tester.tap(find.byType(LearnerCardTile));
      expect(tapped, isTrue);
    });

    testWidgets('AssignmentCard displays title, instructions, and status chip', (tester) async {
      final assignment = AssignmentItem(
        id: 'asg-1',
        teacherId: 't-1',
        teacherName: 'Ms. Smith',
        studentId: 's-1',
        studentName: 'Alex',
        lessonId: 'l-1',
        title: 'Vocabulary Word Association',
        instructions: 'Complete exercises 1 to 3 before Friday.',
        status: 'assigned',
        lessonTitle: 'Word Association Basics',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AssignmentCard(assignment: assignment),
          ),
        ),
      );

      expect(find.text('Vocabulary Word Association'), findsOneWidget);
      expect(find.text('Complete exercises 1 to 3 before Friday.'), findsOneWidget);
      expect(find.text('Student: Alex • Lesson: Word Association Basics'), findsOneWidget);
      expect(find.text('ASSIGNED'), findsOneWidget);
    });

    testWidgets('ReportCard displays non-diagnostic title, date, and download action', (tester) async {
      final report = ReportItem(
        id: 'rep-1',
        creatorId: 'prof-1',
        creatorName: 'Specialist Taylor',
        learnerId: 'l-1',
        learnerName: 'Sam',
        reportType: 'specialist_summary',
        title: 'Quarterly Educational Progress Dossier',
        summaryData: const {'total_lessons': 10},
        disclaimer: 'This report summarizes learning-support activity within LINGUA AI.',
        status: 'ready',
        createdAt: DateTime(2026, 9, 30),
      );

      bool downloaded = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReportCard(
              report: report,
              onDownload: () => downloaded = true,
            ),
          ),
        ),
      );

      expect(find.text('Quarterly Educational Progress Dossier'), findsOneWidget);
      expect(find.text('Educational learning summary. Not a clinical diagnosis or medical evaluation.'), findsOneWidget);
      expect(find.text('Specialist Support Review'), findsOneWidget);

      await tester.tap(find.text('Download PDF Report'));
      expect(downloaded, isTrue);
    });

    testWidgets('AiReviewCard displays human review actions and triggers callback', (tester) async {
      String? selectedAction;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiReviewCard(
              recommendationId: 'rec-1',
              lessonTitle: 'Story Retell Practice',
              explanation: 'Learner demonstrated high confidence with short sentence stems.',
              humanStatus: 'pending',
              onAction: (action) => selectedAction = action,
            ),
          ),
        ),
      );

      expect(find.text('Story Retell Practice'), findsOneWidget);
      expect(find.text('Learner demonstrated high confidence with short sentence stems.'), findsOneWidget);
      expect(find.text('Approve'), findsOneWidget);
      expect(find.text('Reject'), findsOneWidget);

      await tester.tap(find.text('Approve'));
      expect(selectedAction, equals('approved'));
    });
  });

  group('Phase 11 Role Dashboards and Screens Tests', () {
    testWidgets('ParentDashboardScreen renders header and handles empty state cleanly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            parentChildrenProvider.overrideWith((ref) => Future.value([])),
          ],
          child: const MaterialApp(
            home: ParentDashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Parent Workspace'), findsOneWidget);
      expect(find.text('No learners connected yet.'), findsOneWidget);
      expect(find.text('Add Learner'), findsOneWidget);
    });

    testWidgets('TeacherDashboardScreen renders tabs and student roster', (tester) async {
      const mockStudents = [
        TeacherStudentItem(
          relationshipId: 'rel-1',
          studentId: 'st-1',
          displayName: 'Jordan',
          ageBand: 'child',
          supportFocus: 'dld_track',
          assignmentsTotal: 2,
          assignmentsCompleted: 1,
          status: 'active',
        )
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            teacherStudentsProvider.overrideWith((ref) => Future.value(mockStudents)),
            teacherAssignmentsProvider.overrideWith((ref) => Future.value([])),
            teacherClassroomTrendsProvider.overrideWith((ref) => Future.value({
                  'total_students': 1,
                  'total_assignments_completed': 1,
                  'class_completion_rate': 50.0,
                  'frequent_practice_tracks': ['dld_track'],
                })),
          ],
          child: const MaterialApp(
            home: TeacherDashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Educator Workspace'), findsOneWidget);
      expect(find.text('Jordan'), findsOneWidget);
      expect(find.text('CHILD'), findsOneWidget);
      expect(find.text('Spoken Language (DLD)'), findsOneWidget);
      expect(find.text('Assignments: 1/2 completed'), findsOneWidget);
    });

    testWidgets('SpecialistDashboardScreen renders Stitch reference dashboard and caseload tab', (tester) async {
      const mockCaseload = [
        SpecialistCaseloadItem(
          relationshipId: 'rel-sp-10',
          learnerId: 'ln-10',
          displayName: 'Taylor',
          ageBand: 'teen',
          supportFocus: 'dyslexia_track',
          baselineStatus: 'completed',
          pendingAiRecommendations: 1,
          status: 'active',
          organization: 'Speech Horizons',
        )
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            specialistCaseloadProvider.overrideWith((ref) => Future.value(mockCaseload)),
          ],
          child: const MaterialApp(
            home: SpecialistDashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Verify Stitch Home Dashboard Visual Hierarchy
      expect(find.text('Lingua AI'), findsOneWidget);
      expect(find.text('SPECIALIST'), findsOneWidget);
      expect(find.text("Here's what needs your attention today."), findsOneWidget);
      expect(find.text('Action required'), findsOneWidget);
      expect(find.text('Review requests'), findsOneWidget);
      expect(find.text('QUICK TOOLS'), findsOneWidget);
      expect(find.text('Consents'), findsOneWidget);
      expect(find.text('AI Suggestions'), findsOneWidget);
      expect(find.text('Recent Activity'), findsOneWidget);

      // 2. Switch to Caseload Tab to verify Caseload roster
      await tester.tap(find.text('Caseload').last);
      await tester.pumpAndSettle();

      expect(find.text('Specialist Caseload'), findsOneWidget);
      expect(find.text('Taylor'), findsOneWidget);
      expect(find.text('TEEN'), findsOneWidget);
      expect(find.text('Literacy & Reading'), findsOneWidget);
      expect(find.text('Baseline: COMPLETED • Pending AI Reviews: 1'), findsOneWidget);
    });

    testWidgets('RelationshipsScreen shows active relationships and pending invitations', (tester) async {
      final mockRels = [
        RelationshipItem(
          id: 'r-1',
          sourceUserId: 'u-1',
          targetUserId: 'u-2',
          targetLearnerName: 'Avery',
          relationshipType: 'specialist',
          status: 'active',
          permissionScope: const ['view_skill_history', 'view_baseline'],
          consentStatus: 'verified',
          createdAt: DateTime.now(),
        )
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            relationshipsProvider.overrideWith((ref) => Future.value(mockRels)),
            invitationsProvider.overrideWith((ref) => Future.value([])),
          ],
          child: const MaterialApp(
            home: RelationshipsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Authorized Connections'), findsOneWidget);
      expect(find.text('Avery'), findsOneWidget);
      expect(find.text('Role: SPECIALIST'), findsOneWidget);
      expect(find.text('Permissions: view_skill_history, view_baseline'), findsOneWidget);
    });

    testWidgets('InviteCollaboratorScreen renders input fields and relationship role selector', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: InviteCollaboratorScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Invite Collaborator'), findsOneWidget);
      expect(find.text('Collaborator Email'), findsOneWidget);
      expect(find.text('Relationship Role'), findsOneWidget);
      expect(find.text('Send Invitation Token'), findsOneWidget);
    });
  });
}

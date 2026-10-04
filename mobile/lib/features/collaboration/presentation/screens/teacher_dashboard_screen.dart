import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_tokens/tokens.dart';
import '../../../../core/widgets/lingua_button.dart';
import '../../../../core/widgets/lingua_animated_card.dart';
import '../../../../app/router/app_router.dart';
import '../../application/collaboration_providers.dart';
import '../widgets/learner_card_tile.dart';
import '../widgets/assignment_card.dart';

class TeacherDashboardScreen extends ConsumerStatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  ConsumerState<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends ConsumerState<TeacherDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(teacherStudentsProvider);
    final assignmentsAsync = ref.watch(teacherAssignmentsProvider);
    final trendsAsync = ref.watch(teacherClassroomTrendsProvider);

    return Scaffold(
      backgroundColor: LinguaTokens.paper50,
      appBar: AppBar(
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text('Educator Workspace', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ),
        backgroundColor: LinguaTokens.paper100,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_outlined),
            tooltip: 'Add Student',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.inviteCollaborator),
          ),
          IconButton(
            icon: const Icon(Icons.description_outlined),
            tooltip: 'Reports',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.learnerReport),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: LinguaTokens.primary700,
          unselectedLabelColor: LinguaTokens.inkMuted,
          indicatorColor: LinguaTokens.primary600,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Roster'),
            Tab(text: 'Assignments'),
            Tab(text: 'Trends'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Student Roster
          studentsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => _buildErrorState('Error loading students', () => ref.refresh(teacherStudentsProvider)),
            data: (students) {
              if (students.isEmpty) {
                return _buildEmptyState(
                  icon: Icons.school_outlined,
                  title: 'No students connected yet',
                  subtitle: 'Invite students to establish an authorized connection and assign practice lessons.',
                  actionLabel: '+ Add Student',
                  onAction: () => Navigator.pushNamed(context, AppRoutes.inviteCollaborator),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(LinguaTokens.space16),
                itemCount: students.length,
                itemBuilder: (ctx, i) {
                  final s = students[i];
                  return LinguaAnimatedCard(
                    animationDelayMs: i * 50,
                    margin: const EdgeInsets.only(bottom: LinguaTokens.space12),
                    child: LearnerCardTile(
                      displayName: s.displayName,
                      ageBand: s.ageBand,
                      supportFocus: s.supportFocus,
                      status: s.status,
                      subtitle: 'Assignments: ${s.assignmentsCompleted}/${s.assignmentsTotal} completed',
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.specialistLearnerDetail,
                        arguments: s.studentId,
                      ),
                    ),
                  );
                },
              );
            },
          ),

          // 2. Assignments
          assignmentsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => _buildErrorState('Error loading assignments', () => ref.refresh(teacherAssignmentsProvider)),
            data: (assignments) {
              if (assignments.isEmpty) {
                return _buildEmptyState(
                  icon: Icons.assignment_outlined,
                  title: 'No assignments created yet',
                  subtitle: 'Create curriculum practice tasks for connected students with personalized focus.',
                  actionLabel: '+ Create Assignment',
                  onAction: () => Navigator.pushNamed(context, AppRoutes.createAssignment),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(LinguaTokens.space16),
                itemCount: assignments.length,
                itemBuilder: (ctx, i) => LinguaAnimatedCard(
                  animationDelayMs: i * 50,
                  margin: const EdgeInsets.only(bottom: LinguaTokens.space12),
                  child: AssignmentCard(assignment: assignments[i]),
                ),
              );
            },
          ),

          // 3. Trends & Classroom Analytics
          trendsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => _buildErrorState('Error loading trends', () => ref.refresh(teacherClassroomTrendsProvider)),
            data: (trends) {
              final totalStudents = trends['total_students'] ?? 0;
              final totalAssignments = trends['total_assignments_created'] ?? 0;
              final completed = trends['assignments_completed'] ?? 0;
              final rate = trends['assignment_completion_rate'] ?? 0.0;
              final overview = trends['practice_overview'] ?? 'Connect with students to see aggregated classroom learning trends.';

              return SingleChildScrollView(
                padding: const EdgeInsets.all(LinguaTokens.space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Classroom Learning Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: LinguaTokens.space12),
                    LinguaAnimatedCard(
                      backgroundColor: LinguaTokens.paper100,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildTrendMetric('Students', '$totalStudents'),
                              _buildTrendMetric('Assigned', '$totalAssignments'),
                              _buildTrendMetric('Completed', '$completed'),
                              _buildTrendMetric('Rate', '$rate%'),
                            ],
                          ),
                          const Divider(height: LinguaTokens.space24),
                          Text(
                            overview.toString(),
                            style: const TextStyle(fontSize: 13, color: LinguaTokens.ink700, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: LinguaTokens.space16),
                    Container(
                      padding: const EdgeInsets.all(LinguaTokens.space12),
                      decoration: BoxDecoration(
                        color: LinguaTokens.paper100,
                        borderRadius: BorderRadius.circular(LinguaTokens.radiusSmall),
                      ),
                      child: const Text(
                        'Classroom analytics are aggregated and non-diagnostic. Student rankings and competitive comparisons are strictly avoided.',
                        style: TextStyle(fontSize: 12, color: LinguaTokens.inkMuted),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.createAssignment),
        backgroundColor: LinguaTokens.primary600,
        icon: const Icon(Icons.assignment_add, color: Colors.white),
        label: const Text('Assign Practice', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(LinguaTokens.space24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: LinguaTokens.primary100,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: LinguaTokens.primary600),
            ),
            const SizedBox(height: LinguaTokens.space16),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: LinguaTokens.ink900),
            ),
            const SizedBox(height: LinguaTokens.space8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: LinguaTokens.inkMuted, height: 1.4),
            ),
            const SizedBox(height: LinguaTokens.space20),
            LinguaButton(
              label: actionLabel,
              onPressed: onAction,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(LinguaTokens.space24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 44, color: LinguaTokens.danger600),
            const SizedBox(height: 12),
            Text(message, style: const TextStyle(fontSize: 14, color: LinguaTokens.ink700)),
            const SizedBox(height: 16),
            LinguaButton(label: 'Retry', icon: Icons.refresh, onPressed: onRetry),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendMetric(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: LinguaTokens.primary700)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: LinguaTokens.inkMuted)),
      ],
    );
  }
}

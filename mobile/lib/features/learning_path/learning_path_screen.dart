import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/design_tokens/tokens.dart';
import '../../core/widgets/non_diagnostic_banner.dart';
import '../../core/widgets/lingua_button.dart';
import '../../core/widgets/lingua_animated_card.dart';
import '../../app/router/app_router.dart';
import '../learning/application/learning_providers.dart';
import '../learning/domain/models/learning_path_model.dart';

/// UX-13 PERSONALIZED LEARNING PATH SCREEN
/// Visual sequence map showing curriculum progression without diagnostic labels.
/// Driven by real backend learning path data and rule-based selection.
class LearningPathScreen extends ConsumerStatefulWidget {
  const LearningPathScreen({super.key});

  @override
  ConsumerState<LearningPathScreen> createState() => _LearningPathScreenState();
}

class _LearningPathScreenState extends ConsumerState<LearningPathScreen> {
  bool _showFullCurriculum = false;

  @override
  Widget build(BuildContext context) {
    final pathAsync = ref.watch(learningPathProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: LinguaTokens.ink900),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'My Skill Path',
          style: TextStyle(color: LinguaTokens.ink900, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: LinguaTokens.ink700),
            tooltip: 'Refresh Path',
            onPressed: () => ref.invalidate(learningPathProvider),
          ),
        ],
      ),
      body: SafeArea(
        child: pathAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: LinguaTokens.primary600),
          ),
          error: (err, stack) => _buildFallbackPath(context),
          data: (path) => _buildPathContent(context, path),
        ),
      ),
    );
  }

  Widget _buildPathContent(BuildContext context, LearningPathModel path) {
    final nodes = path.nodes;
    final activeNode = nodes.firstWhere(
      (n) => n.isActive,
      orElse: () => nodes.isNotEmpty ? nodes.first : _defaultActiveNode,
    );

    const maxInitialNodes = 4;
    final initialNodes = nodes.take(maxInitialNodes).toList();
    final remainingNodes = nodes.length > maxInitialNodes ? nodes.skip(maxInitialNodes).toList() : <LearningPathNodeModel>[];

    final isDld = activeNode.track.contains('dld');
    final activeTrackColor = isDld ? LinguaTokens.dldTrack : LinguaTokens.dyslexiaTrack;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: LinguaTokens.space24,
        vertical: LinguaTokens.space12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const NonDiagnosticBanner(compact: true),
          const SizedBox(height: LinguaTokens.space16),

          // Header
          const Text(
            'Personalized Learning Sequence',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.4, color: LinguaTokens.ink900),
          ),
          const SizedBox(height: 4),
          const Text(
            'Progress step-by-step through speech, language, and reading milestones.',
            style: TextStyle(fontSize: 13, color: LinguaTokens.ink700),
          ),
          const SizedBox(height: LinguaTokens.space16),

          // Hero Active Lesson Card
          Container(
            padding: const EdgeInsets.all(LinguaTokens.space16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  activeTrackColor.withValues(alpha: 0.08),
                  activeTrackColor.withValues(alpha: 0.03),
                ],
              ),
              borderRadius: BorderRadius.circular(LinguaTokens.radiusHero),
              border: Border.all(color: activeTrackColor.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: activeTrackColor,
                        borderRadius: BorderRadius.circular(LinguaTokens.radiusPill),
                      ),
                      child: const Text(
                        'CURRENT PRACTICE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Text(
                      'Step ${activeNode.stepNumber}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: activeTrackColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: LinguaTokens.space12),
                Text(
                  'Active Focus: ${activeNode.title}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: LinguaTokens.ink900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${activeNode.skillName} • ${isDld ? "Spoken Language" : "Literacy Practice"}',
                  style: const TextStyle(fontSize: 13, color: LinguaTokens.ink700),
                ),
                const SizedBox(height: LinguaTokens.space16),
                LinguaButton(
                  label: 'Start Lesson',
                  icon: Icons.play_arrow_rounded,
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.lessonPlayer,
                      arguments: activeNode.lessonId,
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: LinguaTokens.space24),

          // Milestone Progression Section
          const Text(
            'Curriculum Milestones',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: LinguaTokens.ink900),
          ),
          const SizedBox(height: LinguaTokens.space12),

          // Initial nodes
          ...initialNodes.asMap().entries.map((entry) {
            final idx = entry.key;
            final node = entry.value;
            final nodeIsDld = node.track.contains('dld');
            final trackColor = nodeIsDld ? LinguaTokens.dldTrack : LinguaTokens.dyslexiaTrack;
            final trackLabel = nodeIsDld ? 'Spoken Track (DLD)' : 'Literacy (Dyslexia)';

            return _buildSkillNode(
              context: context,
              delayMs: 60 * (idx + 1),
              stepNumber: node.stepNumber,
              lessonId: node.lessonId,
              title: node.title,
              track: trackLabel,
              status: node.isCompleted
                  ? 'Completed'
                  : node.isActive
                      ? 'In Progress'
                      : 'Upcoming',
              isCompleted: node.isCompleted,
              isActive: node.isActive,
              color: trackColor,
              isLast: idx == initialNodes.length - 1 && remainingNodes.isEmpty && !_showFullCurriculum,
            );
          }),

          // Remaining nodes if expanded
          if (_showFullCurriculum) ...[
            ...remainingNodes.asMap().entries.map((entry) {
              final idx = entry.key;
              final node = entry.value;
              final nodeIsDld = node.track.contains('dld');
              final trackColor = nodeIsDld ? LinguaTokens.dldTrack : LinguaTokens.dyslexiaTrack;
              final trackLabel = nodeIsDld ? 'Spoken Track (DLD)' : 'Literacy (Dyslexia)';

              return _buildSkillNode(
                context: context,
                delayMs: 40 * (idx + 1),
                stepNumber: node.stepNumber,
                lessonId: node.lessonId,
                title: node.title,
                track: trackLabel,
                status: node.isCompleted
                    ? 'Completed'
                    : node.isActive
                        ? 'In Progress'
                        : 'Upcoming',
                isCompleted: node.isCompleted,
                isActive: node.isActive,
                color: trackColor,
                isLast: idx == remainingNodes.length - 1,
              );
            }),
          ],

          if (remainingNodes.isNotEmpty) ...[
            const SizedBox(height: LinguaTokens.space8),
            Center(
              child: TextButton.icon(
                icon: Icon(
                  _showFullCurriculum ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: LinguaTokens.primary600,
                ),
                label: Text(
                  _showFullCurriculum
                      ? 'Show Fewer Steps'
                      : 'View Entire Sequence (${remainingNodes.length} more steps)',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: LinguaTokens.primary600),
                ),
                onPressed: () => setState(() => _showFullCurriculum = !_showFullCurriculum),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFallbackPath(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: LinguaTokens.space24, vertical: LinguaTokens.space12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const NonDiagnosticBanner(compact: true),
          const SizedBox(height: LinguaTokens.space16),

          const Text(
            'Your Learning Journey',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: LinguaTokens.ink900),
          ),
          const SizedBox(height: 4),
          const Text(
            'Progress step-by-step through speech, language, and reading milestones.',
            style: TextStyle(fontSize: 13, color: LinguaTokens.ink700),
          ),
          const SizedBox(height: LinguaTokens.space16),

          _buildSkillNode(
            context: context,
            delayMs: 0,
            stepNumber: 1,
            lessonId: 'lesson-dld-001',
            title: 'Everyday Action Words',
            track: 'Spoken Track (DLD)',
            status: 'In Progress',
            isCompleted: false,
            isActive: true,
            color: LinguaTokens.dldTrack,
            isLast: false,
          ),
          _buildSkillNode(
            context: context,
            delayMs: 60,
            stepNumber: 2,
            lessonId: 'lesson-dyslexia-001',
            title: 'Phoneme Blending & Rhyme',
            track: 'Literacy (Dyslexia)',
            status: 'Upcoming',
            isCompleted: false,
            isActive: false,
            color: LinguaTokens.dyslexiaTrack,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSkillNode({
    required BuildContext context,
    required int delayMs,
    required int stepNumber,
    required String lessonId,
    required String title,
    required String track,
    required String status,
    required bool isCompleted,
    required bool isActive,
    required Color color,
    required bool isLast,
  }) {
    return LinguaAnimatedCard(
      animationDelayMs: delayMs,
      margin: const EdgeInsets.only(bottom: LinguaTokens.space12),
      padding: const EdgeInsets.all(LinguaTokens.space16),
      backgroundColor: isActive ? LinguaTokens.primary50 : LinguaTokens.surfaceCard,
      borderColor: isActive ? color : LinguaTokens.borderSubtle,
      borderWidth: isActive ? 2.0 : 1.0,
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.lessonPlayer,
          arguments: lessonId,
        );
      },
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: isCompleted
                ? LinguaTokens.success600
                : isActive
                    ? color
                    : LinguaTokens.paper100,
            child: isCompleted
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                : Text(
                    '$stepNumber',
                    style: TextStyle(
                      color: isActive ? Colors.white : LinguaTokens.inkMuted,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: LinguaTokens.ink900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    color: isCompleted
                        ? LinguaTokens.success600
                        : isActive
                            ? color
                            : LinguaTokens.inkMuted,
                    fontWeight: isCompleted || isActive ? FontWeight.w700 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          if (isActive)
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: LinguaTokens.primary600),
        ],
      ),
    );
  }

  static const _defaultActiveNode = LearningPathNodeModel(
    stepNumber: 1,
    lessonId: 'lesson-dld-001',
    title: 'Everyday Action Words',
    track: 'dld_track',
    skillName: 'Vocabulary',
    status: 'active',
    isCompleted: false,
    isActive: true,
    difficulty: 1,
  );
}

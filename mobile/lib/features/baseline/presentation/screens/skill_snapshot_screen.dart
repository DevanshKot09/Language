import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_tokens/tokens.dart';
import '../../../../core/widgets/non_diagnostic_banner.dart';
import '../../../../core/widgets/track_badge.dart';
import '../../../../core/widgets/lingua_button.dart';
import '../../../../app/providers/age_profile_provider.dart';
import '../../../../app/router/app_router.dart';
import '../../../../shared/models/skill_track.dart';
import '../../data/models/skill_snapshot_model.dart';
import '../../providers/baseline_provider.dart';

/// UX-10 SKILL SNAPSHOT & LEARNING PROFILE
/// Descriptive, non-diagnostic skill readiness breakdown across
/// DLD spoken language and Dyslexia literacy tracks.
class SkillSnapshotScreen extends ConsumerStatefulWidget {
  const SkillSnapshotScreen({super.key});

  @override
  ConsumerState<SkillSnapshotScreen> createState() => _SkillSnapshotScreenState();
}

class _SkillSnapshotScreenState extends ConsumerState<SkillSnapshotScreen> {
  String _selectedFilter = 'all'; // 'all', 'dld_track', 'dyslexia_track'

  void _showAddGoalDialog(BuildContext context, SkillSnapshotItemModel skill) {
    final titleController = TextEditingController(text: 'Practice ${skill.skillName}');
    String frequency = 'weekly';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(LinguaTokens.radiusCard)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: LinguaTokens.space20,
            right: LinguaTokens.space20,
            top: LinguaTokens.space20,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + LinguaTokens.space24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Set a Practice Goal',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(sheetCtx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Goal Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Target Frequency', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'daily', label: Text('Daily')),
                  ButtonSegment(value: 'weekly', label: Text('3x / Week')),
                  ButtonSegment(value: 'biweekly', label: Text('Weekly')),
                ],
                selected: {frequency},
                onSelectionChanged: (val) {
                  setSheetState(() => frequency = val.first);
                },
              ),
              const SizedBox(height: 20),
              LinguaButton(
                label: 'Save Goal',
                onPressed: () async {
                  final repo = ref.read(baselineRepositoryProvider);
                  await repo.createGoal(
                    title: titleController.text.trim(),
                    skillId: skill.skillId,
                    targetFrequency: frequency,
                  );
                  ref.invalidate(learnerGoalsProvider);
                  if (sheetCtx.mounted) {
                    Navigator.pop(sheetCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Goal saved for ${skill.skillName}!')),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ageProfile = ref.watch(ageProfileProvider);
    final snapshotAsync = ref.watch(skillSnapshotProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Skill Snapshot'),
        actions: [
          IconButton(
            tooltip: 'Accessibility',
            icon: const Icon(Icons.accessibility_new),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.accessibility),
          ),
        ],
      ),
      body: SafeArea(
        child: snapshotAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(LinguaTokens.space24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: LinguaTokens.danger600),
                  const SizedBox(height: 16),
                  const Text(
                    'Unable to load Skill Snapshot',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: LinguaTokens.inkMuted),
                  ),
                  const SizedBox(height: 24),
                  LinguaButton(
                    label: 'Retry',
                    onPressed: () => ref.refresh(skillSnapshotProvider),
                  ),
                ],
              ),
            ),
          ),
          data: (snapshot) {
            final filteredSkills = snapshot.skills.where((s) {
              if (_selectedFilter == 'all') return true;
              return s.track == _selectedFilter;
            }).toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(LinguaTokens.space20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Non-Diagnostic Safety Banner
                  const NonDiagnosticBanner(compact: true),
                  const SizedBox(height: LinguaTokens.space16),

                  // Header
                  Text(
                    'Your Learning Profile',
                    style: TextStyle(
                      fontSize: ageProfile.baseFontSize + 6,
                      fontWeight: FontWeight.bold,
                      color: LinguaTokens.ink900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Descriptive snapshot of baseline readiness across skill areas.',
                    style: TextStyle(fontSize: 13, color: LinguaTokens.inkMuted),
                  ),
                  const SizedBox(height: LinguaTokens.space16),

                  // Strength & Practice Quick Summaries
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          title: 'Strengths',
                          count: snapshot.strengthAreas.length,
                          color: LinguaTokens.success600,
                          bg: LinguaTokens.successLight,
                          icon: Icons.check_circle_outline,
                        ),
                      ),
                      const SizedBox(width: LinguaTokens.space12),
                      Expanded(
                        child: _buildSummaryCard(
                          title: 'Practice Areas',
                          count: snapshot.priorityPracticeAreas.length,
                          color: LinguaTokens.primary600,
                          bg: LinguaTokens.primary100,
                          icon: Icons.flag_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: LinguaTokens.space20),

                  // Track Filter Segmented Control
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'all', label: Text('All Skills')),
                        ButtonSegment(value: 'dld_track', label: Text('Spoken (DLD)')),
                        ButtonSegment(value: 'dyslexia_track', label: Text('Literacy')),
                      ],
                      selected: {_selectedFilter},
                      onSelectionChanged: (val) {
                        setState(() => _selectedFilter = val.first);
                      },
                    ),
                  ),
                  const SizedBox(height: LinguaTokens.space20),

                  // Skill Cards List
                  if (filteredSkills.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(LinguaTokens.space24),
                      alignment: Alignment.center,
                      child: const Text(
                        'No skills recorded yet for this track.',
                        style: TextStyle(color: LinguaTokens.inkMuted),
                      ),
                    )
                  else
                    ...filteredSkills.map(
                      (skill) => Padding(
                        padding: const EdgeInsets.only(bottom: LinguaTokens.space12),
                        child: _buildSkillCard(
                          context: context,
                          skill: skill,
                          fontSize: ageProfile.baseFontSize,
                        ),
                      ),
                    ),

                  const SizedBox(height: LinguaTokens.space24),

                  // Action Buttons
                  LinguaButton(
                    label: 'Continue to Learning Path',
                    minHeight: ageProfile.minTouchTarget,
                    onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.path),
                  ),
                  const SizedBox(height: LinguaTokens.space12),

                  LinguaButton(
                    label: 'Done',
                    variant: LinguaButtonVariant.secondary,
                    minHeight: ageProfile.minTouchTarget,
                    onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.home),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required int count,
    required Color color,
    required Color bg,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(LinguaTokens.space12),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$count Skills',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: LinguaTokens.ink700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillCard({
    required BuildContext context,
    required SkillSnapshotItemModel skill,
    required double fontSize,
  }) {
    final bandColor = _getBandColor(skill.band);
    final bandBg = _getBandBgColor(skill.band);

    return Container(
      padding: const EdgeInsets.all(LinguaTokens.space16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
        border: Border.all(color: LinguaTokens.borderSubtle),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  skill.skillName,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: LinguaTokens.ink900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: bandBg,
                  borderRadius: BorderRadius.circular(LinguaTokens.radiusPill),
                  border: Border.all(color: bandColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  skill.band,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: bandColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                skill.domain.toUpperCase(),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: LinguaTokens.inkMuted),
              ),
              TrackBadge(track: SupportTrackExtension.fromApiId(skill.track), compact: true),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: skill.accuracy,
            backgroundColor: LinguaTokens.borderSubtle,
            valueColor: AlwaysStoppedAnimation<Color>(bandColor),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: 8),
          Text(
            skill.description,
            style: const TextStyle(fontSize: 12, color: LinguaTokens.ink700, height: 1.4),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.flag_outlined, size: 16),
              label: const Text('Set Goal', style: TextStyle(fontSize: 12)),
              onPressed: () => _showAddGoalDialog(context, skill),
            ),
          ),
        ],
      ),
    );
  }

  Color _getBandColor(String band) {
    switch (band.toLowerCase()) {
      case 'consistent':
        return LinguaTokens.success600;
      case 'practicing':
        return LinguaTokens.primary600;
      case 'developing':
        return LinguaTokens.accent600;
      case 'starting':
      default:
        return const Color(0xFF7C3AED);
    }
  }

  Color _getBandBgColor(String band) {
    switch (band.toLowerCase()) {
      case 'consistent':
        return LinguaTokens.successLight;
      case 'practicing':
        return LinguaTokens.primary100;
      case 'developing':
        return LinguaTokens.accent100;
      case 'starting':
      default:
        return const Color(0xFFF3E8FF);
    }
  }
}

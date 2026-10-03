import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_tokens/tokens.dart';
import '../../../../core/widgets/lingua_button.dart';
import '../../../../core/widgets/lingua_animated_card.dart';
import '../../../../app/router/app_router.dart';
import '../../application/collaboration_providers.dart';
import '../widgets/learner_card_tile.dart';

class ParentDashboardScreen extends ConsumerStatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  ConsumerState<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends ConsumerState<ParentDashboardScreen> {
  String? _selectedChildId;

  void _showAddChildDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    String ageBand = 'child';
    String supportFocus = 'dld_track';
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
          ),
          title: const Row(
            children: [
              Icon(Icons.child_care, color: LinguaTokens.primary600, size: 28),
              SizedBox(width: 10),
              Text('Add Child Learner'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Child Name or Nickname', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    hintText: 'e.g. Aarav or Maya',
                    filled: true,
                    fillColor: LinguaTokens.paper100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(LinguaTokens.radiusSmall)),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Age Group', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: ageBand,
                  isExpanded: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: LinguaTokens.paper100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(LinguaTokens.radiusSmall)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'child', child: Text('Child (Ages 5–11)')),
                    DropdownMenuItem(value: 'teen', child: Text('Teen (Ages 12–17)')),
                    DropdownMenuItem(value: 'adult', child: Text('Adult (18+)')),
                  ],
                  onChanged: (val) => setDialogState(() => ageBand = val ?? 'child'),
                ),
                const SizedBox(height: 14),
                const Text('Support Learning Track', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: supportFocus,
                  isExpanded: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: LinguaTokens.paper100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(LinguaTokens.radiusSmall)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'dld_track', child: Text('Spoken Language (DLD Track)')),
                    DropdownMenuItem(value: 'dyslexia_track', child: Text('Reading & Literacy (Dyslexia Track)')),
                    DropdownMenuItem(value: 'both_track', child: Text('Comprehensive (Both Tracks)')),
                  ],
                  onChanged: (val) => setDialogState(() => supportFocus = val ?? 'dld_track'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: LinguaTokens.primary600,
                foregroundColor: Colors.white,
              ),
              onPressed: isSaving
                  ? null
                  : () async {
                      if (nameCtrl.text.trim().isEmpty) return;
                      final messenger = ScaffoldMessenger.of(context);
                      final nav = Navigator.of(ctx);
                      setDialogState(() => isSaving = true);
                      try {
                        final repo = ref.read(collaborationRepositoryProvider);
                        await repo.createChildProfile(
                          displayName: nameCtrl.text.trim(),
                          ageBand: ageBand,
                          supportFocus: supportFocus,
                        );
                        ref.invalidate(parentChildrenProvider);
                        nav.pop();
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Child learner profile added successfully!')),
                        );
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        messenger.showSnackBar(
                          SnackBar(content: Text('Failed to add child: $e')),
                        );
                      }
                    },
              child: isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Save & Connect'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAppointDoctorDialog(BuildContext context, String childId, String childName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final specialistsAsync = ref.watch(availableSpecialistsProvider);

          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(LinguaTokens.radiusHero)),
            ),
            padding: const EdgeInsets.all(LinguaTokens.space20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: LinguaTokens.borderSubtle,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.medical_services_outlined, color: LinguaTokens.primary600, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Appoint Doctor / Specialist',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: LinguaTokens.ink900),
                          ),
                          Text(
                            'Connect certified specialist for $childName',
                            style: const TextStyle(fontSize: 13, color: LinguaTokens.ink700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Available Registered Specialists',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: LinguaTokens.ink700),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: specialistsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Could not load specialists directory.'),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => ref.refresh(availableSpecialistsProvider),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                    data: (specialists) {
                      if (specialists.isEmpty) {
                        return const Center(
                          child: Text('No registered specialists found at this moment.'),
                        );
                      }
                      return ListView.separated(
                        itemCount: specialists.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final doc = specialists[i];
                          final docId = doc['id'] as String? ?? '';
                          final docName = doc['display_name'] as String? ?? 'Dr. Specialist';
                          final docEmail = doc['email'] as String? ?? '';
                          final docOrg = doc['organization'] as String? ?? 'Speech & Literacy Clinic';
                          final docFocus = doc['support_focus'] as String? ?? 'dld_track';
                          final focusLabel = docFocus == 'dld_track'
                              ? 'Speech & Language'
                              : docFocus == 'dyslexia_track'
                                  ? 'Reading & Literacy'
                                  : 'Comprehensive Practice';

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: LinguaTokens.paper100,
                              borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
                              border: Border.all(color: LinguaTokens.borderSubtle),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: LinguaTokens.primary100,
                                      child: const Icon(Icons.person, color: LinguaTokens.primary700),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            docName,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                          ),
                                          Text(
                                            docOrg,
                                            style: const TextStyle(fontSize: 12, color: LinguaTokens.ink700),
                                          ),
                                          Text(
                                            docEmail,
                                            style: const TextStyle(fontSize: 11, color: LinguaTokens.inkMuted),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: LinguaTokens.primary100,
                                        borderRadius: BorderRadius.circular(LinguaTokens.radiusPill),
                                      ),
                                      child: Text(
                                        focusLabel,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: LinguaTokens.primary700,
                                        ),
                                      ),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: LinguaTokens.primary600,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      ),
                                      onPressed: () async {
                                        try {
                                          final repo = ref.read(collaborationRepositoryProvider);
                                          final res = await repo.appointSpecialist(
                                            childId: childId,
                                            specialistId: docId,
                                          );
                                          ref.invalidate(relationshipsProvider);
                                          ref.invalidate(parentChildrenProvider);
                                          if (ctx.mounted) Navigator.pop(ctx);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(res['message'] as String? ?? 'Specialist appointed successfully!'),
                                                backgroundColor: LinguaTokens.success600,
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Failed to appoint specialist: $e'),
                                                backgroundColor: LinguaTokens.danger600,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      child: const Text('Appoint Doctor'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final childrenAsync = ref.watch(parentChildrenProvider);

    return Scaffold(
      backgroundColor: LinguaTokens.paper50,
      appBar: AppBar(
        title: const Text('Parent Workspace', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: LinguaTokens.paper100,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_outlined),
            tooltip: 'Add Child Learner',
            onPressed: () => _showAddChildDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.vpn_key_outlined),
            tooltip: 'Invite with Token',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.inviteCollaborator),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
          ),
        ],
      ),
      body: childrenAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(LinguaTokens.space24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: LinguaTokens.danger600),
                const SizedBox(height: LinguaTokens.space12),
                const Text(
                  'We couldn\'t load your connected learners right now.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: LinguaTokens.ink700),
                ),
                const SizedBox(height: LinguaTokens.space16),
                LinguaButton(
                  label: 'Retry',
                  icon: Icons.refresh,
                  onPressed: () => ref.refresh(parentChildrenProvider),
                ),
              ],
            ),
          ),
        ),
        data: (children) {
          if (children.isEmpty) {
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
                      child: const Icon(Icons.family_restroom, size: 48, color: LinguaTokens.primary600),
                    ),
                    const SizedBox(height: LinguaTokens.space20),
                    const Text(
                      'No learners connected yet.',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: LinguaTokens.ink900),
                    ),
                    const SizedBox(height: LinguaTokens.space8),
                    const Text(
                      'Connect with your child to review their learning progress, celebrate milestones, and support home practice.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: LinguaTokens.ink700, height: 1.4),
                    ),
                    const SizedBox(height: LinguaTokens.space24),
                    LinguaButton(
                      label: 'Add Learner',
                      onPressed: () => _showAddChildDialog(context),
                    ),
                    const SizedBox(height: LinguaTokens.space12),
                    LinguaButton(
                      label: 'Invite or Link via Token',
                      variant: LinguaButtonVariant.secondary,
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.inviteCollaborator),
                    ),
                  ],
                ),
              ),
            );
          }

          final selectedChild = children.firstWhere(
            (c) => c.learnerId == _selectedChildId,
            orElse: () => children.first,
          );

          final progressAsync = ref.watch(parentChildProgressProvider(selectedChild.learnerId));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(LinguaTokens.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Child Switcher if multiple children
                if (children.length > 1) ...[
                  const Text('Select Learner', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: LinguaTokens.ink700)),
                  const SizedBox(height: LinguaTokens.space8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: children.map((child) {
                        final isSelected = child.learnerId == selectedChild.learnerId;
                        return Padding(
                          padding: const EdgeInsets.only(right: LinguaTokens.space8),
                          child: ChoiceChip(
                            label: Text(child.displayName),
                            selected: isSelected,
                            onSelected: (val) {
                              if (val) setState(() => _selectedChildId = child.learnerId);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: LinguaTokens.space16),
                ],

                // Selected Child Card
                LearnerCardTile(
                  displayName: selectedChild.displayName,
                  ageBand: selectedChild.ageBand,
                  supportFocus: selectedChild.supportFocus,
                  status: selectedChild.status,
                  subtitle: 'Consent: ${selectedChild.guardianConsentStatus.toUpperCase()}',
                ),
                const SizedBox(height: LinguaTokens.space16),

                // Live Practice Overview if available
                progressAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => const SizedBox.shrink(),
                  data: (data) {
                    final completed = data.summary.totalLessonsCompleted;
                    final streak = data.summary.consistencyStreakDays;
                    final minutes = data.summary.totalPracticeTimeMinutes;

                    return LinguaAnimatedCard(
                      animationDelayMs: 60,
                      backgroundColor: LinguaTokens.paper100,
                      margin: const EdgeInsets.only(bottom: LinguaTokens.space16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Home Practice Snapshot',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: LinguaTokens.ink900),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildMetricItem('$completed', 'Lessons Done'),
                              _buildMetricItem('$minutes min', 'Practice Time'),
                              _buildMetricItem('$streak days', 'Consistency'),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Focused Action Shortcuts
                const Text('Family Tools', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: LinguaTokens.ink900)),
                const SizedBox(height: LinguaTokens.space12),

                _buildActionCard(
                  title: 'Appoint Specialist / Doctor',
                  description: 'Connect with a certified speech therapist or educator for professional review.',
                  icon: Icons.medical_services_outlined,
                  color: LinguaTokens.success600,
                  onTap: () => _showAppointDoctorDialog(
                    context,
                    selectedChild.learnerId,
                    selectedChild.displayName,
                  ),
                ),
                _buildActionCard(
                  title: 'Add Child Learner Profile',
                  description: 'Add a child profile directly to track their baseline & practice.',
                  icon: Icons.person_add_alt_1_outlined,
                  color: LinguaTokens.primary600,
                  onTap: () => _showAddChildDialog(context),
                ),
                _buildActionCard(
                  title: 'Learning Progress & Skills',
                  description: 'Track lesson milestones and skill readiness bands.',
                  icon: Icons.trending_up,
                  color: LinguaTokens.primary600,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.progress),
                ),
                _buildActionCard(
                  title: 'Family Learning Summary',
                  description: 'Generate and review non-diagnostic practice summaries.',
                  icon: Icons.description_outlined,
                  color: LinguaTokens.accent600,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.reportBuilder),
                ),
                _buildActionCard(
                  title: 'Connected Team & Privacy',
                  description: 'Review authorized teachers, specialists, and data controls.',
                  icon: Icons.shield_outlined,
                  color: LinguaTokens.ink700,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.relationships),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: LinguaTokens.primary700),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: LinguaTokens.inkMuted),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return LinguaAnimatedCard(
      margin: const EdgeInsets.only(bottom: LinguaTokens.space12),
      padding: const EdgeInsets.all(LinguaTokens.space16),
      backgroundColor: LinguaTokens.surfaceCard,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(LinguaTokens.space8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(LinguaTokens.radiusSmall),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: LinguaTokens.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: LinguaTokens.ink900)),
                const SizedBox(height: 2),
                Text(description, style: const TextStyle(fontSize: 12, color: LinguaTokens.inkMuted)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: LinguaTokens.inkMuted, size: 20),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_tokens/tokens.dart';
import '../../../../core/widgets/lingua_button.dart';
import '../../../../core/widgets/lingua_animated_card.dart';
import '../../../../app/router/app_router.dart';
import '../../application/collaboration_providers.dart';
import '../widgets/learner_card_tile.dart';
import '../widgets/ai_review_card.dart';

class SpecialistDashboardScreen extends ConsumerStatefulWidget {
  const SpecialistDashboardScreen({super.key});

  @override
  ConsumerState<SpecialistDashboardScreen> createState() => _SpecialistDashboardScreenState();
}

class _SpecialistDashboardScreenState extends ConsumerState<SpecialistDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final caseloadAsync = ref.watch(specialistCaseloadProvider);

    return Scaffold(
      backgroundColor: LinguaTokens.paper50,
      appBar: AppBar(
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text('Specialist Caseload', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ),
        backgroundColor: LinguaTokens.paper100,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_outlined),
            tooltip: 'Add Learner to Caseload',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.inviteCollaborator),
          ),
          IconButton(
            icon: const Icon(Icons.description_outlined),
            tooltip: 'Support Reports',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.reportBuilder),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: LinguaTokens.primary700,
          unselectedLabelColor: LinguaTokens.inkMuted,
          indicatorColor: LinguaTokens.primary600,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Caseload'),
            Tab(text: 'AI Oversight'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Caseload List
          caseloadAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(
              child: Padding(
                padding: const EdgeInsets.all(LinguaTokens.space24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 44, color: LinguaTokens.danger600),
                    const SizedBox(height: 12),
                    Text('Error loading caseload: $e', style: const TextStyle(fontSize: 14, color: LinguaTokens.ink700)),
                    const SizedBox(height: 16),
                    LinguaButton(
                      label: 'Retry',
                      icon: Icons.refresh,
                      onPressed: () => ref.refresh(specialistCaseloadProvider),
                    ),
                  ],
                ),
              ),
            ),
            data: (caseload) {
              if (caseload.isEmpty) {
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
                          child: const Icon(Icons.folder_shared_outlined, size: 44, color: LinguaTokens.primary600),
                        ),
                        const SizedBox(height: LinguaTokens.space16),
                        const Text('Your caseload is empty', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: LinguaTokens.ink900)),
                        const SizedBox(height: LinguaTokens.space8),
                        const Text(
                          'Connect with authorized learners to review baseline snapshots, support goals, and practice history.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: LinguaTokens.inkMuted, height: 1.4),
                        ),
                        const SizedBox(height: LinguaTokens.space20),
                        LinguaButton(
                          label: '+ Add Learner',
                          onPressed: () => Navigator.pushNamed(context, AppRoutes.inviteCollaborator),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(LinguaTokens.space16),
                itemCount: caseload.length,
                itemBuilder: (ctx, i) {
                  final c = caseload[i];
                  return LinguaAnimatedCard(
                    animationDelayMs: i * 50,
                    margin: const EdgeInsets.only(bottom: LinguaTokens.space12),
                    child: LearnerCardTile(
                      displayName: c.displayName,
                      ageBand: c.ageBand,
                      supportFocus: c.supportFocus,
                      status: c.status,
                      subtitle: 'Baseline: ${c.baselineStatus.toUpperCase()} • Pending AI Reviews: ${c.pendingAiRecommendations}',
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.specialistLearnerDetail,
                          arguments: c.learnerId,
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),

          // 2. AI Oversight
          ListView(
            padding: const EdgeInsets.all(LinguaTokens.space16),
            children: [
              LinguaAnimatedCard(
                backgroundColor: LinguaTokens.paper100,
                borderColor: LinguaTokens.borderSubtle,
                padding: const EdgeInsets.all(LinguaTokens.space16),
                margin: const EdgeInsets.only(bottom: LinguaTokens.space16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.verified_user_outlined, color: LinguaTokens.primary600, size: 22),
                    const SizedBox(width: LinguaTokens.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Specialist Human Oversight',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: LinguaTokens.ink900),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'AI recommendations are assistive suggestions only. You can approve, modify, or reject them. Actions do not alter underlying progress metrics.',
                            style: TextStyle(fontSize: 12, color: LinguaTokens.inkMuted, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              AiReviewCard(
                recommendationId: 'rec-1',
                lessonTitle: 'Active Listening & Conversational Turns',
                explanation: 'Suggested based on 4 recent spoken language exercises.',
                humanStatus: 'none',
                onAction: (status) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Recommendation marked as $status.')),
                  );
                },
              ),
              AiReviewCard(
                recommendationId: 'rec-2',
                lessonTitle: 'Phonological Rhyme & Syllable Segmentation',
                explanation: 'Suggested for literacy practice consistency.',
                humanStatus: 'approved',
                onAction: (status) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Recommendation marked as $status.')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

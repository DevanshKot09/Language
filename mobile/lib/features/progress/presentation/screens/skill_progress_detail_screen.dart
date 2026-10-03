import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_tokens/tokens.dart';
import '../../../../core/widgets/non_diagnostic_banner.dart';
import '../../application/progress_providers.dart';
import '../widgets/skill_progress_card.dart';

class SkillProgressDetailScreen extends ConsumerStatefulWidget {
  const SkillProgressDetailScreen({super.key});

  @override
  ConsumerState<SkillProgressDetailScreen> createState() => _SkillProgressDetailScreenState();
}

class _SkillProgressDetailScreenState extends ConsumerState<SkillProgressDetailScreen> with SingleTickerProviderStateMixin {
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
    final progressAsync = ref.watch(progressDashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Skill Growth & Readiness'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: LinguaTokens.primary600,
          unselectedLabelColor: LinguaTokens.inkMuted,
          indicatorColor: LinguaTokens.primary600,
          tabs: const [
            Tab(text: 'All Skills'),
            Tab(text: 'Spoken Language'),
            Tab(text: 'Literacy & Reading'),
          ],
        ),
      ),
      body: SafeArea(
        child: progressAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Text('Failed to load skills: $err'),
          ),
          data: (data) {
            return TabBarView(
              controller: _tabController,
              children: [
                _buildSkillList(data.skills),
                _buildSkillList(data.dldSkills),
                _buildSkillList(data.dyslexiaSkills),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSkillList(List<dynamic> skills) {
    if (skills.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(LinguaTokens.space24),
          child: Text(
            'No skills recorded in this category yet.',
            style: TextStyle(fontSize: 14, color: LinguaTokens.inkMuted),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(LinguaTokens.space16),
      children: [
        const NonDiagnosticBanner(compact: true),
        const SizedBox(height: LinguaTokens.space16),
        const Text(
          'Descriptive Readiness Bands',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: LinguaTokens.ink900),
        ),
        const SizedBox(height: 4),
        const Text(
          'Starting (introductory) • Developing (guided practice) • Practicing (building fluency) • Consistent (independent application). Non-diagnostic.',
          style: TextStyle(fontSize: 12, color: LinguaTokens.ink700),
        ),
        const SizedBox(height: LinguaTokens.space16),
        ...skills.map((s) => SkillProgressCard(skill: s)),
      ],
    );
  }
}

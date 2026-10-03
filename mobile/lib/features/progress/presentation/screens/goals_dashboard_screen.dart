import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_tokens/tokens.dart';
import '../../../../core/widgets/lingua_button.dart';
import '../../../../app/router/app_router.dart';
import '../../application/progress_providers.dart';
import '../widgets/goal_card.dart';

class GoalsDashboardScreen extends ConsumerStatefulWidget {
  const GoalsDashboardScreen({super.key});

  @override
  ConsumerState<GoalsDashboardScreen> createState() => _GoalsDashboardScreenState();
}

class _GoalsDashboardScreenState extends ConsumerState<GoalsDashboardScreen> with SingleTickerProviderStateMixin {
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
    final goalsAsync = ref.watch(goalsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning Goals'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: LinguaTokens.primary600,
          unselectedLabelColor: LinguaTokens.inkMuted,
          indicatorColor: LinguaTokens.primary600,
          tabs: const [
            Tab(text: 'Active Goals'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: SafeArea(
        child: goalsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Text('Failed to load goals: $err'),
          ),
          data: (goals) {
            final activeGoals = goals.where((g) => !g.isCompleted).toList();
            final completedGoals = goals.where((g) => g.isCompleted).toList();

            return TabBarView(
              controller: _tabController,
              children: [
                _buildGoalsList(activeGoals, isActiveList: true),
                _buildGoalsList(completedGoals, isActiveList: false),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(LinguaTokens.space16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: LinguaTokens.borderSubtle)),
        ),
        child: LinguaButton(
          label: '+ Set a New Goal',
          onPressed: () => Navigator.pushNamed(context, AppRoutes.createGoal),
        ),
      ),
    );
  }

  Widget _buildGoalsList(List<dynamic> list, {required bool isActiveList}) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(LinguaTokens.space24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isActiveList ? Icons.flag_outlined : Icons.emoji_events_outlined,
                size: 48,
                color: LinguaTokens.inkMuted,
              ),
              const SizedBox(height: 12),
              Text(
                isActiveList ? 'No active goals' : 'No completed goals yet',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                isActiveList
                    ? 'Create a small goal to guide your learning practice.'
                    : 'Completed goals will appear here to celebrate your achievements.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: LinguaTokens.ink700),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(LinguaTokens.space16),
      itemCount: list.length,
      itemBuilder: (context, i) {
        final goal = list[i];
        return GoalCard(
          goal: goal,
          onDelete: () => _confirmDelete(goal.id),
        );
      },
    );
  }

  void _confirmDelete(String goalId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Goal?'),
        content: const Text('Are you sure you want to remove this learning goal? Your existing practice history is safe.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(goalsNotifierProvider.notifier).deleteGoal(goalId);
            },
            child: const Text('Remove', style: TextStyle(color: LinguaTokens.danger600)),
          ),
        ],
      ),
    );
  }
}

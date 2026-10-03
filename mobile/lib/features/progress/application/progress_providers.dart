import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/network_provider.dart';
import '../data/progress_repository.dart';
import '../data/goal_repository.dart';
import '../data/achievement_repository.dart';
import '../domain/models/progress_models.dart';
import '../domain/models/goal_models.dart';
import '../domain/models/achievement_models.dart';

final progressRepositoryProvider = Provider<IProgressRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return ProgressRepository(client);
});

final goalRepositoryProvider = Provider<IGoalRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return GoalRepository(client);
});

final achievementRepositoryProvider = Provider<IAchievementRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return AchievementRepository(client);
});

/// Authoritative progress dashboard provider
final progressDashboardProvider = FutureProvider.autoDispose<ProgressDashboardData>((ref) async {
  final repo = ref.watch(progressRepositoryProvider);
  return repo.getProgressDashboard(includeAiInsight: true);
});

/// Skill progress list provider (filtered optionally by track: 'dld_track', 'dyslexia_track', or null for all)
final skillProgressProvider = FutureProvider.family.autoDispose<List<SkillProgressItem>, String?>((ref, track) async {
  final repo = ref.watch(progressRepositoryProvider);
  return repo.getSkillProgress(track: track);
});

/// Chronological activity timeline provider
final activityTimelineProvider = FutureProvider.autoDispose<List<ActivityTimelineItem>>((ref) async {
  final repo = ref.watch(progressRepositoryProvider);
  return repo.getActivityTimeline(limit: 25);
});

/// System achievements enriched with learner progress
final achievementsProvider = FutureProvider.autoDispose<List<AchievementItem>>((ref) async {
  final repo = ref.watch(achievementRepositoryProvider);
  return repo.getAchievements();
});

/// Interactive goals notifier for creating, updating, and removing learner goals
class GoalsNotifier extends AsyncNotifier<List<LearnerGoal>> {
  @override
  FutureOr<List<LearnerGoal>> build() async {
    final repo = ref.watch(goalRepositoryProvider);
    return repo.getGoals();
  }

  Future<LearnerGoal?> createGoal(GoalCreateDto dto) async {
    final repo = ref.read(goalRepositoryProvider);
    try {
      final created = await repo.createGoal(dto);
      // Refresh current goals list and invalidate progress dashboard
      final current = state.value ?? [];
      state = AsyncData([created, ...current]);
      ref.invalidate(progressDashboardProvider);
      return created;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  Future<bool> updateGoal(String goalId, GoalUpdateDto dto) async {
    final repo = ref.read(goalRepositoryProvider);
    try {
      final updated = await repo.updateGoal(goalId, dto);
      final current = state.value ?? [];
      state = AsyncData(current.map((g) => g.id == goalId ? updated : g).toList());
      ref.invalidate(progressDashboardProvider);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> deleteGoal(String goalId) async {
    final repo = ref.read(goalRepositoryProvider);
    try {
      await repo.deleteGoal(goalId);
      final current = state.value ?? [];
      state = AsyncData(current.filter((g) => g.id != goalId).toList());
      ref.invalidate(progressDashboardProvider);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(goalRepositoryProvider);
      return repo.getGoals();
    });
  }
}

final goalsNotifierProvider = AsyncNotifierProvider<GoalsNotifier, List<LearnerGoal>>(() {
  return GoalsNotifier();
});

extension _IterableExt<T> on Iterable<T> {
  Iterable<T> filter(bool Function(T) test) => where(test);
}

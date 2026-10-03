import 'package:lingua_ai/features/baseline/data/models/baseline_activity_model.dart';
import 'package:lingua_ai/features/baseline/data/models/baseline_session_model.dart';
import 'package:lingua_ai/features/baseline/data/models/skill_snapshot_model.dart';
import 'package:lingua_ai/features/baseline/data/models/learner_goal_model.dart';
import 'package:lingua_ai/features/baseline/data/repositories/baseline_repository.dart';

class MockBaselineRepository implements IBaselineRepository {
  final List<BaselineActivityModel> activities;
  final SkillSnapshotModel snapshot;
  final List<LearnerGoalModel> goals;

  MockBaselineRepository({
    List<BaselineActivityModel>? activities,
    SkillSnapshotModel? snapshot,
    List<LearnerGoalModel>? goals,
  })  : activities = activities ??
            [
              const BaselineActivityModel(
                id: 'act-1',
                skillId: 's1',
                track: 'dld_track',
                domain: 'vocabulary',
                ageBand: 'teen',
                activityType: 'multiple_choice',
                instruction: 'Select the best meaning for the highlighted word.',
                prompt: 'What is the closest meaning of "candid"?',
                options: ['Frank and outspoken', 'Shy and quiet', 'Rough and loud'],
                hint: 'Think about honesty.',
                difficulty: 'medium',
              ),
              const BaselineActivityModel(
                id: 'act-2',
                skillId: 's2',
                track: 'dyslexia_track',
                domain: 'phonology',
                ageBand: 'teen',
                activityType: 'sound_identification',
                instruction: 'Identify the common sound pattern.',
                prompt: 'Which word contains the same sound as the "ph" in "photo"?',
                options: ['Laugh', 'Ghost', 'Thought'],
                hint: 'Focus on the /f/ sound.',
                difficulty: 'medium',
              ),
            ],
        snapshot = snapshot ??
            SkillSnapshotModel(
              userId: 'test-user',
              baselineStatus: 'completed',
              completedAt: DateTime.now(),
              skills: const [
                SkillSnapshotItemModel(
                  skillId: 's1',
                  skillCode: 'dld_vocab',
                  skillName: 'Vocabulary Breadth',
                  track: 'dld_track',
                  domain: 'vocabulary',
                  band: 'Consistent',
                  score: 0.9,
                  accuracy: 0.9,
                  description: 'Strong independent skill; ready for diverse applied contexts.',
                ),
                SkillSnapshotItemModel(
                  skillId: 's2',
                  skillCode: 'dys_phon',
                  skillName: 'Phonological Awareness',
                  track: 'dyslexia_track',
                  domain: 'phonology',
                  band: 'Developing',
                  score: 0.5,
                  accuracy: 0.5,
                  description: 'Emerging ability; benefits from structured visual support.',
                ),
              ],
              strengthAreas: const ['Vocabulary Breadth'],
              priorityPracticeAreas: const ['Phonological Awareness'],
            ),
        goals = goals ?? [];

  @override
  Future<BaselineSessionModel> createOrGetSession() async {
    return BaselineSessionModel(
      id: 'mock-session-1',
      userId: 'test-user',
      track: 'dld_track',
      status: 'in_progress',
      totalActivities: activities.length,
      completedActivities: 0,
      activities: activities,
    );
  }

  @override
  Future<BaselineSessionModel> getSession(String sessionId) async {
    return BaselineSessionModel(
      id: sessionId,
      userId: 'test-user',
      track: 'dld_track',
      status: 'in_progress',
      totalActivities: activities.length,
      completedActivities: 0,
      activities: activities,
    );
  }

  @override
  Future<BaselineResponseResultModel> submitResponse({
    required String sessionId,
    required String activityId,
    required String selectedOption,
    required int timeTakenMs,
  }) async {
    return BaselineResponseResultModel(
      activityId: activityId,
      isCorrect: true,
      correctAnswer: activities.first.options.first,
      completedActivities: 1,
      totalActivities: activities.length,
      isSessionComplete: activities.length == 1,
    );
  }

  @override
  Future<SkillSnapshotModel> completeSession(String sessionId) async {
    return snapshot;
  }

  @override
  Future<SkillSnapshotModel> getSkillSnapshot() async {
    return snapshot;
  }

  @override
  Future<List<LearnerGoalModel>> getGoals() async {
    return goals;
  }

  @override
  Future<LearnerGoalModel> createGoal({
    required String title,
    String? skillId,
    String targetFrequency = 'weekly',
    String? targetBehavior,
  }) async {
    final g = LearnerGoalModel(
      id: 'g-new',
      userId: 'test-user',
      skillId: skillId,
      title: title,
      targetFrequency: targetFrequency,
      targetBehavior: targetBehavior,
    );
    goals.add(g);
    return g;
  }
}

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/baseline_session_model.dart';
import '../models/skill_snapshot_model.dart';
import '../models/learner_goal_model.dart';

abstract class IBaselineRepository {
  Future<BaselineSessionModel> createOrGetSession();
  Future<BaselineSessionModel> getSession(String sessionId);
  Future<BaselineResponseResultModel> submitResponse({
    required String sessionId,
    required String activityId,
    required String selectedOption,
    required int timeTakenMs,
  });
  Future<SkillSnapshotModel> completeSession(String sessionId);
  Future<SkillSnapshotModel> getSkillSnapshot();
  Future<List<LearnerGoalModel>> getGoals();
  Future<LearnerGoalModel> createGoal({
    required String title,
    String? skillId,
    String targetFrequency = 'weekly',
    String? targetBehavior,
  });
}

class BaselineRepository implements IBaselineRepository {
  final IApiClient _client;

  BaselineRepository(this._client);

  @override
  Future<BaselineSessionModel> createOrGetSession() async {
    final response = await _client.post(ApiEndpoints.baselineSessions);
    return BaselineSessionModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<BaselineSessionModel> getSession(String sessionId) async {
    final response = await _client.get('${ApiEndpoints.baselineSessions}/$sessionId');
    return BaselineSessionModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<BaselineResponseResultModel> submitResponse({
    required String sessionId,
    required String activityId,
    required String selectedOption,
    required int timeTakenMs,
  }) async {
    final response = await _client.post(
      '${ApiEndpoints.baselineSessions}/$sessionId/responses',
      body: {
        'activity_id': activityId,
        'selected_option': selectedOption,
        'time_taken_ms': timeTakenMs,
      },
    );
    return BaselineResponseResultModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<SkillSnapshotModel> completeSession(String sessionId) async {
    final response = await _client.post(
      '${ApiEndpoints.baselineSessions}/$sessionId/complete',
    );
    return SkillSnapshotModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<SkillSnapshotModel> getSkillSnapshot() async {
    final response = await _client.get(ApiEndpoints.learnerSnapshot);
    return SkillSnapshotModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<List<LearnerGoalModel>> getGoals() async {
    final response = await _client.get(ApiEndpoints.learnerGoals);
    if (response is List) {
      return response
          .map((e) => LearnerGoalModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<LearnerGoalModel> createGoal({
    required String title,
    String? skillId,
    String targetFrequency = 'weekly',
    String? targetBehavior,
  }) async {
    final response = await _client.post(
      ApiEndpoints.learnerGoals,
      body: {
        'title': title,
        'skill_id': skillId,
        'target_frequency': targetFrequency,
        'target_behavior': targetBehavior,
      },
    );
    return LearnerGoalModel.fromJson(response as Map<String, dynamic>);
  }
}

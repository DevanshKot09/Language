import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../domain/models/goal_models.dart';

abstract class IGoalRepository {
  Future<List<LearnerGoal>> getGoals({String? status});
  Future<LearnerGoal> getGoal(String goalId);
  Future<LearnerGoal> createGoal(GoalCreateDto dto);
  Future<LearnerGoal> updateGoal(String goalId, GoalUpdateDto dto);
  Future<void> deleteGoal(String goalId);
}

class GoalRepository implements IGoalRepository {
  final IApiClient _client;

  GoalRepository(this._client);

  @override
  Future<List<LearnerGoal>> getGoals({String? status}) async {
    final queryParams = <String, String>{};
    if (status != null) queryParams['status'] = status;
    final response = await _client.get(
      ApiEndpoints.goals,
      queryParameters: queryParams,
    );
    final list = response as List<dynamic>? ?? [];
    return list.map((e) => LearnerGoal.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<LearnerGoal> getGoal(String goalId) async {
    final response = await _client.get(ApiEndpoints.goalDetail(goalId));
    return LearnerGoal.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<LearnerGoal> createGoal(GoalCreateDto dto) async {
    final response = await _client.post(
      ApiEndpoints.goals,
      body: dto.toJson(),
    );
    return LearnerGoal.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<LearnerGoal> updateGoal(String goalId, GoalUpdateDto dto) async {
    final response = await _client.put(
      ApiEndpoints.goalDetail(goalId),
      body: dto.toJson(),
    );
    return LearnerGoal.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<void> deleteGoal(String goalId) async {
    await _client.delete(ApiEndpoints.goalDetail(goalId));
  }
}

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../domain/models/progress_models.dart';

abstract class IProgressRepository {
  Future<ProgressDashboardData> getProgressDashboard({bool includeAiInsight = true});
  Future<List<SkillProgressItem>> getSkillProgress({String? track});
  Future<List<ActivityTimelineItem>> getActivityTimeline({int limit = 20});
}

class ProgressRepository implements IProgressRepository {
  final IApiClient _client;

  ProgressRepository(this._client);

  @override
  Future<ProgressDashboardData> getProgressDashboard({bool includeAiInsight = true}) async {
    final response = await _client.get(
      ApiEndpoints.progress,
      queryParameters: {'include_ai_insight': includeAiInsight.toString()},
    );
    return ProgressDashboardData.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<List<SkillProgressItem>> getSkillProgress({String? track}) async {
    final queryParams = <String, String>{};
    if (track != null) queryParams['track'] = track;
    final response = await _client.get(
      ApiEndpoints.progressSkills,
      queryParameters: queryParams,
    );
    final list = response as List<dynamic>? ?? [];
    return list.map((e) => SkillProgressItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<ActivityTimelineItem>> getActivityTimeline({int limit = 20}) async {
    final response = await _client.get(
      ApiEndpoints.progressTimeline,
      queryParameters: {'limit': limit.toString()},
    );
    final list = response as List<dynamic>? ?? [];
    return list.map((e) => ActivityTimelineItem.fromJson(e as Map<String, dynamic>)).toList();
  }
}

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../domain/models/achievement_models.dart';

abstract class IAchievementRepository {
  Future<List<AchievementItem>> getAchievements();
}

class AchievementRepository implements IAchievementRepository {
  final IApiClient _client;

  AchievementRepository(this._client);

  @override
  Future<List<AchievementItem>> getAchievements() async {
    final response = await _client.get(ApiEndpoints.achievements);
    final list = response as List<dynamic>? ?? [];
    return list.map((e) => AchievementItem.fromJson(e as Map<String, dynamic>)).toList();
  }
}

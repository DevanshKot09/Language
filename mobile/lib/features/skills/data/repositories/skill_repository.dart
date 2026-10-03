import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/skill_model.dart';

abstract class ISkillRepository {
  Future<List<SkillModel>> getSkills({String? track, String? ageBand});
  Future<SkillModel> getSkillById(String id);
}

class SkillRepository implements ISkillRepository {
  final IApiClient _client;

  SkillRepository(this._client);

  @override
  Future<List<SkillModel>> getSkills({String? track, String? ageBand}) async {
    final params = <String, dynamic>{};
    if (track != null) params['track'] = track;
    if (ageBand != null) params['age_band'] = ageBand;

    final response = await _client.get(
      ApiEndpoints.skills,
      queryParameters: params.isNotEmpty ? params : null,
    );

    if (response is List) {
      return response
          .map((e) => SkillModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<SkillModel> getSkillById(String id) async {
    final response = await _client.get('${ApiEndpoints.skills}/$id');
    return SkillModel.fromJson(response as Map<String, dynamic>);
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers/network_provider.dart';
import '../data/models/skill_model.dart';
import '../data/repositories/skill_repository.dart';

final skillRepositoryProvider = Provider<ISkillRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return SkillRepository(client);
});

final skillsListProvider = FutureProvider.family<List<SkillModel>, String?>((ref, track) async {
  final repo = ref.watch(skillRepositoryProvider);
  return await repo.getSkills(track: track);
});

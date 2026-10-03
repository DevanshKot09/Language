import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../domain/models/lesson_model.dart';
import '../domain/models/exercise_attempt_model.dart';
import '../domain/models/practice_hub_model.dart';
import '../domain/models/learning_path_model.dart';

abstract class ILearningRepository {
  Future<List<LessonSummaryModel>> getLessons({
    String? track,
    String? skillId,
    String? ageBand,
    int? difficulty,
  });
  Future<LessonDetailModel> getLessonDetail(String lessonId);
  Future<Map<String, dynamic>> startOrResumeLesson(String lessonId);
  Future<Map<String, dynamic>> getLessonState(String lessonId);
  Future<ExerciseAttemptResponseModel> submitExerciseAttempt({
    required String exerciseId,
    required ExerciseAttemptRequestModel request,
  });
  Future<Map<String, dynamic>> completeLesson(String lessonId);
  Future<PracticeHubModel> getPracticeHub();
  Future<LearningPathModel> getLearningPath();
}

class LearningRepository implements ILearningRepository {
  final IApiClient _client;

  LearningRepository(this._client);

  @override
  Future<List<LessonSummaryModel>> getLessons({
    String? track,
    String? skillId,
    String? ageBand,
    int? difficulty,
  }) async {
    final queryParams = <String, String>{};
    if (track != null) queryParams['track'] = track;
    if (skillId != null) queryParams['skill_id'] = skillId;
    if (ageBand != null) queryParams['age_band'] = ageBand;
    if (difficulty != null) queryParams['difficulty'] = difficulty.toString();

    final response = await _client.get(ApiEndpoints.lessons, queryParameters: queryParams);
    final list = response as List<dynamic>? ?? [];
    return list.map((e) => LessonSummaryModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<LessonDetailModel> getLessonDetail(String lessonId) async {
    final response = await _client.get(ApiEndpoints.lessonDetail(lessonId));
    return LessonDetailModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<Map<String, dynamic>> startOrResumeLesson(String lessonId) async {
    final response = await _client.post(ApiEndpoints.lessonStart(lessonId));
    return response as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> getLessonState(String lessonId) async {
    final response = await _client.get(ApiEndpoints.lessonState(lessonId));
    return response as Map<String, dynamic>;
  }

  @override
  Future<ExerciseAttemptResponseModel> submitExerciseAttempt({
    required String exerciseId,
    required ExerciseAttemptRequestModel request,
  }) async {
    final response = await _client.post(
      ApiEndpoints.exerciseAttempt(exerciseId),
      body: request.toJson(),
    );
    return ExerciseAttemptResponseModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<Map<String, dynamic>> completeLesson(String lessonId) async {
    final response = await _client.post(ApiEndpoints.lessonComplete(lessonId));
    return response as Map<String, dynamic>;
  }

  @override
  Future<PracticeHubModel> getPracticeHub() async {
    final response = await _client.get(ApiEndpoints.practice);
    return PracticeHubModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<LearningPathModel> getLearningPath() async {
    final response = await _client.get(ApiEndpoints.learningPath);
    return LearningPathModel.fromJson(response as Map<String, dynamic>);
  }
}

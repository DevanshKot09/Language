import 'package:lingua_ai/features/learning/data/learning_repository.dart';
import 'package:lingua_ai/features/learning/domain/models/lesson_model.dart';
import 'package:lingua_ai/features/learning/domain/models/exercise_model.dart';
import 'package:lingua_ai/features/learning/domain/models/exercise_attempt_model.dart';
import 'package:lingua_ai/features/learning/domain/models/practice_hub_model.dart';
import 'package:lingua_ai/features/learning/domain/models/learning_path_model.dart';

class MockLearningRepository implements ILearningRepository {
  final List<LessonSummaryModel> mockLessons;
  final LessonDetailModel mockLessonDetail;
  final PracticeHubModel mockPracticeHub;
  final LearningPathModel mockLearningPath;

  MockLearningRepository({
    List<LessonSummaryModel>? lessons,
    LessonDetailModel? lessonDetail,
    PracticeHubModel? practiceHub,
    LearningPathModel? learningPath,
  })  : mockLessons = lessons ?? _defaultLessons,
        mockLessonDetail = lessonDetail ?? _defaultLessonDetail,
        mockPracticeHub = practiceHub ?? _defaultPracticeHub,
        mockLearningPath = learningPath ?? _defaultLearningPath;

  @override
  Future<List<LessonSummaryModel>> getLessons({
    String? track,
    String? skillId,
    String? ageBand,
    int? difficulty,
  }) async {
    return mockLessons;
  }

  @override
  Future<LessonDetailModel> getLessonDetail(String lessonId) async {
    return mockLessonDetail;
  }

  @override
  Future<Map<String, dynamic>> startOrResumeLesson(String lessonId) async {
    return {
      'lesson_id': lessonId,
      'current_exercise_index': 0,
      'status': 'in_progress',
      'completed_at': null,
      'total_exercises': mockLessonDetail.exercises.length,
      'completed_exercises': 0,
    };
  }

  @override
  Future<Map<String, dynamic>> getLessonState(String lessonId) async {
    return {
      'lesson_id': lessonId,
      'current_exercise_index': 0,
      'status': 'in_progress',
      'completed_at': null,
      'total_exercises': mockLessonDetail.exercises.length,
      'completed_exercises': 0,
    };
  }

  @override
  Future<ExerciseAttemptResponseModel> submitExerciseAttempt({
    required String exerciseId,
    required ExerciseAttemptRequestModel request,
  }) async {
    final isCorrect = request.response == 'To look around and discover new things' ||
        request.response == 'sun' ||
        (request.response is List && (request.response as List).length == 3);

    return ExerciseAttemptResponseModel(
      attemptId: 'att-mock-1',
      status: isCorrect ? 'correct' : 'incorrect',
      isCorrect: isCorrect,
      partialScore: isCorrect ? 1.0 : 0.0,
      feedbackMessage: isCorrect
          ? 'Wonderful job! You found the right answer.'
          : 'Good try! Look closely at the clue and give it another try.',
      explanation: 'Educational practice explanation.',
      currentExerciseIndex: 0,
      nextExerciseIndex: 1,
      lessonCompleted: false,
    );
  }

  @override
  Future<Map<String, dynamic>> completeLesson(String lessonId) async {
    return {
      'lesson_id': lessonId,
      'status': 'completed',
      'completed_at': '2026-10-01T10:00:00Z',
    };
  }

  @override
  Future<PracticeHubModel> getPracticeHub() async {
    return mockPracticeHub;
  }

  @override
  Future<LearningPathModel> getLearningPath() async {
    return mockLearningPath;
  }

  static final _defaultLessons = [
    const LessonSummaryModel(
      id: 'lesson-dld-001',
      skillId: 'skill-vocab',
      skillName: 'Vocabulary Breadth',
      title: 'Everyday Action Words',
      description: 'Practice core action verbs with meaningful context.',
      track: 'dld_track',
      ageBand: 'child',
      difficulty: 1,
      sequenceOrder: 1,
      estimatedEffortMinutes: 5,
      totalExercises: 3,
      userStatus: 'in_progress',
      currentExerciseIndex: 1,
      completedExercises: 1,
    ),
    const LessonSummaryModel(
      id: 'lesson-dys-001',
      skillId: 'skill-phonology',
      skillName: 'Phonological Awareness',
      title: 'Sound Blending & Phonemes',
      description: 'Isolate and blend spoken sounds into words.',
      track: 'dyslexia_track',
      ageBand: 'child',
      difficulty: 1,
      sequenceOrder: 2,
      estimatedEffortMinutes: 5,
      totalExercises: 3,
      userStatus: 'not_started',
      currentExerciseIndex: 0,
      completedExercises: 0,
    ),
  ];

  static const _defaultLessonDetail = LessonDetailModel(
    id: 'lesson-dld-001',
    skillId: 'skill-vocab',
    skillName: 'Vocabulary Breadth',
    title: 'Everyday Action Words',
    description: 'Practice core action verbs with meaningful context.',
    track: 'dld_track',
    ageBand: 'child',
    difficulty: 1,
    sequenceOrder: 1,
    estimatedEffortMinutes: 5,
    totalExercises: 3,
    userStatus: 'in_progress',
    currentExerciseIndex: 0,
    completedExercises: 0,
    exercises: [
      ExerciseModel(
        id: 'ex-1',
        lessonId: 'lesson-dld-001',
        skillId: 'skill-vocab',
        exerciseType: 'multiple_choice',
        prompt: 'What does the action word "explore" mean?',
        instruction: 'Read the question and select the best meaning.',
        content: {
          'options': [
            'To look around and discover new things',
            'To sleep quietly in bed',
            'To hide away in a dark room',
          ]
        },
        difficulty: 1,
        ageBand: 'child',
        track: 'dld_track',
        sequenceOrder: 1,
        hints: ['Think about traveling to new places.'],
        explanation: 'Explore means traveling around a place to learn about it.',
      ),
      ExerciseModel(
        id: 'ex-2',
        lessonId: 'lesson-dld-001',
        skillId: 'skill-vocab',
        exerciseType: 'word_order',
        prompt: 'Build a sentence about playing outside.',
        instruction: 'Arrange the words in order.',
        content: {
          'tokens': ['The', 'children', 'played.']
        },
        difficulty: 1,
        ageBand: 'child',
        track: 'dld_track',
        sequenceOrder: 2,
        hints: ['Start with The children.'],
      ),
      ExerciseModel(
        id: 'ex-3',
        lessonId: 'lesson-dld-001',
        skillId: 'skill-vocab',
        exerciseType: 'matching',
        prompt: 'Connect action words to meanings.',
        instruction: 'Pair items together.',
        content: {
          'pairs': [
            {'key': 'soar', 'value': 'fly high'},
            {'key': 'sprint', 'value': 'run fast'},
          ]
        },
        difficulty: 1,
        ageBand: 'child',
        track: 'dld_track',
        sequenceOrder: 3,
      ),
    ],
  );

  static final _defaultPracticeHub = PracticeHubModel(
    recommendedLessons: _defaultLessons,
    inProgressLessons: [_defaultLessons[0]],
    completedLessons: [],
    skillsSummary: [
      const SkillProgressItemModel(
        skillId: 'skill-vocab',
        skillCode: 'dld_vocabulary',
        skillName: 'Vocabulary Breadth',
        track: 'dld_track',
        completedLessons: 1,
        totalLessons: 2,
        masteryStatus: 'Practicing',
      ),
    ],
  );

  static const _defaultLearningPath = LearningPathModel(
    track: 'dld_track',
    nodes: [
      LearningPathNodeModel(
        stepNumber: 1,
        lessonId: 'lesson-dld-001',
        title: 'Everyday Action Words',
        track: 'dld_track',
        skillName: 'Vocabulary',
        status: 'active',
        isCompleted: false,
        isActive: true,
        difficulty: 1,
      ),
      LearningPathNodeModel(
        stepNumber: 2,
        lessonId: 'lesson-dld-003',
        title: 'Building Connected Sentences',
        track: 'dld_track',
        skillName: 'Syntax',
        status: 'upcoming',
        isCompleted: false,
        isActive: false,
        difficulty: 1,
      ),
    ],
  );
}

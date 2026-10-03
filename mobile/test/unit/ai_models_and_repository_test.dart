import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_ai/core/network/api_client.dart';
import 'package:lingua_ai/features/ai/domain/models/ai_models.dart';
import 'package:lingua_ai/features/ai/data/ai_repository.dart';

class FakeApiClient implements IApiClient {
  final Map<String, dynamic> Function(String path, {dynamic body})? onPost;
  final dynamic Function(String path)? onGet;

  FakeApiClient({this.onPost, this.onGet});

  @override
  String? get authToken => 'fake-token';

  @override
  void setAuthToken(String? token) {}

  @override
  Future<dynamic> get(String path, {Map<String, String>? headers, Map<String, dynamic>? queryParameters}) async {
    if (onGet != null) return onGet!(path);
    return {};
  }

  @override
  Future<dynamic> post(String path, {Map<String, String>? headers, dynamic body}) async {
    if (onPost != null) return onPost!(path, body: body);
    return {};
  }

  @override
  Future<dynamic> put(String path, {Map<String, String>? headers, dynamic body}) async => {};

  @override
  Future<dynamic> patch(String path, {Map<String, String>? headers, dynamic body}) async => {};

  @override
  Future<dynamic> delete(String path, {Map<String, String>? headers, dynamic body}) async => {};
}

void main() {
  group('AI Models Serialization', () {
    test('AiRecommendationItemModel deserializes correctly', () {
      final json = {
        'lesson_id': 'lesson-dld-002',
        'reason_code': 'skill_continuity',
        'short_explanation': 'Builds on complex sentences.',
        'confidence_level': 'high',
      };
      final item = AiRecommendationItemModel.fromJson(json);
      expect(item.lessonId, 'lesson-dld-002');
      expect(item.reasonCode, 'skill_continuity');
      expect(item.shortExplanation, 'Builds on complex sentences.');
      expect(item.confidenceLevel, 'high');
    });

    test('AiExplanationModel deserializes correctly', () {
      final json = {
        'explanation': 'Because introduces a reason clause.',
        'clarity_tip': 'Look for cause and effect.',
        'fallback_used': false,
      };
      final model = AiExplanationModel.fromJson(json);
      expect(model.explanation, 'Because introduces a reason clause.');
      expect(model.clarityTip, 'Look for cause and effect.');
      expect(model.fallbackUsed, isFalse);
    });

    test('AiFeedbackModel deserializes correctly', () {
      final json = {
        'clarity_note': 'Idea is well structured.',
        'learning_tip': 'Add transition words.',
        'encouragement': 'Great job!',
        'revision_suggestion': 'Try adding "However" at the start.',
        'fallback_used': false,
      };
      final model = AiFeedbackModel.fromJson(json);
      expect(model.clarityNote, 'Idea is well structured.');
      expect(model.learningTip, 'Add transition words.');
      expect(model.encouragement, 'Great job!');
      expect(model.revisionSuggestion, 'Try adding "However" at the start.');
      expect(model.fallbackUsed, isFalse);
    });

    test('AiConversationReplyModel deserializes correctly', () {
      final json = {
        'reply': 'Can you tell me which character went first?',
        'followup_prompt': 'Think about the beginning of the story.',
        'is_scenario_complete': false,
        'fallback_used': false,
      };
      final model = AiConversationReplyModel.fromJson(json);
      expect(model.reply, 'Can you tell me which character went first?');
      expect(model.followupPrompt, 'Think about the beginning of the story.');
      expect(model.isScenarioComplete, isFalse);
      expect(model.fallbackUsed, isFalse);
    });

    test('AiProgressInsightModel deserializes correctly', () {
      final json = {
        'practice_summary': 'You practiced 5 lessons.',
        'what_went_well': 'Great vocabulary retention.',
        'next_practice_area': 'Explore compound sentences.',
        'encouraging_note': 'Keep up the steady practice!',
        'fallback_used': false,
      };
      final model = AiProgressInsightModel.fromJson(json);
      expect(model.practiceSummary, 'You practiced 5 lessons.');
      expect(model.whatWentWell, 'Great vocabulary retention.');
      expect(model.nextPracticeArea, 'Explore compound sentences.');
      expect(model.encouragingNote, 'Keep up the steady practice!');
      expect(model.fallbackUsed, isFalse);
    });
  });

  group('AiRepository Deterministic Fallbacks', () {
    test('Recommendation falls back to first candidate on network failure', () async {
      final repo = AiRepository(
        apiClient: FakeApiClient(
          onPost: (_, {body}) => throw Exception('Network timeout'),
        ),
      );

      final recs = await repo.getRecommendations(
        track: 'dld',
        ageBand: 'child',
        candidateLessonIds: ['lesson-dld-001', 'lesson-dld-002'],
      );

      expect(recs, isNotEmpty);
      expect(recs.first.lessonId, 'lesson-dld-001');
      expect(recs.first.reasonCode, 'curriculum_sequence');
    });

    test('Explanation provides safe fallback on error', () async {
      final repo = AiRepository(
        apiClient: FakeApiClient(
          onPost: (_, {body}) => throw Exception('Service unavailable'),
        ),
      );

      final expl = await repo.getExplanation(
        lessonTitle: 'Complex Sentences',
        exercisePrompt: 'Combine using because',
        targetConcept: 'Causal Conjunctions',
        learnerQuestion: 'Why is this correct?',
        ageBand: 'child',
      );

      expect(expl.fallbackUsed, isTrue);
      expect(expl.explanation, isNotEmpty);
    });

    test('Feedback provides safe fallback on error', () async {
      final repo = AiRepository(
        apiClient: FakeApiClient(
          onPost: (_, {body}) => throw Exception('Quota exceeded'),
        ),
      );

      final fb = await repo.getFeedback(
        activityType: 'speaking_practice',
        prompt: 'Describe your day',
        learnerSubmission: 'I went to school and played.',
        ageBand: 'child',
        track: 'dld',
      );

      expect(fb.fallbackUsed, isTrue);
      expect(fb.encouragement, isNotEmpty);
    });
  });
}

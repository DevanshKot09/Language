import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_ai/features/ai/domain/models/ai_models.dart';
import 'package:lingua_ai/features/ai/presentation/widgets/ai_recommendation_card.dart';
import 'package:lingua_ai/features/ai/presentation/widgets/ai_explanation_sheet.dart';
import 'package:lingua_ai/features/ai/presentation/widgets/ai_feedback_card.dart';
import 'package:lingua_ai/features/ai/presentation/widgets/ai_status_notice.dart';
import 'package:lingua_ai/features/ai/presentation/widgets/ai_conversation_view.dart';
import 'package:lingua_ai/features/ai/presentation/widgets/ai_progress_insight_card.dart';

void main() {
  group('AiRecommendationCard Widget Tests', () {
    testWidgets('Renders recommendation details and non-diagnostic disclaimer', (tester) async {
      bool started = false;
      const rec = AiRecommendationItemModel(
        lessonId: 'lesson-dld-001',
        reasonCode: 'skill_continuity',
        shortExplanation: 'Continues practicing descriptive vocabulary.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiRecommendationCard(
              recommendation: rec,
              lessonTitle: 'Descriptive Words in Stories',
              onStart: () => started = true,
            ),
          ),
        ),
      );

      expect(find.text('AI-Assisted Suggestion'), findsOneWidget);
      expect(find.text('Descriptive Words in Stories'), findsOneWidget);
      expect(find.text('Continues practicing descriptive vocabulary.'), findsOneWidget);
      expect(find.textContaining('Not a clinical prescription'), findsOneWidget);

      await tester.tap(find.text('Start Suggested Activity'));
      await tester.pump();
      expect(started, isTrue);
    });
  });

  group('AiExplanationSheet Widget Tests', () {
    testWidgets('Renders concept explanation and non-diagnostic educational note', (tester) async {
      const expl = AiExplanationModel(
        explanation: 'A compound sentence joins two complete thoughts with a conjunction.',
        clarityTip: 'Notice the comma before "and".',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiExplanationSheet(
              conceptTitle: 'Compound Sentences',
              explanation: expl,
              onClose: () {},
            ),
          ),
        ),
      );

      expect(find.text('AI-Assisted Explanation'), findsOneWidget);
      expect(find.text('Compound Sentences'), findsOneWidget);
      expect(find.textContaining('two complete thoughts'), findsOneWidget);
      expect(find.textContaining('Notice the comma'), findsOneWidget);
      expect(find.textContaining('It is not clinical or diagnostic advice'), findsOneWidget);
    });
  });

  group('AiFeedbackCard Widget Tests', () {
    testWidgets('Renders educational feedback without clinical diagnostic claims', (tester) async {
      const fb = AiFeedbackModel(
        clarityNote: 'Your ideas are arranged in clear order.',
        learningTip: 'Try adding transition words like first and next.',
        encouragement: 'Wonderful effort expressing your thoughts!',
        revisionSuggestion: 'First, I went to the park.',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AiFeedbackCard(
              feedback: fb,
              activityTitle: 'Narrative Speaking Activity',
            ),
          ),
        ),
      );

      expect(find.text('AI-Assisted Educational Feedback'), findsOneWidget);
      expect(find.text('Your ideas are arranged in clear order.'), findsOneWidget);
      expect(find.text('Try adding transition words like first and next.'), findsOneWidget);
      expect(find.text('First, I went to the park.'), findsOneWidget);
      expect(find.text('Wonderful effort expressing your thoughts!'), findsOneWidget);
      expect(find.textContaining('It is not clinical speech scoring'), findsOneWidget);
    });
  });

  group('AiStatusNotice Widget Tests', () {
    testWidgets('Renders neutral degradation notice with retry button', (tester) async {
      bool retried = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiStatusNotice(
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      expect(find.textContaining("Your regular learning activities are still available"), findsOneWidget);
      await tester.tap(find.text('Try Again'));
      await tester.pump();
      expect(retried, isTrue);
    });
  });

  group('AiProgressInsightCard Widget Tests', () {
    testWidgets('Renders quantitative summary adhering to educational language', (tester) async {
      const insight = AiProgressInsightModel(
        practiceSummary: 'You have completed 6 lessons and 14 activities.',
        whatWentWell: 'Consistent focus on vocabulary expansion.',
        nextPracticeArea: 'Sentence combining practice.',
        encouragingNote: 'Every practice session strengthens your communication.',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AiProgressInsightCard(insight: insight),
          ),
        ),
      );

      expect(find.text('AI Learning Summary'), findsOneWidget);
      expect(find.text('You have completed 6 lessons and 14 activities.'), findsOneWidget);
      expect(find.text('Consistent focus on vocabulary expansion.'), findsOneWidget);
      expect(find.text('Sentence combining practice.'), findsOneWidget);
      expect(find.textContaining('Not a medical evaluation or clinical outcome score'), findsOneWidget);
    });
  });

  group('AiConversationView Widget Tests', () {
    testWidgets('Renders conversational partner and handles turns', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiConversationView(
              scenario: 'clarification',
              scenarioTitle: 'Asking for Clarification',
              maxTurns: 3,
              onSendMessage: (msg) async {
                return const AiConversationReplyModel(
                  reply: 'That is a great way to ask! How would you say it politely?',
                  followupPrompt: 'Try using please.',
                );
              },
              onReset: () {},
            ),
          ),
        ),
      );

      expect(find.text('Asking for Clarification'), findsOneWidget);
      expect(find.textContaining('Turn 0 of 3'), findsOneWidget);
      expect(find.textContaining('Welcome to this practice scenario'), findsOneWidget);
      expect(find.textContaining('Constrained conversational practice for educational use only'), findsOneWidget);

      // Enter user text
      await tester.enterText(find.byType(TextField), 'Could you please repeat that?');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      expect(find.text('Could you please repeat that?'), findsOneWidget);
      expect(find.text('That is a great way to ask! How would you say it politely?'), findsOneWidget);
      expect(find.text('Turn 1 of 3 • Educational Practice Partner'), findsOneWidget);
    });
  });
}

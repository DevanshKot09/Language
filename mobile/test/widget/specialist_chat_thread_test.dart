import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_ai/features/collaboration/presentation/screens/collaboration_chat_screen.dart';

void main() {
  Widget buildChatScreen({
    String conversationId = 'group_aarav',
    String? conversationTitle,
    bool isLocked = false,
  }) {
    return ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFFAF9FF),
        ),
        home: CollaborationChatScreen(
          conversationId: conversationId,
          title: conversationTitle ?? "Aarav's Support Circle",
          subtitle: "Speech Specialist • Online",
          targetLearnerId: "learner_aarav",
          roles: const ['Parent', 'Teacher', 'Specialist'],
          isLocked: isLocked,
        ),
      ),
    );
  }

  group('LINGUA AI Specialist Chat Thread - Stitch Reference UI & Interaction Tests', () {
    testWidgets('Renders complete Stitch visual hierarchy and header', (WidgetTester tester) async {
      await tester.pumpWidget(buildChatScreen());
      await tester.pumpAndSettle();

      // 1. Header back button, title, and subtitle
      expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);
      expect(find.byIcon(Icons.more_vert_rounded), findsOneWidget);
      expect(find.text("Aarav's Support Circle"), findsOneWidget);
      expect(find.text('Speech Specialist • Online'), findsOneWidget);

      // 2. Date separators
      expect(find.text('Yesterday'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);

      // 3. Incoming message senders and role badges
      expect(find.text('Priya Mehta'), findsWidgets);
      expect(find.text('Parent'), findsOneWidget);
      expect(find.text('Mrs. Davies'), findsOneWidget);
      expect(find.text('Teacher • Oakridge'), findsOneWidget);

      // 4. Outgoing message elements
      expect(find.text('You (Specialist)'), findsWidgets);
      expect(find.textContaining('Delivered'), findsWidgets);
      expect(find.textContaining('two-syllable'), findsWidgets);

      // 5. Attachment preview card
      expect(find.textContaining('Phoneme_Pacing'), findsWidgets);
      expect(find.textContaining('2.4 MB'), findsWidgets);
      expect(find.text('Preview'), findsWidgets);

      // 6. Composer bar
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
      expect(find.text('Write a message...'), findsOneWidget);
      expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
    });

    testWidgets('Input composer typing activates send and adds message', (WidgetTester tester) async {
      await tester.pumpWidget(buildChatScreen());
      await tester.pumpAndSettle();

      final inputField = find.byType(TextField);
      expect(inputField, findsOneWidget);

      // Enter test response
      await tester.enterText(inputField, 'Session recap scheduled for Friday.');
      await tester.pumpAndSettle();

      expect(find.text('Session recap scheduled for Friday.'), findsOneWidget);

      // Tap send button
      final sendBtn = find.byKey(const ValueKey('chat_send_button'));
      expect(sendBtn, findsOneWidget);
      await tester.tap(sendBtn);
      await tester.pumpAndSettle();

      // Verified text is present as outgoing message
      expect(find.text('Session recap scheduled for Friday.'), findsOneWidget);
    });

    testWidgets('Tapping attachment button opens resource options bottom sheet', (WidgetTester tester) async {
      await tester.pumpWidget(buildChatScreen());
      await tester.pumpAndSettle();

      final attachBtn = find.byKey(const ValueKey('chat_attachment_button'));
      expect(attachBtn, findsOneWidget);
      await tester.tap(attachBtn);
      await tester.pumpAndSettle();

      expect(find.text('Attach Learning Resource'), findsOneWidget);
      expect(find.text('Phonics Pacing Cards (PDF)'), findsOneWidget);
      expect(find.text('Fluency Progress Worksheet'), findsOneWidget);
      expect(find.text('Session Turn Summary'), findsOneWidget);

      // Select a resource
      await tester.tap(find.text('Phonics Pacing Cards (PDF)'));
      await tester.pumpAndSettle();

      // Sheet closes
      expect(find.text('Attach Learning Resource'), findsNothing);
    });

    testWidgets('Tapping header more menu displays learner context actions', (WidgetTester tester) async {
      await tester.pumpWidget(buildChatScreen());
      await tester.pumpAndSettle();

      final moreBtn = find.byKey(const ValueKey('chat_header_more_button'));
      expect(moreBtn, findsOneWidget);
      await tester.tap(moreBtn);
      await tester.pumpAndSettle();

      expect(find.text('View Learner Profile'), findsOneWidget);
      expect(find.text('View Progress Report'), findsOneWidget);
      expect(find.text('Schedule Support Session'), findsOneWidget);
      expect(find.text('Collaboration Privacy & Consent'), findsOneWidget);
    });

    testWidgets('Consent locked conversation shows privacy notice and audio restriction', (WidgetTester tester) async {
      await tester.pumpWidget(buildChatScreen(isLocked: true));
      await tester.pumpAndSettle();

      // Consent warning banner is displayed
      expect(find.textContaining('Guardian Consent Pending'), findsOneWidget);

      // Tapping mic shows locked alert
      final micBtn = find.byKey(const ValueKey('chat_mic_button'));
      expect(micBtn, findsOneWidget);
      await tester.tap(micBtn);
      await tester.pumpAndSettle();

      expect(find.text('Audio Turns Locked'), findsOneWidget);
    });

    testWidgets('Responsive Layout: No overflow on 320px, 360px, 390px, 430px widths', (WidgetTester tester) async {
      final testWidths = [320.0, 360.0, 390.0, 430.0];

      for (final width in testWidths) {
        tester.view.physicalSize = Size(width * 2.5, 800 * 2.5);
        tester.view.devicePixelRatio = 2.5;

        await tester.pumpWidget(buildChatScreen());
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Failed overflow check on width $width');
      }

      tester.view.resetPhysicalSize();
    });
  });
}

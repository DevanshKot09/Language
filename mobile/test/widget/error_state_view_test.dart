import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingua_ai/app/providers/session_provider.dart';
import 'package:lingua_ai/app/router/app_router.dart';
import 'package:lingua_ai/features/collaboration/application/collaboration_providers.dart';
import 'package:lingua_ai/features/error_state/error_state_type.dart';
import 'package:lingua_ai/features/error_state/error_state_view.dart';
import 'package:lingua_ai/shared/models/auth_user.dart';
import 'package:lingua_ai/shared/models/user_role.dart';

void main() {
  Widget buildTestApp({
    required Widget child,
    UserRole? role,
    bool isAuthenticated = false,
  }) {
    final user = isAuthenticated
        ? AuthUser(
            id: 'test-user',
            email: 'test@lingua.ai',
            role: role ?? UserRole.specialist,
            status: 'active',
            createdAt: DateTime.now(),
          )
        : null;

    return ProviderScope(
      overrides: [
        userSessionProvider.overrideWith(
          () => _MockUserSessionNotifier(
            UserSessionState(
              status: isAuthenticated
                  ? SessionStatus.authenticated
                  : SessionStatus.unauthenticated,
              currentUser: user,
              currentRole: role ?? UserRole.learner,
            ),
          ),
        ),
        specialistCaseloadProvider.overrideWith((ref) => Future.value([])),
        relationshipsProvider.overrideWith((ref) => Future.value([])),
        invitationsProvider.overrideWith((ref) => Future.value([])),
      ],
      child: MaterialApp(
        onGenerateRoute: AppRouter.generateRoute,
        home: child,
      ),
    );
  }

  group('ErrorStateView Widget Tests', () {
    testWidgets('Renders notFound (404) with proper layout, text and primary Go to Home button', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: const ErrorStateView(type: ErrorStateType.notFound),
        ),
      );
      await tester.pump();

      expect(find.text('404'), findsOneWidget);
      expect(find.text("Looks like you're lost"), findsOneWidget);
      expect(find.text('The page you are looking for is not available.'), findsOneWidget);
      expect(find.byKey(const Key('error_state_go_home_primary_button')), findsOneWidget);
      expect(find.text('Go to Home'), findsOneWidget);
      expect(find.byKey(const Key('error_state_retry_button')), findsNothing);
    });

    testWidgets('Renders noInternet with OFFLINE badge, Try again button and secondary Go to Home', (tester) async {
      bool retried = false;
      await tester.pumpWidget(
        buildTestApp(
          child: ErrorStateView(
            type: ErrorStateType.noInternet,
            onRetry: () => retried = true,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('OFFLINE'), findsOneWidget);
      expect(find.text('No internet connection'), findsOneWidget);
      expect(find.text('Check your Wi-Fi or mobile data and try again.'), findsOneWidget);
      expect(find.byKey(const Key('error_state_retry_button')), findsOneWidget);
      expect(find.byKey(const Key('error_state_go_home_secondary_button')), findsOneWidget);

      await tester.tap(find.byKey(const Key('error_state_retry_button')));
      await tester.pump();
      expect(retried, isTrue);
    });

    testWidgets('Renders serverError with 500 badge and custom title/message overrides', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: const ErrorStateView(
            type: ErrorStateType.serverError,
            title: 'Custom Server Outage',
            message: 'Our clusters are rebooting.',
            errorCode: '503',
          ),
        ),
      );
      await tester.pump();

      expect(find.text('503'), findsOneWidget);
      expect(find.text('Custom Server Outage'), findsOneWidget);
      expect(find.text('Our clusters are rebooting.'), findsOneWidget);
      expect(find.byKey(const Key('error_state_retry_button')), findsOneWidget);
    });

    testWidgets('Renders generic error state properly', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: const ErrorStateView(type: ErrorStateType.generic),
        ),
      );
      await tester.pump();

      expect(find.text('ERROR'), findsOneWidget);
      expect(find.text('Oops, something broke'), findsOneWidget);
      expect(find.text('Please try again.'), findsOneWidget);
    });

    testWidgets('Navigates to /specialist when logged in as specialist', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          isAuthenticated: true,
          role: UserRole.specialist,
          child: const ErrorStateView(type: ErrorStateType.notFound),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('error_state_go_home_primary_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Should land on specialist dashboard
      expect(find.text('Lingua AI'), findsWidgets);
    });

    testWidgets('Navigates to /login when unauthenticated', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          isAuthenticated: false,
          child: const ErrorStateView(type: ErrorStateType.notFound),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('error_state_go_home_primary_button')));
      await tester.pumpAndSettle();

      // Should land on Login screen
      expect(find.text('Sign In'), findsWidgets);
    });

    testWidgets('Supports disableAnimations without throwing or looping', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(() {
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
      });

      await tester.pumpWidget(
        buildTestApp(
          child: const ErrorStateView(type: ErrorStateType.noInternet),
        ),
      );
      await tester.pump();

      expect(find.text('No internet connection'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Responsive rendering at 320, 360, 390, 430 px widths without overflow', (tester) async {
      final widths = [320.0, 360.0, 390.0, 430.0];
      for (final w in widths) {
        tester.view.physicalSize = Size(w * 3, 1000 * 3);
        tester.view.devicePixelRatio = 3.0;

        await tester.pumpWidget(
          buildTestApp(
            child: const ErrorStateView(type: ErrorStateType.serverError),
          ),
        );
        await tester.pump();

        expect(find.text('500'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      tester.view.resetPhysicalSize();
    });
  });
}

class _MockUserSessionNotifier extends UserSessionNotifier {
  final UserSessionState _initial;
  _MockUserSessionNotifier(this._initial);

  @override
  UserSessionState build() => _initial;
}

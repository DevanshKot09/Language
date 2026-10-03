import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/design_tokens/tokens.dart';
import '../../shared/models/skill_track.dart';
import '../../shared/models/user_role.dart';
import '../../core/widgets/non_diagnostic_banner.dart';
import '../../core/widgets/lingua_selection_card.dart';
import '../../core/widgets/lingua_button.dart';
import '../../app/providers/session_provider.dart';
import '../../app/router/app_router.dart';

/// UX-02 ONBOARDING SCREEN
/// Streamlined 3-step experience adhering to Phase 4 guidance:
/// Strong visual, short title, concise description, clear progress indicator,
/// smooth PageView transitions, and non-diagnostic boundary preservation.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const int _totalPages = 3;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _finishOnboarding() {
    final sessionNotifier = ref.read(userSessionProvider.notifier);
    final session = ref.read(userSessionProvider);
    sessionNotifier.completeOnboarding();

    switch (session.currentRole) {
      case UserRole.parent:
        Navigator.pushReplacementNamed(context, AppRoutes.parentDashboard);
        break;
      case UserRole.teacher:
        Navigator.pushReplacementNamed(context, AppRoutes.teacherDashboard);
        break;
      case UserRole.specialist:
        Navigator.pushReplacementNamed(context, AppRoutes.specialistDashboard);
        break;
      case UserRole.learner:
        Navigator.pushReplacementNamed(context, AppRoutes.home);
        break;
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(userSessionProvider);
    final sessionNotifier = ref.read(userSessionProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: _currentPage > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: LinguaTokens.ink900),
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeInOut,
                  );
                },
              )
            : null,
        title: Text(
          'Step ${_currentPage + 1} of $_totalPages',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: LinguaTokens.ink700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _finishOnboarding,
            child: const Text(
              'Skip',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: LinguaTokens.inkMuted,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: LinguaTokens.space24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_currentPage + 1) / _totalPages,
                  backgroundColor: LinguaTokens.paper100,
                  valueColor: const AlwaysStoppedAnimation<Color>(LinguaTokens.primary600),
                  minHeight: 4,
                ),
              ),
            ),
            const SizedBox(height: LinguaTokens.space12),

            // Scrollable / Animated PageView Body
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  // Page 1: Inclusive Foundation
                  _buildPage1(),

                  // Page 2: Track Focus
                  _buildPage2(session, sessionNotifier),

                  // Page 3: Accessibility Comfort & Ready
                  _buildPage3(),
                ],
              ),
            ),

            // Bottom CTA & Page Dots
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: LinguaTokens.space24,
                vertical: LinguaTokens.space16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Smooth indicator dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_totalPages, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 22 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: isActive ? LinguaTokens.primary600 : LinguaTokens.borderSubtle,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: LinguaTokens.space16),

                  LinguaButton(
                    label: _currentPage == _totalPages - 1 ? 'Go to Dashboard' : 'Continue',
                    onPressed: _nextPage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: LinguaTokens.space24, vertical: LinguaTokens.space12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const NonDiagnosticBanner(compact: true),
          const SizedBox(height: LinguaTokens.space20),

          // Visual illustration card
          Center(
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: LinguaTokens.primary100,
                shape: BoxShape.circle,
                border: Border.all(color: LinguaTokens.primary500.withValues(alpha: 0.2), width: 3),
              ),
              child: const Icon(
                Icons.auto_stories_rounded,
                size: 52,
                color: LinguaTokens.primary600,
              ),
            ),
          ),
          const SizedBox(height: LinguaTokens.space24),

          const Text(
            'Personalized to your strengths.',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: LinguaTokens.ink900,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: LinguaTokens.space12),
          const Text(
            'LINGUA AI separates spoken language learning (DLD) and reading fluency (Dyslexia) so you practice with evidence-based exercises.',
            style: TextStyle(
              fontSize: 15,
              height: 1.45,
              color: LinguaTokens.ink700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: LinguaTokens.space24),

          Container(
            padding: const EdgeInsets.all(LinguaTokens.space16),
            decoration: BoxDecoration(
              color: LinguaTokens.paper50,
              borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
              border: Border.all(color: LinguaTokens.borderSubtle),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, color: LinguaTokens.success600, size: 24),
                SizedBox(width: LinguaTokens.space12),
                Expanded(
                  child: Text(
                    'Practice with safe speech-language pathology principles in a private, supportive space.',
                    style: TextStyle(fontSize: 13, color: LinguaTokens.ink700, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage2(dynamic session, dynamic sessionNotifier) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: LinguaTokens.space24, vertical: LinguaTokens.space12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Choose your focus area',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: LinguaTokens.ink900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Select your initial practice focus. You can switch or combine them anytime in settings.',
            style: TextStyle(fontSize: 14, color: LinguaTokens.ink700),
          ),
          const SizedBox(height: LinguaTokens.space20),

          ...SupportTrack.values.map((track) {
            return LinguaSelectionCard(
              title: track.title,
              subtitle: track.subtitle,
              activeColor: track.primaryColor,
              activeBackgroundColor: track.backgroundColor,
              isSelected: session.activeTrack == track,
              onSelected: () => sessionNotifier.setTrack(track),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPage3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: LinguaTokens.space24, vertical: LinguaTokens.space12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: LinguaTokens.successLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                size: 54,
                color: LinguaTokens.success600,
              ),
            ),
          ),
          const SizedBox(height: LinguaTokens.space20),

          const Text(
            'You are all set!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: LinguaTokens.ink900,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: LinguaTokens.space8),
          const Text(
            'Your workspace is prepared with personalized exercises, accessible audio guides, and progress tracking.',
            style: TextStyle(fontSize: 14, height: 1.45, color: LinguaTokens.ink700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: LinguaTokens.space24),

          Container(
            padding: const EdgeInsets.all(LinguaTokens.space16),
            decoration: BoxDecoration(
              color: LinguaTokens.paper50,
              borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
              border: Border.all(color: LinguaTokens.borderSubtle),
            ),
            child: Column(
              children: [
                _buildComfortFeature(
                  icon: Icons.record_voice_over_rounded,
                  title: 'High-Legibility Font & Text-to-Speech',
                  subtitle: 'Every exercise supports clear audio read-aloud.',
                ),
                const Divider(height: 20, color: LinguaTokens.borderSubtle),
                _buildComfortFeature(
                  icon: Icons.speed_rounded,
                  title: 'Learn at Your Own Pace',
                  subtitle: 'No penalties, no timers unless you choose them.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildComfortFeature({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: LinguaTokens.borderSubtle),
          ),
          child: Icon(icon, size: 20, color: LinguaTokens.primary600),
        ),
        const SizedBox(width: LinguaTokens.space12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: LinguaTokens.ink900),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: LinguaTokens.ink700),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

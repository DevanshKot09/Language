import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/router/app_router.dart';

/// LINGUA AI - Premium 3-Screen Welcome / Onboarding Flow
///
/// Faithfully reproduces the visual hierarchy, typography, colors, and layout
/// from the reference designs:
/// - Screen 1: "Language learning, made personal."
/// - Screen 2: "Practice at your pace." (with ✨ Personalized badge)
/// - Screen 3: "Learn with the right support." (ecosystem & secondary sign-in)
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late final AnimationController _floatController;
  int _currentPage = 0;

  static const int _totalPages = 3;

  @override
  void initState() {
    super.initState();
    // Continuous subtle floating micro-animation for the illustration panel
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 340),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _onGetStarted();
    }
  }

  void _onBack() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 340),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _onSkip() {
    Navigator.pushNamed(context, AppRoutes.signup);
  }

  void _onGetStarted() {
    Navigator.pushNamed(context, AppRoutes.signup);
  }

  void _onSignIn() {
    Navigator.pushNamed(context, AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9FD),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFAF9FD),
              Color(0xFFF5F1FA),
              Color(0xFFEFEAF7),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 1. Top Navigation Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back Button (Screens 2 & 3)
                    _currentPage > 0
                        ? Semantics(
                            label: 'Back to previous screen',
                            button: true,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _onBack,
                                borderRadius: BorderRadius.circular(22.0),
                                child: Container(
                                  width: 44.0,
                                  height: 44.0,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFFECE7F7),
                                      width: 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF38148E).withValues(alpha: 0.06),
                                        blurRadius: 10.0,
                                        offset: const Offset(0, 3.0),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.arrow_back,
                                    color: Color(0xFF1B1738),
                                    size: 20.0,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : const SizedBox(width: 44.0, height: 44.0),

                    // Skip Action
                    Semantics(
                      label: 'Skip onboarding',
                      button: true,
                      child: TextButton(
                        onPressed: _onSkip,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                          minimumSize: const Size(44.0, 44.0),
                        ),
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3B3855),
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Continuous Swipable PageView
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  children: [
                    _buildPage(
                      index: 0,
                      screenHeight: size.height,
                      screenWidth: size.width,
                      headline: 'Language learning, made\npersonal.',
                      description:
                          'Build communication skills through\nguided practice designed around you.',
                      illustration: _buildScreen1Illustration(),
                    ),
                    _buildPage(
                      index: 1,
                      screenHeight: size.height,
                      screenWidth: size.width,
                      headline: 'Practice at your pace.',
                      description:
                          'Follow focused activities that adapt to\nyour learning journey.',
                      illustration: _buildScreen2Illustration(),
                    ),
                    _buildPage(
                      index: 2,
                      screenHeight: size.height,
                      screenWidth: size.width,
                      headline: 'Learn with the right support.',
                      description:
                          'Track progress and stay connected with the\npeople who support your learning.',
                      illustration: _buildScreen3Illustration(),
                    ),
                  ],
                ),
              ),

              // 3. Bottom Controls Area (Progress Indicator + Primary CTA + Secondary Action)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 3-Step Progress Indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_totalPages, (i) {
                        final bool isActive = _currentPage == i;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOutCubic,
                          margin: const EdgeInsets.symmetric(horizontal: 4.0),
                          width: isActive ? 28.0 : 7.0,
                          height: 6.5,
                          decoration: BoxDecoration(
                            color: isActive
                                ? const Color(0xFF4F22E5)
                                : const Color(0xFFE4DCF9),
                            borderRadius: BorderRadius.circular(3.5),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 22.0),

                    // Primary 3D CTA Button
                    _Onboarding3DButton(
                      label: _currentPage == 2 ? 'Get Started' : 'Next',
                      onPressed: _onNext,
                    ),

                    const SizedBox(height: 12.0),

                    // Secondary Account Action (Screen 3 only)
                    SizedBox(
                      height: 26.0,
                      child: _currentPage == 2
                          ? FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Already have an account? ',
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF4C4964),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: _onSignIn,
                                    child: const Text(
                                      'Sign in',
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF4F22E5),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),

                    const SizedBox(height: 6.0),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage({
    required int index,
    required double screenHeight,
    required double screenWidth,
    required String headline,
    required String description,
    required Widget illustration,
  }) {
    final double maxCardWidth = math.max(160.0, screenWidth - 48.0);
    final double responsiveCardDim = screenHeight < 700
        ? math.min(maxCardWidth, 230.0)
        : math.min(maxCardWidth, 320.0);

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            SizedBox(height: screenHeight < 700 ? 8.0 : 16.0),

            // Large Centered Illustration Container
            AnimatedBuilder(
              animation: _floatController,
              builder: (context, child) {
                final double dy = math.sin(_floatController.value * 2 * math.pi) * 3.5;
                return Transform.translate(
                  offset: Offset(0, dy),
                  child: child,
                );
              },
              child: Container(
                width: responsiveCardDim,
                height: responsiveCardDim,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32.0),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.95),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF38148E).withValues(alpha: 0.07),
                      blurRadius: 28.0,
                      offset: const Offset(0, 14.0),
                      spreadRadius: -4.0,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30.0),
                  child: illustration,
                ),
              ),
            ),

            SizedBox(height: screenHeight < 700 ? 18.0 : 28.0),

            // Headline
            Text(
              headline,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: screenHeight < 700 ? 23.0 : 27.0,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1B1738),
                height: 1.25,
                letterSpacing: -0.4,
              ),
            ),

            const SizedBox(height: 12.0),

            // Description
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: screenHeight < 700 ? 14.0 : 15.5,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF4C4964),
                height: 1.45,
                letterSpacing: 0.1,
              ),
            ),

            const SizedBox(height: 16.0),
          ],
        ),
      ),
    );
  }

  Widget _buildScreen1Illustration() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFAF9FD),
      ),
      child: Center(
        child: Image.asset(
          'assets/branding/onboarding_1_illustration.png',
          fit: BoxFit.contain,
          semanticLabel: 'Abstract flowing speech and communication ribbon illustration',
        ),
      ),
    );
  }

  Widget _buildScreen2Illustration() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFAF9FD),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: Image.asset(
              'assets/branding/onboarding_2_illustration.png',
              fit: BoxFit.contain,
              semanticLabel: 'Personalized practice path with connected learning nodes',
            ),
          ),
          // Floating "✨ Personalized" Pill Badge
          Positioned(
            right: 14.0,
            bottom: 14.0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.0),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF38148E).withValues(alpha: 0.12),
                    blurRadius: 16.0,
                    offset: const Offset(0, 4.0),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: Color(0xFF00B4B0),
                    size: 16.0,
                  ),
                  SizedBox(width: 6.0),
                  Text(
                    'Personalized',
                    style: TextStyle(
                      fontSize: 13.0,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1B1738),
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScreen3Illustration() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFAF9FD),
      ),
      child: Center(
        child: Image.asset(
          'assets/branding/onboarding_3_illustration.png',
          fit: BoxFit.contain,
          semanticLabel:
              'Connected support ecosystem: Parent, Learner, Educator, and Specialist',
        ),
      ),
    );
  }
}

/// Tactile 3D Rounded Purple Onboarding Button
class _Onboarding3DButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _Onboarding3DButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    const double buttonHeight = 56.0;
    const double borderRadiusValue = 28.0;

    return Semantics(
      label: label,
      button: true,
      child: SizedBox(
        width: double.infinity,
        height: buttonHeight + 4.0, // extra height for the 3D bottom bevel
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // Darker Indigo/Purple Lower Ledge (3D Depth)
            Positioned(
              top: 4.0,
              left: 0,
              right: 0,
              child: Container(
                height: buttonHeight,
                decoration: BoxDecoration(
                  color: const Color(0xFF2E0F98),
                  borderRadius: BorderRadius.circular(borderRadiusValue),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF38148E).withValues(alpha: 0.28),
                      blurRadius: 18.0,
                      offset: const Offset(0, 8.0),
                      spreadRadius: -2.0,
                    ),
                  ],
                ),
              ),
            ),

            // Top Primary Button Face
            Positioned(
              top: 0.0,
              left: 0,
              right: 0,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onPressed,
                  borderRadius: BorderRadius.circular(borderRadiusValue),
                  child: Container(
                    height: buttonHeight,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F22E5),
                      borderRadius: BorderRadius.circular(borderRadiusValue),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            label,
                            style: const TextStyle(
                              fontSize: 17.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          const Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: 20.0,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

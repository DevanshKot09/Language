import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/user_role.dart';
import '../../app/providers/session_provider.dart';
import '../../app/router/app_router.dart';

/// LINGUA AI - Premium Application Launch / Splash Screen
///
/// Faithfully reproduces the reference visual hierarchy:
/// 1. Pale lavender / off-white ambient background
/// 2. Delicate flowing background communication waves & floating nodes
/// 3. Centered 3D purple-indigo rounded app icon with dual-bubble speech glyph (white + cyan)
/// 4. Bold geometric "LINGUA" wordmark with lavender "AI" pill
/// 5. Refined tagline: "Learn. Practice. Communicate."
/// 6. Minimal horizontal purple indicator loading animation
/// 7. Supporting context label: Shield icon + "SPEECH & LANGUAGE AI"
/// 8. Non-blocking Firebase auth / session restoration & role-based routing
class SplashScreen extends ConsumerStatefulWidget {
  final bool autoInitialize;

  const SplashScreen({
    super.key,
    this.autoInitialize = true,
  });

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _waveController;
  late final AnimationController _loadingController;
  late final AnimationController _exitController;

  late final Animation<double> _iconFade;
  late final Animation<double> _iconScale;
  late final Animation<double> _brandFade;
  late final Animation<Offset> _brandSlide;
  late final Animation<double> _taglineFade;
  late final Animation<Offset> _taglineSlide;
  late final Animation<double> _indicatorFade;
  late final Animation<double> _bottomFade;
  late final Animation<double> _exitFade;
  late final Animation<Offset> _exitSlide;

  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    // 1. Entrance animation sequence (1100ms)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _iconFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.05, 0.50, curve: Curves.easeOut),
      ),
    );

    _iconScale = Tween<double>(begin: 0.93, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.05, 0.55, curve: Curves.easeOutBack),
      ),
    );

    _brandFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.30, 0.70, curve: Curves.easeOut),
      ),
    );

    _brandSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.20),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.30, 0.70, curve: Curves.easeOutCubic),
      ),
    );

    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.50, 0.85, curve: Curves.easeOut),
      ),
    );

    _taglineSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.50, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _indicatorFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.65, 0.95, curve: Curves.easeOut),
      ),
    );

    _bottomFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.75, 1.0, curve: Curves.easeOut),
      ),
    );

    // 2. Background wave animation (continuous gentle flow, 3500ms cycle)
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat();

    // 3. Smooth horizontal loading indicator animation (1400ms cycle)
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    // 4. Smooth exit transition controller (350ms)
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInOut),
    );

    _exitSlide = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.0, -0.04),
    ).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInOut),
    );

    _entranceController.forward();

    // Trigger async initialization and subsequent navigation if enabled
    if (widget.autoInitialize) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _startAppInitialization();
        }
      });
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _waveController.dispose();
    _loadingController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  Future<void> _startAppInitialization() async {
    try {
      final stopwatch = Stopwatch()..start();

      // Restore server-authoritative session or verify unauthenticated state
      try {
        await ref
            .read(userSessionProvider.notifier)
            .restoreSession()
            .timeout(const Duration(milliseconds: 2500), onTimeout: () {});
      } catch (e) {
        debugPrint('Session restoration notice: $e');
      }

      // Allow the entrance sequence and branding to be appreciated comfortably
      final elapsed = stopwatch.elapsedMilliseconds;
      if (elapsed < 2000) {
        await Future.delayed(Duration(milliseconds: 2000 - elapsed));
      }

      if (!mounted || _hasNavigated) return;

      // Smooth exit transition (fade out and gentle lift)
      await _exitController.forward();
      if (!mounted || _hasNavigated) return;

      _hasNavigated = true;
      _performNavigation();
    } catch (_) {
      if (mounted && !_hasNavigated) {
        _hasNavigated = true;
        _performNavigation();
      }
    }
  }

  void _performNavigation() {
    final sessionState = ref.read(userSessionProvider);

    if (sessionState.isAuthenticated && sessionState.currentUser != null) {
      // Direct authenticated users to their server-authoritative workspace
      final destination = switch (sessionState.currentRole) {
        UserRole.learner => AppRoutes.home,
        UserRole.parent => AppRoutes.parentDashboard,
        UserRole.teacher => AppRoutes.teacherDashboard,
        UserRole.specialist => AppRoutes.specialistDashboard,
      };
      Navigator.pushNamedAndRemoveUntil(context, destination, (route) => false);
    } else {
      // Unauthenticated users proceed to Get Started / Welcome
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.welcome, (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FC),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Ambient Background Gradient (Pale Lavender / Off-White)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFAF9FD),
                  Color(0xFFF4F1FA),
                  Color(0xFFEFEAF8),
                ],
              ),
            ),
          ),

          // 2. Animated Flowing Wave Lines & Decorative Nodes Behind Icon
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _SplashWavePainter(
                    animationProgress: _waveController.value,
                  ),
                );
              },
            ),
          ),

          // 3. Central Composition
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: FadeTransition(
                    opacity: _exitFade,
                    child: SlideTransition(
                      position: _exitSlide,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Top Breathing Space (Responsive)
                          SizedBox(height: size.height * 0.04),

                          // APP ICON WITH 3D DEPTH & GLYPH
                          AnimatedBuilder(
                            animation: _entranceController,
                            builder: (context, child) {
                              return FadeTransition(
                                opacity: _iconFade,
                                child: ScaleTransition(
                                  scale: _iconScale,
                                  child: const _Lingua3DIcon(),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 36.0),

                          // BRAND NAME: LINGUA + [AI] PILL
                          AnimatedBuilder(
                            animation: _entranceController,
                            builder: (context, child) {
                              return FadeTransition(
                                opacity: _brandFade,
                                child: SlideTransition(
                                  position: _brandSlide,
                                  child: child,
                                ),
                              );
                            },
                            child: const _LinguaBrandWordmark(),
                          ),

                          const SizedBox(height: 14.0),

                          // TAGLINE: "Learn. Practice. Communicate."
                          AnimatedBuilder(
                            animation: _entranceController,
                            builder: (context, child) {
                              return FadeTransition(
                                opacity: _taglineFade,
                                child: SlideTransition(
                                  position: _taglineSlide,
                                  child: child,
                                ),
                              );
                            },
                            child: const Text(
                              'Learn. Practice. Communicate.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF383652),
                                letterSpacing: 0.15,
                                height: 1.25,
                              ),
                            ),
                          ),

                          const SizedBox(height: 24.0),

                          // ANIMATED HORIZONTAL PURPLE LOADING INDICATOR
                          AnimatedBuilder(
                            animation: _entranceController,
                            builder: (context, child) {
                              return FadeTransition(
                                opacity: _indicatorFade,
                                child: child,
                              );
                            },
                            child: _SplashHorizontalLoadingLine(
                              animation: _loadingController,
                            ),
                          ),

                          const SizedBox(height: 24.0),

                          // BOTTOM SUPPORTING LABEL: SHIELD + SPEECH & LANGUAGE AI
                          AnimatedBuilder(
                            animation: _entranceController,
                            builder: (context, child) {
                              return FadeTransition(
                                opacity: _bottomFade,
                                child: child,
                              );
                            },
                            child: const _BottomBadge(),
                          ),

                          // Bottom Safe Space
                          SizedBox(height: size.height * 0.04),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 3D Rounded Purple/Indigo Tile with Dual Speech Glyph
class _Lingua3DIcon extends StatelessWidget {
  const _Lingua3DIcon();

  @override
  Widget build(BuildContext context) {
    const double iconSize = 132.0;
    const double borderRadiusValue = 38.0;

    return Semantics(
      label: 'LINGUA AI Official Brand Logo',
      child: SizedBox(
        width: iconSize,
        height: iconSize + 8.0, // extra height to accommodate the 3D depth layer
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // Lower 3D Extrusion / Depth Layer (Darker Indigo Ledge)
            Positioned(
              top: 7.0,
              child: Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: const Color(0xFF22086E), // Dark solid 3D bevel ledge
                  borderRadius: BorderRadius.circular(borderRadiusValue),
                  boxShadow: [
                    // Deep ambient drop shadow
                    BoxShadow(
                      color: const Color(0xFF3B10C0).withValues(alpha: 0.36),
                      blurRadius: 30.0,
                      offset: const Offset(0.0, 16.0),
                      spreadRadius: -2.0,
                    ),
                  ],
                ),
              ),
            ),

            // Top Primary Face of the Rounded Icon
            Positioned(
              top: 0.0,
              child: Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadiusValue),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF6332F6), // Rich vivid purple
                      Color(0xFF4C1CDD), // Mid vibrant indigo
                      Color(0xFF3B10C0), // Deep violet
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                    width: 1.2,
                  ),
                ),
                child: Center(
                  child: CustomPaint(
                    size: const Size(62.0, 52.0),
                    painter: const _SpeechCommunicationGlyphPainter(),
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

/// Custom Vector Painter for White + Cyan Communication Speech Bubbles
class _SpeechCommunicationGlyphPainter extends CustomPainter {
  const _SpeechCommunicationGlyphPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Stroke paint settings
    final whiteStroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final cyanStroke = Paint()
      ..color = const Color(0xFF00F0FF) // Vibrant Cyan/Aqua accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final whiteFill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final cyanFill = Paint()
      ..color = const Color(0xFF00F0FF)
      ..style = PaintingStyle.fill;

    // 1. Right/Secondary Cyan Speech Bubble (organic circular bubble)
    final cyanPath = Path();
    cyanPath.moveTo(w * 0.48, h * 0.22);
    cyanPath.cubicTo(w * 0.65, h * 0.16, w * 0.88, h * 0.28, w * 0.88, h * 0.48);
    cyanPath.cubicTo(w * 0.88, h * 0.67, w * 0.72, h * 0.78, w * 0.58, h * 0.78);
    // Downward curved speech tail
    cyanPath.lineTo(w * 0.50, h * 0.92);
    cyanPath.lineTo(w * 0.48, h * 0.77);
    cyanPath.cubicTo(w * 0.38, h * 0.74, w * 0.34, h * 0.64, w * 0.34, h * 0.52);

    canvas.drawPath(cyanPath, cyanStroke);

    // Cyan internal speech dots
    canvas.drawCircle(Offset(w * 0.66, h * 0.41), 1.9, cyanFill);
    canvas.drawCircle(Offset(w * 0.76, h * 0.52), 1.9, cyanFill);

    // 2. Left/Primary White Speech Bubble (in front, smooth organic contours)
    final whitePath = Path();
    whitePath.moveTo(w * 0.36, h * 0.12);
    whitePath.cubicTo(w * 0.54, h * 0.12, w * 0.66, h * 0.24, w * 0.66, h * 0.42);
    whitePath.cubicTo(w * 0.66, h * 0.58, w * 0.54, h * 0.71, w * 0.38, h * 0.71);
    // Pointer tail at bottom-left
    whitePath.lineTo(w * 0.22, h * 0.88);
    whitePath.lineTo(w * 0.23, h * 0.70);
    // Left curve back to top
    whitePath.cubicTo(w * 0.11, h * 0.67, w * 0.08, h * 0.55, w * 0.08, h * 0.42);
    whitePath.cubicTo(w * 0.08, h * 0.25, w * 0.20, h * 0.12, w * 0.36, h * 0.12);
    whitePath.close();

    canvas.drawPath(whitePath, whiteStroke);

    // 3. Inside White Bubble: Three Communication Dots in a slight arc
    canvas.drawCircle(Offset(w * 0.27, h * 0.41), 2.2, whiteFill);
    canvas.drawCircle(Offset(w * 0.38, h * 0.39), 2.4, whiteFill);
    canvas.drawCircle(Offset(w * 0.49, h * 0.43), 2.2, whiteFill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Delicate Flowing Background Waves & Nodes
class _SplashWavePainter extends CustomPainter {
  final double animationProgress;

  _SplashWavePainter({required this.animationProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double phase = animationProgress * 2 * math.pi;

    // Center area behind the app icon
    final double centerY = h * 0.38;

    // Paint for cyan wave
    final cyanPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    // Paint for purple wave
    final purplePaint = Paint()
      ..color = const Color(0xFF7B52F8).withValues(alpha: 0.24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    // Paint for dashed lavender wave
    final dashedPaint = Paint()
      ..color = const Color(0xFF8F6CF6).withValues(alpha: 0.38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    // 1. Draw Cyan Continuous Smooth Wave
    final cyanPath = Path();
    cyanPath.moveTo(w * 0.08, centerY + 28.0 + math.sin(phase) * 5.0);
    cyanPath.cubicTo(
      w * 0.22,
      centerY + 8.0 + math.cos(phase) * 6.0,
      w * 0.40,
      centerY + 16.0 + math.sin(phase + 1) * 6.0,
      w * 0.58,
      centerY + 4.0 + math.cos(phase + 1) * 5.0,
    );
    cyanPath.cubicTo(
      w * 0.72,
      centerY - 6.0 + math.sin(phase + 2) * 6.0,
      w * 0.82,
      centerY - 18.0 + math.cos(phase + 2) * 5.0,
      w * 0.94,
      centerY - 4.0 + math.sin(phase + 3) * 6.0,
    );
    canvas.drawPath(cyanPath, cyanPaint);

    // 2. Draw Purple Continuous Smooth Wave
    final purplePath = Path();
    purplePath.moveTo(w * 0.05, centerY - 8.0 + math.cos(phase) * 6.0);
    purplePath.cubicTo(
      w * 0.25,
      centerY + 24.0 + math.sin(phase + 0.5) * 5.0,
      w * 0.48,
      centerY + 10.0 + math.cos(phase + 1.2) * 6.0,
      w * 0.65,
      centerY + 20.0 + math.sin(phase + 1.5) * 6.0,
    );
    purplePath.cubicTo(
      w * 0.78,
      centerY + 28.0 + math.cos(phase + 2.0) * 5.0,
      w * 0.88,
      centerY + 12.0 + math.sin(phase + 2.5) * 6.0,
      w * 0.96,
      centerY + 22.0 + math.cos(phase + 3.0) * 5.0,
    );
    canvas.drawPath(purplePath, purplePaint);

    // 3. Draw Dashed Lavender Wave
    _drawDashedWave(
      canvas: canvas,
      paint: dashedPaint,
      startX: w * 0.04,
      endX: w * 0.96,
      centerY: centerY - 12.0,
      phase: phase,
      width: w,
    );

    // 4. Floating Decorative Nodes / Dots
    final dotPaint = Paint()..style = PaintingStyle.fill;

    // Small lavender dot (top-left)
    dotPaint.color = const Color(0xFF7B52F8).withValues(alpha: 0.35);
    canvas.drawCircle(
      Offset(w * 0.20, centerY - 32.0 + math.sin(phase) * 3.0),
      3.2,
      dotPaint,
    );

    // Cyan dot (right)
    dotPaint.color = const Color(0xFF00E5FF).withValues(alpha: 0.40);
    canvas.drawCircle(
      Offset(w * 0.79, centerY + 30.0 + math.cos(phase) * 3.0),
      3.8,
      dotPaint,
    );

    // Tiny purple dot (far right)
    dotPaint.color = const Color(0xFF6B3FF7).withValues(alpha: 0.28);
    canvas.drawCircle(
      Offset(w * 0.93, centerY - 16.0 + math.sin(phase + 1) * 2.5),
      2.8,
      dotPaint,
    );
  }

  void _drawDashedWave({
    required Canvas canvas,
    required Paint paint,
    required double startX,
    required double endX,
    required double centerY,
    required double phase,
    required double width,
  }) {
    const double dashLength = 4.5;
    const double spaceLength = 5.0;
    double currentX = startX;

    while (currentX < endX) {
      final double progress = (currentX - startX) / (endX - startX);
      final double y = centerY +
          math.sin(progress * 4.0 * math.pi + phase) * 14.0 +
          math.cos(progress * 2.0 * math.pi) * 8.0;

      final double nextX = math.min(currentX + dashLength, endX);
      final double nextProgress = (nextX - startX) / (endX - startX);
      final double nextY = centerY +
          math.sin(nextProgress * 4.0 * math.pi + phase) * 14.0 +
          math.cos(nextProgress * 2.0 * math.pi) * 8.0;

      canvas.drawLine(Offset(currentX, y), Offset(nextX, nextY), paint);
      currentX += dashLength + spaceLength;
    }
  }

  @override
  bool shouldRepaint(covariant _SplashWavePainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress;
  }
}

/// Brand Name: "LINGUA" in bold navy with "AI" lavender pill
class _LinguaBrandWordmark extends StatelessWidget {
  const _LinguaBrandWordmark();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'LINGUA',
          style: TextStyle(
            fontSize: 32.0,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1B1938), // Deep navy / dark indigo
            letterSpacing: 2.8,
            height: 1.0,
          ),
        ),
        const SizedBox(width: 8.0),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9.5, vertical: 3.5),
          decoration: BoxDecoration(
            color: const Color(0xFFE2DCF7), // Soft lavender pill
            borderRadius: BorderRadius.circular(14.0),
          ),
          child: const Text(
            'AI',
            style: TextStyle(
              fontSize: 13.0,
              fontWeight: FontWeight.w800,
              color: Color(0xFF4A2BAF), // Secondary indigo
              letterSpacing: 0.6,
              height: 1.0,
            ),
          ),
        ),
      ],
    );
  }
}

/// Minimalist Horizontal Purple Loading Line
class _SplashHorizontalLoadingLine extends StatelessWidget {
  final Animation<double> animation;

  const _SplashHorizontalLoadingLine({required this.animation});

  @override
  Widget build(BuildContext context) {
    const double trackWidth = 140.0;
    const double trackHeight = 3.8;
    const double indicatorWidth = 38.0;

    return Container(
      width: trackWidth,
      height: trackHeight,
      decoration: BoxDecoration(
        color: const Color(0xFFE8E4F6), // Pale lavender background track
        borderRadius: BorderRadius.circular(trackHeight / 2),
      ),
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          // Slide smoothly left to right
          final double maxOffset = trackWidth - indicatorWidth;
          final double currentOffset = maxOffset * animation.value;

          return Align(
            alignment: Alignment.centerLeft,
            child: Transform.translate(
              offset: Offset(currentOffset, 0.0),
              child: Container(
                width: indicatorWidth,
                height: trackHeight,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF562FE2),
                      Color(0xFF6B3FF7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(trackHeight / 2),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Supporting Context Label: Shield + "SPEECH & LANGUAGE AI"
class _BottomBadge extends StatelessWidget {
  const _BottomBadge();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.verified_user_outlined,
          size: 15.0,
          color: Color(0xFF7E7D9A),
        ),
        SizedBox(width: 7.0),
        Text(
          'SPEECH & LANGUAGE AI',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF7E7D9A),
            letterSpacing: 1.6,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}

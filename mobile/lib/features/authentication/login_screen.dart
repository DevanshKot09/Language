import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/design_tokens/tokens.dart';
import '../../shared/models/user_role.dart';
import '../../core/widgets/lingua_text_input.dart';
import '../../core/widgets/lingua_button.dart';
import '../../core/widgets/lingua_brand_logo.dart';
import '../../app/providers/session_provider.dart';
import '../../app/router/app_router.dart';

/// UX-03 LOGIN SCREEN
/// Clean, accessible authentication interface.
/// Implements Mobbin/Refero clean visual hierarchy:
/// Brand identity -> Welcome headline -> Input fields ->
/// Sign In CTA -> OR divider -> Official Google Sign-In -> Secondary actions -> Sign Up link.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _clientError;
  bool _isGoogleSigningIn = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _clientError = 'Please enter a valid email address.');
      return;
    }
    if (password.isEmpty) {
      setState(() => _clientError = 'Please enter your password.');
      return;
    }

    setState(() {
      _clientError = null;
      _isSubmitting = true;
    });

    try {
      await ref.read(userSessionProvider.notifier).login(
            email: email,
            password: password,
          );

      if (!mounted) return;

      final session = ref.read(userSessionProvider);
      _navigateToRoleDashboard(session);
    } catch (_) {
      // The session notifier already set the domain error message
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _navigateToRoleDashboard(UserSessionState session) {
    if (!session.isOnboardingCompleted) {
      Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
      return;
    }
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

  Future<void> _handleGoogleSignIn() async {
    if (_isGoogleSigningIn || ref.read(userSessionProvider).isLoading) return;

    setState(() {
      _isGoogleSigningIn = true;
      _clientError = null;
    });

    try {
      await ref.read(userSessionProvider.notifier).signInWithGoogle();

      if (!mounted) return;

      final session = ref.read(userSessionProvider);
      _navigateToRoleDashboard(session);
    } catch (e) {
      if (mounted) {
        final session = ref.read(userSessionProvider);
        setState(() {
          _clientError = session.errorMessage ?? "We couldn't complete Google sign-in. Please try again.";
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isGoogleSigningIn = false);
      }
    }
  }

  Widget _buildGoogleIcon() {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(20, 20),
            painter: _OfficialGoogleVectorPainter(),
          ),
          const Text(
            'G',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Color(0xFF4285F4),
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(userSessionProvider);
    final errorToShow = _clientError ?? session.errorMessage;
    final isAnyLoading = _isSubmitting || _isGoogleSigningIn;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: LinguaTokens.ink900),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const LinguaBrandLogo(size: 28),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: LinguaTokens.space24,
            vertical: LinguaTokens.space12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: LinguaTokens.ink900,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Sign in to continue your personalized learning journey.',
                style: TextStyle(fontSize: 14, color: LinguaTokens.ink700),
              ),
              const SizedBox(height: LinguaTokens.space16),

              if (errorToShow != null) ...[
                Container(
                  padding: const EdgeInsets.all(LinguaTokens.space12),
                  decoration: BoxDecoration(
                    color: LinguaTokens.dangerLight,
                    borderRadius: BorderRadius.circular(LinguaTokens.radiusSmall),
                    border: Border.all(color: LinguaTokens.danger600.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: LinguaTokens.danger600, size: 20),
                      const SizedBox(width: LinguaTokens.space8),
                      Expanded(
                        child: Text(
                          errorToShow,
                          style: const TextStyle(
                            color: LinguaTokens.danger600,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: LinguaTokens.space16),
              ],

              LinguaTextInput(
                controller: _emailController,
                label: 'Email Address',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: LinguaTokens.space12),

              LinguaTextInput(
                controller: _passwordController,
                label: 'Password',
                prefixIcon: Icons.lock_outline_rounded,
                isPassword: true,
              ),
              const SizedBox(height: 4),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: LinguaTokens.primary600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: LinguaTokens.space8),

              LinguaButton(
                label: 'Sign In',
                isLoading: _isSubmitting,
                onPressed: isAnyLoading ? null : _handleLogin,
              ),
              const SizedBox(height: LinguaTokens.space12),

              Row(
                children: [
                  const Expanded(child: Divider(color: LinguaTokens.borderSubtle)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: LinguaTokens.space12),
                    child: Text(
                      'or',
                      style: TextStyle(
                        color: LinguaTokens.inkMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: LinguaTokens.borderSubtle)),
                ],
              ),
              const SizedBox(height: LinguaTokens.space12),

              LinguaButton(
                label: 'Continue with Google',
                variant: LinguaButtonVariant.secondary,
                semanticLabel: 'Continue with Google sign-in',
                isLoading: _isGoogleSigningIn,
                leading: _buildGoogleIcon(),
                onPressed: isAnyLoading ? null : _handleGoogleSignIn,
              ),
              const SizedBox(height: LinguaTokens.space12),

              LinguaButton(
                label: 'Sign In with Magic Link (Passwordless)',
                variant: LinguaButtonVariant.secondary,
                icon: Icons.mail_outline_rounded,
                onPressed: isAnyLoading ? null : () {},
              ),
              const SizedBox(height: LinguaTokens.space20),

              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.pushNamed(context, AppRoutes.signup),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: LinguaTokens.space8, horizontal: LinguaTokens.space12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('New to LINGUA AI? ', style: TextStyle(color: LinguaTokens.ink700, fontSize: 14)),
                      const Text(
                        'Create an account',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: LinguaTokens.primary600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: LinguaTokens.space16),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfficialGoogleVectorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = size.width / 2;
    final strokeWidth = radius * 0.36;

    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius - strokeWidth / 2);

    final paintRed = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final paintYellow = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final paintGreen = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final paintBlue = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    canvas.drawArc(rect, -math.pi * 0.75, math.pi * 0.65, false, paintRed);
    canvas.drawArc(rect, math.pi * 0.6, math.pi * 0.65, false, paintYellow);
    canvas.drawArc(rect, math.pi * 0.25, math.pi * 0.35, false, paintGreen);
    canvas.drawArc(rect, -math.pi * 0.1, math.pi * 0.35, false, paintBlue);

    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - strokeWidth * 0.2, cy - strokeWidth / 2, radius * 0.95, strokeWidth),
        const Radius.circular(2),
      ),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/user_role.dart';
import '../../app/providers/session_provider.dart';
import '../../app/router/app_router.dart';
import 'forgot_password_screen.dart';
import '../../core/widgets/lingua_button.dart';

/// UX-03 LOGIN SCREEN
/// Clean, accessible authentication interface matching the authentic Stitch design.
/// Implements:
/// Brand identity -> Welcome headline + abstract visual card -> Input fields with role/case cues ->
/// Sign In CTA -> OR divider -> Official Google Sign-In -> Create Account link.
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
  bool _isPasswordVisible = false;
  bool _isEmailValid = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onEmailChanged);
  }

  void _onEmailChanged() {
    final text = _emailController.text.trim();
    final isValid = RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(text);
    if (isValid != _isEmailValid) {
      setState(() => _isEmailValid = isValid);
    }
  }

  @override
  void dispose() {
    _emailController.removeListener(_onEmailChanged);
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
      // The session notifier already sets the domain error message
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _navigateToRoleDashboard(UserSessionState session) {
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.specialistDashboard, (route) => false);
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
        leadingWidth: 70,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20.0),
          child: Center(
            child: Semantics(
              label: 'Back',
              child: InkWell(
                onTap: () => Navigator.maybePop(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFECE7F7), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF38148E).withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Color(0xFF1B1738),
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFF4F22E5),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1B1738),
                  letterSpacing: -0.3,
                ),
                children: [
                  TextSpan(text: 'Lingua'),
                  TextSpan(
                    text: 'AI',
                    style: TextStyle(color: Color(0xFF4F22E5)),
                  ),
                ],
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFECE7F7), width: 1.2),
              ),
              child: const Icon(
                Icons.help_outline_rounded,
                color: Color(0xFF1B1738),
                size: 20,
              ),
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Color(0xFF4F22E5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 20,
              ),
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 24.0,
            vertical: 16.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row: "Welcome back" + Abstract Illustration Card
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Welcome back',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: Color(0xFF1B1738),
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Sign in to continue your personalized learning journey.',
                          style: TextStyle(
                            fontSize: 14.5,
                            color: Color(0xFF5E5B74),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Abstract decorative avatar card matching Stitch reference
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE9FE),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        Positioned(
                          top: -6,
                          right: -6,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFDE68A),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -8,
                          left: -8,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: Color(0xFF6EE7B7),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Error display if any
              if (errorToShow != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Color(0xFFDC2626), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          errorToShow,
                          style: const TextStyle(
                            color: Color(0xFFDC2626),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Email Field
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Email address',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1B1738),
                    ),
                  ),
                  Text(
                    'Parent or Clinician',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF7E7B95),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFECE7F7), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF38148E).withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1B1738),
                  ),
                  decoration: InputDecoration(
                    hintText: 'sarah.jenkins@example.com',
                    hintStyle: const TextStyle(
                      color: Color(0xFF9A97B0),
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                    prefixIcon: const Icon(
                      Icons.mail_outline_rounded,
                      color: Color(0xFF7E7B95),
                      size: 20,
                    ),
                    suffixIcon: _isEmailValid
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF10B981),
                            size: 20,
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Password Field
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Password',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1B1738),
                    ),
                  ),
                  Text(
                    'Case-sensitive',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF7E7B95),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFECE7F7), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF38148E).withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1B1738),
                  ),
                  decoration: InputDecoration(
                    hintText: '••••••••••••••',
                    hintStyle: const TextStyle(
                      color: Color(0xFF9A97B0),
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      color: Color(0xFF7E7B95),
                      size: 20,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: const Color(0xFF7E7B95),
                        size: 20,
                      ),
                      onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Forgot password? Button
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    final email = _emailController.text.trim();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ForgotPasswordScreen(
                          initialEmail: email.isNotEmpty ? email : null,
                        ),
                      ),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'Forgot password?',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4F22E5),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Sign In CTA Button with depth and arrow
              Semantics(
                button: true,
                label: 'Sign In',
                child: InkWell(
                  onTap: isAnyLoading ? null : _handleLogin,
                  borderRadius: BorderRadius.circular(28),
                  child: Container(
                    height: 54,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F22E5),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xFF38148E),
                          offset: Offset(0, 4),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Sign In',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                Icons.arrow_forward,
                                color: Colors.white,
                                size: 19,
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // OR Divider
              Row(
                children: const [
                  Expanded(child: Divider(color: Color(0xFFECE7F7), thickness: 1.2)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        color: Color(0xFF9A97B0),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Color(0xFFECE7F7), thickness: 1.2)),
                ],
              ),
              const SizedBox(height: 24),

              // Continue with Google Button
              LinguaButton(
                label: 'Continue with Google',
                variant: LinguaButtonVariant.secondary,
                semanticLabel: 'Continue with Google sign-in',
                isLoading: _isGoogleSigningIn,
                leading: _buildGoogleIcon(),
                minHeight: 54,
                onPressed: isAnyLoading ? null : _handleGoogleSignIn,
              ),
              const SizedBox(height: 32),

              // Bottom Create account link
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, AppRoutes.signup),
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 14.5,
                        color: Color(0xFF5E5B74),
                      ),
                      children: [
                        TextSpan(text: "Don't have an account? "),
                        TextSpan(
                          text: 'Create account ↗',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4F22E5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
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

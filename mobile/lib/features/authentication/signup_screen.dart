import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/design_tokens/tokens.dart';
import '../../shared/models/user_role.dart';
import '../../core/widgets/lingua_text_input.dart';
import '../../core/widgets/lingua_button.dart';
import '../../core/widgets/lingua_brand_logo.dart';
import '../../app/providers/session_provider.dart';
import '../../app/router/app_router.dart';

/// UX-04 SIGNUP SCREEN
/// Inclusive, accessible account creation with plain-language consent,
/// safety boundary confirmation, and age consent notice.
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _consentAcknowledged = false;
  final bool _termsAcknowledged = true;
  String? _clientError;
  bool _isSubmitting = false;
  bool _hasSubmitted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(userSessionProvider.notifier).clearError();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _clientError = 'Please enter a valid email address.');
      return;
    }
    if (password.length < 8) {
      setState(() => _clientError = 'Password must be at least 8 characters long.');
      return;
    }
    if (password != confirmPassword) {
      setState(() => _clientError = 'Passwords do not match.');
      return;
    }
    if (!_consentAcknowledged) {
      setState(() => _clientError = 'Please acknowledge the non-diagnostic support notice to continue.');
      return;
    }

    setState(() {
      _clientError = null;
      _isSubmitting = true;
      _hasSubmitted = true;
    });

    final currentRole = ref.read(userSessionProvider).currentRole;

    try {
      await ref.read(userSessionProvider.notifier).signup(
            email: email,
            password: password,
            confirmPassword: confirmPassword,
            role: currentRole,
            displayName: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : null,
            termsAcknowledged: _termsAcknowledged,
            nonDiagnosticAcknowledged: _consentAcknowledged,
          );

      if (!mounted) return;

      final updatedSession = ref.read(userSessionProvider);
      if (!updatedSession.isOnboardingCompleted) {
        if (updatedSession.currentRole == UserRole.learner) {
          Navigator.pushReplacementNamed(context, AppRoutes.ageMode);
        } else {
          Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
        }
      } else {
        switch (updatedSession.currentRole) {
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
    } catch (e) {
      if (mounted) {
        final sessionErr = ref.read(userSessionProvider).errorMessage;
        setState(() {
          _clientError = sessionErr ?? e.toString();
        });
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(userSessionProvider);
    final errorToShow = _clientError ?? (_hasSubmitted ? session.errorMessage : null);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: LinguaTokens.ink900),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: LinguaTokens.space24,
            vertical: LinguaTokens.space8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Brand Identity
              const Center(
                child: LinguaBrandLogo(size: 40),
              ),
              const SizedBox(height: LinguaTokens.space16),

              // Headline & Subtitle
              const Text(
                'Create Your Account',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: LinguaTokens.ink900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Personalized, evidence-informed speech & reading practice.',
                style: TextStyle(fontSize: 14, color: LinguaTokens.ink700),
              ),
              const SizedBox(height: LinguaTokens.space20),

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
                          style: const TextStyle(color: LinguaTokens.danger600, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: LinguaTokens.space16),
              ],

              LinguaTextInput(
                controller: _nameController,
                label: 'Full Name / Preferred Name',
                prefixIcon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: LinguaTokens.space12),

              LinguaTextInput(
                controller: _emailController,
                label: 'Email Address',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: LinguaTokens.space12),

              LinguaTextInput(
                controller: _passwordController,
                label: 'Password (min. 8 characters)',
                prefixIcon: Icons.lock_outline_rounded,
                isPassword: true,
              ),
              const SizedBox(height: LinguaTokens.space12),

              LinguaTextInput(
                controller: _confirmPasswordController,
                label: 'Confirm Password',
                prefixIcon: Icons.lock_outline_rounded,
                isPassword: true,
              ),
              const SizedBox(height: LinguaTokens.space12),

              Material(
                color: _consentAcknowledged ? LinguaTokens.primary100.withValues(alpha: 0.3) : LinguaTokens.paper100,
                borderRadius: BorderRadius.circular(LinguaTokens.radiusSmall),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(LinguaTokens.radiusSmall),
                    border: Border.all(
                      color: _consentAcknowledged ? LinguaTokens.primary500.withValues(alpha: 0.4) : LinguaTokens.borderSubtle,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: CheckboxListTile(
                    value: _consentAcknowledged,
                    onChanged: (val) => setState(() {
                      _consentAcknowledged = val ?? false;
                      if (_consentAcknowledged && _clientError != null) {
                        _clientError = null;
                      }
                    }),
                    activeColor: LinguaTokens.primary600,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text(
                      'I understand that LINGUA AI provides educational and practice support, not clinical medical diagnosis.',
                      style: TextStyle(fontSize: 13, height: 1.35, color: LinguaTokens.ink900, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: LinguaTokens.space20),

              LinguaButton(
                label: 'Create My Account',
                isLoading: _isSubmitting,
                onPressed: _consentAcknowledged && !_isSubmitting ? _handleSignup : null,
              ),
              const SizedBox(height: LinguaTokens.space16),

              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.pushNamed(context, AppRoutes.login),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: LinguaTokens.space8, horizontal: LinguaTokens.space12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Already have an account? ', style: TextStyle(color: LinguaTokens.ink700, fontSize: 14)),
                      const Text(
                        'Sign In',
                        style: TextStyle(fontWeight: FontWeight.w700, color: LinguaTokens.primary600, fontSize: 14),
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

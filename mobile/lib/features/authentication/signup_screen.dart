import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/user_role.dart';
import '../../shared/models/age_profile.dart';
import '../../app/providers/session_provider.dart';
import '../../app/router/app_router.dart';

/// LINGUA AI - Premium Create Account / Sign Up Screen
///
/// Faithfully reproduces the visual hierarchy, typography, colors, and layout
/// from the reference design:
/// 1. Top App Bar: Circular back button, official LinguaAI branding, question-mark help icon, thin divider.
/// 2. Header: "Create your account" + "Start your personalized language learning journey."
/// 3. Full name field with "Required" label and profile icon.
/// 4. Email address field with "Required" label and email icon.
/// 5. Password field with obscure toggle, 8+ characters rule, and 3-bar password strength indicator.
/// 7. Role selection: 2x2 grid (Adult, Parent, Teacher, Specialist) with active checkmark badges.
/// 8. Parent conditional section: Smoothly reveals "Child age group" (5–11 years / 11–18 years).
/// 9. Consent checkbox: "I agree to the Terms & Privacy Policy".
/// 10. Tactile 3D "Create Account →" primary button with loading state.
/// 11. "OR" divider & "Continue with Google" button with official Google "G" logo.
/// 12. "Already have an account? Sign in" bottom navigation action.
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _consentAcknowledged = true; // Pre-checked per reference design
  bool _isSubmitting = false;
  bool _isGoogleSubmitting = false;
  String? _clientError;

  // Selected Role (Default: Adult, matching reference)
  String _selectedRole = 'Adult';
  String _selectedChildAge = '5–11';

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
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  // --- Password Strength Calculation ---
  int get _passwordStrengthScore {
    final password = _passwordController.text;
    if (password.isEmpty) return 0;
    if (password.length < 8) return 1; // Weak

    bool hasLetters = password.contains(RegExp(r'[a-zA-Z]'));
    bool hasNumbers = password.contains(RegExp(r'[0-9]'));
    bool hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    if (hasLetters && hasNumbers && hasSpecial) return 3; // Strong
    if (hasLetters && hasNumbers) return 2; // Medium
    return 1; // Weak
  }

  String get _passwordStrengthLabel {
    final score = _passwordStrengthScore;
    if (score == 3) return 'Strong';
    if (score == 2) return 'Medium';
    if (score == 1) return 'Weak';
    return '';
  }

  Color get _passwordStrengthColor {
    final score = _passwordStrengthScore;
    if (score == 3) return const Color(0xFF00A86B); // Strong green
    if (score == 2) return const Color(0xFFFB8C00); // Medium orange
    if (score == 1) return const Color(0xFFE53935); // Weak red
    return const Color(0xFFE0DBF2);
  }

  // --- Form Submission / Signup ---
  Future<void> _handleSignup() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty) {
      setState(() => _clientError = 'Please enter your full name.');
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _clientError = 'Please enter a valid email address.');
      return;
    }
    if (password.length < 8) {
      setState(() => _clientError = 'Password must be at least 8 characters long.');
      return;
    }
    if (!_consentAcknowledged) {
      setState(() => _clientError = 'Please agree to the Terms & Privacy Policy.');
      return;
    }

    setState(() {
      _clientError = null;
      _isSubmitting = true;
    });

    // Map UI role to domain UserRole
    final role = switch (_selectedRole) {
      'Parent' => UserRole.parent,
      'Teacher' => UserRole.teacher,
      'Specialist' => UserRole.specialist,
      _ => UserRole.learner, // Adult / Learner
    };

    // Map age band
    final ageBand = _selectedRole == 'Parent'
        ? (_selectedChildAge == '5–11' ? AgeBand.child : AgeBand.teen)
        : AgeBand.adult;

    try {
      await ref.read(userSessionProvider.notifier).signup(
            email: email,
            password: password,
            confirmPassword: password,
            role: role,
            ageBand: ageBand,
            displayName: name,
            termsAcknowledged: true,
            nonDiagnosticAcknowledged: true,
          );

      if (!mounted) return;

      final updatedSession = ref.read(userSessionProvider);
      if (!updatedSession.isOnboardingCompleted) {
        if (updatedSession.currentRole == UserRole.learner) {
          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.ageMode, (route) => false);
        } else {
          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.onboarding, (route) => false);
        }
      } else {
        final destination = switch (updatedSession.currentRole) {
          UserRole.parent => AppRoutes.parentDashboard,
          UserRole.teacher => AppRoutes.teacherDashboard,
          UserRole.specialist => AppRoutes.specialistDashboard,
          UserRole.learner => AppRoutes.home,
        };
        Navigator.pushNamedAndRemoveUntil(context, destination, (route) => false);
      }
    } catch (e) {
      if (mounted) {
        final sessionErr = ref.read(userSessionProvider).errorMessage;
        setState(() {
          _clientError = sessionErr ?? 'Unable to create account. Please check your credentials.';
        });
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _clientError = null;
      _isGoogleSubmitting = true;
    });

    try {
      await ref.read(userSessionProvider.notifier).signInWithGoogle();

      if (!mounted) return;

      final updatedSession = ref.read(userSessionProvider);
      final destination = switch (updatedSession.currentRole) {
        UserRole.parent => AppRoutes.parentDashboard,
        UserRole.teacher => AppRoutes.teacherDashboard,
        UserRole.specialist => AppRoutes.specialistDashboard,
        UserRole.learner => AppRoutes.home,
      };
      Navigator.pushReplacementNamed(context, destination);
    } catch (e) {
      if (mounted) {
        final sessionErr = ref.read(userSessionProvider).errorMessage;
        setState(() {
          _clientError = sessionErr ?? 'Google sign-in could not be completed.';
        });
      }
    } finally {
      if (mounted) setState(() => _isGoogleSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(userSessionProvider);
    final errorToShow = _clientError ?? session.errorMessage;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9FD),
      body: SafeArea(
        child: Column(
          children: [
            // 1. TOP APP BAR
            _buildTopAppBar(context),

            // Thin divider below header
            const Divider(height: 1.0, thickness: 1.0, color: Color(0xFFF0ECF8)),

            // 2. SCROLLABLE FORM CONTENT
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 36.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // TITLE & SUBTITLE
                      const Text(
                        'Create your account',
                        style: TextStyle(
                          fontSize: 27.0,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1B1738),
                          letterSpacing: -0.4,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6.0),
                      const Text(
                        'Start your personalized language learning journey.',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF4C4964),
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 22.0),

                      // ERROR BANNER (if present)
                      if (errorToShow != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDECEE),
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(color: const Color(0xFFF5B7BD)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded,
                                  color: Color(0xFFD32F2F), size: 18.0),
                              const SizedBox(width: 10.0),
                              Expanded(
                                child: Text(
                                  errorToShow,
                                  style: const TextStyle(
                                    color: Color(0xFFD32F2F),
                                    fontSize: 13.0,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16.0),
                      ],

                      // 3. FULL NAME FIELD
                      _buildFieldLabel(
                        label: 'Full name',
                        trailing: const Text(
                          'Required',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF7E7B95),
                          ),
                        ),
                      ),
                      const SizedBox(height: 7.0),
                      _buildInputField(
                        controller: _nameController,
                        focusNode: _nameFocusNode,
                        placeholder: 'Enter your full name',
                        prefixIcon: Icons.person_outline_rounded,
                        textCapitalization: TextCapitalization.words,
                      ),

                      const SizedBox(height: 16.0),

                      // 4. EMAIL FIELD
                      _buildFieldLabel(
                        label: 'Email address',
                        trailing: const Text(
                          'Required',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF7E7B95),
                          ),
                        ),
                      ),
                      const SizedBox(height: 7.0),
                      _buildInputField(
                        controller: _emailController,
                        focusNode: _emailFocusNode,
                        placeholder: 'you@example.com',
                        prefixIcon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                      ),

                      const SizedBox(height: 16.0),

                      // 6. PASSWORD FIELD
                      _buildFieldLabel(label: 'Password'),
                      const SizedBox(height: 7.0),
                      _buildInputField(
                        controller: _passwordController,
                        focusNode: _passwordFocusNode,
                        placeholder: 'Create a password',
                        prefixIcon: Icons.lock_outline_rounded,
                        obscureText: _obscurePassword,
                        onChanged: (_) => setState(() {}),
                        suffixWidget: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: const Color(0xFF7E7B95),
                            size: 20.0,
                          ),
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
                      ),

                      const SizedBox(height: 8.0),

                      // Password Requirement & Strength Bars
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '8+ characters',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF7E7B95),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Row(
                            children: [
                              ...List.generate(3, (idx) {
                                final active = _passwordStrengthScore > idx;
                                return Container(
                                  margin: const EdgeInsets.only(left: 4.0),
                                  width: 22.0,
                                  height: 4.0,
                                  decoration: BoxDecoration(
                                    color: active
                                        ? _passwordStrengthColor
                                        : const Color(0xFFE4DCF9),
                                    borderRadius: BorderRadius.circular(2.0),
                                  ),
                                );
                              }),
                              if (_passwordStrengthLabel.isNotEmpty) ...[
                                const SizedBox(width: 8.0),
                                Text(
                                  _passwordStrengthLabel,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: _passwordStrengthColor,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 22.0),

                      // 7. ROLE SELECTION (2 x 2 GRID)
                      const Text(
                        'How will you use LINGUA AI?',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1B1738),
                        ),
                      ),
                      const SizedBox(height: 12.0),

                      // Row 1: Adult / Parent
                      Row(
                        children: [
                          Expanded(
                            child: _buildRoleCard(
                              name: 'Adult',
                              icon: Icons.person_rounded,
                              isSelected: _selectedRole == 'Adult',
                              onTap: () => setState(() => _selectedRole = 'Adult'),
                            ),
                          ),
                          const SizedBox(width: 12.0),
                          Expanded(
                            child: _buildRoleCard(
                              name: 'Parent',
                              icon: Icons.people_alt_rounded,
                              isSelected: _selectedRole == 'Parent',
                              onTap: () => setState(() => _selectedRole = 'Parent'),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12.0),

                      // Row 2: Teacher / Specialist
                      Row(
                        children: [
                          Expanded(
                            child: _buildRoleCard(
                              name: 'Teacher',
                              icon: Icons.school_rounded,
                              isSelected: _selectedRole == 'Teacher',
                              onTap: () => setState(() => _selectedRole = 'Teacher'),
                            ),
                          ),
                          const SizedBox(width: 12.0),
                          Expanded(
                            child: _buildRoleCard(
                              name: 'Specialist',
                              icon: Icons.psychology_outlined,
                              isSelected: _selectedRole == 'Specialist',
                              onTap: () => setState(() => _selectedRole = 'Specialist'),
                            ),
                          ),
                        ],
                      ),

                      // 8. CONDITIONAL PARENT AGE-GROUP SECTION
                      AnimatedSize(
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeInOutCubic,
                        child: _selectedRole == 'Parent'
                            ? Padding(
                                padding: const EdgeInsets.only(top: 14.0),
                                child: Container(
                                  padding: const EdgeInsets.all(14.0),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16.0),
                                    border: Border.all(color: const Color(0xFFE4DCF9)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Child age group',
                                        style: TextStyle(
                                          fontSize: 14.0,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1B1738),
                                        ),
                                      ),
                                      const SizedBox(height: 10.0),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildAgeGroupChip(
                                              label: '5–11 years',
                                              isSelected: _selectedChildAge == '5–11',
                                              onTap: () => setState(() => _selectedChildAge = '5–11'),
                                            ),
                                          ),
                                          const SizedBox(width: 12.0),
                                          Expanded(
                                            child: _buildAgeGroupChip(
                                              label: '11–18 years',
                                              isSelected: _selectedChildAge == '11–18',
                                              onTap: () => setState(() => _selectedChildAge = '11–18'),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),

                      const SizedBox(height: 18.0),

                      // 9. CONSENT CHECKBOX
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 24.0,
                            height: 24.0,
                            child: Checkbox(
                              value: _consentAcknowledged,
                              activeColor: const Color(0xFF4F22E5),
                              checkColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5.0),
                              ),
                              side: const BorderSide(color: Color(0xFF4F22E5), width: 1.6),
                              onChanged: (val) {
                                setState(() {
                                  _consentAcknowledged = val ?? false;
                                  if (_consentAcknowledged && _clientError != null) {
                                    _clientError = null;
                                  }
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 10.0),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  color: Color(0xFF1B1738),
                                  fontWeight: FontWeight.w500,
                                ),
                                children: [
                                  const TextSpan(text: 'I agree to the '),
                                  TextSpan(
                                    text: 'Terms & Privacy Policy',
                                    style: const TextStyle(
                                      color: Color(0xFF4F22E5),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 22.0),

                      // 10. CREATE ACCOUNT CTA (3D Button)
                      _buildCreateAccountButton(),

                      const SizedBox(height: 18.0),

                      // 11. OR SEPARATOR
                      const Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: Color(0xFFE8E4F4),
                              thickness: 1.0,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 14.0),
                            child: Text(
                              'OR',
                              style: TextStyle(
                                fontSize: 13.0,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF7E7B95),
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Color(0xFFE8E4F4),
                              thickness: 1.0,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18.0),

                      // 12. CONTINUE WITH GOOGLE BUTTON
                      _buildGoogleButton(),

                      const SizedBox(height: 22.0),

                      // 13. ALREADY HAVE AN ACCOUNT? SIGN IN
                      Center(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => Navigator.pushNamed(context, AppRoutes.login),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: RichText(
                              text: const TextSpan(
                                style: TextStyle(
                                  fontSize: 14.5,
                                  color: Color(0xFF4C4964),
                                  fontWeight: FontWeight.w500,
                                ),
                                children: [
                                  TextSpan(text: 'Already have an account? '),
                                  TextSpan(
                                    text: 'Sign in',
                                    style: TextStyle(
                                      color: Color(0xFF4F22E5),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14.0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- SUB-COMPONENTS ---

  Widget _buildTopAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Circular Back Button
          Semantics(
            label: 'Back',
            button: true,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.maybePop(context),
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
                        color: const Color(0xFF38148E).withValues(alpha: 0.05),
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
          ),

          // Official LinguaAI Brand Logo
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.asset(
                  'assets/branding/lingua_app_icon.png',
                  width: 28.0,
                  height: 28.0,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 28.0,
                    height: 28.0,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F22E5),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: const Icon(Icons.record_voice_over, color: Colors.white, size: 16.0),
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1B1738),
                    letterSpacing: -0.3,
                  ),
                  children: [
                    TextSpan(text: 'Lingua'),
                    TextSpan(
                      text: 'AI',
                      style: TextStyle(color: Color(0xFF5324E7)),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Help / Question Icon
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: Color(0xFF383552), size: 24.0),
            tooltip: 'Help & Information',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Account Creation Support'),
                  content: const Text(
                    'LINGUA AI provides personalized speech and literacy support.\n\n'
                    'Your account securely stores your learning progress, accessibility configurations, '
                    'and collaborator connections with complete FERPA & COPPA compliance.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel({required String label, Widget? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1B1738),
          ),
        ),
        ?trailing,
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String placeholder,
    required IconData prefixIcon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    Widget? suffixWidget,
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: focusNode.hasFocus ? const Color(0xFF4F22E5) : const Color(0xFFECE7F7),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF38148E).withValues(alpha: 0.04),
            blurRadius: 10.0,
            offset: const Offset(0, 3.0),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        onChanged: onChanged,
        style: const TextStyle(
          fontSize: 15.0,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1B1738),
        ),
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w400,
            color: Color(0xFFA19EAF),
          ),
          prefixIcon: Icon(prefixIcon, color: const Color(0xFF7E7B95), size: 21.0),
          suffixIcon: suffixWidget != null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [suffixWidget],
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 15.0),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required String name,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Semantics(
      label: '$name role',
      selected: isSelected,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.0),
          child: Container(
            height: 64.0,
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFF7F4FD) : Colors.white,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: isSelected ? const Color(0xFF4F22E5) : const Color(0xFFECE7F7),
                width: isSelected ? 1.8 : 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF38148E).withValues(alpha: 0.05),
                  blurRadius: 8.0,
                  offset: const Offset(0, 3.0),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon Box
                Container(
                  width: 34.0,
                  height: 34.0,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF4F22E5) : const Color(0xFFF4F0FA),
                    borderRadius: BorderRadius.circular(9.0),
                  ),
                  child: Icon(
                    icon,
                    size: 19.0,
                    color: isSelected ? Colors.white : const Color(0xFF5324E7),
                  ),
                ),
                const SizedBox(width: 8.0),
                // Role Label
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      name,
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 15.0,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1B1738),
                      ),
                    ),
                  ),
                ),
                // Checkmark Pill Badge when selected
                if (isSelected) ...[
                  const SizedBox(width: 4.0),
                  Container(
                    width: 18.0,
                    height: 18.0,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4F22E5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 12.0,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAgeGroupChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF7F4FD) : Colors.white,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: isSelected ? const Color(0xFF4F22E5) : const Color(0xFFECE7F7),
              width: isSelected ? 1.6 : 1.2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSelected) ...[
                const Icon(Icons.check_circle_rounded, color: Color(0xFF4F22E5), size: 16.0),
                const SizedBox(width: 6.0),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: const Color(0xFF1B1738),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreateAccountButton() {
    const double buttonHeight = 56.0;
    const double borderRadiusValue = 28.0;

    return Semantics(
      label: 'Create Account',
      button: true,
      child: SizedBox(
        width: double.infinity,
        height: buttonHeight + 4.0,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // Darker Indigo 3D Bottom Ledge
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
                  onTap: _consentAcknowledged && !_isSubmitting ? _handleSignup : null,
                  borderRadius: BorderRadius.circular(borderRadiusValue),
                  child: Container(
                    height: buttonHeight,
                    decoration: BoxDecoration(
                      color: _consentAcknowledged
                          ? const Color(0xFF4F22E5)
                          : const Color(0xFF9881E6),
                      borderRadius: BorderRadius.circular(borderRadiusValue),
                    ),
                    child: Center(
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 22.0,
                              height: 22.0,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Create Account',
                                  style: TextStyle(
                                    fontSize: 17.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                SizedBox(width: 8.0),
                                Icon(
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

  Widget _buildGoogleButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isGoogleSubmitting ? null : _handleGoogleSignIn,
        borderRadius: BorderRadius.circular(28.0),
        child: Container(
          width: double.infinity,
          height: 56.0,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28.0),
            border: Border.all(
              color: const Color(0xFFECE7F7),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF38148E).withValues(alpha: 0.05),
                blurRadius: 10.0,
                offset: const Offset(0, 3.0),
              ),
            ],
          ),
          child: Center(
            child: _isGoogleSubmitting
                ? const SizedBox(
                    width: 22.0,
                    height: 22.0,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F22E5)),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/branding/google_g_logo.png',
                        width: 22.0,
                        height: 22.0,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.g_mobiledata_rounded,
                          size: 26.0,
                          color: Color(0xFF4285F4),
                        ),
                      ),
                      const SizedBox(width: 10.0),
                      const Text(
                        'Continue with Google',
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1B1738),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

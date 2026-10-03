import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/design_tokens/tokens.dart';
import '../../shared/models/user_role.dart';
import '../../core/widgets/non_diagnostic_banner.dart';
import '../../core/widgets/lingua_selection_card.dart';
import '../../core/widgets/lingua_button.dart';
import '../../app/providers/session_provider.dart';
import '../../app/router/app_router.dart';

/// UX-05 ROLE SELECTION SCREEN
/// Configures account role and establishes strict permission/privacy boundaries.
class RoleSelectionScreen extends ConsumerWidget {
  const RoleSelectionScreen({super.key});

  IconData _iconForRole(UserRole role) {
    switch (role) {
      case UserRole.learner:
        return Icons.school_rounded;
      case UserRole.parent:
        return Icons.family_restroom_rounded;
      case UserRole.teacher:
        return Icons.co_present_rounded;
      case UserRole.specialist:
        return Icons.psychology_rounded;
    }
  }

  Color _colorForRole(UserRole role) {
    switch (role) {
      case UserRole.learner:
        return LinguaTokens.primary600;
      case UserRole.parent:
        return LinguaTokens.accent600;
      case UserRole.teacher:
        return LinguaTokens.dyslexiaTrack;
      case UserRole.specialist:
        return LinguaTokens.primary700;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(userSessionProvider);
    final sessionNotifier = ref.read(userSessionProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: LinguaTokens.ink900),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Choose Your Role',
          style: TextStyle(
            color: LinguaTokens.ink900,
            fontWeight: FontWeight.w700,
          ),
        ),
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
              const NonDiagnosticBanner(compact: true),
              const SizedBox(height: LinguaTokens.space16),

              const Text(
                'How will you use LINGUA AI?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: LinguaTokens.ink900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Select your primary role to customize your workspace, tools, and privacy settings.',
                style: TextStyle(fontSize: 14, height: 1.4, color: LinguaTokens.ink700),
              ),
              const SizedBox(height: LinguaTokens.space20),

              ...UserRole.values.map((role) {
                final roleColor = _colorForRole(role);
                return LinguaSelectionCard(
                  title: role.displayName,
                  subtitle: role.description,
                  icon: _iconForRole(role),
                  activeColor: roleColor,
                  activeBackgroundColor: roleColor.withValues(alpha: 0.08),
                  isSelected: session.currentRole == role,
                  onSelected: () => sessionNotifier.setRole(role),
                );
              }),

              const SizedBox(height: LinguaTokens.space20),

              LinguaButton(
                label: 'Continue',
                onPressed: () {
                  if (session.currentRole == UserRole.learner) {
                    Navigator.pushNamed(context, AppRoutes.ageMode);
                  } else {
                    Navigator.pushNamed(context, AppRoutes.signup);
                  }
                },
              ),
              const SizedBox(height: LinguaTokens.space16),
            ],
          ),
        ),
      ),
    );
  }
}

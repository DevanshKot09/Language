import 'package:flutter/material.dart';
import '../../shared/design_tokens/tokens.dart';
import '../../core/widgets/lingua_button.dart';
import '../../core/widgets/lingua_brand_logo.dart';
import '../../app/router/app_router.dart';

/// UX-01 WELCOME / GET STARTED SCREEN
/// Premium, high-converting product launch experience.
/// Implements Mobbin/Refero minimalist hierarchy:
/// One hero visual, one clear headline, concise value proposition, dual-track tags, and focused CTAs.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: LinguaTokens.space24,
            vertical: LinguaTokens.space16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Navigation / Brand Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const LinguaBrandLogo(size: 36),
                  IconButton(
                    icon: const Icon(Icons.accessibility_new_rounded),
                    color: LinguaTokens.ink700,
                    tooltip: 'Accessibility settings',
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.accessibility),
                  ),
                ],
              ),
              const SizedBox(height: LinguaTokens.space16),

              // Hero Visual Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: LinguaTokens.space16,
                  vertical: LinguaTokens.space20,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFF4F4FD),
                      Color(0xFFE9E9FF),
                      Color(0xFFEBF7F2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(LinguaTokens.radiusHero),
                  border: Border.all(color: LinguaTokens.borderSubtle),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: LinguaTokens.primary900.withValues(alpha: 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: LinguaTokens.primary600,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: LinguaTokens.space12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _buildTrackPill(
                          icon: Icons.record_voice_over_rounded,
                          label: 'Spoken Track (DLD)',
                          color: LinguaTokens.dldTrack,
                          bgColor: Colors.white,
                        ),
                        _buildTrackPill(
                          icon: Icons.menu_book_rounded,
                          label: 'Literacy (Dyslexia)',
                          color: LinguaTokens.dyslexiaTrack,
                          bgColor: Colors.white,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: LinguaTokens.space24),

              // Value Proposition
              const Text(
                'Empowering every voice and reader.',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  letterSpacing: -0.5,
                  color: LinguaTokens.ink900,
                ),
              ),
              const SizedBox(height: LinguaTokens.space8),
              const Text(
                'Personalized speech practice and reading science tools designed for learners, supported by parents, teachers, and specialists.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: LinguaTokens.ink700,
                ),
              ),
              const SizedBox(height: LinguaTokens.space24),

              // Primary Call to Action
              LinguaButton(
                label: 'Get Started',
                onPressed: () => Navigator.pushNamed(context, AppRoutes.roles),
              ),
              const SizedBox(height: LinguaTokens.space12),

              // Secondary Sign-In Button
              LinguaButton(
                label: 'I already have an account • Sign In',
                variant: LinguaButtonVariant.secondary,
                onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
              ),
              const SizedBox(height: LinguaTokens.space16),

              // Micro Trust / Privacy Line
              Center(
                child: Text(
                  'Privacy by design • Non-diagnostic • COPPA & FERPA aligned',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: LinguaTokens.inkMuted,
                  ),
                ),
              ),
              const SizedBox(height: LinguaTokens.space8),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildTrackPill({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(LinguaTokens.radiusPill),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

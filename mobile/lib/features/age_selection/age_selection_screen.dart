import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/design_tokens/tokens.dart';
import '../../shared/models/age_profile.dart';
import '../../core/widgets/non_diagnostic_banner.dart';
import '../../core/widgets/lingua_selection_card.dart';
import '../../core/widgets/lingua_button.dart';
import '../../app/providers/age_profile_provider.dart';
import '../../app/router/app_router.dart';

/// UX-06 AGE SELECTION SCREEN
/// Sets age-adaptive presentation (Child, Teen, Adult) via Riverpod,
/// seamlessly adjusting typography, controls, and visual density.
class AgeSelectionScreen extends ConsumerWidget {
  const AgeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentProfile = ref.watch(ageProfileProvider);
    final ageNotifier = ref.read(ageProfileProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Age-Adaptive Setup'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(LinguaTokens.space20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const NonDiagnosticBanner(compact: true),
              const SizedBox(height: LinguaTokens.space16),

              const Text(
                'Select Learner Age Band',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: LinguaTokens.ink900,
                ),
              ),
              const SizedBox(height: LinguaTokens.space8),
              const Text(
                'LINGUA AI automatically configures text size, vocabulary difficulty, visuals, and reward styles to match developmental stages.',
                style: TextStyle(fontSize: 14, color: LinguaTokens.ink700),
              ),
              const SizedBox(height: LinguaTokens.space20),

              // Child Mode Card
              LinguaSelectionCard(
                title: 'Child (Ages 5–11)',
                badgeText: 'Visual & Scaffolding Focus',
                subtitle: 'Friendly, warm presentation with larger controls, gentle star rewards, audio instructions, and low visual clutter.',
                icon: Icons.child_care,
                isSelected: currentProfile.ageBand == AgeBand.child,
                onSelected: () => ageNotifier.setAgeBand(AgeBand.child),
              ),

              // Teen Mode Card
              LinguaSelectionCard(
                title: 'Teen (Ages 12–17)',
                badgeText: 'Autonomy & Skill Milestones',
                subtitle: 'Modern, motivating, non-childish design. Academic & real-world vocabulary, skill milestone badges, and optional challenges.',
                icon: Icons.school_outlined,
                isSelected: currentProfile.ageBand == AgeBand.teen,
                onSelected: () => ageNotifier.setAgeBand(AgeBand.teen),
              ),

              // Adult Mode Card
              LinguaSelectionCard(
                title: 'Adult (Ages 18+)',
                badgeText: 'Productive & Goal-Driven',
                subtitle: 'Professional, clean, practical interface. College & workplace reading/writing tasks, competence markers, and flexible scheduling.',
                icon: Icons.work_outline,
                isSelected: currentProfile.ageBand == AgeBand.adult,
                onSelected: () => ageNotifier.setAgeBand(AgeBand.adult),
              ),

              const SizedBox(height: LinguaTokens.space16),

              Container(
                padding: const EdgeInsets.all(LinguaTokens.space12),
                decoration: BoxDecoration(
                  color: LinguaTokens.paper100,
                  borderRadius: BorderRadius.circular(LinguaTokens.radiusSmall),
                ),
                child: const Text(
                  'Note: You can adjust this configuration at any time from Settings without losing your progress history.',
                  style: TextStyle(fontSize: 12, color: LinguaTokens.ink700),
                ),
              ),
              const SizedBox(height: LinguaTokens.space24),

              LinguaButton(
                label: 'Continue to Focus Setup',
                minHeight: currentProfile.minTouchTarget,
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.onboarding);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

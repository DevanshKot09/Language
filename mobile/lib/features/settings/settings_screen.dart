import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/design_tokens/tokens.dart';
import '../../core/widgets/non_diagnostic_banner.dart';
import '../../core/widgets/lingua_button.dart';
import '../../app/providers/age_profile_provider.dart';
import '../../app/providers/session_provider.dart';
import '../../app/router/app_router.dart';

/// UX-31 SETTINGS SCREEN
/// Application preferences, profile management, age-band switching,
/// voice privacy data center, and non-diagnostic research reference links.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ageProfile = ref.watch(ageProfileProvider);
    final session = ref.watch(userSessionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Preferences'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(LinguaTokens.space20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const NonDiagnosticBanner(compact: true),
              const SizedBox(height: LinguaTokens.space16),

              // Section 1: Active Profile
              _buildSectionTitle('Profile & Adaptive Configuration'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: LinguaTokens.primary100,
                        child: Icon(Icons.person, color: LinguaTokens.primary600),
                      ),
                      title: Text(session.learnerName),
                      subtitle: Text('Active Mode: ${ageProfile.displayName} (${ageProfile.ageRangeLabel})'),
                      trailing: TextButton(
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.ageMode),
                        child: const Text('Switch Mode'),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.family_restroom, color: LinguaTokens.ink700),
                      title: const Text('Guardian / Family Sync'),
                      subtitle: const Text('Connected: Sarah Mercer (Parent)'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: LinguaTokens.space16),

              // Section: Role Workspaces (Learner, Parent, Educator, Specialist)
              _buildSectionTitle('Role Workspaces & Dashboards'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.school, color: LinguaTokens.primary600),
                      title: const Text('Learner Workspace'),
                      subtitle: const Text('Daily lessons, practice hub, DLD & Dyslexia tracks'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.pushNamed(context, AppRoutes.home),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.family_restroom, color: LinguaTokens.success600),
                      title: const Text('Parent Workspace'),
                      subtitle: const Text('Connected children, home practice, and progress'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.pushNamed(context, AppRoutes.parentDashboard),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.menu_book, color: LinguaTokens.dldTrack),
                      title: const Text('Educator / Teacher Workspace'),
                      subtitle: const Text('Classroom roster, curriculum assignments, and trends'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.pushNamed(context, AppRoutes.teacherDashboard),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.health_and_safety, color: LinguaTokens.dyslexiaTrack),
                      title: const Text('Specialist Caseload'),
                      subtitle: const Text('Clinical caseload, goals, and AI recommendation review'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.pushNamed(context, AppRoutes.specialistDashboard),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: LinguaTokens.space16),

              // Section 2: Accessibility & Privacy
              _buildSectionTitle('Accessibility & Privacy Controls'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.accessibility_new, color: LinguaTokens.primary600),
                      title: const Text('Accessibility Center'),
                      subtitle: const Text('Text scale, contrast, fonts, and speech settings'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.pushNamed(context, AppRoutes.accessibility),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.mic_none, color: LinguaTokens.primary600),
                      title: const Text('Voice & Audio Privacy'),
                      subtitle: const Text('Hardware status, retention controls, and data protection'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.pushNamed(context, AppRoutes.voicePrivacy),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: LinguaTokens.space16),

              // Section 3: Evidence & Safety
              _buildSectionTitle('Evidence & Clinical Safety'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.science_outlined, color: LinguaTokens.success600),
                      title: const Text('Clinical Evidence & Research Base'),
                      subtitle: const Text('Read about CATALISE DLD and IDA Dyslexia frameworks'),
                      trailing: const Icon(Icons.open_in_new, size: 18),
                      onTap: () {},
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.health_and_safety_outlined, color: LinguaTokens.warning600),
                      title: const Text('Safety & Medical Boundary Policy'),
                      subtitle: const Text('Why LINGUA AI is educational support, not diagnosis'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: LinguaTokens.space24),

              LinguaButton(
                label: 'Sign Out',
                variant: LinguaButtonVariant.danger,
                icon: Icons.logout,
                onPressed: () async {
                  await ref.read(userSessionProvider.notifier).logout();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.welcome, (route) => false);
                  }
                },
              ),
              const SizedBox(height: LinguaTokens.space24),

              Center(
                child: Text(
                  'LINGUA AI v1.0.0 (Phase 3 Foundation)\nEvidence-Informed Language & Literacy Platform',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: LinguaTokens.inkMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: LinguaTokens.ink700,
        ),
      ),
    );
  }
}

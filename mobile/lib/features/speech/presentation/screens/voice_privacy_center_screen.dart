import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_tokens/tokens.dart';
import '../../../../core/widgets/non_diagnostic_banner.dart';
import '../../../../app/providers/audio_provider.dart';
import '../../../../core/audio/audio_capabilities.dart';
import '../../../../core/audio/i_audio_permission_service.dart';

/// Comprehensive Voice & Audio Privacy Center.
/// Displays platform audio capabilities, permissions status, retention policies,
/// and transparent disclosures on transient on-device vs platform speech processing.
class VoicePrivacyCenterScreen extends ConsumerWidget {
  const VoicePrivacyCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capabilitiesAsync = ref.watch(audioCapabilitiesProvider);
    final permService = ref.watch(audioPermissionServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice & Audio Privacy'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(LinguaTokens.space20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const NonDiagnosticBanner(compact: true),
              const SizedBox(height: LinguaTokens.space16),

              // Title header
              Text(
                'Audio Privacy & Control Center',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: LinguaTokens.ink900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Lingua AI treats your speech as a transient interaction tool, not medical or clinical data.',
                style: TextStyle(fontSize: 14, color: LinguaTokens.ink700, height: 1.4),
              ),
              const SizedBox(height: LinguaTokens.space20),

              // Section 1: Microphone & Audio Hardware Status
              _buildSectionTitle('Microphone & Hardware Status'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(LinguaTokens.space16),
                  child: FutureBuilder<MicrophonePermissionStatus>(
                    future: permService.checkPermission(),
                    builder: (context, snapshot) {
                      final status = snapshot.data ?? MicrophonePermissionStatus.notDetermined;
                      final isGranted = status == MicrophonePermissionStatus.granted;
                      final isDenied = status == MicrophonePermissionStatus.denied ||
                          status == MicrophonePermissionStatus.permanentlyDenied;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.mic, color: LinguaTokens.primary600, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Microphone Permission',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isGranted ? LinguaTokens.successLight : (isDenied ? LinguaTokens.warningLight : LinguaTokens.paper100),
                                  borderRadius: BorderRadius.circular(LinguaTokens.radiusPill),
                                ),
                                child: Text(
                                  isGranted ? 'Allowed' : (isDenied ? 'Not Allowed' : 'Not Requested Yet'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isGranted ? LinguaTokens.success600 : (isDenied ? LinguaTokens.warning600 : LinguaTokens.ink700),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Used only when you explicitly tap Speak in a structured activity. Lingua AI never records in the background.',
                            style: TextStyle(fontSize: 13, color: LinguaTokens.ink700, height: 1.4),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: LinguaTokens.space16),

              // Section 2: Audio Engine & Capabilities
              _buildSectionTitle('Speech Engine Architecture'),
              Card(
                child: capabilitiesAsync.when(
                  data: (capabilities) {
                    final modeLabel = capabilities.processingMode == SpeechProcessingMode.onDevice
                        ? 'On-Device (Local)'
                        : (capabilities.processingMode == SpeechProcessingMode.platformManaged
                            ? 'Platform-Managed'
                            : 'Unavailable on this device');

                    return Padding(
                      padding: const EdgeInsets.all(LinguaTokens.space16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow(
                            'Text-to-Speech (TTS):',
                            capabilities.ttsSupported ? 'Supported (Offline & System Voice)' : 'Not Supported',
                          ),
                          const Divider(height: 20),
                          _buildDetailRow(
                            'Speech-to-Text (STT):',
                            capabilities.sttSupported ? 'Supported' : 'Not Supported',
                          ),
                          const Divider(height: 20),
                          _buildDetailRow('Processing Mode:', modeLabel),
                          const Divider(height: 20),
                          _buildDetailRow('Active Language:', capabilities.activeLocale),
                          const Divider(height: 20),
                          _buildDetailRow(
                            'Word Highlight Sync:',
                            capabilities.supportsWordHighlighting ? 'Available' : 'Fallback (Full Sentence)',
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (err, _) => Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Could not read audio capabilities: $err'),
                  ),
                ),
              ),
              const SizedBox(height: LinguaTokens.space16),

              // Section 3: Data Retention & Child Voice Protection
              _buildSectionTitle('Audio Retention & Child Protection Policies'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(LinguaTokens.space16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      _PolicyItem(
                        icon: Icons.delete_outline,
                        title: 'Zero Permanent Raw Audio Storage',
                        description:
                            'Lingua AI does not store raw audio recordings in PostgreSQL or cloud databases. Temporary audio buffers are deleted immediately after transcription.',
                      ),
                      SizedBox(height: 14),
                      _PolicyItem(
                        icon: Icons.child_care,
                        title: 'Child Data Minimization (COPPA/GDPR-K Compliant)',
                        description:
                            'In Child mode, voice recording requires explicit guardian/user tap. Child voice is never sent to external AI model providers or third parties.',
                      ),
                      SizedBox(height: 14),
                      _PolicyItem(
                        icon: Icons.fact_check_outlined,
                        title: 'Learner-Controlled Transcripts',
                        description:
                            'When speech is recognized, you can review, edit, or reject the transcript before saving it as an activity answer.',
                      ),
                      SizedBox(height: 14),
                      _PolicyItem(
                        icon: Icons.keyboard_outlined,
                        title: 'Universal Type-In Fallback',
                        description:
                            'Every speech practice task has a "Type your answer instead" button. Voice input is never mandatory to complete an activity.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: LinguaTokens.space16),

              // Section 4: AI Assistance & Data Privacy
              _buildSectionTitle('AI Assistance & Data Minimization'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(LinguaTokens.space16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      _PolicyItem(
                        icon: Icons.auto_awesome,
                        title: 'What AI is Used For',
                        description:
                            'AI assists with lesson recommendations, clarifying educational concepts, providing feedback on writing/transcripts, and constrained practice scenarios. AI never diagnoses or makes clinical decisions.',
                      ),
                      SizedBox(height: 14),
                      _PolicyItem(
                        icon: Icons.mic_off,
                        title: 'Zero Raw Audio Sent to AI',
                        description:
                            'Raw microphone audio recordings are never sent to external AI providers. Only sanitized, learner-reviewed text transcripts are used.',
                      ),
                      SizedBox(height: 14),
                      _PolicyItem(
                        icon: Icons.security,
                        title: 'Strict Data Minimization',
                        description:
                            'AI requests never include passwords, auth tokens, device locations, or personal identity details. Requests only include minimized curriculum context (age band, candidate lesson IDs, exercise prompts).',
                      ),
                      SizedBox(height: 14),
                      _PolicyItem(
                        icon: Icons.verified_user_outlined,
                        title: 'Child Mode Protection & Deterministic Fallback',
                        description:
                            'For young learners, cloud AI processing is gated by default. If AI is unavailable or disabled, the entire learning path operates using deterministic curriculum rules.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: LinguaTokens.space24),

              OutlinedButton.icon(
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Settings'),
                onPressed: () => Navigator.of(context).pop(),
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
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: LinguaTokens.ink700,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(label, style: const TextStyle(fontSize: 14, color: LinguaTokens.ink700)),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: LinguaTokens.ink900),
          ),
        ),
      ],
    );
  }
}

class _PolicyItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _PolicyItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: LinguaTokens.primary600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: LinguaTokens.ink900),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: const TextStyle(fontSize: 13, height: 1.4, color: LinguaTokens.ink700),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

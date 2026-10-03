import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_tokens/tokens.dart';
import '../../../../core/widgets/non_diagnostic_banner.dart';
import '../providers/ai_providers.dart';
import '../widgets/ai_conversation_view.dart';

/// Screen hosting constrained AI Conversational Practice.
/// Provides safe, structured educational scenarios for oral language (DLD)
/// and reading discussion (Dyslexia/Literacy), strictly governed by non-diagnostic rules.
class AiConversationScreen extends ConsumerStatefulWidget {
  const AiConversationScreen({super.key});

  @override
  ConsumerState<AiConversationScreen> createState() => _AiConversationScreenState();
}

class _AiConversationScreenState extends ConsumerState<AiConversationScreen> {
  String _selectedScenarioKey = 'clarification';
  final List<Map<String, String>> _scenarios = [
    {
      'key': 'clarification',
      'title': 'Asking for Clarification',
      'desc': 'Practice asking questions when you need someone to repeat or explain something.',
      'track': 'dld',
    },
    {
      'key': 'event_description',
      'title': 'Describing an Event',
      'desc': 'Practice sharing what happened using sequencing words like first, next, and finally.',
      'track': 'dld',
    },
    {
      'key': 'reading_discussion',
      'title': 'Discussing a Story',
      'desc': 'Practice answering questions about a short passage and sharing your thoughts.',
      'track': 'dyslexia',
    },
    {
      'key': 'vocabulary_context',
      'title': 'Using Words in Context',
      'desc': 'Practice using new vocabulary words in natural sentences.',
      'track': 'both',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final activeScenario = _scenarios.firstWhere(
      (s) => s['key'] == _selectedScenarioKey,
      orElse: () => _scenarios.first,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversational Practice'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'About Practice Partner',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Educational Practice Partner'),
                  content: const Text(
                    'This conversational partner helps you practice speaking and expressing ideas in specific educational scenarios.\n\n'
                    'It is strictly educational and non-diagnostic. It does not provide medical therapy, evaluate disorders, or score clinical speech.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Understood'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const NonDiagnosticBanner(compact: true),
            // Scenario Selector Dropdown Bar
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: LinguaTokens.space16,
                vertical: LinguaTokens.space8,
              ),
              color: LinguaTokens.paper50,
              child: Row(
                children: [
                  const Icon(Icons.topic_outlined, size: 20, color: LinguaTokens.primary700),
                  const SizedBox(width: 8),
                  const Text(
                    'Scenario: ',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Expanded(
                    child: DropdownButton<String>(
                      value: _selectedScenarioKey,
                      isExpanded: true,
                      underline: const SizedBox.shrink(),
                      style: const TextStyle(
                        fontSize: 13,
                        color: LinguaTokens.ink900,
                        fontWeight: FontWeight.w600,
                      ),
                      items: _scenarios.map((s) {
                        return DropdownMenuItem<String>(
                          value: s['key'],
                          child: Text(s['title']!, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedScenarioKey = val);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Main Conversation View
            Expanded(
              child: AiConversationView(
                key: ValueKey(_selectedScenarioKey),
                scenario: activeScenario['key']!,
                scenarioTitle: activeScenario['title']!,
                maxTurns: 5,
                onSendMessage: (msg) async {
                  final repo = ref.read(aiRepositoryProvider);
                  return repo.getConversationReply(
                    scenarioId: activeScenario['key']!,
                    scenarioTitle: activeScenario['title']!,
                    scenarioContext: activeScenario['desc']!,
                    ageBand: 'child',
                    history: const [],
                    userMessage: msg,
                  );
                },
                onReset: () {
                  // State reset handled internally by key & widget
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

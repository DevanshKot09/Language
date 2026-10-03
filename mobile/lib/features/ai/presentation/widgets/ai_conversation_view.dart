import 'package:flutter/material.dart';
import '../../../../shared/design_tokens/tokens.dart';
import '../../domain/models/ai_models.dart';

/// Message item representing a turn in the practice conversation.
class AiChatMessage {
  final String sender; // 'learner' or 'ai'
  final String text;
  final String? followupPrompt;

  const AiChatMessage({
    required this.sender,
    required this.text,
    this.followupPrompt,
  });
}

/// Constrained Conversational Practice View
/// Provides structured, educational dialogue scenarios (e.g. asking for clarification,
/// summarizing a story, discussing a reading passage).
/// Strictly non-diagnostic, strictly educational, with bounded turns and explicit reset.
class AiConversationView extends StatefulWidget {
  final String scenario;
  final String scenarioTitle;
  final int maxTurns;
  final Future<AiConversationReplyModel> Function(String userMessage) onSendMessage;
  final VoidCallback onReset;

  const AiConversationView({
    super.key,
    required this.scenario,
    required this.scenarioTitle,
    this.maxTurns = 5,
    required this.onSendMessage,
    required this.onReset,
  });

  @override
  State<AiConversationView> createState() => _AiConversationViewState();
}

class _AiConversationViewState extends State<AiConversationView> {
  final List<AiChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  int _currentTurn = 0;
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    // Initial educational prompt
    _messages.add(
      AiChatMessage(
        sender: 'ai',
        text: 'Welcome to this practice scenario: "${widget.scenarioTitle}". I am your conversational practice partner. How would you like to begin?',
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isLoading || _isComplete) return;

    _textController.clear();
    setState(() {
      _messages.add(AiChatMessage(sender: 'learner', text: text));
      _currentTurn++;
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final reply = await widget.onSendMessage(text);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _messages.add(
          AiChatMessage(
            sender: 'ai',
            text: reply.reply,
            followupPrompt: reply.followupPrompt,
          ),
        );
        if (_currentTurn >= widget.maxTurns || reply.isScenarioComplete) {
          _isComplete = true;
        }
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _messages.add(
          const AiChatMessage(
            sender: 'ai',
            text: "I'm having a little trouble responding right now, but your practice was great! Let's pause here.",
          ),
        );
        _isComplete = true;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Scenario header with turn counter and reset
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: LinguaTokens.space16,
            vertical: LinguaTokens.space8,
          ),
          decoration: BoxDecoration(
            color: LinguaTokens.paper50,
            border: Border(
              bottom: BorderSide(color: LinguaTokens.borderSubtle),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.scenarioTitle,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: LinguaTokens.ink900,
                      ),
                    ),
                    Text(
                      'Turn $_currentTurn of ${widget.maxTurns} • Educational Practice Partner',
                      style: const TextStyle(
                        fontSize: 11,
                        color: LinguaTokens.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _messages.clear();
                    _currentTurn = 0;
                    _isComplete = false;
                    _messages.add(
                      AiChatMessage(
                        sender: 'ai',
                        text: 'Welcome back! Scenario restarted: "${widget.scenarioTitle}". What would you like to practice saying?',
                      ),
                    );
                  });
                  widget.onReset();
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Reset'),
              ),
            ],
          ),
        ),

        // Conversation history list
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(LinguaTokens.space16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              final isAi = msg.sender == 'ai';
              return Padding(
                padding: const EdgeInsets.only(bottom: LinguaTokens.space12),
                child: Row(
                  mainAxisAlignment:
                      isAi ? MainAxisAlignment.start : MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isAi) ...[
                      const CircleAvatar(
                        radius: 14,
                        backgroundColor: LinguaTokens.primary100,
                        child: Icon(
                          Icons.smart_toy_outlined,
                          size: 16,
                          color: LinguaTokens.primary700,
                        ),
                      ),
                      const SizedBox(width: LinguaTokens.space8),
                    ],
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.all(LinguaTokens.space12),
                        decoration: BoxDecoration(
                          color: isAi
                              ? LinguaTokens.paper100
                              : LinguaTokens.primary600,
                          borderRadius: BorderRadius.circular(
                            LinguaTokens.radiusSmall,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: isAi
                              ? CrossAxisAlignment.start
                              : CrossAxisAlignment.end,
                          children: [
                            Text(
                              msg.text,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.4,
                                color: isAi
                                    ? LinguaTokens.ink900
                                    : Colors.white,
                              ),
                            ),
                            if (msg.followupPrompt != null &&
                                msg.followupPrompt!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                '💡 ${msg.followupPrompt!}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: LinguaTokens.primary700,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (!isAi) const SizedBox(width: LinguaTokens.space8),
                  ],
                ),
              );
            },
          ),
        ),

        // Thinking indicator
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: LinguaTokens.space8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text(
                  'Preparing educational response...',
                  style: TextStyle(fontSize: 12, color: LinguaTokens.inkMuted),
                ),
              ],
            ),
          ),

        // Completed notice
        if (_isComplete)
          Container(
            padding: const EdgeInsets.all(LinguaTokens.space12),
            margin: const EdgeInsets.symmetric(horizontal: LinguaTokens.space16),
            decoration: BoxDecoration(
              color: LinguaTokens.successLight,
              borderRadius: BorderRadius.circular(LinguaTokens.radiusSmall),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: LinguaTokens.success600, size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    "Practice session complete! Great job expressing yourself.",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: LinguaTokens.success600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _messages.clear();
                      _currentTurn = 0;
                      _isComplete = false;
                      _messages.add(
                        AiChatMessage(
                          sender: 'ai',
                          text: 'Starting a new conversation. What would you like to practice saying?',
                        ),
                      );
                    });
                    widget.onReset();
                  },
                  child: const Text('New Session'),
                ),
              ],
            ),
          ),

        // Input controls
        if (!_isComplete)
          Padding(
            padding: const EdgeInsets.all(LinguaTokens.space12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    onSubmitted: (_) => _handleSend(),
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: LinguaTokens.space16,
                        vertical: LinguaTokens.space12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(LinguaTokens.radiusPill),
                        borderSide: BorderSide(color: LinguaTokens.borderSubtle),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: LinguaTokens.space8),
                IconButton.filled(
                  onPressed: _isLoading ? null : _handleSend,
                  icon: const Icon(Icons.send, size: 18),
                ),
              ],
            ),
          ),

        // Non-diagnostic footer note
        const Padding(
          padding: EdgeInsets.only(
            bottom: LinguaTokens.space8,
            left: LinguaTokens.space16,
            right: LinguaTokens.space16,
          ),
          child: Text(
            'Constrained conversational practice for educational use only. Not clinical speech therapy or diagnostic evaluation.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: LinguaTokens.inkMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }
}

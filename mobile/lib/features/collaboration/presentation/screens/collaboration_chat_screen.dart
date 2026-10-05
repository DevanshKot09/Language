import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/router/app_router.dart';
import '../../application/collaboration_providers.dart';
import '../../domain/models/collaboration_models.dart';

/// Conversation Detail / Collaboration Chat Thread Screen
///
/// Specialist support conversation view matching the primary Stitch visual design:
/// - Custom Header with Back, Avatar with Online Badge, Title & Role, More Options
/// - Date Separators (Yesterday, Today)
/// - Multi-role Participant Incoming Message Bubbles (Priya Mehta - Parent, Mrs. Davies - Teacher)
/// - Outgoing Specialist Message Bubbles in Royal Purple with Rich PDF Attachment Preview
/// - Comprehensive Input Composer with Attachment (+) button, Voice Mic turn, and Send
/// - Non-diagnostic terminology, server-side RBAC, and Guardian Consent awareness.
class CollaborationChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String title;
  final String? subtitle;
  final String? targetLearnerId;
  final List<String> roles;
  final bool isLocked;

  const CollaborationChatScreen({
    super.key,
    required this.conversationId,
    required this.title,
    this.subtitle,
    this.targetLearnerId,
    this.roles = const [],
    this.isLocked = false,
  });

  @override
  ConsumerState<CollaborationChatScreen> createState() => _CollaborationChatScreenState();
}

class _CollaborationChatScreenState extends ConsumerState<CollaborationChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;

  // Stitch Design Palette
  static const Color _bg = Color(0xFFF9FAFD);
  static const Color _primaryPurple = Color(0xFF3813C2);
  static const Color _primaryLight = Color(0xFFEDE9FE);
  static const Color _inkDark = Color(0xFF1E1E38);
  static const Color _muted = Color(0xFF64748B);
  static const Color _subtle = Color(0xFF94A3B8);
  static const Color _onlineTeal = Color(0xFF10B981);
  static const Color _micGreen = Color(0xFF047857);
  static const Color _bubbleBorder = Color(0xFFEDE9FE);

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasContent = _textController.text.trim().isNotEmpty;
    if (hasContent != _hasText) {
      setState(() => _hasText = hasContent);
    }
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _scrollToBottomDelayed();
    }
  }

  void _scrollToBottomDelayed([int milliseconds = 250]) {
    Future.delayed(Duration(milliseconds: milliseconds), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _handleSendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    setState(() => _hasText = false);

    final success = await ref
        .read(chatThreadNotifierProvider(widget.conversationId).notifier)
        .sendMessage(text);

    _scrollToBottomDelayed(100);

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message could not be sent. Tap retry to send again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleAttachmentAction() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.attach_file_rounded, color: _primaryPurple, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Attach Learning Resource',
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: _inkDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildAttachmentOption(
                icon: Icons.picture_as_pdf_rounded,
                iconColor: const Color(0xFF2DD4BF),
                title: 'Phonics Pacing Cards (PDF)',
                subtitle: 'Send 2-syllable /r/ practice set',
                onTap: () {
                  Navigator.pop(ctx);
                  _sendPredefinedAttachment(
                    'Phoneme_Pacing_Cards.pdf',
                    '2.4 MB',
                    'Guided Practice',
                  );
                },
              ),
              _buildAttachmentOption(
                icon: Icons.assignment_outlined,
                iconColor: const Color(0xFF6366F1),
                title: 'Fluency Progress Worksheet',
                subtitle: 'Weekly classroom reinforcement sheet',
                onTap: () {
                  Navigator.pop(ctx);
                  _sendPredefinedAttachment(
                    'Fluency_Worksheet_Week4.pdf',
                    '1.6 MB',
                    'Classroom Practice',
                  );
                },
              ),
              _buildAttachmentOption(
                icon: Icons.auto_graph_rounded,
                iconColor: const Color(0xFFEC4899),
                title: 'Session Turn Summary',
                subtitle: 'Factual summary of today\'s live turns',
                onTap: () {
                  Navigator.pop(ctx);
                  _sendPredefinedAttachment(
                    'Session_Summary_Oct17.pdf',
                    '890 KB',
                    'Session Overview',
                  );
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  void _sendPredefinedAttachment(String filename, String size, String category) {
    ref.read(chatThreadNotifierProvider(widget.conversationId).notifier).sendMessage(
          "I've attached the $category materials: $filename",
          attachmentId: 'att_${filename.split('.').first.toLowerCase()}',
        );
    _scrollToBottomDelayed(100);
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _inkDark),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 11.5, color: _muted),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: _subtle),
      onTap: onTap,
    );
  }

  void _handleVoiceMicAction() {
    if (widget.isLocked) {
      _showConsentLockedAlert();
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFECFDF5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mic_rounded, color: _micGreen, size: 32),
              ),
              const SizedBox(height: 16),
              const Text(
                'Record Learning Audio Turn',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _inkDark),
              ),
              const SizedBox(height: 8),
              const Text(
                'Record speech pronunciation guidance for the support circle. Protected under educational collaboration permissions.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: _muted, height: 1.4),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  ref.read(chatThreadNotifierProvider(widget.conversationId).notifier).sendMessage(
                        '🎙️ Voice Note: /r/ cluster articulation demonstration (0:45)',
                      );
                  _scrollToBottomDelayed(100);
                },
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Simulate Audio Turn Send'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _micGreen,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showConsentLockedAlert() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.lock_rounded, color: Color(0xFFDC2626), size: 22),
            SizedBox(width: 8),
            Text('Audio Turns Locked', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
        content: const Text(
          'Guardian consent is pending verification. Educational audio turns and session note access are strictly protected until guardian verification is confirmed.',
          style: TextStyle(fontSize: 13, color: _muted, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                widget.title,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _inkDark),
              ),
              const SizedBox(height: 4),
              Text(
                widget.subtitle ?? 'Support Conversation Thread',
                style: const TextStyle(fontSize: 12, color: _muted),
              ),
              const Divider(height: 24),
              ListTile(
                leading: const Icon(Icons.person_pin_circle_outlined, color: _primaryPurple),
                title: const Text('View Learner Profile', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Open caseload milestones and track profile', style: TextStyle(fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  if (widget.targetLearnerId != null) {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.specialistLearnerDetail,
                      arguments: widget.targetLearnerId,
                    );
                  } else {
                    Navigator.pushNamed(context, AppRoutes.specialistDashboard);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.analytics_outlined, color: Color(0xFF0284C7)),
                title: const Text('View Progress Report', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Factual educational metrics & session summary', style: TextStyle(fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(
                    context,
                    AppRoutes.learnerReport,
                    arguments: widget.targetLearnerId,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_month_outlined, color: Color(0xFF059669)),
                title: const Text('Schedule Support Session', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Coordinate live interactive practice', style: TextStyle(fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, AppRoutes.specialistSchedule);
                },
              ),
              ListTile(
                leading: const Icon(Icons.shield_outlined, color: Color(0xFF7C3AED)),
                title: const Text('Collaboration Privacy & Consent', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('Status: ${widget.isLocked ? "Pending Consent" : "Verified & Active"}', style: const TextStyle(fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Conversation ${widget.conversationId} • Protected by LINGUA AI Privacy'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    final threadState = ref.watch(chatThreadNotifierProvider(widget.conversationId));

    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildHeader(),
      body: SafeArea(
        child: Column(
          children: [
            // Consent Locked Banner (if consent is pending)
            if (widget.isLocked) _buildConsentPendingBanner(),

            // Message List Content
            Expanded(
              child: _buildMessagesBody(threadState),
            ),

            // Input Composer Bar
            _buildInputComposer(),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. HEADER (Back, Avatar + Online Badge, Title & Status, Options Menu)
  // ---------------------------------------------------------------------------
  PreferredSizeWidget _buildHeader() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 1,
      titleSpacing: 0,
      leading: Semantics(
        button: true,
        label: 'Back to messages',
        child: IconButton(
          icon: const Icon(
            Icons.chevron_left_rounded,
            color: _primaryPurple,
            size: 32,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      title: Row(
        children: [
          // Header Avatar with Teal Online Dot
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _primaryLight,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFDDD6FE), width: 1.2),
                ),
                child: const Center(
                  child: Icon(
                    Icons.psychology_alt_rounded,
                    color: _primaryPurple,
                    size: 22,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _onlineTeal,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),

          // Title & Subtitle with Online Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title.isNotEmpty ? widget.title : 'Specialist Conversation',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: _inkDark,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: _onlineTeal,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        widget.subtitle ?? 'Speech Specialist • Online',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: _muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Semantics(
          button: true,
          label: 'More conversation options',
          child: IconButton(
            key: const ValueKey('chat_header_more_button'),
            icon: const Icon(Icons.more_vert_rounded, color: _muted, size: 22),
            onPressed: _showMoreOptions,
          ),
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          color: const Color(0xFFF1F5F9),
          height: 1,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. GUARDIAN CONSENT PENDING BANNER
  // ---------------------------------------------------------------------------
  Widget _buildConsentPendingBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECACA), width: 1.1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Color(0xFFFEE2E2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_outline_rounded, color: Color(0xFFDC2626), size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Guardian Consent Pending',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF991B1B),
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  'Audio turns and session notes locked until guardian sign-off.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFFB91C1C),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _showConsentLockedAlert,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Details',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFFB91C1C),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. MESSAGES BODY (Loading, Empty, Error, or List with Date Separators)
  // ---------------------------------------------------------------------------
  Widget _buildMessagesBody(ChatThreadState state) {
    if (state.isLoading && state.messages.isEmpty) {
      return _buildLoadingSkeleton();
    }

    if (state.errorMessage != null && state.messages.isEmpty) {
      return _buildErrorState(state.errorMessage!);
    }

    if (state.messages.isEmpty) {
      return _buildEmptyState();
    }

    // Render messages with date separators
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: state.messages.length,
      itemBuilder: (context, index) {
        final message = state.messages[index];

        // Determine if date separator is needed before this message
        final showSeparator = index == 0 ||
            state.messages[index - 1].dateGroup != message.dateGroup;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showSeparator) _buildDateSeparator(message.dateGroup),
            if (message.isSelf)
              _buildOutgoingMessageBubble(message)
            else
              _buildIncomingMessageBubble(message),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 4. DATE SEPARATOR CAPSULE (Yesterday, Today)
  // ---------------------------------------------------------------------------
  Widget _buildDateSeparator(String label) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 14),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: _primaryLight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF5B5BD6),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. INCOMING MESSAGE BUBBLE (Multi-role Participant, Soft White Card)
  // ---------------------------------------------------------------------------
  Widget _buildIncomingMessageBubble(ChatMessageItem message) {
    final senderInitials = message.avatarInitials ??
        (message.senderName.isNotEmpty
            ? message.senderName
                .split(' ')
                .take(2)
                .map((e) => e.isNotEmpty ? e[0] : '')
                .join()
            : 'U');

    final roleLabel = message.senderRoleLabel;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Participant Avatar
          _buildParticipantAvatar(message.senderRole, senderInitials),

          const SizedBox(width: 12),

          // Message Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sender Info Line: Name, Role Badge, Timestamp
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 2,
                  children: [
                    Text(
                      message.senderName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _inkDark,
                      ),
                    ),
                    if (roleLabel != null && roleLabel.isNotEmpty)
                      _buildRoleBadge(roleLabel),
                    Text(
                      message.timestamp,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: _subtle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // White Message Bubble
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _bubbleBorder, width: 1.1),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x08000000),
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    message.content,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: _inkDark,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantAvatar(String role, String initials) {
    Color bg = const Color(0xFFFEF3C7);
    Color text = const Color(0xFFB45309);

    if (role == 'teacher') {
      bg = const Color(0xFFCCFBF1);
      text = const Color(0xFF0F766E);
    } else if (role == 'system') {
      bg = const Color(0xFFF1F5F9);
      text = const Color(0xFF475569);
    }

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: text,
          ),
        ),
      ),
    );
  }

  Widget _buildRoleBadge(String label) {
    final isTeacher = label.toLowerCase().contains('teacher');
    final bg = isTeacher ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9);
    final border = isTeacher ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0);
    final text = isTeacher ? const Color(0xFF047857) : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: text,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 6. OUTGOING MESSAGE BUBBLE (Specialist - Royal Purple with PDF Preview)
  // ---------------------------------------------------------------------------
  Widget _buildOutgoingMessageBubble(ChatMessageItem message) {
    final isSending = message.deliveryStatus == 'sending';
    final isFailed = message.deliveryStatus == 'failed';

    String statusText = '${message.timestamp} • Delivered';
    if (isSending) statusText = 'Sending...';
    if (isFailed) statusText = 'Not sent • Tap to retry';

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Header Line above Outgoing Bubble: Timestamp/Status + You (Specialist)
          Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 2,
            children: [
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isFailed ? const Color(0xFFDC2626) : _subtle,
                ),
              ),
              const Text(
                'You (Specialist)',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: _primaryPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Rich Royal Purple Bubble
          GestureDetector(
            onTap: isFailed
                ? () => ref
                    .read(chatThreadNotifierProvider(widget.conversationId).notifier)
                    .retryMessage(message.id)
                : null,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.84,
              ),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _primaryPurple,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x243813C2),
                    blurRadius: 14,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Message Text in White
                  Text(
                    message.content,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                      height: 1.45,
                    ),
                  ),

                  // Embedded Document / Practice Card Attachment Preview
                  if (message.attachment != null) ...[
                    const SizedBox(height: 14),
                    _buildAttachmentPreviewCard(message.attachment!),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 7. EMBEDDED ATTACHMENT CARD PREVIEW (Phoneme_Pacing_Cards.pdf)
  // ---------------------------------------------------------------------------
  Widget _buildAttachmentPreviewCard(ChatMessageAttachmentItem attachment) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Teal Document Icon Container
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF2DD4BF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Icon(
                Icons.picture_as_pdf_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // File Title & Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  attachment.filename,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: _inkDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${attachment.fileSizeLabel} • ${attachment.categoryLabel}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: _muted,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // "Preview" Action Button
          Material(
            color: _primaryLight,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _openAttachmentViewer(attachment),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Text(
                  'Preview',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: _primaryPurple,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openAttachmentViewer(ChatMessageAttachmentItem attachment) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF2DD4BF)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                attachment.filename,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Educational Learning Material • ${attachment.categoryLabel}',
              style: const TextStyle(fontSize: 12, color: _muted),
            ),
            const SizedBox(height: 12),
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.menu_book_rounded, size: 36, color: _primaryPurple),
                    const SizedBox(height: 6),
                    Text(
                      'Ready for Phonics Session (${attachment.fileSizeLabel})',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _inkDark),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 8. INPUT COMPOSER (+ Attachment, TextField, Mic Voice Turn, Send)
  // ---------------------------------------------------------------------------
  Widget _buildInputComposer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
      ),
      child: Row(
        children: [
          // Plus / Attachment Button (+)
          Semantics(
            button: true,
            label: 'Add attachment',
            child: Material(
              key: const ValueKey('chat_attachment_button'),
              color: _primaryLight,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: _handleAttachmentAction,
                customBorder: const CircleBorder(),
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: Icon(Icons.add_rounded, color: _primaryPurple, size: 24),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Message Input Capsule
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
              ),
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _handleSendMessage(),
                style: const TextStyle(fontSize: 14, color: _inkDark),
                decoration: const InputDecoration(
                  hintText: 'Write a message...',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: _subtle,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Forest Green Voice Mic Button
          Semantics(
            button: true,
            label: 'Record voice note',
            child: Material(
              key: const ValueKey('chat_mic_button'),
              color: _micGreen,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: _handleVoiceMicAction,
                customBorder: const CircleBorder(),
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: Icon(Icons.mic_rounded, color: Colors.white, size: 22),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Royal Purple Send Button
          Semantics(
            button: true,
            label: 'Send message',
            child: Material(
              key: const ValueKey('chat_send_button'),
              color: _hasText ? _primaryPurple : _primaryPurple.withValues(alpha: 0.8),
              shape: const CircleBorder(),
              child: InkWell(
                onTap: _handleSendMessage,
                customBorder: const CircleBorder(),
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 9. LOADING, EMPTY & ERROR STATES
  // ---------------------------------------------------------------------------
  Widget _buildLoadingSkeleton() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildDateSeparator('Today'),
        const SizedBox(height: 12),
        // Incoming Skeleton
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(color: Color(0xFFEEF2F6), shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Container(
              width: 220,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Outgoing Skeleton
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            width: 260,
            height: 90,
            decoration: BoxDecoration(
              color: const Color(0xFFDDD6FE),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded, color: _primaryPurple, size: 30),
            ),
            const SizedBox(height: 16),
            const Text(
              'Start the conversation',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _inkDark),
            ),
            const SizedBox(height: 6),
            const Text(
              'Send a message to begin supporting this learner and coordinating with the support team.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: _muted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 44),
            const SizedBox(height: 12),
            const Text(
              'Unable to load conversation messages',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _inkDark),
            ),
            const SizedBox(height: 6),
            Text(
              message.contains('SocketException')
                  ? 'Network unreachable. Please check your connection.'
                  : 'An error occurred while loading this chat thread.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: _muted),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(chatThreadNotifierProvider(widget.conversationId).notifier).loadMessages();
              },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

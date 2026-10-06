import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/providers/session_provider.dart';
import '../../../../app/router/app_router.dart';
import '../../../../shared/models/user_role.dart';
import '../../domain/models/collaboration_models.dart';
import 'package:lingua_ai/features/error_state/error_state_type.dart';
import 'package:lingua_ai/features/error_state/error_state_view.dart';

/// Specialist — Live Support Session Screen.
///
/// Designed to visually and functionally match the Stitch visual reference:
/// * Header with Back/Close, Live Session title, session options and profile avatar.
/// * Learner identification bar with avatar, live elapsed timer, and profile link.
/// * Deep-navy main session surface featuring Picture-in-Picture (PiP) specialist
///   view, learner presence indicator, audio connection state, and live target prompt.
/// * Interactive Session Tools: Cards, Pacer, Notes, and Reward.
/// * Learner Guidance summary card with Tier 2 badge and recent progress insight.
/// * Bottom session control bar with Mic, Camera, Speaker, Materials, and End Session.
///
/// Non-diagnostic: focuses strictly on speech, language, phonological pacing,
/// and learning support.
class SpecialistLiveSessionScreen extends ConsumerStatefulWidget {
  /// Session or learner identifier/object passed from navigation.
  final dynamic sessionOrLearner;

  const SpecialistLiveSessionScreen({
    super.key,
    this.sessionOrLearner,
  });

  @override
  ConsumerState<SpecialistLiveSessionScreen> createState() => _SpecialistLiveSessionScreenState();
}

enum _SessionLifecycle {
  ready,
  joining,
  connecting,
  active,
  ending,
  completed,
  error,
}

class _SpecialistLiveSessionScreenState extends ConsumerState<SpecialistLiveSessionScreen> {
  // Theme palette matching Stitch reference
  static const _ink = Color(0xFF1E1B4B);
  static const _primaryPurple = Color(0xFF5B21B6);
  static const _deepNavySurface = Color(0xFF1C1848);
  static const _lavenderBg = Color(0xFFEDE9FE);
  static const _lavenderLight = Color(0xFFF1EFF9);
  static const _muted = Color(0xFF64748B);
  static const _subtleGrey = Color(0xFF94A3B8);
  static const _mintGreen = Color(0xFF10B981);
  static const _tealPraise = Color(0xFF2DD4BF);
  static const _redEnd = Color(0xFFB91C1C);

  // Session lifecycle & controls state
  _SessionLifecycle _lifecycle = _SessionLifecycle.active;
  bool _isMicMuted = false;
  bool _isCameraOff = true;
  bool _isSpeakerMuted = false;
  bool _isAudioConnected = true;

  // Live timer (defaults to matching 18:42 in Stitch screenshot, ticks up in active state)
  int _elapsedSeconds = 18 * 60 + 42; // 1122 seconds = 18:42
  Timer? _timer;

  // Session content state
  int _currentCardIndex = 4;
  final int _totalCards = 8;
  final String _targetPhoneme = '/r/';
  int _praiseCount = 0;
  int _pacerBpm = 64;
  bool _isPacerActive = false;

  // Learner information (resolved from sessionOrLearner or defaults to Aarav Mehta)
  late String _learnerId;
  late String _learnerName;
  late String _learnerAgeBand;
  late String _supportFocus;
  late String _sessionNumberText;

  final List<Map<String, String>> _practiceCards = [
    {'title': 'Rabbit', 'cue': 'Initial /r/', 'word': 'Rabbit hops in grass'},
    {'title': 'Train', 'cue': 'Blend /tr/', 'word': 'The fast blue train'},
    {'title': 'Frog', 'cue': 'Blend /fr/', 'word': 'Green frog on a leaf'},
    {'title': 'Ring', 'cue': 'Initial /r/', 'word': 'Silver shiny ring'},
    {'title': 'Grass', 'cue': 'Blend /gr/', 'word': 'Green sweet grass'},
    {'title': 'Drum', 'cue': 'Blend /dr/', 'word': 'Play loud beat on drum'},
    {'title': 'Bridge', 'cue': 'Blend /br/', 'word': 'Walk across high bridge'},
    {'title': 'Crown', 'cue': 'Blend /kr/', 'word': 'Golden royal crown'},
  ];

  @override
  void initState() {
    super.initState();
    _resolveLearnerData();
    _startTimer();
  }

  void _resolveLearnerData() {
    final arg = widget.sessionOrLearner;
    if (arg is SpecialistScheduleSession) {
      _learnerId = arg.learnerId;
      _learnerName = arg.learnerName;
      _learnerAgeBand = arg.ageBand;
      _supportFocus = arg.focus ?? 'Consonant Clusters';
      _sessionNumberText = 'Session 3';
    } else if (arg is SpecialistCaseloadItem) {
      _learnerId = arg.learnerId;
      _learnerName = arg.displayName;
      _learnerAgeBand = arg.ageBand;
      _supportFocus = arg.supportFocus.replaceAll('_', ' ');
      _sessionNumberText = 'Session 3';
    } else if (arg is String && arg.isNotEmpty) {
      _learnerId = arg;
      if (arg.contains('maya')) {
        _learnerName = 'Maya Sharma';
        _learnerAgeBand = 'Adult';
        _supportFocus = 'Phonological Decoding';
        _sessionNumberText = 'Session 5';
      } else {
        _learnerName = 'Aarav Mehta';
        _learnerAgeBand = 'Age 10';
        _supportFocus = 'Consonant Clusters';
        _sessionNumberText = 'Session 3';
      }
    } else {
      // Default to Aarav Mehta matching the Stitch visual specification
      _learnerId = 'lr-1';
      _learnerName = 'Aarav Mehta';
      _learnerAgeBand = 'Age 10';
      _supportFocus = 'Consonant Clusters';
      _sessionNumberText = 'Session 3';
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_lifecycle == _SessionLifecycle.active && mounted) {
        setState(() {
          _elapsedSeconds++;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatElapsed(int totalSecs) {
    final mins = (totalSecs ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSecs % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  // ---------------------------------------------------------------------------
  // BUILD METHOD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final session = ref.watch(userSessionProvider);

    // RBAC Security Check
    if (session.isAuthenticated && session.currentRole != UserRole.specialist) {
      return _buildRestrictedRoleScreen();
    }

    return PopScope(
      canPop: _lifecycle == _SessionLifecycle.completed || _lifecycle == _SessionLifecycle.ready,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && mounted) {
          _confirmEndSession();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FE),
        body: SafeArea(
          bottom: false,
          child: _buildLifecycleContent(),
        ),
        bottomNavigationBar: _lifecycle == _SessionLifecycle.active
            ? _buildBottomSessionControls()
            : null,
      ),
    );
  }

  Widget _buildLifecycleContent() {
    switch (_lifecycle) {
      case _SessionLifecycle.ready:
        return _buildReadyState();
      case _SessionLifecycle.joining:
        return _buildStatusTransitionState(
          title: 'Joining session…',
          subtitle: 'Initializing secure audio/video channel with $_learnerName',
          icon: Icons.meeting_room_rounded,
        );
      case _SessionLifecycle.connecting:
        return _buildStatusTransitionState(
          title: 'Connecting…',
          subtitle: 'Performing acoustic check and synchronizing learning cards',
          icon: Icons.sync_rounded,
        );
      case _SessionLifecycle.active:
        return _buildActiveSessionView();
      case _SessionLifecycle.ending:
        return _buildStatusTransitionState(
          title: 'Ending session…',
          subtitle: 'Saving speech practice metrics and learning observations',
          icon: Icons.hourglass_top_rounded,
        );
      case _SessionLifecycle.completed:
        return _buildSessionCompletedView();
      case _SessionLifecycle.error:
        return ErrorStateView(
          type: ErrorStateType.serverError,
          title: 'Live Session Disconnected',
          message: 'Unable to connect to the live support channel. Please check your connection and try again.',
          onRetry: () {
            setState(() {
              _lifecycle = _SessionLifecycle.connecting;
            });
            Future.delayed(const Duration(milliseconds: 800), () {
              if (mounted) {
                setState(() {
                  _lifecycle = _SessionLifecycle.active;
                });
              }
            });
          },
        );
    }
  }

  // ---------------------------------------------------------------------------
  // ACTIVE SESSION VIEW (STITCH SOURCE OF TRUTH)
  // ---------------------------------------------------------------------------
  Widget _buildActiveSessionView() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Top App Bar / Header
          _buildTopHeader(),

          const SizedBox(height: 8),

          // 2. Learner Identity & Live Timer Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildLearnerIdentityHeader(),
          ),

          const SizedBox(height: 12),

          // 3. Main Session Surface (Deep navy card with PiP & active audio feedback)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildMainSessionArea(),
          ),

          const SizedBox(height: 16),

          // 4. "SESSION TOOLS" Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: _buildSessionToolsHeader(),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildSessionToolsGrid(),
          ),

          const SizedBox(height: 16),

          // 5. "Learner Guidance" Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildLearnerGuidanceCard(),
          ),
        ],
      ),
    );
  }

  // 1. TOP APP BAR ------------------------------------------------------------
  Widget _buildTopHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          // Close button (X)
          Semantics(
            button: true,
            label: 'Close live session',
            child: InkWell(
              key: const Key('live_session_close_button'),
              onTap: _confirmEndSession,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: _lavenderLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: _ink,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Screen Title
          const Expanded(
            child: Text(
              'Specialist Live Session',
              style: TextStyle(
                fontSize: 17.5,
                fontWeight: FontWeight.w800,
                color: _ink,
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(width: 8),

          // More Options Button
          Semantics(
            button: true,
            label: 'Session options',
            child: InkWell(
              key: const Key('live_session_options_button'),
              onTap: _showSessionOptionsMenu,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: _lavenderLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.more_vert_rounded,
                  color: _ink,
                  size: 20,
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Specialist Profile Button
          Semantics(
            button: true,
            label: 'Specialist profile',
            child: InkWell(
              key: const Key('live_session_specialist_avatar'),
              onTap: _showSpecialistPresenceSheet,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: _primaryPurple,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 2. LEARNER IDENTITY HEADER ------------------------------------------------
  Widget _buildLearnerIdentityHeader() {
    final initial = _learnerName.isNotEmpty ? _learnerName[0].toUpperCase() : 'L';
    return Row(
      children: [
        // Learner Avatar with online green status dot
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: _lavenderBg,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: _primaryPurple,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  color: _mintGreen,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(width: 12),

        // Name, Live Timer pill, and Subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      _learnerName,
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Elapsed Live Timer Badge Pill (Matching "🟢 18:42" in Stitch)
                  Container(
                    key: const Key('live_session_timer_badge'),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF059669),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatElapsed(_elapsedSeconds),
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF065F46),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                '$_learnerAgeBand • $_supportFocus • $_sessionNumberText',
                style: const TextStyle(
                  fontSize: 12,
                  color: _muted,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        // Action: Quick View Learner Report / Card
        Semantics(
          button: true,
          label: 'View learner clinical report',
          child: InkWell(
            key: const Key('live_session_quick_report_button'),
            onTap: _openLearnerProfile,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _lavenderLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.assignment_ind_outlined,
                color: _primaryPurple,
                size: 21,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 3. MAIN SESSION SURFACE ---------------------------------------------------
  Widget _buildMainSessionArea() {
    final initial = _learnerName.isNotEmpty ? _learnerName[0].toUpperCase() : 'L';

    return Container(
      height: 360,
      decoration: BoxDecoration(
        color: _deepNavySurface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _ink.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Picture-in-Picture (PiP) Window (Top Right - Specialist View)
          Positioned(
            top: 14,
            right: 14,
            child: _buildSpecialistPipWindow(),
          ),

          // Central Learner Audio Presence Indicator
          Align(
            alignment: const Alignment(0, -0.15),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Large Avatar Circle
                Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 104,
                      height: 104,
                      decoration: const BoxDecoration(
                        color: _lavenderBg,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.w800,
                            color: _primaryPurple,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: _isAudioConnected ? _mintGreen : Colors.amber,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Learner Name
                Text(
                  _learnerName,
                  style: const TextStyle(
                    fontSize: 18.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 3),

                // Subtitle: "Live Audio"
                const Text(
                  'Live Audio',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFFC7D2FE),
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 3),

                // Connection status
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _isAudioConnected ? const Color(0xFF34D399) : Colors.amber,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _isAudioConnected ? 'Connected' : 'Reconnecting…',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFE0E7FF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Bottom Inside Overlay Pill: "Focus: Phoneme /r/ • Card 4/8" + "★ Praise"
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: _buildSessionFocusPromptPill(),
          ),
        ],
      ),
    );
  }

  // Specialist PiP Surface
  Widget _buildSpecialistPipWindow() {
    return Container(
      width: 96,
      height: 116,
      decoration: BoxDecoration(
        color: const Color(0xFFBFC3CD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Preview placeholder / camera state
          Center(
            child: _isCameraOff
                ? const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.videocam_off_rounded, size: 26, color: Color(0xFF64748B)),
                      SizedBox(height: 4),
                      Text(
                        'img',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  )
                : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.indigo.shade300, Colors.deepPurple.shade400],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Icon(Icons.person_outline_rounded, color: Colors.white, size: 36),
                    ),
                  ),
          ),

          // Bottom overlay bar: "You" + teal microphone icon
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 26,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: _ink.withValues(alpha: 0.8),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
              ),
              child: Row(
                children: [
                  const Text(
                    'You',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _isMicMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                    size: 13,
                    color: _isMicMuted ? const Color(0xFFF87171) : const Color(0xFF2DD4BF),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Inside bottom overlay prompt pill
  Widget _buildSessionFocusPromptPill() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEDEAF8),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.record_voice_over_outlined,
            size: 19,
            color: _primaryPurple,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Focus: Phoneme $_targetPhoneme • Card $_currentCardIndex/$_totalCards',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: _ink,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),

          // "★ Praise" Action Button (Mint/turquoise capsule)
          Semantics(
            button: true,
            label: 'Send praise to learner',
            child: InkWell(
              key: const Key('live_session_praise_button'),
              onTap: _sendPraiseToLearner,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _tealPraise,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      size: 15,
                      color: Color(0xFF064E3B),
                    ),
                    SizedBox(width: 3),
                    Text(
                      'Praise',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF064E3B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 4. "SESSION TOOLS" SECTION ------------------------------------------------
  Widget _buildSessionToolsHeader() {
    return const Text(
      'SESSION TOOLS',
      style: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w800,
        color: _muted,
        letterSpacing: 0.9,
      ),
    );
  }

  Widget _buildSessionToolsGrid() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildToolButton(
          key: const Key('session_tool_cards'),
          label: 'Cards',
          icon: Icons.style_outlined,
          color: const Color(0xFF6366F1),
          bgColor: const Color(0xFFEDE9FE),
          onTap: _openPracticeCardsModal,
        ),
        _buildToolButton(
          key: const Key('session_tool_pacer'),
          label: 'Pacer',
          icon: Icons.speed_rounded,
          color: const Color(0xFF0D9488),
          bgColor: const Color(0xFFCCFBF1),
          onTap: _openPacerModal,
        ),
        _buildToolButton(
          key: const Key('session_tool_notes'),
          label: 'Notes',
          icon: Icons.edit_note_rounded,
          color: const Color(0xFF4F46E5),
          bgColor: const Color(0xFFF1EFF9),
          onTap: _openSessionNotesModal,
        ),
        _buildToolButton(
          key: const Key('session_tool_reward'),
          label: 'Reward',
          icon: Icons.stars_rounded,
          color: const Color(0xFFD97706),
          bgColor: const Color(0xFFFEF3C7),
          onTap: _giveStarReward,
        ),
      ],
    );
  }

  Widget _buildToolButton({
    required Key key,
    required String label,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          label: 'Open $label tool',
          child: InkWell(
            key: key,
            onTap: onTap,
            borderRadius: BorderRadius.circular(30),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: color,
                  size: 26,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _ink,
          ),
        ),
      ],
    );
  }

  // 5. "Learner Guidance" CARD ------------------------------------------------
  Widget _buildLearnerGuidanceCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F0F8), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card Header: Brain icon + "Learner Guidance" + "Tier 2" badge
          Row(
            children: [
              const Icon(
                Icons.psychology_alt_outlined,
                size: 22,
                color: _primaryPurple,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Learner Guidance',
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _lavenderBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Tier',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: _primaryPurple,
                        height: 1.0,
                      ),
                    ),
                    Text(
                      '2',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: _primaryPurple,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Focus strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F7FC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 58,
                  child: Text(
                    'Focus',
                    style: TextStyle(
                      fontSize: 13,
                      color: _muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Pacing & /r/ consonant clusters',
                    style: TextStyle(
                      fontSize: 13,
                      color: _ink,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Recent strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F7FC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 58,
                  child: Text(
                    'Recent',
                    style: TextStyle(
                      fontSize: 13,
                      color: _muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Mastered 12 cards (88% accuracy)',
                    style: TextStyle(
                      fontSize: 13,
                      color: _ink,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Footer row: "View Profile →" link + "Updated 2h ago"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Semantics(
                  button: true,
                  label: 'View learner full profile',
                  child: InkWell(
                    key: const Key('live_session_view_profile_link'),
                    onTap: _openLearnerProfile,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            'View Profile',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _primaryPurple,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 15,
                          color: _primaryPurple,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Updated 2h ago',
                style: TextStyle(
                  fontSize: 11.5,
                  color: _subtleGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 6. BOTTOM SESSION CONTROLS BAR --------------------------------------------
  Widget _buildBottomSessionControls() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(10, 8, 10, bottomPadding > 0 ? bottomPadding + 8 : 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 1. Microphone Toggle
          _buildControlCircleButton(
            key: const Key('control_mic_toggle'),
            label: _isMicMuted ? 'Unmute mic' : 'Mute mic',
            icon: _isMicMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
            iconColor: _isMicMuted ? Colors.white : _ink,
            bgColor: _isMicMuted ? const Color(0xFFDC2626) : _lavenderLight,
            onTap: () {
              setState(() => _isMicMuted = !_isMicMuted);
              _showBriefToast(_isMicMuted ? 'Microphone muted' : 'Microphone active');
            },
          ),

          // 2. Camera Toggle (Red in Stitch screenshot)
          _buildControlCircleButton(
            key: const Key('control_camera_toggle'),
            label: _isCameraOff ? 'Turn camera on' : 'Turn camera off',
            icon: _isCameraOff ? Icons.videocam_off_rounded : Icons.videocam_rounded,
            iconColor: _isCameraOff ? Colors.white : _ink,
            bgColor: _isCameraOff ? const Color(0xFFDC2626) : _lavenderLight,
            onTap: () {
              setState(() => _isCameraOff = !_isCameraOff);
              _showBriefToast(_isCameraOff ? 'Camera paused' : 'Camera active');
            },
          ),

          // 3. Speaker / Volume Toggle
          _buildControlCircleButton(
            key: const Key('control_speaker_toggle'),
            label: _isSpeakerMuted ? 'Unmute speaker' : 'Mute speaker',
            icon: _isSpeakerMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
            iconColor: _ink,
            bgColor: _lavenderLight,
            onTap: () {
              setState(() => _isSpeakerMuted = !_isSpeakerMuted);
              _showBriefToast(_isSpeakerMuted ? 'Audio output muted' : 'Audio output standard');
            },
          ),

          // 4. Materials / Lesson Book Button (with green indicator dot)
          Stack(
            clipBehavior: Clip.none,
            children: [
              _buildControlCircleButton(
                key: const Key('control_materials_button'),
                label: 'Curriculum materials',
                icon: Icons.menu_book_rounded,
                iconColor: _primaryPurple,
                bgColor: _lavenderLight,
                onTap: _openMaterialsSheet,
              ),
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: _mintGreen,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),

          // 5. End Session Capsule Button
          Semantics(
            button: true,
            label: 'End live session',
            child: ElevatedButton.icon(
              key: const Key('control_end_session_button'),
              onPressed: _confirmEndSession,
              icon: const Icon(Icons.call_end_rounded, size: 18, color: Colors.white),
              label: const Text(
                'End',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _redEnd,
                elevation: 0,
                minimumSize: const Size(68, 44),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlCircleButton({
    required Key key,
    required String label,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        key: key,
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // INTERACTIVE TOOLS & MODALS
  // ---------------------------------------------------------------------------

  // Practice Cards Modal
  void _openPracticeCardsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final activeCard = _practiceCards[_currentCardIndex - 1];
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.style_outlined, color: _primaryPurple, size: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Practice Cards ($_currentCardIndex/$_totalCards)',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _ink),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Card presentation container
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: _lavenderBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFDDD6FE), width: 1.2),
                    ),
                    child: Column(
                      children: [
                        Text(
                          activeCard['cue'] ?? '',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _primaryPurple),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          activeCard['title'] ?? '',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: _ink),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '"${activeCard['word']}"',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: _muted),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Card navigation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: OutlinedButton.icon(
                          onPressed: _currentCardIndex > 1
                              ? () {
                                  setModalState(() => _currentCardIndex--);
                                  setState(() {});
                                }
                              : null,
                          icon: const Icon(Icons.arrow_back_rounded, size: 16),
                          label: const Text('Previous', overflow: TextOverflow.ellipsis),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: ElevatedButton.icon(
                          onPressed: _currentCardIndex < _totalCards
                              ? () {
                                  setModalState(() => _currentCardIndex++);
                                  setState(() {});
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryPurple,
                            foregroundColor: Colors.white,
                          ),
                          label: const Text('Next Card', overflow: TextOverflow.ellipsis),
                          icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Speech Pacer & Metronome Modal
  void _openPacerModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.speed_rounded, color: Color(0xFF0D9488), size: 24),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Speech Cadence Pacer',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _ink),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Assists learners with consonant cluster elongation and rhythmic pacing.',
                    style: TextStyle(fontSize: 12.5, color: _muted),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: Text(
                      '$_pacerBpm BPM',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF0D9488)),
                    ),
                  ),
                  Slider(
                    value: _pacerBpm.toDouble(),
                    min: 40,
                    max: 120,
                    divisions: 16,
                    activeColor: const Color(0xFF0D9488),
                    onChanged: (val) {
                      setModalState(() => _pacerBpm = val.round());
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      setModalState(() => _isPacerActive = !_isPacerActive);
                      setState(() {});
                      Navigator.pop(ctx);
                      _showBriefToast(_isPacerActive ? 'Pacer active at $_pacerBpm BPM' : 'Pacer stopped');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(_isPacerActive ? 'Stop Pacer' : 'Start Pacer'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Session Notes Modal
  void _openSessionNotesModal() {
    final noteController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.edit_note_rounded, color: _primaryPurple, size: 24),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Add Learning Support Note',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _ink),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Record pedagogical cues used, response latency, and phoneme milestones.',
                style: TextStyle(fontSize: 12.5, color: _muted),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: noteController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'e.g. Responded well to tactile pacing on /tr/ blend with minimal repetition…',
                  hintStyle: const TextStyle(fontSize: 13, color: _subtleGrey),
                  filled: true,
                  fillColor: const Color(0xFFF8F7FC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _showBriefToast('Learning support observation saved.');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Save Note', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );
      },
    );
  }

  // Praise Action
  void _sendPraiseToLearner() {
    setState(() => _praiseCount++);
    _showBriefToast('★ Praise sent to $_learnerName!');
  }

  // Star Reward Action
  void _giveStarReward() {
    setState(() => _praiseCount += 5);
    _showBriefToast('🌟 5 Practice Stars awarded to $_learnerName!');
  }

  // Materials & Curriculum Sheet
  void _openMaterialsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Curriculum Materials & Targets',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _ink),
              ),
              const SizedBox(height: 12),
              _buildMaterialRow('1. Consonant Cluster Articulation Deck (8 cards)', 'Active in session'),
              _buildMaterialRow('2. Multisensory Syllable Pacing Sheet', 'Ready to present'),
              _buildMaterialRow('3. Home Reinforcement Worksheet (PDF)', 'Shared with parent'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Done'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMaterialRow(String title, String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.description_outlined, color: _primaryPurple, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _ink)),
                Text(status, style: const TextStyle(fontSize: 11.5, color: _muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // NAVIGATION & ACTIONS
  // ---------------------------------------------------------------------------
  void _openLearnerProfile() {
    Navigator.pushNamed(
      context,
      AppRoutes.specialistLearnerDetail,
      arguments: _learnerId,
    );
  }

  void _showSessionOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.help_outline_rounded, color: _ink),
                title: const Text('Session Guidelines & Rubric'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showBriefToast('Evidence-informed DLD & Dyslexia protocol active.');
                },
              ),
              ListTile(
                leading: const Icon(Icons.lock_outline_rounded, color: _ink),
                title: const Text('Privacy & Consent Verification'),
                subtitle: const Text('Parental consent confirmed for this session'),
                onTap: () => Navigator.pop(ctx),
              ),
              ListTile(
                leading: Icon(_isAudioConnected ? Icons.wifi_rounded : Icons.wifi_off_rounded, color: _ink),
                title: Text(_isAudioConnected ? 'Simulate Audio Network Disconnect' : 'Reconnect Audio Channel'),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _isAudioConnected = !_isAudioConnected);
                  _showBriefToast(_isAudioConnected ? 'Audio connected' : 'Connection unstable / audio disconnected');
                },
              ),
              ListTile(
                leading: const Icon(Icons.call_end_rounded, color: _redEnd),
                title: const Text('End Live Support Session', style: TextStyle(color: _redEnd, fontWeight: FontWeight.w700)),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmEndSession();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSpecialistPresenceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Specialist Workspace Presence',
                  style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: _ink),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Connected as verified Speech-Language Specialist. Session is scoped strictly to authorized pedagogical goals.',
                  style: TextStyle(fontSize: 13, color: _muted),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // END SESSION & CONFIRMATION
  // ---------------------------------------------------------------------------
  void _confirmEndSession() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: _redEnd, size: 24),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'End this session?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _ink),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to end this live support session with $_learnerName? Your progress and card responses will be saved.',
          style: const TextStyle(fontSize: 13.5, color: _muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continue Session', style: TextStyle(color: _muted, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _lifecycle = _SessionLifecycle.completed);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _redEnd,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('End Session', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // COMPLETION VIEW
  // ---------------------------------------------------------------------------
  Widget _buildSessionCompletedView() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: Color(0xFFD1FAE5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF059669),
              size: 44,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Session Completed!',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _ink),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Live support session with $_learnerName concluded successfully.',
            style: const TextStyle(fontSize: 13.5, color: _muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Session stats summary box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _buildStatLine('Duration', _formatElapsed(_elapsedSeconds)),
                const Divider(height: 18),
                _buildStatLine('Focus Area', 'Consonant Clusters (/r/)'),
                const Divider(height: 18),
                _buildStatLine('Cards Practiced', '$_currentCardIndex of $_totalCards cards'),
                const Divider(height: 18),
                _buildStatLine('Praises Given', '$_praiseCount awards'),
              ],
            ),
          ),

          const SizedBox(height: 24),

          ElevatedButton.icon(
            key: const Key('completed_add_note_button'),
            onPressed: () {
              Navigator.pushNamed(
                context,
                AppRoutes.specialistSessionSummary,
                arguments: SpecialistSessionSummaryModel(
                  id: 'summary_$_learnerId',
                  sessionId: 'sess_$_learnerId',
                  learnerId: _learnerId,
                  learnerName: _learnerName,
                  learnerAgeBand: _learnerAgeBand,
                  sessionDate: 'Today, Oct 17',
                  sessionTime: '10:30 – 11:02 AM',
                  sessionDurationMinutes: (_elapsedSeconds / 60).round().clamp(1, 120),
                  sessionType: '1-to-1 Live Support',
                  targetFocus: '$_targetPhoneme Blends',
                  cardsCompleted: _currentCardIndex,
                  pacingRhythmPercentage: 88,
                  audioReflectionsCount: 1,
                  workingAreas: const [
                    'Phonics & Blends',
                    'Speaking & Pacing',
                    'Reading Aloud',
                  ],
                  outcome: 'great_progress',
                  nextPracticeFocus: 'Consonant Clusters (/rk/, /st/) in 2-syllable words',
                  followUpActions: const [
                    'Send tailored /r/ practice cards to Parent',
                    'Share session highlight with Teacher',
                  ],
                  nextScheduledSessionDate: 'Friday, Oct 25 • 10:30 AM',
                ),
              );
            },
            icon: const Icon(Icons.note_add_outlined),
            label: const Text('Add Session Note'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            key: const Key('completed_return_button'),
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Return to Caseload', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatLine(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: _muted)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: _ink),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TRANSITION & READY STATES
  // ---------------------------------------------------------------------------
  Widget _buildReadyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: _lavenderBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.videocam_rounded, color: _primaryPurple, size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              'Ready to start session with $_learnerName',
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: _ink),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Microphone, audio channel, and consonant cluster practice cards are ready.',
              style: TextStyle(fontSize: 13.5, color: _muted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => setState(() => _lifecycle = _SessionLifecycle.active),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Start Live Session', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTransitionState({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: _primaryPurple),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _ink),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 13, color: _muted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // RESTRICTED ROLE ACCESS VIEW
  // ---------------------------------------------------------------------------
  Widget _buildRestrictedRoleScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Support Session'),
        backgroundColor: Colors.white,
        foregroundColor: _ink,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shield_outlined, size: 54, color: _redEnd),
              const SizedBox(height: 16),
              const Text(
                'Specialist Access Scoped',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _ink),
              ),
              const SizedBox(height: 8),
              const Text(
                'Live support sessions can only be conducted by authorized Speech-Language Specialists.',
                style: TextStyle(fontSize: 13, color: _muted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryPurple,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Return to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBriefToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: _ink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

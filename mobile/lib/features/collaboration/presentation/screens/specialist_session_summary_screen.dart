import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/router/app_router.dart';
import '../../application/collaboration_providers.dart';
import '../../domain/models/collaboration_models.dart';

/// Specialist — Session Summary & Notes Screen.
///
/// Designed to visually and functionally match the Stitch reference:
/// * Top header with Back button, "Session Summary" title, "• DRAFT AUTO-SAVED" indicator,
///   more options menu, and Specialist avatar circle.
/// * Learner identification card with avatar, age band, "1-to-1 Live Support",
///   "✓ Completed" badge, and session date/time/duration.
/// * 2x2 Metric cards: Cards completed, Target sound focus, Pacing rhythm, Audio reflection.
/// * "What did you work on?": Interactive toggle chips for language pillars.
/// * "Session Observations & Notes": Multiline text field with character count,
///   "Lingua AI Co-Writer Ready" prompt assistance, and quick-tag inserters.
/// * "How did today's session go?": 4 interactive outcome cards (Great progress,
///   Good progress, Steady practice, Needs support).
/// * "Next Practice Focus": Focus target card with "Change focus" action.
/// * "Follow-up Actions": 4 interactive action items with checkboxes & counter.
/// * "Next Session Scheduled": Scheduled appointment summary with "Reschedule or edit".
/// * Bottom action area: Primary CTA "Save & Complete Summary" with clipboard icon
///   and arrow, plus secondary "Discard Draft or Return to Caseload".
/// * Unsaved changes guard: PopScope and discard confirmations.
/// * Responsive across 320px, 360px, 390px, 430px widths; keyboard handling.
class SpecialistSessionSummaryScreen extends ConsumerStatefulWidget {
  /// Session, learner, or summary argument passed via router.
  final dynamic sessionOrSummary;

  const SpecialistSessionSummaryScreen({
    super.key,
    this.sessionOrSummary,
  });

  @override
  ConsumerState<SpecialistSessionSummaryScreen> createState() =>
      _SpecialistSessionSummaryScreenState();
}

class _SpecialistSessionSummaryScreenState
    extends ConsumerState<SpecialistSessionSummaryScreen> {
  // Theme palette matching Stitch reference
  static const _ink = Color(0xFF1E1B4B);
  static const _primaryPurple = Color(0xFF3800B0);
  static const _deepPurpleBg = Color(0xFF310E68);
  static const _accentPurple = Color(0xFF7C3AED);
  static const _lavenderBg = Color(0xFFF1EFF9);
  static const _lavenderLight = Color(0xFFF5F3FF);
  static const _lavenderBorder = Color(0xFFEDE9FE);
  static const _cardBorder = Color(0xFFF1EFF9);
  static const _muted = Color(0xFF64748B);
  static const _subtleGrey = Color(0xFF94A3B8);
  static const _teal = Color(0xFF0D9488);
  static const _tealLight = Color(0xFFCCFBF1);
  static const _greenSuccess = Color(0xFF059669);
  static const _greenBadgeBg = Color(0xFFD1FAE5);
  static const _amber = Color(0xFFD97706);
  static const _amberLight = Color(0xFFFEF3C7);

  late final TextEditingController _notesController;
  late final SessionSummaryQuery _query;
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();

    String? sessionId;
    String? learnerId;
    final arg = widget.sessionOrSummary;
    if (arg is SpecialistSessionSummaryModel) {
      sessionId = arg.sessionId;
      learnerId = arg.learnerId;
    } else if (arg is SpecialistScheduleSession) {
      sessionId = arg.id;
      learnerId = arg.learnerId;
    } else if (arg is SpecialistCaseloadItem) {
      learnerId = arg.learnerId;
    } else if (arg is String) {
      learnerId = arg;
    }

    _query = SessionSummaryQuery(
      sessionId: sessionId,
      learnerId: learnerId,
      initialArg: arg,
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _syncNotesFromState(String notes) {
    if (!_isInit) {
      _notesController.text = notes;
      _isInit = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final summaryState = ref.watch(sessionSummaryNotifierProvider(_query));
    final notifier = ref.read(sessionSummaryNotifierProvider(_query).notifier);
    final summary = summaryState.summary;

    _syncNotesFromState(summary.notes);

    return PopScope(
      canPop: !summaryState.hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _confirmUnsavedChanges(context, notifier);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFBFBFE),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildTopHeader(context, summaryState),
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Learner & Session Overview Card
                      _buildLearnerOverviewCard(summary),
                      const SizedBox(height: 14),

                      // 2. 2x2 Metric Cards
                      _buildMetricGrid(summary),
                      const SizedBox(height: 14),

                      // 3. What did you work on? (Language Pillars)
                      _buildWorkingAreasCard(summary, notifier),
                      const SizedBox(height: 14),

                      // 4. Session Observations & Notes
                      _buildNotesCard(summary, notifier),
                      const SizedBox(height: 14),

                      // 5. How did today's session go? (Outcome)
                      _buildOutcomeCard(summary, notifier),
                      const SizedBox(height: 14),

                      // 6. Next Practice Focus
                      _buildNextPracticeCard(summary, notifier),
                      const SizedBox(height: 14),

                      // 7. Follow-up Actions
                      _buildFollowUpActionsCard(summary, notifier),
                      const SizedBox(height: 14),

                      // 8. Next Session Scheduled
                      _buildNextSessionCard(summary),
                      const SizedBox(height: 24),

                      // 9. Primary & Secondary CTA Buttons
                      _buildBottomActions(summaryState, notifier),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. TOP HEADER
  // ---------------------------------------------------------------------------
  Widget _buildTopHeader(BuildContext context, SessionSummaryState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF1EFF9), width: 1)),
      ),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: 'Back',
            child: IconButton(
              key: const Key('session_summary_back_button'),
              icon: const Icon(Icons.arrow_back_rounded, color: _ink, size: 22),
              onPressed: () {
                if (state.hasUnsavedChanges) {
                  _confirmUnsavedChanges(
                    context,
                    ref.read(sessionSummaryNotifierProvider(_query).notifier),
                  );
                } else {
                  Navigator.of(context).maybePop();
                }
              },
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Session Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: _ink,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: state.hasUnsavedChanges
                            ? _amber
                            : (state.isSaved ? _greenSuccess : _teal),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        state.isSaved
                            ? 'SAVED TO CASELOAD'
                            : (state.hasUnsavedChanges
                                ? 'UNSAVED CHANGES'
                                : 'DRAFT AUTO-SAVED'),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: state.hasUnsavedChanges
                              ? _amber
                              : (state.isSaved ? _greenSuccess : _teal),
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Semantics(
            button: true,
            label: 'More options',
            child: IconButton(
              key: const Key('session_summary_options_button'),
              icon: const Icon(Icons.more_vert_rounded, color: _ink, size: 22),
              onPressed: _showOptionsMenu,
            ),
          ),
          const SizedBox(width: 4),
          Semantics(
            label: 'Specialist profile',
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: _deepPurpleBg,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.person_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. LEARNER OVERVIEW CARD
  // ---------------------------------------------------------------------------
  Widget _buildLearnerOverviewCard(SpecialistSessionSummaryModel summary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Learner avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _lavenderBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: _lavenderBorder, width: 2),
                ),
                child: Center(
                  child: Text(
                    summary.learnerName.isNotEmpty
                        ? summary.learnerName[0].toUpperCase()
                        : 'A',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: _accentPurple,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.learnerName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: _ink,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _lavenderBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        summary.learnerAgeBand,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _muted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.verified_outlined,
                          size: 14,
                          color: _teal,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            summary.sessionType,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4B5563),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Completed badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _greenBadgeBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, size: 13, color: _greenSuccess),
                    SizedBox(width: 4),
                    Text(
                      'Completed',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: _greenSuccess,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1EFF9)),
          const SizedBox(height: 12),
          // Date & Time row
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 14, color: _accentPurple),
                  const SizedBox(width: 5),
                  Text(
                    summary.sessionDate,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                ],
              ),
              const Text(
                '•',
                style: TextStyle(fontSize: 12, color: _subtleGrey),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time_rounded, size: 14, color: _accentPurple),
                  const SizedBox(width: 5),
                  Text(
                    summary.sessionTime,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                ],
              ),
              const Text(
                '•',
                style: TextStyle(fontSize: 12, color: _subtleGrey),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _lavenderBorder,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${summary.sessionDurationMinutes} min',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _accentPurple,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. 2x2 METRIC CARDS
  // ---------------------------------------------------------------------------
  Widget _buildMetricGrid(SpecialistSessionSummaryModel summary) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                icon: Icons.layers_outlined,
                iconColor: _accentPurple,
                iconBg: _lavenderBorder,
                value: '${summary.cardsCompleted}',
                label: 'Cards completed',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                icon: Icons.record_voice_over_rounded,
                iconColor: _teal,
                iconBg: _tealLight,
                value: summary.targetFocus,
                label: 'Target sound focus',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                icon: Icons.speed_rounded,
                iconColor: _amber,
                iconBg: _amberLight,
                value: '${summary.pacingRhythmPercentage}%',
                label: 'Pacing rhythm',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                icon: Icons.mic_none_rounded,
                iconColor: _accentPurple,
                iconBg: _lavenderBorder,
                value: '${summary.audioReflectionsCount} Rec',
                label: 'Audio reflection',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: _ink,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: _muted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. WHAT DID YOU WORK ON? (LANGUAGE PILLARS)
  // ---------------------------------------------------------------------------
  Widget _buildWorkingAreasCard(
    SpecialistSessionSummaryModel summary,
    SessionSummaryNotifier notifier,
  ) {
    const allAreas = [
      'Phonics & Blends',
      'Speaking & Pacing',
      'Reading Aloud',
      'Vocabulary',
      'Listening Comprehension',
      'Word Rhythm',
      'Spelling Patterns',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'What did you work on?',
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w900,
                    color: _ink,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Tap to toggle',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: _teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Select language pillars exercised during this interaction',
            style: TextStyle(fontSize: 12.5, color: _muted),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: allAreas.map((area) {
              final isSelected = summary.workingAreas.contains(area);
              return Semantics(
                button: true,
                selected: isSelected,
                label: 'Toggle $area',
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => notifier.toggleWorkingArea(area),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? _deepPurpleBg : _lavenderBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? _deepPurpleBg : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isSelected ? Icons.check_rounded : Icons.add_rounded,
                            size: 15,
                            color: isSelected ? Colors.white : _primaryPurple,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              area,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                color: isSelected ? Colors.white : _primaryPurple,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. SESSION OBSERVATIONS & NOTES
  // ---------------------------------------------------------------------------
  Widget _buildNotesCard(
    SpecialistSessionSummaryModel summary,
    SessionSummaryNotifier notifier,
  ) {
    const quickTags = [
      '+ Great engagement',
      '+ Self-corrected pacing',
      '+ Needs visual prompt',
      '+ Parent guided',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Session Observations & Notes',
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w900,
                    color: _ink,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: _teal,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Live Draft',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: _teal,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Educational progress, strategies that worked, or areas needing gentle repetition.',
            style: TextStyle(fontSize: 12.5, color: _muted),
          ),
          const SizedBox(height: 12),

          // Multiline text input box
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8F7FC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  key: const Key('session_summary_notes_field'),
                  controller: _notesController,
                  minLines: 4,
                  maxLines: 7,
                  onChanged: (val) {
                    notifier.updateNotes(val);
                    setState(() {});
                  },
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: _ink,
                    height: 1.45,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: 'Add specific session notes here…',
                    hintStyle: TextStyle(
                      fontSize: 13.5,
                      color: _subtleGrey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Semantics(
                        button: true,
                        label: 'Use Lingua AI Co-Writer suggestion',
                        child: InkWell(
                          onTap: () => _showAiCoWriterSuggestions(notifier),
                          borderRadius: BorderRadius.circular(6),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.auto_awesome_rounded, size: 14, color: _accentPurple),
                                SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'Lingua AI Co-Writer Ready',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: _accentPurple,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_notesController.text.length} characters',
                      style: const TextStyle(
                        fontSize: 11,
                        color: _subtleGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),
          const Text(
            'TAP TO INSERT NOTE TAG:',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: _muted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: quickTags.map((tag) {
              return Semantics(
                button: true,
                label: 'Insert $tag into notes',
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      notifier.appendNoteTag(tag);
                      _notesController.text = ref
                          .read(sessionSummaryNotifierProvider(_query))
                          .summary
                          .notes;
                      setState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _lavenderBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: _primaryPurple,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 6. HOW DID TODAY'S SESSION GO? (OUTCOME)
  // ---------------------------------------------------------------------------
  Widget _buildOutcomeCard(
    SpecialistSessionSummaryModel summary,
    SessionSummaryNotifier notifier,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "How did today's session go?",
            style: TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w900,
              color: _ink,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Encouraging baseline to guide the learner's customized pathway",
            style: TextStyle(fontSize: 12.5, color: _muted),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildOutcomeItem(
                  keyString: 'outcome_great_progress',
                  code: 'great_progress',
                  emoji: '☀️',
                  title: 'Great progress',
                  subtitle: 'Exceeded key target',
                  isSelected: summary.outcome == 'great_progress',
                  onTap: () => notifier.updateOutcome('great_progress'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildOutcomeItem(
                  keyString: 'outcome_good_progress',
                  code: 'good_progress',
                  emoji: '👍',
                  title: 'Good progress',
                  subtitle: 'Met session goals',
                  isSelected: summary.outcome == 'good_progress',
                  onTap: () => notifier.updateOutcome('good_progress'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildOutcomeItem(
                  keyString: 'outcome_steady_practice',
                  code: 'steady_practice',
                  emoji: '🌱',
                  title: 'Steady practice',
                  subtitle: 'Reinforcing rhythm',
                  isSelected: summary.outcome == 'steady_practice',
                  onTap: () => notifier.updateOutcome('steady_practice'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildOutcomeItem(
                  keyString: 'outcome_needs_support',
                  code: 'needs_support',
                  emoji: '🤲',
                  title: 'Needs support',
                  subtitle: 'Break into parts',
                  isSelected: summary.outcome == 'needs_support',
                  onTap: () => notifier.updateOutcome('needs_support'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOutcomeItem({
    required String keyString,
    required String code,
    required String emoji,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: '$title: $subtitle',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key(keyString),
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? _lavenderLight : const Color(0xFFF8F7FC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? _primaryPurple : const Color(0xFFE2E8F0),
                width: isSelected ? 1.6 : 1.0,
              ),
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: isSelected ? _primaryPurple : _ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: _muted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                if (isSelected)
                  const Positioned(
                    top: 0,
                    right: 0,
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: _primaryPurple,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 7. NEXT PRACTICE FOCUS
  // ---------------------------------------------------------------------------
  Widget _buildNextPracticeCard(
    SpecialistSessionSummaryModel summary,
    SessionSummaryNotifier notifier,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.flag_rounded, size: 18, color: _primaryPurple),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Next Practice Focus',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w900,
                          color: _ink,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Semantics(
                button: true,
                label: 'Change practice focus',
                child: InkWell(
                  key: const Key('change_focus_button'),
                  onTap: () => _showChangeFocusDialog(summary, notifier),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _lavenderBorder,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Change focus',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: _primaryPurple,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F7FC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2DD4BF),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      'Az',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        summary.nextPracticeFocus,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        summary.nextPracticeDescription,
                        style: const TextStyle(
                          fontSize: 12,
                          color: _muted,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 8. FOLLOW-UP ACTIONS
  // ---------------------------------------------------------------------------
  Widget _buildFollowUpActionsCard(
    SpecialistSessionSummaryModel summary,
    SessionSummaryNotifier notifier,
  ) {
    final actionsList = [
      {
        'key': 'Send tailored /r/ practice cards to Parent',
        'title': 'Send tailored /r/ practice cards to Parent',
        'subtitle': 'Recipients: Priya Mehta (Mother)',
      },
      {
        'key': 'Share session highlight with Teacher',
        'title': 'Share session highlight with Teacher',
        'subtitle': 'Classroom lead: Mrs. Davies (Grade 4)',
      },
      {
        'key': 'Schedule next live practice check-in',
        'title': 'Schedule next live practice check-in',
        'subtitle': 'Recommend within 7 calendar days',
      },
      {
        'key': 'Update Caseload Milestone Tracker',
        'title': 'Update Caseload Milestone Tracker',
        'subtitle': 'Mark Step 4: Final Consonant Consistencies',
      },
    ];

    final selectedCount = summary.followUpActions.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Follow-up Actions',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w900,
                    color: _ink,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$selectedCount of ${actionsList.length} selected',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: _muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...actionsList.map((item) {
            final key = item['key']!;
            final isChecked = summary.followUpActions.contains(key);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Semantics(
                button: true,
                selected: isChecked,
                label: 'Toggle ${item['title']}',
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => notifier.toggleFollowUpAction(key),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F7FC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isChecked ? _lavenderBorder : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: isChecked ? _primaryPurple : Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isChecked ? _primaryPurple : const Color(0xFFCBD5E1),
                                width: 1.5,
                              ),
                            ),
                            child: isChecked
                                ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title']!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: _ink,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item['subtitle']!,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: _muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 9. NEXT SESSION SCHEDULED
  // ---------------------------------------------------------------------------
  Widget _buildNextSessionCard(SpecialistSessionSummaryModel summary) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF2DD4BF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(Icons.calendar_month_rounded, color: Colors.white, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'NEXT SESSION SCHEDULED',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        color: _teal,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      summary.nextScheduledSessionDate ?? 'Friday, Oct 25 • 10:30 AM',
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      summary.nextScheduledSessionDescription ??
                          'Practice Check-in • 20 min live video',
                      style: const TextStyle(
                        fontSize: 12,
                        color: _muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Semantics(
              button: true,
              label: 'Reschedule or edit next session',
              child: TextButton.icon(
                key: const Key('reschedule_next_session_button'),
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.specialistSchedule);
                },
                icon: const Icon(Icons.edit_calendar_outlined, size: 14, color: _primaryPurple),
                label: const Text(
                  'Reschedule or edit',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _primaryPurple,
                  ),
                ),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 10. BOTTOM ACTIONS & SAVE
  // ---------------------------------------------------------------------------
  Widget _buildBottomActions(
    SessionSummaryState state,
    SessionSummaryNotifier notifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEF4444)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Color(0xFFB91C1C), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.errorMessage!,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFB91C1C),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Primary Save CTA
        Semantics(
          button: true,
          label: 'Save and complete summary',
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              key: const Key('save_summary_primary_button'),
              onPressed: state.isSaving
                  ? null
                  : () async {
                      final success = await notifier.saveSummary();
                      if (success && mounted) {
                        _showBriefToast('✓ Session summary saved successfully.');
                        // Navigate back or to Learner Detail
                        Future.delayed(const Duration(milliseconds: 600), () {
                          if (mounted && Navigator.of(context).canPop()) {
                            Navigator.of(context).pop(true);
                          }
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryPurple,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _primaryPurple.withValues(alpha: 0.6),
                elevation: 3,
                shadowColor: _primaryPurple.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
              child: state.isSaving
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Saving summary…',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.assignment_turned_in_rounded, size: 20),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Save & Complete Summary',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Secondary CTA: Discard Draft or Return to Caseload
        Center(
          child: TextButton(
            key: const Key('discard_draft_button'),
            onPressed: () {
              if (state.hasUnsavedChanges) {
                _confirmUnsavedChanges(context, notifier);
              } else {
                Navigator.of(context).maybePop();
              }
            },
            child: const Text(
              'Discard Draft or Return to Caseload',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: _muted,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // HELPER MODALS & DIALOGS
  // ---------------------------------------------------------------------------
  void _confirmUnsavedChanges(BuildContext context, SessionSummaryNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Save your session notes?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _ink),
        ),
        content: const Text(
          'You have unsaved observations in this session summary. Would you like to keep editing, discard, or save now?',
          style: TextStyle(fontSize: 13.5, color: _muted),
        ),
        actions: [
          TextButton(
            key: const Key('dialog_discard_button'),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).pop();
            },
            child: const Text(
              'Discard',
              style: TextStyle(color: Color(0xFFB91C1C), fontWeight: FontWeight.w700),
            ),
          ),
          TextButton(
            key: const Key('dialog_keep_editing_button'),
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Keep Editing',
              style: TextStyle(color: _muted, fontWeight: FontWeight.w700),
            ),
          ),
          ElevatedButton(
            key: const Key('dialog_save_button'),
            onPressed: () async {
              final nav = Navigator.of(context);
              Navigator.pop(ctx);
              final success = await notifier.saveSummary();
              if (success && mounted) {
                _showBriefToast('✓ Session summary saved.');
                nav.maybePop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showChangeFocusDialog(
    SpecialistSessionSummaryModel summary,
    SessionSummaryNotifier notifier,
  ) {
    final focusController = TextEditingController(text: summary.nextPracticeFocus);
    final descController = TextEditingController(text: summary.nextPracticeDescription);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
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
                'Customize Next Practice Focus',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: _ink),
              ),
              const SizedBox(height: 6),
              const Text(
                'Set the target phonemes, words, or pacing activities for home reinforcement.',
                style: TextStyle(fontSize: 12.5, color: _muted),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: focusController,
                decoration: InputDecoration(
                  labelText: 'Target Focus Title',
                  labelStyle: const TextStyle(fontSize: 13, color: _muted),
                  filled: true,
                  fillColor: const Color(0xFFF8F7FC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Home Deck Instructions',
                  labelStyle: const TextStyle(fontSize: 13, color: _muted),
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
                  notifier.updateNextPracticeFocus(
                    focusController.text.trim(),
                    description: descController.text.trim(),
                  );
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Update Practice Focus', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAiCoWriterSuggestions(SessionSummaryNotifier notifier) {
    final suggestions = [
      'Responded well to multisensory finger-tapping cues on initial /r/ blends with steady cadence.',
      'Showed high self-correction on consonant clusters (/rk/, /st/) during reading aloud practice.',
      'Demonstrated 88% pacing consistency across 8 curriculum articulation cards with minimal prompts.',
      'Maintained excellent focus throughout the 1-to-1 session; parent guided reinforcement recommended.',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
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
                const Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: _accentPurple, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Lingua AI Pedagogical Co-Writer',
                      style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900, color: _ink),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Select an evidence-based, non-diagnostic observation template to insert:',
                  style: TextStyle(fontSize: 12.5, color: _muted),
                ),
                const SizedBox(height: 14),
                ...suggestions.map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        notifier.appendNoteTag(s);
                        _notesController.text = ref
                            .read(sessionSummaryNotifierProvider(_query))
                            .summary
                            .notes;
                        setState(() {});
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _lavenderBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          s,
                          style: const TextStyle(fontSize: 12.5, color: _ink, height: 1.35),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showOptionsMenu() {
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
                leading: const Icon(Icons.person_outline_rounded, color: _ink),
                title: const Text('View Learner Profile'),
                onTap: () {
                  Navigator.pop(ctx);
                  final summary = ref.read(sessionSummaryNotifierProvider(_query)).summary;
                  Navigator.pushNamed(
                    context,
                    AppRoutes.specialistLearnerDetail,
                    arguments: summary.learnerId,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_month_outlined, color: _ink),
                title: const Text('View Schedule'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, AppRoutes.specialistSchedule);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_outlined, color: _ink),
                title: const Text('Export Session Summary as PDF'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showBriefToast('PDF generation scheduled.');
                },
              ),
            ],
          ),
        );
      },
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingua_ai/features/collaboration/application/collaboration_providers.dart';

/// Active display mode for the Learner Report screen
/// Supports Child (Aarav), Adult (Maya), No Activity (Liam/Empty), and Skeleton loading states.
enum ReportViewMode {
  child,
  adult,
  noActivity,
  skeleton,
}

/// LINGUA AI — Specialist → Learner Report & Progress Screen
///
/// Faithful Flutter implementation matching the Stitch visual design reference:
/// 1. Top App Bar: Compact back button, bold 'Learner Report', share, options & specialist avatar.
/// 2. Mode Switcher: Interactive pills [Child (Aarav)], [Adult (Maya)], [No Activity], [Skeleton].
/// 3. Learner Identity / Context Card: Photo avatar, name, age, connection row, and Active badge.
/// 4. Time Range Filter: Capsule container with '7 Days', '30 Days', '3 Months'.
/// 5. 3 Summary Metrics: Sessions, Audio Time, Active Skills in clean rounded cards.
/// 6. Practice Activity Card: Minutes per week bubble chart with weekly rhythm indicator and trend badge.
/// 7. Skill Progress Section: Horizontal skill level bars, subtext, percentages, and improvement banner.
/// 8. Recent Sessions: Compact session list with timestamps and completed badges.
/// 9. Specialist Reflection Card: Dr. Maya Lin reflection quote with view full reflection link.
/// 10. Action Buttons: 'Share Report with Circle' and 'Download PDF Summary' with security footnote.
class LearnerReportScreen extends ConsumerStatefulWidget {
  final String? learnerId;
  final ReportViewMode? initialMode;

  const LearnerReportScreen({
    super.key,
    this.learnerId,
    this.initialMode,
  });

  @override
  ConsumerState<LearnerReportScreen> createState() => _LearnerReportScreenState();
}

class _LearnerReportScreenState extends ConsumerState<LearnerReportScreen> {
  late ReportViewMode _currentMode;
  String _selectedPeriod = '30 Days';

  @override
  void initState() {
    super.initState();
    if (widget.initialMode != null) {
      _currentMode = widget.initialMode!;
    } else if (widget.learnerId == 'lr-2') {
      _currentMode = ReportViewMode.adult;
    } else {
      _currentMode = ReportViewMode.child;
    }
  }

  void _onSelectMode(ReportViewMode mode) {
    setState(() {
      _currentMode = mode;
    });
  }

  void _onSelectPeriod(String period) {
    setState(() {
      _selectedPeriod = period;
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeLearnerId = switch (_currentMode) {
      ReportViewMode.child => widget.learnerId ?? 'lr-1',
      ReportViewMode.adult => 'lr-2',
      ReportViewMode.noActivity => 'lr-3',
      ReportViewMode.skeleton => widget.learnerId ?? 'lr-1',
    };

    final learnerDetailAsync = ref.watch(specialistLearnerDetailProvider(activeLearnerId));

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9FD),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top App Bar
            _buildTopAppBar(context),

            // 2. Interactive Mode Switcher Pills
            _buildModeSwitcher(),

            // 3. Scrollable Report Body
            Expanded(
              child: _currentMode == ReportViewMode.skeleton
                  ? _buildSkeletonBody()
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Learner Context Card
                          _buildLearnerContextCard(learnerDetailAsync),
                          const SizedBox(height: 12),

                          // Time Range Selector
                          _buildTimeRangeSelector(),
                          const SizedBox(height: 14),

                          // 3 Metric Cards Row
                          _buildSummaryMetricsRow(),
                          const SizedBox(height: 14),

                          // Practice Activity Card
                          _buildPracticeActivityCard(),
                          const SizedBox(height: 16),

                          // Skill Progress Section
                          _buildSkillProgressSection(),
                          const SizedBox(height: 16),

                          // Recent Sessions Section
                          _buildRecentSessionsSection(),
                          const SizedBox(height: 16),

                          // Latest Reflection Card
                          _buildReflectionCard(context),
                          const SizedBox(height: 20),

                          // Primary & Secondary Actions
                          _buildActionButtons(context),
                          const SizedBox(height: 14),

                          // Security / Privacy Footnote
                          _buildSecurityFootnote(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. TOP APP BAR
  // ---------------------------------------------------------------------------
  Widget _buildTopAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
      color: const Color(0xFFFAF9FD),
      child: Row(
        children: [
          // Circular Back Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(22),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4318D1).withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Color(0xFF1E1B4B),
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Title
          const Expanded(
            child: Text(
              'Learner Report',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E1B4B),
                letterSpacing: -0.2,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),

          // Share Action
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sharing learner progress summary with support circle...'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(
              Icons.share_outlined,
              color: Color(0xFF475569),
              size: 20,
            ),
            tooltip: 'Share',
            splashRadius: 20,
          ),

          // More Options Action
          IconButton(
            onPressed: () => _showMoreOptionsModal(context),
            icon: const Icon(
              Icons.more_vert_rounded,
              color: Color(0xFF475569),
              size: 22,
            ),
            tooltip: 'More options',
            splashRadius: 20,
          ),

          // Specialist User Avatar
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF4318D1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4318D1).withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 19,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. MODE SWITCHER PILLS (Child, Adult, No Activity, Skeleton)
  // ---------------------------------------------------------------------------
  Widget _buildModeSwitcher() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE9FE).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildModePill('Child (Aarav)', ReportViewMode.child),
            _buildModePill('Adult (Maya)', ReportViewMode.adult),
            _buildModePill('No Activity', ReportViewMode.noActivity),
            _buildModePill('Skeleton', ReportViewMode.skeleton),
          ],
        ),
      ),
    );
  }

  Widget _buildModePill(String label, ReportViewMode mode) {
    final isSelected = _currentMode == mode;
    return GestureDetector(
      onTap: () => _onSelectMode(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 3.0),
        padding: const EdgeInsets.symmetric(horizontal: 13.0, vertical: 7.0),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4318D1) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF4318D1).withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.0,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF4C4964),
            letterSpacing: 0.1,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. LEARNER IDENTITY / CONTEXT CARD
  // ---------------------------------------------------------------------------
  Widget _buildLearnerContextCard(AsyncValue<Map<String, dynamic>> detailAsync) {
    final isChild = _currentMode == ReportViewMode.child;
    final isAdult = _currentMode == ReportViewMode.adult;
    final isNoActivity = _currentMode == ReportViewMode.noActivity;

    final name = isChild
        ? 'Aarav Mehta'
        : isAdult
            ? 'Maya S.'
            : 'Liam K.';

    final subtitle = isChild
        ? 'Child • 10 years old'
        : isAdult
            ? 'Adult • Self-connected learner'
            : 'Teen • 14 years old';

    final connectionText = isChild
        ? 'Parent connected: Priya M.'
        : isAdult
            ? 'Self-managed practice'
            : 'Parent & Teacher connected';

    final statusText = isNoActivity ? 'Pending' : 'Active';

    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4318D1).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar with Active Dot
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: isChild
                      ? const Color(0xFFFDE68A)
                      : isAdult
                          ? const Color(0xFFA7F3D0)
                          : const Color(0xFFE9D5FF),
                  image: isChild
                      ? const DecorationImage(
                          image: AssetImage('assets/images/characters/echo_fox.png'),
                          fit: BoxFit.cover,
                          onError: _fallbackAvatarError,
                        )
                      : null,
                ),
                child: Center(
                  child: Text(
                    isChild
                        ? 'AM'
                        : isAdult
                            ? 'MS'
                            : 'LK',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isChild
                          ? const Color(0xFF92400E)
                          : isAdult
                              ? const Color(0xFF065F46)
                              : const Color(0xFF6B21A8),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -1,
                right: -1,
                child: Container(
                  width: 13,
                  height: 13,
                  decoration: BoxDecoration(
                    color: isNoActivity ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // Name, Age and Connection Row
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E1B4B),
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      isChild ? Icons.favorite_border_rounded : Icons.person_outline_rounded,
                      size: 13,
                      color: const Color(0xFF6366F1),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        connectionText,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4C4964),
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

          // Status Badge (Active / Pending)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
            decoration: BoxDecoration(
              color: isNoActivity
                  ? const Color(0xFFFEF3C7)
                  : const Color(0xFFE6FFFA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isNoActivity ? const Color(0xFFD97706) : const Color(0xFF0D9488),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isNoActivity ? const Color(0xFFB45309) : const Color(0xFF0D9488),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static void _fallbackAvatarError(Object exception, StackTrace? stackTrace) {}

  // ---------------------------------------------------------------------------
  // 4. TIME RANGE SELECTOR
  // ---------------------------------------------------------------------------
  Widget _buildTimeRangeSelector() {
    final options = ['7 Days', '30 Days', '3 Months'];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F0FB),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: options.map((period) {
          final isSelected = _selectedPeriod == period;
          return Expanded(
            child: GestureDetector(
              onTap: () => _onSelectPeriod(period),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF4318D1).withValues(alpha: 0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    period,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? const Color(0xFF4318D1) : const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. 3 SUMMARY METRICS ROW
  // ---------------------------------------------------------------------------
  Widget _buildSummaryMetricsRow() {
    final isChild = _currentMode == ReportViewMode.child;
    final isNoActivity = _currentMode == ReportViewMode.noActivity;

    final sessionsValue = isNoActivity ? '0' : (isChild ? '12' : '18');
    final audioTimeValue = isNoActivity ? '0m' : (isChild ? '4h 20m' : '6h 40m');
    final activeSkillsValue = isNoActivity ? '0 Active' : (isChild ? '3 Active' : '4 Active');

    return Row(
      children: [
        // Metric 1: Sessions
        Expanded(
          child: _buildMetricTile(
            icon: Icons.headphones_rounded,
            iconColor: const Color(0xFF6366F1),
            iconBgColor: const Color(0xFFEDE9FE),
            value: sessionsValue,
            label: 'Sessions',
          ),
        ),
        const SizedBox(width: 8),

        // Metric 2: Audio Time
        Expanded(
          child: _buildMetricTile(
            icon: Icons.access_time_filled_rounded,
            iconColor: const Color(0xFF0D9488),
            iconBgColor: const Color(0xFFCCFBF1),
            value: audioTimeValue,
            label: 'Audio Time',
          ),
        ),
        const SizedBox(width: 8),

        // Metric 3: Active Skills
        Expanded(
          child: _buildMetricTile(
            icon: Icons.workspace_premium_rounded,
            iconColor: const Color(0xFFD97706),
            iconBgColor: const Color(0xFFFEF3C7),
            value: activeSkillsValue,
            label: 'Skills',
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4318D1).withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E1B4B),
              ),
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 6. PRACTICE ACTIVITY CARD (Bubble Chart & Weekly Rhythm)
  // ---------------------------------------------------------------------------
  Widget _buildPracticeActivityCard() {
    final isChild = _currentMode == ReportViewMode.child;
    final isAdult = _currentMode == ReportViewMode.adult;
    final isNoActivity = _currentMode == ReportViewMode.noActivity;

    final trendText = isNoActivity ? '0%' : (isChild ? '+18%' : '+24%');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4318D1).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Practice Activity',
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E1B4B),
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Minutes per week ($_selectedPeriod)',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Trend Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isNoActivity ? const Color(0xFFF1F5F9) : const Color(0xFFE6FFFA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isNoActivity ? Icons.horizontal_rule_rounded : Icons.trending_up_rounded,
                      size: 13,
                      color: isNoActivity ? const Color(0xFF64748B) : const Color(0xFF0D9488),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      trendText,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: isNoActivity ? const Color(0xFF64748B) : const Color(0xFF0D9488),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Activity Visualization (4 Bubble Weeks or Empty State)
          if (isNoActivity) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F7FD),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Column(
                children: [
                  Icon(Icons.schedule_rounded, color: Color(0xFF94A3B8), size: 28),
                  SizedBox(height: 8),
                  Text(
                    'No practice sessions logged yet',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF334155),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Activity minutes and weekly rhythm will track automatically as practice begins.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // 4 Weeks Bubble Chart
            _buildBubbleChart(isChild: isChild, isAdult: isAdult),
            const SizedBox(height: 14),

            // Weekly Rhythm Bar
            _buildWeeklyRhythmBar(isChild: isChild),
          ],
        ],
      ),
    );
  }

  Widget _buildBubbleChart({required bool isChild, required bool isAdult}) {
    final weekData = isChild
        ? [
            {'label': 'W1', 'mins': '45m', 'size': 44.0, 'color': const Color(0xFFEDE9FE)},
            {'label': 'W2', 'mins': '60m', 'size': 54.0, 'color': const Color(0xFFE0E7FF)},
            {'label': 'W3', 'mins': '75m', 'size': 64.0, 'color': const Color(0xFFDDD6FE)},
            {'label': 'W4 (Now)', 'mins': '80m', 'size': 74.0, 'color': const Color(0xFF4318D1)},
          ]
        : [
            {'label': 'W1', 'mins': '60m', 'size': 46.0, 'color': const Color(0xFFEDE9FE)},
            {'label': 'W2', 'mins': '85m', 'size': 56.0, 'color': const Color(0xFFE0E7FF)},
            {'label': 'W3', 'mins': '105m', 'size': 66.0, 'color': const Color(0xFFDDD6FE)},
            {'label': 'W4 (Now)', 'mins': '120m', 'size': 76.0, 'color': const Color(0xFF4318D1)},
          ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: weekData.map((w) {
        final isLatest = w['label'] == 'W4 (Now)';
        final size = w['size'] as double;
        final color = w['color'] as Color;
        final mins = w['mins'] as String;
        final label = w['label'] as String;

        return Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                mins,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isLatest ? FontWeight.w800 : FontWeight.w600,
                  color: isLatest ? const Color(0xFF4318D1) : const Color(0xFF64748B),
                ),
                maxLines: 1,
              ),
              const SizedBox(height: 6),
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: isLatest
                      ? [
                          BoxShadow(
                            color: const Color(0xFF4318D1).withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isLatest ? FontWeight.w800 : FontWeight.w600,
                    color: isLatest ? const Color(0xFF4318D1) : const Color(0xFF475569),
                  ),
                  maxLines: 1,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWeeklyRhythmBar({required bool isChild}) {
    // 7 days (M, T, W, T, F, S, S)
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    // Active states matching Stitch screenshot
    final activeStatus = isChild
        ? [true, false, true, true, false, true, false]
        : [true, true, false, true, true, false, false];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7FD),
        borderRadius: BorderRadius.circular(16),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Color(0xFFFEF3C7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.stars_rounded, color: Color(0xFFD97706), size: 14),
            ),
            const SizedBox(width: 6),
            const Text(
              'Weekly Rhythm:',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E1B4B),
              ),
            ),
            const SizedBox(width: 8),
            ...List.generate(days.length, (i) {
              final isActive = activeStatus[i];
              final isWeekend = i >= 5;
              final activeBg = isWeekend
                  ? const Color(0xFF0D9488)
                  : const Color(0xFF4318D1);

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isActive ? activeBg : const Color(0xFFE2E8F0),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    days[i],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isActive ? Colors.white : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 7. SKILL PROGRESS SECTION
  // ---------------------------------------------------------------------------
  Widget _buildSkillProgressSection() {
    final isChild = _currentMode == ReportViewMode.child;
    final isNoActivity = _currentMode == ReportViewMode.noActivity;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Skill Progress',
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E1B4B),
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Validated through guided audio practice',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFEDE9FE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.insights_rounded,
                color: Color(0xFF4318D1),
                size: 18,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (isNoActivity) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: Color(0xFF94A3B8), size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Progress indicators will appear after completing guided practice sessions.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else if (isChild) ...[
          // Skill 1: Phonological Awareness
          _buildSkillCard(
            title: 'Phonological Awareness',
            level: 'Level 4',
            levelColor: const Color(0xFF4318D1),
            levelBg: const Color(0xFFEDE9FE),
            progress: 0.78,
            progressColor: const Color(0xFF4318D1),
            subtext: 'Strong initial consonant cluster recognition',
            percentage: '78%',
            icon: Icons.record_voice_over_rounded,
            iconBg: const Color(0xFFEDE9FE),
            iconColor: const Color(0xFF4318D1),
          ),
          const SizedBox(height: 10),

          // Skill 2: Reading Fluency & Pacing
          _buildSkillCard(
            title: 'Reading Fluency & Pacing',
            level: 'Level 3',
            levelColor: const Color(0xFF0D9488),
            levelBg: const Color(0xFFCCFBF1),
            progress: 0.65,
            progressColor: const Color(0xFF0D9488),
            subtext: 'Cadence consistency improved by 14%',
            percentage: '65%',
            icon: Icons.menu_book_rounded,
            iconBg: const Color(0xFFCCFBF1),
            iconColor: const Color(0xFF0D9488),
          ),
          const SizedBox(height: 10),

          // Skill 3: Syllable Segmentation
          _buildSkillCard(
            title: 'Syllable Segmentation',
            level: 'Level 2',
            levelColor: const Color(0xFFD97706),
            levelBg: const Color(0xFFFEF3C7),
            progress: 0.52,
            progressColor: const Color(0xFFF59E0B),
            subtext: 'Multi-syllable word breakdown in progress',
            percentage: '52%',
            icon: Icons.auto_stories_rounded,
            iconBg: const Color(0xFFFEF3C7),
            iconColor: const Color(0xFFD97706),
          ),
          const SizedBox(height: 10),

          // Steady Improvement Banner
          _buildImprovementBanner(
            title: 'Steady Improvement:',
            message: 'Practice consistency increased nicely with parent co-play routine this week.',
          ),
        ] else ...[
          // Adult Skills
          _buildSkillCard(
            title: 'Presentation Pacing & Cadence',
            level: 'Level 4',
            levelColor: const Color(0xFF4318D1),
            levelBg: const Color(0xFFEDE9FE),
            progress: 0.84,
            progressColor: const Color(0xFF4318D1),
            subtext: 'Average 125 WPM with strategic 2-second pauses',
            percentage: '84%',
            icon: Icons.record_voice_over_rounded,
            iconBg: const Color(0xFFEDE9FE),
            iconColor: const Color(0xFF4318D1),
          ),
          const SizedBox(height: 10),

          _buildSkillCard(
            title: 'Vocal Projection & Pitch Modulation',
            level: 'Level 3',
            levelColor: const Color(0xFF0D9488),
            levelBg: const Color(0xFFCCFBF1),
            progress: 0.72,
            progressColor: const Color(0xFF0D9488),
            subtext: 'Audible resonance across larger meeting spaces',
            percentage: '72%',
            icon: Icons.volume_up_rounded,
            iconBg: const Color(0xFFCCFBF1),
            iconColor: const Color(0xFF0D9488),
          ),
          const SizedBox(height: 10),

          _buildSkillCard(
            title: 'Filler Word Reduction',
            level: 'Level 3',
            levelColor: const Color(0xFFD97706),
            levelBg: const Color(0xFFFEF3C7),
            progress: 0.68,
            progressColor: const Color(0xFFF59E0B),
            subtext: 'Filler frequency decreased from 8.2% to 2.4%',
            percentage: '68%',
            icon: Icons.speed_rounded,
            iconBg: const Color(0xFFFEF3C7),
            iconColor: const Color(0xFFD97706),
          ),
          const SizedBox(height: 10),

          _buildImprovementBanner(
            title: 'Steady Improvement:',
            message: 'Significant reduction in filler words during simulated boardroom reviews.',
          ),
        ],
      ],
    );
  }

  Widget _buildSkillCard({
    required String title,
    required String level,
    required Color levelColor,
    required Color levelBg,
    required double progress,
    required Color progressColor,
    required String subtext,
    required String percentage,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4318D1).withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Skill Header Row
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E1B4B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: levelBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  level,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: levelColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Horizontal Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6.5,
              backgroundColor: const Color(0xFFF1F0FB),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          const SizedBox(height: 8),

          // Subtext Row + Percentage
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  subtext,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                percentage,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: progressColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImprovementBanner({required String title, required String message}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDD6FE).withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: Color(0xFF4318D1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_graph_rounded,
              color: Colors.white,
              size: 15,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF334155),
                  height: 1.35,
                ),
                children: [
                  TextSpan(
                    text: '$title ',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF4318D1),
                    ),
                  ),
                  TextSpan(text: message),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 8. RECENT SESSIONS SECTION
  // ---------------------------------------------------------------------------
  Widget _buildRecentSessionsSection() {
    final isNoActivity = _currentMode == ReportViewMode.noActivity;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Recent Sessions',
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E1B4B),
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Viewing all past session logs...')),
                );
              },
              child: const Row(
                children: [
                  Text(
                    'View all',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4318D1),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: Color(0xFF4318D1),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (isNoActivity) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Text(
              'No completed sessions in this period.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ),
        ] else ...[
          // Session 1: Live Support Session
          _buildSessionTile(
            icon: Icons.videocam_outlined,
            title: 'Live Support Session',
            subtitle: 'Today • 30 mins',
          ),
          const SizedBox(height: 8),

          // Session 2: Practice Review
          _buildSessionTile(
            icon: Icons.mic_none_rounded,
            title: 'Practice Review',
            subtitle: 'Yesterday • 20 mins',
          ),
        ],
      ],
    );
  }

  Widget _buildSessionTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4318D1).withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F0FB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF4318D1), size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E1B4B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Completed Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE6FFFA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_rounded, color: Color(0xFF0D9488), size: 12),
                SizedBox(width: 3),
                Text(
                  'Completed',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0D9488),
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
  // 9. SPECIALIST REFLECTION CARD
  // ---------------------------------------------------------------------------
  Widget _buildReflectionCard(BuildContext context) {
    final isChild = _currentMode == ReportViewMode.child;
    final isAdult = _currentMode == ReportViewMode.adult;

    final quote = isChild
        ? '“Aarav showed noticeable confidence during syllable pacing games. Self-corrected initial /r/ blends with minimal prompting.”'
        : isAdult
            ? '“Maya demonstrated excellent pacing control under simulated time pressure. Pauses were purposeful and natural.”'
            : '“Initial observation recommended to establish baseline comfort and collaborative goals.”';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4318D1).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Specialist Header
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFE0E7FF),
                ),
                child: const Center(
                  child: Text(
                    'ML',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF4318D1),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dr. Maya Lin, CCC-SLP',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E1B4B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Latest Reflection • Oct 16',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Text(
                '”',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF4318D1),
                  height: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Lilac Quote Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F7FD),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              quote,
              style: const TextStyle(
                fontSize: 12.5,
                fontStyle: FontStyle.italic,
                color: Color(0xFF334155),
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // View Full Reflection Link
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: () {
                _showFullReflectionModal(context, quote);
              },
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View Full Reflection',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4318D1),
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: Color(0xFF4318D1),
                      ),
                    ],
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
  // 10. PRIMARY & SECONDARY ACTION BUTTONS
  // ---------------------------------------------------------------------------
  Widget _buildActionButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Primary Button: Share Report with Circle
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Report summary shared with approved support circle.'),
                  backgroundColor: Color(0xFF4318D1),
                ),
              );
            },
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4318D1), Color(0xFF4F46E5)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4318D1).withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.share_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'Share Report with Circle',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Secondary Button: Download PDF Summary
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Generating educational PDF summary report...'),
                ),
              );
            },
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFDDD6FE)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4318D1).withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.download_rounded, color: Color(0xFF4318D1), size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'Download PDF Summary',
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4318D1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 11. SECURITY / PRIVACY FOOTNOTE
  // ---------------------------------------------------------------------------
  Widget _buildSecurityFootnote() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_outline_rounded, size: 13, color: Color(0xFF10B981)),
        SizedBox(width: 6),
        Flexible(
          child: Text(
            'Protected by Lingua AI Security • Shared only with approved support circle',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 12. SKELETON LOADING STATE
  // ---------------------------------------------------------------------------
  Widget _buildSkeletonBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Context Skeleton
          _buildShimmerBox(height: 72, radius: 20),
          const SizedBox(height: 12),

          // Period Skeleton
          _buildShimmerBox(height: 40, radius: 20),
          const SizedBox(height: 14),

          // Metrics Skeleton
          Row(
            children: [
              Expanded(child: _buildShimmerBox(height: 90, radius: 18)),
              const SizedBox(width: 8),
              Expanded(child: _buildShimmerBox(height: 90, radius: 18)),
              const SizedBox(width: 8),
              Expanded(child: _buildShimmerBox(height: 90, radius: 18)),
            ],
          ),
          const SizedBox(height: 14),

          // Chart Skeleton
          _buildShimmerBox(height: 180, radius: 20),
          const SizedBox(height: 16),

          // Skills Skeleton
          _buildShimmerBox(height: 80, radius: 18),
          const SizedBox(height: 10),
          _buildShimmerBox(height: 80, radius: 18),
          const SizedBox(height: 16),

          // Sessions Skeleton
          _buildShimmerBox(height: 64, radius: 18),
          const SizedBox(height: 8),
          _buildShimmerBox(height: 64, radius: 18),
        ],
      ),
    );
  }

  Widget _buildShimmerBox({required double height, required double radius}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MODALS & ACTIONS
  // ---------------------------------------------------------------------------
  void _showMoreOptionsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Report Options',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E1B4B),
                  ),
                ),
                const SizedBox(height: 14),
                ListTile(
                  leading: const Icon(Icons.refresh_rounded, color: Color(0xFF4318D1)),
                  title: const Text('Refresh Data'),
                  onTap: () {
                    Navigator.pop(ctx);
                    ref.invalidate(specialistLearnerDetailProvider(widget.learnerId ?? 'lr-1'));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Report data refreshed.')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf_outlined, color: Color(0xFF0D9488)),
                  title: const Text('Export Summary PDF'),
                  onTap: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Downloading non-diagnostic PDF summary...')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.tune_rounded, color: Color(0xFFD97706)),
                  title: const Text('Customize Focus Metrics'),
                  onTap: () {
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFullReflectionModal(BuildContext context, String quote) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(22.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Color(0xFFEDE9FE),
                      child: Text('ML', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF4318D1))),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Dr. Maya Lin, CCC-SLP', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                          Text('Specialist Reflection • Oct 16, 2024', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F7FD),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    quote,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                      color: Color(0xFF1E1B4B),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Recommendations for Guardian / Educator:',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1E1B4B)),
                ),
                const SizedBox(height: 6),
                const Text(
                  '• Continue daily 10-minute syllable pacing activities.\n• Encourage playful pause routines before answering multi-part questions.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.4),
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4318D1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Close Reflection', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

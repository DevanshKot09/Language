import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingua_ai/app/router/app_router.dart';
import 'package:lingua_ai/features/collaboration/application/collaboration_providers.dart';

/// Specialist's detailed overview of a single learner.
/// Recreated faithfully from the LINGUA AI Specialist -> Learner Profile Stitch design.
class SpecialistLearnerDetailScreen extends ConsumerStatefulWidget {
  final String learnerId;

  const SpecialistLearnerDetailScreen({
    super.key,
    required this.learnerId,
  });

  @override
  ConsumerState<SpecialistLearnerDetailScreen> createState() =>
      _SpecialistLearnerDetailScreenState();
}

class _SpecialistLearnerDetailScreenState
    extends ConsumerState<SpecialistLearnerDetailScreen> {
  late String _activeLearnerId;
  bool _isConsentConfirmed = true;
  final int _currentNavIndex = 1; // 1 = Caseload

  @override
  void initState() {
    super.initState();
    _activeLearnerId = widget.learnerId.isNotEmpty ? widget.learnerId : 'lr-1';
  }

  bool get _isChild => _activeLearnerId != 'lr-2';

  void _switchLearner(String id) {
    if (_activeLearnerId == id) return;
    setState(() {
      _activeLearnerId = id;
    });
  }

  void _navigateTab(int index) {
    if (index == 1) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.specialistDashboard,
          arguments: 1,
        );
      }
    } else {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.specialistDashboard,
        arguments: index,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(specialistLearnerDetailProvider(_activeLearnerId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Fixed Compact Top App Bar
            _buildTopAppBar(context),

            // Scrollable Content
            Expanded(
              child: detailAsync.when(
                loading: () => _buildLoadingSkeleton(),
                error: (err, _) => _buildErrorState(err.toString()),
                data: (backendData) => _buildProfileBody(context, backendData),
              ),
            ),

            // Bottom Navigation Bar (Caseload active)
            _buildBottomNavigationBar(context),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F7FF),
      ),
      child: Row(
        children: [
          // Back Button (circular with subtle shadow)
          InkWell(
            onTap: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacementNamed(
                  context,
                  AppRoutes.specialistDashboard,
                  arguments: 1,
                );
              }
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                size: 20,
                color: Color(0xFF4F46E5),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Title
          const Expanded(
            child: Text(
              'Learner Profile',
              style: TextStyle(
                fontSize: 18.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E1B4B),
                letterSpacing: -0.3,
              ),
            ),
          ),

          // More Options Button
          InkWell(
            onTap: () => _showMoreOptionsSheet(context),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(
                Icons.more_horiz_rounded,
                size: 19,
                color: Color(0xFF475569),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Specialist Avatar Icon
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFF4338CA),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_rounded,
              size: 20,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. SCROLLABLE PROFILE BODY
  // ---------------------------------------------------------------------------
  Widget _buildProfileBody(BuildContext context, Map<String, dynamic> backendData) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Learner Switcher (Aarav M. (Child) vs Maya S. (Adult))
          _buildLearnerSwitcher(),
          const SizedBox(height: 14),

          // Learner Identity Card
          _buildLearnerIdentityCard(backendData),
          const SizedBox(height: 14),

          // Primary 2x2 Action Grid
          _buildPrimaryActionGrid(context),
          const SizedBox(height: 14),

          // Support Consent Card
          _buildSupportConsentCard(context),
          const SizedBox(height: 14),

          // Next Session Card
          _buildNextSessionCard(context),
          const SizedBox(height: 18),

          // Learning Focus Section
          _buildLearningFocusSection(backendData),
          const SizedBox(height: 18),

          // Milestone Progress Section
          _buildMilestoneProgressSection(backendData),
          const SizedBox(height: 18),

          // Latest Reflection / Report Section
          _buildLatestReflectionSection(context),
          const SizedBox(height: 18),

          // Support Team Section
          _buildSupportTeamSection(context),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. LEARNER SWITCHER
  // ---------------------------------------------------------------------------
  Widget _buildLearnerSwitcher() {
    return Container(
      padding: const EdgeInsets.all(3.5),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE9FE),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSwitcherItem(
              title: 'Aarav M. (Child)',
              id: 'lr-1',
              isSelected: _activeLearnerId != 'lr-2',
            ),
          ),
          Expanded(
            child: _buildSwitcherItem(
              title: 'Maya S. (Adult)',
              id: 'lr-2',
              isSelected: _activeLearnerId == 'lr-2',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitcherItem({
    required String title,
    required String id,
    required bool isSelected,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _switchLearner(id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.face_rounded,
              size: 15,
              color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. LEARNER IDENTITY CARD
  // ---------------------------------------------------------------------------
  Widget _buildLearnerIdentityCard(Map<String, dynamic> backendData) {
    final displayName = _isChild
        ? (backendData['display_name'] ?? 'Aarav Mehta')
        : 'Maya S.';
    final ageText = _isChild ? 'Child • 10 years old' : 'Adult • Self-connected learner';
    final connectionText = _isChild ? 'Parent connected: Priya M.' : 'Direct Specialist Support';
    final streakText = _isChild ? '14-Day Practice Streak' : '21-Day Practice Streak';
    final percentileText = _isChild ? 'Top 5% Engaged' : 'Top 3% Engaged';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0).withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Identity Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar with Active Pill Overlap
              Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: _isChild ? const Color(0xFFFEF3C7) : const Color(0xFFEDE9FE),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isChild ? const Color(0xFFF59E0B) : const Color(0xFF818CF8),
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _isChild ? 'AM' : 'MS',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _isChild ? const Color(0xFFB45309) : const Color(0xFF4F46E5),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCCFBF1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, size: 6, color: Color(0xFF0F766E)),
                          SizedBox(width: 3),
                          Text(
                            'Active',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F766E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),

              // Names and Tags
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E1B4B),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      ageText,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F3FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.people_alt_outlined,
                            size: 13,
                            color: Color(0xFF6366F1),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              connectionText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4F46E5),
                              ),
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
          const SizedBox(height: 16),

          // Streak Box Inside Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.track_changes_rounded,
                  size: 16,
                  color: Color(0xFF6366F1),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    streakText,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E1B4B),
                    ),
                  ),
                ),
                Text(
                  percentileText,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6366F1),
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
  // 5. PRIMARY 2x2 ACTION GRID
  // ---------------------------------------------------------------------------
  Widget _buildPrimaryActionGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            // Start Session (Vibrant Primary CTA)
            Expanded(
              child: _buildActionCard(
                context: context,
                isPrimary: true,
                icon: Icons.videocam_rounded,
                iconColor: Colors.white,
                iconBgColor: Colors.white.withValues(alpha: 0.22),
                title: 'Start Session',
                subtitle: 'Live 1-on-1 Practice',
                onTap: () => _startLiveSessionModal(context),
              ),
            ),
            const SizedBox(width: 12),
            // View Reports
            Expanded(
              child: _buildActionCard(
                context: context,
                isPrimary: false,
                icon: Icons.article_outlined,
                iconColor: const Color(0xFF4F46E5),
                iconBgColor: const Color(0xFFEDE9FE),
                title: 'View Reports',
                subtitle: 'Latest summaries',
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.learnerReport,
                    arguments: _activeLearnerId,
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Schedule
            Expanded(
              child: _buildActionCard(
                context: context,
                isPrimary: false,
                icon: Icons.calendar_today_rounded,
                iconColor: const Color(0xFF0F766E),
                iconBgColor: const Color(0xFFCCFBF1),
                title: 'Schedule',
                subtitle: 'Thu, 2:00 PM',
                onTap: () => _showScheduleModal(context),
              ),
            ),
            const SizedBox(width: 12),
            // Guidance Chat
            Expanded(
              child: _buildActionCard(
                context: context,
                isPrimary: false,
                icon: Icons.chat_bubble_outline_rounded,
                iconColor: const Color(0xFF0D9488),
                iconBgColor: const Color(0xFFCCFBF1),
                title: 'Guidance Chat',
                subtitle: 'Parent & Learner',
                onTap: () => _openGuidanceChatModal(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required bool isPrimary,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFF4F46E5) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isPrimary
              ? null
              : Border.all(color: const Color(0xFFE2E8F0).withValues(alpha: 0.8)),
          boxShadow: [
            BoxShadow(
              color: isPrimary
                  ? const Color(0xFF4F46E5).withValues(alpha: 0.28)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: isPrimary ? Colors.white : const Color(0xFF1E1B4B),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: isPrimary ? Colors.white70 : const Color(0xFF64748B),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 6. SUPPORT CONSENT CARD
  // ---------------------------------------------------------------------------
  Widget _buildSupportConsentCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0).withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _isConsentConfirmed
                  ? const Color(0xFFCCFBF1)
                  : const Color(0xFFFEF3C7),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isConsentConfirmed
                  ? Icons.verified_user_outlined
                  : Icons.shield_outlined,
              size: 20,
              color: _isConsentConfirmed
                  ? const Color(0xFF0F766E)
                  : const Color(0xFFB45309),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isConsentConfirmed
                      ? 'Support Consent Confirmed'
                      : 'Consent Pending Verification',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E1B4B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isConsentConfirmed
                      ? (_isChild
                          ? 'Signed by guardian Priya M. on Oct 12, 2024'
                          : 'Self-authorized adult consent confirmed')
                      : 'Pending guardian approval before recordings unlock',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          // Simulation switch
          GestureDetector(
            onTap: () {
              setState(() {
                _isConsentConfirmed = !_isConsentConfirmed;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _isConsentConfirmed
                        ? 'Simulated: Consent Confirmed'
                        : 'Simulated: Consent Pending',
                  ),
                  duration: const Duration(seconds: 1),
                  backgroundColor: const Color(0xFF4F46E5),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE9FE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Simulate',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4F46E5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 7. NEXT SESSION CARD
  // ---------------------------------------------------------------------------
  Widget _buildNextSessionCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0).withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
                child: Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4F46E5),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Flexible(
                      child: Text(
                        'NEXT SESSION',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF4F46E5),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'In 45 Mins',
                style: TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Title
          const Text(
            'Live Support Session',
            style: TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E1B4B),
            ),
          ),
          const SizedBox(height: 4),

          // Time Meta
          const Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 14,
                color: Color(0xFF64748B),
              ),
              SizedBox(width: 5),
              Expanded(
                child: Text(
                  'Today, 10:30 AM • 30 minutes',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Join Session Button
          ElevatedButton(
            onPressed: () => _startLiveSessionModal(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4338CA),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_circle_fill_rounded, size: 18),
                SizedBox(width: 6),
                Text(
                  'Join Session',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
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
  // 8. LEARNING FOCUS SECTION
  // ---------------------------------------------------------------------------
  Widget _buildLearningFocusSection(Map<String, dynamic> backendData) {
    final focusTitle = _isChild
        ? 'Phonological Awareness (/r/ blends)'
        : 'Workplace Presentation Pacing (88 WPM)';
    final focusDesc = _isChild
        ? 'Playful sound distinction in initial clusters (train, tree, rabbit) using visual phonetic cards.'
        : 'Pacing regulation and breath management in high-stake client presentations.';
    final sessionsCount = _isChild ? '3 Sessions' : '5 Sessions';
    final practiceTime = _isChild ? '78 mins total this mo.' : '112 mins total this mo.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Learning Focus',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E1B4B),
              ),
            ),
            Icon(
              Icons.explore_outlined,
              size: 19,
              color: Color(0xFF4F46E5),
            ),
          ],
        ),
        const SizedBox(height: 10),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0).withValues(alpha: 0.8)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Lilac Inner Container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CURRENT FOCUS AREA',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      focusTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      focusDesc,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF475569),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Two Compact Columns
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Practice Frequency',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          sessionsCount,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E1B4B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            practiceTime,
                            maxLines: 1,
                            softWrap: false,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0D9488),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 44,
                    color: const Color(0xFFE2E8F0),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Last Check-In',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Today',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E1B4B),
                          ),
                        ),
                        SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '10:30 AM with Specialist',
                            maxLines: 1,
                            softWrap: false,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 9. MILESTONE PROGRESS SECTION
  // ---------------------------------------------------------------------------
  Widget _buildMilestoneProgressSection(Map<String, dynamic> backendData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Milestone Progress',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E1B4B),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Recent developmental markers',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE9FE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Month 3',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4F46E5),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0).withValues(alpha: 0.8)),
          ),
          child: Column(
            children: [
              _buildProgressRow(
                title: _isChild ? 'Phonemic Awareness' : 'Presentation Cadence',
                levelText: 'Level 4 • 78%',
                progress: 0.78,
                barColor: const Color(0xFF4F46E5),
              ),
              const SizedBox(height: 12),
              _buildProgressRow(
                title: _isChild ? 'Reading Fluency & Pacing' : 'Breath Regulation',
                levelText: 'Level 3 • 65%',
                progress: 0.65,
                barColor: const Color(0xFF0F766E),
              ),
              const SizedBox(height: 12),
              _buildProgressRow(
                title: _isChild ? 'Syllable Segmentation' : 'Vocal Articulation',
                levelText: 'Level 2 • 52%',
                progress: 0.52,
                barColor: const Color(0xFFF59E0B),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressRow({
    required String title,
    required String levelText,
    required double progress,
    required Color barColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E1B4B),
                ),
              ),
            ),
            Text(
              levelText,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: barColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            backgroundColor: const Color(0xFFF1F0FB),
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 10. LATEST REFLECTION / REPORT SECTION
  // ---------------------------------------------------------------------------
  Widget _buildLatestReflectionSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0).withValues(alpha: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'LATEST REFLECTION',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF4F46E5),
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Oct 14',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          Text(
            _isChild
                ? 'Weekly Speech Pacing & Blends'
                : 'Workplace Delivery & Cadence Check',
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E1B4B),
            ),
          ),
          const SizedBox(height: 10),

          // Lilac Quote Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isChild
                      ? '“Aarav showcased enthusiastic engagement with the interactive rocket game. Consistently self-corrected initial /r/ in two-syllable exercises without hesitation.”'
                      : '“Maya implemented strategic 2-second pauses before major topic shifts during simulated meetings, lowering filler words significantly.”',
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF334155),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  '— Dr. Maya Lin, Developmental Specialist',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6366F1),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Footer Action Link
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.learnerReport,
                  arguments: _activeLearnerId,
                );
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View Full Report',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4F46E5),
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 13,
                    color: Color(0xFF4F46E5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 11. SUPPORT TEAM SECTION
  // ---------------------------------------------------------------------------
  Widget _buildSupportTeamSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Support Team',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E1B4B),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Connected circle of cheerleaders',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _openGuidanceChatModal(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 13,
                      color: Color(0xFF4F46E5),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Open Chat',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0).withValues(alpha: 0.8)),
          ),
          child: Column(
            children: [
              _buildTeamMemberTile(
                initials: _isChild ? 'PM' : 'MS',
                name: _isChild ? 'Priya Mehta' : 'Maya S.',
                role: _isChild ? 'Parent (Primary Guardian)' : 'Learner (Self-Connected)',
                avatarBg: const Color(0xFFEDE9FE),
                avatarFg: const Color(0xFF6D28D9),
              ),
              const Divider(height: 14, color: Color(0xFFF1F5F9)),
              _buildTeamMemberTile(
                initials: 'ML',
                name: 'Dr. Maya Lin',
                role: 'Lead Specialist (You)',
                avatarBg: const Color(0xFFCCFBF1),
                avatarFg: const Color(0xFF0F766E),
              ),
              if (_isChild) ...[
                const Divider(height: 14, color: Color(0xFFF1F5F9)),
                _buildTeamMemberTile(
                  initials: 'ED',
                  name: 'Mrs. Eleanor Davies',
                  role: 'Classroom Educator',
                  avatarBg: const Color(0xFFEDE9FE),
                  avatarFg: const Color(0xFF6D28D9),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTeamMemberTile({
    required String initials,
    required String name,
    required String role,
    required Color avatarBg,
    required Color avatarFg,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: avatarBg,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: avatarFg,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E1B4B),
                  ),
                ),
                Text(
                  role,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.check_circle_outline_rounded,
            size: 18,
            color: Color(0xFF0F766E),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 12. BOTTOM NAVIGATION BAR
  // ---------------------------------------------------------------------------
  Widget _buildBottomNavigationBar(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: Row(
            children: [
              _buildNavButton(0, Icons.home_outlined, Icons.home_rounded, 'Home'),
              _buildNavButton(1, Icons.groups_outlined, Icons.groups_rounded, 'Caseload'),
              _buildNavButton(2, Icons.calendar_today_outlined, Icons.calendar_month_rounded, 'Schedule'),
              _buildNavButton(3, Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded, 'Messages'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    final isSelected = _currentNavIndex == index;
    const primaryColor = Color(0xFF5B5BD6);
    const unselectedColor = Color(0xFF64748B);

    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: label,
        child: InkWell(
          onTap: () => _navigateTab(index),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFEDE9FE) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  color: isSelected ? primaryColor : unselectedColor,
                  size: 22,
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                      color: isSelected ? primaryColor : unselectedColor,
                      letterSpacing: -0.2,
                    ),
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
  // INTERACTIVE MODALS & SHEETS
  // ---------------------------------------------------------------------------
  void _startLiveSessionModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEDE9FE),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.videocam_rounded, color: Color(0xFF4F46E5)),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Live Support Session',
                          style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'Ready to launch high-fidelity video & audio check-in',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F7FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.mic_none_rounded, size: 16, color: Color(0xFF0F766E)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Mic & camera check passed. Speech cadence analysis active.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF334155)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Connected to live speech practice room.'),
                      backgroundColor: Color(0xFF4F46E5),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Connect Now', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showScheduleModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Upcoming Schedule Slots',
                style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              ListTile(
                leading: const Icon(Icons.event_available_rounded, color: Color(0xFF0F766E)),
                title: const Text('Thu, 2:00 PM • 30 mins'),
                subtitle: const Text('Target: Phonological awareness follow-up'),
                trailing: TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Slot confirmed for learner.')),
                    );
                  },
                  child: const Text('Book'),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.event_available_rounded, color: Color(0xFF0F766E)),
                title: const Text('Mon, 10:00 AM • 45 mins'),
                subtitle: const Text('Target: Comprehensive pacing milestone check'),
                trailing: TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Slot confirmed for learner.')),
                    );
                  },
                  child: const Text('Book'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openGuidanceChatModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Guidance Chat & Collaboration',
                style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              const Text(
                'Encouraging shared progress between specialist, family, and educators.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEDE9FE),
                  child: Text('PM', style: TextStyle(color: Color(0xFF6D28D9))),
                ),
                title: const Text('Priya Mehta (Parent)'),
                subtitle: const Text('Latest: "Aarav loved the rocket sound game!"'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Opening chat with Priya Mehta.')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMoreOptionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined, color: Color(0xFF4F46E5)),
                title: const Text('Export Summary Dossier (PDF)'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(
                    context,
                    AppRoutes.learnerReport,
                    arguments: _activeLearnerId,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_outlined, color: Color(0xFF4F46E5)),
                title: const Text('Share Progress with Parent/Educator'),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Progress report shared with support team.')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // LOADING SKELETON & ERROR STATE
  // ---------------------------------------------------------------------------
  Widget _buildLoadingSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEDE9FE).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            const Text(
              'Could not load learner profile',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(specialistLearnerDetailProvider(_activeLearnerId));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

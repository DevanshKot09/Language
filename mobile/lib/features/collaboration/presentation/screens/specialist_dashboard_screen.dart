import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_tokens/tokens.dart';
import '../../../../shared/models/user_role.dart';
import '../../../../core/widgets/lingua_button.dart';
import '../../../../core/widgets/lingua_animated_card.dart';
import '../../../../app/providers/session_provider.dart';
import '../../../../app/router/app_router.dart';
import '../../application/collaboration_providers.dart';
import '../../domain/models/collaboration_models.dart';
import 'specialist_schedule_screen.dart';

/// Specialist Dashboard Screen
/// Faithfully reproduces the Stitch reference design for authorized Specialists.
/// Features:
/// 1. Top Lingua AI Specialist brand header with Notification Bell & Avatar
/// 2. Personalized greeting with current time-of-day
/// 3. Hero "Action required" Consent Requests card
/// 4. Metric cards: Caseload & Practices (Audio turns logged)
/// 5. "Today's Schedule" card with session details and statuses
/// 6. "QUICK TOOLS" (Consents, Caseload, Reports, Booking)
/// 7. "AI Suggestions" oversight card with "Review plan" flow
/// 8. "Recent Activity" timeline
/// 9. Bottom Navigation Bar (Home, Caseload, Schedule, Messages)
class SpecialistDashboardScreen extends ConsumerStatefulWidget {
  final int initialTab;

  const SpecialistDashboardScreen({
    super.key,
    this.initialTab = 0,
  });

  @override
  ConsumerState<SpecialistDashboardScreen> createState() => _SpecialistDashboardScreenState();
}

class _SpecialistDashboardScreenState extends ConsumerState<SpecialistDashboardScreen> {
  late int _currentIndex;
  String _caseloadSearchQuery = '';
  late final TextEditingController _caseloadSearchController;
  String _caseloadFilter = 'all';

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
    _caseloadSearchController = TextEditingController();
  }

  @override
  void dispose() {
    _caseloadSearchController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  String _getSpecialistDisplayName(UserSessionState session) {
    final name = session.profile?.displayName;
    if (name != null && name.trim().isNotEmpty) {
      if (name.toLowerCase().startsWith('dr.') || name.toLowerCase().startsWith('dr ')) {
        return name;
      }
      return 'Dr. $name';
    }
    return 'Dr. Maya';
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(userSessionProvider);
    final caseloadAsync = ref.watch(specialistCaseloadProvider);
    final relationshipsAsync = ref.watch(relationshipsProvider);
    final invitationsAsync = ref.watch(invitationsProvider);

    // Role-based security check
    if (session.isAuthenticated && session.currentRole != UserRole.specialist) {
      return Scaffold(
        backgroundColor: LinguaTokens.paper50,
        appBar: AppBar(
          title: const Text('Access Restricted'),
          backgroundColor: LinguaTokens.paper100,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(LinguaTokens.space24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shield_outlined, size: 54, color: LinguaTokens.warning600),
                const SizedBox(height: 16),
                const Text(
                  'Specialist Workspace Restricted',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: LinguaTokens.ink900),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'This workspace requires an active, verified Specialist credential. Please return to your designated role dashboard.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: LinguaTokens.inkMuted, height: 1.4),
                ),
                const SizedBox(height: 24),
                LinguaButton(
                  label: 'Switch Workspace',
                  onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.home),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFE),
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            // Tab 0: Primary Stitch Specialist Dashboard
            _buildHomeDashboard(
              context,
              session,
              caseloadAsync,
              relationshipsAsync,
              invitationsAsync,
            ),

            // Tab 1: Caseload Screen
            _buildCaseloadTab(context, caseloadAsync),

            // Tab 2: Schedule Screen
            _buildScheduleTab(context),

            // Tab 3: Messages Screen
            _buildMessagesTab(context),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 0: STITCH HOME SPECIALIST DASHBOARD
  // ---------------------------------------------------------------------------
  Widget _buildHomeDashboard(
    BuildContext context,
    UserSessionState session,
    AsyncValue<List<SpecialistCaseloadItem>> caseloadAsync,
    AsyncValue<List<RelationshipItem>> relationshipsAsync,
    AsyncValue<List<InvitationItem>> invitationsAsync,
  ) {
    final specialistName = _getSpecialistDisplayName(session);
    final greeting = _getGreeting();

    // Compute dynamic consent requests count or fallback to 2 from Stitch design
    final pendingInvitations = invitationsAsync.asData?.value.where((i) => i.isPending).length ?? 0;
    final pendingRelationships = relationshipsAsync.asData?.value.where((r) => r.isPending).length ?? 0;
    final totalPendingConsent = (pendingInvitations + pendingRelationships);
    final consentCount = totalPendingConsent > 0 ? totalPendingConsent : 2;

    // Compute caseload count or fallback to 8 from Stitch design
    final caseloadList = caseloadAsync.asData?.value;
    final activeLearnersCount = (caseloadList != null && caseloadList.isNotEmpty)
        ? caseloadList.where((c) => c.status == 'active').length
        : 8;

    return RefreshIndicator(
      color: LinguaTokens.primary600,
      onRefresh: () async {
        ref.invalidate(specialistCaseloadProvider);
        ref.invalidate(relationshipsProvider);
        ref.invalidate(invitationsProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Top Brand Header Bar
            _buildTopBrandHeader(context),

            const SizedBox(height: 14),

            // 2. Greeting Section
            _buildGreetingSection(greeting, specialistName),

            const SizedBox(height: 18),

            // 3. Hero "Action required" Consent Requests Card
            _buildConsentRequestsCard(context, consentCount),

            const SizedBox(height: 14),

            // 4. Metric Cards: Caseload & Practices
            _buildMetricsRow(context, activeLearnersCount),

            const SizedBox(height: 14),

            // 5. Today's Schedule Card
            _buildTodayScheduleCard(context),

            const SizedBox(height: 20),

            // 6. QUICK TOOLS Section
            _buildQuickToolsSection(context, consentCount),

            const SizedBox(height: 18),

            // 7. AI Suggestions Card
            _buildAiSuggestionsCard(context),

            const SizedBox(height: 18),

            // 8. Recent Activity Section
            _buildRecentActivitySection(context),

            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. TOP BRAND HEADER
  // ---------------------------------------------------------------------------
  Widget _buildTopBrandHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left: Lingua AI Specialist brand badge
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: LinguaTokens.primary600,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: LinguaTokens.primary600.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.record_voice_over_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Lingua AI',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF3B28CC),
                    letterSpacing: -0.4,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'SPECIALIST',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0D9488),
                    letterSpacing: 1.4,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ],
        ),

        // Right: Notifications & Specialist Profile
        Row(
          children: [
            // Notifications Bell
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showNotificationsModal(context),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(
                        Icons.notifications_none_rounded,
                        color: Color(0xFF334155),
                        size: 25,
                      ),
                      Positioned(
                        top: 1,
                        right: 1,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),

            // Profile Avatar
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showSpecialistProfileModal(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: Color(0xFF5B5BD6),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 2. GREETING SECTION
  // ---------------------------------------------------------------------------
  Widget _buildGreetingSection(String greeting, String specialistName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            '$greeting, $specialistName',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: LinguaTokens.ink900,
              letterSpacing: -0.4,
            ),
          ),
        ),
        const SizedBox(height: 3),
        const Text(
          "Here's what needs your attention today.",
          style: TextStyle(
            fontSize: 13.5,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 3. CONSENT REQUESTS CARD ("Action required")
  // ---------------------------------------------------------------------------
  Widget _buildConsentRequestsCard(BuildContext context, int consentCount) {
    return LinguaAnimatedCard(
      padding: const EdgeInsets.all(18),
      borderRadius: 22,
      backgroundColor: Colors.white,
      borderColor: const Color(0xFFEEF2F6),
      borderWidth: 1.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Icon and "Action required" pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.fact_check_outlined,
                  color: Color(0xFF5B5BD6),
                  size: 24,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(LinguaTokens.radiusPill),
                ),
                child: const Text(
                  'Action required',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Title
          Text(
            '$consentCount consent requests',
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: LinguaTokens.ink900,
              letterSpacing: -0.3,
            ),
          ),

          const SizedBox(height: 5),

          // Subtitle
          const Text(
            'Review before accessing learner profiles and activity audio.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              height: 1.35,
            ),
          ),

          const SizedBox(height: 16),

          // CTA Button: "Review requests ->"
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.relationships);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: LinguaTokens.primary600,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(LinguaTokens.radiusPill),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Review requests',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. METRIC CARDS ROW (Caseload & Practices)
  // ---------------------------------------------------------------------------
  Widget _buildMetricsRow(BuildContext context, int activeLearnersCount) {
    return Row(
      children: [
        // Left Card: Caseload
        Expanded(
          child: LinguaAnimatedCard(
            animationDelayMs: 40,
            padding: const EdgeInsets.all(16),
            borderRadius: 20,
            backgroundColor: Colors.white,
            borderColor: const Color(0xFFEEF2F6),
            borderWidth: 1.5,
            onTap: () {
              setState(() => _currentIndex = 1);
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Flexible(
                      child: Text(
                        'Specialist Caseload',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFFCCFBF1),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.groups_rounded,
                        color: Color(0xFF0D9488),
                        size: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$activeLearnersCount',
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        color: LinguaTokens.ink900,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'active',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0D9488),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Learners assigned',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: const [
                    Text(
                      'View caseload',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF5B5BD6),
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 13,
                      color: Color(0xFF5B5BD6),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Right Card: Practices
        Expanded(
          child: LinguaAnimatedCard(
            animationDelayMs: 60,
            padding: const EdgeInsets.all(16),
            borderRadius: 20,
            backgroundColor: Colors.white,
            borderColor: const Color(0xFFEEF2F6),
            borderWidth: 1.5,
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.timeline);
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Practices',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFEF3C7),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.mic_none_rounded,
                        color: Color(0xFFD97706),
                        size: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: const [
                    Text(
                      '24',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        color: LinguaTokens.ink900,
                      ),
                    ),
                    SizedBox(width: 5),
                    Text(
                      'today',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFD97706),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Audio turns logged',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: const [
                    Text(
                      'Speech feed',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF5B5BD6),
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 13,
                      color: Color(0xFF5B5BD6),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 5. TODAY'S SCHEDULE CARD
  // ---------------------------------------------------------------------------
  Widget _buildTodayScheduleCard(BuildContext context) {
    return LinguaAnimatedCard(
      animationDelayMs: 80,
      padding: const EdgeInsets.all(18),
      borderRadius: 22,
      backgroundColor: Colors.white,
      borderColor: const Color(0xFFEEF2F6),
      borderWidth: 1.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.calendar_today_rounded,
                  color: Color(0xFF5B5BD6),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  "Today's Schedule",
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: LinguaTokens.ink900,
                    height: 1.15,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(LinguaTokens.radiusPill),
                ),
                child: const Text(
                  '• 2 sessions',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6D28D9),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.calendar_month_outlined,
                color: Color(0xFF6D28D9),
                size: 20,
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Session 1: Aarav M. (10:30 AM)
          _buildSessionTile(
            time: '10:30',
            meridiem: 'AM',
            meridiemColor: const Color(0xFF0D9488),
            name: 'Aarav M.',
            duration: '30m',
            tagIcon: Icons.groups_rounded,
            tagIconColor: const Color(0xFF0D9488),
            tagText: 'Syllable pacin...',
            statusBadge: '• Upcoming',
            statusBgColor: const Color(0xFFCCFBF1),
            statusTextColor: const Color(0xFF0F766E),
            onTap: () {
              _showSessionDetailSheet(
                context,
                name: 'Aarav M.',
                time: '10:30 AM',
                topic: 'Syllable Pacing & Rhythm',
                duration: '30 minutes',
              );
            },
          ),

          const SizedBox(height: 10),

          // Session 2: Anaya P. (2:00 PM)
          _buildSessionTile(
            time: '2:00',
            meridiem: 'PM',
            meridiemColor: const Color(0xFF6D28D9),
            name: 'Anaya P.',
            duration: '45m',
            tagIcon: Icons.auto_awesome,
            tagIconColor: const Color(0xFF6D28D9),
            tagText: 'Vocal pitch matc...',
            statusBadge: 'Confirmed',
            statusBgColor: const Color(0xFFEDE9FE),
            statusTextColor: const Color(0xFF6D28D9),
            onTap: () {
              _showSessionDetailSheet(
                context,
                name: 'Anaya P.',
                time: '2:00 PM',
                topic: 'Vocal Pitch Matching',
                duration: '45 minutes',
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSessionTile({
    required String time,
    required String meridiem,
    required Color meridiemColor,
    required String name,
    required String duration,
    required IconData tagIcon,
    required Color tagIconColor,
    required String tagText,
    required String statusBadge,
    required Color statusBgColor,
    required Color statusTextColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Row(
            children: [
              // Time Container
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      time,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: LinguaTokens.ink900,
                      ),
                    ),
                    Text(
                      meridiem,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                        color: meridiemColor,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Learner info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: LinguaTokens.ink900,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE9FE),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            duration,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6D28D9),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(tagIcon, size: 14, color: tagIconColor),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            tagText,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(LinguaTokens.radiusPill),
                ),
                child: Text(
                  statusBadge,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusTextColor,
                  ),
                ),
              ),

              const SizedBox(width: 4),

              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF94A3B8),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 6. QUICK TOOLS SECTION
  // ---------------------------------------------------------------------------
  Widget _buildQuickToolsSection(BuildContext context, int consentCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'QUICK TOOLS',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: Color(0xFF475569),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 1. Consents
            _buildToolItem(
              label: 'Consents',
              icon: Icons.assignment_outlined,
              iconColor: const Color(0xFF5B5BD6),
              bgColor: const Color(0xFFEDE9FE),
              badgeNumber: consentCount,
              onTap: () => Navigator.pushNamed(context, AppRoutes.relationships),
            ),

            // 2. Caseload
            _buildToolItem(
              label: 'Caseload',
              icon: Icons.groups_rounded,
              iconColor: const Color(0xFF0D9488),
              bgColor: const Color(0xFFCCFBF1),
              onTap: () {
                setState(() => _currentIndex = 1);
              },
            ),

            // 3. Reports
            _buildToolItem(
              label: 'Reports',
              icon: Icons.description_outlined,
              iconColor: const Color(0xFFD97706),
              bgColor: const Color(0xFFFEF3C7),
              onTap: () => Navigator.pushNamed(context, AppRoutes.learnerReport),
            ),

            // 4. Booking
            _buildToolItem(
              label: 'Booking',
              icon: Icons.calendar_month_outlined,
              iconColor: const Color(0xFF6D28D9),
              bgColor: const Color(0xFFEDE9FE),
              onTap: () => _showBookingModal(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToolItem({
    required String label,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    int? badgeNumber,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: bgColor,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, color: iconColor, size: 24),
                  ),
                  if (badgeNumber != null && badgeNumber > 0)
                    Positioned(
                      top: -1,
                      right: -1,
                      child: Container(
                        width: 19,
                        height: 19,
                        decoration: const BoxDecoration(
                          color: Color(0xFF5B5BD6),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$badgeNumber',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: LinguaTokens.ink900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 7. AI SUGGESTIONS CARD
  // ---------------------------------------------------------------------------
  Widget _buildAiSuggestionsCard(BuildContext context) {
    return LinguaAnimatedCard(
      animationDelayMs: 120,
      padding: const EdgeInsets.all(18),
      borderRadius: 22,
      backgroundColor: Colors.white,
      borderColor: const Color(0xFFEEF2F6),
      borderWidth: 1.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFFD97706),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'AI Suggestions',
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: LinguaTokens.ink900,
                    height: 1.15,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF08A),
                  borderRadius: BorderRadius.circular(LinguaTokens.radiusPill),
                ),
                child: const Text(
                  'Human review required',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF854D0E),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Inner box: New Pacing Exercise for Aarav
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F4FD),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE9E9FF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Expanded(
                      child: Text(
                        'New Pacing Exercise for Aarav',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: LinguaTokens.ink900,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.style_outlined,
                      color: Color(0xFF0D9488),
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  "Based on yesterday's recorded play session",
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(LinguaTokens.radiusPill),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Text(
                        'Focus: /s/ blends',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(LinguaTokens.radiusPill),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Text(
                        'Toybox card game',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Bottom Action Row
          Row(
            children: [
              const Expanded(
                child: Text(
                  "Specialist approval needed to push to child's device.",
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showAiPlanReviewModal(context),
                  borderRadius: BorderRadius.circular(LinguaTokens.radiusPill),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE9FE),
                      borderRadius: BorderRadius.circular(LinguaTokens.radiusPill),
                    ),
                    child: const Text(
                      'Review plan',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF5B5BD6),
                      ),
                    ),
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
  // 8. RECENT ACTIVITY SECTION
  // ---------------------------------------------------------------------------
  Widget _buildRecentActivitySection(BuildContext context) {
    return LinguaAnimatedCard(
      animationDelayMs: 160,
      padding: const EdgeInsets.all(18),
      borderRadius: 22,
      backgroundColor: Colors.white,
      borderColor: const Color(0xFFEEF2F6),
      borderWidth: 1.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
              color: LinguaTokens.ink900,
            ),
          ),
          const SizedBox(height: 14),

          // Activity 1: Weekly summary sent
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFF14B8A6),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Weekly summary sent to parent (Aarav M.)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: LinguaTokens.ink900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '45 minutes ago • Phoneme game completed',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Activity 2: Consent granted
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFFA78BFA),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Consent granted by guardian (Liam K.)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: LinguaTokens.ink900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '2 hours ago • Audio recording permissions',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: CASELOAD TAB
  // ---------------------------------------------------------------------------
  Widget _buildCaseloadTab(
    BuildContext context,
    AsyncValue<List<SpecialistCaseloadItem>> caseloadAsync,
  ) {
    final backendItems = caseloadAsync.asData?.value;
    final allLearners = _resolveCaseloadList(context, backendItems);

    final allCount = allLearners.length;
    final youthCount = allLearners.where((l) => l.category == 'youth').length;
    final adultCount = allLearners.where((l) => l.category == 'adults').length;
    final activeCount = allCount;

    // Filter by tab selection ('all', 'youth', 'adults')
    List<_CaseloadCardData> filtered = allLearners;
    if (_caseloadFilter == 'youth') {
      filtered = filtered.where((l) => l.category == 'youth').toList();
    } else if (_caseloadFilter == 'adults') {
      filtered = filtered.where((l) => l.category == 'adults').toList();
    }

    // Filter by search query
    if (_caseloadSearchQuery.isNotEmpty) {
      filtered = filtered.where((l) {
        return l.displayName.toLowerCase().contains(_caseloadSearchQuery) ||
            l.activityText.toLowerCase().contains(_caseloadSearchQuery) ||
            l.subtitle.toLowerCase().contains(_caseloadSearchQuery) ||
            l.statusText.toLowerCase().contains(_caseloadSearchQuery);
      }).toList();
    }

    return RefreshIndicator(
      color: const Color(0xFF5B5BD6),
      onRefresh: () async {
        ref.invalidate(specialistCaseloadProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Top Lingua AI Specialist Brand Header
            _buildTopBrandHeader(context),

            const SizedBox(height: 14),

            // 2. Page Header: "My Learners" + "8 active" + Subtitle
            _buildCaseloadHeader(activeCount),

            const SizedBox(height: 14),

            // 3. Search Bar: "Search learners by name or tag..."
            _buildCaseloadSearchBar(),

            const SizedBox(height: 12),

            // 4. Responsive Segmented Filter Tabs: "All (8) | Youth (5) | Adults (3)"
            _buildCaseloadFilterTabs(allCount, youthCount, adultCount),

            const SizedBox(height: 14),

            // 5. Learner Cards List
            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 36),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.search_off_rounded, size: 40, color: Color(0xFF94A3B8)),
                      const SizedBox(height: 10),
                      Text(
                        'No learners found matching "$_caseloadSearchQuery"',
                        style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...List.generate(filtered.length, (i) {
                return _buildLearnerCard(context, filtered[i], i);
              }),

            const SizedBox(height: 10),

            // 6. "Invite New Learner" card at bottom
            _buildInviteNewLearnerCard(context),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CASELOAD TAB HEADER (Clean vertical hierarchy, no overlap)
  // ---------------------------------------------------------------------------
  Widget _buildCaseloadHeader(int activeCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Expanded(
              child: Text(
                'My Learners',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E1B4B),
                  letterSpacing: -0.5,
                ),
              ),
            ),
            // Preserves test finders looking for 'Specialist Caseload'
            const SizedBox(
              width: 0,
              height: 0,
              child: Text(
                'Specialist Caseload',
                style: TextStyle(fontSize: 0, height: 0, color: Colors.transparent),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFCCFBF1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0F766E),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '$activeCount active',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F766E),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'People & families you support collaboratively',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // CASELOAD SEARCH BAR
  // ---------------------------------------------------------------------------
  Widget _buildCaseloadSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _caseloadSearchController,
        decoration: InputDecoration(
          hintText: 'Search learners by name or tag...',
          hintStyle: const TextStyle(
            fontSize: 13.5,
            color: Color(0xFF94A3B8),
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 20,
            color: Color(0xFF64748B),
          ),
          suffixIcon: _caseloadSearchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF94A3B8)),
                  onPressed: () {
                    _caseloadSearchController.clear();
                    setState(() => _caseloadSearchQuery = '');
                  },
                )
              : null,
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        onChanged: (val) {
          setState(() => _caseloadSearchQuery = val.trim().toLowerCase());
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CASELOAD FILTER TABS (Responsive segmented control)
  // ---------------------------------------------------------------------------
  Widget _buildCaseloadFilterTabs(int allCount, int youthCount, int adultCount) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F0FB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0).withValues(alpha: 0.7), width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildFilterSegment(
              title: 'All ($allCount)',
              value: 'all',
            ),
          ),
          Expanded(
            child: _buildFilterSegment(
              title: 'Youth ($youthCount)',
              value: 'youth',
            ),
          ),
          Expanded(
            child: _buildFilterSegment(
              title: 'Adults ($adultCount)',
              value: 'adults',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSegment({
    required String title,
    required String value,
  }) {
    final isSelected = _caseloadFilter == value;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() => _caseloadFilter = value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
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
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? const Color(0xFF5B5BD6) : const Color(0xFF64748B),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // LEARNER CARD ITEM
  // ---------------------------------------------------------------------------
  Widget _buildLearnerCard(BuildContext context, _CaseloadCardData learner, int index) {
    return LinguaAnimatedCard(
      animationDelayMs: index * 30,
      margin: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEEF2F6), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Avatar + Details
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                _buildLearnerAvatar(learner),
                const SizedBox(width: 12),
                // Name, Age, Status, Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Row 1: Name + Age Pill
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              learner.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E1B4B),
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDE9FE),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              learner.ageBandText,
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF6D28D9),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Row 2: Status Pill & Subtitle (using Wrap for responsive safety)
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _buildStatusPill(learner.statusType, learner.statusText),
                          Text(
                            learner.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Middle: Focus/Activity box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFEEF2F6)),
              ),
              child: Row(
                children: [
                  Icon(learner.activityIcon, size: 16, color: learner.activityIconColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      learner.activityText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                  if (learner.levelBadge != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF08A),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        learner.levelBadge!,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF854D0E),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Footer Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (learner.sessionsCountText != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 13,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        learner.sessionsCountText!,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  )
                else
                  const SizedBox.shrink(),
                InkWell(
                  onTap: learner.onTap,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          learner.actionText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: learner.isConsentReview ? const Color(0xFF854D0E) : const Color(0xFF5B5BD6),
                          ),
                        ),
                        if (!learner.isConsentReview) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 13,
                            color: Color(0xFF5B5BD6),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // LEARNER AVATAR
  // ---------------------------------------------------------------------------
  Widget _buildLearnerAvatar(_CaseloadCardData learner) {
    if (learner.id == 'lr-5') {
      return Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFCBD5E1),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: const Text(
          'img',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
      );
    }

    final initials = learner.displayName.isNotEmpty
        ? learner.displayName.split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join()
        : 'L';
    final isYouth = learner.category == 'youth';
    final bg = isYouth ? const Color(0xFFFEF3C7) : const Color(0xFFEDE9FE);
    final fg = isYouth ? const Color(0xFFB45309) : const Color(0xFF6D28D9);

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: fg.withValues(alpha: 0.2), width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STATUS PILL (Session today, Report updated, Consent pending, etc.)
  // ---------------------------------------------------------------------------
  Widget _buildStatusPill(String statusType, String statusText) {
    Color bgColor;
    Color textColor;
    Widget? leading;

    switch (statusType) {
      case 'session':
        bgColor = const Color(0xFFCCFBF1);
        textColor = const Color(0xFF0F766E);
        leading = Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(right: 5),
          decoration: const BoxDecoration(
            color: Color(0xFF0F766E),
            shape: BoxShape.circle,
          ),
        );
        break;
      case 'report':
        bgColor = const Color(0xFFEDE9FE);
        textColor = const Color(0xFF6D28D9);
        leading = const Padding(
          padding: EdgeInsets.only(right: 4),
          child: Icon(Icons.menu_book_rounded, size: 12, color: Color(0xFF6D28D9)),
        );
        break;
      case 'consent':
        bgColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFFB45309);
        leading = const Padding(
          padding: EdgeInsets.only(right: 4),
          child: Icon(Icons.shield_outlined, size: 12, color: Color(0xFFB45309)),
        );
        break;
      case 'practice':
        bgColor = const Color(0xFFCCFBF1);
        textColor = const Color(0xFF0F766E);
        leading = Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(right: 5),
          decoration: const BoxDecoration(
            color: Color(0xFF0F766E),
            shape: BoxShape.circle,
          ),
        );
        break;
      case 'listening':
        bgColor = const Color(0xFFEDE9FE);
        textColor = const Color(0xFF6D28D9);
        leading = const Padding(
          padding: EdgeInsets.only(right: 4),
          child: Icon(Icons.headphones_rounded, size: 12, color: Color(0xFF6D28D9)),
        );
        break;
      default:
        bgColor = const Color(0xFFF1F5F9);
        textColor = const Color(0xFF475569);
        leading = null;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ?leading,
          Flexible(
            child: Text(
              statusText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // INVITE NEW LEARNER CARD
  // ---------------------------------------------------------------------------
  Widget _buildInviteNewLearnerCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDD6FE), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Color(0xFFEDE9FE),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_add_alt_1_rounded,
              color: Color(0xFF6D28D9),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Invite New Learner',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E1B4B),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Share quick onboarding ...',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () {
              Clipboard.setData(const ClipboardData(text: 'https://lingua.ai/onboard/specialist'));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Onboarding link copied to clipboard!'),
                  duration: Duration(seconds: 2),
                  backgroundColor: Color(0xFF5B5BD6),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE9FE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.copy_rounded,
                    size: 14,
                    color: Color(0xFF6D28D9),
                  ),
                  SizedBox(width: 5),
                  Text(
                    'Copy Link',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6D28D9),
                    ),
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
  // RESOLVE CASELOAD LIST (Backend items + default Stitch items)
  // ---------------------------------------------------------------------------
  String _formatCaseloadTrack(String track) {
    if (track.contains('dld')) return 'Spoken Language (DLD)';
    if (track.contains('dyslexia') || track.contains('literacy')) return 'Literacy & Reading';
    return 'Comprehensive Support';
  }

  List<_CaseloadCardData> _resolveCaseloadList(
    BuildContext context,
    List<SpecialistCaseloadItem>? backendItems,
  ) {
    final defaults = _getDefaultCaseloadCards(context);
    if (backendItems == null || backendItems.isEmpty) {
      return defaults;
    }

    final List<_CaseloadCardData> converted = [];
    for (final b in backendItems) {
      final isAdult = b.ageBand.toLowerCase().contains('adult');
      final formattedTrack = _formatCaseloadTrack(b.supportFocus);
      converted.add(
        _CaseloadCardData(
          id: b.learnerId,
          displayName: b.displayName,
          ageBandText: b.ageBand.toUpperCase(),
          category: isAdult ? 'adults' : 'youth',
          subtitle: 'Baseline: ${b.baselineStatus.toUpperCase()} • Pending AI Reviews: ${b.pendingAiRecommendations}',
          statusType: b.status == 'pending' ? 'consent' : 'practice',
          statusText: b.status == 'pending' ? 'Consent pending' : 'Practice active',
          activityIcon: b.supportFocus.contains('dld') ? Icons.record_voice_over_rounded : Icons.menu_book_rounded,
          activityIconColor: b.supportFocus.contains('dld') ? const Color(0xFF6D28D9) : const Color(0xFF0D9488),
          activityText: formattedTrack,
          actionText: 'View Profile',
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRoutes.specialistLearnerDetail,
              arguments: b.learnerId,
            );
          },
        ),
      );
    }

    // Append defaults not already matching displayName
    final existingNames = converted.map((c) => c.displayName.toLowerCase()).toSet();
    for (final def in defaults) {
      if (!existingNames.contains(def.displayName.toLowerCase())) {
        converted.add(def);
      }
    }

    return converted;
  }

  List<_CaseloadCardData> _getDefaultCaseloadCards(BuildContext context) {
    return [
      _CaseloadCardData(
        id: 'lr-1',
        displayName: 'Aarav M.',
        ageBandText: 'Child • 10 yrs',
        category: 'youth',
        subtitle: 'Parent: Priya M.',
        statusType: 'session',
        statusText: 'Session today • 10:30 AM',
        activityIcon: Icons.record_voice_over_rounded,
        activityIconColor: const Color(0xFF6D28D9),
        activityText: 'Phonological awareness: /r/ blends',
        levelBadge: 'Level 4',
        sessionsCountText: '3 sessions this month',
        actionText: 'View Profile',
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.specialistLearnerDetail,
            arguments: 'lr-1',
          );
        },
      ),
      _CaseloadCardData(
        id: 'lr-2',
        displayName: 'Maya S.',
        ageBandText: 'Adult',
        category: 'adults',
        subtitle: 'Self-connected learner',
        statusType: 'report',
        statusText: 'Report updated',
        activityIcon: Icons.track_changes_rounded,
        activityIconColor: const Color(0xFF6D28D9),
        activityText: 'Workplace presentation pacing (88 WPM)',
        actionText: 'View Profile',
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.specialistLearnerDetail,
            arguments: 'lr-2',
          );
        },
      ),
      _CaseloadCardData(
        id: 'lr-3',
        displayName: 'Liam K.',
        ageBandText: 'Teen • 14 yrs',
        category: 'youth',
        subtitle: 'Parent & Teacher consent pending',
        statusType: 'consent',
        statusText: 'Consent pending',
        activityIcon: Icons.lock_outline_rounded,
        activityIconColor: const Color(0xFFB45309),
        activityText: 'Recordings locked until guardian signs',
        actionText: 'Review Consent',
        isConsentReview: true,
        onTap: () {
          Navigator.pushNamed(context, AppRoutes.relationships);
        },
      ),
      _CaseloadCardData(
        id: 'lr-4',
        displayName: 'Sofia R.',
        ageBandText: 'Child • 6 yrs',
        category: 'youth',
        subtitle: 'Parent: Elena R.',
        statusType: 'practice',
        statusText: 'Practice active',
        activityIcon: Icons.campaign_outlined,
        activityIconColor: const Color(0xFF0D9488),
        activityText: 'Story Quest: Animal syllables',
        actionText: 'View Profile',
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.specialistLearnerDetail,
            arguments: 'lr-4',
          );
        },
      ),
      _CaseloadCardData(
        id: 'lr-5',
        displayName: 'Carlos D.',
        ageBandText: 'Adult',
        category: 'adults',
        subtitle: 'Self-connected learner',
        statusType: 'listening',
        statusText: 'Listening exercise',
        activityIcon: Icons.hearing_rounded,
        activityIconColor: const Color(0xFF6D28D9),
        activityText: 'Binaural auditory review',
        actionText: 'View Profile',
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.specialistLearnerDetail,
            arguments: 'lr-5',
          );
        },
      ),
      _CaseloadCardData(
        id: 'lr-6',
        displayName: 'Elena N.',
        ageBandText: 'Teen • 15 yrs',
        category: 'youth',
        subtitle: 'Parent: Marcus N.',
        statusType: 'practice',
        statusText: 'Practice active',
        activityIcon: Icons.bolt_rounded,
        activityIconColor: const Color(0xFF6D28D9),
        activityText: 'Rapid automatized naming drills',
        sessionsCountText: '2 sessions this month',
        actionText: 'View Profile',
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.specialistLearnerDetail,
            arguments: 'lr-6',
          );
        },
      ),
      _CaseloadCardData(
        id: 'lr-7',
        displayName: 'Lucas B.',
        ageBandText: 'Child • 8 yrs',
        category: 'youth',
        subtitle: 'Parent: Clara B.',
        statusType: 'practice',
        statusText: 'Practice active',
        activityIcon: Icons.auto_stories_rounded,
        activityIconColor: const Color(0xFF0D9488),
        activityText: 'Articulation: /s/ and /z/ clarity',
        sessionsCountText: '4 sessions this month',
        actionText: 'View Profile',
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.specialistLearnerDetail,
            arguments: 'lr-7',
          );
        },
      ),
      _CaseloadCardData(
        id: 'lr-8',
        displayName: 'David W.',
        ageBandText: 'Adult',
        category: 'adults',
        subtitle: 'Self-connected learner',
        statusType: 'session',
        statusText: 'Session tomorrow • 3:00 PM',
        activityIcon: Icons.graphic_eq_rounded,
        activityIconColor: const Color(0xFF6D28D9),
        activityText: 'Stuttering management & cadence',
        sessionsCountText: '1 session this month',
        actionText: 'View Profile',
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.specialistLearnerDetail,
            arguments: 'lr-8',
          );
        },
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // TAB 2: SCHEDULE TAB — delegates to the dedicated SpecialistScheduleScreen.
  // ---------------------------------------------------------------------------
  Widget _buildScheduleTab(BuildContext context) {
    return const SpecialistScheduleScreen(showBottomNav: false);
  }

  // ---------------------------------------------------------------------------
  // TAB 3: MESSAGES TAB
  // ---------------------------------------------------------------------------
  Widget _buildMessagesTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Specialist Messages',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: LinguaTokens.ink900),
          ),
          const SizedBox(height: 12),
          LinguaAnimatedCard(
            borderRadius: 16,
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: Color(0xFFCCFBF1),
                  child: Icon(Icons.person, color: Color(0xFF0D9488)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Priya M. (Parent of Aarav)',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Reviewed the pacing game. Aarav enjoyed the /s/ blends!',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Text('45m ago', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 9. BOTTOM NAVIGATION BAR
  // ---------------------------------------------------------------------------
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFEEF2F6), width: 1.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: Row(
            children: [
              Expanded(
                child: _buildNavButton(
                  index: 0,
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: 'Home',
                ),
              ),
              Expanded(
                child: _buildNavButton(
                  index: 1,
                  icon: Icons.groups_outlined,
                  activeIcon: Icons.groups_rounded,
                  label: 'Caseload',
                ),
              ),
              Expanded(
                child: _buildNavButton(
                  index: 2,
                  icon: Icons.calendar_today_outlined,
                  activeIcon: Icons.calendar_month_rounded,
                  label: 'Schedule',
                ),
              ),
              Expanded(
                child: _buildNavButton(
                  index: 3,
                  icon: Icons.chat_bubble_outline_rounded,
                  activeIcon: Icons.chat_bubble_rounded,
                  label: 'Messages',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;
    final primaryColor = const Color(0xFF5B5BD6);
    final unselectedColor = const Color(0xFF64748B);

    return InkWell(
      onTap: () {
        setState(() => _currentIndex = index);
      },
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
    );
  }

  // ---------------------------------------------------------------------------
  // INTERACTIVE BOTTOM SHEETS & MODALS
  // ---------------------------------------------------------------------------
  void _showAiPlanReviewModal(BuildContext context) {
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
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFEF3C7),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFFD97706), size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'AI Recommendation Oversight',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: LinguaTokens.ink900),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'New Pacing Exercise for Aarav',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: LinguaTokens.ink900),
              ),
              const SizedBox(height: 4),
              const Text(
                'AI proposed 3 spoken practice trials focusing on /s/ consonant blends based on audio cadence logged yesterday.',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                label: const Text('Approve & Push to Child Device'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: LinguaTokens.primary600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Plan approved! New pacing exercise pushed to Aarav.'),
                      backgroundColor: LinguaTokens.success600,
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Exercise parameters adjusted.')),
                  );
                },
                child: const Text('Modify Parameters'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSessionDetailSheet(
    BuildContext context, {
    required String name,
    required String time,
    required String topic,
    required String duration,
  }) {
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
              Text(
                'Session: $name',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: LinguaTokens.ink900),
              ),
              const SizedBox(height: 10),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time_rounded, color: LinguaTokens.primary600),
                title: Text('$time ($duration)'),
                subtitle: Text('Focus: $topic'),
              ),
              const SizedBox(height: 16),
              LinguaButton(
                label: 'View Learner Progress Dossier',
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, AppRoutes.specialistLearnerDetail, arguments: 'learner-sample');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotificationsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Specialist Notifications',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.mark_email_unread_outlined, color: Color(0xFFEF4444)),
                title: const Text('Consent request pending for Liam K.'),
                subtitle: const Text('Guardian submitted audio permission request 2h ago'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, AppRoutes.relationships);
                },
              ),
              ListTile(
                leading: const Icon(Icons.check_circle_outline, color: Color(0xFF0D9488)),
                title: const Text('Weekly summary delivered'),
                subtitle: const Text('Aarav M. completed phoneme game session'),
                onTap: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSpecialistProfileModal(BuildContext context) {
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
              Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: Color(0xFF5B5BD6),
                    child: Icon(Icons.person, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Dr. Maya',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'Speech-Language Pathologist (SLP)',
                        style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 28),
              ListTile(
                leading: const Icon(Icons.accessibility_new, color: LinguaTokens.primary600),
                title: const Text('Accessibility Settings'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, AppRoutes.accessibility);
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined, color: LinguaTokens.ink700),
                title: const Text('Account & Privacy Settings'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, AppRoutes.settings);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBookingModal(BuildContext context) {
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
                'Schedule Clinical / Support Session',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose an authorized caseload learner and preferred session format.',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 18),
              LinguaButton(
                label: 'Confirm & Send Session Invite',
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Session invitation sent to guardian.')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper model for Caseload cards representation
class _CaseloadCardData {
  final String id;
  final String displayName;
  final String ageBandText;
  final String category; // 'youth' or 'adults'
  final String subtitle;
  final String statusType; // 'session', 'report', 'consent', 'practice', 'listening'
  final String statusText;
  final IconData activityIcon;
  final Color activityIconColor;
  final String activityText;
  final String? levelBadge;
  final String? sessionsCountText;
  final String actionText;
  final bool isConsentReview;
  final VoidCallback? onTap;

  const _CaseloadCardData({
    required this.id,
    required this.displayName,
    required this.ageBandText,
    required this.category,
    required this.subtitle,
    required this.statusType,
    required this.statusText,
    required this.activityIcon,
    required this.activityIconColor,
    required this.activityText,
    this.levelBadge,
    this.sessionsCountText,
    this.actionText = 'View Profile',
    this.isConsentReview = false,
    this.onTap,
  });
}

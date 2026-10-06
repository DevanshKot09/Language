import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/router/app_router.dart';
import '../../application/collaboration_providers.dart';
import '../../domain/models/collaboration_models.dart';

/// Specialist Notifications Screen.
///
/// Designed to visually match the user-provided Stitch reference:
/// - Header with circular back button, "Notifications" title, and Specialist avatar circle.
/// - Filter chips: All, Sessions, Learners, Messages, Team.
/// - "Today" section with count badge and "Priority Queue" label.
/// - Dynamic notification cards:
///   * Live session reminder card with "Dismiss" and "Join Session →" actions.
///   * Guardian consent verified card with "Review Details" action.
///   * Teacher collaboration note card with "↩ Open Chat" action.
/// - "Yesterday & Earlier" section with "Archive" label.
///   * Progress summary generated card with "View Learning Deck →" action.
///   * Availability slot approved card with "Manage Schedule" action.
/// - Empty state: "You're all caught up" when no items match filters.
/// - Child-safe architecture & FERPA compliance footer.
/// - Responsive down to 320px width without RenderFlex overflow.
class SpecialistNotificationsScreen extends ConsumerWidget {
  const SpecialistNotificationsScreen({super.key});

  static const _ink = Color(0xFF1E1B4B);
  static const _primaryPurple = Color(0xFF5925DC);
  static const _lavenderBg = Color(0xFFF8F7FF);
  static const _lavenderBorder = Color(0xFFEDE9FE);
  static const _lavenderPill = Color(0xFFF1EFF9);
  static const _muted = Color(0xFF64748B);
  static const _tealLight = Color(0xFFCCFBF1);
  static const _tealDark = Color(0xFF0F766E);
  static const _amber = Color(0xFFD97706);
  static const _amberLight = Color(0xFFFEF3C7);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(specialistNotificationsNotifierProvider);
    final notifier = ref.read(specialistNotificationsNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: _lavenderBg,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top App Bar
            _buildAppBar(context, notifier),

            // 2. Filter Pills Row
            _buildFilterTabs(state, notifier),

            // 3. Scrollable Notifications List
            Expanded(
              child: RefreshIndicator(
                color: _primaryPurple,
                onRefresh: () => notifier.loadNotifications(),
                child: state.filteredNotifications.isEmpty
                    ? _buildEmptyState(context, state)
                    : SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // TODAY SECTION
                            if (state.todayNotifications.isNotEmpty) ...[
                              _buildSectionHeader(
                                title: 'Today',
                                countBadge: '${state.unreadCount} new',
                                queueLabel: 'Priority Queue',
                              ),
                              const SizedBox(height: 12),
                              ...state.todayNotifications.map(
                                (n) => Padding(
                                  padding: const EdgeInsets.only(bottom: 14.0),
                                  child: _buildNotificationCard(context, n, notifier),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],

                            // YESTERDAY & EARLIER SECTION
                            if (state.earlierNotifications.isNotEmpty) ...[
                              _buildSectionHeader(
                                title: 'Yesterday & Earlier',
                                queueLabel: 'Archive',
                              ),
                              const SizedBox(height: 12),
                              ...state.earlierNotifications.map(
                                (n) => Padding(
                                  padding: const EdgeInsets.only(bottom: 14.0),
                                  child: _buildNotificationCard(context, n, notifier),
                                ),
                              ),
                            ],

                            const SizedBox(height: 16),

                            // Child-Safe Architecture Reassurance
                            _buildComplianceFooter(),

                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. APP BAR
  // ---------------------------------------------------------------------------
  Widget _buildAppBar(BuildContext context, SpecialistNotificationsNotifier notifier) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Material(
            color: Colors.white,
            shape: const CircleBorder(),
            elevation: 1,
            shadowColor: Colors.black12,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushReplacementNamed(context, AppRoutes.specialistDashboard);
                }
              },
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.arrow_back, color: _ink, size: 22),
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Notifications',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: _ink,
                letterSpacing: -0.3,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Mark all as read',
            icon: const Icon(Icons.done_all_rounded, color: _primaryPurple, size: 20),
            onPressed: () {
              notifier.markAllAsRead();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All notifications marked as read.'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: _primaryPurple,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.person, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. FILTER TABS
  // ---------------------------------------------------------------------------
  Widget _buildFilterTabs(
    SpecialistNotificationsState state,
    SpecialistNotificationsNotifier notifier,
  ) {
    const filters = ['All', 'Sessions', 'Learners', 'Messages', 'Team'];
    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = state.selectedFilter == filter;
          return GestureDetector(
            onTap: () => notifier.setFilter(filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? _primaryPurple : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? _primaryPurple : _lavenderBorder,
                  width: 1.2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: _primaryPurple.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                filter,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : _muted,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. SECTION HEADER
  // ---------------------------------------------------------------------------
  Widget _buildSectionHeader({
    required String title,
    String? countBadge,
    required String queueLabel,
  }) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                  letterSpacing: -0.2,
                ),
              ),
              if (countBadge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _lavenderBorder,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    countBadge,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: _primaryPurple,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Text(
          queueLabel,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _muted,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 4. NOTIFICATION CARD
  // ---------------------------------------------------------------------------
  Widget _buildNotificationCard(
    BuildContext context,
    SpecialistNotificationModel item,
    SpecialistNotificationsNotifier notifier,
  ) {
    final iconConfig = _getNotificationIconConfig(item.iconType);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: item.isRead ? _lavenderBorder : _primaryPurple.withValues(alpha: 0.35),
          width: item.isRead ? 1.2 : 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x082B1277),
            blurRadius: 14,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Icon + Title & Supporting text
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconConfig.bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(iconConfig.icon, size: 20, color: iconConfig.iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.supportingText,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: const Color(0xFF475569),
                        height: 1.35,
                        fontStyle: item.iconType == 'chat' ? FontStyle.italic : FontStyle.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Meta Row: Time + Pill Badge
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.timestamp.contains('Oct') ? Icons.calendar_today_rounded : Icons.access_time_rounded,
                      size: 13,
                      color: _muted,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      item.timestamp,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: _muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (item.badgeLabel != null)
                _buildBadge(item.badgeLabel!, item.badgeType),
            ],
          ),

          // Action Buttons Row (if actionable)
          if (item.actionLabel != null) ...[
            const SizedBox(height: 12),
            _buildActionRow(context, item, notifier),
          ],
        ],
      ),
    );
  }

  Widget _buildBadge(String label, String? type) {
    Color bg = _lavenderPill;
    Color fg = _primaryPurple;

    if (type == 'interactive_audio') {
      bg = _tealLight;
      fg = _tealDark;
    } else if (type == 'consent_logged') {
      bg = const Color(0xFFEDE9FE);
      fg = _primaryPurple;
    } else if (type == 'classroom_synergy') {
      bg = _amberLight;
      fg = _amber;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          color: fg,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildActionRow(
    BuildContext context,
    SpecialistNotificationModel item,
    SpecialistNotificationsNotifier notifier,
  ) {
    if (item.actionType == 'join_session') {
      return Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 6,
        children: [
          TextButton(
            onPressed: () => notifier.dismissNotification(item.id),
            style: TextButton.styleFrom(
              foregroundColor: _muted,
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('Dismiss', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () {
              notifier.markAsRead(item.id);
              Navigator.pushNamed(
                context,
                AppRoutes.specialistLiveSession,
                arguments: item.targetId ?? 'sess_live_001',
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryPurple,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text('Join Session', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, size: 14),
              ],
            ),
          ),
        ],
      );
    } else if (item.actionType == 'open_chat') {
      return Align(
        alignment: Alignment.centerRight,
        child: ElevatedButton(
          onPressed: () {
            notifier.markAsRead(item.id);
            Navigator.pushNamed(
              context,
              AppRoutes.chatThread,
              arguments: {
                'conversation_id': item.targetId ?? 'conv-aarav',
                'title': 'Mrs. Davies (Teacher)',
                'subtitle': 'Aarav Mehta • Classroom Synergy',
              },
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF006257),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.reply_rounded, size: 15),
              SizedBox(width: 6),
              Text('Open Chat', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
            ],
          ),
        ),
      );
    } else if (item.actionType == 'review_details') {
      return Align(
        alignment: Alignment.centerRight,
        child: ElevatedButton(
          onPressed: () {
            notifier.markAsRead(item.id);
            Navigator.pushNamed(context, AppRoutes.specialistConsentSharing);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _lavenderPill,
            foregroundColor: _primaryPurple,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          child: const Text('Review Details', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
        ),
      );
    } else if (item.actionType == 'view_deck') {
      return Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: () {
            notifier.markAsRead(item.id);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Opening Sofia K. practice deck review.')),
            );
          },
          style: TextButton.styleFrom(foregroundColor: _primaryPurple),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Flexible(
                child: Text(
                  'View Learning Deck',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 4),
              Icon(Icons.arrow_forward_rounded, size: 14),
            ],
          ),
        ),
      );
    } else if (item.actionType == 'manage_schedule') {
      return Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: () {
            notifier.markAsRead(item.id);
            Navigator.pushNamed(context, AppRoutes.specialistSchedule);
          },
          style: TextButton.styleFrom(foregroundColor: _ink),
          child: const Text('Manage Schedule', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  _IconConfig _getNotificationIconConfig(String iconType) {
    switch (iconType) {
      case 'video':
        return const _IconConfig(Icons.videocam_rounded, _tealDark, _tealLight);
      case 'shield':
        return const _IconConfig(Icons.shield_outlined, _primaryPurple, Color(0xFFEDE9FE));
      case 'chat':
        return const _IconConfig(Icons.chat_bubble_outline_rounded, _tealDark, _tealLight);
      case 'analytics':
        return const _IconConfig(Icons.auto_graph_rounded, _amber, _amberLight);
      case 'calendar':
        return const _IconConfig(Icons.calendar_month_outlined, _primaryPurple, Color(0xFFEDE9FE));
      default:
        return const _IconConfig(Icons.notifications_active_outlined, _primaryPurple, Color(0xFFEDE9FE));
    }
  }

  // ---------------------------------------------------------------------------
  // 5. EMPTY STATE
  // ---------------------------------------------------------------------------
  Widget _buildEmptyState(BuildContext context, SpecialistNotificationsState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFEDE9FE),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.done_all_rounded, size: 32, color: _primaryPurple),
            ),
            const SizedBox(height: 16),
            const Text(
              "You're all caught up",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              state.selectedFilter == 'All'
                  ? 'No notifications right now. Everything is running smoothly.'
                  : 'No notifications in category "${state.selectedFilter}".',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: _muted,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 6. COMPLIANCE & FERPA FOOTER
  // ---------------------------------------------------------------------------
  Widget _buildComplianceFooter() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 5,
              children: const [
                Icon(Icons.verified_user_outlined, size: 14, color: _tealDark),
                Text(
                  'Lingua Child-Safe Architecture',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: _tealDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'All speech recordings, transcripts, and learner collaboration logs are end-to-end encrypted & FERPA compliant.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.5,
                color: _muted,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconConfig {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  const _IconConfig(this.icon, this.iconColor, this.bgColor);
}

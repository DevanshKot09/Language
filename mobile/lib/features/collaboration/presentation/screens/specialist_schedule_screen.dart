import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/router/app_router.dart';
import '../../application/collaboration_providers.dart';
import '../../domain/models/collaboration_models.dart';

/// Specialist Schedule & Appointments screen (Stitch reference).
///
/// Data-driven: every session, request and count comes from
/// [specialistScheduleProvider]. Nothing is hard-coded; when there is no
/// schedule data the screen shows the "Your schedule is clear" state.
///
/// Used in two places:
/// * Embedded as the Schedule tab of the Specialist Dashboard
///   (`showBottomNav: false`, the dashboard owns the navigation bar).
/// * Standalone via [AppRoutes.specialistSchedule] (e.g. from Learner
///   Profile → Schedule Session), with its own bottom navigation.
class SpecialistScheduleScreen extends ConsumerStatefulWidget {
  final bool showBottomNav;

  /// Optional "now" override, used by widget tests for deterministic dates.
  final DateTime? now;

  const SpecialistScheduleScreen({super.key, this.showBottomNav = true, this.now});

  @override
  ConsumerState<SpecialistScheduleScreen> createState() => _SpecialistScheduleScreenState();
}

class _SpecialistScheduleScreenState extends ConsumerState<SpecialistScheduleScreen> {
  static const _primary = Color(0xFF4318D1);
  static const _ink = Color(0xFF1E1B4B);
  static const _muted = Color(0xFF64748B);
  static const _border = Color(0xFFE2E8F0);
  static const _teal = Color(0xFF0D9488);

  static const _weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
  static const _weekdaysLong = ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'];
  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  late DateTime _selectedDate;
  int _weekOffset = 0;

  DateTime get _now => widget.now ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    final n = _now;
    _selectedDate = DateTime(n.year, n.month, n.day);
  }

  DateTime get _weekStart {
    final today = DateTime(_now.year, _now.month, _now.day);
    return today.subtract(Duration(days: today.weekday - 1)).add(Duration(days: 7 * _weekOffset));
  }

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final scheduleAsync = ref.watch(specialistScheduleProvider);

    final body = SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: _primary,
        onRefresh: () async => ref.invalidate(specialistScheduleProvider),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: scheduleAsync.when(
            loading: () => _buildLoading(),
            error: (_, _) => _buildError(),
            data: (sessions) => _buildContent(sessions),
          ),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFE),
      body: body,
      bottomNavigationBar: widget.showBottomNav ? _buildBottomNav() : null,
    );
  }

  // ---------------------------------------------------------------------------
  // CONTENT
  // ---------------------------------------------------------------------------
  Widget _buildContent(List<SpecialistScheduleSession> all) {
    final daySessions = all
        .where((s) => _sameDay(s.startsAt, _selectedDate) && s.status != ScheduleSessionStatus.requestPending)
        .toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    final requests = all.where((s) => s.status == ScheduleSessionStatus.requestPending).toList();

    final upcoming = daySessions
        .where((s) =>
            (s.status == ScheduleSessionStatus.upcoming || s.status == ScheduleSessionStatus.confirmed) &&
            s.startsAt.add(Duration(minutes: s.durationMinutes)).isAfter(_now))
        .toList();
    final done = daySessions.where((s) => s.status == ScheduleSessionStatus.completed).length;
    final next = upcoming.isNotEmpty ? upcoming.first : null;
    final datesWithSessions = all
        .where((s) => s.status != ScheduleSessionStatus.requestPending)
        .map((s) => DateTime(s.startsAt.year, s.startsAt.month, s.startsAt.day))
        .toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(),
        const SizedBox(height: 14),
        _buildSummaryCard(daySessions.length, upcoming.length, done),
        const SizedBox(height: 16),
        _buildDateSelector(datesWithSessions),
        const SizedBox(height: 16),
        if (next != null) ...[
          _AnimatedEntry(key: ValueKey('next-${next.id}'), child: _buildNextSessionCard(next)),
          const SizedBox(height: 16),
        ],
        if (requests.isNotEmpty) ...[
          _buildRequestsCard(requests),
          const SizedBox(height: 16),
        ],
        if (daySessions.isEmpty)
          _buildEmptyState()
        else
          _buildDaySchedule(daySessions, next),
        const SizedBox(height: 16),
        _buildAvailabilityCard(),
      ],
    );
  }

  // 1. HEADER -----------------------------------------------------------------
  Widget _buildHeader() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Schedule',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: _ink, letterSpacing: -0.5, height: 1.15),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 2),
              Text(
                'Your upcoming support sessions',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _muted),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Semantics(
          button: true,
          label: 'Go to today',
          child: Material(
            color: const Color(0xFFF1F0FB),
            shape: const CircleBorder(side: BorderSide(color: _border)),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _goToToday,
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(Icons.today_rounded, color: _primary, size: 20),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Semantics(
          button: true,
          label: 'Schedule new session',
          child: ElevatedButton.icon(
            key: const Key('schedule_new_session_button'),
            onPressed: _showNewSessionSheet,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('New Session', maxLines: 1, softWrap: false),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            ),
          ),
        ),
      ],
    );
  }

  // 2. SUMMARY ----------------------------------------------------------------
  Widget _buildSummaryCard(int total, int upcoming, int done) {
    final d = _selectedDate;
    final dateLabel = '${_weekdaysLong[d.weekday - 1]}, ${_months[d.month - 1].substring(0, 3).toUpperCase()} ${d.day}';
    final title = total == 0 ? 'No sessions scheduled' : '$total ${total == 1 ? 'Session' : 'Sessions'} Scheduled';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: const Color(0xFFF1F0FB), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.calendar_today_rounded, color: _primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dateLabel,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _muted, letterSpacing: 0.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(title,
                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: _ink),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (total > 0) ...[
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                _pill('$upcoming upcoming', const Color(0xFFCCFBF1), const Color(0xFF0F766E), dot: _teal),
                const SizedBox(height: 4),
                _pill('$done done', const Color(0xFFEDE9FE), const Color(0xFF6D28D9)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // 3. DATE SELECTOR ----------------------------------------------------------
  Widget _buildDateSelector(Set<DateTime> datesWithSessions) {
    final start = _weekStart;
    final mid = start.add(const Duration(days: 3));
    final weekLabel = _weekOffset == 0
        ? 'This Week'
        : _weekOffset == 1
            ? 'Next Week'
            : _weekOffset == -1
                ? 'Last Week'
                : '${_months[start.month - 1].substring(0, 3)} ${start.day}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${_months[mid.month - 1]} ${mid.year}',
                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: _ink),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _weekArrow(Icons.chevron_left_rounded, 'Previous week', () => _shiftWeek(-1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(weekLabel,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _primary)),
            ),
            _weekArrow(Icons.chevron_right_rounded, 'Next week', () => _shiftWeek(1)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: List.generate(7, (i) {
            final date = start.add(Duration(days: i));
            final isSelected = _sameDay(date, _selectedDate);
            final isToday = _sameDay(date, _now);
            final hasSessions = datesWithSessions.contains(date);
            final isWeekend = i >= 5;
            return Expanded(
              child: Semantics(
                button: true,
                selected: isSelected,
                label: '${_weekdaysLong[i]} ${_months[date.month - 1]} ${date.day}'
                    '${isToday ? ', today' : ''}${hasSessions ? ', has sessions' : ''}',
                child: GestureDetector(
                  key: Key('schedule_day_$i'),
                  onTap: () => setState(() => _selectedDate = date),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? _primary : Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: isSelected ? null : Border.all(color: isToday ? const Color(0xFFC4B5FD) : _border),
                      boxShadow: isSelected
                          ? [BoxShadow(color: _primary.withValues(alpha: 0.32), blurRadius: 8, offset: const Offset(0, 3))]
                          : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(_weekdays[i],
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? Colors.white : (isWeekend ? const Color(0xFF94A3B8) : _muted),
                              )),
                        ),
                        const SizedBox(height: 3),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('${date.day}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: isSelected ? Colors.white : (isWeekend ? const Color(0xFF94A3B8) : _ink),
                              )),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: hasSessions
                                ? (isSelected ? const Color(0xFF5EEAD4) : const Color(0xFFA5B4FC))
                                : Colors.transparent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _weekArrow(IconData icon, String label, VoidCallback onTap) {
    return Semantics(
      button: true,
      label: label,
      child: InkResponse(
        onTap: onTap,
        radius: 20,
        child: Padding(padding: const EdgeInsets.all(6), child: Icon(icon, color: _primary, size: 20)),
      ),
    );
  }

  // 4. NEXT SESSION HERO ------------------------------------------------------
  Widget _buildNextSessionCard(SpecialistScheduleSession s) {
    final minutesAway = s.startsAt.difference(_now).inMinutes;
    final String timing;
    if (minutesAway <= 0) {
      timing = 'IN PROGRESS';
    } else if (minutesAway < 60) {
      timing = 'IN $minutesAway MIN';
    } else if (_sameDay(s.startsAt, _now)) {
      timing = 'AT ${_formatTime(s.startsAt)}';
    } else {
      timing = _formatTime(s.startsAt);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3812B2), Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: _primary.withValues(alpha: 0.28), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Flexible(
                child: _glassPill(
                  'NEXT SESSION • $timing',
                  dot: const Color(0xFF5EEAD4),
                ),
              ),
              const SizedBox(width: 8),
              _glassPill('${s.durationMinutes} min'),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _avatar(s.learnerName, size: 44, onDark: true),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(s.learnerName,
                              style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: Colors.white),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 6),
                        _glassPill(_ageLabel(s.ageBand), small: true),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.videocam_rounded, size: 14, color: Color(0xFF5EEAD4)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(s.sessionType,
                              style: const TextStyle(fontSize: 12, color: Color(0xFFE0E7FF)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (s.focus != null && s.focus!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.flag_outlined, size: 13, color: Color(0xFF5EEAD4)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('Focus: ${s.focus}',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Semantics(
                  button: true,
                  label: 'Join session with ${s.learnerName}',
                  child: ElevatedButton.icon(
                    key: const Key('schedule_join_next_button'),
                    onPressed: () => Navigator.pushNamed(
                      context,
                      AppRoutes.specialistLiveSession,
                      arguments: s,
                    ),
                    icon: const Icon(Icons.videocam_rounded, size: 19),
                    label: const Text('Join Session', maxLines: 1, softWrap: false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _primary,
                      elevation: 0,
                      minimumSize: const Size(0, 46),
                      textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _glassIconButton(Icons.person_outline_rounded, 'Open ${s.learnerName} profile', () => _openLearner(s.learnerId)),
              const SizedBox(width: 8),
              _glassIconButton(Icons.more_vert_rounded, 'Session options', () => _showSessionOptions(s)),
            ],
          ),
        ],
      ),
    );
  }

  // 5. REQUESTS ---------------------------------------------------------------
  Widget _buildRequestsCard(List<SpecialistScheduleSession> requests) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_active_rounded, color: Color(0xFFD97706), size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text('Session Request (${requests.length})',
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: _ink),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              _pill('Requires Response', const Color(0xFFFEF3C7), const Color(0xFF92400E)),
            ],
          ),
          for (final r in requests.take(3)) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEDE9FE)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.requestedVia != null ? '${r.learnerName} (via ${r.requestedVia})' : r.learnerName,
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _ink),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text('${r.sessionType} • ${r.durationMinutes} min',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.access_time_rounded, size: 12, color: _muted),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text('Requested: ${_formatShortDate(r.startsAt)} • ${_formatTime(r.startsAt)}',
                                  style: const TextStyle(fontSize: 11, color: _muted),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Semantics(
                    button: true,
                    label: 'Accept request from ${r.learnerName}',
                    child: ElevatedButton.icon(
                      onPressed: () => _respondToRequest(r, accept: true),
                      icon: const Icon(Icons.check_rounded, size: 14),
                      label: const Text('Accept'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F766E),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'Decline request',
                    onPressed: () => _respondToRequest(r, accept: false),
                    icon: const Icon(Icons.close_rounded, size: 18, color: _muted),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 6. DAY SCHEDULE -----------------------------------------------------------
  Widget _buildDaySchedule(List<SpecialistScheduleSession> sessions, SpecialistScheduleSession? next) {
    final isToday = _sameDay(_selectedDate, _now);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(isToday ? "Today's Schedule" : 'Schedule for ${_formatShortDate(_selectedDate)}',
                  style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: _ink),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            Text('${sessions.length} Total',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _muted)),
          ],
        ),
        const SizedBox(height: 14),
        for (var i = 0; i < sessions.length; i++) ...[
          _AnimatedEntry(
            key: ValueKey('row-${sessions[i].id}'),
            delayMs: 40 * i,
            child: _buildTimelineRow(sessions[i], isNext: next?.id == sessions[i].id, isLast: i == sessions.length - 1),
          ),
          if (i != sessions.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildTimelineRow(SpecialistScheduleSession s, {required bool isNext, required bool isLast}) {
    final timeParts = _formatTime(s.startsAt).split(' ');
    final timeColor = isNext ? _primary : _ink;
    final isCancelled = s.status == ScheduleSessionStatus.cancelled;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(timeParts.first,
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: timeColor)),
                ),
                Text(timeParts.length > 1 ? timeParts[1] : '',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isNext ? _primary : _muted)),
                Text('${s.durationMinutes}m', style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                if (!isLast) ...[
                  const SizedBox(height: 6),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Container(width: 1.5, color: _border),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: EdgeInsets.fromLTRB(12, isNext ? 14 : 12, 6, 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isNext ? const Color(0xFFA5B4FC) : _border,
                      width: isNext ? 1.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _primary.withValues(alpha: isNext ? 0.07 : 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(s.learnerName,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: isCancelled ? _muted : _ink,
                                  decoration: isCancelled ? TextDecoration.lineThrough : null,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: 6),
                          _statusBadge(s.status),
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              tooltip: 'Session options',
                              onPressed: () => _showSessionOptions(s),
                              icon: const Icon(Icons.more_vert_rounded, size: 18, color: _muted),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text('${_ageLabel(s.ageBand)} • ${s.sessionType}',
                            style: const TextStyle(fontSize: 11.5, color: _muted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(height: 8),
                      _buildRowActions(s, isNext),
                    ],
                  ),
                ),
                if (isNext)
                  Positioned(
                    top: -9,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(8)),
                      child: const Text('NEXT',
                          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRowActions(SpecialistScheduleSession s, bool isNext) {
    if (s.status == ScheduleSessionStatus.completed || s.status == ScheduleSessionStatus.cancelled) {
      return _textLink('View Learner Profile', () => _openLearner(s.learnerId));
    }
    return Wrap(
      spacing: 10,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (isNext)
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(
              context,
              AppRoutes.specialistLiveSession,
              arguments: s,
            ),
            icon: const Icon(Icons.play_arrow_rounded, size: 16),
            label: const Text('Join'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size(0, 34),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
            ),
          ),
        _textLink(isNext ? 'Details' : 'Manage Session', () => _openLearner(s.learnerId)),
      ],
    );
  }

  // 7. EMPTY STATE ------------------------------------------------------------
  Widget _buildEmptyState() {
    final isToday = _sameDay(_selectedDate, _now);
    return Container(
      key: const Key('schedule_empty_state'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(color: Color(0xFFF1F0FB), shape: BoxShape.circle),
            child: const Icon(Icons.event_available_rounded, color: _primary, size: 26),
          ),
          const SizedBox(height: 12),
          Text(isToday ? 'Your schedule is clear' : 'No sessions on this day',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: _ink)),
          const SizedBox(height: 4),
          const Text('Upcoming learner sessions will appear here.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: _muted)),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _showNewSessionSheet,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Schedule Session'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _primary,
              minimumSize: const Size(0, 44),
              side: const BorderSide(color: Color(0xFFC4B5FD)),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            ),
          ),
        ],
      ),
    );
  }

  // 8. AVAILABILITY -----------------------------------------------------------
  Widget _buildAvailabilityCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFE),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0E7FF)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: const Color(0xFFEDE9FE), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.event_note_rounded, color: _primary, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Weekly Availability',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _ink),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                SizedBox(height: 2),
                Text('Set when learners can book sessions with you',
                    style: TextStyle(fontSize: 11.5, color: _muted), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: _showAvailabilityInfo,
            style: OutlinedButton.styleFrom(
              foregroundColor: _primary,
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              side: const BorderSide(color: Color(0xFFDDD6FE)),
              backgroundColor: Colors.white,
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [Text('Manage'), SizedBox(width: 3), Icon(Icons.arrow_forward_rounded, size: 13)],
            ),
          ),
        ],
      ),
    );
  }

  // LOADING / ERROR -----------------------------------------------------------
  Widget _buildLoading() {
    Widget box(double h, {double r = 20}) => Container(
          height: h,
          decoration: BoxDecoration(color: const Color(0xFFEDEAF7), borderRadius: BorderRadius.circular(r)),
        );
    return Semantics(
      label: 'Loading schedule',
      child: Column(
        key: const Key('schedule_loading'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Expanded(child: Align(alignment: Alignment.centerLeft, child: SizedBox(width: 150, child: box(30, r: 10)))),
            SizedBox(width: 110, child: box(44, r: 22)),
          ]),
          const SizedBox(height: 14),
          box(64),
          const SizedBox(height: 16),
          Row(children: List.generate(7, (_) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: box(62, r: 22))))),
          const SizedBox(height: 16),
          box(190, r: 24),
          const SizedBox(height: 16),
          box(92, r: 18),
          const SizedBox(height: 12),
          box(92, r: 18),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Column(
      key: const Key('schedule_error'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(),
        const SizedBox(height: 40),
        const Icon(Icons.cloud_off_rounded, size: 40, color: Color(0xFF94A3B8)),
        const SizedBox(height: 12),
        const Text("We couldn't load your schedule",
            textAlign: TextAlign.center, style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: _ink)),
        const SizedBox(height: 4),
        const Text('Please check your connection and try again.',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: _muted)),
        const SizedBox(height: 16),
        Center(
          child: ElevatedButton(
            onPressed: () => ref.invalidate(specialistScheduleProvider),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(140, 46),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
            ),
            child: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  // BOTTOM NAV (standalone only) ---------------------------------------------
  Widget _buildBottomNav() {
    Widget item(IconData icon, String label, {bool selected = false, VoidCallback? onTap}) {
      return Expanded(
        child: Semantics(
          button: true,
          selected: selected,
          label: label,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFEDE9FE) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 22, color: selected ? const Color(0xFF5B5BD6) : _muted),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(label,
                        maxLines: 1,
                        softWrap: false,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                          color: selected ? const Color(0xFF5B5BD6) : _muted,
                        )),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    void goToTab(int index) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.specialistDashboard,
        arguments: index,
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F0FB), width: 1.2)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: Row(
            children: [
              item(Icons.home_outlined, 'Home', onTap: () => goToTab(0)),
              item(Icons.groups_outlined, 'Caseload', onTap: () => goToTab(1)),
              item(Icons.calendar_month_rounded, 'Schedule', selected: true),
              item(Icons.chat_bubble_outline_rounded, 'Messages', onTap: () => goToTab(3)),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ACTIONS
  // ---------------------------------------------------------------------------
  void _goToToday() {
    final n = _now;
    setState(() {
      _weekOffset = 0;
      _selectedDate = DateTime(n.year, n.month, n.day);
    });
  }

  void _shiftWeek(int delta) {
    setState(() {
      _weekOffset += delta;
      final idx = _selectedDate.weekday - 1;
      _selectedDate = _weekStart.add(Duration(days: idx));
    });
  }

  /// Join / Details route into the existing Learner Profile, which owns the
  /// live-session entry point. No meeting links are generated here.
  void _openLearner(String learnerId) {
    if (learnerId.isEmpty) return;
    Navigator.pushNamed(context, AppRoutes.specialistLearnerDetail, arguments: learnerId);
  }

  void _respondToRequest(SpecialistScheduleSession r, {required bool accept}) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Responding to session requests will be available once scheduling sync is enabled.')),
    );
  }

  void _showSessionOptions(SpecialistScheduleSession s) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('${s.learnerName} • ${_formatTime(s.startsAt)}',
                  style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: _ink),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.person_outline_rounded, color: _primary),
                title: const Text('Open Learner Profile'),
                onTap: () {
                  Navigator.pop(ctx);
                  _openLearner(s.learnerId);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// "New Session" picks a real caseload learner and continues in the
  /// existing Learner Profile → Schedule flow (no duplicate booking system).
  void _showNewSessionSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Consumer(
        builder: (ctx, ref, _) {
          final caseload = ref.watch(specialistCaseloadProvider);
          return SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Schedule a Session',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _ink)),
                    const SizedBox(height: 4),
                    const Text('Choose a learner from your caseload to continue.',
                        style: TextStyle(fontSize: 12.5, color: _muted)),
                    const SizedBox(height: 12),
                    Flexible(
                      child: caseload.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator(color: _primary)),
                        ),
                        error: (_, _) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text("We couldn't load your learners.", style: TextStyle(color: _muted)),
                              TextButton(
                                onPressed: () => ref.invalidate(specialistCaseloadProvider),
                                child: const Text('Try Again'),
                              ),
                            ],
                          ),
                        ),
                        data: (items) => items.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Text(
                                  'No learners are connected to you yet. Learners appear here once a family or learner connects.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12.5, color: _muted),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                itemCount: items.length,
                                separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFF1F0FB)),
                                itemBuilder: (_, i) {
                                  final l = items[i];
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: _avatar(l.displayName, size: 40),
                                    title: Text(l.displayName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.w700, color: _ink)),
                                    subtitle: Text(_ageLabel(l.ageBand),
                                        maxLines: 1, overflow: TextOverflow.ellipsis),
                                    trailing: const Icon(Icons.chevron_right_rounded, color: _muted),
                                    onTap: () {
                                      Navigator.pop(ctx);
                                      _openLearner(l.learnerId);
                                    },
                                  );
                                },
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAvailabilityInfo() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Weekly Availability',
                  style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: _ink)),
              const SizedBox(height: 6),
              const Text(
                "Availability hasn't been set up yet. Once enabled, families and learners will be able to request sessions within the times you choose.",
                style: TextStyle(fontSize: 12.5, color: _muted, height: 1.4),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
                ),
                child: const Text('Got it', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SMALL HELPERS
  // ---------------------------------------------------------------------------
  BoxDecoration _cardDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
        boxShadow: [BoxShadow(color: _primary.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
      );

  Widget _pill(String text, Color bg, Color fg, {Color? dot}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot != null) ...[
            Container(width: 5, height: 5, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
            const SizedBox(width: 4),
          ],
          Text(text, maxLines: 1, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: fg)),
        ],
      ),
    );
  }

  Widget _glassPill(String text, {Color? dot, bool small = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 7 : 8, vertical: small ? 2.5 : 4),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot != null) ...[
            Container(width: 6, height: 6, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: small ? 10 : 10.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.3,
                )),
          ),
        ],
      ),
    );
  }

  Widget _glassIconButton(IconData icon, String label, VoidCallback onTap) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.white.withValues(alpha: 0.2),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(width: 44, height: 44, child: Icon(icon, color: Colors.white, size: 20)),
        ),
      ),
    );
  }

  Widget _avatar(String name, {double size = 40, bool onDark = false}) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    final initials = parts.isEmpty
        ? '?'
        : (parts.length == 1 ? parts.first[0] : '${parts.first[0]}${parts.last[0]}').toUpperCase();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: onDark ? const Color(0xFF6366F1) : const Color(0xFFEDE9FE),
        borderRadius: BorderRadius.circular(size * 0.32),
        border: onDark ? Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5) : null,
      ),
      alignment: Alignment.center,
      child: Text(initials,
          style: TextStyle(
            fontSize: size * 0.36,
            fontWeight: FontWeight.w800,
            color: onDark ? Colors.white : _primary,
          )),
    );
  }

  Widget _statusBadge(ScheduleSessionStatus status) {
    late final String label;
    late final IconData icon;
    late final Color bg;
    late final Color fg;
    switch (status) {
      case ScheduleSessionStatus.upcoming:
        label = 'Upcoming';
        icon = Icons.schedule_rounded;
        bg = const Color(0xFFCCFBF1);
        fg = const Color(0xFF0F766E);
      case ScheduleSessionStatus.confirmed:
        label = 'Confirmed';
        icon = Icons.event_available_rounded;
        bg = const Color(0xFFEDE9FE);
        fg = const Color(0xFF6D28D9);
      case ScheduleSessionStatus.completed:
        label = 'Completed';
        icon = Icons.check_circle_rounded;
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF334155);
      case ScheduleSessionStatus.cancelled:
        label = 'Cancelled';
        icon = Icons.cancel_outlined;
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFB91C1C);
      case ScheduleSessionStatus.requestPending:
        label = 'Request Pending';
        icon = Icons.hourglass_top_rounded;
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFF92400E);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 3),
          Text(label, maxLines: 1, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: fg)),
        ],
      ),
    );
  }

  Widget _textLink(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _primary)),
            const SizedBox(width: 3),
            const Icon(Icons.arrow_forward_rounded, size: 13, color: _primary),
          ],
        ),
      ),
    );
  }

  String _ageLabel(String band) {
    switch (band) {
      case 'child':
        return 'Child';
      case 'teen':
        return 'Teen';
      case 'adult':
        return 'Adult';
      default:
        return band.isEmpty ? 'Learner' : '${band[0].toUpperCase()}${band.substring(1)}';
    }
  }

  String _formatTime(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    return '${h.toString().padLeft(2, '0')}:$m ${t.hour < 12 ? 'AM' : 'PM'}';
  }

  String _formatShortDate(DateTime d) =>
      '${_weekdays[d.weekday - 1][0]}${_weekdays[d.weekday - 1].substring(1).toLowerCase()}, '
      '${_months[d.month - 1].substring(0, 3)} ${d.day}';
}

/// Subtle fade + slide entrance used for session cards.
class _AnimatedEntry extends StatelessWidget {
  final Widget child;
  final int delayMs;

  const _AnimatedEntry({super.key, required this.child, this.delayMs = 0});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 260 + delayMs),
      curve: Curves.easeOutCubic,
      builder: (_, v, c) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, (1 - v) * 8), child: c),
      ),
      child: child,
    );
  }
}

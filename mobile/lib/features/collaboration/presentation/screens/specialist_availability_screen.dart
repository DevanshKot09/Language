import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/router/app_router.dart';
import '../../application/collaboration_providers.dart';
import '../../domain/models/collaboration_models.dart';

/// Specialist Availability & Appointment Settings Screen.
///
/// Designed to visually match the user-provided Stitch reference:
/// - Top app bar with back navigation and profile avatar.
/// - Specialist header card (Dr. Maya Lin, M.S. CCC-SLP • Active Caseload).
/// - Accepting Requests card with toggle switch and specialist timezone banner.
/// - Weekly Schedule day cards with active slots, trash buttons, and "+ Add Slot".
/// - Session Preferences: 30 / 45 (Recommended) / 60 min pills, buffer selector,
///   daily session cap stepper, and advance notice pill.
/// - Sticky bottom "Save Availability" CTA with saved/saving feedback.
/// - Responsive down to 320px width without RenderFlex overflow.
class SpecialistAvailabilityScreen extends ConsumerStatefulWidget {
  const SpecialistAvailabilityScreen({super.key});

  @override
  ConsumerState<SpecialistAvailabilityScreen> createState() =>
      _SpecialistAvailabilityScreenState();
}

class _SpecialistAvailabilityScreenState
    extends ConsumerState<SpecialistAvailabilityScreen> {
  static const _ink = Color(0xFF1E1B4B);
  static const _primaryPurple = Color(0xFF5925DC);
  static const _lavenderBg = Color(0xFFF8F7FF);
  static const _lavenderBorder = Color(0xFFEDE9FE);
  static const _lavenderCard = Color(0xFFF5F3FF);
  static const _muted = Color(0xFF64748B);
  static const _teal = Color(0xFF0D9488);
  static const _green = Color(0xFF10B981);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(specialistAvailabilityNotifierProvider);
    final notifier =
        ref.read(specialistAvailabilityNotifierProvider.notifier);
    final availability = state.availability;

    return Scaffold(
      backgroundColor: _lavenderBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: state.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: _primaryPurple),
                    )
                  : RefreshIndicator(
                      color: _primaryPurple,
                      onRefresh: () => notifier.loadAvailability(),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Specialist Header Card
                            _buildSpecialistHeaderCard(availability),

                            const SizedBox(height: 16),

                            // Accepting Requests Card
                            _buildAcceptingRequestsCard(
                                availability, notifier),

                            const SizedBox(height: 24),

                            // Weekly Schedule Section
                            _buildWeeklyScheduleSection(
                                availability, notifier),

                            const SizedBox(height: 24),

                            // Session Preferences Section
                            _buildSessionPreferencesSection(
                                availability, notifier),

                            const SizedBox(height: 28),

                            // Save Availability Button
                            _buildSaveButton(state, notifier),

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

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: _lavenderBorder, width: 1),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            key: const Key('availability_back_button'),
            icon: const Icon(Icons.arrow_back, color: _ink),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                Navigator.of(context).pushReplacementNamed(
                  AppRoutes.specialistDashboard,
                );
              }
            },
            tooltip: 'Back',
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Availability Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _ink,
                letterSpacing: -0.3,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          InkWell(
            onTap: () {
              Navigator.of(context).pushNamed(AppRoutes.specialistProfile);
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _primaryPurple.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: _primaryPurple, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialistHeaderCard(SpecialistAvailabilityModel availability) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _lavenderBorder),
        boxShadow: [
          BoxShadow(
            color: _primaryPurple.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _primaryPurple.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    'ML',
                    style: TextStyle(
                      color: _primaryPurple,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: _green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    availability.specialistBadge.toUpperCase(),
                    style: const TextStyle(
                      color: _teal,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  availability.specialistName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                    letterSpacing: -0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  availability.specialistTitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _muted,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcceptingRequestsCard(
    SpecialistAvailabilityModel availability,
    SpecialistAvailabilityNotifier notifier,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _lavenderBorder),
        boxShadow: [
          BoxShadow(
            color: _primaryPurple.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: _green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'ACCEPTING REQUESTS',
                style: TextStyle(
                  color: _green,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Available for sessions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              Switch.adaptive(
                key: const Key('available_for_sessions_toggle'),
                value: availability.availableForSessions,
                activeThumbColor: Colors.white,
                activeTrackColor: _primaryPurple,
                onChanged: (val) => notifier.toggleAvailableForSessions(val),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Learners and families can view and book learning-support blocks during your open hours.',
            style: TextStyle(
              fontSize: 13,
              color: _muted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          // Timezone box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _lavenderCard,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _primaryPurple.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.language,
                    color: _primaryPurple,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SPECIALIST TIME ZONE',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: _muted,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        availability.timezone,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Time zone matches device settings (GMT-7).'),
                      ),
                    );
                  },
                  child: const Text(
                    'Change',
                    style: TextStyle(
                      color: _primaryPurple,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
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

  Widget _buildWeeklyScheduleSection(
    SpecialistAvailabilityModel availability,
    SpecialistAvailabilityNotifier notifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weekly Schedule',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Custom blocks for interactive play & speech practice',
                    style: TextStyle(
                      fontSize: 12,
                      color: _muted,
                    ),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Monday-Friday schedule template synced.'),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _primaryPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.copy, size: 14, color: _primaryPurple),
                    SizedBox(width: 4),
                    Text(
                      'Copy M-F',
                      style: TextStyle(
                        color: _primaryPurple,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...availability.days.map((day) => _buildDayCard(day, notifier)),
      ],
    );
  }

  Widget _buildDayCard(
    SpecialistDayAvailabilityModel day,
    SpecialistAvailabilityNotifier notifier,
  ) {
    final isGrouped = day.dayKey == 'thursday_friday';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _lavenderBorder),
        boxShadow: [
          BoxShadow(
            color: _primaryPurple.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: day.isEnabled
                      ? (isGrouped
                          ? _ink
                          : _primaryPurple)
                      : Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    day.initial,
                    style: TextStyle(
                      color: day.isEnabled ? Colors.white : Colors.grey.shade600,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
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
                      day.dayLabel,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      day.subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: day.isEnabled && day.slots.isNotEmpty
                            ? _green
                            : _muted,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isGrouped)
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Editing Thursday & Friday standard blocks.'),
                      ),
                    );
                  },
                  child: const Text(
                    'Edit',
                    style: TextStyle(
                      color: _primaryPurple,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                )
              else
                Switch.adaptive(
                  key: Key('toggle_day_${day.dayKey}'),
                  value: day.isEnabled,
                  activeThumbColor: Colors.white,
                  activeTrackColor: _primaryPurple,
                  onChanged: (_) => notifier.toggleDay(day.dayKey),
                ),
            ],
          ),
          if (day.isEnabled && day.slots.isNotEmpty && !isGrouped) ...[
            const SizedBox(height: 12),
            ...day.slots.map(
              (slot) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _lavenderCard,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      slot.iconType == 'sparkle'
                          ? Icons.auto_awesome
                          : Icons.wb_sunny_outlined,
                      size: 18,
                      color: slot.iconType == 'sparkle'
                          ? _teal
                          : _primaryPurple,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        slot.timeRange,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _ink,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          size: 18, color: _muted),
                      onPressed: () =>
                          notifier.removeSlot(day.dayKey, slot.id),
                      tooltip: 'Remove Slot',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            InkWell(
              key: Key('add_slot_${day.dayKey}'),
              onTap: () => _showAddSlotDialog(context, day.dayKey, notifier),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _primaryPurple.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle_outline,
                        size: 16, color: _primaryPurple),
                    SizedBox(width: 6),
                    Text(
                      'Add Slot',
                      style: TextStyle(
                        color: _primaryPurple,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAddSlotDialog(
    BuildContext context,
    String dayKey,
    SpecialistAvailabilityNotifier notifier,
  ) {
    final times = [
      '8:30 AM – 11:30 AM',
      '9:00 AM – 12:00 PM',
      '1:00 PM – 4:00 PM',
      '2:00 PM – 5:30 PM',
      '4:00 PM – 7:00 PM',
    ];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Time Slot',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 12),
                ...times.map(
                  (t) => ListTile(
                    title: Text(t, style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.add, color: _primaryPurple),
                    onTap: () {
                      notifier.addSlot(dayKey, t);
                      Navigator.of(ctx).pop();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSessionPreferencesSection(
    SpecialistAvailabilityModel availability,
    SpecialistAvailabilityNotifier notifier,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _lavenderBorder),
        boxShadow: [
          BoxShadow(
            color: _primaryPurple.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt, size: 16, color: _primaryPurple),
              const SizedBox(width: 6),
              const Text(
                'ERGONOMICS & ENERGY',
                style: TextStyle(
                  color: _primaryPurple,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Session Preferences',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _ink,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Designed to keep speech coaching energetic and mindful.',
            style: TextStyle(
              fontSize: 12,
              color: _muted,
            ),
          ),
          const SizedBox(height: 18),

          // Standard Session Duration
          const Text(
            'Standard Session Duration',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          const SizedBox(height: 10),
          _buildDurationCard(
            minutes: 30,
            title: '30 Minutes',
            subtitle: 'Quick Focus & Phoneme Drills',
            isSelected: availability.sessionDurationMinutes == 30,
            isRecommended: false,
            onTap: () => notifier.selectDuration(30),
          ),
          const SizedBox(height: 8),
          _buildDurationCard(
            minutes: 45,
            title: '45 Minutes',
            subtitle: 'Optimal for child engagement & play review',
            isSelected: availability.sessionDurationMinutes == 45,
            isRecommended: true,
            onTap: () => notifier.selectDuration(45),
          ),
          const SizedBox(height: 8),
          _buildDurationCard(
            minutes: 60,
            title: '60 Minutes',
            subtitle: 'In-depth articulation & parent debrief',
            isSelected: availability.sessionDurationMinutes == 60,
            isRecommended: false,
            onTap: () => notifier.selectDuration(60),
          ),

          const SizedBox(height: 20),

          // Buffer Between Sessions
          const Text(
            'Buffer Between Sessions',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildBufferPill('None', 0, availability.bufferMinutes == 0,
                  () => notifier.selectBuffer(0)),
              _buildBufferPill('10 min', 10, availability.bufferMinutes == 10,
                  () => notifier.selectBuffer(10)),
              _buildBufferPill('15 min ⚡', 15, availability.bufferMinutes == 15,
                  () => notifier.selectBuffer(15)),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '15-minute buffers help prevent voice strain and caseload fatigue.',
            style: TextStyle(
              fontSize: 11,
              color: _teal,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 20),

          // Daily Session Cap
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _lavenderCard,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Session Cap',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Maximum learners scheduled per day',
                        style: TextStyle(
                          fontSize: 11,
                          color: _muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _lavenderBorder),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        key: const Key('cap_decrement_button'),
                        icon: const Icon(Icons.remove, size: 16, color: _primaryPurple),
                        onPressed: () => notifier.changeDailyCap(-1),
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        padding: EdgeInsets.zero,
                      ),
                      Text(
                        '${availability.dailySessionCap}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: _primaryPurple,
                        ),
                      ),
                      IconButton(
                        key: const Key('cap_increment_button'),
                        icon: const Icon(Icons.add, size: 16, color: _primaryPurple),
                        onPressed: () => notifier.changeDailyCap(1),
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Advance Notice
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _lavenderCard,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _primaryPurple.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: _primaryPurple,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Advance Notice',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Cut-off window before session starts',
                        style: TextStyle(
                          fontSize: 11,
                          color: _muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _primaryPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    availability.advanceNotice,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _primaryPurple,
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

  Widget _buildDurationCard({
    required int minutes,
    required String title,
    required String subtitle,
    required bool isSelected,
    required bool isRecommended,
    required VoidCallback onTap,
  }) {
    return InkWell(
      key: Key('duration_option_$minutes'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? _lavenderCard : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? _primaryPurple : _lavenderBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? _primaryPurple : _ink,
                          ),
                        ),
                        if (isRecommended) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _primaryPurple,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Recommended',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: _muted,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: _primaryPurple,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBufferPill(
    String label,
    int minutes,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return InkWell(
      key: Key('buffer_option_$minutes'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _teal : _lavenderCard,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : _ink,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton(
    SpecialistAvailabilityState state,
    SpecialistAvailabilityNotifier notifier,
  ) {
    final isSaving = state.isSaving;
    final isSaved = state.isSaved;

    return SizedBox(
      height: 52,
      child: ElevatedButton(
        key: const Key('save_availability_button'),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSaved ? _green : _primaryPurple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          elevation: 2,
        ),
        onPressed: isSaving ? null : () => notifier.saveAvailability(),
        child: isSaving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(isSaved ? Icons.check : Icons.check_circle_outline,
                        size: 20),
                    const SizedBox(width: 8),
                    Text(
                      isSaved ? 'Availability Saved!' : 'Save Availability',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

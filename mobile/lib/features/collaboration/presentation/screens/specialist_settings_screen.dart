import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/providers/session_provider.dart';
import '../../../../app/router/app_router.dart';
import '../../application/collaboration_providers.dart';
import '../../domain/models/collaboration_models.dart';

/// Specialist Settings Screen.
///
/// Implemented to visually match the Stitch visual reference:
/// - App bar with circular back button and "Specialist Settings" title.
/// - Specialist Account Summary card with avatar, role subtitle, verification badge,
///   caseload count, and "View Profile >" action.
/// - Specialist Account section (FERPA Safe badge) linking to Profile, Availability,
///   Verification, and Security.
/// - Live Notifications section (Push & Sound) with 5 interactive toggles.
/// - Child Safety & Consent section linking to Consent & Sharing, Profile Visibility,
///   and Data & Privacy Controls.
/// - Accessibility & Comfort section with 4 interactive toggles.
/// - Specialist Studio section with Language, Appearance, Time Zone, and Audio FX toggle.
/// - Support & Community section linking to Help & Resource Center, Report a Problem,
///   and Contact Specialist Desk.
/// - Prominent Log Out button with confirmation dialog integrated with Firebase Auth.
/// - Safe, playful speech learning ecosystem footer.
/// - Fully responsive across 320px, 360px, 390px, 430px widths without overflow.
class SpecialistSettingsScreen extends ConsumerStatefulWidget {
  const SpecialistSettingsScreen({super.key});

  @override
  ConsumerState<SpecialistSettingsScreen> createState() =>
      _SpecialistSettingsScreenState();
}

class _SpecialistSettingsScreenState
    extends ConsumerState<SpecialistSettingsScreen> {
  static const _ink = Color(0xFF1E1B4B);
  static const _primaryPurple = Color(0xFF5925DC);
  static const _lavenderBg = Color(0xFFFBFBFE);
  static const _lavenderBorder = Color(0xFFEDE9FE);
  static const _muted = Color(0xFF64748B);
  static const _teal = Color(0xFF0D9488);
  static const _tealLight = Color(0xFFCCFBF1);
  static const _coralBg = Color(0xFFFFE4E6);
  static const _coralText = Color(0xFFE11D48);

  bool _isLoggingOut = false;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(userSessionProvider);
    final settingsState = ref.watch(specialistSettingsNotifierProvider);
    final settingsNotifier =
        ref.read(specialistSettingsNotifierProvider.notifier);

    final settings = settingsState.settings;

    // Use current authenticated specialist name or fallback to Stitch default
    final specialistName = (session.profile?.displayName != null &&
            session.profile!.displayName.isNotEmpty)
        ? session.profile!.displayName
        : settings.specialistName;

    return Scaffold(
      backgroundColor: _lavenderBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            _buildAppBar(context),

            // Main Settings Scrollable Body
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Profile / Account Summary Card
                    _buildProfileSummaryCard(
                      context,
                      specialistName: specialistName,
                      settings: settings,
                    ),

                    const SizedBox(height: 20),

                    // 2. SPECIALIST ACCOUNT Section
                    _buildSectionHeader(
                      title: 'SPECIALIST ACCOUNT',
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _tealLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'FERPA Safe',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: _teal,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildSpecialistAccountCard(context),

                    const SizedBox(height: 22),

                    // 3. LIVE NOTIFICATIONS Section
                    _buildSectionHeader(
                      title: 'LIVE NOTIFICATIONS',
                      trailing: const Text(
                        'Push & Sound',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _primaryPurple,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildLiveNotificationsCard(settings, settingsNotifier),

                    const SizedBox(height: 22),

                    // 4. CHILD SAFETY & CONSENT Section
                    _buildSectionHeader(
                      title: 'CHILD SAFETY & CONSENT',
                      trailing: const Icon(
                        Icons.verified_user_outlined,
                        size: 16,
                        color: _teal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildChildSafetyConsentCard(
                      context,
                      settings,
                      settingsNotifier,
                    ),

                    const SizedBox(height: 22),

                    // 5. ACCESSIBILITY & COMFORT Section
                    _buildSectionHeader(
                      title: 'ACCESSIBILITY & COMFORT',
                      trailing: const Icon(
                        Icons.accessibility_new_rounded,
                        size: 16,
                        color: _primaryPurple,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildAccessibilityCard(settings, settingsNotifier),

                    const SizedBox(height: 22),

                    // 6. SPECIALIST STUDIO Section
                    _buildSectionHeader(title: 'SPECIALIST STUDIO'),
                    const SizedBox(height: 8),
                    _buildSpecialistStudioCard(
                      context,
                      settings,
                      settingsNotifier,
                    ),

                    const SizedBox(height: 22),

                    // 7. SUPPORT & COMMUNITY Section
                    _buildSectionHeader(title: 'SUPPORT & COMMUNITY'),
                    const SizedBox(height: 8),
                    _buildSupportCommunityCard(context),

                    const SizedBox(height: 28),

                    // 8. Log Out Button
                    _buildLogoutButton(context),

                    const SizedBox(height: 22),

                    // 9. Footer
                    _buildFooter(),

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
  // APP BAR
  // ---------------------------------------------------------------------------
  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Material(
            color: Colors.white,
            shape: const CircleBorder(),
            elevation: 1,
            shadowColor: Colors.black12,
            child: InkWell(
              key: const Key('settings_back_button'),
              customBorder: const CircleBorder(),
              onTap: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  Navigator.of(context)
                      .pushReplacementNamed(AppRoutes.specialistDashboard);
                }
              },
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.arrow_back, color: _ink, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Specialist Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _ink,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. PROFILE / ACCOUNT SUMMARY CARD
  // ---------------------------------------------------------------------------
  Widget _buildProfileSummaryCard(
    BuildContext context, {
    required String specialistName,
    required SpecialistSettingsModel settings,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _lavenderBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: _primaryPurple.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Specialist Avatar with Verification Badge
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: _primaryPurple.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _primaryPurple.withValues(alpha: 0.25),
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _getInitials(specialistName),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _primaryPurple,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: _teal,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified,
                          size: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),

                // Name & Role Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        specialistName,
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                          letterSpacing: -0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        settings.specialistTitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: _muted,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // Profile Verified Pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _tealLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                color: _teal,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                settings.verificationBadge,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: _teal,
                                ),
                                overflow: TextOverflow.ellipsis,
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
          ),

          // Divider
          const Divider(height: 1, thickness: 1, color: _lavenderBorder),

          // Lower Caseload & View Profile Action
          InkWell(
            key: const Key('settings_view_profile_action'),
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.specialistProfile);
            },
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(22)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Caseload: ${settings.activeLearnersCount} Active Learners',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: _ink,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View Profile',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: _primaryPurple,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: _primaryPurple,
                      ),
                    ],
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
  // SECTION HEADER
  // ---------------------------------------------------------------------------
  Widget _buildSectionHeader({
    required String title,
    Widget? trailing,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: _muted,
              letterSpacing: 0.9,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing,
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 2. SPECIALIST ACCOUNT CARD
  // ---------------------------------------------------------------------------
  Widget _buildSpecialistAccountCard(BuildContext context) {
    return _buildGroupCard([
      _buildNavRow(
        key: const Key('settings_row_my_profile'),
        icon: Icons.person_outline_rounded,
        iconBg: _primaryPurple.withValues(alpha: 0.1),
        iconColor: _primaryPurple,
        title: 'My Profile',
        subtitle: 'Credentials, bio & specializations',
        onTap: () => Navigator.pushNamed(context, AppRoutes.specialistProfile),
      ),
      const Divider(height: 1, thickness: 1, color: _lavenderBorder),
      _buildNavRow(
        key: const Key('settings_row_availability'),
        icon: Icons.calendar_today_outlined,
        iconBg: _tealLight,
        iconColor: _teal,
        title: 'Availability & Appointments',
        subtitle: 'Weekly schedule, session caps & buffers',
        onTap: () => Navigator.pushNamed(
          context,
          AppRoutes.specialistAvailabilitySettings,
        ),
      ),
      const Divider(height: 1, thickness: 1, color: _lavenderBorder),
      _buildNavRow(
        key: const Key('settings_row_verification'),
        icon: Icons.verified_outlined,
        iconBg: _tealLight,
        iconColor: _teal,
        title: 'Verification Status',
        subtitle: 'State board approval & background checks',
        onTap: () => Navigator.pushNamed(
          context,
          AppRoutes.specialistVerificationStatus,
        ),
      ),
      const Divider(height: 1, thickness: 1, color: _lavenderBorder),
      _buildNavRow(
        key: const Key('settings_row_security'),
        icon: Icons.lock_reset_outlined,
        iconBg: _primaryPurple.withValues(alpha: 0.1),
        iconColor: _primaryPurple,
        title: 'Change Password & Security',
        subtitle: 'Two-factor auth & active sessions',
        onTap: () {
          _showSecurityInfoSheet(context);
        },
      ),
    ]);
  }

  // ---------------------------------------------------------------------------
  // 3. LIVE NOTIFICATIONS CARD
  // ---------------------------------------------------------------------------
  Widget _buildLiveNotificationsCard(
    SpecialistSettingsModel settings,
    SpecialistSettingsNotifier notifier,
  ) {
    return _buildGroupCard([
      _buildSwitchRow(
        key: const Key('toggle_session_reminders'),
        icon: Icons.alarm_outlined,
        iconBg: _primaryPurple.withValues(alpha: 0.1),
        iconColor: _primaryPurple,
        title: 'Session Reminders',
        subtitle: '15m before live 1-on-1 exercises',
        value: settings.sessionReminders,
        onChanged: (val) => notifier.updateToggle('session_reminders', val),
      ),
      const Divider(height: 1, thickness: 1, color: _lavenderBorder),
      _buildSwitchRow(
        key: const Key('toggle_consent_alerts'),
        icon: Icons.shield_outlined,
        iconBg: _tealLight,
        iconColor: _teal,
        title: 'Consent & Sharing Alerts',
        subtitle: 'Guardian consents & profile requests',
        value: settings.consentAlerts,
        onChanged: (val) => notifier.updateToggle('consent_alerts', val),
      ),
      const Divider(height: 1, thickness: 1, color: _lavenderBorder),
      _buildSwitchRow(
        key: const Key('toggle_messages_alerts'),
        icon: Icons.chat_bubble_outline_rounded,
        iconBg: _primaryPurple.withValues(alpha: 0.1),
        iconColor: _primaryPurple,
        title: 'Learner & Parent Messages',
        subtitle: 'Direct notes from school & families',
        value: settings.messagesAlerts,
        onChanged: (val) => notifier.updateToggle('messages_alerts', val),
      ),
      const Divider(height: 1, thickness: 1, color: _lavenderBorder),
      _buildSwitchRow(
        key: const Key('toggle_appointment_requests'),
        icon: Icons.event_available_outlined,
        iconBg: _tealLight,
        iconColor: _teal,
        title: 'Appointment Requests',
        subtitle: 'New consultation & review invites',
        value: settings.appointmentRequests,
        onChanged: (val) => notifier.updateToggle('appointment_requests', val),
      ),
      const Divider(height: 1, thickness: 1, color: _lavenderBorder),
      _buildSwitchRow(
        key: const Key('toggle_weekly_progress_digests'),
        icon: Icons.assignment_outlined,
        iconBg: _primaryPurple.withValues(alpha: 0.1),
        iconColor: _primaryPurple,
        title: 'Weekly Progress Digests',
        subtitle: 'Milestone summaries & sound telemetry',
        value: settings.weeklyProgressDigests,
        onChanged: (val) =>
            notifier.updateToggle('weekly_progress_digests', val),
      ),
    ]);
  }

  // ---------------------------------------------------------------------------
  // 4. CHILD SAFETY & CONSENT CARD
  // ---------------------------------------------------------------------------
  Widget _buildChildSafetyConsentCard(
    BuildContext context,
    SpecialistSettingsModel settings,
    SpecialistSettingsNotifier notifier,
  ) {
    return _buildGroupCard([
      _buildNavRow(
        key: const Key('settings_row_consent_center'),
        icon: Icons.check_circle_outline_rounded,
        iconBg: _tealLight,
        iconColor: _teal,
        title: 'Consent & Sharing Center',
        subtitle: 'Active guardian authorizations',
        onTap: () => Navigator.pushNamed(
          context,
          AppRoutes.specialistConsentSharing,
        ),
      ),
      const Divider(height: 1, thickness: 1, color: _lavenderBorder),
      _buildNavRow(
        key: const Key('settings_row_profile_visibility'),
        icon: Icons.visibility_outlined,
        iconBg: _primaryPurple.withValues(alpha: 0.1),
        iconColor: _primaryPurple,
        title: 'Profile Visibility',
        subtitle: 'Visible to enrolled schools & families',
        trailingBadge: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: _tealLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            settings.profileVisibility,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: _teal,
            ),
          ),
        ),
        onTap: () => _showVisibilityPicker(context, settings, notifier),
      ),
      const Divider(height: 1, thickness: 1, color: _lavenderBorder),
      _buildNavRow(
        key: const Key('settings_row_privacy_controls'),
        icon: Icons.lock_outline_rounded,
        iconBg: _primaryPurple.withValues(alpha: 0.1),
        iconColor: _primaryPurple,
        title: 'Data & Privacy Controls',
        subtitle: 'COPPA-compliant voice recording storage',
        onTap: () => _showPrivacyControlsDialog(context),
      ),
    ]);
  }

  // ---------------------------------------------------------------------------
  // 5. ACCESSIBILITY & COMFORT CARD
  // ---------------------------------------------------------------------------
  Widget _buildAccessibilityCard(
    SpecialistSettingsModel settings,
    SpecialistSettingsNotifier notifier,
  ) {
    return _buildGroupCard([
      _buildSwitchRow(
        key: const Key('toggle_larger_text'),
        icon: Icons.text_fields_rounded,
        iconBg: _primaryPurple.withValues(alpha: 0.1),
        iconColor: _primaryPurple,
        title: 'Larger Text / Dynamic Type',
        subtitle: 'Scale fonts for high-contrast viewing',
        value: settings.largerText,
        onChanged: (val) => notifier.updateToggle('larger_text', val),
      ),
      const Divider(height: 1, thickness: 1, color: _lavenderBorder),
      _buildSwitchRow(
        key: const Key('toggle_reduce_motion'),
        icon: Icons.motion_photos_off_outlined,
        iconBg: _primaryPurple.withValues(alpha: 0.1),
        iconColor: _primaryPurple,
        title: 'Reduce Motion',
        subtitle: 'Minimize celebratory card bounces',
        value: settings.reduceMotion,
        onChanged: (val) => notifier.updateToggle('reduce_motion', val),
      ),
      const Divider(height: 1, thickness: 1, color: _lavenderBorder),
      _buildSwitchRow(
        key: const Key('toggle_high_contrast'),
        icon: Icons.contrast_rounded,
        iconBg: _primaryPurple.withValues(alpha: 0.1),
        iconColor: _primaryPurple,
        title: 'High Contrast Mode',
        subtitle: 'Strengthen glyph bevels & phoneme art',
        value: settings.highContrast,
        onChanged: (val) => notifier.updateToggle('high_contrast', val),
      ),
      const Divider(height: 1, thickness: 1, color: _lavenderBorder),
      _buildSwitchRow(
        key: const Key('toggle_haptic_feedback'),
        icon: Icons.vibration_rounded,
        iconBg: _tealLight,
        iconColor: _teal,
        title: 'Haptic Touch Feedback',
        subtitle: 'Tactile clicks on speech cards & dials',
        value: settings.hapticFeedback,
        onChanged: (val) => notifier.updateToggle('haptic_feedback', val),
      ),
    ]);
  }

  // ---------------------------------------------------------------------------
  // 6. SPECIALIST STUDIO CARD
  // ---------------------------------------------------------------------------
  Widget _buildSpecialistStudioCard(
    BuildContext context,
    SpecialistSettingsModel settings,
    SpecialistSettingsNotifier notifier,
  ) {
    return _buildGroupCard([
      _buildNavRow(
        key: const Key('settings_row_language'),
        icon: Icons.translate_rounded,
        iconBg: _primaryPurple.withValues(alpha: 0.1),
        iconColor: _primaryPurple,
        title: 'Language',
        subtitle: 'Phonetic guide & interface',
        trailingText: settings.language,
        onTap: () => _showLanguagePicker(context, settings, notifier),
      ),
      const Divider(height: 1, thickness: 1, color: _lavenderBorder),
      _buildNavRow(
        key: const Key('settings_row_appearance'),
        icon: Icons.palette_outlined,
        iconBg: _tealLight,
        iconColor: _teal,
        title: 'Appearance / Theme',
        subtitle: 'Tactile Play theme palette',
        trailingText: settings.appearanceTheme,
        onTap: () => _showThemePicker(context, settings, notifier),
      ),
      const Divider(height: 1, thickness: 1, color: _lavenderBorder),
      _buildNavRow(
        key: const Key('settings_row_time_zone'),
        icon: Icons.access_time_rounded,
        iconBg: _primaryPurple.withValues(alpha: 0.1),
        iconColor: _primaryPurple,
        title: 'Specialist Time Zone',
        subtitle: settings.timeZone,
        trailingText: 'Change',
        onTap: () => _showTimeZoneDialog(context, settings, notifier),
      ),
      const Divider(height: 1, thickness: 1, color: _lavenderBorder),
      _buildSwitchRow(
        key: const Key('toggle_audio_sound_fx'),
        icon: Icons.volume_up_outlined,
        iconBg: const Color(0xFFFEF3C7),
        iconColor: const Color(0xFFD97706),
        title: 'Audio & Sound FX',
        subtitle: 'Audio feedback in speech games & cues',
        value: settings.audioSoundFx,
        onChanged: (val) => notifier.updateToggle('audio_sound_fx', val),
      ),
    ]);
  }

  // ---------------------------------------------------------------------------
  // 7. SUPPORT & COMMUNITY CARD
  // ---------------------------------------------------------------------------
  Widget _buildSupportCommunityCard(BuildContext context) {
    return _buildGroupCard([
      _buildNavRow(
        key: const Key('settings_row_help_center'),
        icon: Icons.help_outline_rounded,
        iconBg: _primaryPurple.withValues(alpha: 0.1),
        iconColor: _primaryPurple,
        title: 'Help & Resource Center',
        subtitle: 'Lesson builders & articulation drills',
        onTap: () => Navigator.pushNamed(context, AppRoutes.specialistHelpSupport),
      ),
      const Divider(height: 1, thickness: 1, color: _lavenderBorder),
      _buildNavRow(
        key: const Key('settings_row_report_problem'),
        icon: Icons.bug_report_outlined,
        iconBg: _primaryPurple.withValues(alpha: 0.1),
        iconColor: _primaryPurple,
        title: 'Report a Problem',
        subtitle: 'Submit audio glitch or UI feedback',
        onTap: () => _showReportProblemDialog(context),
      ),
      const Divider(height: 1, thickness: 1, color: _lavenderBorder),
      _buildNavRow(
        key: const Key('settings_row_contact_desk'),
        icon: Icons.headset_mic_outlined,
        iconBg: _tealLight,
        iconColor: _teal,
        title: 'Contact Specialist Desk',
        subtitle: '< 15 min average priority reply',
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Opening priority line to Specialist Support Desk...',
              ),
            ),
          );
        },
      ),
    ]);
  }

  // ---------------------------------------------------------------------------
  // 8. LOG OUT BUTTON
  // ---------------------------------------------------------------------------
  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        key: const Key('settings_logout_button'),
        style: ElevatedButton.styleFrom(
          backgroundColor: _coralBg,
          foregroundColor: _coralText,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        onPressed: _isLoggingOut ? null : () => _confirmLogout(context),
        child: _isLoggingOut
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _coralText,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout_rounded, size: 20, color: _coralText),
                  SizedBox(width: 8),
                  Text(
                    'Log Out',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _coralText,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 9. FOOTER
  // ---------------------------------------------------------------------------
  Widget _buildFooter() {
    return Column(
      children: [
        const Text(
          'Terms of Service  •  Privacy Policy  •  COPPA Badge',
          style: TextStyle(
            fontSize: 11,
            color: _muted,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        const Text(
          'Lingua Specialist Suite v2.4.1 (Build 842)',
          style: TextStyle(
            fontSize: 10.5,
            color: _muted,
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        const Text(
          'Safe, playful speech learning ecosystem',
          style: TextStyle(
            fontSize: 10.5,
            color: _teal,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // REUSABLE CARD CONTAINER
  // ---------------------------------------------------------------------------
  Widget _buildGroupCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _lavenderBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: _primaryPurple.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  // ---------------------------------------------------------------------------
  // REUSABLE NAVIGATION ROW
  // ---------------------------------------------------------------------------
  Widget _buildNavRow({
    required Key key,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailingBadge,
    String? trailingText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: _muted,
                      fontWeight: FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (trailingBadge != null) ...[
              const SizedBox(width: 8),
              Flexible(child: trailingBadge),
            ],
            if (trailingText != null) ...[
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  trailingText,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _primaryPurple,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // REUSABLE SWITCH ROW
  // ---------------------------------------------------------------------------
  Widget _buildSwitchRow({
    required Key key,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: _muted,
                    fontWeight: FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          CupertinoSwitch(
            key: key,
            value: value,
            activeTrackColor: _primaryPurple,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // LOGOUT CONFIRMATION DIALOG
  // ---------------------------------------------------------------------------
  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Row(
            children: [
              Icon(Icons.logout_rounded, color: _coralText, size: 24),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Log Out of LINGUA AI?',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
              ),
            ],
          ),
          content: const Text(
            'You will need to sign in again to access your Specialist workspace and learner caseload.',
            style: TextStyle(fontSize: 13.5, color: _muted, height: 1.4),
          ),
          actions: [
            TextButton(
              key: const Key('logout_cancel_button'),
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _muted,
                ),
              ),
            ),
            ElevatedButton(
              key: const Key('logout_confirm_button'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _coralText,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () async {
                Navigator.of(dialogCtx).pop();
                setState(() => _isLoggingOut = true);
                try {
                  await ref.read(userSessionProvider.notifier).logout();
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRoutes.welcome,
                      (route) => false,
                    );
                  }
                } finally {
                  if (mounted) {
                    setState(() => _isLoggingOut = false);
                  }
                }
              },
              child: const Text(
                'Log Out',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // HELPER MODALS & DIALOGS
  // ---------------------------------------------------------------------------
  void _showSecurityInfoSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Password & Security',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _ink),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your account authentication is secured with Firebase Auth. Multi-factor authentication is active on all specialist accounts.',
                style: TextStyle(fontSize: 13, color: _muted, height: 1.4),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password reset instructions sent to your email.'),
                      ),
                    );
                  },
                  child: const Text('Send Password Reset Link'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showVisibilityPicker(
    BuildContext context,
    SpecialistSettingsModel settings,
    SpecialistSettingsNotifier notifier,
  ) {
    final options = ['Public', 'Enrolled Schools Only', 'Private'];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Specialist Profile Visibility',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _ink),
              ),
              const SizedBox(height: 12),
              ...options.map((opt) {
                final isSelected = opt == settings.profileVisibility;
                return ListTile(
                  title: Text(opt, style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: _teal)
                      : null,
                  onTap: () {
                    notifier.updateVisibility(opt);
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showPrivacyControlsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Data & Privacy Controls', style: TextStyle(fontWeight: FontWeight.w800)),
          content: const Text(
            'All learner audio and speech drills are encrypted at rest with AES-256 and stored in compliance with COPPA, FERPA, and HIPAA guidelines.',
            style: TextStyle(fontSize: 13, color: _muted, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Understood'),
            ),
          ],
        );
      },
    );
  }

  void _showLanguagePicker(
    BuildContext context,
    SpecialistSettingsModel settings,
    SpecialistSettingsNotifier notifier,
  ) {
    final languages = ['English (US)', 'English (UK)', 'Spanish (ES)'];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Phonetic & Interface Language',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _ink)),
              const SizedBox(height: 12),
              ...languages.map((lang) {
                final isSelected = lang == settings.language;
                return ListTile(
                  title: Text(lang, style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: isSelected ? const Icon(Icons.check, color: _primaryPurple) : null,
                  onTap: () {
                    notifier.updateStudioPreference(language: lang);
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showThemePicker(
    BuildContext context,
    SpecialistSettingsModel settings,
    SpecialistSettingsNotifier notifier,
  ) {
    final themes = ['Light (Playful)', 'Soft Slate', 'High Contrast'];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Studio Theme',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _ink)),
              const SizedBox(height: 12),
              ...themes.map((th) {
                final isSelected = th == settings.appearanceTheme;
                return ListTile(
                  title: Text(th, style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: isSelected ? const Icon(Icons.check, color: _teal) : null,
                  onTap: () {
                    notifier.updateStudioPreference(appearanceTheme: th);
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showTimeZoneDialog(
    BuildContext context,
    SpecialistSettingsModel settings,
    SpecialistSettingsNotifier notifier,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Specialist Time Zone', style: TextStyle(fontWeight: FontWeight.w800)),
          content: Text(
            'Current time zone is set to ${settings.timeZone}. Scheduled sessions automatically translate to learners\' local time.',
            style: const TextStyle(fontSize: 13, color: _muted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showReportProblemDialog(BuildContext context) {
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Report a Problem', style: TextStyle(fontWeight: FontWeight.w800)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Submit an audio glitch or user experience feedback for our engineering team.',
                style: TextStyle(fontSize: 12.5, color: _muted),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('settings_report_problem_field'),
                controller: descCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Describe what happened...',
                  hintStyle: const TextStyle(fontSize: 12, color: _muted),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _lavenderBorder),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              key: const Key('settings_submit_problem_button'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                final txt = descCtrl.text.trim();
                if (txt.isNotEmpty) {
                  ref
                      .read(specialistHelpNotifierProvider.notifier)
                      .reportProblem('Settings Feedback', txt);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Report received! Our team is looking into this.',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  static String _getInitials(String name) {
    final clean = name.replaceAll(RegExp(r'^(Dr\.|M\.S\.|CCC-SLP)\s*'), '');
    final parts = clean.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'MR';
  }
}

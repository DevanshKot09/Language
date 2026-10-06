import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/router/app_router.dart';
import '../../application/collaboration_providers.dart';
import '../../domain/models/collaboration_models.dart';

/// Specialist Profile Screen.
///
/// Designed to visually match the user-provided Stitch reference:
/// - Header with back navigation, "My Profile", edit action, and Specialist avatar circle.
/// - Segmented pill toggle: "Specialist View" vs "Learner Preview".
/// - Profile Hero card: Photo avatar with camera badge, name, title, green-teal verification
///   badge ("VERIFIED SPECIALIST • LINGUA SAFE"), location & spots, and 3 metric tiles.
/// - Profile Visibility card: Live directory indicator, dropdown pill, and learner discovery info.
/// - About Me card: Introduction text with "Read full bio" expansion.
/// - Support Focus Areas: 7 stylized pillar chips with dedicated icons.
/// - Practice Details: Experience, Languages, Age groups, and Supported formats.
/// - Credentials & Safety: Verified educational degrees, certificates, and Child-Safe status.
/// - Actions: "Edit Specialist Profile", "Manage Schedule & Slots" (wires to Schedule).
/// - Child-safe privacy reassurance footer.
/// - Responsive down to 320px width without RenderFlex overflow.
class SpecialistProfileScreen extends ConsumerStatefulWidget {
  const SpecialistProfileScreen({super.key});

  @override
  ConsumerState<SpecialistProfileScreen> createState() => _SpecialistProfileScreenState();
}

class _SpecialistProfileScreenState extends ConsumerState<SpecialistProfileScreen> {
  static const _ink = Color(0xFF1E1B4B);
  static const _primaryPurple = Color(0xFF5925DC);
  static const _lavenderBg = Color(0xFFF8F7FF);
  static const _lavenderBorder = Color(0xFFEDE9FE);
  static const _lavenderPill = Color(0xFFF1EFF9);
  static const _muted = Color(0xFF64748B);
  static const _teal = Color(0xFF0D9488);
  static const _tealLight = Color(0xFFCCFBF1);
  static const _tealDark = Color(0xFF0F766E);
  static const _amber = Color(0xFFD97706);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(specialistProfileNotifierProvider);
    final notifier = ref.read(specialistProfileNotifierProvider.notifier);
    final profile = state.profile;

    return Scaffold(
      backgroundColor: _lavenderBg,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top App Bar
            _buildAppBar(context),

            // 2. View Mode Toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: _buildViewModeToggle(state, notifier),
            ),

            // 3. Scrollable Profile Content
            Expanded(
              child: RefreshIndicator(
                color: _primaryPurple,
                onRefresh: () => notifier.loadProfile(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Hero Card
                      _buildHeroCard(context, profile),

                      const SizedBox(height: 16),

                      // Profile Visibility Card
                      _buildVisibilityCard(context, profile, notifier),

                      const SizedBox(height: 16),

                      // About Me Card
                      _buildAboutMeCard(context, profile, state, notifier),

                      const SizedBox(height: 16),

                      // Support Focus Areas Card
                      _buildSupportFocusCard(context, profile),

                      const SizedBox(height: 16),

                      // Practice Details Card
                      _buildPracticeDetailsCard(context, profile),

                      const SizedBox(height: 16),

                      // Credentials & Safety Card
                      _buildCredentialsCard(context, profile),

                      const SizedBox(height: 24),

                      // Action Buttons
                      _buildActionButtons(context, profile),

                      const SizedBox(height: 20),

                      // Child-Safe Privacy Reassurance Footer
                      _buildPrivacyFooter(profile),

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
  Widget _buildAppBar(BuildContext context) {
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
              'My Profile',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: _ink,
                letterSpacing: -0.3,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Edit Profile',
            icon: const Icon(Icons.edit_outlined, color: _primaryPurple, size: 22),
            onPressed: () => _showEditProfileSheet(context),
          ),
          IconButton(
            key: const Key('profile_settings_icon_button'),
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined, color: _primaryPurple, size: 22),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.specialistSettings),
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
  // 2. VIEW MODE TOGGLE (Specialist View vs Learner Preview)
  // ---------------------------------------------------------------------------
  Widget _buildViewModeToggle(
    SpecialistProfileState state,
    SpecialistProfileNotifier notifier,
  ) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _lavenderBorder,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => notifier.toggleViewMode(true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: state.isSpecialistView ? _primaryPurple : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: state.isSpecialistView
                      ? [
                          BoxShadow(
                            color: _primaryPurple.withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.badge_outlined,
                        size: 15,
                        color: state.isSpecialistView ? Colors.white : _muted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Specialist View',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: state.isSpecialistView ? Colors.white : _muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => notifier.toggleViewMode(false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: !state.isSpecialistView ? _primaryPurple : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: !state.isSpecialistView
                      ? [
                          BoxShadow(
                            color: _primaryPurple.withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.visibility_outlined,
                        size: 15,
                        color: !state.isSpecialistView ? Colors.white : _muted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Learner Preview',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: !state.isSpecialistView ? Colors.white : _muted,
                        ),
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
  // 3. PROFILE HERO CARD
  // ---------------------------------------------------------------------------
  Widget _buildHeroCard(BuildContext context, SpecialistProfileModel profile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _lavenderBorder, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A2B1277),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Centered Avatar with Camera Badge
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _primaryPurple.withValues(alpha: 0.3), width: 2),
                ),
                child: const CircleAvatar(
                  radius: 46,
                  backgroundColor: Color(0xFFEDE9FE),
                  child: Icon(
                    Icons.face_rounded,
                    size: 60,
                    color: _primaryPurple,
                  ),
                ),
              ),
              Positioned(
                bottom: 2,
                right: 4,
                child: GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profile photo update available in settings.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: _primaryPurple,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Specialist Display Name
          Text(
            profile.displayName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _ink,
              letterSpacing: -0.4,
            ),
          ),

          const SizedBox(height: 4),

          // Professional Title
          Text(
            profile.professionalTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _primaryPurple,
            ),
          ),

          const SizedBox(height: 10),

          // Verified Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: _tealLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF99F6E4)),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified_rounded, size: 14, color: _tealDark),
                  const SizedBox(width: 5),
                  Text(
                    profile.verificationBadge,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: _tealDark,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Location & spots pill
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 4,
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: _muted),
              Text(
                profile.location,
                style: const TextStyle(fontSize: 12, color: _muted, fontWeight: FontWeight.w500),
              ),
              const Text('•', style: TextStyle(color: _muted, fontSize: 12)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _lavenderPill,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
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
                      const SizedBox(width: 5),
                      Text(
                        '${profile.availabilitySpots} new learner spots',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // 3 Metric Cards Row
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  value: '${profile.activeLearnersCount}',
                  valueColor: _primaryPurple,
                  label: 'Active\nLearners',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  value: '${profile.rating} ★',
                  valueColor: _ink,
                  label: '${profile.reviewsCount} Reviews',
                  isRating: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  value: '${profile.experienceYears} yrs',
                  valueColor: _ink,
                  label: 'Lingua Guide',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String value,
    required Color valueColor,
    required String label,
    bool isRating = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: _lavenderPill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _lavenderBorder),
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: isRating
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        value.split(' ')[0],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.star_rounded, size: 16, color: _amber),
                    ],
                  )
                : Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: valueColor,
                    ),
                  ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: _muted,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. PROFILE VISIBILITY CARD
  // ---------------------------------------------------------------------------
  Widget _buildVisibilityCard(
    BuildContext context,
    SpecialistProfileModel profile,
    SpecialistProfileNotifier notifier,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _lavenderBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: _tealLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.visibility_outlined, color: _tealDark, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Profile Visibility',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: _ink,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Live in Lingua Specialist Directory',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: _muted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                initialValue: profile.profileVisibility,
                onSelected: (val) => notifier.updateVisibility(val),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                itemBuilder: (ctx) => const [
                  PopupMenuItem(value: 'Parents & Learners', child: Text('Parents & Learners')),
                  PopupMenuItem(value: 'Authorized Caseload Only', child: Text('Authorized Caseload Only')),
                  PopupMenuItem(value: 'Private / Direct Link', child: Text('Private / Direct Link')),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _lavenderBorder,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        profile.profileVisibility,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _primaryPurple,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: _primaryPurple),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: const [
              Icon(Icons.info_outline_rounded, size: 14, color: _tealDark),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Learners can discover and request sessions with you.',
                  style: TextStyle(
                    fontSize: 11,
                    color: _tealDark,
                    fontWeight: FontWeight.w500,
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
  // 5. ABOUT ME CARD
  // ---------------------------------------------------------------------------
  Widget _buildAboutMeCard(
    BuildContext context,
    SpecialistProfileModel profile,
    SpecialistProfileState state,
    SpecialistProfileNotifier notifier,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _lavenderBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.auto_awesome, color: _primaryPurple, size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'About Me',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            state.isBioExpanded ? profile.fullBio : profile.aboutMe,
            style: const TextStyle(
              fontSize: 13,
              color: _ink,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => notifier.toggleBioExpanded(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  state.isBioExpanded ? 'Show less' : 'Read full bio',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: _primaryPurple,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  state.isBioExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: _primaryPurple,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 6. SUPPORT FOCUS AREAS CARD
  // ---------------------------------------------------------------------------
  Widget _buildSupportFocusCard(BuildContext context, SpecialistProfileModel profile) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _lavenderBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE9FE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.menu_book_rounded, color: _primaryPurple, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Support Focus Areas',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _lavenderPill,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${profile.supportFocusAreas.length} Areas',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _primaryPurple,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: profile.supportFocusAreas.map((area) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: _buildFocusAreaPill(area),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFocusAreaPill(String area) {
    final config = _getFocusAreaConfig(area);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: _lavenderPill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _lavenderBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 17, color: config.color),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              area,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _AreaConfig _getFocusAreaConfig(String area) {
    final lower = area.toLowerCase();
    if (lower.contains('reading')) {
      return const _AreaConfig(Icons.auto_stories_outlined, Color(0xFF8B5CF6));
    } else if (lower.contains('speech') || lower.contains('pacing')) {
      return const _AreaConfig(Icons.record_voice_over_rounded, Color(0xFF2563EB));
    } else if (lower.contains('phonics') || lower.contains('spelling')) {
      return const _AreaConfig(Icons.spellcheck_rounded, Color(0xFF0D9488));
    } else if (lower.contains('vocabulary')) {
      return const _AreaConfig(Icons.lightbulb_outline_rounded, Color(0xFFD97706));
    } else if (lower.contains('story') || lower.contains('expression')) {
      return const _AreaConfig(Icons.draw_outlined, Color(0xFFF59E0B));
    } else if (lower.contains('listening')) {
      return const _AreaConfig(Icons.headphones_outlined, Color(0xFF475569));
    } else {
      return const _AreaConfig(Icons.extension_outlined, Color(0xFF10B981));
    }
  }

  // ---------------------------------------------------------------------------
  // 7. PRACTICE DETAILS CARD
  // ---------------------------------------------------------------------------
  Widget _buildPracticeDetailsCard(BuildContext context, SpecialistProfileModel profile) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _lavenderBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.explore_outlined, color: _primaryPurple, size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Practice Details',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _buildDetailItem(
            icon: Icons.school_outlined,
            title: 'EXPERIENCE',
            content: profile.practiceDetails['experience'] ?? '8+ Years Pediatric Practice',
          ),
          const SizedBox(height: 10),

          _buildDetailItem(
            icon: Icons.translate_rounded,
            title: 'LANGUAGES',
            content: profile.practiceDetails['languages'] ?? 'English (Native), Spanish (Conversational)',
          ),
          const SizedBox(height: 10),

          _buildDetailItem(
            icon: Icons.groups_outlined,
            title: 'LEARNER AGE GROUPS',
            content: profile.practiceDetails['age_groups'] ?? 'Preschool (3–5), Elementary (6–10), Teens (11–16)',
          ),
          const SizedBox(height: 10),

          _buildDetailItem(
            icon: Icons.videocam_outlined,
            title: 'SUPPORTED FORMATS',
            content: profile.practiceDetails['supported_formats'] ?? '1-on-1 Interactive Audio & Video, Asynchronous Practice Reviews',
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _lavenderPill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _lavenderBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFEDE9FE),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: _primaryPurple),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: _muted,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _ink,
                    height: 1.3,
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
  // 8. CREDENTIALS & SAFETY CARD
  // ---------------------------------------------------------------------------
  Widget _buildCredentialsCard(BuildContext context, SpecialistProfileModel profile) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _lavenderBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.verified_user_outlined, color: _primaryPurple, size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Credentials & Safety',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
              ),
              InkWell(
                key: const Key('view_verification_status_link'),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.specialistVerificationStatus,
                  );
                },
                child: const Text(
                  'View Status >',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _primaryPurple,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          ...profile.credentials.map((cred) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _lavenderPill,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _lavenderBorder),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      cred.type == 'safety'
                          ? Icons.shield_outlined
                          : Icons.check_circle_outline_rounded,
                      color: _tealDark,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cred.title,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            cred.subtitle,
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
            );
          }),

          const SizedBox(height: 4),
          Center(
            child: Text(
              profile.disclaimer,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: _muted,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 9. ACTION BUTTONS
  // ---------------------------------------------------------------------------
  Widget _buildActionButtons(BuildContext context, SpecialistProfileModel profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Primary Edit Profile Button
        ElevatedButton(
          onPressed: () => _showEditProfileSheet(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryPurple,
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.edit_outlined, size: 18),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Edit Specialist Profile',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Secondary Manage Schedule & Slots Button
        OutlinedButton(
          key: const Key('profile_manage_schedule_button'),
          onPressed: () {
            Navigator.pushNamed(
              context,
              AppRoutes.specialistAvailabilitySettings,
            );
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: _primaryPurple,
            side: const BorderSide(color: _primaryPurple, width: 1.5),
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.calendar_month_outlined, size: 18),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Manage Schedule & Slots',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Tertiary Help & Support Button
        TextButton(
          key: const Key('profile_help_support_button'),
          onPressed: () {
            Navigator.pushNamed(context, AppRoutes.specialistHelpSupport);
          },
          style: TextButton.styleFrom(
            foregroundColor: _primaryPurple,
            minimumSize: const Size.fromHeight(44),
          ),
          child: const FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.help_outline, size: 18, color: _primaryPurple),
                SizedBox(width: 6),
                Text(
                  'Help & Support Center',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: _primaryPurple,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Specialist Settings Action Button
        TextButton(
          key: const Key('profile_settings_action_button'),
          onPressed: () {
            Navigator.pushNamed(context, AppRoutes.specialistSettings);
          },
          style: TextButton.styleFrom(
            foregroundColor: _muted,
            minimumSize: const Size.fromHeight(40),
          ),
          child: const FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.settings_outlined, size: 17, color: _muted),
                SizedBox(width: 6),
                Text(
                  'Specialist Settings & Preferences',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 10. PRIVACY FOOTER
  // ---------------------------------------------------------------------------
  Widget _buildPrivacyFooter(SpecialistProfileModel profile) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _tealLight,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.lock_outline_rounded, color: _tealDark, size: 16),
            ),
            const SizedBox(height: 8),
            Text(
              profile.privacyReassurance,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
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
  // EDIT PROFILE MODAL SHEET
  // ---------------------------------------------------------------------------
  void _showEditProfileSheet(BuildContext context) {
    final profile = ref.read(specialistProfileNotifierProvider).profile;
    final nameCtrl = TextEditingController(text: profile.displayName);
    final titleCtrl = TextEditingController(text: profile.professionalTitle);
    final locationCtrl = TextEditingController(text: profile.location);
    final bioCtrl = TextEditingController(text: profile.fullBio);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Edit Specialist Profile',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _ink),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Display Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: 'Professional Title',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locationCtrl,
                decoration: InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bioCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Bio & Introduction',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () async {
                  final updated = profile.copyWith(
                    displayName: nameCtrl.text.trim(),
                    professionalTitle: titleCtrl.text.trim(),
                    location: locationCtrl.text.trim(),
                    fullBio: bioCtrl.text.trim(),
                    aboutMe: bioCtrl.text.trim().length > 100
                        ? '${bioCtrl.text.trim().substring(0, 100)}...'
                        : bioCtrl.text.trim(),
                  );
                  Navigator.pop(ctx);
                  final success = await ref
                      .read(specialistProfileNotifierProvider.notifier)
                      .updateProfile(updated);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? 'Profile updated successfully' : 'Failed to update profile'),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryPurple,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AreaConfig {
  final IconData icon;
  final Color color;
  const _AreaConfig(this.icon, this.color);
}

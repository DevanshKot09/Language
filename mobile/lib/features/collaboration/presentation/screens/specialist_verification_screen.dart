import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/router/app_router.dart';
import '../../application/collaboration_providers.dart';
import '../../domain/models/collaboration_models.dart';

/// Specialist Verification Status Screen.
///
/// Designed to visually match the user-provided Stitch reference:
/// - Top app bar with back navigation and profile avatar.
/// - Hero Verified card: Teal shield icon, "• PROFILE VERIFIED" badge,
///   "Your profile is verified" headline, validity date footer.
/// - Review Milestones section: 5-step visual progression
///   (Profile, Details, Degrees, Review, Badge).
/// - Specialist Details card: "Edit Profile >" CTA, "MR" avatar, name,
///   specialization, experience, languages, and Approved Support Domains chips.
/// - Verified Documents list: Degrees, Board Certification, Child-Safe clearance
///   with "✓ Approved" and "✓ Cleared" badges. Encrypted • FERPA Compliant header.
/// - Navigation to Help & Support for any questions.
/// - Fully responsive down to 320px width without RenderFlex overflow.
class SpecialistVerificationScreen extends ConsumerStatefulWidget {
  const SpecialistVerificationScreen({super.key});

  @override
  ConsumerState<SpecialistVerificationScreen> createState() =>
      _SpecialistVerificationScreenState();
}

class _SpecialistVerificationScreenState
    extends ConsumerState<SpecialistVerificationScreen> {
  static const _ink = Color(0xFF1E1B4B);
  static const _primaryPurple = Color(0xFF5925DC);
  static const _lavenderBg = Color(0xFFF8F7FF);
  static const _lavenderBorder = Color(0xFFEDE9FE);
  static const _lavenderCard = Color(0xFFF5F3FF);
  static const _muted = Color(0xFF64748B);
  static const _teal = Color(0xFF0D9488);
  static const _tealLight = Color(0xFFCCFBF1);
  static const _cyanMint = Color(0xFF2DD4BF);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(specialistVerificationNotifierProvider);
    final notifier =
        ref.read(specialistVerificationNotifierProvider.notifier);
    final verif = state.verification;

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
                      onRefresh: () => notifier.loadVerification(),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 1. Verified Hero Card
                            _buildHeroVerifiedCard(verif),

                            const SizedBox(height: 18),

                            // 2. Review Milestones Card
                            _buildReviewMilestonesCard(verif),

                            const SizedBox(height: 18),

                            // 3. Specialist Details Card
                            _buildSpecialistDetailsCard(context, verif),

                            const SizedBox(height: 22),

                            // 4. Verified Documents Section
                            _buildVerifiedDocumentsSection(verif),

                            const SizedBox(height: 20),

                            // 5. Help & Support Link Card
                            _buildHelpBanner(context),

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
            key: const Key('verification_back_button'),
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
              'Verification Status',
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

  Widget _buildHeroVerifiedCard(SpecialistVerificationModel verif) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
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
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _cyanMint.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.verified,
                    color: _teal,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _tealLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
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
                        verif.statusBadge,
                        style: const TextStyle(
                          color: _teal,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            verif.headline,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _ink,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            verif.description,
            style: const TextStyle(
              fontSize: 13,
              color: _muted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 15,
                color: _muted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  verif.verificationDateText,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _muted,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewMilestonesCard(SpecialistVerificationModel verif) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
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
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Review Milestones',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${verif.milestonesCompleted} of ${verif.milestonesTotal} Complete',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _primaryPurple,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildMilestoneProgress(verif),
        ],
      ),
    );
  }

  Widget _buildMilestoneProgress(SpecialistVerificationModel verif) {
    final milestones = verif.milestones;
    if (milestones.isEmpty) return const SizedBox.shrink();

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: SizedBox(
        width: 380,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(milestones.length * 2 - 1, (index) {
            if (index.isOdd) {
              // Connector line
              return Expanded(
                child: Container(
                  height: 3,
                  margin: const EdgeInsets.only(top: 13),
                  color: _primaryPurple,
                ),
              );
            }

            final mIndex = index ~/ 2;
            final m = milestones[mIndex];
            final isLast = mIndex == milestones.length - 1;

            return Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isLast ? _teal : _primaryPurple,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryPurple.withValues(alpha: 0.2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      isLast ? Icons.verified_user : Icons.check,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    m.label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _ink,
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildSpecialistDetailsCard(
    BuildContext context,
    SpecialistVerificationModel verif,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
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
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.badge_outlined, color: _primaryPurple, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Specialist Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                InkWell(
                  key: const Key('edit_profile_link'),
                  onTap: () {
                    Navigator.of(context).pushNamed(AppRoutes.specialistProfile);
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Edit Profile',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _primaryPurple,
                        ),
                      ),
                      Icon(Icons.chevron_right, size: 18, color: _primaryPurple),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Inner lavender container
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _lavenderCard,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _primaryPurple.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          verif.specialistInitials,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _primaryPurple,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            verif.specialistName,
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
                            verif.specialistRoleSubtitle,
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
                const SizedBox(height: 12),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.school_outlined, size: 14, color: _teal),
                      const SizedBox(width: 4),
                      Text(
                        verif.experienceText,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _ink,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text('•', style: TextStyle(color: _muted)),
                      const SizedBox(width: 10),
                      const Icon(Icons.translate, size: 14, color: _primaryPurple),
                      const SizedBox(width: 4),
                      Text(
                        verif.languagesText,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Text(
            'APPROVED SUPPORT DOMAINS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: _muted,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: verif.approvedDomains.map((domain) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: _lavenderCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _lavenderBorder),
                ),
                child: Text(
                  domain,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _ink,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifiedDocumentsSection(SpecialistVerificationModel verif) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Verified Documents',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                verif.complianceNotice,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _muted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ...verif.verifiedDocuments.map((doc) => _buildDocumentCard(doc)),
      ],
    );
  }

  Widget _buildDocumentCard(SpecialistVerifiedDocumentModel doc) {
    IconData iconData = Icons.school_outlined;
    if (doc.iconType == 'certificate') {
      iconData = Icons.workspace_premium_outlined;
    } else if (doc.iconType == 'shield') {
      iconData = Icons.shield_outlined;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _lavenderBorder),
        boxShadow: [
          BoxShadow(
            color: _primaryPurple.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _primaryPurple.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(iconData, color: _primaryPurple, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  doc.subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _tealLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check, size: 12, color: _teal),
                const SizedBox(width: 3),
                Text(
                  doc.statusLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _teal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpBanner(BuildContext context) {
    return InkWell(
      key: const Key('verification_help_banner'),
      onTap: () {
        Navigator.of(context).pushNamed(AppRoutes.specialistHelpSupport);
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _lavenderCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _lavenderBorder),
        ),
        child: const Row(
          children: [
            Icon(Icons.help_outline, color: _primaryPurple, size: 22),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Need assistance with credentials?',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Visit Help & Support for credential review answers.',
                    style: TextStyle(
                      fontSize: 11,
                      color: _muted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: _primaryPurple, size: 20),
          ],
        ),
      ),
    );
  }
}

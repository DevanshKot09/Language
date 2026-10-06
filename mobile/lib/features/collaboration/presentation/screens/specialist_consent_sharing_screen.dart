import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/router/app_router.dart';
import '../../application/collaboration_providers.dart';
import '../../domain/models/collaboration_models.dart';

/// Specialist Consent & Sharing Management Screen.
///
/// Designed to visually match the user-provided Stitch reference:
/// - Header with circular back button, "Consent & Sharing" title, and Specialist avatar circle.
/// - "Active Circles" counter badge + "+ Connect Learner" quick action.
/// - Learner connection cards:
///   * Card 1 (Aarav Mehta): "✓ Active" badge, Shared collaboration circle with Guardian & Teacher pills,
///     active learning permission scopes (Shared vs Not Shared), consent re-confirmed timestamp,
///     and "Manage Circle" action.
///   * Card 2 (Sophia Chen): "⇄ Limited" badge, Self-directed collaboration circle,
///     reading fluency scope vs learner-private scope, and "View Scope" action.
/// - Bottom learner privacy policy reassurance card with lock icon.
/// - Interactive scope management with confirmation dialogs.
/// - Responsive down to 320px width without RenderFlex overflow.
class SpecialistConsentSharingScreen extends ConsumerWidget {
  const SpecialistConsentSharingScreen({super.key});

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
    final state = ref.watch(specialistConsentCirclesNotifierProvider);
    final notifier = ref.read(specialistConsentCirclesNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: _lavenderBg,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top App Bar
            _buildAppBar(context),

            // 2. Subheader Row (Active Circles + Connect Learner)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: _buildSubHeader(context, state),
            ),

            // 3. Scrollable List of Consent Circles
            Expanded(
              child: RefreshIndicator(
                color: _primaryPurple,
                onRefresh: () => notifier.loadCircles(),
                child: state.circles.isEmpty
                    ? _buildEmptyState(context)
                    : SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ...state.circles.map(
                              (circle) => Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: _buildConsentCircleCard(context, circle, notifier),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Bottom Privacy Notice Card
                            _buildPrivacyNoticeCard(),

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
              'Consent & Sharing',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: _ink,
                letterSpacing: -0.3,
              ),
            ),
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
  // 2. SUBHEADER (Active Circles + Connect Learner)
  // ---------------------------------------------------------------------------
  Widget _buildSubHeader(BuildContext context, SpecialistConsentCirclesState state) {
    final activeCount = state.circles.where((c) => c.status == 'active').length;

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 6,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            const Text(
              'Active Circles',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: _ink,
                letterSpacing: -0.2,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _tealLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '$activeCount Active',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: _tealDark,
                ),
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () {
            Navigator.pushReplacementNamed(
              context,
              AppRoutes.specialistDashboard,
              arguments: 1, // Caseload Tab
            );
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.add_circle_outline_rounded, color: _primaryPurple, size: 18),
              SizedBox(width: 4),
              Text(
                'Connect Learner',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _primaryPurple,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 3. CONSENT CIRCLE CARD
  // ---------------------------------------------------------------------------
  Widget _buildConsentCircleCard(
    BuildContext context,
    SpecialistConsentCircleModel circle,
    SpecialistConsentCirclesNotifier notifier,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _lavenderBorder, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x082B1277),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header: Avatar + Name + Status Pill + 3-dots
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: circle.avatarColor == 'amber' ? _amberLight : const Color(0xFFEDE9FE),
                child: Text(
                  circle.learnerInitials,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: circle.avatarColor == 'amber' ? _amber : _primaryPurple,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      children: [
                        Text(
                          circle.learnerName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: _ink,
                          ),
                        ),
                        _buildStatusBadge(circle),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      circle.subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: _muted),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                onSelected: (val) => _handleCardMenuAction(context, val, circle),
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'details', child: Text('View Full Agreement')),
                  const PopupMenuItem(value: 'reconfirm', child: Text('Re-confirm Consent')),
                  const PopupMenuItem(
                    value: 'pause',
                    child: Text('Pause Access', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Shared Collaboration Circle Section
          _buildCollaborationMembersSection(circle),

          const SizedBox(height: 16),

          // Active Learning Permission Scopes Section
          _buildPermissionScopesSection(context, circle, notifier),

          const SizedBox(height: 14),

          // Card Footer: Reconfirmed timestamp + Action button
          Row(
            children: [
              Icon(
                circle.consentReconfirmedDate != null
                    ? Icons.verified_user_outlined
                    : Icons.access_time_rounded,
                size: 13,
                color: _muted,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  circle.consentReconfirmedDate != null
                      ? 'Consent re-confirmed ${circle.consentReconfirmedDate}'
                      : 'Updated ${circle.updatedTimeAgo ?? "recently"}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: _muted,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ElevatedButton(
                onPressed: () => _showManageCircleSheet(context, circle, notifier),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _lavenderPill,
                  foregroundColor: _primaryPurple,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  circle.status == 'limited' ? 'View Scope' : 'Manage Circle',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(SpecialistConsentCircleModel circle) {
    if (circle.status == 'active') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF006257),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          circle.statusLabel,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: _amber,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          circle.statusLabel,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      );
    }
  }

  Widget _buildCollaborationMembersSection(SpecialistConsentCircleModel circle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _lavenderPill,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            circle.status == 'limited'
                ? 'COLLABORATION CIRCLE'
                : 'SHARED COLLABORATION CIRCLE',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
              color: _muted,
            ),
          ),
          const SizedBox(height: 8),
          if (circle.status == 'limited')
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4,
                  children: [
                    Text(
                      circle.collaborationCircle.first.name,
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _ink),
                    ),
                    Text(
                      circle.collaborationCircle.first.roleLabel,
                      style: const TextStyle(fontSize: 11, color: _muted),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    circle.collaborationCircle.last.name == 'You'
                        ? 'You (Specialist)'
                        : circle.collaborationCircle.last.name,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: _primaryPurple,
                    ),
                  ),
                ),
              ],
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: circle.collaborationCircle.map((member) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 8,
                        backgroundColor: member.isSpecialist
                            ? const Color(0xFFEDE9FE)
                            : (member.initial == 'P' ? _tealLight : _amberLight),
                        child: Text(
                          member.initial,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: member.isSpecialist
                                ? _primaryPurple
                                : (member.initial == 'P' ? _tealDark : _amber),
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 160),
                        child: Text(
                          '${member.name} ${member.roleLabel}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: member.isSpecialist ? _primaryPurple : _ink,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildPermissionScopesSection(
    BuildContext context,
    SpecialistConsentCircleModel circle,
    SpecialistConsentCirclesNotifier notifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ACTIVE LEARNING PERMISSION SCOPES',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.7,
            color: _muted,
          ),
        ),
        const SizedBox(height: 8),
        ...circle.permissionScopes.map((scope) {
          final icon = _getScopeIcon(scope.iconType);
          return Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: InkWell(
              onTap: () => _confirmToggleScope(context, circle, scope, notifier),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _lavenderPill,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _lavenderBorder),
                ),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      size: 16,
                      color: scope.isShared ? _tealDark : _muted,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        scope.title,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: scope.isShared ? _ink : _muted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _buildScopeStatusBadge(scope),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildScopeStatusBadge(PermissionScopeItemModel scope) {
    if (scope.isShared) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: _tealLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.check_rounded, size: 12, color: _tealDark),
            SizedBox(width: 3),
            Text(
              'Shared',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: _tealDark,
              ),
            ),
          ],
        ),
      );
    } else if (scope.statusLabel.contains('Private')) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFEDE9FE),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.person_outline_rounded, size: 12, color: _primaryPurple),
            SizedBox(width: 3),
            Text(
              'Learner Private',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: _primaryPurple,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.lock_outline_rounded, size: 12, color: _muted),
            SizedBox(width: 3),
            Text(
              'Not Shared',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: _muted,
              ),
            ),
          ],
        ),
      );
    }
  }

  IconData _getScopeIcon(String iconType) {
    switch (iconType) {
      case 'mic':
        return Icons.mic_none_rounded;
      case 'trend':
        return Icons.trending_up_rounded;
      case 'chat':
        return Icons.chat_bubble_outline_rounded;
      case 'puzzle':
        return Icons.extension_outlined;
      case 'book':
        return Icons.menu_book_rounded;
      case 'mic_off':
      default:
        return Icons.mic_off_outlined;
    }
  }

  // ---------------------------------------------------------------------------
  // 4. PRIVACY NOTICE CARD
  // ---------------------------------------------------------------------------
  Widget _buildPrivacyNoticeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _lavenderPill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _lavenderBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Learner privacy is our priority. Guardians or adult learners can pause, reconfigure, or withdraw specialization scopes at any time directly through their profile.',
              style: TextStyle(
                fontSize: 11.5,
                color: Color(0xFF475569),
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. EMPTY STATE
  // ---------------------------------------------------------------------------
  Widget _buildEmptyState(BuildContext context) {
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
              child: const Icon(Icons.verified_user_outlined, size: 32, color: _primaryPurple),
            ),
            const SizedBox(height: 16),
            const Text(
              'No active sharing',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _ink,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'You currently have no active learner collaboration circles.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: _muted),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(
                  context,
                  AppRoutes.specialistDashboard,
                  arguments: 1,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: const Text('Connect a learner'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ACTIONS & MODALS
  // ---------------------------------------------------------------------------
  void _confirmToggleScope(
    BuildContext context,
    SpecialistConsentCircleModel circle,
    PermissionScopeItemModel scope,
    SpecialistConsentCirclesNotifier notifier,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(scope.isShared ? 'Restrict Scope Access?' : 'Request Scope Access?'),
        content: Text(
          scope.isShared
              ? 'Are you sure you want to stop sharing "${scope.title}" with the collaboration circle?'
              : 'Would you like to request access to "${scope.title}" from the learner\'s authorized circle?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              notifier.toggleScope(circle.id, scope.key, scope.isShared);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    scope.isShared ? 'Scope access restricted' : 'Scope access updated',
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: _primaryPurple, foregroundColor: Colors.white),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showManageCircleSheet(
    BuildContext context,
    SpecialistConsentCircleModel circle,
    SpecialistConsentCirclesNotifier notifier,
  ) {
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Manage Circle • ${circle.learnerName}',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _ink),
              ),
              const SizedBox(height: 6),
              Text(
                'Status: ${circle.statusLabel} • ${circle.subtitle}',
                style: const TextStyle(fontSize: 12.5, color: _muted),
              ),
              const Divider(height: 24),
              ListTile(
                leading: const Icon(Icons.people_outline_rounded, color: _primaryPurple),
                title: const Text('View Circle Members'),
                subtitle: Text('${circle.collaborationCircle.length} authorized members'),
                onTap: () => Navigator.pop(ctx),
              ),
              ListTile(
                leading: const Icon(Icons.history_rounded, color: _tealDark),
                title: const Text('Consent Audit Trail'),
                subtitle: Text(circle.consentReconfirmedDate != null
                    ? 'Last re-confirmed ${circle.consentReconfirmedDate}'
                    : 'Updated 3 days ago'),
                onTap: () => Navigator.pop(ctx),
              ),
              ListTile(
                leading: const Icon(Icons.pause_circle_outline_rounded, color: Colors.red),
                title: const Text('Pause Learning Scope', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Scope pause request initiated.')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleCardMenuAction(
    BuildContext context,
    String action,
    SpecialistConsentCircleModel circle,
  ) {
    if (action == 'details') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Viewing agreement for ${circle.learnerName}.')),
      );
    } else if (action == 'reconfirm') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Consent re-confirmation sent to guardian.')),
      );
    } else if (action == 'pause') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Access paused for ${circle.learnerName}.')),
      );
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/router/app_router.dart';
import '../../application/collaboration_providers.dart';
import '../../domain/models/collaboration_models.dart';

/// Specialist Help & Support Screen.
///
/// Designed to visually match the user-provided Stitch reference:
/// - Top App Bar with back navigation and "🎧 Help & Support" capsule badge.
/// - Search input bar ("Search help articles, topics, guides...").
/// - Browse by Topic 8-category 2-column grid.
/// - Frequently Asked Questions: Curated answers with expand/collapse chevrons.
/// - "Still need help?" card with 3 action buttons:
///   1. "Send a Message (<15m reply)" (wires to specialist messages)
///   2. "Report a Problem" (interactive modal sheet + problem submission)
///   3. "Schedule Platform Walkthrough"
/// - System Status footer: All Systems Operational, desk hours, avg response,
///   version info, and release notes link.
/// - Search empty state: "No help articles found".
/// - Responsive down to 320px width without RenderFlex overflow.
class SpecialistHelpSupportScreen extends ConsumerStatefulWidget {
  const SpecialistHelpSupportScreen({super.key});

  @override
  ConsumerState<SpecialistHelpSupportScreen> createState() =>
      _SpecialistHelpSupportScreenState();
}

class _SpecialistHelpSupportScreenState
    extends ConsumerState<SpecialistHelpSupportScreen> {
  static const _ink = Color(0xFF1E1B4B);
  static const _primaryPurple = Color(0xFF5925DC);
  static const _lavenderBg = Color(0xFFF8F7FF);
  static const _lavenderBorder = Color(0xFFEDE9FE);
  static const _lavenderCard = Color(0xFFF5F3FF);
  static const _muted = Color(0xFF64748B);
  static const _teal = Color(0xFF0D9488);
  static const _tealLight = Color(0xFFCCFBF1);
  static const _cyanMint = Color(0xFF2DD4BF);
  static const _green = Color(0xFF10B981);
  static const _amber = Color(0xFFD97706);

  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(specialistHelpNotifierProvider);
    final notifier = ref.read(specialistHelpNotifierProvider.notifier);
    final help = state.helpData;

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
                      onRefresh: () => notifier.loadHelp(),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 1. Search Bar
                            _buildSearchBar(notifier),

                            const SizedBox(height: 20),

                            // 2. Browse by Topic
                            _buildBrowseByTopicSection(context, state),

                            const SizedBox(height: 24),

                            // 3. Frequently Asked Questions
                            _buildFaqSection(state, notifier),

                            const SizedBox(height: 24),

                            // 4. Still Need Help? Card
                            _buildStillNeedHelpCard(context, notifier),

                            const SizedBox(height: 24),

                            // 5. System Status & Desk Hours Footer
                            _buildSystemStatusFooter(help),

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
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            IconButton(
              key: const Key('help_back_button'),
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _primaryPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.headset_mic_outlined,
                      size: 16, color: _primaryPurple),
                  SizedBox(width: 6),
                  Text(
                    'Help & Support',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _primaryPurple,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(SpecialistHelpNotifier notifier) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _lavenderBorder),
        boxShadow: [
          BoxShadow(
            color: _primaryPurple.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        key: const Key('help_search_field'),
        controller: _searchController,
        onChanged: (val) => notifier.setSearchQuery(val),
        decoration: InputDecoration(
          hintText: 'Search help articles, topics, guides...',
          hintStyle: const TextStyle(
            color: _muted,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: const Icon(Icons.search, color: _primaryPurple, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18, color: _muted),
                  onPressed: () {
                    _searchController.clear();
                    notifier.setSearchQuery('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildBrowseByTopicSection(
    BuildContext context,
    SpecialistHelpState state,
  ) {
    final categories = state.filteredCategories;

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
                'Browse by Topic',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '${categories.length} categories',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _muted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.1,
          ),
          itemBuilder: (context, index) {
            final cat = categories[index];
            return _buildCategoryCard(context, cat);
          },
        ),
      ],
    );
  }

  Widget _buildCategoryCard(BuildContext context, HelpCategoryItemModel cat) {
    IconData iconData = Icons.person_outline;
    Color iconColor = _primaryPurple;
    Color bgCircle = _primaryPurple.withValues(alpha: 0.12);

    if (cat.id == 'sessions') {
      iconData = Icons.videocam_outlined;
      iconColor = _teal;
      bgCircle = _teal.withValues(alpha: 0.12);
    } else if (cat.id == 'learners') {
      iconData = Icons.school_outlined;
      iconColor = _amber;
      bgCircle = _amber.withValues(alpha: 0.12);
    } else if (cat.id == 'messages') {
      iconData = Icons.chat_bubble_outline;
      iconColor = _primaryPurple;
      bgCircle = _primaryPurple.withValues(alpha: 0.12);
    } else if (cat.id == 'consent') {
      iconData = Icons.shield_outlined;
      iconColor = _cyanMint;
      bgCircle = _cyanMint.withValues(alpha: 0.15);
    } else if (cat.id == 'verification') {
      iconData = Icons.verified_user_outlined;
      iconColor = _teal;
      bgCircle = _teal.withValues(alpha: 0.12);
    } else if (cat.id == 'availability') {
      iconData = Icons.access_time;
      iconColor = _primaryPurple;
      bgCircle = _primaryPurple.withValues(alpha: 0.12);
    } else if (cat.id == 'alerts') {
      iconData = Icons.notifications_none;
      iconColor = _primaryPurple;
      bgCircle = _primaryPurple.withValues(alpha: 0.12);
    }

    return InkWell(
      key: Key('topic_category_${cat.id}'),
      onTap: () => _handleCategoryTap(context, cat.id),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _lavenderBorder),
          boxShadow: [
            BoxShadow(
              color: _primaryPurple.withValues(alpha: 0.02),
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
                color: bgCircle,
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: iconColor, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cat.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    cat.subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: _muted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleCategoryTap(BuildContext context, String catId) {
    if (catId == 'account') {
      Navigator.of(context).pushNamed(AppRoutes.specialistProfile);
    } else if (catId == 'availability') {
      Navigator.of(context).pushNamed(AppRoutes.specialistAvailabilitySettings);
    } else if (catId == 'verification') {
      Navigator.of(context).pushNamed(AppRoutes.specialistVerificationStatus);
    } else if (catId == 'consent') {
      Navigator.of(context).pushNamed(AppRoutes.specialistConsentSharing);
    } else if (catId == 'messages') {
      Navigator.of(context).pushNamed(AppRoutes.specialistMessages);
    } else if (catId == 'alerts') {
      Navigator.of(context).pushNamed(AppRoutes.specialistNotifications);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Browsing articles for topic: $catId'),
        ),
      );
    }
  }

  Widget _buildFaqSection(
    SpecialistHelpState state,
    SpecialistHelpNotifier notifier,
  ) {
    final faqs = state.filteredFaqs;

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
                'Frequently Asked Questions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
              const SizedBox(width: 16),
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Showing all 24 curated articles.')),
                  );
                },
                child: const Text(
                  'View all (24)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _primaryPurple,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Top answers curated for speech specialists',
          style: TextStyle(
            fontSize: 12,
            color: _muted,
          ),
        ),
        const SizedBox(height: 14),
        if (faqs.isEmpty)
          _buildSearchEmptyState()
        else
          ...faqs.map(
            (faq) => _buildFaqCard(
              faq: faq,
              isExpanded: state.expandedFaqIds.contains(faq.id),
              onTap: () => notifier.toggleFaq(faq.id),
            ),
          ),
      ],
    );
  }

  Widget _buildSearchEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _lavenderBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _primaryPurple.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_off, color: _primaryPurple, size: 24),
          ),
          const SizedBox(height: 12),
          const Text(
            'No help articles found',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Try searching for topics like availability, consent, or sessions.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: _muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqCard({
    required FaqItemModel faq,
    required bool isExpanded,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _lavenderBorder),
        boxShadow: [
          BoxShadow(
            color: _primaryPurple.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          key: Key('faq_item_${faq.id}'),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        faq.question,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: _lavenderCard,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: _primaryPurple,
                        size: 18,
                      ),
                    ),
                  ],
                ),
                if (isExpanded) ...[
                  const SizedBox(height: 12),
                  const Divider(color: _lavenderBorder, height: 1),
                  const SizedBox(height: 12),
                  Text(
                    faq.answer,
                    style: const TextStyle(
                      fontSize: 13,
                      color: _muted,
                      height: 1.45,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStillNeedHelpCard(
    BuildContext context,
    SpecialistHelpNotifier notifier,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _lavenderCard,
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
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: _primaryPurple,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.chat_bubble, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 14),
          const Text(
            'Still need help?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _ink,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Our Specialist Support team is here to assist with caseload setup, parent circles, and technical guidance.',
            style: TextStyle(
              fontSize: 13,
              color: _muted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),

          // Button 1: Send a Message
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              key: const Key('help_send_message_button'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _ink,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.specialistMessages);
              },
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_outlined, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Send a Message (<15m reply)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Button 2: Report a Problem
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              key: const Key('help_report_problem_button'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _cyanMint,
                foregroundColor: _ink,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
              onPressed: () => _showReportProblemSheet(context, notifier),
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bug_report_outlined, size: 18, color: _ink),
                    SizedBox(width: 8),
                    Text(
                      'Report a Problem',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Button 3: Schedule Platform Walkthrough
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              key: const Key('help_schedule_walkthrough_button'),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _ink,
                side: const BorderSide(color: _lavenderBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Walkthrough requested! A specialist success lead will email your invite.',
                    ),
                  ),
                );
              },
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 16, color: _primaryPurple),
                    SizedBox(width: 8),
                    Text(
                      'Schedule Platform Walkthrough',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showReportProblemSheet(
    BuildContext context,
    SpecialistHelpNotifier notifier,
  ) {
    String selectedCategory = 'Audio & Microphones';
    final descController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Report a Problem',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tell us what went wrong so our technical specialists can investigate.',
                    style: TextStyle(fontSize: 12, color: _muted),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Category',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    isExpanded: true,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _lavenderBorder),
                      ),
                    ),
                    items: [
                      'Audio & Microphones',
                      'Video & Rooms',
                      'Caseload Sync',
                      'Consent Permissions',
                      'Profile & Credentials',
                      'Other Technical Issue',
                    ].map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Text(
                          cat,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setSheetState(() => selectedCategory = val);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    key: const Key('report_problem_description_field'),
                    controller: descController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Briefly describe what happened...',
                      hintStyle: const TextStyle(fontSize: 12, color: _muted),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _lavenderBorder),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      key: const Key('submit_problem_button'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      onPressed: () {
                        final desc = descController.text.trim();
                        if (desc.isNotEmpty) {
                          notifier.reportProblem(selectedCategory, desc);
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Ticket received! Our engineering team is investigating.',
                              ),
                            ),
                          );
                        }
                      },
                      child: const Text(
                        'Submit Report',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSystemStatusFooter(SpecialistHelpModel help) {
    return Container(
      padding: const EdgeInsets.all(18),
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
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: _green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      help.systemStatus,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _tealLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Live Status',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _teal,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _lavenderCard,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SUPPORT DESK HOURS',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: _muted,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        help.supportDeskHours,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: _lavenderBorder,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AVG RESPONSE',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: _muted,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        help.avgResponseTime,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  help.appVersion,
                  style: const TextStyle(
                    fontSize: 11,
                    color: _muted,
                  ),
                ),
                const SizedBox(width: 16),
                InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Viewing v2.4.1 Release Notes.'),
                      ),
                    );
                  },
                  child: const Text(
                    'Release Notes',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _primaryPurple,
                      decoration: TextDecoration.underline,
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
}

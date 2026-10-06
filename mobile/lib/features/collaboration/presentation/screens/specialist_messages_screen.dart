import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingua_ai/app/providers/session_provider.dart';
import 'package:lingua_ai/app/router/app_router.dart';
import 'package:lingua_ai/core/widgets/lingua_skeleton.dart';
import 'package:lingua_ai/features/collaboration/application/collaboration_providers.dart';
import 'package:lingua_ai/features/collaboration/domain/models/collaboration_models.dart';
import 'package:lingua_ai/features/error_state/error_state_type.dart';
import 'package:lingua_ai/features/error_state/error_state_view.dart';

/// Specialist – Messages & Collaboration Screen
///
/// Faithfully reproduces the Stitch visual design for the Specialist communication
/// and collaboration center.
///
/// Respects:
/// - Specialist role & active caseload relationships (server-side RBAC)
/// - Guardian consent guardrails (locked state with 'Review & Prompt' action)
/// - Multi-role collaboration groups (Parent + Teacher + Specialist / Adult Learner + Teacher + Specialist)
/// - Strictly non-diagnostic educational positioning
class SpecialistMessagesScreen extends ConsumerStatefulWidget {
  final bool showBottomNav;

  const SpecialistMessagesScreen({
    super.key,
    this.showBottomNav = true,
  });

  @override
  ConsumerState<SpecialistMessagesScreen> createState() => _SpecialistMessagesScreenState();
}

class _SpecialistMessagesScreenState extends ConsumerState<SpecialistMessagesScreen> {
  String _selectedFilter = 'all'; // 'all', 'learners', 'teams', 'unread'
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchExpanded = false;
  String _searchQuery = '';

  // Palette Tokens matching Stitch Design
  static const Color _bg = Color(0xFFFBFBFE);
  static const Color _primary = Color(0xFF5B5BD6);
  static const Color _primaryLight = Color(0xFFEDE9FE);
  static const Color _inkDark = Color(0xFF1E1E38);
  static const Color _muted = Color(0xFF64748B);
  static const Color _borderSubtle = Color(0xFFEEF2F6);
  static const Color _onlineGreen = Color(0xFF10B981);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onFilterSelected(String filterKey) {
    setState(() {
      _selectedFilter = filterKey;
    });
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value.trim();
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearchExpanded = !_isSearchExpanded;
      if (!_isSearchExpanded) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(userSessionProvider);
    final query = SpecialistConversationsQuery(
      filter: _selectedFilter == 'all' ? null : _selectedFilter,
      search: _searchQuery.isEmpty ? null : _searchQuery,
    );

    final conversationsAsync = ref.watch(specialistConversationsProvider(query));

    if (conversationsAsync.hasError && !conversationsAsync.hasValue) {
      return ErrorStateView(
        type: ErrorStateTypeX.fromError(conversationsAsync.error),
        message: conversationsAsync.error?.toString(),
        onRetry: () => ref.invalidate(specialistConversationsProvider(query)),
        isFullScreen: widget.showBottomNav,
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header (Screen Title, Search & Profile Actions)
            _buildHeader(context, session),

            // 2. Expandable Search Field
            if (_isSearchExpanded) _buildSearchField(),

            // 3. Filter Chips Row
            _buildFilterChipsRow(),

            const SizedBox(height: 12),

            // 4. Conversation List Content
            Expanded(
              child: conversationsAsync.when(
                data: (conversations) => _buildConversationList(context, conversations),
                loading: () => _buildLoadingSkeleton(),
                error: (err, _) => _buildErrorState(err, () {
                  ref.invalidate(specialistConversationsProvider(query));
                }),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: widget.showBottomNav ? _buildBottomNav() : null,
    );
  }

  // ---------------------------------------------------------------------------
  // 1. HEADER
  // ---------------------------------------------------------------------------
  Widget _buildHeader(BuildContext context, UserSessionState session) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Messages',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: _inkDark,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Your support conversations',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: _muted,
                  ),
                ),
              ],
            ),
          ),
          // Search Icon Button
          Semantics(
            button: true,
            label: 'Search conversations',
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: _toggleSearch,
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    _isSearchExpanded ? Icons.close_rounded : Icons.search_rounded,
                    color: const Color(0xFF334155),
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Specialist Profile Button
          Semantics(
            button: true,
            label: 'Specialist profile and settings',
            child: GestureDetector(
              onTap: () => _showSpecialistProfileModal(context, session),
              child: Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Color(0xFF6366F1),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1F6366F1),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
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
    );
  }

  // ---------------------------------------------------------------------------
  // 2. EXPANDABLE SEARCH FIELD
  // ---------------------------------------------------------------------------
  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _primary.withValues(alpha: 0.35), width: 1.4),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          autofocus: true,
          onChanged: _onSearchChanged,
          style: const TextStyle(fontSize: 14, color: _inkDark),
          decoration: InputDecoration(
            hintText: 'Search by learner, parent, or team...',
            hintStyle: const TextStyle(fontSize: 13.5, color: _muted),
            prefixIcon: const Icon(Icons.search_rounded, color: _primary, size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18, color: _muted),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. FILTER CHIPS ROW
  // ---------------------------------------------------------------------------
  Widget _buildFilterChipsRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _filterChip(
            id: 'all',
            label: 'All',
            icon: Icons.chat_bubble_outline_rounded,
            isSelected: _selectedFilter == 'all',
          ),
          const SizedBox(width: 8),
          _filterChip(
            id: 'learners',
            label: 'Learners',
            icon: Icons.person_outline_rounded,
            iconColor: const Color(0xFF0D9488),
            isSelected: _selectedFilter == 'learners',
          ),
          const SizedBox(width: 8),
          _filterChip(
            id: 'teams',
            label: 'Teams',
            icon: Icons.groups_outlined,
            iconColor: const Color(0xFF6D28D9),
            isSelected: _selectedFilter == 'teams',
          ),
          const SizedBox(width: 8),
          _filterChip(
            id: 'unread',
            label: 'Unread',
            icon: Icons.mark_chat_unread_outlined,
            iconColor: const Color(0xFFD97706),
            isSelected: _selectedFilter == 'unread',
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String id,
    required String label,
    required IconData icon,
    Color? iconColor,
    required bool isSelected,
  }) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: 'Filter conversations by $label',
      child: InkWell(
        onTap: () => _onFilterSelected(id),
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? _primary : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected ? _primary : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x285B5BD6),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ]
                : const [
                    BoxShadow(
                      color: Color(0x06000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 17,
                color: isSelected ? Colors.white : (iconColor ?? const Color(0xFF475569)),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. CONVERSATION LIST (PRIORITY + RECENT SECTIONS)
  // ---------------------------------------------------------------------------
  Widget _buildConversationList(
    BuildContext context,
    List<SpecialistConversationItem> conversations,
  ) {
    if (conversations.isEmpty) {
      return _buildEmptyState();
    }

    final priorityItems = conversations.where((c) => c.isPinned).toList();
    final recentItems = conversations.where((c) => !c.isPinned).toList();

    return RefreshIndicator(
      color: _primary,
      onRefresh: () async {
        final query = SpecialistConversationsQuery(
          filter: _selectedFilter == 'all' ? null : _selectedFilter,
          search: _searchQuery.isEmpty ? null : _searchQuery,
        );
        ref.invalidate(specialistConversationsProvider(query));
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          // Section 1: PRIORITY COLLABORATION (if present)
          if (priorityItems.isNotEmpty) ...[
            _buildSectionHeader(
              title: 'PRIORITY COLLABORATION',
              isPriority: true,
              trailingLabel: 'PINNED',
            ),
            const SizedBox(height: 8),
            ...priorityItems.map((c) => _buildPriorityConversationCard(context, c)),
            const SizedBox(height: 18),
          ],

          // Section 2: RECENT CONVERSATIONS
          if (recentItems.isNotEmpty) ...[
            _buildSectionHeader(
              title: 'RECENT CONVERSATIONS',
              isPriority: false,
              trailingLabel: '${recentItems.length} Active',
            ),
            const SizedBox(height: 8),
            ...recentItems.map((c) => _buildRecentConversationCard(context, c)),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required bool isPriority,
    required String trailingLabel,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isPriority) ...[
                const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFD97706),
                  size: 16,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                title,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: isPriority ? const Color(0xFF78350F) : const Color(0xFF475569),
                ),
              ),
            ],
          ),
          Text(
            trailingLabel,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. PRIORITY CONVERSATION CARD (Dual Avatar, Tags, Preview)
  // ---------------------------------------------------------------------------
  Widget _buildPriorityConversationCard(BuildContext context, SpecialistConversationItem c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDE9FE), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C5B5BD6),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openConversation(context, c),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dual Overlapping Avatar
                _buildDualAvatar(isOnline: c.isOnline),

                const SizedBox(width: 14),

                // Conversation Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title & Timestamp
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              c.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                color: _inkDark,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            c.lastMessageTime,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 5),

                      // Role Badge Pill + Unread Badge Pill
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3E8FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              c.subtitle.isNotEmpty ? c.subtitle : 'Parent · Teacher · Specialist',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF6D28D9),
                              ),
                            ),
                          ),
                          if (c.unreadCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.chat_bubble, size: 10, color: Color(0xFF92400E)),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${c.unreadCount} unread',
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF92400E),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 7),

                      // Last Message Preview
                      Text.rich(
                        TextSpan(
                          children: [
                            if (c.lastMessageSender != null && c.lastMessageSender!.isNotEmpty)
                              TextSpan(
                                text: '${c.lastMessageSender} ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF4338CA),
                                  fontSize: 12.5,
                                ),
                              ),
                            TextSpan(
                              text: c.lastMessageText,
                              style: const TextStyle(
                                color: Color(0xFF334155),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 4),

                // Trailing Chevron
                const Padding(
                  padding: EdgeInsets.only(top: 14),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFFCBD5E1),
                    size: 20,
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
  // 6. RECENT CONVERSATION CARDS
  // ---------------------------------------------------------------------------
  Widget _buildRecentConversationCard(BuildContext context, SpecialistConversationItem c) {
    // Card 3: Guardian Consent Pending Locked State
    if (c.isLocked || c.consentStatus == 'pending') {
      return _buildConsentLockedCard(context, c);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderSubtle, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openConversation(context, c),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar according to type
                _buildAvatarForType(c),

                const SizedBox(width: 13),

                // Main Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title, Dot Badge (if any), Timestamp
                      Row(
                        children: [
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    c.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: _inkDark,
                                    ),
                                  ),
                                ),
                                if (c.avatarType == 'parent_online') ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF6366F1),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            c.lastMessageTime,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 3),

                      // Subtitle / Relationship Row
                      Row(
                        children: [
                          if (c.avatarType == 'parent_online') ...[
                            const Icon(
                              Icons.groups_rounded,
                              size: 13,
                              color: Color(0xFF6366F1),
                            ),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: Text(
                              c.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // Last Message Preview
                      Text.rich(
                        TextSpan(
                          children: [
                            if (c.lastMessageSender != null && c.lastMessageSender!.isNotEmpty)
                              TextSpan(
                                text: '${c.lastMessageSender} ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF334155),
                                  fontSize: 12.5,
                                ),
                              ),
                            TextSpan(
                              text: c.lastMessageText,
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 4),

                // Trailing Chevron
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFCBD5E1),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 7. CONSENT LOCKED CARD (Sofia's Support Circle)
  // ---------------------------------------------------------------------------
  Widget _buildConsentLockedCard(BuildContext context, SpecialistConversationItem c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFEE2E2), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08DC2626),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showConsentPendingDetails(context, c),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Lavender Squircle Face with Red Lock Badge
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE9FE),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.face_rounded,
                            color: Color(0xFF6D28D9),
                            size: 26,
                          ),
                        ),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: const Color(0xFFDC2626),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.lock_rounded,
                              size: 10,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(width: 13),

                    // Title & Timestamp
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  c.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: _inkDark,
                                  ),
                                ),
                              ),
                              Text(
                                c.lastMessageTime,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),

                          // Guardian Consent Pending Pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFCA5A5), width: 0.8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.error_outline_rounded,
                                  size: 12,
                                  color: Color(0xFFDC2626),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Guardian Consent Pending',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFB91C1C),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Review & Prompt Button
                          Semantics(
                            button: true,
                            label: 'Review consent and send prompt to guardian',
                            child: InkWell(
                              onTap: () => _promptGuardianForConsent(context, c),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF991B1B),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x28991B1B),
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  'Review & Prompt',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Shield Notice Row
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Row(
                    children: const [
                      Icon(
                        Icons.shield_outlined,
                        size: 13,
                        color: Color(0xFFDC2626),
                      ),
                      SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          'Audio turns and session notes locked until guardian sign-off.',
                          style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
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
  // 8. AVATAR BUILDERS
  // ---------------------------------------------------------------------------
  Widget _buildDualAvatar({required bool isOnline}) {
    return SizedBox(
      width: 50,
      height: 48,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Base / Primary Avatar (Parent photo / stylized)
          Positioned(
            left: 0,
            top: 0,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'PM',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF92400E),
                    ),
                  ),
                ),
                if (isOnline)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _onlineGreen,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Secondary Overlapping Avatar (Teacher)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFCCFBF1),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x10000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Text(
                'ED',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F766E),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarForType(SpecialistConversationItem c) {
    if (c.avatarType == 'team_teal') {
      // Maya's Learning Circle: Turquoise squircle with team icon + specialist badge
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFF2DD4BF),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.groups_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF0D9488), width: 1.5),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.psychology_outlined,
                size: 11,
                color: Color(0xFF0D9488),
              ),
            ),
          ),
        ],
      );
    }

    if (c.avatarType == 'teacher_book') {
      // Mrs. Eleanor Davies: Circle avatar with purple open book badge
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFEDE9FE),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFDDD6FE), width: 1.5),
            ),
            alignment: Alignment.center,
            child: const Text(
              'ED',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF6D28D9),
              ),
            ),
          ),
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: _primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.8),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.menu_book_rounded,
                size: 10,
                color: Colors.white,
              ),
            ),
          ),
        ],
      );
    }

    // Default / Parent Online Avatar
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(
            c.title.isNotEmpty ? c.title[0].toUpperCase() : 'C',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF92400E),
            ),
          ),
        ),
        if (c.isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _onlineGreen,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 9. EMPTY & ERROR & SKELETON STATES
  // ---------------------------------------------------------------------------
  Widget _buildEmptyState() {
    final isSearching = _searchQuery.isNotEmpty || _selectedFilter != 'all';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _primaryLight,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                isSearching ? Icons.search_off_rounded : Icons.chat_bubble_outline_rounded,
                color: _primary,
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              isSearching ? 'No matching conversations' : 'No support conversations yet',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: _inkDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearching
                  ? 'No conversations found matching "$_searchQuery". Try selecting a different filter or clearing search.'
                  : 'Active caseload learners, connected parents, and teachers will appear here.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: _muted,
                height: 1.4,
              ),
            ),
            if (isSearching) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _searchQuery = '';
                    _selectedFilter = 'all';
                    _isSearchExpanded = false;
                  });
                },
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Reset filters & search'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primary,
                  side: const BorderSide(color: _primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(Object? error, VoidCallback onRetry) {
    return ErrorStateView(
      type: ErrorStateTypeX.fromError(error),
      message: error?.toString(),
      onRetry: onRetry,
      isFullScreen: false,
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        const LinguaSkeleton(height: 16, width: 140),
        const SizedBox(height: 12),
        const LinguaSkeleton(height: 120, borderRadius: 20),
        const SizedBox(height: 24),
        const LinguaSkeleton(height: 16, width: 160),
        const SizedBox(height: 12),
        const LinguaSkeleton(height: 76, borderRadius: 18),
        const SizedBox(height: 12),
        const LinguaSkeleton(height: 76, borderRadius: 18),
        const SizedBox(height: 12),
        const LinguaSkeleton(height: 94, borderRadius: 18),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 10. ACTIONS & MODALS
  // ---------------------------------------------------------------------------
  void _openConversation(BuildContext context, SpecialistConversationItem c) {
    // Navigate to Chat Thread route with contract arguments
    Navigator.pushNamed(
      context,
      AppRoutes.chatThread,
      arguments: {
        'conversation_id': c.id,
        'title': c.title,
        'subtitle': c.subtitle,
        'target_learner_id': c.targetLearnerId,
        'roles': c.roles,
        'is_locked': c.isLocked,
      },
    );
  }

  void _showConsentPendingDetails(BuildContext context, SpecialistConversationItem c) {
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
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFEE2E2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_rounded, color: Color(0xFFDC2626), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      c.title,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Parent / Guardian Consent Required',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF991B1B)),
              ),
              const SizedBox(height: 6),
              const Text(
                'In accordance with educational privacy and consent standards, speech audio turns and confidential session observations are locked until verified guardian approval is provided.',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.4),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _promptGuardianForConsent(context, c);
                },
                icon: const Icon(Icons.send_rounded, size: 16),
                label: const Text('Send Consent Prompt to Guardian'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF991B1B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _promptGuardianForConsent(BuildContext context, SpecialistConversationItem c) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('A gentle consent reminder was queued for ${c.title}.'),
        backgroundColor: const Color(0xFF4338CA),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSpecialistProfileModal(BuildContext context, UserSessionState session) {
    final specialistName = session.profile?.displayName ?? 'Specialist';
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
                    backgroundColor: Color(0xFF6366F1),
                    child: Icon(Icons.person, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        specialistName,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                      ),
                      const Text(
                        'Speech-Language Specialist (SLP)',
                        style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ListTile(
                leading: const Icon(Icons.notifications_outlined, color: _primary),
                title: const Text('Notification Preferences'),
                onTap: () => Navigator.pop(ctx),
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined, color: _primary),
                title: const Text('Collaboration Privacy & Consent Log'),
                onTap: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 11. BOTTOM NAVIGATION (4 Specialist destinations: Home, Caseload, Schedule, Messages)
  // ---------------------------------------------------------------------------
  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F0FB), width: 1.2)),
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: Row(
            children: [
              _buildBottomNavItem(
                icon: Icons.home_outlined,
                label: 'Home',
                isSelected: false,
                onTap: () => _goToSpecialistTab(0),
              ),
              _buildBottomNavItem(
                icon: Icons.groups_outlined,
                label: 'Caseload',
                isSelected: false,
                onTap: () => _goToSpecialistTab(1),
              ),
              _buildBottomNavItem(
                icon: Icons.calendar_today_outlined,
                label: 'Schedule',
                isSelected: false,
                onTap: () => _goToSpecialistTab(2),
              ),
              _buildBottomNavItem(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Messages',
                isSelected: true,
                hasNotificationBadge: true,
                onTap: null, // Already on Messages
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    bool hasNotificationBadge = false,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
            decoration: BoxDecoration(
              color: isSelected ? _primaryLight : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      icon,
                      size: 22,
                      color: isSelected ? _primary : _muted,
                    ),
                    if (hasNotificationBadge)
                      Positioned(
                        right: -3,
                        top: -2,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2DD4BF),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
                      ),
                  ],
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
                      color: isSelected ? _primary : _muted,
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

  void _goToSpecialistTab(int index) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.specialistDashboard,
      arguments: index,
    );
  }
}

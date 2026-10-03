import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingua_ai/shared/design_tokens/tokens.dart';
import 'package:lingua_ai/app/router/app_router.dart';
import 'package:lingua_ai/features/collaboration/application/collaboration_providers.dart';
import 'package:lingua_ai/features/collaboration/presentation/widgets/relationship_badge.dart';

class RelationshipsScreen extends ConsumerWidget {
  const RelationshipsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final relsAsync = ref.watch(relationshipsProvider);
    final invsAsync = ref.watch(invitationsProvider);

    return Scaffold(
      backgroundColor: LinguaTokens.paper50,
      appBar: AppBar(
        title: const Text('Authorized Connections', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: LinguaTokens.paper100,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            tooltip: 'Invite Collaborator',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.inviteCollaborator),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(LinguaTokens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Privacy Center Notice
            Container(
              padding: const EdgeInsets.all(LinguaTokens.space12),
              decoration: BoxDecoration(
                color: LinguaTokens.paper50,
                borderRadius: BorderRadius.circular(LinguaTokens.radiusSmall),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline, size: 16, color: LinguaTokens.ink700),
                  SizedBox(width: LinguaTokens.space8),
                  Expanded(
                    child: Text(
                      'Access is relationship-based. Only authorized parents, educators, and specialists can view scoped progress.',
                      style: TextStyle(fontSize: 12, color: LinguaTokens.ink700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: LinguaTokens.space20),

            // Active Connections Section
            const Text('Active Relationships', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: LinguaTokens.space12),

            relsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Text('Error loading relationships: $e'),
              data: (rels) {
                if (rels.isEmpty) {
                  return const Text('No connected collaborators yet.', style: TextStyle(color: LinguaTokens.inkMuted));
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: rels.length,
                  itemBuilder: (ctx, i) {
                    final r = rels[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: LinguaTokens.space12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
                        side: const BorderSide(color: LinguaTokens.borderSubtle),
                      ),
                      color: LinguaTokens.paper100,
                      child: Padding(
                        padding: const EdgeInsets.all(LinguaTokens.space16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  r.targetLearnerName,
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                                RelationshipBadge(status: r.status),
                              ],
                            ),
                            const SizedBox(height: LinguaTokens.space4),
                            Text(
                              'Role: ${r.relationshipType.toUpperCase()}${r.organization != null ? ' • ${r.organization}' : ''}',
                              style: const TextStyle(fontSize: 12, color: LinguaTokens.inkMuted),
                            ),
                            const SizedBox(height: LinguaTokens.space8),
                            Text(
                              'Permissions: ${r.permissionScope.join(", ")}',
                              style: const TextStyle(fontSize: 11, color: LinguaTokens.ink700),
                            ),
                            if (r.isActive) ...[
                              const Divider(height: LinguaTokens.space20),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (dCtx) => AlertDialog(
                                        title: const Text('Revoke Access?'),
                                        content: const Text(
                                          'Revoking will immediately block this user from accessing the learner\'s data.',
                                        ),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('Cancel')),
                                          ElevatedButton(
                                            onPressed: () => Navigator.pop(dCtx, true),
                                            style: ElevatedButton.styleFrom(backgroundColor: LinguaTokens.danger600),
                                            child: const Text('Revoke Access', style: TextStyle(color: Colors.white)),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      final repo = ref.read(collaborationRepositoryProvider);
                                      await repo.revokeRelationship(r.id);
                                      ref.invalidate(relationshipsProvider);
                                      ref.invalidate(parentChildrenProvider);
                                      ref.invalidate(teacherStudentsProvider);
                                      ref.invalidate(specialistCaseloadProvider);
                                    }
                                  },
                                  icon: const Icon(Icons.link_off, size: 16, color: LinguaTokens.danger600),
                                  label: const Text('Revoke Access', style: TextStyle(color: LinguaTokens.danger600, fontSize: 12)),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: LinguaTokens.space24),

            // Pending Invitations Section
            const Text('Pending Invitations', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: LinguaTokens.space12),

            invsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, s) => Text('Error: $e'),
              data: (invs) {
                if (invs.isEmpty) {
                  return const Text('No pending invitations.', style: TextStyle(color: LinguaTokens.inkMuted));
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: invs.length,
                  itemBuilder: (ctx, i) {
                    final inv = invs[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: LinguaTokens.space8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
                        side: const BorderSide(color: LinguaTokens.borderSubtle),
                      ),
                      color: LinguaTokens.paper100,
                      child: ListTile(
                        leading: const Icon(Icons.mail_outline, color: LinguaTokens.warning600),
                        title: Text(inv.inviteeEmail, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        subtitle: Text('Role: ${inv.relationshipType.toUpperCase()} • Status: ${inv.status.toUpperCase()}'),
                        trailing: inv.isPending
                            ? ElevatedButton(
                                onPressed: () async {
                                  final repo = ref.read(collaborationRepositoryProvider);
                                  await repo.acceptInvitation(inv.invitationToken);
                                  ref.invalidate(relationshipsProvider);
                                  ref.invalidate(invitationsProvider);
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: LinguaTokens.primary600),
                                child: const Text('Accept', style: TextStyle(fontSize: 11, color: Colors.white)),
                              )
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.inviteCollaborator),
        icon: const Icon(Icons.add, color: Colors.white),
        backgroundColor: LinguaTokens.primary600,
        label: const Text('Add Connection', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingua_ai/shared/design_tokens/tokens.dart';
import 'package:lingua_ai/features/collaboration/application/collaboration_providers.dart';

class InviteCollaboratorScreen extends ConsumerStatefulWidget {
  const InviteCollaboratorScreen({super.key});

  @override
  ConsumerState<InviteCollaboratorScreen> createState() => _InviteCollaboratorScreenState();
}

class _InviteCollaboratorScreenState extends ConsumerState<InviteCollaboratorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _orgController = TextEditingController();
  String _relationshipType = 'specialist';
  bool _isSending = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _orgController.dispose();
    super.dispose();
  }

  void _showTokenSuccessDialog(String token) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LinguaTokens.radiusCard),
        ),
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: LinguaTokens.success600, size: 28),
            SizedBox(width: 10),
            Text('Token Generated!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Share this single-use invitation token with your learner or collaborator to link accounts:',
              style: TextStyle(fontSize: 13, color: LinguaTokens.ink700, height: 1.4),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: LinguaTokens.primary100,
                borderRadius: BorderRadius.circular(LinguaTokens.radiusSmall),
                border: Border.all(color: LinguaTokens.primary600.withValues(alpha: 0.3)),
              ),
              child: SelectableText(
                token,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: LinguaTokens.primary700,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: token));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Token copied to clipboard!')),
                  );
                },
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copy Token Code'),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: LinguaTokens.primary600,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendInvitation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(collaborationRepositoryProvider);
      final inv = await repo.createInvitation(
        inviteeEmail: _emailController.text.trim(),
        relationshipType: _relationshipType,
        organization: _orgController.text.trim().isNotEmpty ? _orgController.text.trim() : null,
      );
      ref.invalidate(invitationsProvider);
      ref.invalidate(relationshipsProvider);
      ref.invalidate(parentChildrenProvider);

      if (mounted) {
        if (inv.invitationToken.isNotEmpty) {
          _showTokenSuccessDialog(inv.invitationToken);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invitation sent successfully.')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LinguaTokens.paper50,
      appBar: AppBar(
        title: const Text('Invite Collaborator', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: LinguaTokens.paper100,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(LinguaTokens.space16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(LinguaTokens.space12),
                  decoration: BoxDecoration(
                    color: LinguaTokens.dangerLight,
                    borderRadius: BorderRadius.circular(LinguaTokens.radiusSmall),
                  ),
                  child: Text(_errorMessage!, style: const TextStyle(color: LinguaTokens.danger600)),
                ),
                const SizedBox(height: LinguaTokens.space16),
              ],

              const Text('Collaborator Email', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: LinguaTokens.space8),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'colleague@school.edu or specialist@clinic.org',
                  filled: true,
                  fillColor: LinguaTokens.paper100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(LinguaTokens.radiusSmall)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Email is required';
                  if (!val.contains('@')) return 'Enter a valid email address';
                  return null;
                },
              ),
              const SizedBox(height: LinguaTokens.space16),

              const Text('Relationship Role', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: LinguaTokens.space8),
              DropdownButtonFormField<String>(
                initialValue: _relationshipType,
                isExpanded: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: LinguaTokens.paper100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(LinguaTokens.radiusSmall)),
                ),
                items: const [
                  DropdownMenuItem(value: 'parent', child: Text('Child / Learner (Link to Parent)')),
                  DropdownMenuItem(value: 'specialist', child: Text('Specialist Doctor / Speech Therapist')),
                  DropdownMenuItem(value: 'teacher', child: Text('Teacher / Educator')),
                ],
                onChanged: (val) => setState(() => _relationshipType = val ?? 'specialist'),
              ),
              const SizedBox(height: LinguaTokens.space16),

              const Text('School or Clinic Organization (Optional)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: LinguaTokens.space8),
              TextFormField(
                controller: _orgController,
                decoration: InputDecoration(
                  hintText: 'e.g. Westside Middle School or Speech Horizons',
                  filled: true,
                  fillColor: LinguaTokens.paper100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(LinguaTokens.radiusSmall)),
                ),
              ),
              const SizedBox(height: LinguaTokens.space24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSending ? null : _sendInvitation,
                  icon: const Icon(Icons.send_outlined),
                  label: _isSending
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Send Invitation Token', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LinguaTokens.primary600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: LinguaTokens.space16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingua_ai/shared/design_tokens/tokens.dart';
import 'package:lingua_ai/features/collaboration/application/collaboration_providers.dart';
import 'package:lingua_ai/features/collaboration/presentation/widgets/report_card.dart';

class ReportBuilderScreen extends ConsumerStatefulWidget {
  final String? initialLearnerId;

  const ReportBuilderScreen({super.key, this.initialLearnerId});

  @override
  ConsumerState<ReportBuilderScreen> createState() => _ReportBuilderScreenState();
}

class _ReportBuilderScreenState extends ConsumerState<ReportBuilderScreen> {
  final _titleController = TextEditingController(text: 'Learning Support Summary');
  String _reportType = 'parent_summary';
  bool _isGenerating = false;
  String? _errorMessage;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _generateReport() async {
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(collaborationRepositoryProvider);
      final learnerId = widget.initialLearnerId ?? 'self';
      await repo.createReport(
        learnerId: learnerId,
        reportType: _reportType,
        title: _titleController.text.trim(),
      );
      ref.invalidate(reportsProvider(widget.initialLearnerId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report generated successfully.')),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(reportsProvider(widget.initialLearnerId));

    return Scaffold(
      backgroundColor: LinguaTokens.paper50,
      appBar: AppBar(
        title: const Text('Learning Reports', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: LinguaTokens.paper100,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(LinguaTokens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Generator Form Card
            Card(
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
                    const Text('Generate Learning Report', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: LinguaTokens.space8),
                    const Text(
                      'Creates a factual summary of practice, skill readiness bands, and goals. Strictly educational and non-diagnostic.',
                      style: TextStyle(fontSize: 12, color: LinguaTokens.inkMuted),
                    ),
                    const SizedBox(height: LinguaTokens.space16),

                    if (_errorMessage != null) ...[
                      Text(_errorMessage!, style: const TextStyle(color: LinguaTokens.danger600, fontSize: 12)),
                      const SizedBox(height: LinguaTokens.space8),
                    ],

                    const Text('Perspective', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: LinguaTokens.space8),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _reportType,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: LinguaTokens.paper50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(LinguaTokens.radiusSmall)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'parent_summary', child: Text('Family Practice Summary', overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: 'teacher_summary', child: Text('Classroom Learning Summary', overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: 'specialist_summary', child: Text('Specialist Support Review', overflow: TextOverflow.ellipsis)),
                      ],
                      onChanged: (val) => setState(() => _reportType = val ?? 'parent_summary'),
                    ),
                    const SizedBox(height: LinguaTokens.space16),

                    const Text('Report Title', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: LinguaTokens.space8),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: LinguaTokens.paper50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(LinguaTokens.radiusSmall)),
                      ),
                    ),
                    const SizedBox(height: LinguaTokens.space16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isGenerating ? null : _generateReport,
                        icon: const Icon(Icons.picture_as_pdf),
                        label: _isGenerating
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Generate Report'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: LinguaTokens.primary600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: LinguaTokens.space12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: LinguaTokens.space24),

            // Reports History
            const Text('Generated Reports', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: LinguaTokens.space12),

            reportsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Text('Error loading reports: $e'),
              data: (reports) {
                if (reports.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(LinguaTokens.space24),
                      child: Text('No reports generated yet.', style: TextStyle(color: LinguaTokens.inkMuted)),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: reports.length,
                  itemBuilder: (ctx, i) => ReportCard(
                    report: reports[i],
                    onDownload: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Downloading non-diagnostic PDF report...')),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

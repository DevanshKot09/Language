import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingua_ai/shared/design_tokens/tokens.dart';
import 'package:lingua_ai/features/collaboration/application/collaboration_providers.dart';

class CreateAssignmentScreen extends ConsumerStatefulWidget {
  const CreateAssignmentScreen({super.key});

  @override
  ConsumerState<CreateAssignmentScreen> createState() => _CreateAssignmentScreenState();
}

class _CreateAssignmentScreenState extends ConsumerState<CreateAssignmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController(text: 'Complete Reading & Vocabulary Practice');
  final _instructionsController = TextEditingController(text: 'Work through exercises 1 and 2.');
  String? _selectedStudentId;
  String _selectedLessonId = 'lesson-1';
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _titleController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStudentId == null) {
      setState(() => _errorMessage = 'Please select a student.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(collaborationRepositoryProvider);
      await repo.createAssignment(
        studentId: _selectedStudentId!,
        lessonId: _selectedLessonId,
        title: _titleController.text.trim(),
        instructions: _instructionsController.text.trim(),
      );
      ref.invalidate(teacherAssignmentsProvider);
      ref.invalidate(teacherClassroomTrendsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assignment created successfully.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(teacherStudentsProvider);

    return Scaffold(
      backgroundColor: LinguaTokens.paper50,
      appBar: AppBar(
        title: const Text('Create Assignment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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

              const Text('Select Student', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: LinguaTokens.space8),
              studentsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, s) => Text('Failed to load students: $e'),
                data: (students) {
                  if (students.isEmpty) {
                    return const Text('No students connected yet. Invite a student first.');
                  }
                  return DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _selectedStudentId,
                    hint: const Text('Choose student'),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: LinguaTokens.paper100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(LinguaTokens.radiusSmall)),
                    ),
                    items: students.map((s) {
                      return DropdownMenuItem<String>(
                        value: s.studentId,
                        child: Text('${s.displayName} (${s.ageBand.toUpperCase()})', overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedStudentId = val),
                    validator: (val) => val == null ? 'Student is required' : null,
                  );
                },
              ),
              const SizedBox(height: LinguaTokens.space16),

              const Text('Curriculum Practice Lesson', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: LinguaTokens.space8),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _selectedLessonId,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: LinguaTokens.paper100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(LinguaTokens.radiusSmall)),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'lesson-1',
                    child: Text('Active Listening & Sentence Practice', overflow: TextOverflow.ellipsis),
                  ),
                  DropdownMenuItem(
                    value: 'lesson-2',
                    child: Text('Phonological Awareness & Syllable Decoding', overflow: TextOverflow.ellipsis),
                  ),
                  DropdownMenuItem(
                    value: 'lesson-3',
                    child: Text('Vocabulary in Everyday Contexts', overflow: TextOverflow.ellipsis),
                  ),
                ],
                onChanged: (val) => setState(() => _selectedLessonId = val ?? 'lesson-1'),
              ),
              const SizedBox(height: LinguaTokens.space16),

              const Text('Assignment Title', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: LinguaTokens.space8),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: LinguaTokens.paper100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(LinguaTokens.radiusSmall)),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: LinguaTokens.space16),

              const Text('Instructions (Optional)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: LinguaTokens.space8),
              TextFormField(
                controller: _instructionsController,
                maxLines: 3,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: LinguaTokens.paper100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(LinguaTokens.radiusSmall)),
                ),
              ),
              const SizedBox(height: LinguaTokens.space24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: LinguaTokens.primary600,
                    foregroundColor: Colors.white,
                  ),
                  child: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Assign Practice to Student', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

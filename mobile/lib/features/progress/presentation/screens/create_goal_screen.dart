import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/design_tokens/tokens.dart';
import '../../../../core/widgets/lingua_button.dart';
import '../../../../app/providers/age_profile_provider.dart';
import '../../domain/models/goal_models.dart';
import '../../application/progress_providers.dart';

class CreateGoalScreen extends ConsumerStatefulWidget {
  const CreateGoalScreen({super.key});

  @override
  ConsumerState<CreateGoalScreen> createState() => _CreateGoalScreenState();
}

class _CreateGoalScreenState extends ConsumerState<CreateGoalScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _goalType = 'complete_lessons';
  int _targetCount = 3;
  String _targetFrequency = 'weekly';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Default suggestion based on age band
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ageProfile = ref.read(ageProfileProvider);
      _applyDefaultPreset(ageProfile.ageBand.name);
    });
  }

  void _applyDefaultPreset(String ageBand) {
    if (ageBand == 'child') {
      _titleController.text = 'Explore 3 Practice Lessons';
      _descriptionController.text = 'Try fun stories and word games this week!';
      _targetCount = 3;
    } else if (ageBand == 'adult') {
      _titleController.text = 'Complete 2 Workplace Reading Activities';
      _descriptionController.text = 'Practical comprehension and communication practice.';
      _targetCount = 2;
    } else {
      _titleController.text = 'Complete 3 Practice Lessons';
      _descriptionController.text = 'Steady practice to build fluency and confidence.';
      _targetCount = 3;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ageProfile = ref.watch(ageProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set a Practice Goal'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(LinguaTokens.space20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Encouraging non-coercive banner (Step 54)
              Container(
                padding: const EdgeInsets.all(LinguaTokens.space12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F7FF),
                  borderRadius: BorderRadius.circular(LinguaTokens.radiusSmall),
                  border: Border.all(color: LinguaTokens.primary600.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lightbulb_outline, size: 20, color: LinguaTokens.primary600),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'A practice goal can help you stay on track. Practice at your own pace without pressure.',
                        style: TextStyle(fontSize: 12, color: LinguaTokens.ink900),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: LinguaTokens.space20),

              // Goal Presets based on Age Band
              Text(
                'Suggestions for ${ageProfile.displayName}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: LinguaTokens.ink900),
              ),
              const SizedBox(height: LinguaTokens.space8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _getPresetsForAge(ageProfile.ageBand.name).map((preset) {
                  return ActionChip(
                    label: Text(preset['title'] as String),
                    onPressed: () {
                      setState(() {
                        _titleController.text = preset['title'] as String;
                        _descriptionController.text = preset['desc'] as String;
                        _targetCount = preset['count'] as int;
                        _goalType = preset['type'] as String;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: LinguaTokens.space20),

              // Title Input
              const Text(
                'Goal Title',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: LinguaTokens.ink900),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'e.g., Complete 3 reading lessons',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(LinguaTokens.radiusSmall)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: LinguaTokens.space16),

              // Optional Description
              const Text(
                'Helpful Note (Optional)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: LinguaTokens.ink900),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Why this goal matters to you...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(LinguaTokens.radiusSmall)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: LinguaTokens.space16),

              // Target Count Selector
              const Text(
                'Target Count',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: LinguaTokens.ink900),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  IconButton.outlined(
                    icon: const Icon(Icons.remove),
                    onPressed: _targetCount > 1 ? () => setState(() => _targetCount--) : null,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '$_targetCount lessons / activities',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 16),
                  IconButton.outlined(
                    icon: const Icon(Icons.add),
                    onPressed: _targetCount < 20 ? () => setState(() => _targetCount++) : null,
                  ),
                ],
              ),
              const SizedBox(height: LinguaTokens.space16),

              // Target Frequency
              const Text(
                'Frequency',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: LinguaTokens.ink900),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _targetFrequency,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(LinguaTokens.radiusSmall)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                items: const [
                  DropdownMenuItem(value: 'daily', child: Text('Daily focus', overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(value: 'weekly', child: Text('Weekly goal (Recommended)', overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(value: 'biweekly', child: Text('Two weeks', overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _targetFrequency = val);
                },
              ),
              const SizedBox(height: LinguaTokens.space32),

              LinguaButton(
                label: _isSaving ? 'Saving Goal...' : 'Save Learning Goal',
                isLoading: _isSaving,
                onPressed: _titleController.text.trim().length >= 3 ? _saveGoal : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getPresetsForAge(String ageBand) {
    if (ageBand == 'child') {
      return [
        {'title': 'Complete 2 Story Lessons', 'desc': 'Listen and learn with stories.', 'count': 2, 'type': 'complete_lessons'},
        {'title': 'Play 3 Word Games', 'desc': 'Practice sound matching and letters.', 'count': 3, 'type': 'complete_lessons'},
        {'title': 'Practice Spoken Words', 'desc': 'Share words out loud.', 'count': 2, 'type': 'complete_lessons'},
      ];
    } else if (ageBand == 'adult') {
      return [
        {'title': 'Complete 2 Workplace Activities', 'desc': 'Reading comprehension for emails and reports.', 'count': 2, 'type': 'complete_lessons'},
        {'title': 'Practice Speech & Fluency', 'desc': 'Clear communication in everyday scenarios.', 'count': 3, 'type': 'complete_lessons'},
        {'title': 'Complete 5 Reading Lessons', 'desc': 'Build reading speed and decoding.', 'count': 5, 'type': 'complete_lessons'},
      ];
    } else {
      return [
        {'title': 'Complete 3 Reading Lessons', 'desc': 'Build fluency and comprehension.', 'count': 3, 'type': 'complete_lessons'},
        {'title': 'Practice Vocabulary 4 Times', 'desc': 'Learn deeper word meanings.', 'count': 4, 'type': 'complete_lessons'},
        {'title': 'Sentence Formulation Focus', 'desc': 'Practice sentence structures for school.', 'count': 3, 'type': 'complete_lessons'},
      ];
    }
  }

  Future<void> _saveGoal() async {
    setState(() => _isSaving = true);
    final dto = GoalCreateDto(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      goalType: _goalType,
      targetCount: _targetCount,
      targetFrequency: _targetFrequency,
    );

    final res = await ref.read(goalsNotifierProvider.notifier).createGoal(dto);
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (res != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Learning goal set successfully!')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('We couldn\'t save that goal. Your existing progress is still safe.')),
      );
    }
  }
}

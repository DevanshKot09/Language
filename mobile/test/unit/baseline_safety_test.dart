import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_ai/features/baseline/data/models/skill_snapshot_model.dart';
import 'package:lingua_ai/features/skills/data/models/skill_model.dart';

const prohibitedTerms = [
  'diagnosis',
  'diagnosed',
  'you have dyslexia',
  'you have dld',
  'clinical severity',
  'medical diagnosis',
  'dyslexia probability',
  'dld probability',
  'medical risk',
  'clinical score',
  'disorder classification',
];

void main() {
  group('Phase 4 Safety Boundary Tests (Zero Diagnostic Language)', () {
    test('Ensures SkillModel contains no prohibited diagnostic terminology', () {
      final skill = SkillModel(
        id: '1',
        code: 'dld_vocab',
        name: 'Vocabulary Breadth',
        description: 'Targeted word learning with phonological and semantic cues.',
        track: 'dld_track',
        domain: 'vocabulary',
      );

      final serialized = jsonEncode(skill.toJson()).toLowerCase();
      for (final term in prohibitedTerms) {
        expect(serialized.contains(term), isFalse, reason: 'Prohibited term "$term" found in SkillModel');
      }
    });

    test('Ensures SkillSnapshotModel contains no prohibited diagnostic terminology', () {
      final snapshot = SkillSnapshotModel(
        userId: 'u1',
        baselineStatus: 'completed',
        completedAt: DateTime.now(),
        skills: [
          const SkillSnapshotItemModel(
            skillId: 's1',
            skillCode: 'dld_vocab',
            skillName: 'Vocabulary',
            track: 'dld_track',
            domain: 'vocabulary',
            band: 'Consistent',
            score: 0.9,
            accuracy: 0.9,
            description: 'Strong independent skill; ready for diverse applied contexts.',
          ),
          const SkillSnapshotItemModel(
            skillId: 's2',
            skillCode: 'dys_phon',
            skillName: 'Phonological Awareness',
            track: 'dyslexia_track',
            domain: 'phonology',
            band: 'Starting',
            score: 0.3,
            accuracy: 0.3,
            description: 'Initial practice target; benefits from audio models and explicit cues.',
          ),
        ],
        strengthAreas: ['Vocabulary'],
        priorityPracticeAreas: ['Phonological Awareness'],
      );

      final serialized = jsonEncode({
        'skills': snapshot.skills.map((s) => s.toJson()).toList(),
        'strength_areas': snapshot.strengthAreas,
        'priority_practice_areas': snapshot.priorityPracticeAreas,
      }).toLowerCase();

      for (final term in prohibitedTerms) {
        expect(serialized.contains(term), isFalse, reason: 'Prohibited term "$term" found in SkillSnapshotModel');
      }
    });

    test('Ensures descriptive readiness bands adhere to non-diagnostic standard', () {
      const allowedBands = {'Consistent', 'Practicing', 'Developing', 'Starting'};
      for (final band in allowedBands) {
        expect(prohibitedTerms.contains(band.toLowerCase()), isFalse);
      }
    });
  });
}

/// Model representing an individual exercise item.
/// Content is structured and decoupled from presentation.
class ExerciseModel {
  final String id;
  final String lessonId;
  final String skillId;
  final String exerciseType;
  final String prompt;
  final String instruction;
  final dynamic content;
  final int difficulty;
  final String ageBand;
  final String track;
  final int sequenceOrder;
  final List<String> hints;
  final String? explanation;

  const ExerciseModel({
    required this.id,
    required this.lessonId,
    required this.skillId,
    required this.exerciseType,
    required this.prompt,
    required this.instruction,
    required this.content,
    required this.difficulty,
    required this.ageBand,
    required this.track,
    required this.sequenceOrder,
    this.hints = const [],
    this.explanation,
  });

  /// Helper to extract list of options for multiple choice or sentence completion
  List<String> get options {
    if (content is Map<String, dynamic>) {
      final opts = content['options'];
      if (opts is List) {
        return opts.map((e) => e.toString()).toList();
      }
    }
    return [];
  }

  /// Helper to extract token list for word ordering
  List<String> get tokens {
    if (content is Map<String, dynamic>) {
      final t = content['tokens'];
      if (t is List) {
        return t.map((e) => e.toString()).toList();
      }
    }
    return [];
  }

  /// Helper to extract pairs for matching exercise
  List<Map<String, String>> get matchingPairs {
    if (content is Map<String, dynamic>) {
      final p = content['pairs'];
      if (p is List) {
        return p.map((item) {
          if (item is Map) {
            return {
              'key': item['key'].toString(),
              'value': item['value'].toString(),
            };
          }
          return <String, String>{};
        }).where((m) => m.isNotEmpty).toList();
      }
    }
    return [];
  }

  /// Helper to extract reading passage text
  String? get readingPassage {
    if (content is Map<String, dynamic>) {
      return content['passage'] as String?;
    }
    return null;
  }

  /// Helper to extract narrative sequencing events
  List<Map<String, String>> get narrativeEvents {
    if (content is Map<String, dynamic>) {
      final events = content['events'];
      if (events is List) {
        return events.map((item) {
          if (item is Map) {
            return {
              'id': item['id'].toString(),
              'text': item['text'].toString(),
            };
          }
          return <String, String>{};
        }).where((m) => m.isNotEmpty).toList();
      }
    }
    return const [];
  }

  /// Helper to extract listening comprehension transcript
  String? get transcript {
    if (content is Map<String, dynamic>) {
      return content['transcript'] as String?;
    }
    return null;
  }

  /// Helper to extract scenario for social communication or context questions
  String? get scenario {
    if (content is Map<String, dynamic>) {
      return content['scenario'] as String?;
    }
    return null;
  }

  /// Helper to extract explicit question prompt if nested in content
  String? get question {
    if (content is Map<String, dynamic>) {
      return content['question'] as String?;
    }
    return null;
  }

  /// Helper to extract letter/sound tiles for word building
  List<String> get tiles {
    if (content is Map<String, dynamic>) {
      final t = content['tiles'];
      if (t is List) {
        return t.map((e) => e.toString()).toList();
      }
    }
    return const [];
  }

  /// Helper to extract target word for word building
  String? get targetWord {
    if (content is Map<String, dynamic>) {
      return content['target_word'] as String?;
    }
    return null;
  }

  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    final hintsRaw = json['hints'] as List<dynamic>?;
    return ExerciseModel(
      id: json['id'] as String,
      lessonId: json['lesson_id'] as String,
      skillId: json['skill_id'] as String,
      exerciseType: json['exercise_type'] as String,
      prompt: json['prompt'] as String,
      instruction: json['instruction'] as String,
      content: json['content'],
      difficulty: json['difficulty'] as int? ?? 1,
      ageBand: json['age_band'] as String? ?? 'all',
      track: json['track'] as String? ?? 'dld_track',
      sequenceOrder: json['sequence_order'] as int? ?? 1,
      hints: hintsRaw?.map((e) => e.toString()).toList() ?? const [],
      explanation: json['explanation'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lesson_id': lessonId,
      'skill_id': skillId,
      'exercise_type': exerciseType,
      'prompt': prompt,
      'instruction': instruction,
      'content': content,
      'difficulty': difficulty,
      'age_band': ageBand,
      'track': track,
      'sequence_order': sequenceOrder,
      'hints': hints,
      'explanation': explanation,
    };
  }
}

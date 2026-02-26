enum VettingAction { accept, reject, skip }

enum QuestionType { mcq, essay, short }

class Question {
  final String id;
  final String text;
  final String type;
  final String? courseCode;
  final String? topic;
  final bool duplicateWarning;
  final double weight;
  final Map<String, dynamic>? options;
  final String? correctAnswer;
  final String? difficulty;
  final int? marks;
  final Map<String, int> coMap;
  final List<String> loList;
  final String? evaluationCriteria;
  final List<String>? expectedPoints;
  final List<String>? keyPoints;
  final int? wordLimit;
  final String? source;
  final String? referenceMaterial;
  final String? referencePage;

  Question({
    required this.id,
    required this.text,
    required this.type,
    this.courseCode,
    this.topic,
    required this.duplicateWarning,
    required this.weight,
    this.options,
    this.correctAnswer,
    this.difficulty,
    this.marks,
    this.coMap = const {},
    this.loList = const [],
    this.evaluationCriteria,
    this.expectedPoints,
    this.keyPoints,
    this.wordLimit,
    this.source,
    this.referenceMaterial,
    this.referencePage,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    String extractId(dynamic id) {
      if (id is String) return id;
      if (id is Map && id.containsKey('\$oid')) return id['\$oid'] as String;
      return id?.toString() ?? '';
    }

    // Parse CO_map
    final rawCo = json['CO_map'];
    final Map<String, int> coMap = {};
    if (rawCo is Map) {
      rawCo.forEach((k, v) {
        if (v is num && v > 0) coMap[k.toString()] = v.toInt();
      });
    }

    // Parse LO_list
    final rawLo = json['LO_list'];
    final List<String> loList = rawLo is List
        ? rawLo.map((e) => e.toString()).toList()
        : [];

    return Question(
      id: extractId(json['_id']),
      text: json['question_text'] ?? '',
      type: json['type'] ?? 'MCQ',
      courseCode: json['course_code'],
      topic: json['topic'],
      duplicateWarning: json['duplicate_warning'] ?? false,
      weight: (json['weight'] ?? 1.0).toDouble(),
      options: json['options'] is Map<String, dynamic> ? json['options'] : null,
      correctAnswer: json['correct_answer'],
      difficulty: json['difficulty'],
      marks: json['marks'] is num ? (json['marks'] as num).toInt() : null,
      coMap: coMap,
      loList: loList,
      evaluationCriteria: json['evaluation_criteria'],
      expectedPoints: json['expected_points'] is List
          ? List<String>.from(json['expected_points'])
          : null,
      keyPoints: json['key_points'] is List
          ? List<String>.from(json['key_points'])
          : null,
      wordLimit: json['word_limit'] is num
          ? (json['word_limit'] as num).toInt()
          : null,
      source: json['source'],
      referenceMaterial: json['reference_material'],
      referencePage: json['reference_page']?.toString(),
    );
  }
}

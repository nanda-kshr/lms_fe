class Rubric {
  final String id;
  final String name;
  final String courseCode;
  final int marks;
  final int total;
  final Map<String, int> coDistribution;
  final Map<String, int> loDistribution;
  final Map<String, int> difficultyDistribution;
  final List<String> topics;
  final String questionStyle;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Rubric({
    required this.id,
    required this.name,
    required this.courseCode,
    this.marks = 1,
    this.total = 1,
    this.coDistribution = const {},
    this.loDistribution = const {},
    this.difficultyDistribution = const {},
    this.topics = const [],
    this.questionStyle = 'Analytical',
    this.createdAt,
    this.updatedAt,
  });

  factory Rubric.fromJson(Map<String, dynamic> json) {
    String extractId(dynamic id) {
      if (id is String) return id;
      if (id is Map && id.containsKey('\$oid')) return id['\$oid'] as String;
      return id?.toString() ?? '';
    }

    Map<String, int> parseIntMap(dynamic raw) {
      if (raw is! Map) return {};
      return raw.map(
        (k, v) => MapEntry(k.toString(), (v is num) ? v.toInt() : 0),
      );
    }

    return Rubric(
      id: extractId(json['_id']),
      name: json['name'] ?? '',
      courseCode: json['course_code'] ?? '',
      marks: json['marks'] ?? 1,
      total: json['total'] ?? 1,
      coDistribution: parseIntMap(json['co_distribution']),
      loDistribution: parseIntMap(json['lo_distribution']),
      difficultyDistribution: parseIntMap(json['difficulty_distribution']),
      topics: json['topics'] is List ? List<String>.from(json['topics']) : [],
      questionStyle: json['question_style'] ?? 'Analytical',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'course_code': courseCode,
    'marks': marks,
    'total': total,
    'co_distribution': coDistribution,
    'lo_distribution': loDistribution,
    'difficulty_distribution': difficultyDistribution,
    'topics': topics,
    'question_style': questionStyle,
  };
}

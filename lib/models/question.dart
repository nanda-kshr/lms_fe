enum VettingAction { accept, reject, skip }

enum QuestionType { mcq, essay, short }

class Question {
  final String id;
  final String text;
  final String type;
  final String? courseCode;
  final String? topic;
  final String uploadedBy;
  final DateTime uploadedAt;
  final bool duplicateWarning;
  final double weight;
  final Map<String, dynamic>? options;
  final String? correctAnswer;

  Question({
    required this.id,
    required this.text,
    required this.type,
    this.courseCode,
    this.topic,
    required this.uploadedBy,
    required this.uploadedAt,
    required this.duplicateWarning,
    required this.weight,
    this.options,
    this.correctAnswer,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    // Handle the "_id" field which could be a string or a Map with "$oid"
    String extractId(dynamic id) {
      if (id is String) return id;
      if (id is Map && id.containsKey('\$oid')) return id['\$oid'] as String;
      return id?.toString() ?? '';
    }

    return Question(
      id: extractId(json['_id']),
      text: json['question_text'] ?? '',
      type: json['type'] ?? 'MCQ',
      courseCode: json['course_code'],
      topic: json['topic'],
      uploadedBy: 'Dr. Smith', // Placeholder for now
      uploadedAt:
          DateTime.tryParse(json['uploaded_at'] ?? '') ?? DateTime.now(),
      duplicateWarning: json['duplicate_warning'] ?? false,
      weight: (json['weight'] ?? 1.0).toDouble(),
      options: json['options'],
      correctAnswer: json['correct_answer'],
    );
  }
}

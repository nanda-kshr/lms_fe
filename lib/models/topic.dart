class Topic {
  final String id;
  final String name;
  final String? description;
  final String courseId;
  final int order;

  Topic({
    required this.id,
    required this.name,
    this.description,
    required this.courseId,
    required this.order,
  });

  factory Topic.fromJson(Map<String, dynamic> json) {
    return Topic(
      id: json['_id'],
      name: json['name'],
      description: json['description'],
      courseId: json['course_id'] is Map
          ? json['course_id']['\$oid'] ?? json['course_id'].toString()
          : json['course_id'].toString(),
      order: json['order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'course_id': courseId,
      'order': order,
    };
  }
}

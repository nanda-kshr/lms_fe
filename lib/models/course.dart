class Course {
  final String id;
  final String name;
  final String code;
  final String? description;

  Course({
    required this.id,
    required this.name,
    required this.code,
    this.description,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['_id'],
      name: json['name'],
      code: json['code'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'_id': id, 'name': name, 'code': code, 'description': description};
  }
}

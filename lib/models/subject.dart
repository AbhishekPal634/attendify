class Subject {
  final String id;
  final String name;
  final String code;
  final String facultyName;
  final String facultyEmail;
  final int credits;
  final String semester;
  final String year;
  final List<String> enrolledStudents;
  final DateTime createdAt;
  final DateTime updatedAt;

  Subject({
    required this.id,
    required this.name,
    required this.code,
    required this.facultyName,
    required this.facultyEmail,
    required this.credits,
    required this.semester,
    required this.year,
    required this.enrolledStudents,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'facultyName': facultyName,
      'facultyEmail': facultyEmail,
      'credits': credits,
      'semester': semester,
      'year': year,
      'enrolledStudents': enrolledStudents,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Subject.fromMap(Map<String, dynamic> map) {
    return Subject(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      code: map['code'] ?? '',
      facultyName: map['facultyName'] ?? '',
      facultyEmail: map['facultyEmail'] ?? '',
      credits: map['credits'] ?? 3,
      semester: map['semester'] ?? '',
      year: map['year'] ?? '',
      enrolledStudents: List<String>.from(map['enrolledStudents'] ?? []),
      createdAt: DateTime.parse(
        map['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        map['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

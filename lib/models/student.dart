class Student {
  final String id;
  final String name;
  final String email;
  final String studentId;
  final String phone;
  final String dateOfBirth;
  final String gender;
  final String address;
  final String program;
  final String year;
  final String semester;
  final double cgpa;
  final int creditsCompleted;
  final int totalCredits;
  final String expectedGraduation;
  final DateTime createdAt;
  final DateTime updatedAt;

  Student({
    required this.id,
    required this.name,
    required this.email,
    required this.studentId,
    required this.phone,
    required this.dateOfBirth,
    required this.gender,
    required this.address,
    required this.program,
    required this.year,
    required this.semester,
    required this.cgpa,
    required this.creditsCompleted,
    required this.totalCredits,
    required this.expectedGraduation,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'studentId': studentId,
      'phone': phone,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'address': address,
      'program': program,
      'year': year,
      'semester': semester,
      'cgpa': cgpa,
      'creditsCompleted': creditsCompleted,
      'totalCredits': totalCredits,
      'expectedGraduation': expectedGraduation,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      studentId: map['studentId'] ?? '',
      phone: map['phone'] ?? '',
      dateOfBirth: map['dateOfBirth'] ?? '',
      gender: map['gender'] ?? '',
      address: map['address'] ?? '',
      program: map['program'] ?? '',
      year: map['year'] ?? '',
      semester: map['semester'] ?? '',
      cgpa: (map['cgpa'] ?? 0.0).toDouble(),
      creditsCompleted: map['creditsCompleted'] ?? 0,
      totalCredits: map['totalCredits'] ?? 120,
      expectedGraduation: map['expectedGraduation'] ?? '',
      createdAt: DateTime.parse(
        map['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        map['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Student copyWith({
    String? name,
    String? email,
    String? phone,
    String? dateOfBirth,
    String? gender,
    String? address,
    String? program,
    String? year,
    String? semester,
    double? cgpa,
    int? creditsCompleted,
    String? expectedGraduation,
  }) {
    return Student(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      studentId: studentId,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      program: program ?? this.program,
      year: year ?? this.year,
      semester: semester ?? this.semester,
      cgpa: cgpa ?? this.cgpa,
      creditsCompleted: creditsCompleted ?? this.creditsCompleted,
      totalCredits: totalCredits,
      expectedGraduation: expectedGraduation ?? this.expectedGraduation,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

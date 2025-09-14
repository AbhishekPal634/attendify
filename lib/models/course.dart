import 'package:cloud_firestore/cloud_firestore.dart';

class Course {
  final String id;
  final String courseId;
  final String courseName;
  final String semester;
  final String facultyId;
  final List<String> enrolledStudentIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  Course({
    required this.id,
    required this.courseId,
    required this.courseName,
    required this.semester,
    required this.facultyId,
    required this.enrolledStudentIds,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      id: map['id'] ?? '',
      courseId: map['courseId'] ?? '',
      courseName: map['courseName'] ?? '',
      semester: map['semester'] ?? '',
      facultyId: map['facultyId'] ?? '',
      enrolledStudentIds: List<String>.from(map['enrolledStudentIds'] ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'courseId': courseId,
      'courseName': courseName,
      'semester': semester,
      'facultyId': facultyId,
      'enrolledStudentIds': enrolledStudentIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Course copyWith({
    String? id,
    String? courseId,
    String? courseName,
    String? semester,
    String? facultyId,
    List<String>? enrolledStudentIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Course(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      courseName: courseName ?? this.courseName,
      semester: semester ?? this.semester,
      facultyId: facultyId ?? this.facultyId,
      enrolledStudentIds: enrolledStudentIds ?? this.enrolledStudentIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  int get studentCount => enrolledStudentIds.length;
}

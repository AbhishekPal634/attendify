import 'package:cloud_firestore/cloud_firestore.dart';

enum AttendanceStatus { present, absent, pending }

class AttendanceRecord {
  final String id;
  final String sessionId;
  final String courseId;
  final String studentId;
  final AttendanceStatus status;
  final DateTime? markedAt;
  final String? markedBy; // facultyId who marked/verified
  final bool isFaceVerified;
  final String? notes;

  AttendanceRecord({
    required this.id,
    required this.sessionId,
    required this.courseId,
    required this.studentId,
    required this.status,
    this.markedAt,
    this.markedBy,
    this.isFaceVerified = false,
    this.notes,
  });

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      id: map['id'] ?? '',
      sessionId: map['sessionId'] ?? '',
      courseId: map['courseId'] ?? '',
      studentId: map['studentId'] ?? '',
      status: AttendanceStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => AttendanceStatus.pending,
      ),
      markedAt: (map['markedAt'] as Timestamp?)?.toDate(),
      markedBy: map['markedBy'],
      isFaceVerified: map['isFaceVerified'] ?? false,
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sessionId': sessionId,
      'courseId': courseId,
      'studentId': studentId,
      'status': status.toString().split('.').last,
      'markedAt': markedAt != null ? Timestamp.fromDate(markedAt!) : null,
      'markedBy': markedBy,
      'isFaceVerified': isFaceVerified,
      'notes': notes,
    };
  }

  AttendanceRecord copyWith({
    String? id,
    String? sessionId,
    String? courseId,
    String? studentId,
    AttendanceStatus? status,
    DateTime? markedAt,
    String? markedBy,
    bool? isFaceVerified,
    String? notes,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      courseId: courseId ?? this.courseId,
      studentId: studentId ?? this.studentId,
      status: status ?? this.status,
      markedAt: markedAt ?? this.markedAt,
      markedBy: markedBy ?? this.markedBy,
      isFaceVerified: isFaceVerified ?? this.isFaceVerified,
      notes: notes ?? this.notes,
    );
  }

  String get statusDisplayName {
    switch (status) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.pending:
        return 'Pending';
    }
  }

  bool get isPresent => status == AttendanceStatus.present;
  bool get isAbsent => status == AttendanceStatus.absent;
  bool get isPending => status == AttendanceStatus.pending;
}

class AttendanceStats {
  final int totalStudents;
  final int presentCount;
  final int absentCount;
  final int pendingCount;

  AttendanceStats({
    required this.totalStudents,
    required this.presentCount,
    required this.absentCount,
    required this.pendingCount,
  });

  double get attendancePercentage =>
      totalStudents > 0 ? (presentCount / totalStudents) * 100 : 0.0;

  factory AttendanceStats.fromRecords(List<AttendanceRecord> records) {
    final present = records.where((r) => r.isPresent).length;
    final absent = records.where((r) => r.isAbsent).length;
    final pending = records.where((r) => r.isPending).length;

    return AttendanceStats(
      totalStudents: records.length,
      presentCount: present,
      absentCount: absent,
      pendingCount: pending,
    );
  }
}

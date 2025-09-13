class Session {
  final String id;
  final String subjectId;
  final String subjectName;
  final String facultyName;
  final DateTime startTime;
  final DateTime endTime;
  final String status; // 'scheduled', 'active', 'completed', 'cancelled'
  final String location;
  final List<String> attendedStudents;
  final DateTime createdAt;
  final DateTime updatedAt;

  Session({
    required this.id,
    required this.subjectId,
    required this.subjectName,
    required this.facultyName,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.location,
    required this.attendedStudents,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'facultyName': facultyName,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'status': status,
      'location': location,
      'attendedStudents': attendedStudents,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Session.fromMap(Map<String, dynamic> map) {
    return Session(
      id: map['id'] ?? '',
      subjectId: map['subjectId'] ?? '',
      subjectName: map['subjectName'] ?? '',
      facultyName: map['facultyName'] ?? '',
      startTime: DateTime.parse(
        map['startTime'] ?? DateTime.now().toIso8601String(),
      ),
      endTime: DateTime.parse(
        map['endTime'] ?? DateTime.now().toIso8601String(),
      ),
      status: map['status'] ?? 'scheduled',
      location: map['location'] ?? '',
      attendedStudents: List<String>.from(map['attendedStudents'] ?? []),
      createdAt: DateTime.parse(
        map['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        map['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  bool get isActive {
    final now = DateTime.now();
    return status == 'active' &&
        now.isAfter(startTime) &&
        now.isBefore(endTime);
  }

  bool get isUpcoming {
    final now = DateTime.now();
    return status == 'scheduled' && startTime.isAfter(now);
  }

  int get remainingMinutes {
    if (!isActive) return 0;
    final now = DateTime.now();
    return endTime.difference(now).inMinutes;
  }

  String get formattedStartTime {
    return '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
  }

  String get formattedEndTime {
    return '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
  }
}
